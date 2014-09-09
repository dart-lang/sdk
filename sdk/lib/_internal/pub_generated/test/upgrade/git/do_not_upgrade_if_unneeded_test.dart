library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      "doesn't upgrade one locked Git package's dependencies if it's "
          "not necessary",
      () {
    ensureGit();
    d.git('foo.git', [d.libDir('foo'), d.libPubspec("foo", "1.0.0", deps: {
        "foo-dep": {
          "git": "../foo-dep.git"
        }
      })]).create();
    d.git(
        'foo-dep.git',
        [d.libDir('foo-dep'), d.libPubspec('foo-dep', '1.0.0')]).create();
    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();
    pubGet();
    d.dir(
        packagesPath,
        [
            d.dir('foo', [d.file('foo.dart', 'main() => "foo";')]),
            d.dir('foo-dep', [d.file('foo-dep.dart', 'main() => "foo-dep";')])]).validate();
    d.git(
        'foo.git',
        [d.libDir('foo', 'foo 2'), d.libPubspec("foo", "1.0.0", deps: {
        "foo-dep": {
          "git": "../foo-dep.git"
        }
      })]).create();
    d.git(
        'foo-dep.git',
        [d.libDir('foo-dep', 'foo-dep 2'), d.libPubspec('foo-dep', '1.0.0')]).commit();
    pubUpgrade(args: ['foo']);
    d.dir(
        packagesPath,
        [
            d.dir('foo', [d.file('foo.dart', 'main() => "foo 2";')]),
            d.dir('foo-dep', [d.file('foo-dep.dart', 'main() => "foo-dep";')])]).validate();
  });
}
