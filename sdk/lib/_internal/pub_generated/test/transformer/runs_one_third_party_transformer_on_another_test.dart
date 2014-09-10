library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("runs one third-party transformer on another", () {
      d.dir("foo", [d.pubspec({
          "name": "foo",
          "version": "1.0.0"
        }),
            d.dir("lib", [d.file("transformer.dart", dartTransformer('foo'))])]).create();
      d.dir("bar", [d.pubspec({
          "name": "bar",
          "version": "1.0.0",
          "transformers": ["foo/transformer"],
          "dependencies": {
            "foo": {
              "path": "../foo"
            }
          }
        }),
            d.dir("lib", [d.file("transformer.dart", dartTransformer('bar'))])]).create();
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["bar/transformer"],
          "dependencies": {
            'bar': {
              'path': '../bar'
            }
          }
        }),
            d.dir("web", [d.file("main.dart", 'const TOKEN = "main.dart";')])]).create();
      createLockFile('myapp', sandbox: ['foo', 'bar'], pkg: ['barback']);
      pubServe();
      requestShouldSucceed(
          "main.dart",
          'const TOKEN = "(main.dart, (bar, foo))";');
      endPubServe();
    });
  });
}
