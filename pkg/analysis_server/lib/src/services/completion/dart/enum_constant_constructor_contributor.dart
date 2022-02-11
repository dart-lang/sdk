// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// A contributor that produces suggestions for constructors to be invoked
/// in enum constants.
class EnumConstantConstructorContributor extends DartCompletionContributor {
  EnumConstantConstructorContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
    if (!request.featureSet.isEnabled(Feature.enhanced_enums)) {
      return;
    }

    // TODO(scheglov) It seems unfortunate that we have to re-discover
    // the location in contributors. This is the work of `OpType`, so why
    // doesn't it provide all these enclosing `EnumConstantDeclaration`,
    // `ConstructorSelector`, `EnumDeclaration`?
    var node = request.target.containingNode;
    if (node is! ConstructorSelector) {
      return;
    }

    if (request.opType.completionLocation != 'ConstructorSelector_name') {
      return;
    }

    var arguments = node.parent;
    if (arguments is! EnumConstantArguments) {
      return;
    }

    var enumConstant = arguments.parent;
    if (enumConstant is! EnumConstantDeclaration) {
      return;
    }

    var enumDeclaration = enumConstant.parent;
    if (enumDeclaration is! EnumDeclaration) {
      return;
    }

    var enumElement = enumDeclaration.declaredElement as ClassElement;
    for (var constructor in enumElement.constructors) {
      builder.suggestConstructor(
        constructor,
        hasClassName: true,
        tearOff: true,
      );
    }
  }
}
