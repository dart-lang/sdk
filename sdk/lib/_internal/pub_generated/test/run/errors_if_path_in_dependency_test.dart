import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration(
      'Errors if the executable is in a subdirectory in a ' 'dependency.',
      () {
    d.dir("foo", [d.libPubspec("foo", "1.0.0")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      })]).create();
    schedulePub(args: ["run", "foo:sub/dir"], error: """
Cannot run an executable in a subdirectory of a dependency.

Usage: pub run <executable> [args...]
-h, --help    Print usage information for this command.
    --mode    Mode to run transformers in.
              (defaults to "release" for dependencies, "debug" for entrypoint)

Run "pub help" to see global options.
""", exitCode: exit_codes.USAGE);
  });
}
