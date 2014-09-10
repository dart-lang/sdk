library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      "gets first if a git dependency's ref doesn't match the one in "
          "the lock file",
      () {
    var repo =
        d.git('foo.git', [d.libDir('foo', 'before'), d.libPubspec('foo', '1.0.0')]);
    repo.create();
    var commit1 = repo.revParse('HEAD');
    d.git(
        'foo.git',
        [d.libDir('foo', 'after'), d.libPubspec('foo', '1.0.0')]).commit();
    var commit2 = repo.revParse('HEAD');
    d.appDir({
      "foo": {
        "git": {
          "url": "../foo.git",
          "ref": commit1
        }
      }
    }).create();
    pubGet();
    d.appDir({
      "foo": {
        "git": {
          "url": "../foo.git",
          "ref": commit2
        }
      }
    }).create();
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "after";');
    endPubServe();
  });
}
