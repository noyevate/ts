import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_speech/google_speech.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart'
    as speech_proto;
import 'package:sound_stream/sound_stream.dart'; 


class SpeechToPdfPage extends StatefulWidget {
  const SpeechToPdfPage({Key? key}) : super(key: key);

  @override
  State<SpeechToPdfPage> createState() => _SpeechToPdfPageState();
}

class _SpeechToPdfPageState extends State<SpeechToPdfPage> {
  bool _isInitializing = true;

  final TextEditingController _textController = TextEditingController();
  bool _isPaused = false;
  bool _isListening = false;
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
  }

  Future<void> _initSpeech() async {
    try {
      await _recorder.initialize();
      await [Permission.microphone, Permission.storage].request();
      final serviceAccount = ServiceAccount.fromString(
        (await rootBundle
            .loadString('assets/keys/chop-nowt-078b693b081d.json')),
      );
      _speechTotext = SpeechToText.viaServiceAccount(serviceAccount);

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
    } catch (e) {
      debugPrint("Error during speech initialization: $e");
    } finally {
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _startRecognitionStream() {
    _recorder.start();

    final responseStream =
        _speechTotext.streamingRecognize(_config!, _recorder.audioStream);

    _responseSubscription = responseStream.listen(
      (data) {
        if (_isPaused) return;

        final StringBuffer interimTranscript = StringBuffer();
        final StringBuffer newFinalParts = StringBuffer();

        for (var result in data.results) {
          if (result.isFinal) {
            newFinalParts.write(result.alternatives.first.transcript);
          } else {
            interimTranscript.write(result.alternatives.first.transcript);
          }
        }

        _finalTranscription += newFinalParts.toString();
        _textController.text = _finalTranscription + interimTranscript.toString();
        _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length));
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

  void _pauseListening() {
    if (!_isListening || _isPaused) return;
    setState(() => _isPaused = true);
    _recorder.stop();
    _responseSubscription?.cancel();
    debugPrint("Transcription paused. Stream torn down.");
  }

  void _resumeListening() async {
    if (!_isListening || !_isPaused) return;
    _finalTranscription = _textController.text;
    setState(() => _isPaused = false);
    _startRecognitionStream();
    debugPrint("Transcription resumed with new stream.");
  }

  Future<void> _startListening() async {
    if (_isListening) return;
    _textController.clear();
    _finalTranscription = "";
    setState(() {
      _isListening = true;
      _isPaused = false;
    });
    _startRecognitionStream();
  }

  void _stopListening() async {
    await _recorder.stop();
    await _responseSubscription?.cancel();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isPaused = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _responseSubscription?.cancel();
    _recorder.stop();
    super.dispose();
  }

  Future<void> _exportToPdf() async {
    if (_textController.text.isEmpty) return;

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

    final pdf = pw.Document(title: customName.isEmpty ? "" : customName);
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Text(_textController.text),
        ),
      ),
    );

    try {
      final dir = await getExternalStorageDirectory();
      if (dir != null) {
        final fileName =
            customName.endsWith(".pdf") ? customName : "$customName.pdf";
        final file = File("${dir.path}/$fileName");
        await file.writeAsBytes(await pdf.save());
        print("Saved: $fileName");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF saved as: $fileName")),
        );
        setState(() {
          _textController.clear();
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Speech to PDF"),
          backgroundColor: Colors.white,
        ),
        body: _isInitializing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Initializing..."),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // AFTER
Expanded(
  child: TextField(
    controller: _textController,
    maxLines: null,
    expands: true,
    readOnly: _isListening && !_isPaused,

    textAlignVertical: TextAlignVertical.bottom,
    
    textAlign: TextAlign.left,

    decoration: InputDecoration(
      hintText: "Press 'Start' and begin speaking...",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 8),
    ),
    style: const TextStyle(fontSize: 16, color: Colors.black87),
  ),
),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _isListening ? _stopListening : _startListening,
                          icon: Icon(_isListening
                              ? Icons.stop_circle_outlined
                              : Icons.mic),
                          label: Text(_isListening ? "Stop" : "Start"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening
                                ? Colors.redAccent
                                : Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_isListening)
                          ElevatedButton.icon(
                            onPressed:
                                _isPaused ? _resumeListening : _pauseListening,
                            icon:
                                Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                            label: Text(_isPaused ? "Resume" : "Pause"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed:
                          _textController.text.isNotEmpty ? _exportToPdf : null,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Export PDF"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}