import 'package:path/path.dart' as p;
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('path dependency to an empty pubspec', () {
    d.dir('foo', [d.libDir('foo'), d.file('pubspec.yaml', '')]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      })]).create();
    pubGet(
        exitCode: exit_codes.DATA,
        error: 'Error on line 1, column 1 of ${p.join('..', 'foo', 'pubspec.yaml')}: '
            'Missing the required "name" field.');
  });
}
