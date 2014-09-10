import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  setUp(() {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("bar", [d.file("file.txt", "contents")])]).create();
  });
  pubBuildAndServeShouldFail(
      "if a specified directory doesn't exist",
      args: ["foo", "bar", "baz"],
      error: 'Directories "foo" and "baz" do not exist.',
      exitCode: exit_codes.DATA);
}
