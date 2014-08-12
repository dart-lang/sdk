// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.naming_conventions;

import 'package:analysis_services/correction/status.dart';
import 'package:analysis_services/refactoring/refactoring.dart';
import 'package:analysis_services/src/refactoring/naming_conventions.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'abstract_refactoring.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(NamingConventionsTest);
}


@ReflectiveTestCase()
class NamingConventionsTest extends RefactoringTest {
  @override
  Refactoring get refactoring => null;

  void test_validateClassName_OK() {
    assertRefactoringStatusOK(validateClassName("NewName"));
  }

  void test_validateClassName_OK_leadingDollar() {
    assertRefactoringStatusOK(validateClassName("\$NewName"));
  }

  void test_validateClassName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateClassName("_NewName"));
  }

  void test_validateClassName_OK_middleDollar() {
    assertRefactoringStatusOK(validateClassName("New\$Name"));
  }

  void test_validateClassName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateClassName("newName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Class name should start with an uppercase letter.");
  }

  void test_validateClassName_empty() {
    assertRefactoringStatus(
        validateClassName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Class name must not be empty.");
  }

  void test_validateClassName_leadingBlanks() {
    assertRefactoringStatus(
        validateClassName(" NewName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Class name must not start or end with a blank.");
  }

  void test_validateClassName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateClassName("New-Name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Class name must not contain '-'.");
  }

  void test_validateClassName_notIdentifierStart() {
    assertRefactoringStatus(
        validateClassName("-NewName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Class name must begin with an uppercase letter or underscore.");
  }

  void test_validateClassName_null() {
    assertRefactoringStatus(
        validateClassName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Class name must not be null.");
  }

  void test_validateClassName_trailingBlanks() {
    assertRefactoringStatus(
        validateClassName("NewName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Class name must not start or end with a blank.");
  }
  void test_validateConstantName_OK() {
    assertRefactoringStatusOK(validateConstantName("NAME"));
  }

  void test_validateConstantName_OK_digit() {
    assertRefactoringStatusOK(validateConstantName("NAME2"));
  }

  void test_validateConstantName_OK_underscoreLeading() {
    assertRefactoringStatusOK(validateConstantName("_NAME"));
  }

  void test_validateConstantName_OK_underscoreMiddle() {
    assertRefactoringStatusOK(validateConstantName("MY_NEW_NAME"));
  }

  void test_validateConstantName_empty() {
    assertRefactoringStatus(
        validateConstantName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constant name must not be empty.");
  }

  void test_validateConstantName_leadingBlanks() {
    assertRefactoringStatus(
        validateConstantName(" NewName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constant name must not start or end with a blank.");
  }

  void test_validateConstantName_notAllCaps() {
    assertRefactoringStatus(
        validateConstantName("NewName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Constant name should be all uppercase with underscores.");
  }

  void test_validateConstantName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateConstantName("NA-ME"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constant name must not contain '-'.");
  }

  void test_validateConstantName_notIdentifierStart() {
    assertRefactoringStatus(
        validateConstantName("99_RED_BALLOONS"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Constant name must begin with an uppercase letter or underscore.");
  }

  void test_validateConstantName_null() {
    assertRefactoringStatus(
        validateConstantName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constant name must not be null.");
  }

  void test_validateConstantName_trailingBlanks() {
    assertRefactoringStatus(
        validateConstantName("NewName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constant name must not start or end with a blank.");
  }

  void test_validateConstructorName_OK() {
    assertRefactoringStatusOK(validateConstructorName("newName"));
  }

  void test_validateConstructorName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateConstructorName("_newName"));
  }

  void test_validateConstructorName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateConstructorName("NewName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Constructor name should start with a lowercase letter.");
  }

  void test_validateConstructorName_empty() {
    assertRefactoringStatusOK(validateConstructorName(""));
  }

  void test_validateConstructorName_leadingBlanks() {
    assertRefactoringStatus(
        validateConstructorName(" newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constructor name must not start or end with a blank.");
  }

  void test_validateConstructorName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateConstructorName("na-me"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constructor name must not contain '-'.");
  }

  void test_validateConstructorName_notIdentifierStart() {
    assertRefactoringStatus(
        validateConstructorName("2name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Constructor name must begin with a lowercase letter or underscore.");
  }

  void test_validateConstructorName_null() {
    assertRefactoringStatus(
        validateConstructorName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constructor name must not be null.");
  }

  void test_validateConstructorName_trailingBlanks() {
    assertRefactoringStatus(
        validateConstructorName("newName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Constructor name must not start or end with a blank.");
  }

  void test_validateFieldName_OK() {
    assertRefactoringStatusOK(validateFieldName("newName"));
  }

  void test_validateFieldName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateFieldName("_newName"));
  }

  void test_validateFieldName_OK_middleUnderscore() {
    assertRefactoringStatusOK(validateFieldName("new_name"));
  }

  void test_validateFieldName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateFieldName("NewName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Field name should start with a lowercase letter.");
  }

  void test_validateFieldName_empty() {
    assertRefactoringStatus(
        validateFieldName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Field name must not be empty.");
  }

  void test_validateFieldName_leadingBlanks() {
    assertRefactoringStatus(
        validateFieldName(" newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Field name must not start or end with a blank.");
  }

  void test_validateFieldName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateFieldName("new-Name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Field name must not contain '-'.");
  }

  void test_validateFieldName_notIdentifierStart() {
    assertRefactoringStatus(
        validateFieldName("2newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Field name must begin with a lowercase letter or underscore.");
  }

  void test_validateFieldName_null() {
    assertRefactoringStatus(
        validateFieldName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Field name must not be null.");
  }

  void test_validateFieldName_trailingBlanks() {
    assertRefactoringStatus(
        validateFieldName("newName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Field name must not start or end with a blank.");
  }

  void test_validateFunctionName_OK() {
    assertRefactoringStatusOK(validateFunctionName("newName"));
  }

  void test_validateFunctionName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateFunctionName("_newName"));
  }

  void test_validateFunctionName_OK_middleUnderscore() {
    assertRefactoringStatusOK(validateFunctionName("new_name"));
  }

  void test_validateFunctionName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateFunctionName("NewName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Function name should start with a lowercase letter.");
  }

  void test_validateFunctionName_empty() {
    assertRefactoringStatus(
        validateFunctionName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Function name must not be empty.");
  }

  void test_validateFunctionName_leadingBlanks() {
    assertRefactoringStatus(
        validateFunctionName(" newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Function name must not start or end with a blank.");
  }

  void test_validateFunctionName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateFunctionName("new-Name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Function name must not contain '-'.");
  }

  void test_validateFunctionName_notIdentifierStart() {
    assertRefactoringStatus(
        validateFunctionName("2newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Function name must begin with a lowercase letter or underscore.");
  }

  void test_validateFunctionName_null() {
    assertRefactoringStatus(
        validateFunctionName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Function name must not be null.");
  }

  void test_validateFunctionName_trailingBlanks() {
    assertRefactoringStatus(
        validateFunctionName("newName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Function name must not start or end with a blank.");
  }

  void test_validateFunctionTypeAliasName_OK() {
    assertRefactoringStatusOK(validateFunctionTypeAliasName("NewName"));
  }

  void test_validateFunctionTypeAliasName_OK_leadingDollar() {
    assertRefactoringStatusOK(validateFunctionTypeAliasName("\$NewName"));
  }

  void test_validateFunctionTypeAliasName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateFunctionTypeAliasName("_NewName"));
  }

  void test_validateFunctionTypeAliasName_OK_middleDollar() {
    assertRefactoringStatusOK(validateFunctionTypeAliasName("New\$Name"));
  }

  void test_validateFunctionTypeAliasName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateFunctionTypeAliasName("newName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage:
            "Function type alias name should start with an uppercase letter.");
  }

  void test_validateFunctionTypeAliasName_empty() {
    assertRefactoringStatus(
        validateFunctionTypeAliasName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Function type alias name must not be empty.");
  }

  void test_validateFunctionTypeAliasName_leadingBlanks() {
    assertRefactoringStatus(
        validateFunctionTypeAliasName(" NewName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Function type alias name must not start or end with a blank.");
  }

  void test_validateFunctionTypeAliasName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateFunctionTypeAliasName("New-Name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Function type alias name must not contain '-'.");
  }

  void test_validateFunctionTypeAliasName_notIdentifierStart() {
    assertRefactoringStatus(
        validateFunctionTypeAliasName("-NewName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Function type alias name must begin with an uppercase letter or underscore.");
  }

  void test_validateFunctionTypeAliasName_null() {
    assertRefactoringStatus(
        validateFunctionTypeAliasName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Function type alias name must not be null.");
  }

  void test_validateFunctionTypeAliasName_trailingBlanks() {
    assertRefactoringStatus(
        validateFunctionTypeAliasName("NewName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Function type alias name must not start or end with a blank.");
  }

  void test_validateImportPrefixName_OK() {
    assertRefactoringStatusOK(validateImportPrefixName("newName"));
  }

  void test_validateImportPrefixName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateImportPrefixName("_newName"));
  }

  void test_validateImportPrefixName_OK_middleUnderscore() {
    assertRefactoringStatusOK(validateImportPrefixName("new_name"));
  }

  void test_validateImportPrefixName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateImportPrefixName("NewName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Import prefix name should start with a lowercase letter.");
  }

  void test_validateImportPrefixName_empty() {
    assertRefactoringStatusOK(validateImportPrefixName(""));
  }

  void test_validateImportPrefixName_leadingBlanks() {
    assertRefactoringStatus(
        validateImportPrefixName(" newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Import prefix name must not start or end with a blank.");
  }

  void test_validateImportPrefixName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateImportPrefixName("new-Name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Import prefix name must not contain '-'.");
  }

  void test_validateImportPrefixName_notIdentifierStart() {
    assertRefactoringStatus(
        validateImportPrefixName("2newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Import prefix name must begin with a lowercase letter or underscore.");
  }

  void test_validateImportPrefixName_null() {
    assertRefactoringStatus(
        validateImportPrefixName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Import prefix name must not be null.");
  }

  void test_validateImportPrefixName_trailingBlanks() {
    assertRefactoringStatus(
        validateImportPrefixName("newName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Import prefix name must not start or end with a blank.");
  }

  void test_validateLibraryName_OK_oneIdentifier() {
    assertRefactoringStatusOK(validateLibraryName("name"));
  }

  void test_validateLibraryName_OK_severalIdentifiers() {
    assertRefactoringStatusOK(validateLibraryName("my.library.name"));
  }

  void test_validateLibraryName_blank() {
    assertRefactoringStatus(
        validateLibraryName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Library name must not be blank.");
    assertRefactoringStatus(
        validateLibraryName(" "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Library name must not be blank.");
  }

  void test_validateLibraryName_blank_identifier() {
    assertRefactoringStatus(
        validateLibraryName("my..name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Library name identifier must not be empty.");
    assertRefactoringStatus(
        validateLibraryName("my. .name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Library name identifier must not start or end with a blank.");
  }

  void test_validateLibraryName_hasUpperCase() {
    assertRefactoringStatus(
        validateLibraryName("my.newName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage:
            "Library name should consist of lowercase identifier separated by dots.");
  }

  void test_validateLibraryName_leadingBlanks() {
    assertRefactoringStatus(
        validateLibraryName("my. name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Library name identifier must not start or end with a blank.");
  }

  void test_validateLibraryName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateLibraryName("my.ba-d.name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Library name identifier must not contain '-'.");
  }

  void test_validateLibraryName_notIdentifierStart() {
    assertRefactoringStatus(
        validateLibraryName("my.2bad.name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Library name identifier must begin with a lowercase letter or underscore.");
  }

  void test_validateLibraryName_null() {
    assertRefactoringStatus(
        validateLibraryName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Library name must not be null.");
  }

  void test_validateLibraryName_trailingBlanks() {
    assertRefactoringStatus(
        validateLibraryName("my.bad .name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Library name identifier must not start or end with a blank.");
  }

  void test_validateMethodName_OK() {
    assertRefactoringStatusOK(validateMethodName("newName"));
  }

  void test_validateMethodName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateMethodName("_newName"));
  }

  void test_validateMethodName_OK_middleUnderscore() {
    assertRefactoringStatusOK(validateMethodName("new_name"));
  }

  void test_validateMethodName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateMethodName("NewName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Method name should start with a lowercase letter.");
  }

  void test_validateMethodName_empty() {
    assertRefactoringStatus(
        validateMethodName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Method name must not be empty.");
  }

  void test_validateMethodName_leadingBlanks() {
    assertRefactoringStatus(
        validateMethodName(" newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Method name must not start or end with a blank.");
  }

  void test_validateMethodName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateMethodName("new-Name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Method name must not contain '-'.");
  }

  void test_validateMethodName_notIdentifierStart() {
    assertRefactoringStatus(
        validateMethodName("2newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Method name must begin with a lowercase letter or underscore.");
  }

  void test_validateMethodName_null() {
    assertRefactoringStatus(
        validateMethodName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Method name must not be null.");
  }

  void test_validateMethodName_trailingBlanks() {
    assertRefactoringStatus(
        validateMethodName("newName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Method name must not start or end with a blank.");
  }

  void test_validateParameterName_OK() {
    assertRefactoringStatusOK(validateParameterName("newName"));
  }

  void test_validateParameterName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateParameterName("_newName"));
  }

  void test_validateParameterName_OK_middleUnderscore() {
    assertRefactoringStatusOK(validateParameterName("new_name"));
  }

  void test_validateParameterName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateParameterName("NewName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Parameter name should start with a lowercase letter.");
  }

  void test_validateParameterName_empty() {
    assertRefactoringStatus(
        validateParameterName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Parameter name must not be empty.");
  }

  void test_validateParameterName_leadingBlanks() {
    assertRefactoringStatus(
        validateParameterName(" newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Parameter name must not start or end with a blank.");
  }

  void test_validateParameterName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateParameterName("new-Name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Parameter name must not contain '-'.");
  }

  void test_validateParameterName_notIdentifierStart() {
    assertRefactoringStatus(
        validateParameterName("2newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Parameter name must begin with a lowercase letter or underscore.");
  }

  void test_validateParameterName_null() {
    assertRefactoringStatus(
        validateParameterName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Parameter name must not be null.");
  }

  void test_validateParameterName_trailingBlanks() {
    assertRefactoringStatus(
        validateParameterName("newName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Parameter name must not start or end with a blank.");
  }

  void test_validateVariableName_OK() {
    assertRefactoringStatusOK(validateVariableName("newName"));
  }

  void test_validateVariableName_OK_leadingDollar() {
    assertRefactoringStatusOK(validateVariableName("\$newName"));
  }

  void test_validateVariableName_OK_leadingUnderscore() {
    assertRefactoringStatusOK(validateVariableName("_newName"));
  }

  void test_validateVariableName_OK_middleUnderscore() {
    assertRefactoringStatusOK(validateVariableName("new_name"));
  }

  void test_validateVariableName_doesNotStartWithLowerCase() {
    assertRefactoringStatus(
        validateVariableName("NewName"),
        RefactoringStatusSeverity.WARNING,
        expectedMessage: "Variable name should start with a lowercase letter.");
  }

  void test_validateVariableName_empty() {
    assertRefactoringStatus(
        validateVariableName(""),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Variable name must not be empty.");
  }

  void test_validateVariableName_leadingBlanks() {
    assertRefactoringStatus(
        validateVariableName(" newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Variable name must not start or end with a blank.");
  }

  void test_validateVariableName_notIdentifierMiddle() {
    assertRefactoringStatus(
        validateVariableName("new-Name"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Variable name must not contain '-'.");
  }

  void test_validateVariableName_notIdentifierStart() {
    assertRefactoringStatus(
        validateVariableName("2newName"),
        RefactoringStatusSeverity.ERROR,
        expectedMessage:
            "Variable name must begin with a lowercase letter or underscore.");
  }

  void test_validateVariableName_null() {
    assertRefactoringStatus(
        validateVariableName(null),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Variable name must not be null.");
  }

  void test_validateVariableName_trailingBlanks() {
    assertRefactoringStatus(
        validateVariableName("newName "),
        RefactoringStatusSeverity.ERROR,
        expectedMessage: "Variable name must not start or end with a blank.");
  }
}
