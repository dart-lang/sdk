library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('"--all" adds all non-installed versions of the package', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.1");
      builder.serve("foo", "1.2.2");
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "2.0.0");
    });
    schedulePub(
        args: ["cache", "add", "foo", "-v", "1.2.1"],
        output: 'Downloading foo 1.2.1...');
    schedulePub(
        args: ["cache", "add", "foo", "-v", "1.2.3"],
        output: 'Downloading foo 1.2.3...');
    schedulePub(args: ["cache", "add", "foo", "--all"], output: '''
          Already cached foo 1.2.1.
          Downloading foo 1.2.2...
          Already cached foo 1.2.3.
          Downloading foo 2.0.0...''');
    d.cacheDir({
      "foo": "1.2.1"
    }).validate();
    d.cacheDir({
      "foo": "1.2.2"
    }).validate();
    d.cacheDir({
      "foo": "1.2.3"
    }).validate();
    d.cacheDir({
      "foo": "2.0.0"
    }).validate();
  });
}
