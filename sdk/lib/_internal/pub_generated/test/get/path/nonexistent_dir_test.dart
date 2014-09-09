import 'package:path/path.dart' as path;
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('path dependency to non-existent directory', () {
    var badPath = path.join(sandboxDir, "bad_path");
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": badPath
        }
      })]).create();
    pubGet(error: """
        Could not find package foo at "$badPath".
        Depended on by:
        - myapp 0.0.0""", exitCode: exit_codes.UNAVAILABLE);
  });
}
