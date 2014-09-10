import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("includes assets from the 'lib' directory of dependencies", () {
    currentSchedule.timeout *= 3;
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "0.0.1"),
            d.dir(
                "lib",
                [
                    d.file("foo.txt", "foo"),
                    d.dir("sub", [d.file("bar.txt", "bar")])])]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir("example", [d.file("index.html", "html")]),
          d.dir(
              "web",
              [
                  d.file("index.html", "html"),
                  d.dir("sub", [d.file("index.html", "html")])])]).create();
    schedulePub(
        args: ["build", "--all"],
        output: new RegExp(r'Built 7 files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'example',
                        [
                            d.file("index.html", "html"),
                            d.dir(
                                'packages',
                                [
                                    d.dir(
                                        'foo',
                                        [d.file('foo.txt', 'foo'), d.dir('sub', [d.file('bar.txt', 'bar')])])])]),
                    d.dir(
                        'web',
                        [
                            d.file("index.html", "html"),
                            d.dir(
                                'packages',
                                [
                                    d.dir(
                                        'foo',
                                        [d.file('foo.txt', 'foo'), d.dir('sub', [d.file('bar.txt', 'bar')])])]),
                            d.dir(
                                "sub",
                                [d.file("index.html", "html"), d.nothing("packages")])])])]).validate();
  });
}
