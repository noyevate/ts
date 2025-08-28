// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';

// import 'package:ts/constnts/r_text.dart';

// class SpeechToPdfPage extends StatefulWidget {
//   const SpeechToPdfPage({super.key});

//   @override
//   _SpeechToPdfPageState createState() => _SpeechToPdfPageState();
// }

// class _SpeechToPdfPageState extends State<SpeechToPdfPage>
//     with SingleTickerProviderStateMixin {
//   stt.SpeechToText _speech = stt.SpeechToText();
//   bool _isListening = false;
//   String _speechText = "";

//   // 🎵 Waveform animation
//   late AnimationController _waveController;
//   late Animation<double> _waveAnimation;
//   Timer? _waveTimer;

//   @override
//   void initState() {
//     super.initState();
//     _waveController =
//         AnimationController(vsync: this, duration: Duration(milliseconds: 500));
//     _waveAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
//       CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
//     );
//   }

//   void _startListening() async {
//     bool available = await _speech.initialize();
//     if (available) {
//       setState(() {
//         _isListening = true;
//       });
//       _waveController.repeat(reverse: true); // start waveform animation
//       _speech.listen(onResult: (val) {
//         setState(() {
//           _speechText = val.recognizedWords;
//         });
//       });
//     }
//   }

//   void _stopListening() {
//     _speech.stop();
//     setState(() {
//       _isListening = false;
//     });
//     _waveController.stop(); // stop waveform
//   }

//   Future<void> _saveAsPdf() async {
//     final pdf = pw.Document();
//     pdf.addPage(pw.Page(
//       build: (pw.Context context) => pw.Center(
//         child: pw.Text(_speechText),
//       ),
//     ));

//     final dir = await getExternalStorageDirectory(); // works on APK
//     final file = File("${dir!.path}/speech_text.pdf");
//     await file.writeAsBytes(await pdf.save());

//     setState(() {
//       _speechText = ""; // reset after saving
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: RText(title: "PDF saved at ${file.path}", style: TextStyle(color: Colors.white),)),
//     );
//   }

//   @override
//   void dispose() {
//     _waveController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Speech to PDF")),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           ScaleTransition(
//             scale: _waveAnimation,
//             child: Icon(
//               Icons.mic,
//               size: 80,
//               color: _isListening ? Colors.red : Colors.grey,
//             ),
//           ),
//           SizedBox(height: 20),
//           Text(
//             _speechText,
//             style: TextStyle(fontSize: 18),
//           ),
//           SizedBox(height: 20),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               FloatingActionButton(
//                 backgroundColor: _isListening ? Colors.red : Colors.blue,
//                 child: Icon(_isListening ? Icons.stop : Icons.mic),
//                 onPressed: () {
//                   if (_isListening) {
//                     _stopListening();
//                   } else {
//                     _startListening();
//                   }
//                 },
//               ),
//               SizedBox(width: 20),
//               ElevatedButton.icon(
//                 icon: Icon(Icons.picture_as_pdf),
//                 label: RText(title: "Export to PDF", style: TextStyle(color: Colors.black),),
//                 onPressed: _speechText.isNotEmpty ? _saveAsPdf : null,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:google_speech/google_speech.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter/services.dart' show rootBundle;

// class SpeechToPdfPage extends StatefulWidget {
//   const SpeechToPdfPage({Key? key}) : super(key: key);

//   @override
//   State<SpeechToPdfPage> createState() => _SpeechToPdfPageState();
// }

// class _SpeechToPdfPageState extends State<SpeechToPdfPage> {
//   bool _isListening = false;
//   String _transcription = "";
//   late SpeechToText _speechToText;
//   StreamingRecognitionConfig? _config;

//   @override
//   void initState() {
//     super.initState();
//     _initSpeech();
//   }

//   Future<void> _initSpeech() async {
//     // Request permissions
//     await Permission.microphone.request();
//     await Permission.storage.request();

//     // Load your Google service account key JSON
//     final serviceAccount = ServiceAccount.fromString(
//       (await rootBundle.loadString('assets/your-service-account.json')),
//     );

//     final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
//     setState(() {
//       _speechToText = speechToText;
//     });

//     _config = StreamingRecognitionConfig(
//       config: RecognitionConfig(
//         encoding: AudioEncoding.LINEAR16,
//         model: RecognitionModel.basic,
//         enableAutomaticPunctuation: true,
//         sampleRateHertz: 16000,
//         languageCode: 'en-US',
//       ),
//       interimResults: true,
//     );
//   }

//   Future<void> _startListening() async {
//     if (_isListening) return;
//     setState(() => _isListening = true);

//     await _speechToText.streamingRecognize(
//       _config!,
//       onData: (data) {
//         setState(() {
//           _transcription = data.results.map((r) => r.alternatives.first.transcript).join("\n");
//         });
//       },
//       onError: (e) {
//         debugPrint("Error: $e");
//         setState(() => _isListening = false);
//       },
//     );
//   }

//   void _stopListening() {
//     _speechToText.stop();
//     setState(() => _isListening = false);
//   }

//   Future<void> _exportToPdf() async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) => pw.Text(_transcription),
//       ),
//     );

//     final dir = await getExternalStorageDirectory();
//     final file = File("${dir!.path}/speech_transcript.pdf");
//     await file.writeAsBytes(await pdf.save());

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("PDF saved at: ${file.path}")),
//     );

//     // clear after export
//     setState(() {
//       _transcription = "";
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Speech to PDF")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Text(
//                     _transcription.isEmpty ? "Say something..." : _transcription,
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _isListening ? _stopListening : _startListening,
//                   icon: Icon(_isListening ? Icons.stop : Icons.mic),
//                   label: Text(_isListening ? "Stop" : "Start"),
//                 ),
//                 const SizedBox(width: 20),
//                 ElevatedButton.icon(
//                   onPressed: _transcription.isNotEmpty ? _exportToPdf : null,
//                   icon: const Icon(Icons.picture_as_pdf),
//                   label: const Text("Export to PDF"),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
// CHANGED: Added a prefix to resolve the name collision
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart' as speech_proto;
import 'package:sound_stream/sound_stream.dart'; // CHANGE: Import sound_stream

class SpeechToPdfPage extends StatefulWidget {
  const SpeechToPdfPage({Key? key}) : super(key: key);

  @override
  State<SpeechToPdfPage> createState() => _SpeechToPdfPageState();
}

class _SpeechToPdfPageState extends State<SpeechToPdfPage> {
  bool _isListening = false;
  String _transcription = "";
  late SpeechToText _speechTotext;
  StreamingRecognitionConfig? _config;


  final RecorderStream _recorder = RecorderStream();
StreamSubscription<speech_proto.StreamingRecognizeResponse>? _responseSubscription;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _recorder.initialize();
  }

  // @override
  // void dispose() {
  //   // Clean up resources
  //   _audioStreamSubscription?.cancel();
  //   _recorder.stop(); // Stop the recorder on dispose
  //   super.dispose();
  // }

  Future<void> _initSpeech() async {
    // ... (This function remains exactly the same)
    await [Permission.microphone, Permission.storage].request();
    final serviceAccount = ServiceAccount.fromString(
      (await rootBundle.loadString('assets/keys/chop-nowt-511622fb9580.json')),
    );
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    setState(() {
      _speechTotext = speechToText;
    });
    _config = StreamingRecognitionConfig(
      config: RecognitionConfig(
        encoding: AudioEncoding.LINEAR16,
        model: RecognitionModel.basic,
        enableAutomaticPunctuation: true,
        sampleRateHertz: 16000,
        languageCode: 'en-US',
      ),
      interimResults: true,
    );
  }


Future<void> _startListening() async {
  if (_isListening) return;
  setState(() => _isListening = true);

  // Start the recording
  await _recorder.start();

  // Pass the audio stream directly to the streamingRecognize method
  final responseStream = _speechTotext.streamingRecognize(_config!, _recorder.audioStream);

  // Listen directly to the stream of responses
  _responseSubscription = responseStream.listen(
    (data) {
      // Update the transcription with the latest results
      setState(() {
        _transcription = data.results.map((e) => e.alternatives.first.transcript).join('\n');
      });
    },
    onError: (e) {
      debugPrint("Error: $e");
      _stopListening();
    },
    onDone: () {
      debugPrint("Stream closed by API.");
      if (_isListening) {
        _stopListening();
      }
    },
  );
}

void _stopListening() async {
  await _recorder.stop();
  await _responseSubscription?.cancel(); 
  if (mounted) {
    setState(() => _isListening = false);
  }
}

@override
void dispose() {
  _responseSubscription?.cancel(); 
  _recorder.stop();
  super.dispose();
}

  // // CHANGE: This whole function is updated to use sound_stream
  // void _stopListening() async {
  //   await _recorder.stop();
  //   await _audioStreamSubscription?.cancel();
  //   if (mounted) {
  //     setState(() => _isListening = false);
  //   }
  // }

  // Future<void> _exportToPdf() async {
  //   if (_transcription.isEmpty) return;
    
  //   final pdf = pw.Document();
  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) => pw.Padding(
  //         padding: const pw.EdgeInsets.all(20),
  //         child: pw.Text(_transcription),
  //       ),
  //     ),
  //   );

    

  //   try {
  //     final dir = await getExternalStorageDirectory();
  //     if (dir != null) {
  //       final file = File("${dir.path}/speech_transcript.pdf");
  //       await file.writeAsBytes(await pdf.save());
  //       print(_transcription);

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("PDF saved at: ${file.path}")),
  //       );
  //        // Clear after export
  //       setState(() {
  //         _transcription = "";
  //       });
  //     }
  //   } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Error saving PDF: $e")),
  //       );
  //   }
  // }

  Future<void> _exportToPdf() async {
  if (_transcription.isEmpty) return;

  // Ask user for file name
  final TextEditingController nameController = TextEditingController();
  final String? customName = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Save PDF"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Enter file name",
            hintText: "e.g. meeting_notes",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(nameController.text.trim());
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );

  if (customName == null || customName.isEmpty) return;

  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Padding(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text(_transcription),
      ),
    ),
  );
  print(_transcription);

  try {
    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      // Use custom filename (with .pdf extension if missing)
      final fileName = customName.endsWith(".pdf") ? customName : "$customName.pdf";
      final file = File("${dir.path}/$fileName");

      await file.writeAsBytes(await pdf.save());
      print("Saved: $fileName");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF saved as: $fileName")),
      );

      // Clear after export
      setState(() {
        _transcription = "";
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error saving PDF: $e")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Speech to PDF"), backgroundColor: Colors.white,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      _transcription.isEmpty ? "Press 'Start' and begin speaking..." : _transcription,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(_isListening ? Icons.stop_circle_outlined : Icons.mic),
                  label: Text(_isListening ? "Stop" : "Start"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.redAccent : Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _transcription.isNotEmpty ? _exportToPdf : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export PDF"),
                   style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}