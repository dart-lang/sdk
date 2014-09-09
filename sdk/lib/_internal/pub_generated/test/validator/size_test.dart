import 'dart:async';
import 'dart:math' as math;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/validator/size.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
Function size(int size) {
  return (entrypoint) => new SizeValidator(entrypoint, new Future.value(size));
}
main() {
  initConfig();
  setUp(d.validPackage.create);
  integration('should consider a package valid if it is <= 10 MB', () {
    expectNoValidationError(size(100));
    expectNoValidationError(size(10 * math.pow(2, 20)));
  });
  integration('should consider a package invalid if it is more than 10 MB', () {
    expectValidationError(size(10 * math.pow(2, 20) + 1));
  });
}
