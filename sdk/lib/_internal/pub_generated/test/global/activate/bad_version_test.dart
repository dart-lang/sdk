import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if the version constraint cannot be parsed', () {
    schedulePub(
        args: ["global", "activate", "foo", "1.0"],
        error: contains('Could not parse version "1.0". Unknown text at "1.0".'),
        exitCode: exit_codes.USAGE);
  });
}
