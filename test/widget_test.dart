// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:control_gastos/main.dart';

void main() {
  testWidgets('Prueba de la pantalla de inicio', (WidgetTester tester) async {

    final database = await openDatabase(
      inMemoryDatabasePath,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE gastos(id INTEGER PRIMARY KEY, descripcion TEXT, categoria TEXT, monto REAL, fecha TEXT)',
        );
      },
      version: 1,
    );

    // Construye la aplicación con la base de datos en memoria
    await tester.pumpWidget(GastosApp(database: database)); // Remueve 'const'

    // Verifica que se muestre el título de la aplicación
    expect(find.text('Control de Gastos'), findsOneWidget);

    // Puedes agregar más pruebas aquí para verificar otros elementos de la UI
    // Por ejemplo, verificar la presencia de la lista de gastos, el resumen, etc.

    // Cierra la base de datos después de la prueba
    await database.close();
  });
}
