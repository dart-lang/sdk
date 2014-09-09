library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration(
      "downgrades a locked package's dependers in order to get it to " "min version",
      () {
    servePackages((builder) {
      builder.serve("foo", "2.0.0", deps: {
        "bar": ">1.0.0"
      });
      builder.serve("bar", "2.0.0");
    });
    d.appDir({
      "foo": "any",
      "bar": "any"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "2.0.0",
      "bar": "2.0.0"
    }).validate();
    servePackages((builder) {
      builder.serve("foo", "1.0.0", deps: {
        "bar": "any"
      });
      builder.serve("bar", "1.0.0");
    });
    pubDowngrade(args: ['bar']);
    d.packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0"
    }).validate();
  });
}
