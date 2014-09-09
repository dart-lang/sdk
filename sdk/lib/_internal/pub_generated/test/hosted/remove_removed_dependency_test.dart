library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  forBothPubGetAndUpgrade((command) {
    integration("removes a dependency that's removed from the pubspec", () {
      servePackages((builder) {
        builder.serve("foo", "1.0.0");
        builder.serve("bar", "1.0.0");
      });
      d.appDir({
        "foo": "any",
        "bar": "any"
      }).create();
      pubCommand(command);
      d.packagesDir({
        "foo": "1.0.0",
        "bar": "1.0.0"
      }).validate();
      d.appDir({
        "foo": "any"
      }).create();
      pubCommand(command);
      d.packagesDir({
        "foo": "1.0.0",
        "bar": null
      }).validate();
    });
  });
}
