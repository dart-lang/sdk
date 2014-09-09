import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('with a pre-existing credentials.json does not authenticate', () {
    d.validPackage.create();
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);
    confirmPublish(pub);
    server.handle('GET', '/api/packages/versions/new', (request) {
      expect(
          request.headers,
          containsPair('authorization', 'Bearer access token'));
      return new shelf.Response(200);
    });
    pub.kill();
  });
}
