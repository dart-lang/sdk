import 'package:scheduled_test/scheduled_test.dart';
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if the Git repo does not exist', () {
    ensureGit();
    schedulePub(
        args: ["global", "activate", "-sgit", "../nope.git"],
        error: contains("repository '../nope.git' does not exist"),
        exitCode: 1);
  });
}
