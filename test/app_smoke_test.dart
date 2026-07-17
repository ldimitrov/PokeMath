import 'package:flutter_test/flutter_test.dart';
import 'package:pokemath/db/database_helper.dart';
import 'package:pokemath/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseHelper.dbName = 'pokemath_smoke_test.db';
  });

  testWidgets('App startet und zeigt die Profilauswahl', (tester) async {
    // runAsync, damit die echte sqflite-I/O im Test abgeschlossen werden kann.
    await tester.runAsync(() async {
      await tester.pumpWidget(const PokeMathApp());
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    expect(find.text('PokeMath'), findsOneWidget);
    expect(find.text('Neues Profil'), findsOneWidget);
  });
}
