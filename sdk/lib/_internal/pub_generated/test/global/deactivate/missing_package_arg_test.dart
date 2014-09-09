import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if no package was given', () {
    schedulePub(args: ["global", "deactivate"], error: """
            No package to deactivate given.

            Usage: pub global deactivate <package>
            -h, --help    Print usage information for this command.

            Run "pub help" to see global options.
            """, exitCode: exit_codes.USAGE);
  });
}
