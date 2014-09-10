library pub_tests;
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("gets first if a transitive dependency is not installed", () {
    servePackages((builder) => builder.serve("bar", "1.2.3"));
    d.dir("foo", [d.libPubspec("foo", "1.0.0", deps: {
        "bar": "any"
      }), d.libDir("foo")]).create();
    d.appDir({
      "foo": {
        "path": "../foo"
      }
    }).create();
    pubGet();
    schedule(() => deleteEntry(path.join(sandboxDir, cachePath)));
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/bar/bar.dart", 'main() => "bar 1.2.3";');
    endPubServe();
  });
}
