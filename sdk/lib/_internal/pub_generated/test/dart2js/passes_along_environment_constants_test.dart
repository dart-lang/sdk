import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("passes along environment constants", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": [{
            "\$dart2js": {
              "environment": {
                'CONSTANT': 'true'
              }
            }
          }]
      }), d.dir("web", [d.file("main.dart", """
void main() {
  if (const bool.fromEnvironment('CONSTANT')) {
    print("hello");
  }
}
""")])]).create();
    pubServe();
    requestShouldSucceed("main.dart.js", contains("hello"));
    endPubServe();
  });
}
