import 'dart:typed_data';
import 'package:metadata_god/metadata_god.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  try{
  WidgetsFlutterBinding.ensureInitialized();
  await MetadataGod.initialize();
  runApp(const MyApp());
  } catch (e) {
    print('Error al inicializar MetadataGod: $e');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reproductor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent
      ),
      home: const MusicPlayerPage(title: 'Hola'),
    );
  }
}

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key, required this.title});
  final String title;

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentSong;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Uint8List? _albumArt;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    
    _audioPlayer.setVolume(_volume);
    // Escucha los cambios de duración
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    // Escucha los cambios de posición
    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });
  }


  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3','m4a','wav','flac','ogg','aac', 'aiff'],
    );

    if (result != null) {
      final path = result.files.single.path!;
      setState(() {
        _currentSong = path;
      });
      
      // Obtener metadatos
      try {
        final metadata = await MetadataGod.readMetadata(file: path);
        setState(() {
          if (metadata.picture != null) {
            _albumArt = metadata.picture?.data;
          }
        });
      } catch (e) {
        print('Error al cargar metadatos: $e');
      }

      await _audioPlayer.play(DeviceFileSource(_currentSong!));
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade800,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                    Text(
                      'REPRODUCIENDO',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              
              // Área de la carátula
              Expanded(
                child: Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white24,
                      image: _albumArt != null
                        ? DecorationImage(
                            image: MemoryImage(_albumArt!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    ),
                        child: _albumArt == null
                            ? const Icon(
                                Icons.music_note,
                                size: 100,
                                color: Colors.white54,
                                )
                              : null,
                        ),
                ),
              ),
              
              // Información de la canción
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _currentSong?.split('/').last ?? 'No hay canción seleccionada',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Artista desconocido',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Barra de progreso
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: Colors.white,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        value: _position.inSeconds.toDouble(),
                        onChanged: (value) async {
                          final position = Duration(seconds: value.toInt());
                          await _audioPlayer.seek(position);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatTime(_position),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            formatTime(_duration),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Control de volumen
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 0),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down, 
                      color: Colors.white, 
                      size: 20,  // Icono más pequeño
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                          thumbColor: Colors.white,
                          trackHeight: 2,  // Altura más delgada
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,  // Thumb más pequeño
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,  // Área de toque más pequeña
                          ),
                        ),
                        child: Slider(
                          min: 0.0,
                          max: 1.0,
                          value: _volume,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                              _audioPlayer.setVolume(_volume);
                            });
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.volume_up, 
                      color: Colors.white, 
                      size: 20,  // Icono más pequeño
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),  // Espacio reducido después de la barra

              // Controles de reproducción
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () {},
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        iconSize: 32,
                        color: Colors.blue.shade800,
                        onPressed: () {
                          if (_currentSong != null) {
                            setState(() {
                              if (_isPlaying) {
                                _audioPlayer.pause();
                              } else {
                                _audioPlayer.resume();
                              }
                              _isPlaying = !_isPlaying;
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.repeat),
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        tooltip: 'Seleccionar canción',
        child: const Icon(Icons.add),
      ),
    );
  }
}