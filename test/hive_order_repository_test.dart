import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vocart/providers/grocery_provider.dart';
import 'package:vocart/providers/order_provider.dart';
import 'package:vocart/services/hive_order_repository.dart';

void main() {
  test('Hive restores the active list and keeps accounts separate', () async {
    final directory = await Directory.systemTemp.createTemp('vocart_orders_');
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);

    final firstAccount = await HiveOrderRepository.open('first-auth-uid');
    final firstUuid = await firstAccount.ensureActiveOrder();
    expect(await firstAccount.ensureActiveOrder(), firstUuid);

    final groceries = GroceryProvider(orderRepository: firstAccount);
    await groceries.loadItems();
    await groceries.addItem(
      name: 'Milk',
      quantity: 1.25,
      unit: 'l',
      categoryKey: 'dairy',
    );
    await groceries.toggleChecked(groceries.allItems.single.id);
    expect(firstAccount.getOrders().single.itemList.single.quantity, 1.25);
    expect(firstAccount.getOrders().single.itemList.single.isChecked, true);

    final secondUuid = await groceries.startNewList();
    expect(secondUuid, isNot(firstUuid));
    await groceries.addItem(
      name: 'Rice',
      quantity: 2.5,
      unit: 'kg',
      categoryKey: 'grains',
    );
    final history = OrderProvider(
      orderRepository: firstAccount,
      activeOrderUuid: secondUuid,
    );
    await history.refreshOrders();
    expect(
      history.orders.map((order) => order.uuid),
      containsAll([firstUuid, secondUuid]),
    );
    expect(history.orders.first.isCurrent, true);
    expect(history.orders.last.completed, true);

    final otherAccount = await HiveOrderRepository.open('other-auth-uid');
    await otherAccount.ensureActiveOrder();
    expect(otherAccount.getActiveItems(), isEmpty);
    expect(otherAccount.getOrders().single.itemList, isEmpty);

    await Hive.close();
    Hive.init(directory.path);
    final reopened = await HiveOrderRepository.open('first-auth-uid');
    expect(await reopened.ensureActiveOrder(), secondUuid);
    expect(reopened.getActiveItems().single.name, 'Rice');
    expect(reopened.getActiveItems().single.quantity, 2.5);
    expect(reopened.getOrders().last.itemList.single.name, 'Milk');

    await reopened.deleteOrder(firstUuid);
    expect(reopened.getOrders().map((order) => order.uuid), [secondUuid]);
    await expectLater(reopened.deleteOrder(secondUuid), throwsStateError);
  });

  test(
    'editing a saved list reuses its UUID and restores item details',
    () async {
      final directory = await Directory.systemTemp.createTemp('vocart_edit_');
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
      Hive.init(directory.path);

      final repository = await HiveOrderRepository.open('edit-auth-uid');
      final firstUuid = await repository.ensureActiveOrder();
      final groceries = GroceryProvider(orderRepository: repository);
      await groceries.loadItems();
      await groceries.addItem(
        name: 'Milk',
        quantity: 1,
        unit: 'l',
        categoryKey: 'dairy',
        notes: 'Buy organic',
      );
      final original = groceries.allItems.single;

      final secondUuid = await groceries.startNewList();
      await groceries.addItem(
        name: 'Rice',
        quantity: 2,
        unit: 'kg',
        categoryKey: 'grains',
      );
      expect(repository.getOrders(), hasLength(2));

      await groceries.editSavedList(firstUuid);
      expect(groceries.allItems, hasLength(1));
      final reopened = groceries.allItems.single;
      expect(reopened.id, original.id);
      expect(reopened.categoryKey, 'dairy');
      expect(reopened.notes, 'Buy organic');
      expect(reopened.createdAt, original.createdAt);
      expect(repository.getOrders(), hasLength(2));
      expect(
        repository
            .getOrders()
            .singleWhere((o) => o.uuid == firstUuid)
            .isCurrent,
        true,
      );
      expect(
        repository
            .getOrders()
            .singleWhere((o) => o.uuid == secondUuid)
            .isCurrent,
        false,
      );

      await groceries.updateItem(
        reopened.copyWith(quantity: 3, notes: 'Buy fresh'),
      );
      final updatedOrder = repository.getOrders().singleWhere(
        (o) => o.uuid == firstUuid,
      );
      expect(updatedOrder.itemList.single.quantity, 3);
      expect(updatedOrder.itemList.single.notes, 'Buy fresh');
      expect(repository.getOrders(), hasLength(2));

      final thirdUuid = await groceries.startNewList();
      expect(thirdUuid, isNot(firstUuid));
      expect(repository.getOrders(), hasLength(3));
      final editedHistory = repository.getOrders().singleWhere(
        (o) => o.uuid == firstUuid,
      );
      expect(editedHistory.itemList.single.notes, 'Buy fresh');
      expect(editedHistory.completed, true);

      await Hive.close();
      Hive.init(directory.path);
      final reloaded = await HiveOrderRepository.open('edit-auth-uid');
      expect(await reloaded.ensureActiveOrder(), thirdUuid);
      final saved = reloaded.getOrders().singleWhere(
        (o) => o.uuid == firstUuid,
      );
      expect(saved.itemList.single.notes, 'Buy fresh');
      expect(saved.itemList.single.categoryKey, 'dairy');
    },
  );
}
