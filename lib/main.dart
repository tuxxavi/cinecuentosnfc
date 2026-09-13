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
        primaryColor: const Color(0xFF4285F4), // Google Blue
        scaffoldBackgroundColor: const Color(
          0xFFF8FAFA,
        ), // Google Drive Light Background
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
        primaryColor: const Color(0xFF8AB4F8), // Google Light Blue
        scaffoldBackgroundColor: const Color(
          0xFF131314,
        ), // Google Workspace Dark
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
    "001 - Los tres cerditos": 1, // 0x01
    "002 - Caperucita Roja": 2, // 0x02
    "003 - El patito feo": 3, // 0x03
    "004 - La ratita presumida": 4, // 0x04
    "005 - Alicia en el pais de las maravillas": 5, // 0x05
    "006 - El libro de la selva": 6, // 0x06
    "007 - Pinocho": 7, // 0x07
    "008 - La cenicienta": 8, // 0x08
    "009 - Los musicos de Bremen": 9, // 0x09
    "010 - Rapunzel": 16, // 0x10
    "011 - El soldadito de plomo": 17, // 0x11
    "012 - La bella durmiente": 18, // 0x12
    "013 - Hansel y Gretel": 19, // 0x13
    "014 - Aladino y la lampara maravillosa": 20, // 0x14
    "015 - La sirenita": 21, // 0x15
    "016 - El mago de oz": 22, // 0x16
    "017 - El flautista de hamelin": 23, // 0x17
    "018 - Blancanieves": 24, // 0x18
    "019 - La bella y la bestia": 25, // 0x19
    "020 - La princesa y el guisante": 32, // 0x20
    "021 - Cuento de navidad": 33, // 0x21
    "022 - La reina de las nieves": 34, // 0x22
    "023 - El gato con botas": 35, // 0x23
    "024 - El rey arturo y excalibur": 36, // 0x24
    "025 - El cascanueces y el rey de los ratones": 37, // 0x25
    "026 - Ricitos de oro": 38, // 0x26
    "027 - El traje nuevo del emperador": 39, // 0x27
    "028 - El cortador de bambu": 40, // 0x28
    "029 - Robin hood": 41, // 0x29
    "030 - La cigarra y la hormiga": 48, // 0x30
    "031 - Simbad el marino": 49, // 0x31
    "032 - Los viajes de gulliver": 50, // 0x32
    "033 - La lechera": 51, // 0x33
    "034 - Ali baba y los 40 ladrones": 52, // 0x34
    "035 - Pulgarcito": 53, // 0x35
    "036 - La liebre y la tortuga": 54, // 0x36
    "037 - Guillermo Tell": 55, // 0x37
    "038 - Moby Dick": 56, // 0x38
    "039 - Juan y las habichuelas mágicas": 57, // 0x39
    "040 - El enano saltarin": 64, // 0x40
    "041 - El lobo y las 7 cabritillas": 65, // 0x41
    "042 - El jorobado de Notre Dame": 66, // 0x42
    "043 - Peter Pan": 67, // 0x43
    "044 - La leyenda de Pegaso": 68, // 0x44
    "045 - Heidi": 69, // 0x45
    "046 - El raton de campo y el raton de ciudad": 70, // 0x46
    "047 - El sastrecillo valiente": 71, // 0x47
    "048 - La gallina de los huevos de oro": 72, // 0x48
    "049 - El fantasma de Canterville": 73, // 0x49
    "050 - Ave fenix": 80, // 0x50
    "051 - Atenea y aracne": 81, // 0x51
    "052 - El pescador Taro Urashima": 82, // 0x52
    "053 - El zapatero y los duendes": 83, // 0x53
    "054 - El principe y el mendigo": 84, // 0x54
    "055 - El leon y el raton": 85, // 0x55
    "056 - Los cisnes salvajes": 86, // 0x56
    "057 - El ruiseñor": 87, // 0x57
    "058 - La zorra y las uvas": 88, // 0x58
    "059 - Juan sin miedo": 89, // 0x59
    "060 - La pequeña cerillera": 96, // 0x60
  };

  final Map<String, int> _disneyMap = {
    "201 - El rey Leon": 201, // Serie 200 -> 0x01
    "202 - El Libro de la Selva": 202, // Serie 200 -> 0x02
    "203 - Lilo y Stitch": 203, // Serie 200 -> 0x03
    "204 - Aladdín": 204, // Serie 200 -> 0x04
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

    // Modal de espera personalizado
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

  List<String> get _filteredStories {
    final Map<String, int> activeMap = _tabController.index == 0
        ? _cinecuentosMap
        : _disneyMap;
    final allNames = activeMap.keys.toList();
    if (_searchQuery.isEmpty) return allNames;
    return allNames
        .where(
          (name) => name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  String get _Query => _searchQuery;
  set _Query(String val) => _searchQuery = val;
  Map<String, int> get _cinecuMap => _cinecuentosMap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storyNames = _filteredStories;

    // Colores según la pestaña activa: Azul para CineCuentos, Amarillo para Disney
    final bool isCinecuentos = _tabController.index == 0;
    final Color itemColor = isCinecuentos
        ? const Color(0xFF4285F4) // Google Blue
        : const Color(0xFFFBBC04); // Google Yellow

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
                  final Map<String, int> activeMap = _tabController.index == 0
                      ? _cinecuMap
                      : _disneyMap;
                  final storyId = activeMap[name]!;

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
                        name.substring(0, 2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: itemColor,
                        ),
                      ),
                      title: Text(
                        name.substring(5),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFFE3E3E3)
                              : const Color(0xFF1F1F1F),
                        ),
                      ),
                      trailing: Icon(Icons.movie, color: itemColor),
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

extension on MainScreen {
  VoidCallback get ToggleTheme => onToggleTheme;
}
