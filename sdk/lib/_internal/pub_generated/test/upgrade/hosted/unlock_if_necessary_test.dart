library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      "upgrades one locked pub server package's dependencies if it's " "necessary",
      () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", deps: {
        "foo_dep": "any"
      });
      builder.serve("foo_dep", "1.0.0");
    });
    d.appDir({
      "foo": "any"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "1.0.0",
      "foo_dep": "1.0.0"
    }).validate();
    servePackages((builder) {
      builder.serve("foo", "2.0.0", deps: {
        "foo_dep": ">1.0.0"
      });
      builder.serve("foo_dep", "2.0.0");
    });
    pubUpgrade(args: ['foo']);
    d.packagesDir({
      "foo": "2.0.0",
      "foo_dep": "2.0.0"
    }).validate();
  });
}
