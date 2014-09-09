import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/entrypoint.dart';
import '../../lib/src/validator.dart';
import '../../lib/src/validator/directory.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
Validator directory(Entrypoint entrypoint) =>
    new DirectoryValidator(entrypoint);
main() {
  initConfig();
  group('should consider a package valid if it', () {
    setUp(d.validPackage.create);
    integration('looks normal', () => expectNoValidationError(directory));
    integration('has a nested directory named "tools"', () {
      d.dir(appPath, [d.dir("foo", [d.dir("tools")])]).create();
      expectNoValidationError(directory);
    });
  });
  group(
      'should consider a package invalid if it has a top-level directory ' 'named',
      () {
    setUp(d.validPackage.create);
    var names = [
        "benchmarks",
        "docs",
        "examples",
        "sample",
        "samples",
        "tests",
        "tools"];
    for (var name in names) {
      integration('"$name"', () {
        d.dir(appPath, [d.dir(name)]).create();
        expectValidationWarning(directory);
      });
    }
  });
}
