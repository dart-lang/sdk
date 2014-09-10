import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if there are extra arguments', () {
    schedulePub(args: ["global", "deactivate", "foo", "bar", "baz"], error: """
            Unexpected arguments "bar" and "baz".

            Usage: pub global deactivate <package>
            -h, --help    Print usage information for this command.

            Run "pub help" to see global options.
            """, exitCode: exit_codes.USAGE);
  });
}
