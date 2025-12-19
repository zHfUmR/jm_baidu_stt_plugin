import 'package:flutter/material.dart';
import 'package:jm_baidu_stt_plugin/jm_baidu_stt_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _appId = 'YOUR_APP_ID';
  static const String _appKey = 'YOUR_APP_KEY';
  static const String _appSecret = 'YOUR_APP_SECRET';

  final List<String> _logs = <String>[];
  bool _asrCreated = false;
  bool _wakeCreated = false;

  @override
  void initState() {
    super.initState();
    JmBaiduSttPlugin.initSDK(
      appId: _appId,
      appKey: _appKey,
      appSecret: _appSecret,
      onEvent: (dynamic event) {
        setState(() {
          _logs.insert(0, event.toString());
          if (_logs.length > 50) {
            _logs.removeLast();
          }
        });
      },
    );
  }

  Future<void> _createAsr() async {
    await JmBaiduSttPlugin.create(type: BaiduSpeechBuildType.asr);
    setState(() {
      _asrCreated = true;
    });
  }

  Future<void> _createWakeUp() async {
    await JmBaiduSttPlugin.create(type: BaiduSpeechBuildType.wakeUp);
    setState(() {
      _wakeCreated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('JM Baidu STT Plugin Example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Replace the placeholder credentials in example/lib/main.dart '
                'with your Baidu Cloud App ID/App Key/App Secret before running on device.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: _createAsr,
                    child: const Text('Create ASR'),
                  ),
                  ElevatedButton(
                    onPressed: _asrCreated
                        ? () => JmBaiduSttPlugin.startRecognition()
                        : null,
                    child: const Text('Start Recognition'),
                  ),
                  ElevatedButton(
                    onPressed: _asrCreated
                        ? () => JmBaiduSttPlugin.stopRecognition()
                        : null,
                    child: const Text('Stop Recognition'),
                  ),
                  ElevatedButton(
                    onPressed: _createWakeUp,
                    child: const Text('Create Wake-up'),
                  ),
                  ElevatedButton(
                    onPressed: _wakeCreated
                        ? () => JmBaiduSttPlugin.startMonitorWakeUp()
                        : null,
                    child: const Text('Start Wake-up'),
                  ),
                  ElevatedButton(
                    onPressed: _wakeCreated
                        ? () => JmBaiduSttPlugin.stopMonitorWakeUp()
                        : null,
                    child: const Text('Stop Wake-up'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Native event stream',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueGrey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_logs[index]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
