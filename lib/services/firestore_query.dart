import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/device_details.dart';
import '../models/grocery_field.dart';
import '../models/grocery_item.dart';
import '../models/list_items_model.dart';
import '../models/list_model.dart';
import '../models/order_item.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firestore_query_guard.dart';
import 'hive_service.dart';
import 'voice_parser.dart';

/// All Firestore queries for profiles, devices, grocery lists, and list items.
/// Supply an ownerId for list operations and share that instance within a session.
class FirestoreQuery {
  FirestoreQuery({
    this._ownerId,
    FirebaseFirestore? firestore,
    FirestoreQueryGuard? guard,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _guard = guard ?? FirestoreQueryGuard();

  final String? _ownerId;
  final FirebaseFirestore _firestore;
  final FirestoreQueryGuard _guard;
  final Uuid _uuid = const Uuid();
  String? _activeListId;
  ListModel? _pendingNewList;
  Map<String, ListItemsModel>? _activeItems;

  String get ownerId {
    final id = _ownerId;
    if (id == null || id.isEmpty) {
      throw StateError('No user profile is available.');
    }
    return id;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _devices =>
      _firestore.collection('devices');
  CollectionReference<Map<String, dynamic>> get _lists =>
      _firestore.collection('lists');
  CollectionReference<Map<String, dynamic>> get _listItems =>
      _firestore.collection('list_items');
  DocumentReference<Map<String, dynamic>> get _user => _users.doc(ownerId);

  /// Stores this installation's device document.
  Future<void> saveDevice({
    required DeviceDetails device,
    required String userUuid,
  }) async {
    final document = _devices.doc('${userUuid}_${device.uuid}');
    final details = {...device.toMap(), 'activeUserId': userUuid};
    await _guard.write(() => document.set(details, SetOptions(merge: true)));
  }

  /// Updates a device when Firebase rotates its messaging token.
  Future<void> saveFcmToken({
    required String userUuid,
    required String deviceUuid,
    required String fcmToken,
  }) => _guard.write(
    () => _devices.doc('${userUuid}_$deviceUuid').set({
      'fcmToken': fcmToken,
    }, SetOptions(merge: true)),
  );

  /// Creates the user profile once and refreshes it on later sign-ins.
  Future<UserModel> saveSignedInUser({required User firebaseUser}) async {
    void ensureSameAccount() {
      if (FirebaseAuth.instance.currentUser?.uid != firebaseUser.uid) {
        throw StateError('The signed-in account changed during profile sync.');
      }
    }

    ensureSameAccount();
    final users = _users;
    var existing = await _guard.read(
      () => users
          .where('loginId', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get(const GetOptions(source: Source.server)),
    );

    // Older profiles used authUid. Reuse their application UUID on first sign-in
    // after the schema change instead of creating a second user document.
    if (existing.docs.isEmpty) {
      existing = await _guard.read(
        () => users
            .where('authUid', isEqualTo: firebaseUser.uid)
            .limit(1)
            .get(const GetOptions(source: Source.server)),
      );
    }

    ensureSameAccount();

    if (existing.docs.isEmpty) {
      final uuid = await HiveService.getOrCreateProfileUuid(firebaseUser.uid);
      final user = UserModel.fromFirebaseUser(firebaseUser, uuid: uuid);
      final details = user.toMap()..remove('updateAt');
      await _guard.write(
        () => users.doc(uuid).set({
          ...details,
          'lastSignInAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
      return user;
    }

    final document = existing.docs.single;
    await _guard.write(
      () => document.reference.update({
        'name': firebaseUser.displayName,
        'email': firebaseUser.email,
        'phoneNo': firebaseUser.phoneNumber,
        'photoUrl': firebaseUser.photoURL,
        'loginProvider': 'google.com',
        'loginId': firebaseUser.uid,
        'devices': FieldValue.delete(),
        'updateAt': FieldValue.serverTimestamp(),
        'lastSignInAt': FieldValue.serverTimestamp(),
        'authUid': FieldValue.delete(),
      }),
    );
    final data = document.data();
    return UserModel.fromMap({
      ...data,
      'name': firebaseUser.displayName,
      'email': firebaseUser.email,
      'phoneNo': firebaseUser.phoneNumber,
      'photoUrl': firebaseUser.photoURL,
      'loginProvider': 'google.com',
      'loginId': firebaseUser.uid,
    });
  }

  String get activeListId =>
      _activeListId ?? (throw StateError('No active list is available.'));

  Future<String> ensureActiveOrder() async {
    final lists = await _readLists();
    if (lists.isEmpty) {
      // A stable UUID prevents duplicate starter lists after an uncertain write.
      final first = _newList(
        _uuid.v5(Namespace.url.value, 'vocart/starter-list/$ownerId'),
      );
      final batch = _firestore.batch();
      batch.set(_lists.doc(first.listId), first.toMap());
      batch.set(_user, {'activeListId': first.listId}, SetOptions(merge: true));
      await _guard.write(batch.commit);
      _activeListId = first.listId;
      return first.listId;
    }

    final user = await _guard.read(
      () => _user.get(const GetOptions(source: Source.server)),
    );
    final savedId = user.data()?['activeListId'] as String?;
    final selected = lists.any((list) => list.listId == savedId)
        ? savedId!
        : lists.first.listId;
    if (savedId != selected) {
      await _guard.write(
        () => _user.set({'activeListId': selected}, SetOptions(merge: true)),
      );
    }
    _activeListId = selected;
    return selected;
  }

  Future<List<GroceryItem>> getActiveItems() async {
    final items = await _readItems(activeListId);
    _activeItems = {for (final item in items) item.listItemId: item};
    return items.map(_toGroceryItem).toList()
      ..sort(GroceryItem.compareForDisplay);
  }

  Future<List<OrderItem>> getOrders() async {
    final lists = await _readLists();
    if (lists.isEmpty) return [];

    final result = await _guard.read(
      () => _listItems
          .where('ownerId', isEqualTo: ownerId)
          .get(const GetOptions(source: Source.server)),
    );
    final itemsByList = <String, List<ListItemsModel>>{};
    for (final document in result.docs) {
      final item = ListItemsModel.fromMap(document.data());
      (itemsByList[item.listId] ??= []).add(item);
    }

    return lists.map((list) {
      final items = itemsByList[list.listId] ?? [];
      items.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.createdTime.compareTo(b.createdTime);
      });
      return OrderItem(
        uuid: list.listId,
        time: DateFormat('MMMM dd, yyyy hh:mm a').format(list.createTime),
        storeName: list.listName,
        itemCount: items.length,
        amount: 0,
        status: list.listId == _activeListId ? 'Pending' : 'Completed',
        itemList: items.map(_toGroceryField).toList(),
        orderId: list.createTime.microsecondsSinceEpoch,
        isCurrent: list.listId == _activeListId,
        completed: list.listId != _activeListId,
        isPinned: list.isPinned,
        updatedAt: list.updateTime,
      );
    }).toList()..sort(OrderItem.compareForDisplay);
  }

  Future<void> saveItems(Iterable<GroceryItem> items) async {
    final listId = activeListId;
    final previous =
        _activeItems ??
        {for (final item in await _readItems(listId)) item.listItemId: item};
    final desired = {for (final item in items) item.id: item};
    final next = Map<String, ListItemsModel>.from(previous);
    final changes = <void Function(WriteBatch)>[];
    final now = DateTime.now();

    for (final oldId in previous.keys) {
      if (desired.containsKey(oldId)) continue;
      changes.add((batch) => batch.delete(_listItems.doc(oldId)));
      next.remove(oldId);
    }
    for (final item in desired.values) {
      final old = previous[item.id];
      if (old != null &&
          old.itemName == item.name &&
          old.quantity == _quantityString(item.quantity) &&
          old.unit == item.unit &&
          old.notes == (item.notes ?? '') &&
          old.categoryKey == item.categoryKey &&
          old.isPinned == item.isPinned &&
          old.isChecked == item.isChecked) {
        continue;
      }
      final model = ListItemsModel(
        listItemId: item.id,
        itemId: old?.itemId ?? item.id,
        listId: listId,
        itemName: item.name,
        quantity: _quantityString(item.quantity),
        unit: item.unit,
        notes: item.notes ?? '',
        categoryKey: item.categoryKey,
        createdTime: old?.createdTime ?? item.createdAt,
        updateTime: now,
        addedBy: old?.addedBy ?? ownerId,
        updatedBy: ownerId,
        ownerId: ownerId,
        isPinned: item.isPinned,
        isChecked: item.isChecked,
        checkedAt: item.isChecked
            ? (old?.isChecked == true ? old!.checkedAt : now)
            : null,
        checkedBy: item.isChecked
            ? (old?.isChecked == true ? old!.checkedBy : ownerId)
            : null,
      );
      changes.add((batch) => batch.set(_listItems.doc(item.id), model.toMap()));
      next[item.id] = model;
    }

    if (changes.isEmpty) return;
    // Reserve one operation per batch for the parent list's update time.
    for (var offset = 0; offset < changes.length; offset += 400) {
      final batch = _firestore.batch();
      for (final change in changes.skip(offset).take(400)) {
        change(batch);
      }
      batch.update(_lists.doc(listId), {'updateTime': Timestamp.fromDate(now)});
      await _guard.write(batch.commit);
    }
    _activeItems = next;
  }

  Future<String> startNewList() async {
    final next = _pendingNewList ?? _newList(_uuid.v4());
    _pendingNewList = next;
    final batch = _firestore.batch();
    batch.set(_lists.doc(next.listId), next.toMap());
    batch.set(_user, {'activeListId': next.listId}, SetOptions(merge: true));
    await _guard.write(batch.commit);
    _activeListId = next.listId;
    _activeItems = {};
    _pendingNewList = null;
    return next.listId;
  }

  Future<void> activateOrder(String listId) async {
    final lists = await _readLists();
    if (!lists.any((list) => list.listId == listId)) {
      throw StateError('List $listId was not found.');
    }
    await _guard.write(
      () => _user.set({'activeListId': listId}, SetOptions(merge: true)),
    );
    _activeListId = listId;
    _activeItems = null;
  }

  Future<void> deleteOrder(String listId) async {
    if (listId == _activeListId) {
      throw StateError('The active list cannot be deleted.');
    }
    final lists = await _readLists();
    if (!lists.any((list) => list.listId == listId)) {
      throw StateError('List $listId was not found.');
    }
    await _guard.write(
      () => _lists.doc(listId).update({
        'isDeleted': true,
        'updateTime': Timestamp.fromDate(DateTime.now()),
      }),
    );
  }

  Future<DateTime> setListPinned(
    String listId, {
    required bool isPinned,
  }) async {
    final updatedAt = DateTime.now();
    await _guard.write(
      () => _lists.doc(listId).update({
        'isPinned': isPinned,
        'updateTime': Timestamp.fromDate(updatedAt),
      }),
    );
    return updatedAt;
  }

  Future<List<ListModel>> _readLists() async {
    final profileId = ownerId;
    final result = await _guard.read(
      () => _lists
          .where('ownerId', isEqualTo: profileId)
          .get(const GetOptions(source: Source.server)),
    );
    final lists = result.docs
        .map((doc) => ListModel.fromMap(doc.data()))
        .where((list) => !list.isDeleted)
        .toList();
    lists.sort((a, b) {
      final byUpdate = b.updateTime.compareTo(a.updateTime);
      return byUpdate != 0 ? byUpdate : b.createTime.compareTo(a.createTime);
    });
    return lists;
  }

  Future<List<ListItemsModel>> _readItems(String listId) async {
    final profileId = ownerId;
    final result = await _guard.read(
      () => _listItems
          .where('ownerId', isEqualTo: profileId)
          .where('listId', isEqualTo: listId)
          .get(const GetOptions(source: Source.server)),
    );
    return result.docs
        .map((doc) => ListItemsModel.fromMap(doc.data()))
        .toList();
  }

  ListModel _newList(String id) {
    final now = DateTime.now();
    return ListModel(
      createTime: now,
      description: '',
      listId: id,
      listName: 'My List',
      updateTime: now,
      color: '#4CAF50',
      isArchive: false,
      isDeleted: false,
      ownerId: ownerId,
    );
  }

  String _quantityString(double quantity) =>
      quantity == quantity.truncateToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();

  GroceryItem _toGroceryItem(ListItemsModel item) {
    final quantity = double.tryParse(item.quantity);
    if (quantity == null) {
      throw FormatException('Invalid quantity for item ${item.listItemId}.');
    }
    return GroceryItem(
      id: item.listItemId,
      name: item.itemName,
      quantity: quantity,
      unit: item.unit,
      categoryKey:
          item.categoryKey ??
          VoiceParser.parse('add ${item.itemName}').categoryKey ??
          GroceryCategory.other.storageKey,
      isChecked: item.isChecked,
      isPinned: item.isPinned,
      createdAt: item.createdTime,
      notes: item.notes.isEmpty ? null : item.notes,
    );
  }

  GroceryField _toGroceryField(ListItemsModel item) {
    final grocery = _toGroceryItem(item);
    return GroceryField(
      id: grocery.id,
      name: grocery.name,
      quantity: grocery.quantity,
      unit: grocery.unit,
      categoryKey: grocery.categoryKey,
      isChecked: grocery.isChecked,
      isPinned: grocery.isPinned,
      createdAt: grocery.createdAt,
      notes: grocery.notes,
    );
  }
}
