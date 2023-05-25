// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:test/test.dart';

void main() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var packageRoot = provider.pathContext.normalize(package_root.packageRoot);
  var pathToAnalyze = provider.pathContext.join(packageRoot, 'analysis_server');
  var parentDirPath = provider.pathContext
      .join(pathToAnalyze, 'test', 'services', 'completion', 'dart');
  var declarationDirPath =
      provider.pathContext.join(parentDirPath, 'declaration');
  var locationDirPath = provider.pathContext.join(parentDirPath, 'location');
  var filesToTest = [
    ...getFilesToTest(provider.getFolder(declarationDirPath)),
    ...getFilesToTest(provider.getFolder(locationDirPath))
  ];
  for (var file in filesToTest) {
    test(file.shortName, () => checkTestFile(file));
  }
}

void checkTestFile(File file) {
  var result = parseFile(
      path: file.path, featureSet: FeatureSet.latestLanguageVersion());
  var duplicatedTestNames = <String>[];
  for (var declaration in result.unit.declarations) {
    if (declaration is MixinDeclaration) {
      for (var member in declaration.members) {
        if (member is MethodDeclaration &&
            member.name.lexeme.startsWith('test_')) {
          for (var statement
              in (member.body as BlockFunctionBody).block.statements) {
            if (statement is IfStatement && statement.hasDuplicateResponses) {
              duplicatedTestNames.add(member.name.lexeme);
            }
          }
        }
      }
    }
  }
  if (duplicatedTestNames.isNotEmpty) {
    var separator = '\n  ';
    var testNames = '$separator${duplicatedTestNames.join(separator)}';
    fail('The following tests have duplicated response assertions:$testNames');
  }
}

Iterable<File> getFilesToTest(Folder directory) => directory
    .getChildren()
    .whereType<File>()
    .where((child) => child.shortName.endsWith('_test.dart'));

extension on IfStatement {
  bool get hasDuplicateResponses {
    var thenResponse = thenStatement.response;
    var elseResponse = elseStatement?.response;
    if (thenResponse == null || elseResponse == null) {
      return false;
    }
    return thenResponse == elseResponse;
  }
}

extension on Statement {
  String? get response {
    var self = this;
    if (self is! Block) {
      return null;
    }
    var statements = self.statements;
    if (statements.length != 1) {
      return null;
    }
    var statement = statements[0];
    if (statement is! ExpressionStatement) {
      return null;
    }
    var expression = statement.expression;
    if (expression is! MethodInvocation) {
      return null;
    }
    var arguments = expression.argumentList.arguments;
    if (expression.methodName.name != 'assertResponse' ||
        arguments.length != 1) {
      return null;
    }
    var argument = arguments[0];
    if (argument is! SimpleStringLiteral) {
      return null;
    }
    return argument.stringValue;
  }
}
