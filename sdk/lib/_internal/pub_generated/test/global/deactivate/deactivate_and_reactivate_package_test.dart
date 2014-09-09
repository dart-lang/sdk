import '../../test_pub.dart';
main() {
  initConfig();
  integration('activates a different version after deactivating', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "2.0.0");
    });
    schedulePub(args: ["global", "activate", "foo", "1.0.0"]);
    schedulePub(
        args: ["global", "deactivate", "foo"],
        output: "Deactivated package foo 1.0.0.");
    schedulePub(args: ["global", "activate", "foo"], output: """
        Resolving dependencies...
        + foo 2.0.0
        Downloading foo 2.0.0...
        Precompiling executables...
        Loading source assets...
        Activated foo 2.0.0.""");
  });
}
