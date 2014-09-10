library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      "does not show how many newer versions are available for "
          "packages that are locked and not being upgraded",
      () {
    servePackages((builder) {
      builder.serve("not_upgraded", "1.0.0");
      builder.serve("not_upgraded", "2.0.0");
      builder.serve("not_upgraded", "3.0.0-dev");
      builder.serve("upgraded", "1.0.0");
      builder.serve("upgraded", "2.0.0");
      builder.serve("upgraded", "3.0.0-dev");
    });
    d.appDir({
      "not_upgraded": "1.0.0",
      "upgraded": "1.0.0"
    }).create();
    pubGet();
    d.appDir({
      "not_upgraded": "any",
      "upgraded": "any"
    }).create();
    pubUpgrade(args: ["upgraded"], output: new RegExp(r"""
Resolving dependencies\.\.\..*
  not_upgraded 1\.0\.0
. upgraded 2\.0\.0 \(was 1\.0\.0\) \(3\.0\.0-dev available\)
""", multiLine: true));
  });
}
