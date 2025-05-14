import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // creación y apertura de la base de datos
  final database = await openDatabase(
    join(await getDatabasesPath(), 'movimientos.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE movimientos(id INTEGER PRIMARY KEY, descripcion TEXT, monto REAL, tipo TEXT, categoria TEXT, fecha TEXT)',
      );
    },
    version: 1,
  );
  runApp(GastosApp(database: database));
}

// clase principal de la app
class GastosApp extends StatelessWidget {
  final Database database;

  GastosApp({required this.database});

//establece disenios de la app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Gastos',
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(239, 21, 106, 139)),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 14.0, color: Colors.grey),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black12),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color.fromARGB(239, 21, 106, 139)),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(color: Color.fromARGB(239, 21, 106, 139)),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color.fromARGB(239, 21, 106, 139),
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color.fromARGB(239, 21, 106, 139),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
            elevation: 0,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(239, 21, 106, 139),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 3,
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(Color.fromARGB(239, 21, 106, 139)),
        ),
        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: const Color.fromARGB(239, 21, 106, 139),
          headerForegroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600
          ),
          iconTheme: IconThemeData(color: Colors.black87)
        )
      ),
      home: HomeScreen(database: database),
    );
  }
}

// clase para la pantalla de inicio
class HomeScreen extends StatefulWidget {
  final Database database;
  HomeScreen({required this.database});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movimiento> _movimientos = [];
  double _totalSaldo = 0;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  // metodo para cargar los movimientos desde la bbdd
  Future<void> _cargarMovimientos() async {
    final List<Map<String, dynamic>> movimientosMap = await widget.database.query('movimientos');
    _movimientos = movimientosMap.map((map) => Movimiento.fromMap(map)).toList();
    _calcularTotalSaldo();
    setState(() {});
  }

  // metodo para calcular el saldo total
  void _calcularTotalSaldo() {
    _totalSaldo = _movimientos.fold(0, (sum, movimiento) {
      if (movimiento.tipo == 'gasto') {
        return sum - movimiento.monto;
      } else {
        return sum + movimiento.monto;
      }
    });
  }

  // metodo para agregar un nuevo movimiento
  Future<void> _agregarNuevoMovimiento(BuildContext context) async {
    final nuevoMovimiento = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AgregarMovimientoScreen(database: widget.database)),
    );
    if (nuevoMovimiento != null) {
      // inserta el nuevo movimiento en la bbdd y recarga la lista
      await widget.database.insert('movimientos', nuevoMovimiento.toMap());
      await _cargarMovimientos();
    }
  }

  // metodo para editar un gasto existente
  Future<void> _editarMovimiento(BuildContext context, Movimiento movimiento) async {
    final movimientoActualizado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarMovimientoScreen(database: widget.database, movimiento: movimiento)),
    );
    if (movimientoActualizado != null) {
      // actualiza el movimiento en la bbdd y recarga la lista
      await widget.database.update(
        'movimientos',
        movimientoActualizado.toMap(),
        where: 'id = ?',
        whereArgs: [movimientoActualizado.id],
      );
      await _cargarMovimientos();
    }
  }

  // metodo para eliminar un gasto
  Future<void> _eliminarGasto(Movimiento movimiento) async {
    bool? confirmar = await showDialog<bool>(
      // muestra un dialogo de confirmación
      context: this.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este movimiento?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Eliminar', style: TextStyle(color: Colors.red[400])),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      // Si el usuario confirma la eliminación, elimina el movimiento de la bbdd y recarga la lista
      await widget.database.delete(
        'movimientos',
        where: 'id = ?',
        whereArgs: [movimiento.id],
      );
      await _cargarMovimientos();
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text('Movimiento eliminado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Gastos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Resumen de Saldo',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_totalSaldo.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        color: _totalSaldo >= 0 ? Colors.green[300] : Colors.red[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _movimientos.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no hay movimientos registrados. ¡Agrega uno!',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _movimientos.length,
                      itemBuilder: (context, index) {
                        final movimiento = _movimientos[index];
                        return GestureDetector(
                          onTap: () => _editarMovimiento(context, movimiento),
                          child: MovimientoCard(
                            movimiento: movimiento,
                            onEliminar: () => _eliminarGasto(movimiento),
                            dateFormat: _dateFormat,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _agregarNuevoMovimiento(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// widget para mostrar la tarjeta de cada movimiento
class MovimientoCard extends StatelessWidget {
  final Movimiento movimiento;
  final VoidCallback onEliminar;
  final DateFormat dateFormat;

  const MovimientoCard({Key? key, required this.movimiento, required this.onEliminar, required this.dateFormat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  movimiento.descripcion,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  movimiento.categoria,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(movimiento.fecha),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              ],
            ),
            Row(
              children: [
                Text(
                  '\$${movimiento.monto.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, color: movimiento.tipo == 'gasto' ? Colors.red[300] : Colors.green[300], fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[400]),
                  onPressed: onEliminar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// clase para la pantalla de agregar movimiento
class AgregarMovimientoScreen extends StatefulWidget {
  final Database database;

  AgregarMovimientoScreen({required this.database});

  @override
  _AgregarMovimientoScreenState createState() => _AgregarMovimientoScreenState();
}

class _AgregarMovimientoScreenState extends State<AgregarMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();
  String _tipoMovimiento = 'gasto';
  String? _categoria;
  DateTime _fecha = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  List<String> _categorias = [];

  // mapas de categorías para gastos e ingresos
  final Map<String, List<String>> _categoriasPorTipo = {
    'gasto': ['Comida', 'Transporte', 'Ocio', 'Servicios', 'Otros'],
    'ingreso': ['Salario', 'Bonificaciones', 'Inversiones', 'Ventas', 'Otros'],
  };

  @override
  void initState() {
    super.initState();
    // inicializa las categorias segun el tipo de movimiento inicial
    _categorias = _categoriasPorTipo[_tipoMovimiento]!;
  }

  // metodo para seleccionar la fecha
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fecha) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Nuevo Movimiento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el monto';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null) {
                    return 'Por favor, ingresa un número válido';
                  }
                   if (monto <= 0) {
                    return 'Por favor, ingresa un número mayor que cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Radio<String>(
                    value: 'gasto',
                    groupValue: _tipoMovimiento,
                    onChanged: (String? value) {
                      setState(() {
                        _tipoMovimiento = value!;
                        _categorias = _categoriasPorTipo[_tipoMovimiento]!;
                        _categoria = null;
                      });
                    },
                  ),
                  const Text('Gasto'),
                  Radio<String>(
                    value: 'ingreso',
                    groupValue: _tipoMovimiento,
                    onChanged: (String? value) {
                      setState(() {
                        _tipoMovimiento = value!;
                        _categorias = _categoriasPorTipo[_tipoMovimiento]!;
                        _categoria = null;
                      });
                    },
                  ),
                  const Text('Ingreso'),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría'),
                value: _categoria,
                items: _categorias.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoria = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Text(
                    'Fecha: ${_dateFormat.format(_fecha)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _seleccionarFecha(context),
                    child: const Text('Seleccionar Fecha'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final nuevoMovimiento = Movimiento(
                      id: null,
                      descripcion: _descripcionController.text,
                      monto: double.parse(_montoController.text),
                      categoria: _categoria!,
                      fecha: _fecha,
                      tipo: _tipoMovimiento,
                    );
                    Navigator.pop(context, nuevoMovimiento);
                  }
                },
                child: const Text('Guardar Movimiento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }
}

// clase para la pantalla de editar movimiento
class EditarMovimientoScreen extends StatefulWidget {
  final Database database;
  final Movimiento movimiento;

  EditarMovimientoScreen({required this.database, required this.movimiento});

  @override
  _EditarMovimientoScreenState createState() => _EditarMovimientoScreenState();
}

class _EditarMovimientoScreenState extends State<EditarMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();
  String? _categoria;
  DateTime _fecha = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  String _tipoMovimiento = 'gasto';
  List<String> _categorias = [];

  // Mapas de categorías para gastos e ingresos
  final Map<String, List<String>> _categoriasPorTipo = {
    'gasto': ['Comida', 'Transporte', 'Ocio', 'Servicios', 'Otros'],
    'ingreso': ['Salario', 'Bonificaciones', 'Inversiones', 'Ventas', 'Otros'],
  };

  @override
  void initState() {
    super.initState();
    _descripcionController.text = widget.movimiento.descripcion;
    _montoController.text = widget.movimiento.monto.toString();
    _categoria = widget.movimiento.categoria;
    _fecha = widget.movimiento.fecha;
    _tipoMovimiento = widget.movimiento.tipo;
    _categorias = _categoriasPorTipo[_tipoMovimiento]!;
  }

  // metodo para seleccionar la fecha
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fecha) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Movimiento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el monto';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null) {
                    return 'Por favor, ingresa un número válido';
                  }
                   if (monto <= 0) {
                    return 'Por favor, ingresa un número mayor que cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Radio<String>(
                    value: 'gasto',
                    groupValue: _tipoMovimiento,
                    onChanged: (String? value) {
                      setState(() {
                        _tipoMovimiento = value!;
                        _categorias = _categoriasPorTipo[_tipoMovimiento]!;
                        _categoria = null;
                      });
                    },
                  ),
                  const Text('Gasto'),
                  Radio<String>(
                    value: 'ingreso',
                    groupValue: _tipoMovimiento,
                    onChanged: (String? value) {
                      setState(() {
                        _tipoMovimiento = value!;
                        _categorias = _categoriasPorTipo[_tipoMovimiento]!;
                        _categoria = null;
                      });
                    },
                  ),
                  const Text('Ingreso'),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría'),
                value: _categoria,
                items: _categorias.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoria = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Text(
                    'Fecha: ${_dateFormat.format(_fecha)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _seleccionarFecha(context),
                    child: const Text('Seleccionar Fecha'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final gastoActualizado = Movimiento(
                      id: widget.movimiento.id,
                      descripcion: _descripcionController.text,
                      monto: double.parse(_montoController.text),
                      tipo: _tipoMovimiento,
                      categoria: _categoria!,
                      fecha: _fecha,
                    );
                    Navigator.pop(context, gastoActualizado);
                  }
                },
                child: const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }
}

// clase para el modelo de datos de Movimiento
class Movimiento {
  int? id;
  String descripcion;
  double monto;
  String tipo;
  String categoria;
  DateTime fecha;
 

  Movimiento({this.id, required this.descripcion, required this.categoria, required this.monto, required this.fecha, required this.tipo});

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'],
      descripcion: map['descripcion'],
      monto: map['monto'],
      tipo: map['tipo'],
      categoria: map['categoria'],
      fecha: DateTime.parse(map['fecha']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'monto': monto,
      'tipo': tipo,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(),
    };
  }
}