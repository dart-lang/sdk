import 'package:scheduled_test/scheduled_test.dart';
import '../../test_pub.dart';
main() {
  initConfig();
  integration('activating a package installs its dependencies', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", deps: {
        "bar": "any"
      });
      builder.serve("bar", "1.0.0", deps: {
        "baz": "any"
      });
      builder.serve("baz", "1.0.0");
    });
    schedulePub(
        args: ["global", "activate", "foo"],
        output: allOf(
            [contains("Downloading bar 1.0.0..."), contains("Downloading baz 1.0.0...")]));
  });
}
