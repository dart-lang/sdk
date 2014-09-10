import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if there are extra arguments', () {
    schedulePub(
        args: ["global", "activate", "foo", "1.0.0", "bar", "baz"],
        error: """
            Unexpected arguments "bar" and "baz".

            Usage: pub global activate <package...>
            -h, --help      Print usage information for this command.
            -s, --source    The source used to find the package.
                            [git, hosted (default), path]

            Run "pub help" to see global options.""",
        exitCode: exit_codes.USAGE);
  });
}
