import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('runs a named Dart application in a dev dependency', () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("bin", [d.file("bar.dart", "main() => print('foobar');")])]).create();
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "foo": {
            "path": "../foo"
          }
        }
      })]).create();
    pubGet();
    var pub = pubRun(args: ["foo:bar"]);
    pub.stdout.expect("foobar");
    pub.shouldExit();
  });
}
