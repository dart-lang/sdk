library pub_tests;
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if there are extra arguments', () {
    schedulePub(args: ["cache", "add", "foo", "bar", "baz"], error: """
            Unexpected arguments "bar" and "baz".
            
            Usage: pub cache add <package> [--version <constraint>] [--all]
            -h, --help       Print usage information for this command.
                --all        Install all matching versions.
            -v, --version    Version constraint.

            Run "pub help" to see global options.
            See http://dartlang.org/tools/pub/cmd/pub-cache.html for detailed documentation.
            """, exitCode: exit_codes.USAGE);
  });
}
