library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('checks out packages transitively from Git', () {
    ensureGit();
    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0', deps: {
        "bar": {
          "git": "../bar.git"
        }
      })]).create();
    d.git('bar.git', [d.libDir('bar'), d.libPubspec('bar', '1.0.0')]).create();
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
                    d.dir(
                        'cache',
                        [d.gitPackageRepoCacheDir('foo'), d.gitPackageRepoCacheDir('bar')]),
                    d.gitPackageRevisionCacheDir('foo'),
                    d.gitPackageRevisionCacheDir('bar')])]).validate();
    d.dir(
        packagesPath,
        [
            d.dir('foo', [d.file('foo.dart', 'main() => "foo";')]),
            d.dir('bar', [d.file('bar.dart', 'main() => "bar";')])]).validate();
  });
}
