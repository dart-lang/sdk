import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("removes previous binstubs when reactivating a package", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "one": null,
          "two": null
        }
      }),
          d.dir(
              "bin",
              [
                  d.file("one.dart", "main() => print('ok');"),
                  d.file("two.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "two": null
        }
      })]).create();
    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);
    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.nothing(binStubName("one")),
                    d.matcherFile(binStubName("two"), contains("two"))])]).validate();
  });
}
