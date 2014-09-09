library pub_tests;
import 'dart:convert';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      "gets first if a dependency's source doesn't match the one in " "the lock file",
      () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1"), d.libDir("foo")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }), d.file("pubspec.lock", JSON.encode({
        'packages': {
          'foo': {
            'version': '0.0.0',
            'source': 'hosted',
            'description': 'foo'
          }
        }
      }))]).create();
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
