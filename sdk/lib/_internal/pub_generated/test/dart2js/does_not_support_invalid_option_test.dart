import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("doesn't support an invalid dart2js option", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": [{
            "\$dart2js": {
              "invalidOption": true
            }
          }]
      })]).create();
    var pub = startPubServe();
    pub.stderr.expect('Unrecognized dart2js option "invalidOption".');
    pub.shouldExit(exit_codes.DATA);
  });
}
