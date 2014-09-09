library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("shows how many newer versions are available", () {
    servePackages((builder) {
      builder.serve("multiple_newer", "1.0.0");
      builder.serve("multiple_newer", "1.0.1-unstable.1");
      builder.serve("multiple_newer", "1.0.1");
      builder.serve("multiple_newer", "1.0.2-unstable.1");
      builder.serve("multiple_newer_stable", "1.0.0");
      builder.serve("multiple_newer_stable", "1.0.1");
      builder.serve("multiple_newer_stable", "1.0.2");
      builder.serve("multiple_newer_unstable", "1.0.0");
      builder.serve("multiple_newer_unstable", "1.0.1-unstable.1");
      builder.serve("multiple_newer_unstable", "1.0.1-unstable.2");
      builder.serve("no_newer", "1.0.0");
      builder.serve("one_newer_unstable", "1.0.0");
      builder.serve("one_newer_unstable", "1.0.1-unstable.1");
      builder.serve("one_newer_stable", "1.0.0");
      builder.serve("one_newer_stable", "1.0.1");
    });
    d.appDir({
      "multiple_newer": "1.0.0",
      "multiple_newer_stable": "1.0.0",
      "multiple_newer_unstable": "1.0.0",
      "no_newer": "1.0.0",
      "one_newer_unstable": "1.0.0",
      "one_newer_stable": "1.0.0"
    }).create();
    pubUpgrade(output: new RegExp(r"""
Resolving dependencies\.\.\..*
. multiple_newer 1\.0\.0 \(1\.0\.1 available\)
. multiple_newer_stable 1\.0\.0 \(1\.0\.2\ available\)
. multiple_newer_unstable 1\.0\.0 \(1\.0\.1-unstable\.2 available\)
. no_newer 1\.0\.0
. one_newer_stable 1\.0\.0 \(1\.0\.1 available\)
. one_newer_unstable 1\.0\.0 \(1\.0\.1-unstable\.1 available\)
""", multiLine: true));
  });
}
