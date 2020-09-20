// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A contributor that produces suggestions for field formal parameters that are
/// based on the fields declared directly by the enclosing class that are not
/// already initialized. More concretely, this class produces suggestions for
/// expressions of the form `this.^` in a constructor's parameter list.
class FieldFormalContributor extends DartCompletionContributor {
  @override
  Future<void> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var node = request.target.containingNode;
    // TODO(brianwilkerson) We should suggest field formal parameters even if
    //  the user hasn't already typed the `this.` prefix, by including the
    //  prefix in the completion.
    if (node is! FieldFormalParameter) {
      return;
    }

    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }

    // Compute the list of fields already referenced in the constructor.
    // TODO(brianwilkerson) This doesn't include fields in initializers, which
    //  shouldn't be suggested.
    var referencedFields = <String>[];
    for (var param in constructor.parameters.parameters) {
      if (param is DefaultFormalParameter) {
        param = (param as DefaultFormalParameter).parameter;
      }
      if (param is FieldFormalParameter) {
        var fieldId = param.identifier;
        if (fieldId != null && fieldId != request.target.entity) {
          var fieldName = fieldId.name;
          if (fieldName != null && fieldName.isNotEmpty) {
            referencedFields.add(fieldName);
          }
        }
      }
    }

    var enclosingClass = constructor.thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) {
      return;
    }

    // Add suggestions for fields that are not already referenced.
    for (var member in enclosingClass.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (var variable in member.fields.variables) {
          var field = variable.name.staticElement;
          if (field != null) {
            var fieldName = field.name;
            if (fieldName != null && fieldName.isNotEmpty) {
              if (!referencedFields.contains(fieldName)) {
                builder.suggestFieldFormalParameter(field);
              }
            }
          }
        }
      }
    }
  }
}
