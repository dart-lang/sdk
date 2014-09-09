import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../test_pub.dart';
void pubBuildAndServeShouldFail(String description, {List<String> args,
    String error, String buildError, String serveError, int exitCode}) {
  if (error != null) {
    assert(buildError == null);
    buildError = error;
    assert(serveError == null);
    serveError = error;
  }
  var buildExpectation = buildError;
  var serveExpectation = serveError;
  if (exitCode == exit_codes.USAGE) {
    buildExpectation =
        allOf(startsWith(buildExpectation), contains("Usage: pub build"));
    serveExpectation =
        allOf(startsWith(serveExpectation), contains("Usage: pub serve"));
  }
  integration("build fails $description", () {
    schedulePub(
        args: ["build"]..addAll(args),
        error: buildExpectation,
        exitCode: exitCode);
  });
  integration("build --format json fails $description", () {
    schedulePub(args: ["build", "--format", "json"]..addAll(args), outputJson: {
      "error": buildError
    }, exitCode: exitCode);
  });
  integration("serve fails $description", () {
    schedulePub(
        args: ["serve"]..addAll(args),
        error: serveExpectation,
        exitCode: exitCode);
  });
}
