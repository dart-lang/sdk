import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../serve/utils.dart';
import '../test_pub.dart';
main() {
  initConfig();
  integration(
      "Dart core libraries are available to source maps when the "
          "build directory is a subdirectory",
      () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.dir(
                        "sub",
                        [
                            d.file(
                                "main.dart",
                                "main() => new StringBuffer().writeAll(['s']);")])])]).create();
    var webSub = path.join("web", "sub");
    pubServe(args: [webSub]);
    requestShouldSucceed(
        "main.dart.js.map",
        contains(r"packages/$sdk/lib/core/string_buffer.dart"),
        root: webSub);
    requestShouldSucceed(
        r"packages/$sdk/lib/core/string_buffer.dart",
        contains("class StringBuffer"),
        root: webSub);
    endPubServe();
  });
}
