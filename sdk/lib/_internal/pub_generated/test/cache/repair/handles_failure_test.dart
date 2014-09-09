library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('handles failure to reinstall some packages', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "1.2.5");
    });
    d.dir(
        cachePath,
        [
            d.dir(
                'hosted',
                [
                    d.async(
                        port.then(
                            (p) =>
                                d.dir(
                                    'localhost%58$p',
                                    [
                                        d.dir("foo-1.2.3", [d.libPubspec("foo", "1.2.3"), d.file("broken.txt")]),
                                        d.dir("foo-1.2.4", [d.libPubspec("foo", "1.2.4"), d.file("broken.txt")]),
                                        d.dir(
                                            "foo-1.2.5",
                                            [d.libPubspec("foo", "1.2.5"), d.file("broken.txt")])])))])]).create();
    var pub = startPub(args: ["cache", "repair"]);
    pub.stdout.expect("Downloading foo 1.2.3...");
    pub.stdout.expect("Downloading foo 1.2.4...");
    pub.stdout.expect("Downloading foo 1.2.5...");
    pub.stderr.expect(startsWith("Failed to repair foo 1.2.4. Error:"));
    pub.stderr.expect("HTTP error 404: Not Found");
    pub.stdout.expect("Reinstalled 2 packages.");
    pub.stdout.expect("Failed to reinstall 1 package.");
    pub.shouldExit(exit_codes.UNAVAILABLE);
  });
}
