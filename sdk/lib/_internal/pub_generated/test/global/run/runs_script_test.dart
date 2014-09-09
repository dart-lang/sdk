import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('runs a script in an activated package', () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "1.0.0",
          contents: [
              d.dir("bin", [d.file("script.dart", "main(args) => print('ok');")])]);
    });
    schedulePub(args: ["global", "activate", "foo"]);
    var pub = pubRun(global: true, args: ["foo:script"]);
    pub.stdout.expect("ok");
    pub.shouldExit();
  });
}
