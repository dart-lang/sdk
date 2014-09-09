library pub_tests;
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("gets first if a dependency is not installed", () {
    servePackages((builder) => builder.serve("foo", "1.2.3"));
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet();
    schedule(() => deleteEntry(path.join(sandboxDir, cachePath)));
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo 1.2.3";');
    endPubServe();
  });
}
