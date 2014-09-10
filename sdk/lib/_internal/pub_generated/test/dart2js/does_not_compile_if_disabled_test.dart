import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("does not compile if dart2js is disabled", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [d.file("main.dart", "void main() => print('hello');")])]).create();
    pubServe(args: ["--no-dart2js"]);
    requestShould404("main.dart.js");
    endPubServe();
  });
}
