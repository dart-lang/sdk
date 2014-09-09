library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("loads different configurations from the same isolate", () {
      d.dir("foo", [d.pubspec({
          "name": "foo",
          "version": "1.0.0",
          "transformers": [{
              "foo/first": {
                "addition": " in foo"
              }
            }, "foo/second"]
        }),
            d.dir(
                "lib",
                [
                    d.file("first.dart", dartTransformer('foo/first')),
                    d.file("second.dart", dartTransformer('foo/second'))])]).create();
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [{
              "foo/first": {
                "addition": " in myapp",
                "\$include": "web/first.dart"
              }
            }, {
              "foo/second": {
                "\$include": "web/second.dart"
              }
            }],
          "dependencies": {
            'foo': {
              'path': '../foo'
            }
          }
        }),
            d.dir(
                "web",
                [
                    d.file("first.dart", 'const TOKEN = "myapp/first";'),
                    d.file("second.dart", 'const TOKEN = "myapp/second";')])]).create();
      createLockFile('myapp', sandbox: ['foo'], pkg: ['barback']);
      pubServe();
      requestShouldSucceed(
          "first.dart",
          'const TOKEN = "(myapp/first, foo/first in myapp)";');
      requestShouldSucceed(
          "second.dart",
          'const TOKEN = "(myapp/second, (foo/second, foo/first in foo))";');
      endPubServe();
    });
  });
}
