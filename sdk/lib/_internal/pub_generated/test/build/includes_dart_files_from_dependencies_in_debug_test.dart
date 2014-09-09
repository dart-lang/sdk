import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("includes .dart files from dependencies in debug mode", () {
    currentSchedule.timeout *= 3;
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "0.0.1"),
            d.dir(
                "lib",
                [
                    d.file('foo.dart', 'foo() => print("hello");'),
                    d.dir("sub", [d.file('bar.dart', 'bar() => print("hello");')])])]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir(
              "example",
              [
                  d.file("main.dart", 'myapp() => print("not entrypoint");'),
                  d.dir(
                      "sub",
                      [d.file("main.dart", 'myapp() => print("not entrypoint");')])])]).create();
    schedulePub(
        args: ["build", "--mode", "debug", "example"],
        output: new RegExp(r'Built \d+ files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'example',
                        [
                            d.file("main.dart", 'myapp() => print("not entrypoint");'),
                            d.dir(
                                'packages',
                                [
                                    d.dir(
                                        'foo',
                                        [
                                            d.file('foo.dart', 'foo() => print("hello");'),
                                            d.dir("sub", [d.file('bar.dart', 'bar() => print("hello");')])])]),
                            d.dir(
                                "sub",
                                [
                                    d.file("main.dart", 'myapp() => print("not entrypoint");'),
                                    d.nothing("packages")])])])]).validate();
  });
}
