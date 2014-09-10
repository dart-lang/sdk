library pub_tests;
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      'keeps a pub server package locked to the version in the ' 'lockfile',
      () {
    servePackages((builder) => builder.serve("foo", "1.0.0"));
    d.appDir({
      "foo": "any"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "1.0.0"
    }).validate();
    schedule(() => deleteEntry(path.join(sandboxDir, packagesPath)));
    servePackages((builder) => builder.serve("foo", "1.0.1"));
    pubGet();
    d.packagesDir({
      "foo": "1.0.0"
    }).validate();
  });
}
