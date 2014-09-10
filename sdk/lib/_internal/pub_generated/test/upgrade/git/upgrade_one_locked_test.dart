library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("upgrades one locked Git package but no others", () {
    ensureGit();
    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]).create();
    d.git('bar.git', [d.libDir('bar'), d.libPubspec('bar', '1.0.0')]).create();
    d.appDir({
      "foo": {
        "git": "../foo.git"
      },
      "bar": {
        "git": "../bar.git"
      }
    }).create();
    pubGet();
    d.dir(
        packagesPath,
        [
            d.dir('foo', [d.file('foo.dart', 'main() => "foo";')]),
            d.dir('bar', [d.file('bar.dart', 'main() => "bar";')])]).validate();
    d.git(
        'foo.git',
        [d.libDir('foo', 'foo 2'), d.libPubspec('foo', '1.0.0')]).commit();
    d.git(
        'bar.git',
        [d.libDir('bar', 'bar 2'), d.libPubspec('bar', '1.0.0')]).commit();
    pubUpgrade(args: ['foo']);
    d.dir(
        packagesPath,
        [
            d.dir('foo', [d.file('foo.dart', 'main() => "foo 2";')]),
            d.dir('bar', [d.file('bar.dart', 'main() => "bar";')])]).validate();
  });
}
