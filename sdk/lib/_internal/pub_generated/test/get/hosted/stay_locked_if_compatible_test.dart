library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      "doesn't upgrade a locked pub server package with a new "
          "compatible constraint",
      () {
    servePackages((builder) => builder.serve("foo", "1.0.0"));
    d.appDir({
      "foo": "any"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "1.0.0"
    }).validate();
    servePackages((builder) => builder.serve("foo", "1.0.1"));
    d.appDir({
      "foo": ">=1.0.0"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "1.0.0"
    }).validate();
  });
}
