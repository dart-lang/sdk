import 'package:path/path.dart' as p;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("errors if an executable's script can't be found", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "missing": "not_here",
          "nope": null
        }
      })]).create();
    var pub = startPub(args: ["global", "activate", "-spath", "../foo"]);
    pub.stderr.expect(
        'Warning: Executable "missing" runs '
            '"${p.join('bin', 'not_here.dart')}", which was not found in foo.');
    pub.stderr.expect(
        'Warning: Executable "nope" runs '
            '"${p.join('bin', 'nope.dart')}", which was not found in foo.');
    pub.shouldExit();
  });
}
