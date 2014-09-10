library pub_tests;
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      'upgrades a locked pub server package with a nonexistent version',
      () {
    servePackages((builder) => builder.serve("foo", "1.0.0"));
    d.appDir({
      "foo": "any"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "1.0.0"
    }).validate();
    schedule(() => deleteEntry(p.join(sandboxDir, cachePath)));
    servePackages((builder) => builder.serve("foo", "1.0.1"), replace: true);
    pubGet();
    d.packagesDir({
      "foo": "1.0.1"
    }).validate();
  });
}
