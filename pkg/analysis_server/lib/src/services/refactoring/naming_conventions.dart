// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:front_end/src/scanner/token.dart' show Keyword;

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateClassName(String name) {
  return _validateUpperCamelCase(name, "Class");
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateConstructorName(String name) {
  if (name != null && name.isEmpty) {
    return new RefactoringStatus();
  }
  return _validateLowerCamelCase(name, "Constructor", allowBuiltIn: true);
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateFieldName(String name) {
  return _validateLowerCamelCase(name, "Field", allowBuiltIn: true);
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateFunctionName(String name) {
  return _validateLowerCamelCase(name, "Function", allowBuiltIn: true);
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateFunctionTypeAliasName(String name) {
  return _validateUpperCamelCase(name, "Function type alias");
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateImportPrefixName(String name) {
  if (name != null && name.isEmpty) {
    return new RefactoringStatus();
  }
  return _validateLowerCamelCase(name, "Import prefix");
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateLabelName(String name) {
  return _validateLowerCamelCase(name, "Label", allowBuiltIn: true);
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateLibraryName(String name) {
  // null
  if (name == null) {
    return new RefactoringStatus.fatal("Library name must not be null.");
  }
  // blank
  if (isBlank(name)) {
    return new RefactoringStatus.fatal("Library name must not be blank.");
  }
  // check identifiers
  List<String> identifiers = name.split('.');
  for (String identifier in identifiers) {
    RefactoringStatus status = _validateIdentifier(identifier,
        "Library name identifier", "a lowercase letter or underscore");
    if (!status.isOK) {
      return status;
    }
  }
  // should not have upper-case letters
  for (String identifier in identifiers) {
    for (int c in identifier.codeUnits) {
      if (isUpperCase(c)) {
        return new RefactoringStatus.warning(
            "Library name should consist of lowercase identifier separated by dots.");
      }
    }
  }
  // OK
  return new RefactoringStatus();
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateMethodName(String name) {
  return _validateLowerCamelCase(name, "Method", allowBuiltIn: true);
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateParameterName(String name) {
  return _validateLowerCamelCase(name, "Parameter", allowBuiltIn: true);
}

/**
 * Returns the [RefactoringStatus] with severity:
 *   OK if the name is valid;
 *   WARNING if the name is discouraged;
 *   FATAL if the name is illegal.
 */
RefactoringStatus validateVariableName(String name) {
  return _validateLowerCamelCase(name, "Variable", allowBuiltIn: true);
}

RefactoringStatus _validateIdentifier(
    String identifier, String desc, String beginDesc,
    {bool allowBuiltIn: false}) {
  // has leading/trailing spaces
  String trimmed = identifier.trim();
  if (identifier != trimmed) {
    String message = "$desc must not start or end with a blank.";
    return new RefactoringStatus.fatal(message);
  }
  // empty
  int length = identifier.length;
  if (length == 0) {
    String message = "$desc must not be empty.";
    return new RefactoringStatus.fatal(message);
  }
  // keyword
  {
    Keyword keyword = Keyword.keywords[identifier];
    if (keyword != null) {
      if (keyword.isBuiltInOrPseudo && allowBuiltIn) {
        String message = "Avoid using built-in identifiers as names.";
        return new RefactoringStatus.warning(message);
      } else {
        String message = "$desc must not be a keyword.";
        return new RefactoringStatus.fatal(message);
      }
    }
  }
  // invalid characters
  for (int i = 0; i < length; i++) {
    int currentChar = identifier.codeUnitAt(i);
    if (!isLetterOrDigit(currentChar) &&
        currentChar != CHAR_UNDERSCORE &&
        currentChar != CHAR_DOLLAR) {
      String charStr = new String.fromCharCode(currentChar);
      String message = "$desc must not contain '$charStr'.";
      return new RefactoringStatus.fatal(message);
    }
  }
  // first character
  final int currentChar = identifier.codeUnitAt(0);
  if (!isLetter(currentChar) &&
      currentChar != CHAR_UNDERSCORE &&
      currentChar != CHAR_DOLLAR) {
    String message = "$desc must begin with $beginDesc.";
    return new RefactoringStatus.fatal(message);
  }
  // OK
  return new RefactoringStatus();
}

/**
 * Validates [identifier], should be lower camel case.
 */
RefactoringStatus _validateLowerCamelCase(String identifier, String desc,
    {bool allowBuiltIn: false}) {
  desc += ' name';
  // null
  if (identifier == null) {
    String message = "$desc must not be null.";
    return new RefactoringStatus.fatal(message);
  }
  // is not identifier
  RefactoringStatus status = _validateIdentifier(
      identifier, desc, "a lowercase letter or underscore",
      allowBuiltIn: allowBuiltIn);
  if (!status.isOK) {
    return status;
  }
  // is private, OK
  if (identifier.codeUnitAt(0) == CHAR_UNDERSCORE) {
    return new RefactoringStatus();
  }
  // leading $, OK
  if (identifier.codeUnitAt(0) == CHAR_DOLLAR) {
    return new RefactoringStatus();
  }
  // does not start with lower case
  if (!isLowerCase(identifier.codeUnitAt(0))) {
    String message = "$desc should start with a lowercase letter.";
    return new RefactoringStatus.warning(message);
  }
  // OK
  return new RefactoringStatus();
}

/**
 * Validate the given identifier, which should be upper camel case.
 */
RefactoringStatus _validateUpperCamelCase(String identifier, String desc) {
  desc += ' name';
  // null
  if (identifier == null) {
    String message = "$desc must not be null.";
    return new RefactoringStatus.fatal(message);
  }
  // is not identifier
  RefactoringStatus status = _validateIdentifier(
      identifier, desc, "an uppercase letter or underscore");
  if (!status.isOK) {
    return status;
  }
  // is private, OK
  if (identifier.codeUnitAt(0) == CHAR_UNDERSCORE) {
    return new RefactoringStatus();
  }
  // leading $, OK
  if (identifier.codeUnitAt(0) == CHAR_DOLLAR) {
    return new RefactoringStatus();
  }
  // does not start with upper case
  if (!isUpperCase(identifier.codeUnitAt(0))) {
    // By convention, class names usually start with an uppercase letter
    String message = "$desc should start with an uppercase letter.";
    return new RefactoringStatus.warning(message);
  }
  // OK
  return new RefactoringStatus();
}
