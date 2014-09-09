library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("finds files in the app's web directory", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file("index.html", "<body>"),
                    d.file("file.dart", "main() => print('hello');"),
                    d.dir(
                        "sub",
                        [
                            d.file("file.html", "<body>in subdir</body>"),
                            d.file("lib.dart", "main() => 'foo';")])])]).create();
    pubServe();
    requestShouldSucceed("index.html", "<body>");
    requestShouldSucceed("file.dart", "main() => print('hello');");
    requestShouldSucceed("sub/file.html", "<body>in subdir</body>");
    requestShouldSucceed("sub/lib.dart", "main() => 'foo';");
    endPubServe();
  });
}
