import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("doesn't support invalid type for boolean option", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": [{
            "\$dart2js": {
              "checked": "foo"
            }
          }]
      }), d.dir("web", [d.file("main.dart", "void main() {}")])]).create();
    var server = pubServe();
    requestShould404("main.dart.js");
    server.stderr.expect(
        emitsLines(
            'Build error:\n' 'Transform Dart2JS on myapp|web/main.dart threw error: '
                'Invalid value for \$dart2js.checked: "foo" ' '(expected true or false).'));
    endPubServe();
  });
}
