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
      builder.serve("a", "1.0.0");
      builder.serve("b", "1.0.0");
      builder.serve("c", "2.0.0");
    });
    d.appDir({
      "a": "any"
    }).create();
    pubUpgrade(output: new RegExp(r"Changed 1 dependency!$"));
    d.appDir({
      "b": "any",
      "c": "any"
    }).create();
    pubUpgrade(output: new RegExp(r"Changed 3 dependencies!$"));
    pubUpgrade(output: new RegExp(r"No dependencies changed.$"));
  });
}
