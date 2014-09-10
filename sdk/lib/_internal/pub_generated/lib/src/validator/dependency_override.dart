library pub.validator.dependency_override;
import 'dart:async';
import '../entrypoint.dart';
import '../validator.dart';
class DependencyOverrideValidator extends Validator {
  DependencyOverrideValidator(Entrypoint entrypoint) : super(entrypoint);
  Future validate() {
    if (entrypoint.root.dependencyOverrides.isNotEmpty) {
      errors.add(
          'Your pubspec.yaml must not have a "dependency_overrides" field.\n'
              'This ensures you test your package against the same versions of '
              'its dependencies\n' 'that users will have when they use it.');
    }
    return new Future.value();
  }
}
