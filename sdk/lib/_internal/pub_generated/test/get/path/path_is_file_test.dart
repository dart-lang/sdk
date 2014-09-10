import 'package:path/path.dart' as path;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('path dependency when path is a file', () {
    d.dir('foo', [d.libDir('foo'), d.libPubspec('foo', '0.0.1')]).create();
    d.file('dummy.txt', '').create();
    var dummyPath = path.join(sandboxDir, 'dummy.txt');
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": dummyPath
        }
      })]).create();
    pubGet(
        error: 'Path dependency for package foo must refer to a '
            'directory, not a file. Was "$dummyPath".');
  });
}
