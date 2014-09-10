import '../../test_pub.dart';
main() {
  initConfig();
  integration('deactivates an active hosted package', () {
    servePackages((builder) => builder.serve("foo", "1.0.0"));
    schedulePub(args: ["global", "activate", "foo"]);
    schedulePub(
        args: ["global", "deactivate", "foo"],
        output: "Deactivated package foo 1.0.0.");
  });
}
