library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
void main() {
  initConfig();
  integration("reports a dependency if the library itself is transformed", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": [{
            "foo": {
              "\$include": "bin/myapp.dart.dart"
            }
          }]
      }),
          d.dir(
              "bin",
              [d.file("myapp.dart", "import 'package:myapp/lib.dart';")])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0"
      }), d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    expectLibraryDependencies('myapp|bin/myapp.dart', ['foo']);
  });
  integration(
      "reports a dependency if a transformed local file is imported",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": [{
            "foo": {
              "\$include": "lib/lib.dart"
            }
          }]
      }),
          d.dir("lib", [d.file("lib.dart", "")]),
          d.dir(
              "bin",
              [d.file("myapp.dart", "import 'package:myapp/lib.dart';")])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0"
      }), d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    expectLibraryDependencies('myapp|bin/myapp.dart', ['foo']);
  });
  integration(
      "reports a dependency if a transformed foreign file is imported",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        }
      }),
          d.dir(
              "bin",
              [d.file("myapp.dart", "import 'package:foo/foo.dart';")])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": [{
            "foo": {
              "\$include": "lib/foo.dart"
            }
          }]
      }),
          d.dir(
              "lib",
              [d.file("foo.dart", ""), d.file("transformer.dart", transformer())])]).create();
    expectLibraryDependencies('myapp|bin/myapp.dart', ['foo']);
  });
  integration(
      "doesn't report a dependency if no transformed files are " "imported",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": [{
            "foo": {
              "\$include": "lib/lib.dart"
            }
          }]
      }),
          d.dir("lib", [d.file("lib.dart", ""), d.file("untransformed.dart", "")]),
          d.dir(
              "bin",
              [
                  d.file("myapp.dart", "import 'package:myapp/untransformed.dart';")])]).create();
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0"
      }), d.dir("lib", [d.file("foo.dart", transformer())])]).create();
    expectLibraryDependencies('myapp|bin/myapp.dart', []);
  });
}
