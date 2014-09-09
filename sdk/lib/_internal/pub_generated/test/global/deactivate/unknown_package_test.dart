import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('errors if the package is not activated', () {
    serveNoPackages();
    schedulePub(
        args: ["global", "deactivate", "foo"],
        error: "No active package foo.",
        exitCode: exit_codes.DATA);
  });
}
