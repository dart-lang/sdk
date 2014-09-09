import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
const SCRIPT = """
main() {
  int a = true;
}
""";
main() {
  initConfig();
  integration('runs the script in checked mode by default', () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("bin", [d.file("script.dart", SCRIPT)])]).create();
    schedulePub(
        args: ["run", "script"],
        error: contains("'bool' is not a subtype of type 'int' of 'a'"),
        exitCode: 255);
  });
}
