import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CineCuentosNFCApp());
}

class CineCuentosNFCApp extends StatefulWidget {
  const CineCuentosNFCApp({super.key});

  @override
  State<CineCuentosNFCApp> createState() => _CineCuentosNFCAppState();
}

class _CineCuentosNFCAppState extends State<CineCuentosNFCApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineCuentosNFC',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF4285F4),
        scaffoldBackgroundColor: const Color(0xFFF8FAFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF1F1F1F),
          elevation: 1,
          shadowColor: Colors.black12,
        ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFFFF),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8AB4F8),
        scaffoldBackgroundColor: const Color(0xFF131314),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1F20),
          foregroundColor: Color(0xFFE3E3E3),
          elevation: 1,
          shadowColor: Colors.black45,
        ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8AB4F8),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1F20),
        ),
      ),
      home: MainScreen(onToggleTheme: _toggleTheme),
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const MainScreen({super.key, required this.onToggleTheme});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  bool _isNfcAvailable = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  final Map<String, int> _cinecuentosMap = {
    "001 - Los tres cerditos": 1,
    "002 - Caperucita Roja": 2,
    "003 - El patito feo": 3,
    "004 - La ratita presumida": 4,
    "005 - Alicia en el pais de las maravillas": 5,
    "006 - El libro de la selva": 6,
    "007 - Pinocho": 7,
    "008 - La cenicienta": 8,
    "009 - Los musicos de Bremen": 9,
    "010 - Rapunzel": 16,
    "011 - El soldadito de plomo": 17,
    "012 - La bella durmiente": 18,
    "013 - Hansel y Gretel": 19,
    "014 - Aladino y la lampara maravillosa": 20,
    "015 - La sirenita": 21,
    "016 - El mago de oz": 22,
    "017 - El flautista de hamelin": 23,
    "018 - Blancanieves": 24,
    "019 - La bella y la bestia": 25,
    "020 - La princesa y el guisante": 32,
    "021 - Cuento de navidad": 33,
    "022 - La reina de las nieves": 34,
    "023 - El gato con botas": 35,
    "024 - El rey arturo y excalibur": 36,
    "025 - El cascanueces y el rey de los ratones": 37,
    "026 - Ricitos de oro": 38,
    "027 - El traje nuevo del emperador": 39,
    "028 - El cortador de bambu": 40,
    "029 - Robin hood": 41,
    "030 - La cigarra y la hormiga": 48,
    "031 - Simbad el marino": 49,
    "032 - Los viajes de gulliver": 50,
    "033 - La lechera": 51,
    "034 - Ali baba y los 40 ladrones": 52,
    "035 - Pulgarcito": 53,
    "036 - La liebre y la tortuga": 54,
    "037 - Guillermo Tell": 55,
    "038 - Moby Dick": 56,
    "039 - Juan y las habichuelas mágicas": 57,
    "040 - El enano saltarin": 64,
    "041 - El lobo y las 7 cabritillas": 65,
    "042 - El jorobado de Notre Dame": 66,
    "043 - Peter Pan": 97, // 67 dec = 0x43 hex[cite: 1]
    "044 - La leyenda de Pegaso": 68,
    "045 - Heidi": 69,
    "046 - El raton de campo y el raton de ciudad": 70,
    "047 - El sastrecillo valiente": 71,
    "048 - La gallina de los huevos de oro": 72,
    "049 - El fantasma de Canterville": 73,
    "050 - Ave fenix": 80,
    "051 - Atenea y aracne": 81,
    "052 - El pescador Taro Urashima": 82,
    "053 - El zapatero y los duendes": 83,
    "054 - El principe y el mendigo": 84,
    "055 - El leon y el raton": 85,
    "056 - Los cisnes salvajes": 86,
    "057 - El ruiseñor": 87,
    "058 - La zorra y las uvas": 88,
    "059 - Juan sin miedo": 89,
    "060 - La pequeña cerillera": 96,
  };

  final Map<String, int> _disneyMap = {
    "201 - El rey Leon": 201,
    "202 - El Libro de la Selva": 202,
    "203 - Lilo y Stitch": 203,
    "204 - Aladdín": 204,
  };

  // Mapa dinámico para la Serie 300 / Cuentos Personalizados
  final Map<String, int> _serie300Map = {
    "301 - Cuento 301": 301,
    "302 - Cuento 302": 302,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    });
    _loadCustomStories300();
    _checkNfcStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Carga los cuentos persistidos en SharedPreferences
  Future<void> _loadCustomStories300() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storiesJson = prefs.getString('custom_serie_300');
    if (storiesJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(storiesJson);
      setState(() {
        _serie300Map.clear();
        decoded.forEach((key, value) {
          _serie300Map[key] = value as int;
        });
      });
    }
  }

  // Guarda la lista de cuentos personalizados
  Future<void> _saveCustomStories300() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_serie_300', jsonEncode(_serie300Map));
  }

  // Diálogo para Añadir Cuento indicando ID libremente (ej: 062, 205, 301...)
  void _showAddStoryDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1F20) : Colors.white,
          title: Text(
            "Añadir nuevo cuento",
            style: TextStyle(
              color: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFE3E3E3)
                      : const Color(0xFF1F1F1F),
                ),
                decoration: const InputDecoration(
                  labelText: "ID del Cuento",
                  hintText: "Ej. 62, 205, 301...",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFE3E3E3)
                      : const Color(0xFF1F1F1F),
                ),
                decoration: const InputDecoration(
                  labelText: "Nombre del Cuento",
                  hintText: "Ej. Peter Pan 2",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final String idText = idController.text.trim();
                final String nameText = nameController.text.trim();

                if (idText.isNotEmpty && nameText.isNotEmpty) {
                  final int? parsedId = int.tryParse(idText);
                  if (parsedId == null) {
                    Fluttertoast.showToast(
                      msg: "El ID debe ser un número válido.",
                    );
                    return;
                  }

                  // Formatear el prefijo a 3 dígitos (ej: 62 -> 062)
                  final String formattedId = parsedId.toString().padLeft(
                    3,
                    '0',
                  );
                  final String keyName = "$formattedId - $nameText";

                  setState(() {
                    _serie300Map[keyName] = parsedId;
                  });
                  _saveCustomStories300();
                  Navigator.of(context).pop();
                  Fluttertoast.showToast(msg: "Cuento $formattedId añadido.");
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  // Diálogo para Confirmar y Eliminar un cuento de la lista
  void _confirmDeleteStory(String storyKey, String storyName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1F20) : Colors.white,
          title: Text(
            "¿Eliminar cuento?",
            style: TextStyle(
              color: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
            ),
          ),
          content: Text(
            "¿Estás seguro de que deseas eliminar '$storyName'? Esta acción no se puede deshacer.",
            style: TextStyle(
              color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4A4A4A),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA4335),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _serie300Map.remove(storyKey);
                });
                _saveCustomStories300();
                Navigator.of(context).pop();
                Fluttertoast.showToast(msg: "Cuento eliminado correctamente.");
              },
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkNfcStatus() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
    });
  }

  // Constantes de trama base según la carpeta objetivo
  static const String baseBlock1Standard =
      "000000000000022301010100"; // Carpeta 01/
  static const String baseBlock1Series200 =
      "000000000000022301010102"; // Carpeta 02/
  static const String baseBlock1Series300 =
      "000000000000022301010103"; // Carpeta 03/
  static const String block1Trailer = "000000";

  Uint8List _hexToBytes(String hexString) {
    var result = Uint8List(hexString.length ~/ 2);
    for (var i = 0; i < hexString.length; i += 2) {
      result[i ~/ 2] = int.parse(hexString.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  Uint8List _getBlockDataForStory(int storyValue) {
    String hexValue = "";
    String baseBlock1 = "";

    if (storyValue >= 300) {
      // Serie 300+ -> Apunta a Carpeta 03/
      baseBlock1 = baseBlock1Series300;
      int adjustedValue = storyValue >= 301 ? storyValue - 300 : storyValue;
      hexValue = adjustedValue.toRadixString(16).padLeft(2, '0').toUpperCase();
    } else if (storyValue >= 200) {
      // Serie 200 (ej: 205) -> Apunta a Carpeta 02/
      baseBlock1 = baseBlock1Series200;
      int adjustedValue = storyValue - 200;
      hexValue = adjustedValue.toRadixString(16).padLeft(2, '0').toUpperCase();
    } else {
      // Serie Estándar (ej: 062) -> Apunta a Carpeta 01/
      baseBlock1 = baseBlock1Standard;
      hexValue = storyValue.toRadixString(16).padLeft(2, '0').toUpperCase();
    }

    String hexString = "$baseBlock1$hexValue$block1Trailer";
    return _hexToBytes(hexString);
  }

  Future<void> _writeNfcTag(int storyValue, String storyName) async {
    await _checkNfcStatus();
    if (!_isNfcAvailable) {
      Fluttertoast.showToast(msg: "Activa el NFC en tu dispositivo.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark
              ? const Color(0xFF1E1F20)
              : const Color(0xFFFFFFFF),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF4285F4)),
                const SizedBox(height: 24),
                Text(
                  "Aproxima la tarjeta para grabar la película",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFE3E3E3)
                        : const Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  storyName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            var mifare = MifareClassic.from(tag);
            if (mifare == null) {
              Navigator.of(context).pop();
              throw Exception("Etiqueta no compatible con MIFARE Classic.");
            }

            bool auth = await mifare.authenticateSectorWithKeyA(
              sectorIndex: 0,
              key: Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
            );

            if (auth) {
              Uint8List data = _getBlockDataForStory(storyValue);
              await mifare.writeBlock(blockIndex: 1, data: data);
              NfcManager.instance.stopSession();
              Navigator.of(context).pop();
              Fluttertoast.showToast(msg: "¡Grabado con éxito!");
            } else {
              Navigator.of(context).pop();
              throw Exception("Autenticación fallida.");
            }
          } catch (e) {
            NfcManager.instance.stopSession();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            Fluttertoast.showToast(msg: "Error al grabar: $e");
          }
        },
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      Fluttertoast.showToast(msg: "Fallo de conexión NFC.");
    }
  }

  Map<String, int> get _activeMap {
    if (_tabController.index == 0) return _cinecuentosMap;
    if (_tabController.index == 1) return _disneyMap;
    return _serie300Map;
  }

  List<String> get _filteredStories {
    final allNames = _activeMap.keys.toList();
    if (_searchQuery.isEmpty) return allNames;
    return allNames
        .where(
          (name) => name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storyNames = _filteredStories;
    final bool isSerie300 = _tabController.index == 2;

    final Color itemColor = _tabController.index == 0
        ? const Color(0xFF4285F4)
        : (_tabController.index == 1
              ? const Color(0xFFFBBC04)
              : const Color(0xFF34A853));

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(
              color: isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: Icon(Icons.search, color: itemColor, size: 18),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2E3133)
                  : const Color(0xFFF1F3F4),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.nfc,
              color: _isNfcAvailable
                  ? const Color(0xFF34A853)
                  : const Color(0xFFEA4335),
            ),
            tooltip: 'Ir a los ajustes de NFC',
            onPressed: () async {
              try {
                const AndroidIntent intent = AndroidIntent(
                  action: 'android.settings.NFC_SETTINGS',
                );
                await intent.launch();
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "No se pudieron abrir los ajustes de NFC.",
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: itemColor,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Cambiar Modo de Iluminación',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: itemColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: itemColor,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'CineCuentos'),
            Tab(icon: Icon(Icons.star), text: 'Disney'),
            Tab(icon: Icon(Icons.video_library), text: 'Serie 300'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: storyNames.length,
                itemBuilder: (context, index) {
                  final name = storyNames[index];
                  final storyId = _activeMap[name]!;

                  return Card(
                    color: isDark
                        ? const Color(0xFF1E1F20)
                        : const Color(0xFFFFFFFF),
                    elevation: isDark ? 0 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF333333)
                            : const Color(0xFFE0E0E0),
                        width: 1.0,
                      ),
                    ),
                    child: ListTile(
                      leading: Text(
                        name.contains(' - ')
                            ? name.split(' - ')[0]
                            : name.substring(0, 3),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: itemColor,
                        ),
                      ),
                      title: Text(
                        name.contains(' - ') ? name.split(' - ')[1] : name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFFE3E3E3)
                              : const Color(0xFF1F1F1F),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSerie300)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Color(0xFFEA4335),
                              ),
                              tooltip: "Eliminar cuento",
                              onPressed: () {
                                _confirmDeleteStory(name, name);
                              },
                            ),
                          Icon(Icons.movie, color: itemColor),
                        ],
                      ),
                      onTap: () {
                        _writeNfcTag(storyId, name);
                      },
                      onLongPress: isSerie300
                          ? () {
                              _confirmDeleteStory(name, name);
                            }
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSerie300
          ? FloatingActionButton(
              onPressed: _showAddStoryDialog,
              backgroundColor: const Color(0xFF34A853),
              tooltip: "Añadir nuevo cuento",
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
