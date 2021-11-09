// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart';

class BulkFixDetails {
  Future<Map<String, CorrectionDetails>> collectOverrides() async {
    var overrideDetails = <String, CorrectionDetails>{};

    var pkgRootPath =
        PhysicalResourceProvider.INSTANCE.pathContext.normalize(packageRoot);
    var directory = Directory(
        '$pkgRootPath/analysis_server/lib/src/services/correction/dart');
    var collection = AnalysisContextCollection(
      includedPaths: [directory.absolute.path],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    var context = collection.contexts[0];

    for (var file in directory.listSync()) {
      var resolvedFile = await context.currentSession
          .getResolvedUnit(file.absolute.path) as ResolvedUnitResult;
      for (var classDecl
          in resolvedFile.unit.declarations.whereType<ClassDeclaration>()) {
        var classElement = classDecl.declaredElement;
        if (classElement != null &&
            classElement.allSupertypes.any(
                (element) => element.element.name == 'CorrectionProducer')) {
          var correctionName = classDecl.name.name;

          for (var method in classDecl.members.whereType<MethodDeclaration>()) {
            if (method.name.name == 'canBeAppliedInBulk') {
              var hasComment =
                  method.returnType?.beginToken.precedingComments != null;

              var body = method.body;
              if (body is BlockFunctionBody) {
                var last = body.block.statements.last;
                if (last is ReturnStatement) {
                  var canBeBulkApplied =
                      (last.expression as BooleanLiteral).value;
                  overrideDetails[correctionName] = CorrectionDetails(
                      canBeBulkApplied: canBeBulkApplied,
                      hasComment: hasComment);
                }
              } else if (body is ExpressionFunctionBody) {
                var expression = body.expression;
                var canBeBulkApplied = (expression as BooleanLiteral).value;
                overrideDetails[correctionName] = CorrectionDetails(
                    canBeBulkApplied: canBeBulkApplied, hasComment: hasComment);
              }
            }
          }
        }
      }
    }
    return overrideDetails;
  }
}

class CorrectionDetails {
  bool canBeBulkApplied;
  bool hasComment;

  CorrectionDetails({required this.canBeBulkApplied, required this.hasComment});
}
