import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:a1_battery/widgets/product_item_widget.dart';

void main() {
  testWidgets('ProductItemWidget renders form fields and serial numbers', (WidgetTester tester) async {
    final controller = ItemRowController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProductItemWidget(
              index: 1,
              controller: controller,
              products: const ['Exide Battery', 'Amaron Battery'],
              onChanged: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    // Verify item header and labels
    expect(find.text('Item Details'), findsOneWidget);
    expect(find.text('Battery Name *'), findsOneWidget);
    expect(find.text('HSN/SAC'), findsOneWidget);
    expect(find.text('Serial Numbers (one per line)'), findsOneWidget);

    controller.dispose();
  });
}
