library pub.validator;
import 'dart:async';
import 'entrypoint.dart';
import 'log.dart' as log;
import 'utils.dart';
import 'validator/compiled_dartdoc.dart';
import 'validator/dependency.dart';
import 'validator/dependency_override.dart';
import 'validator/directory.dart';
import 'validator/executable.dart';
import 'validator/license.dart';
import 'validator/name.dart';
import 'validator/pubspec_field.dart';
import 'validator/size.dart';
import 'validator/utf8_readme.dart';
abstract class Validator {
  final Entrypoint entrypoint;
  final errors = <String>[];
  final warnings = <String>[];
  Validator(this.entrypoint);
  Future validate();
  static Future<Pair<List<String>, List<String>>> runAll(Entrypoint entrypoint,
      [Future<int> packageSize]) {
    var validators = [
        new LicenseValidator(entrypoint),
        new NameValidator(entrypoint),
        new PubspecFieldValidator(entrypoint),
        new DependencyValidator(entrypoint),
        new DependencyOverrideValidator(entrypoint),
        new DirectoryValidator(entrypoint),
        new ExecutableValidator(entrypoint),
        new CompiledDartdocValidator(entrypoint),
        new Utf8ReadmeValidator(entrypoint)];
    if (packageSize != null) {
      validators.add(new SizeValidator(entrypoint, packageSize));
    }
    return Future.wait(
        validators.map((validator) => validator.validate())).then((_) {
      var errors = flatten(validators.map((validator) => validator.errors));
      var warnings = flatten(validators.map((validator) => validator.warnings));
      if (!errors.isEmpty) {
        log.error("Missing requirements:");
        for (var error in errors) {
          log.error("* ${error.split('\n').join('\n  ')}");
        }
        log.error("");
      }
      if (!warnings.isEmpty) {
        log.warning("Suggestions:");
        for (var warning in warnings) {
          log.warning("* ${warning.split('\n').join('\n  ')}");
        }
        log.warning("");
      }
      return new Pair<List<String>, List<String>>(errors, warnings);
    });
  }
}
