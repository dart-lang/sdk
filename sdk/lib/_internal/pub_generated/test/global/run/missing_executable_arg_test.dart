import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if no executable was given', () {
    schedulePub(args: ["global", "run"], error: """
            Must specify an executable to run.

            Usage: pub global run <package>:<executable> [args...]
            -h, --help    Print usage information for this command.

            Run "pub help" to see global options.
            """, exitCode: exit_codes.USAGE);
  });
}
