import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if no package was given', () {
    schedulePub(
        args: ["global", "activate"],
        error: contains("No package to activate given."),
        exitCode: exit_codes.USAGE);
  });
}
