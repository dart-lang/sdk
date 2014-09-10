import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("handles imports in the Dart code", () {
    d.dir(
        "foo",
        [d.libPubspec("foo", "0.0.1"), d.dir("lib", [d.file("foo.dart", """
library foo;
foo() => 'footext';
""")])]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }), d.dir("lib", [d.file("lib.dart", """
library lib;
lib() => 'libtext';
""")]), d.dir("web", [d.file("main.dart", """
import 'package:foo/foo.dart';
import 'package:myapp/lib.dart';
void main() {
  print(foo());
  print(lib());
}
""")])]).create();
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("main.dart.js", contains("footext"));
    requestShouldSucceed("main.dart.js", contains("libtext"));
    endPubServe();
  });
}
