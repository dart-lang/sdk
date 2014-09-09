import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/entrypoint.dart';
import '../../lib/src/validator.dart';
import '../../lib/src/validator/utf8_readme.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
Validator utf8Readme(Entrypoint entrypoint) =>
    new Utf8ReadmeValidator(entrypoint);
main() {
  initConfig();
  group('should consider a package valid if it', () {
    setUp(d.validPackage.create);
    integration('looks normal', () => expectNoValidationError(utf8Readme));
    integration('has a non-primary readme with invalid utf-8', () {
      d.dir(
          appPath,
          [
              d.file("README", "Valid utf-8"),
              d.binaryFile("README.invalid", [192])]).create();
      expectNoValidationError(utf8Readme);
    });
  });
  integration(
      'should consider a package invalid if it has a README with ' 'invalid utf-8',
      () {
    d.validPackage.create();
    d.dir(appPath, [d.binaryFile("README", [192])]).create();
    expectValidationWarning(utf8Readme);
  });
}
