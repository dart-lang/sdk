library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('checks out a package at a specific revision from Git', () {
    ensureGit();
    var repo =
        d.git('foo.git', [d.libDir('foo', 'foo 1'), d.libPubspec('foo', '1.0.0')]);
    repo.create();
    var commit = repo.revParse('HEAD');
    d.git(
        'foo.git',
        [d.libDir('foo', 'foo 2'), d.libPubspec('foo', '1.0.0')]).commit();
    d.appDir({
      "foo": {
        "git": {
          "url": "../foo.git",
          "ref": commit
        }
      }
    }).create();
    pubGet();
    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo 1";')])]).validate();
  });
}
