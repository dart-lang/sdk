import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('activating a Git package installs its dependencies', () {
    servePackages((builder) {
      builder.serve("bar", "1.0.0", deps: {
        "baz": "any"
      });
      builder.serve("baz", "1.0.0");
    });
    d.git('foo.git', [d.libPubspec("foo", "1.0.0", deps: {
        "bar": "any"
      }),
          d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(
        args: ["global", "activate", "-sgit", "../foo.git"],
        output: allOf(
            [contains("Downloading bar 1.0.0..."), contains("Downloading baz 1.0.0...")]));
  });
}
