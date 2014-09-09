library pub_tests;
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('reinstalls previously cached git packages', () {
    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]).create();
    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();
    pubGet();
    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.1')]).commit();
    pubUpgrade();
    var fooDirs;
    schedule(() {
      var gitCacheDir = path.join(sandboxDir, cachePath, "git");
      fooDirs = listDir(
          gitCacheDir).where((dir) => path.basename(dir).startsWith("foo-")).toList();
      for (var dir in fooDirs) {
        deleteEntry(path.join(dir, "lib", "foo.dart"));
      }
    });
    schedulePub(args: ["cache", "repair"], output: '''
          Resetting Git repository for foo 1.0.0...
          Resetting Git repository for foo 1.0.1...
          Reinstalled 2 packages.''');
    schedule(() {
      var fooLibs = fooDirs.map((dir) {
        var fooDirName = path.basename(dir);
        return d.dir(
            fooDirName,
            [d.dir("lib", [d.file("foo.dart", 'main() => "foo";')])]);
      }).toList();
      d.dir(cachePath, [d.dir("git", fooLibs)]).validate();
    });
  });
}
