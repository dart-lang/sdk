import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('errors if the package could not be found', () {
    serveNoPackages();
    schedulePub(
        args: ["global", "activate", "foo"],
        error: startsWith("Could not find package foo at"),
        exitCode: exit_codes.UNAVAILABLE);
  });
}
