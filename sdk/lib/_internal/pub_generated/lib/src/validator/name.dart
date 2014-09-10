library pub.validator.name;
import 'dart:async';
import 'package:path/path.dart' as path;
import '../entrypoint.dart';
import '../io.dart';
import '../utils.dart';
import '../validator.dart';
final _RESERVED_WORDS = [
    "assert",
    "break",
    "case",
    "catch",
    "class",
    "const",
    "continue",
    "default",
    "do",
    "else",
    "extends",
    "false",
    "final",
    "finally",
    "for",
    "if",
    "in",
    "is",
    "new",
    "null",
    "return",
    "super",
    "switch",
    "this",
    "throw",
    "true",
    "try",
    "var",
    "void",
    "while",
    "with"];
class NameValidator extends Validator {
  NameValidator(Entrypoint entrypoint) : super(entrypoint);
  Future validate() {
    return syncFuture(() {
      _checkName(
          entrypoint.root.name,
          'Package name "${entrypoint.root.name}"',
          isPackage: true);
      var libraries = _libraries;
      for (var library in libraries) {
        var libName = path.basenameWithoutExtension(library);
        _checkName(
            libName,
            'The name of "$library", "$libName",',
            isPackage: false);
      }
      if (libraries.length == 1) {
        var libName = path.basenameWithoutExtension(libraries[0]);
        if (libName == entrypoint.root.name) return;
        warnings.add(
            'The name of "${libraries[0]}", "$libName", should match '
                'the name of the package, "${entrypoint.root.name}".\n'
                'This helps users know what library to import.');
      }
    });
  }
  List<String> get _libraries {
    var libDir = path.join(entrypoint.root.dir, "lib");
    if (!dirExists(libDir)) return [];
    return entrypoint.root.listFiles(
        beneath: libDir).map(
            (file) =>
                path.relative(
                    file,
                    from: path.dirname(
                        libDir))).where(
                            (file) =>
                                !path.split(file).contains("src") && path.extension(file) == '.dart').toList();
  }
  void _checkName(String name, String description, {bool isPackage}) {
    var messages = isPackage ? errors : warnings;
    if (name == "") {
      errors.add("$description may not be empty.");
    } else if (!new RegExp(r"^[a-zA-Z0-9_]*$").hasMatch(name)) {
      messages.add(
          "$description may only contain letters, numbers, and " "underscores.\n"
              "Using a valid Dart identifier makes the name usable in Dart code.");
    } else if (!new RegExp(r"^[a-zA-Z_]").hasMatch(name)) {
      messages.add(
          "$description must begin with a letter or underscore.\n"
              "Using a valid Dart identifier makes the name usable in Dart code.");
    } else if (_RESERVED_WORDS.contains(name.toLowerCase())) {
      messages.add(
          "$description may not be a reserved word in Dart.\n"
              "Using a valid Dart identifier makes the name usable in Dart code.");
    } else if (new RegExp(r"[A-Z]").hasMatch(name)) {
      warnings.add(
          '$description should be lower-case. Maybe use ' '"${_unCamelCase(name)}"?');
    }
  }
  String _unCamelCase(String source) {
    var builder = new StringBuffer();
    var lastMatchEnd = 0;
    for (var match in new RegExp(r"[a-z]([A-Z])").allMatches(source)) {
      builder
          ..write(source.substring(lastMatchEnd, match.start + 1))
          ..write("_")
          ..write(match.group(1).toLowerCase());
      lastMatchEnd = match.end;
    }
    builder.write(source.substring(lastMatchEnd));
    return builder.toString().toLowerCase();
  }
}
