library pub_tests;
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("doesn't re-fetch a repository if nothing changes", () {
    ensureGit();
    var repo =
        d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]);
    repo.create();
    d.appDir({
      "foo": {
        "git": {
          "url": "../foo.git"
        }
      }
    }).create();
    pubGet();
    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();
    schedule(() => deleteEntry(p.join(sandboxDir, 'foo.git')));
    pubGet();
    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();
  });
}
