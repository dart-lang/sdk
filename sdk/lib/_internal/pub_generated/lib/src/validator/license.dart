library pub.validator.license;
import 'dart:async';
import 'package:path/path.dart' as path;
import '../entrypoint.dart';
import '../utils.dart';
import '../validator.dart';
class LicenseValidator extends Validator {
  LicenseValidator(Entrypoint entrypoint) : super(entrypoint);
  Future validate() {
    return new Future.sync(() {
      var licenseLike =
          new RegExp(r"^([a-zA-Z0-9]+[-_])?(LICENSE|COPYING)(\..*)?$");
      if (entrypoint.root.listFiles(
          recursive: false).map(path.basename).any(licenseLike.hasMatch)) {
        return;
      }
      errors.add(
          "You must have a COPYING or LICENSE file in the root directory.\n"
              "An open-source license helps ensure people can legally use your " "code.");
    });
  }
}
