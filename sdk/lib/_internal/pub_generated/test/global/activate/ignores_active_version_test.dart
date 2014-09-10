import '../../test_pub.dart';
main() {
  initConfig();
  integration('ignores previously activated version', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "1.3.0");
    });
    schedulePub(args: ["global", "activate", "foo", "1.2.3"]);
    schedulePub(args: ["global", "activate", "foo", ">1.0.0"], output: """
        Package foo is currently active at version 1.2.3.
        Resolving dependencies...
        + foo 1.3.0
        Downloading foo 1.3.0...
        Precompiling executables...
        Loading source assets...
        Activated foo 1.3.0.""");
  });
}
