import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("generates unminified JS when not in release mode", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [d.file("main.dart", "void main() => print('hello');")])]).create();
    pubServe(args: ["--mode", "whatever"]);
    requestShouldSucceed("main.dart.js", isUnminifiedDart2JSOutput);
    endPubServe();
  });
}
