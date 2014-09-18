import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("removes all binstubs for package", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "foo": null
        }
      }),
          d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);
    d.dir("foo", [d.pubspec({
        "name": "foo"
      })]).create();
    schedulePub(args: ["global", "deactivate", "foo"]);
    d.dir(cachePath, [d.dir("bin", [d.nothing("foo")])]).validate();
  });
}
