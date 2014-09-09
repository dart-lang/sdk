import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  setUp(d.validPackage.create);
  integration('cloud storage upload provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);
    confirmPublish(pub);
    handleUploadForm(server);
    server.handle('POST', '/upload', (request) {
      return drainStream(request.read()).then((_) {
        return new shelf.Response.notFound(
            '<Error><Message>Your request sucked.</Message></Error>',
            headers: {
          'content-type': 'application/xml'
        });
      });
    });
    pub.stderr.expect('Failed to upload the package.');
    pub.shouldExit(1);
  });
}
