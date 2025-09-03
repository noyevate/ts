import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
// CHANGED: Added a prefix to resolve the name collision
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart'
    as speech_proto;
import 'package:sound_stream/sound_stream.dart'; // CHANGE: Import sound_stream

class SpeechToPdfPage extends StatefulWidget {
  const SpeechToPdfPage({Key? key}) : super(key: key);

  @override
  State<SpeechToPdfPage> createState() => _SpeechToPdfPageState();
}

class _SpeechToPdfPageState extends State<SpeechToPdfPage> {
  bool _isListening = false;
  String _transcription = "";

  String _finalTranscription = "";

  late SpeechToText _speechTotext;
  StreamingRecognitionConfig? _config;

  final RecorderStream _recorder = RecorderStream();
  StreamSubscription<speech_proto.StreamingRecognizeResponse>?
      _responseSubscription;

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
    await [Permission.microphone, Permission.storage].request();
    final serviceAccount = ServiceAccount.fromString(
      (await rootBundle.loadString('assets/keys/chop-nowt-078b693b081d.json')),
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

  setState(() {
    _transcription = "";
    _finalTranscription = "";
  });

  setState(() => _isListening = true);

  await _recorder.start();
  final responseStream = _speechTotext.streamingRecognize(_config!, _recorder.audioStream);

  _responseSubscription = responseStream.listen(
    (data) {
      final StringBuffer interimTranscript = StringBuffer();
      
      final StringBuffer newFinalParts = StringBuffer();

      for (var result in data.results) {
        if (result.isFinal) {
          newFinalParts.write(result.alternatives.first.transcript);
        } else {
          interimTranscript.write(result.alternatives.first.transcript);
        }
      }

      setState(() {
        _finalTranscription += newFinalParts.toString();
        
        _transcription = _finalTranscription + interimTranscript.toString();
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

  Future<void> _exportToPdf() async {
    if (_transcription.isEmpty) return;

    final TextEditingController nameController = TextEditingController();
    final String? customName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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

    final pdf = pw.Document( title:  customName.isEmpty ? "" : customName );
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
        final fileName =
            customName.endsWith(".pdf") ? customName : "$customName.pdf";
        final file = File("${dir.path}/$fileName");

        await file.writeAsBytes(await pdf.save());
        print("Saved: $fileName");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF saved as: $fileName")),
        );

        setState(() {
          _transcription = "";
          _finalTranscription = "";
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
      appBar: AppBar(
        title: const Text("Speech to PDF"),
        backgroundColor: Colors.white,
      ),
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
                      _transcription.isEmpty
                          ? "Press 'Start' and begin speaking..."
                          : _transcription,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
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
                  icon: Icon(
                      _isListening ? Icons.stop_circle_outlined : Icons.mic),
                  label: Text(_isListening ? "Stop" : "Start"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isListening ? Colors.redAccent : Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _transcription.isNotEmpty ? _exportToPdf : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export PDF"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
