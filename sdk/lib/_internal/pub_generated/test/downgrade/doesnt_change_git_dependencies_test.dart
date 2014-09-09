import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("doesn't change git dependencies", () {
    ensureGit();
    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]).create();
    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();
    pubGet();
    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();
    d.git(
        'foo.git',
        [d.libDir('foo', 'foo 2'), d.libPubspec('foo', '1.0.0')]).commit();
    pubDowngrade();
    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();
  });
}
