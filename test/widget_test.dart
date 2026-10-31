import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bulbeni/main.dart';
import 'package:bulbeni/providers/app_provider.dart';
import 'package:bulbeni/providers/search_provider.dart';
import 'package:bulbeni/providers/library_provider.dart';
import 'package:bulbeni/providers/settings_provider.dart';

void main() {
  testWidgets('BulBeniApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => LibraryProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const BulBeniApp(),
      ),
    );

    expect(find.byType(BulBeniApp), findsOneWidget);
  });
}
