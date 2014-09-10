library validator.utils;
import 'package:scheduled_test/scheduled_test.dart';
import '../test_pub.dart';
void expectNoValidationError(ValidatorCreator fn) {
  expect(schedulePackageValidation(fn), completion(pairOf(isEmpty, isEmpty)));
}
void expectValidationError(ValidatorCreator fn) {
  expect(
      schedulePackageValidation(fn),
      completion(pairOf(isNot(isEmpty), anything)));
}
void expectValidationWarning(ValidatorCreator fn) {
  expect(
      schedulePackageValidation(fn),
      completion(pairOf(isEmpty, isNot(isEmpty))));
}
