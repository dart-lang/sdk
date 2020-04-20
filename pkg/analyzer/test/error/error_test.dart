// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../generated/parser_test.dart';

main() {
  _analyzerRootComponents = path.split(path.fromUri(Platform.script));
  int index = _analyzerRootComponents.lastIndexOf('analyzer');
  _analyzerRootComponents = _analyzerRootComponents.sublist(0, index + 1);
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorCodeValuesTest);
  });
}

List<String> _analyzerRootComponents;

@reflectiveTest
class ErrorCodeValuesTest extends ParserTestCase {
  bool bad() {
    return false;
  }

  List<String> getDeclaredCodes(List<String> relativeComponents) {
    List<String> declaredCodes = <String>[];
    CompilationUnit definingUnit = parseFile(relativeComponents);
    for (CompilationUnitMember declaration in definingUnit.declarations) {
      if (declaration is ClassDeclaration) {
        ExtendsClause extendsClause = declaration.extendsClause;
        if (extendsClause != null &&
            extendsClause.superclass.name.name == 'ErrorCode') {
          String className = declaration.name.name;
          for (ClassMember member in declaration.members) {
            if (member is FieldDeclaration &&
                member.isStatic &&
                (member.fields.type == null ? bad() : true) &&
                member.fields.type.toSource() == className) {
              String fieldName = member.fields.variables[0].name.name;
              declaredCodes.add(className + '.' + fieldName);
            }
          }
        }
      }
    }
    return declaredCodes;
  }

  List<String> getListedCodes() {
    List<String> listedCodes = <String>[];
    CompilationUnit listingUnit = parseFile(['lib', 'error', 'error.dart']);
    TopLevelVariableDeclaration declaration = listingUnit.declarations
        .firstWhere(
            (member) =>
                member is TopLevelVariableDeclaration &&
                member.variables.variables[0].name.name == 'errorCodeValues',
            orElse: () => null);
    ListLiteral listLiteral = declaration.variables.variables[0].initializer;
    for (PrefixedIdentifier element in listLiteral.elements) {
      listedCodes.add(element.name);
    }
    return listedCodes;
  }

  CompilationUnit parseFile(List<String> relativeComponents) {
    List<String> pathComponents = _analyzerRootComponents.toList()
      ..addAll(relativeComponents);
    String filePath = path.normalize(path.joinAll(pathComponents));
    return parseCompilationUnit(File(filePath).readAsStringSync());
  }

  test_errorCodeValues() {
    List<String> listedCodes = getListedCodes();
    List<String> missingCodes = <String>[];
    List<List<String>> declaringPaths = [
      ['lib', 'src', 'analysis_options', 'error', 'option_codes.dart'],
      ['lib', 'src', 'dart', 'error', 'ffi_code.dart'],
      ['lib', 'src', 'dart', 'error', 'hint_codes.dart'],
      ['lib', 'src', 'dart', 'error', 'lint_codes.dart'],
      ['lib', 'src', 'dart', 'error', 'todo_codes.dart'],
      ['lib', 'src', 'dart', 'error', 'syntactic_errors.dart'],
      ['lib', 'src', 'error', 'codes.dart'],
      ['..', '_fe_analyzer_shared', 'lib', 'src', 'scanner', 'errors.dart']
    ];
    for (List<String> path in declaringPaths) {
      for (String declaredCode in getDeclaredCodes(path)) {
        if (!listedCodes.contains(declaredCode)) {
          missingCodes.add(declaredCode);
        }
      }
    }
    expect(missingCodes, isEmpty);
  }
}
