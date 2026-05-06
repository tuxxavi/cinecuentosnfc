import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:nfc_manager/platform_tags.dart';

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
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
        primaryColor: const Color(0xFF4285F4), // Google Blue
        scaffoldBackgroundColor: const Color(0xFFF8FAFA), // Google Drive Light Background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8AB4F8),
        scaffoldBackgroundColor: const Color(0xFF131314), // Google Workspace Dark
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1F20),
          foregroundColor: Color(0xFFE3E3E3),
          elevation: 0,
        ),
        useMaterial3: true,
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
    "01 - Los tres cerditos": 1,
    "02 - Caperucita roja": 2,
    "03 - El patito feo": 3,
    "04 - La ratita presumida": 4,
    "05 - Alicia en el país de las maravillas": 5,
    "06 - El libro de la selva": 6,
    "07 - Pinocho": 7,
    "08 - La Cenicienta": 8,
    "09 - Los músicos de Bremen": 9,
    "10 - Rapunzel": 16,
    "11 - El sodadito de plomo": 17,
    "12 - La Bella Durmiente": 18,
    "13 - Hansel y Gretel": 19,
    "14 - Aladino y la lámpara maravillosa": 20,
    "15 - La Sirenita": 21,
    "16 - El Mago de Oz": 22,
    "17 - El flautista de Hamelín": 23,
    "18 - Blancanieves": 12,
    "19 - La bella y la bestia": 25,
    "20 - La princesa y el guisante": 32,
    "21 - Cuento de Navidad": 33,
    "22 - La reina de las nieves": 34,
    "23 - El gato con botas": 35,
    "24 - El rey Arturo": 36,
    "25 - El cascanueces y el rey de los ratones": 37,
    "26 - Ricitos de oro": 38,
    "27 - El traje nuevo del emperador": 39,
    "28 - El cortador de bambú": 40,
    "29 - Robin Hood": 41,
    "30 - La cigarra y la hormiga": 48,
    "31 - Simbad el marino": 49,
    "32 - Los viajes de Gulliver": 50,
    "33 - La lechera": 51,
    "34 - Alí Babá y los 40 ladrones": 52,
    "35 - Pulgarcito": 53,
    "36 - La liebre y la tortuga": 54,
    "37 - Guillermo Tell": 55,
    "38 - Moby Dick": 34,
    "39 - Juan y las habichuelas mágicas": 57,
    "40 - El lobo y las siete cabritillas": 64,
    "41 - El Enano Saltarín": 65,
    "42 - La leyenda de Sleepy Hollow": 66,
    "43 - El jorobado de Notre Dame": 67,
    "44 - Peter Pan": 68,
    "45 - Heidi": 69,
    "46 - El ratón de campo y el ratón de ciudad": 70,
    "47 - El Sastrecillo Valiente": 71,
    "48 - La Gallina de los Huevos de Oro": 72,
    "49 - El fantasma de Canterville": 73,
    "50 - Ave Fénix": 80,
    "51 - El pescador Taro Urashima": 81,
    "52 - El príncipe y el mendigo": 82,
    "53 - El león y el ratón": 83,
    "54 - Los cisnes salvajes": 84,
    "55 - El ruiseñor": 85,
    "56 - La zorra y las uvas": 86,
    "57 - Juan sin miedo": 87,
    "58 - La pequeña cerillera": 88,
  };

  final Map<String, int> _disneyMap = {
    "201 - rey leon": 201,
    "202 - libro de la selva": 202,
    "203 - Lilo y stich": 203,
    "204 - aladin": 204,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    });
    _checkNfcStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkNfcStatus() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
    });
  }

  static const String baseBlock1Standard = "000000000000022301010100";
  static const String baseBlock1Series200 = "000000000000022301010102";
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

    if (storyValue >= 201 && storyValue <= 204) {
      baseBlock1 = baseBlock1Series200;
      int adjustedValue = storyValue - 200;
      hexValue = adjustedValue.toRadixString(16).padLeft(2, '0').toUpperCase();
    } else {
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

    // Mostrar modal de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF4285F4)),
                const SizedBox(height: 24),
                const Text(
                  "Aproxima la tarjeta para grabar la película",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
              Navigator.of(context).pop(); // Cerrar modal
              throw Exception("Etiqueta no compatible con MIFARE Classic.");
            }

            bool auth = await mifare.authenticateSectorWithKeyA(
              sectorIndex: 0,
              key: Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]),
            );

            if (auth) {
              Uint8List data = _getBlockDataForStory(storyValue);
              await mifare.writeBlock(
                blockIndex: 1,
                data: data,
              );
              NfcManager.instance.stopSession();
              Navigator.of(context).pop(); // Cerrar modal
              Fluttertoast.showToast(msg: "¡Grabado con éxito!");
            } else {
              Navigator.of(context).pop(); // Cerrar modal
              throw Exception("Autenticación fallida.");
            }
          } catch (e) {
            NfcManager.instance.stopSession();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Cerrar modal por seguridad
            }
            Fluttertoast.showToast(msg: "Error al grabar: $e");
          }
        },
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Cerrar modal si algo falla
      }
      Fluttertoast.showToast(msg: "Fallo de conexión NFC.");
    }
  }

  List<String> get _filteredStories {
    final Map<String, int> activeMap =
        _tabController.index == 0 ? _cinecuentosMap : _disneyMap;
    final allNames = activeMap.keys.toList();
    if (_searchQuery.isEmpty) return allNames;
    return allNames
        .where((name) => name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  String get _Query => _searchQuery;
  set _Query(String val) => _searchQuery = val;
  Map<String, int> get _cinecuMap => _cinecuentosMap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storyNames = _filteredStories;

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
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFFB400), size: 18),
              filled: true,
              fillColor: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
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
              color: _isNfcAvailable ? const Color(0xFF34A853) : const Color(0xFFEA4335), // Google Green / Red
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
                    msg: "No se pudieron abrir los ajustes de NFC.");
              }
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: const Color(0xFFFFB400),
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Cambiar Modo de Iluminación',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFFB400),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE50914),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'CineCuentos'),
            Tab(icon: Icon(Icons.star), text: 'Disney'),
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
                  final Map<String, int> activeMap =
                      _tabController.index == 0 ? _cinecuMap : _disneyMap;
                  final storyId = activeMap[name]!;

                  return Card(
                    color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Color(0xFFFFB400), width: 0.5),
                    ),
                    child: ListTile(
                      leading: Text(
                        name.substring(0, 2),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFFE50914),
                        ),
                      ),
                      title: Text(
                        name.substring(5),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: const Icon(Icons.movie, color: Color(0xFFFFB400)),
                      onTap: () {
                        _writeNfcTag(storyId, name);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}