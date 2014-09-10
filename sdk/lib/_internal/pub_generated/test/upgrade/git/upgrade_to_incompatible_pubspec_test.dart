library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("upgrades Git packages to an incompatible pubspec", () {
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
    d.git('foo.git', [d.libDir('zoo'), d.libPubspec('zoo', '1.0.0')]).commit();
    pubUpgrade(
        error: contains('"name" field doesn\'t match expected name ' '"foo".'),
        exitCode: exit_codes.DATA);
    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();
  });
}
