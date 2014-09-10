library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("highlights overridden packages", () {
    servePackages((builder) => builder.serve("overridden", "1.0.0"));
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependency_overrides": {
          "overridden": "any"
        }
      })]).create();
    pubUpgrade(output: new RegExp(r"""
Resolving dependencies\.\.\..*
! overridden 1\.0\.0 \(overridden\)
""", multiLine: true));
  });
}
