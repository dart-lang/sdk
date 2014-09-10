library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('checks out and upgrades a package from Git', () {
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
    d.git(
        'foo.git',
        [d.libDir('foo', 'foo 2'), d.libPubspec('foo', '1.0.0')]).commit();
    pubUpgrade();
    d.dir(
        cachePath,
        [
            d.dir(
                'git',
                [
                    d.dir('cache', [d.gitPackageRepoCacheDir('foo')]),
                    d.gitPackageRevisionCacheDir('foo'),
                    d.gitPackageRevisionCacheDir('foo', 2)])]).validate();
    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo 2";')])]).validate();
  });
}
