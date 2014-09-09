import 'package:path/path.dart' as path;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('path dependency to non-package directory', () {
    d.dir('foo').create();
    var fooPath = path.join(sandboxDir, "foo");
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": fooPath
        }
      })]).create();
    pubGet(
        error: new RegExp(
            r'Could not find a file named "pubspec.yaml" ' r'in "[^\n]*"\.'));
  });
}
