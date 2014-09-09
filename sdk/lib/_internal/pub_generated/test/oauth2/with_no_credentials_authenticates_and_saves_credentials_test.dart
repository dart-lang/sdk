import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      'with no credentials.json, authenticates and saves ' 'credentials.json',
      () {
    d.validPackage.create();
    var server = new ScheduledServer();
    var pub = startPublish(server);
    confirmPublish(pub);
    authorizePub(pub, server);
    server.handle('GET', '/api/packages/versions/new', (request) {
      expect(
          request.headers,
          containsPair('authorization', 'Bearer access token'));
      return new shelf.Response(200);
    });
    pub.shouldExit(1);
    d.credentialsFile(server, 'access token').validate();
  });
}
