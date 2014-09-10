library pub.validator.pubspec_field;
import 'dart:async';
import '../entrypoint.dart';
import '../validator.dart';
class PubspecFieldValidator extends Validator {
  PubspecFieldValidator(Entrypoint entrypoint) : super(entrypoint);
  Future validate() {
    _validateAuthors();
    _validateFieldIsString('description');
    _validateFieldIsString('homepage');
    _validateFieldUrl('homepage');
    _validateFieldUrl('documentation');
    _validateFieldIsString('version');
    for (var error in entrypoint.root.pubspec.allErrors) {
      errors.add('In your pubspec.yaml, ${error.message}');
    }
    return new Future.value();
  }
  void _validateAuthors() {
    var pubspec = entrypoint.root.pubspec;
    var author = pubspec.fields['author'];
    var authors = pubspec.fields['authors'];
    if (author == null && authors == null) {
      errors.add('Your pubspec.yaml must have an "author" or "authors" field.');
      return;
    }
    if (author != null && author is! String) {
      errors.add(
          'Your pubspec.yaml\'s "author" field must be a string, but it '
              'was "$author".');
      return;
    }
    if (authors != null &&
        (authors is! List || authors.any((author) => author is! String))) {
      errors.add(
          'Your pubspec.yaml\'s "authors" field must be a list, but '
              'it was "$authors".');
      return;
    }
    if (authors == null) authors = [author];
    var hasName = new RegExp(r"^ *[^< ]");
    var hasEmail = new RegExp(r"<[^>]+> *$");
    for (var authorName in authors) {
      if (!hasName.hasMatch(authorName)) {
        warnings.add(
            'Author "$authorName" in pubspec.yaml should have a ' 'name.');
      }
      if (!hasEmail.hasMatch(authorName)) {
        warnings.add(
            'Author "$authorName" in pubspec.yaml should have an '
                'email address\n(e.g. "name <email>").');
      }
    }
  }
  void _validateFieldIsString(String field) {
    var value = entrypoint.root.pubspec.fields[field];
    if (value == null) {
      errors.add('Your pubspec.yaml is missing a "$field" field.');
    } else if (value is! String) {
      errors.add(
          'Your pubspec.yaml\'s "$field" field must be a string, but '
              'it was "$value".');
    }
  }
  void _validateFieldUrl(String field) {
    var url = entrypoint.root.pubspec.fields[field];
    if (url == null) return;
    if (url is! String) {
      errors.add(
          'Your pubspec.yaml\'s "$field" field must be a string, but ' 'it was "$url".');
      return;
    }
    var goodScheme = new RegExp(r'^https?:');
    if (!goodScheme.hasMatch(url)) {
      errors.add(
          'Your pubspec.yaml\'s "$field" field must be an "http:" or '
              '"https:" URL, but it was "$url".');
    }
  }
}
