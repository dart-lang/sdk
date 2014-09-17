import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('Errors if the executable does not exist.', () {
    d.dir(appPath, [d.appPubspec()]).create();
    schedulePub(args: ["run"], error: """
Must specify an executable to run.

Usage: pub run <executable> [args...]
-h, --help    Print usage information for this command.
    --mode    Mode to run transformers in.
              (defaults to "release" for dependencies, "debug" for entrypoint)

Run "pub help" to see global options.
""", exitCode: exit_codes.USAGE);
  });
}
