import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:groceryvoicelist/screens/setting_screen.dart';
import 'package:provider/provider.dart';

import '../providers/grocery_provider.dart';
import '../providers/order_provider.dart';
import '../providers/voice_provider.dart';
import '../services/hive_service.dart';
import '../utils/app_colors.dart';
import '../widgets/category_filter_row.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/grocery_list_item.dart';
import '../widgets/icon_text_button.dart';
import '../widgets/item_progress_bar.dart';
import '../widgets/voice_fab.dart';
import 'edit_item_screen.dart';
import 'my_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  int indexClick = 0;
  bool _showSearch = false;
  Timer? _deleteSnackBarTimer;

  @override
  void dispose() {
    _deleteSnackBarTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDeleteConfirmAll(BuildContext context) {
    final grocery = context.read<GroceryProvider>();
    final orderProvider = context.read<OrderProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start New List?'),
        content: const Text('Do you want to start a new list ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              orderProvider.addOrder(HiveService.getAllGroceryItems(false));
              grocery.clearAll();
              Get.back();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChecked(BuildContext context) {
    final grocery = context.read<GroceryProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove checked items?'),
        content: const Text('All ticked items will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              grocery.clearChecked();
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _openVoiceForItem(BuildContext context, String itemName) =>
      VoiceFab.openSheet(context, itemContextName: itemName);

  Future<void> _handleDelete(BuildContext context, String id) async {
    final grocery = context.read<GroceryProvider>();
    final voice = context.read<VoiceProvider>();
    final itemName = grocery.allItems.firstWhere((i) => i.id == id).name;

    await grocery.deleteItem(id);
    voice.speak('$itemName removed');

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    _deleteSnackBarTimer?.cancel();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('$itemName removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await grocery.undo();
            voice.speak('Restored $itemName');
          },
        ),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
      ),
    );

    // SnackBars with actions can remain visible indefinitely when accessible
    // navigation is enabled. Close this specific delete SnackBar explicitly so
    // its Undo window is consistently three seconds on every device.
    final dismissTimer = Timer(const Duration(seconds: 3), controller.close);
    _deleteSnackBarTimer = dismissTimer;

    // Clear the undo entry once the snackbar window closes without undo
    controller.closed.then((reason) {
      dismissTimer.cancel();
      if (identical(_deleteSnackBarTimer, dismissTimer)) {
        _deleteSnackBarTimer = null;
      }
      if (reason != SnackBarClosedReason.action) {
        grocery.clearUndoStack();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final grocery = context.read<GroceryProvider>();
    final colorScheme = AppColors.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: getTitle(indexClick),
        showLogoInLeading: indexClick == 0,
        actions: [
          indexClick == 0
              ? IconButton(
                  icon: Icon(
                    _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchCtrl.clear();
                        grocery.setSearchQuery('');
                      }
                    });
                  },
                )
              : SizedBox(),
          indexClick == 0
              ? IconButton(
                  icon: Icon(
                    grocery.showChecked
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: grocery.showChecked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  tooltip: grocery.showChecked
                      ? 'Hide checked'
                      : 'Show checked',
                  onPressed: grocery.toggleShowChecked,
                )
              : SizedBox(),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.only(left: 15, right: 15),
                child: _setWidgetOnTabClick(indexClick),
              ),
            ),
            Container(
              color: colorScheme.surface,
              height: 65,
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        indexClick = 0;
                        setState(() {});
                      },
                      child: SizedBox(
                        height: 65,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home,
                              size: 25,
                              color: indexClick == 0
                                  ? colorScheme.primary
                                  : Colors.grey,
                            ),
                            Text(
                              'Home',
                              style: TextStyle(
                                fontSize: 13,
                                color: indexClick == 0
                                    ? colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        indexClick = 1;
                        setState(() {});
                      },
                      child: SizedBox(
                        height: 65,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 25,
                              color: indexClick == 1
                                  ? colorScheme.primary
                                  : Colors.grey,
                            ),
                            Text(
                              'My Lists',
                              style: TextStyle(
                                fontSize: 13,
                                color: indexClick == 1
                                    ? colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        indexClick = 2;
                        setState(() {});
                      },
                      child: SizedBox(
                        height: 65,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info,
                              size: 25,
                              color: indexClick == 2
                                  ? colorScheme.primary
                                  : Colors.grey,
                            ),
                            Text(
                              'Info',
                              style: TextStyle(
                                fontSize: 13,
                                color: indexClick == 2
                                    ? colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
      floatingActionButton: indexClick == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: VoiceFab(),
            )
          : SizedBox(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String getTitle(int indexClick) {
    switch (indexClick) {
      case 0:
        return '';
      case 1:
        return 'My Orders';
      case 2:
        return 'App Info';
      default:
        return '';
    }
  }

  _setWidgetOnTabClick(int indexClick) {
    switch (indexClick) {
      case 0:
        return getHomePageWidget();
      case 1:
        return MyOrdersScreen();
      case 2:
        return SettingScreen();
      default:
        SizedBox();
    }
  }

  Widget getHomePageWidget() {
    final colorScheme = AppColors.of(context);
    final grocery = context.watch<GroceryProvider>();
    final items = grocery.filteredItems;
    return Column(
      children: [
        _showSearch
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.bottomBar,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: grocery.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search items…',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                    prefixIcon: Icon(Icons.search, color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            : SizedBox(),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(child: SizedBox()),
            IconTextButton(
              icon: Icons.add,
              text: 'Item',
              backgroundColor: AppColors.of(context).primary,
              onTap: () {
                Get.to(() => EditItemScreen());
              },
            ),
            SizedBox(width: 20),
            IconTextButton(
              icon: Icons.add,
              backgroundColor: AppColors.of(context).primary,
              text: 'New List',
              onTap: () {
                _showDeleteConfirmAll(context);
              },
            ),
          ],
        ),

        // Progress bar
        if (grocery.totalItems > 0) ItemsProgressBar(),

        SizedBox(height: 8),
        CategoryFilterRow(),
        SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? grocery.totalItems == 0
                    ? const EmptyState()
                    : Center(
                        child: Text(
                          'No items in this category',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GroceryListItem(
                      key: ValueKey(item.id),
                      item: item,
                      onToggle: () async {
                        final msg = await grocery.toggleChecked(item.id);
                        if (msg != null && context.mounted) {
                          context.read<VoiceProvider>().speak(msg);
                        }
                      },
                      onDelete: () => _handleDelete(context, item.id),
                      onEdit: () => Get.to(() => EditItemScreen(item: item)),
                      onVoice: () => _openVoiceForItem(context, item.name),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
