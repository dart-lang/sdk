library pub_tests;
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if no package was given', () {
    schedulePub(args: ["cache", "add"], error: """
            No package to add given.
            
            Usage: pub cache add <package> [--version <constraint>] [--all]
            -h, --help       Print usage information for this command.
                --all        Install all matching versions.
            -v, --version    Version constraint.

            Run "pub help" to see global options.
            See http://dartlang.org/tools/pub/cmd/pub-cache.html for detailed documentation.
            """, exitCode: exit_codes.USAGE);
  });
}
