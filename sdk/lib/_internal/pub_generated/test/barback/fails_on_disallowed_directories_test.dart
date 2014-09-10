import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  setUp(() {
    d.appDir().create();
  });
  var libSub = path.join("lib", "sub");
  pubBuildAndServeShouldFail(
      "if given directories are not allowed",
      args: [libSub, "lib"],
      error: 'Directories "$libSub" and "lib" are not allowed.',
      exitCode: exit_codes.USAGE);
}
