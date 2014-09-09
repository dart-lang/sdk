import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("supports most dart2js command-line options", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": [{
            "\$dart2js": {
              "commandLineOptions": ["--enable-diagnostic-colors"],
              "checked": true,
              "csp": true,
              "minify": true,
              "verbose": true,
              "environment": {
                "name": "value"
              },
              "analyzeAll": true,
              "suppressWarnings": true,
              "suppressHints": true,
              "suppressPackageWarnings": false,
              "terse": true
            }
          }]
      })]).create();
    pubServe();
    requestShouldSucceed("main.dart.js", isNot(isEmpty));
    endPubServe();
  });
}
