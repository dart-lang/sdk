import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("overwrites an existing binstub if --overwrite is passed", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "foo": "foo",
          "collide1": "foo",
          "collide2": "foo"
        }
      }),
          d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    d.dir("bar", [d.pubspec({
        "name": "bar",
        "executables": {
          "bar": "bar",
          "collide1": "bar",
          "collide2": "bar"
        }
      }),
          d.dir("bin", [d.file("bar.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "-spath", "../foo"]);
    var pub =
        startPub(args: ["global", "activate", "-spath", "../bar", "--overwrite"]);
    pub.stdout.expect(
        consumeThrough("Installed executables bar, collide1 and collide2."));
    pub.stderr.expect("Replaced collide1 previously installed from foo.");
    pub.stderr.expect("Replaced collide2 previously installed from foo.");
    pub.shouldExit();
    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.matcherFile(binStubName("foo"), contains("foo:foo")),
                    d.matcherFile(binStubName("bar"), contains("bar:bar")),
                    d.matcherFile(binStubName("collide1"), contains("bar:bar")),
                    d.matcherFile(binStubName("collide2"), contains("bar:bar"))])]).validate();
  });
}
