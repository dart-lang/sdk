import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if no package was given', () {
    schedulePub(args: ["global", "activate"], error: """
            No package to activate given.

            Usage: pub global activate <package...>
            -h, --help      Print usage information for this command.
            -s, --source    The source used to find the package.
                            [git, hosted (default), path]

            Run "pub help" to see global options.""",
        exitCode: exit_codes.USAGE);
  });
}
