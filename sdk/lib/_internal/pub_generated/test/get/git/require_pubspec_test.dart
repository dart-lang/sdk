library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('requires the dependency to have a pubspec', () {
    ensureGit();
    d.git('foo.git', [d.libDir('foo')]).create();
    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();
    pubGet(
        error: new RegExp(
            r'Could not find a file named "pubspec\.yaml" ' r'in "[^\n]*"\.'));
  });
}
