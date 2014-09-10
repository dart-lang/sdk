import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("Dart core libraries are available to source maps", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file("main.dart", "main() => new StringBuffer().writeAll(['s']);"),
                    d.dir(
                        "sub",
                        [
                            d.file(
                                "main.dart",
                                "main() => new StringBuffer().writeAll(['s']);")])])]).create();
    schedulePub(
        args: ["build", "--mode", "debug"],
        output: new RegExp(r'Built \d+ files to "build".'),
        exitCode: 0);
    d.dir(
        appPath,
        [
            d.dir(
                "build",
                [
                    d.dir(
                        "web",
                        [
                            d.matcherFile(
                                "main.dart.js.map",
                                contains(r"packages/$sdk/lib/core/string_buffer.dart")),
                            d.dir(
                                "sub",
                                [
                                    d.matcherFile(
                                        "main.dart.js.map",
                                        contains(r"../packages/$sdk/lib/core/string_buffer.dart"))]),
                            d.dir(
                                "packages",
                                [
                                    d.dir(
                                        r"$sdk",
                                        [
                                            d.dir(
                                                "lib",
                                                [
                                                    d.dir(
                                                        r"core",
                                                        [
                                                            d.matcherFile(
                                                                "string_buffer.dart",
                                                                contains("class StringBuffer"))])])])])])])]).validate();
  });
}
