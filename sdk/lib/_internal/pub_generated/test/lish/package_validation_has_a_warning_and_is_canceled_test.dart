import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  setUp(d.validPackage.create);
  integration('package validation has a warning and is canceled', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["author"] = "Natalie Weizenbaum";
    d.dir(appPath, [d.pubspec(pkg)]).create();
    var server = new ScheduledServer();
    var pub = startPublish(server);
    pub.writeLine("n");
    pub.shouldExit(exit_codes.SUCCESS);
    pub.stderr.expect(consumeThrough("Package upload canceled."));
  });
}
