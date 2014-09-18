import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("does not overwrite an existing binstub", () {
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
    var pub = startPub(args: ["global", "activate", "-spath", "../bar"]);
    pub.stdout.expect(consumeThrough("Installed executable bar."));
    pub.stderr.expect("Executable collide1 was already installed from foo.");
    pub.stderr.expect("Executable collide2 was already installed from foo.");
    pub.stderr.expect(
        "Deactivate the other package(s) or activate bar using " "--overwrite.");
    pub.shouldExit();
    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.matcherFile("foo", contains("foo:foo")),
                    d.matcherFile("bar", contains("bar:bar")),
                    d.matcherFile("collide1", contains("foo:foo")),
                    d.matcherFile("collide2", contains("foo:foo"))])]).validate();
  });
}
