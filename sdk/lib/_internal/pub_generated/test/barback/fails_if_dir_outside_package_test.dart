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
  pubBuildAndServeShouldFail(
      "if source directory reaches outside the package",
      args: [".."],
      error: 'Directory ".." isn\'t in this package.',
      exitCode: exit_codes.USAGE);
}
