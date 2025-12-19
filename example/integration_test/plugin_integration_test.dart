// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:jm_baidu_stt_plugin/jm_baidu_stt_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initSDK wires event stream', (WidgetTester tester) async {
    JmBaiduSttPlugin.initSDK(
      appId: 'test_app_id',
      appKey: 'test_app_key',
      appSecret: 'test_app_secret',
      onEvent: (_) {},
    );

    final stream = JmBaiduSttPlugin.onChange();
    expect(stream, isNotNull);
    await tester.pumpAndSettle();
  });
}
