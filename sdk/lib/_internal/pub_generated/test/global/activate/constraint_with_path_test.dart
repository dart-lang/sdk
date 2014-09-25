import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if a version is passed with the path source', () {
    schedulePub(
        args: ["global", "activate", "-spath", "foo", "1.2.3"],
        error: contains('Unexpected argument "1.2.3".'),
        exitCode: exit_codes.USAGE);
  });
}
