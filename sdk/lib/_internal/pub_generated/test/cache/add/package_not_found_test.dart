library pub_tests;
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if the package cound not be found on the source', () {
    serveNoPackages();
    schedulePub(
        args: ["cache", "add", "foo"],
        error: new RegExp(r"Could not find package foo at http://.*"),
        exitCode: exit_codes.UNAVAILABLE);
  });
}
