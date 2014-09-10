import 'dart:convert';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  setUp(d.validPackage.create);
  integration('upload form is missing url', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);
    confirmPublish(pub);
    var body = {
      'fields': {
        'field1': 'value1',
        'field2': 'value2'
      }
    };
    handleUploadForm(server, body);
    pub.stderr.expect('Invalid server response:');
    pub.stderr.expect(JSON.encode(body));
    pub.shouldExit(1);
  });
}
