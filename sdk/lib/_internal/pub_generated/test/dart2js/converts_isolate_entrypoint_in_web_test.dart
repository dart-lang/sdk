import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  integration("converts a Dart isolate entrypoint in web to JS", () {
    currentSchedule.timeout *= 2;
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file(
                        "isolate.dart",
                        "void main(List<String> args, SendPort "
                            "sendPort) => print('hello');")])]).create();
    pubServe();
    requestShouldSucceed("isolate.dart.js", contains("hello"));
    endPubServe();
  });
}
