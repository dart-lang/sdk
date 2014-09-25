import 'package:path/path.dart' as p;
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('errors if the script is in a subdirectory.', () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "1.0.0",
          contents: [
              d.dir("example", [d.file("script.dart", "main(args) => print('ok');")])]);
    });
    schedulePub(args: ["global", "activate", "foo"]);
    schedulePub(args: ["global", "run", "foo:example/script"], error: """
Cannot run an executable in a subdirectory of a global package.

Usage: pub global run <package>:<executable> [args...]
-h, --help    Print usage information for this command.
    --mode    Mode to run transformers in.
              (defaults to "release")

Run "pub help" to see global options.
""", exitCode: exit_codes.USAGE);
  });
}
