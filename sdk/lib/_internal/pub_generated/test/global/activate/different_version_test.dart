import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      "discards the previous active version if it doesn't match the " "constraint",
      () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "2.0.0");
    });
    schedulePub(args: ["global", "activate", "foo", "1.0.0"]);
    schedulePub(args: ["global", "activate", "foo", ">1.0.0"], output: """
        Package foo is currently active at version 1.0.0.
        Resolving dependencies...
        + foo 2.0.0
        Downloading foo 2.0.0...
        Precompiling executables...
        Loading source assets...
        Activated foo 2.0.0.""");
  });
}
