library pub.validator.size;
import 'dart:async';
import 'dart:math' as math;
import '../entrypoint.dart';
import '../validator.dart';
const _MAX_SIZE = 10 * 1024 * 1024;
class SizeValidator extends Validator {
  final Future<int> packageSize;
  SizeValidator(Entrypoint entrypoint, this.packageSize) : super(entrypoint);
  Future validate() {
    return packageSize.then((size) {
      if (size <= _MAX_SIZE) return;
      var sizeInMb = (size / math.pow(2, 20)).toStringAsPrecision(4);
      errors.add(
          "Your package is $sizeInMb MB. Hosted packages must be " "smaller than 10 MB.");
    });
  }
}
