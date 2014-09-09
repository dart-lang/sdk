library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("does not show how many other versions are available", () {
    servePackages((builder) {
      builder.serve("downgraded", "1.0.0");
      builder.serve("downgraded", "2.0.0");
      builder.serve("downgraded", "3.0.0-dev");
    });
    d.appDir({
      "downgraded": "3.0.0-dev"
    }).create();
    pubGet();
    d.appDir({
      "downgraded": ">=2.0.0"
    }).create();
    pubDowngrade(output: contains("downgraded 2.0.0 (was 3.0.0-dev)"));
  });
}
