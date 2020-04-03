// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Keyword;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateClassName(String name) {
  return _validateUpperCamelCase(name, 'Class');
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateConstructorName(String name) {
  if (name != null && name.isEmpty) {
    return RefactoringStatus();
  }
  return _validateLowerCamelCase(name, 'Constructor', allowBuiltIn: true);
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateFieldName(String name) {
  return _validateLowerCamelCase(name, 'Field', allowBuiltIn: true);
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateFunctionName(String name) {
  return _validateLowerCamelCase(name, 'Function', allowBuiltIn: true);
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateFunctionTypeAliasName(String name) {
  return _validateUpperCamelCase(name, 'Function type alias');
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateImportPrefixName(String name) {
  if (name != null && name.isEmpty) {
    return RefactoringStatus();
  }
  return _validateLowerCamelCase(name, 'Import prefix');
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateLabelName(String name) {
  return _validateLowerCamelCase(name, 'Label', allowBuiltIn: true);
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateLibraryName(String name) {
  // null
  if (name == null) {
    return RefactoringStatus.fatal('Library name must not be null.');
  }
  // blank
  if (isBlank(name)) {
    return RefactoringStatus.fatal('Library name must not be blank.');
  }
  // check identifiers
  var identifiers = name.split('.');
  for (var identifier in identifiers) {
    var status = _validateIdentifier(identifier, 'Library name identifier',
        'a lowercase letter or underscore');
    if (!status.isOK) {
      return status;
    }
  }
  // should not have upper-case letters
  for (var identifier in identifiers) {
    for (var c in identifier.codeUnits) {
      if (isUpperCase(c)) {
        return RefactoringStatus.warning(
            'Library name should consist of lowercase identifier separated by dots.');
      }
    }
  }
  // OK
  return RefactoringStatus();
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateMethodName(String name) {
  return _validateLowerCamelCase(name, 'Method', allowBuiltIn: true);
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateParameterName(String name) {
  return _validateLowerCamelCase(name, 'Parameter', allowBuiltIn: true);
}

/// Returns the [RefactoringStatus] with severity:
/// - OK if the name is valid;
/// - WARNING if the name is discouraged;
/// - FATAL if the name is illegal.
RefactoringStatus validateVariableName(String name) {
  return _validateLowerCamelCase(name, 'Variable', allowBuiltIn: true);
}

RefactoringStatus _validateIdentifier(
    String identifier, String desc, String beginDesc,
    {bool allowBuiltIn = false}) {
  // has leading/trailing spaces
  var trimmed = identifier.trim();
  if (identifier != trimmed) {
    var message = '$desc must not start or end with a blank.';
    return RefactoringStatus.fatal(message);
  }
  // empty
  var length = identifier.length;
  if (length == 0) {
    var message = '$desc must not be empty.';
    return RefactoringStatus.fatal(message);
  }
  // keyword
  {
    var keyword = Keyword.keywords[identifier];
    if (keyword != null) {
      if (keyword.isBuiltInOrPseudo && allowBuiltIn) {
        var message = 'Avoid using built-in identifiers as names.';
        return RefactoringStatus.warning(message);
      } else {
        var message = '$desc must not be a keyword.';
        return RefactoringStatus.fatal(message);
      }
    }
  }
  // invalid characters
  for (var i = 0; i < length; i++) {
    var currentChar = identifier.codeUnitAt(i);
    if (!isLetterOrDigit(currentChar) &&
        currentChar != CHAR_UNDERSCORE &&
        currentChar != CHAR_DOLLAR) {
      var charStr = String.fromCharCode(currentChar);
      var message = "$desc must not contain '$charStr'.";
      return RefactoringStatus.fatal(message);
    }
  }
  // first character
  var currentChar = identifier.codeUnitAt(0);
  if (!isLetter(currentChar) &&
      currentChar != CHAR_UNDERSCORE &&
      currentChar != CHAR_DOLLAR) {
    var message = '$desc must begin with $beginDesc.';
    return RefactoringStatus.fatal(message);
  }
  // OK
  return RefactoringStatus();
}

/// Validates [identifier], should be lower camel case.
RefactoringStatus _validateLowerCamelCase(String identifier, String desc,
    {bool allowBuiltIn = false}) {
  desc += ' name';
  // null
  if (identifier == null) {
    var message = '$desc must not be null.';
    return RefactoringStatus.fatal(message);
  }
  // is not identifier
  var status = _validateIdentifier(
      identifier, desc, 'a lowercase letter or underscore',
      allowBuiltIn: allowBuiltIn);
  if (!status.isOK) {
    return status;
  }
  // is private, OK
  if (identifier.codeUnitAt(0) == CHAR_UNDERSCORE) {
    return RefactoringStatus();
  }
  // leading $, OK
  if (identifier.codeUnitAt(0) == CHAR_DOLLAR) {
    return RefactoringStatus();
  }
  // does not start with lower case
  if (!isLowerCase(identifier.codeUnitAt(0))) {
    var message = '$desc should start with a lowercase letter.';
    return RefactoringStatus.warning(message);
  }
  // OK
  return RefactoringStatus();
}

/// Validate the given identifier, which should be upper camel case.
RefactoringStatus _validateUpperCamelCase(String identifier, String desc) {
  desc += ' name';
  // null
  if (identifier == null) {
    var message = '$desc must not be null.';
    return RefactoringStatus.fatal(message);
  }
  // is not identifier
  var status = _validateIdentifier(
      identifier, desc, 'an uppercase letter or underscore');
  if (!status.isOK) {
    return status;
  }
  // is private, OK
  if (identifier.codeUnitAt(0) == CHAR_UNDERSCORE) {
    return RefactoringStatus();
  }
  // leading $, OK
  if (identifier.codeUnitAt(0) == CHAR_DOLLAR) {
    return RefactoringStatus();
  }
  // does not start with upper case
  if (!isUpperCase(identifier.codeUnitAt(0))) {
    // By convention, class names usually start with an uppercase letter
    var message = '$desc should start with an uppercase letter.';
    return RefactoringStatus.warning(message);
  }
  // OK
  return RefactoringStatus();
}
