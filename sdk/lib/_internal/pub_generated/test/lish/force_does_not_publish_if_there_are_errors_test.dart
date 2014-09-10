import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_stream.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  setUp(d.validPackage.create);
  integration('--force does not publish if there are errors', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg.remove("homepage");
    d.dir(appPath, [d.pubspec(pkg)]).create();
    var server = new ScheduledServer();
    var pub = startPublish(server, args: ['--force']);
    pub.shouldExit(exit_codes.SUCCESS);
    pub.stderr.expect(
        consumeThrough(
            "Sorry, your package is missing a " "requirement and can't be published yet."));
  });
}
