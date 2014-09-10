library pub_tests;
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  forBothPubGetAndUpgrade((command) {
    integration('fails gracefully if the url does not resolve', () {
      d.dir(appPath, [d.appPubspec({
          "foo": {
            "hosted": {
              "name": "foo",
              "url": "http://pub.invalid"
            }
          }
        })]).create();
      pubCommand(
          command,
          error: 'Could not resolve URL "http://pub.invalid".',
          exitCode: exit_codes.UNAVAILABLE);
    });
  });
}
