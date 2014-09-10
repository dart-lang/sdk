library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      "doesn't unlock dependencies if a new dependency is already " "satisfied",
      () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", deps: {
        "bar": "<2.0.0"
      });
      builder.serve("bar", "1.0.0", deps: {
        "baz": "<2.0.0"
      });
      builder.serve("baz", "1.0.0");
    });
    d.appDir({
      "foo": "any"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "baz": "1.0.0"
    }).validate();
    servePackages((builder) {
      builder.serve("foo", "2.0.0", deps: {
        "bar": "<3.0.0"
      });
      builder.serve("bar", "2.0.0", deps: {
        "baz": "<3.0.0"
      });
      builder.serve("baz", "2.0.0");
      builder.serve("newdep", "2.0.0", deps: {
        "baz": ">=1.0.0"
      });
    });
    d.appDir({
      "foo": "any",
      "newdep": "any"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "baz": "1.0.0",
      "newdep": "2.0.0"
    }).validate();
  });
}
