import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("minify configuration overrides the mode", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": [{
            "\$dart2js": {
              "minify": true
            }
          }]
      })]).create();
    pubServe();
    requestShouldSucceed("main.dart.js", isMinifiedDart2JSOutput);
    endPubServe();
  });
}
