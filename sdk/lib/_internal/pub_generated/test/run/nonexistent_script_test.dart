import 'package:path/path.dart' as p;
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('Errors if the script does not exist.', () {
    d.dir(appPath, [d.appPubspec()]).create();
    var pub = pubRun(args: ["script"]);
    pub.stderr.expect("Could not find ${p.join("bin", "script.dart")}.");
    pub.shouldExit(exit_codes.NO_INPUT);
  });
}
