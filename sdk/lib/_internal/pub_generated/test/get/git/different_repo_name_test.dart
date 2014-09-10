library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      'doesn\'t require the repository name to match the name in the ' 'pubspec',
      () {
    ensureGit();
    d.git(
        'foo.git',
        [d.libDir('weirdname'), d.libPubspec('weirdname', '1.0.0')]).create();
    d.dir(appPath, [d.appPubspec({
        "weirdname": {
          "git": "../foo.git"
        }
      })]).create();
    pubGet();
    d.dir(
        packagesPath,
        [
            d.dir(
                'weirdname',
                [d.file('weirdname.dart', 'main() => "weirdname";')])]).validate();
  });
}
