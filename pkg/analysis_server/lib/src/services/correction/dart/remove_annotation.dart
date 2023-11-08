// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class RemoveAnnotation extends ResolvedCorrectionProducer {
  String _annotationName = '';

  @override
  // Not predictably the correct action.
  bool get canBeAppliedInBulk => false;

  @override
  // Not predictably the correct action.
  bool get canBeAppliedToFile => false;

  @override
  List<Object> get fixArguments => [_annotationName];

  @override
  FixKind get fixKind => DartFixKind.REMOVE_ANNOTATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Future<void> addFix(Annotation? node) async {
      if (node == null) {
        return;
      }
      var followingToken = node.endToken.next!;
      followingToken = followingToken.precedingComments ?? followingToken;
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(node, followingToken));
      });
      _annotationName = node.name.name;
    }

    Annotation? findAnnotation(List<Annotation> metadata, String targetName) {
      return metadata.firstWhereOrNull(
        (annotation) => annotation.name.name == targetName,
      );
    }

    var node = coveredNode;
    if (node is Annotation) {
      await addFix(node);
    } else if (node is DefaultFormalParameter) {
      await addFix(findAnnotation(node.parameter.metadata, 'required'));
    } else if (node is NormalFormalParameter) {
      await addFix(findAnnotation(node.metadata, 'required'));
    } else if (node is MethodDeclaration) {
      await addFix(findAnnotation(node.metadata, 'override'));
      await addFix(findAnnotation(node.metadata, 'redeclare'));
    } else if (node is VariableDeclaration) {
      var fieldDeclaration = node.thisOrAncestorOfType<FieldDeclaration>();
      if (fieldDeclaration != null) {
        await addFix(findAnnotation(fieldDeclaration.metadata, 'override'));
      }
    }
  }
}
