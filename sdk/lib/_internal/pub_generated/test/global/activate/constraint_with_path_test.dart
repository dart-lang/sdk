import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if a version is passed with the path source', () {
    schedulePub(
        args: ["global", "activate", "-spath", "foo", "1.2.3"],
        error: """
            Unexpected argument "1.2.3".

            Usage: pub global activate <package...>
            -h, --help      Print usage information for this command.
            -s, --source    The source used to find the package.
                            [git, hosted (default), path]

            Run "pub help" to see global options.
            """, exitCode: exit_codes.USAGE);
  });
}
