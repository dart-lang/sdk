library pub_tests;
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if the version constraint cannot be parsed', () {
    schedulePub(args: ["cache", "add", "foo", "-v", "1.0"], error: """
            Could not parse version "1.0". Unknown text at "1.0".
            
            Usage: pub cache add <package> [--version <constraint>] [--all]
            -h, --help       Print usage information for this command.
                --all        Install all matching versions.
            -v, --version    Version constraint.

            Run "pub help" to see global options.
            See http://dartlang.org/tools/pub/cmd/pub-cache.html for detailed documentation.
            """, exitCode: exit_codes.USAGE);
  });
}
