library pub_tests;
import 'dart:convert';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("gets first if a dev dependency has changed", () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1"), d.libDir("foo")]).create();
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "foo": {
            "path": "../foo"
          }
        }
      }), d.file("pubspec.lock", JSON.encode({
        'packages': {}
      }))]).create();
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
