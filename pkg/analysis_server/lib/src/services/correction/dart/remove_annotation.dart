// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveAnnotation extends CorrectionProducer {
  String _annotationName;

  @override
  List<Object> get fixArguments => [_annotationName];

  @override
  FixKind get fixKind => DartFixKind.REMOVE_ANNOTATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Future<void> addFix(Annotation node) async {
      if (node == null) {
        return;
      }
      var followingToken = node.endToken.next;
      followingToken = followingToken.precedingComments ?? followingToken;
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(node, followingToken));
      });
      _annotationName = node.name.name;
    }

    Annotation findAnnotation(
        NodeList<Annotation> metadata, String targetName) {
      return metadata.firstWhere(
          (annotation) => annotation.name.name == targetName,
          orElse: () => null);
    }

    var node = coveredNode;
    if (node is Annotation) {
      await addFix(node);
    } else if (node is DefaultFormalParameter) {
      await addFix(findAnnotation(node.parameter.metadata, 'required'));
    } else if (node is NormalFormalParameter) {
      await addFix(findAnnotation(node.metadata, 'required'));
    } else if (node is DeclaredSimpleIdentifier) {
      var parent = node.parent;
      if (parent is MethodDeclaration) {
        await addFix(findAnnotation(parent.metadata, 'override'));
      } else if (parent is VariableDeclaration) {
        var fieldDeclaration = parent.thisOrAncestorOfType<FieldDeclaration>();
        if (fieldDeclaration != null) {
          await addFix(findAnnotation(fieldDeclaration.metadata, 'override'));
        }
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveAnnotation newInstance() => RemoveAnnotation();
}
