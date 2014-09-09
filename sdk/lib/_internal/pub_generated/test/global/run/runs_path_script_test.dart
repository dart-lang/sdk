import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('runs a script in a path package', () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);
    var pub = pubRun(global: true, args: ["foo"]);
    pub.stdout.expect("ok");
    pub.shouldExit();
  });
}
