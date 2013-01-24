// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library name_validator;

import 'dart:async';
import 'dart:io';

import '../../../pkg/path/lib/path.dart' as path;
import '../entrypoint.dart';
import '../io.dart';
import '../validator.dart';

/// Dart reserved words, from the Dart spec.
final _RESERVED_WORDS = [
  "abstract", "as", "dynamic", "export", "external", "factory", "get",
  "implements", "import", "library", "operator", "part", "set", "static",
  "typedef"
];

/// A validator that validates the name of the package and its libraries.
class NameValidator extends Validator {
  NameValidator(Entrypoint entrypoint)
    : super(entrypoint);

  Future validate() {
    _checkName(entrypoint.root.name, 'Package name "${entrypoint.root.name}"');

    return _libraries.then((libraries) {
      for (var library in libraries) {
        var libName = path.basenameWithoutExtension(library);
        _checkName(libName, 'The name of "$library", "$libName",');
      }

      if (libraries.length == 1) {
        var libName = path.basenameWithoutExtension(libraries[0]);
        if (libName == entrypoint.root.name) return;
        warnings.add('The name of "${libraries[0]}", "$libName", should match '
            'the name of the package, "${entrypoint.root.name}".\n'
            'This helps users know what library to import.');
      }
    });
  }

  /// Returns a list of all libraries in the current package as paths relative
  /// to the package's root directory.
  Future<List<String>> get _libraries {
    var libDir = join(entrypoint.root.dir, "lib");
    return dirExists(libDir).then((libDirExists) {
      if (!libDirExists) return [];
      return listDir(libDir, recursive: true);
    }).then((files) {
      return files
          .mappedBy((file) => relativeTo(file, dirname(libDir)))
          .where((file) => !splitPath(file).contains("src") &&
                           path.extension(file) == '.dart')
          .toList();
    });
  }

  void _checkName(String name, String description) {
    if (name == "") {
      errors.add("$description may not be empty.");
    } else if (!new RegExp(r"^[a-zA-Z0-9_]*$").hasMatch(name)) {
      errors.add("$description may only contain letters, numbers, and "
          "underscores.\n"
          "Using a valid Dart identifier makes the name usable in Dart code.");
    } else if (!new RegExp(r"^[a-zA-Z]").hasMatch(name)) {
      errors.add("$description must begin with letter.\n"
          "Using a valid Dart identifier makes the name usable in Dart code.");
    } else if (_RESERVED_WORDS.contains(name.toLowerCase())) {
      errors.add("$description may not be a reserved word in Dart.\n"
          "Using a valid Dart identifier makes the name usable in Dart code.");
    } else if (new RegExp(r"[A-Z]").hasMatch(name)) {
      warnings.add('$description should be lower-case. Maybe use '
          '"${_unCamelCase(name)}"?');
    }
  }

  String _unCamelCase(String source) {
    var builder = new StringBuffer();
    var lastMatchEnd = 0;
    for (var match in new RegExp(r"[a-z]([A-Z])").allMatches(source)) {
      builder
        ..add(source.substring(lastMatchEnd, match.start + 1))
        ..add("_")
        ..add(match.group(1).toLowerCase());
      lastMatchEnd = match.end;
    }
    builder.add(source.substring(lastMatchEnd));
    return builder.toString().toLowerCase();
  }
}
