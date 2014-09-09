import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if the version constraint cannot be parsed', () {
    schedulePub(args: ["global", "activate", "foo", "1.0"], error: """
            Could not parse version "1.0". Unknown text at "1.0".

            Usage: pub global activate <package...>
            -h, --help      Print usage information for this command.
            -s, --source    The source used to find the package.
                            [git, hosted (default), path]

            Run "pub help" to see global options.
            """, exitCode: exit_codes.USAGE);
  });
}
