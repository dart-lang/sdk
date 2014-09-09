library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('reinstalls previously cached hosted packages', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "1.2.4");
      builder.serve("foo", "1.2.5");
      builder.serve("bar", "1.2.3");
      builder.serve("bar", "1.2.4");
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
                                        d.dir("foo-1.2.5", [d.libPubspec("foo", "1.2.5"), d.file("broken.txt")]),
                                        d.dir(
                                            "bar-1.2.4",
                                            [d.libPubspec("bar", "1.2.4"), d.file("broken.txt")])])))])]).create();
    schedulePub(args: ["cache", "repair"], output: '''
          Downloading bar 1.2.4...
          Downloading foo 1.2.3...
          Downloading foo 1.2.5...
          Reinstalled 3 packages.''');
    d.hostedCache(
        [
            d.dir("bar-1.2.4", [d.nothing("broken.txt")]),
            d.dir("foo-1.2.3", [d.nothing("broken.txt")]),
            d.dir("foo-1.2.5", [d.nothing("broken.txt")])]).validate();
  });
}
