import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/recipe.dart';

class HandsFreeCookingScreen extends StatefulWidget {
  final Recipe recipe;
  const HandsFreeCookingScreen({super.key, required this.recipe});

  @override
  State<HandsFreeCookingScreen> createState() => _HandsFreeCookingScreenState();
}

class _HandsFreeCookingScreenState extends State<HandsFreeCookingScreen> {
  int _currentStep = 0;
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
    _speakCurrentStep();
  }

  void _initTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.5); // Slightly slower for clear cooking instructions
  }

  void _speakCurrentStep() {
    if (widget.recipe.instructions.isEmpty) return;
    String text = "Step ${_currentStep + 1}. ${widget.recipe.instructions[_currentStep]}";
    _flutterTts.speak(text);
  }

  void _nextStep() {
    if (_currentStep < widget.recipe.instructions.length - 1) {
      setState(() => _currentStep++);
      _speakCurrentStep();
    } else {
      _flutterTts.speak("You have completed all steps. Enjoy your meal!");
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _speakCurrentStep();
    }
  }

  void _listenForCommands() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') setState(() => _isListening = false);
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          String command = val.recognizedWords.toLowerCase();
          if (command.contains('next') || command.contains('forward')) {
            _speech.stop();
            _nextStep();
          } else if (command.contains('back') || command.contains('previous')) {
            _speech.stop();
            _prevStep();
          } else if (command.contains('repeat') || command.contains('again')) {
            _speech.stop();
            _speakCurrentStep();
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipe.instructions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cooking Mode')),
        body: const Center(child: Text('No instructions available.')),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black, // Dark mode forced for cooking
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text("Step ${_currentStep + 1} of ${widget.recipe.instructions.length}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.white, size: 30),
                    onPressed: _listenForCommands,
                  ),
                ],
              ),
            ),
            if (_isListening)
              const Text("Listening for 'Next', 'Back', or 'Repeat'...", style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic)),
            
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    widget.recipe.instructions[_currentStep],
                    style: const TextStyle(color: Colors.white, fontSize: 28, height: 1.5, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                     onPressed: _currentStep > 0 ? _prevStep : null,
                     child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 30),
                   ),
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, shape: const CircleBorder(), padding: const EdgeInsets.all(24)),
                     onPressed: _speakCurrentStep,
                     child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 32),
                   ),
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                     onPressed: _currentStep < widget.recipe.instructions.length - 1 ? _nextStep : null,
                     child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
                   ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
