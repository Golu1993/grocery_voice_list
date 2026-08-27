import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groceryvoicelist/features/smooth_speech_to_text/smooth_speech_to_text.dart';
import 'package:groceryvoicelist/models/grocery_item.dart';
import 'package:groceryvoicelist/providers/grocery_provider.dart';
import 'package:groceryvoicelist/widgets/grocery_list_item.dart';
import 'package:groceryvoicelist/widgets/voice_fab.dart';
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
