library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('checks out a package from Git twice', () {
    ensureGit();
    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]).create();
    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();
    pubGet();
    d.dir(
        cachePath,
        [
            d.dir(
                'git',
                [
                    d.dir('cache', [d.gitPackageRepoCacheDir('foo')]),
                    d.gitPackageRevisionCacheDir('foo')])]).validate();
    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();
    pubUpgrade();
  });
}
