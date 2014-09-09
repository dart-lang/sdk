import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('changes in a path package are immediately reflected', () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);
    d.file("foo/bin/foo.dart", "main() => print('changed');").create();
    var pub = pubRun(global: true, args: ["foo"]);
    pub.stdout.expect("changed");
    pub.shouldExit();
  });
}
