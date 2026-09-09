import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocart/features/smooth_speech_to_text/smooth_speech_to_text.dart';
import 'package:vocart/models/grocery_field.dart';
import 'package:vocart/models/grocery_item.dart';
import 'package:vocart/models/order_item.dart';
import 'package:vocart/providers/grocery_provider.dart';
import 'package:vocart/widgets/grocery_list_item.dart';
import 'package:vocart/widgets/order_list_item.dart';
import 'package:vocart/widgets/voice_fab.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('grocery list item uses the compact home layout', (tester) async {
    final item = GroceryItem(
      id: 'milk',
      name: 'Milk',
      quantity: 2,
      unit: 'l',
      categoryKey: 'dairy',
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: ListView(
              children: [
                GroceryListItem(
                  item: item,
                  onToggle: () {},
                  onDelete: () {},
                  onEdit: () {},
                  onVoice: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(GroceryListItem)).height,
      lessThanOrEqualTo(60),
    );
    expect(find.byTooltip('Voice update'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card tap edits and checkbox tap toggles the item', (
    tester,
  ) async {
    var editCount = 0;
    var toggleCount = 0;
    final item = GroceryItem(
      id: 'milk',
      name: 'Milk',
      quantity: 2,
      unit: 'l',
      categoryKey: 'dairy',
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroceryListItem(
            item: item,
            onToggle: () => toggleCount++,
            onDelete: () {},
            onEdit: () => editCount++,
            onVoice: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Milk'));
    await tester.pump();

    expect(editCount, 1);
    expect(toggleCount, 0);

    await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
    await tester.pump();

    expect(editCount, 1);
    expect(toggleCount, 1);
  });

  testWidgets('home voice action is visible and accessible', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GroceryProvider(),
        child: const MaterialApp(
          home: Scaffold(floatingActionButton: VoiceFab()),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byTooltip('Add groceries by voice'), findsOneWidget);
  });

  testWidgets('saved list card opens while only View items expands', (
    tester,
  ) async {
    var openCount = 0;
    var expandCount = 0;
    final order = OrderItem(
      time: 'September 9, 2026',
      storeName: 'My Store',
      itemCount: 1,
      amount: 0,
      status: 'Pending',
      itemList: [
        GroceryField(name: 'Milk', quantity: 2, unit: 'l', isChecked: false),
      ],
      orderId: 1,
      isCurrent: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderListItemItem(
            orderItem: order,
            index: 0,
            onDelete: () {},
            onShare: () {},
            onOpen: () => openCount++,
            onToggleExpanded: () => expandCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('September 9, 2026'));
    await tester.pump();
    expect(openCount, 1);
    expect(expandCount, 0);

    final viewItemsButton = find.widgetWithText(TextButton, 'View items');
    expect(tester.getSize(viewItemsButton).height, greaterThanOrEqualTo(40));

    await tester.tap(viewItemsButton);
    await tester.pump();
    expect(openCount, 1);
    expect(expandCount, 1);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pump();
    expect(openCount, 2);
    expect(expandCount, 1);
  });

  testWidgets(
    'voice dialog centers mic with transcript below and Done at top',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SmoothSpeechToTextWidget(
                height: 320,
                title: 'Add by voice',
                centeredVoiceLayout: true,
                showTranscriptActions: false,
                localeLabel: 'English (India)',
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      final mic = find.byTooltip('Start listening');
      final prompt = find.text('Tap the microphone to speak');
      final done = find.text('Done');

      expect(mic, findsOneWidget);
      expect(prompt, findsOneWidget);
      expect(done, findsOneWidget);
      expect(
        tester.getCenter(prompt).dy,
        greaterThan(tester.getCenter(mic).dy),
      );
      expect(tester.getCenter(done).dx, greaterThan(tester.getCenter(mic).dx));
      expect(tester.getCenter(done).dy, lessThan(tester.getCenter(mic).dy));
      expect(tester.takeException(), isNull);
    },
  );
}
