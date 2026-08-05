// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToPrimaryConstructor extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind? get assistKind => DartAssistKind.convertToPrimaryConstructor;

  /// This is only a fix in order to support the lint usePrimaryConstructors.
  /// If that lint is removed after testing the primary constructors feature,
  /// then this producer can be changed back to only producing an assist.
  @override
  FixKind get fixKind => DartFixKind.convertToPrimaryConstructor;

  @override
  FixKind get multiFixKind => DartFixKind.convertToPrimaryConstructorMulti;

  /// The constructor being converted to a primary constructor.
  ConstructorDeclaration? get _constructorToConvert {
    var node = this.node;
    if (node is ConstructorDeclaration) return node;
    if (node is! SimpleIdentifier) return null;
    var parent = node.parent;
    if (parent is ConstructorDeclaration && parent.typeName == node) {
      return parent;
    }
    return null;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!isEnabled(Feature.primary_constructors)) return;
    var constructor = _constructorToConvert;
    if (constructor == null ||
        constructor.factoryKeyword != null ||
        constructor.externalKeyword != null ||
        constructor.isRedirectingGenerativeConstructor) {
      return;
    }
    var containerData = _getContainerData(constructor);
    if (containerData == null ||
        containerData.hasPrimaryConstructor ||
        containerData.hasMultipleNonRedirectingGenerativeConstructors) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      // Add the primary constructor.
      if (constructor.constKeyword != null && !containerData.isEnum) {
        builder.addSimpleInsertion(containerData.name.offset, 'const ');
      }
      builder.addInsertion(
        containerData.typeParameters?.end ?? containerData.name.end,
        (builder) {
          if (constructor.name case var name?) {
            builder.write('.');
            builder.write(name.lexeme);
          }
          builder.write(_parameterText(constructor.parameters));
        },
      );

      // Remove the constructor that was converted.
      //
      // Note: There is no attempt made to preserve non-doc comments. In the
      // then branch, where only a small portion of the text is replaced, this
      // is unlikely to be a problem. It might be more of a problem in the else
      // branch where everything is removed.
      if (constructor.initializers.isNotEmpty ||
          constructor.body.isNotEmpty ||
          constructor.documentationComment != null ||
          constructor.metadata.isNotEmpty) {
        builder.addSimpleReplacement(
          range.startEnd(
            constructor.firstTokenAfterCommentAndMetadata,
            constructor.parameters.endToken,
          ),
          'this',
        );
      } else {
        builder.deleteClassMember(constructor);
      }
    });
  }

  /// Returns information about the declaration in which the [constructor] is
  /// declared.
  _ContainerData? _getContainerData(ConstructorDeclaration constructor) {
    var parent = switch (constructor.parent) {
      BlockClassBody body => body.parent,
      BlockEnumBody body => body.parent,
      var parent => parent,
    };

    return switch (parent) {
      ClassDeclaration(:var namePart) ||
      EnumDeclaration(:var namePart) => _ContainerData(
        container: parent!,
        name: namePart.typeName,
        typeParameters: namePart.typeParameters,
        hasPrimaryConstructor: namePart is PrimaryConstructorDeclaration,
        hasMultipleNonRedirectingGenerativeConstructors:
            _nonRedirectingGenerativeConstructorCount(parent.classMembers) > 1,
        isEnum: parent is EnumDeclaration,
      ),
      _ => null,
    };
  }

  /// Returns the number of non-redirecting generative constructors in the list
  /// of [members].
  int _nonRedirectingGenerativeConstructorCount(List<ClassMember> members) {
    var count = 0;
    for (var member in members) {
      if (member.isNonRedirectingGenerativeConstructor) {
        count++;
      }
    }
    return count;
  }

  /// Returns the source text of the [parameterList].
  String _parameterText(FormalParameterList parameterList) {
    return utils.getRangeText(parameterList.sourceRange);
  }
}

/// Information about the class or enum declaration containing the constructor
/// to be converted.
class _ContainerData {
  /// The class or enum declaration.
  AstNode container;

  /// The name of the class or enum.
  Token name;

  /// The type parameters on the class or enum or `null` if the type isn't
  /// generic.
  TypeParameterList? typeParameters;

  /// Whether the class or enum already has a primary constructor.
  bool hasPrimaryConstructor;

  /// Whether the class or enum has more than one non-redirecting generative
  /// constructor.
  bool hasMultipleNonRedirectingGenerativeConstructors;

  /// Whether the container is an enum.
  bool isEnum;

  new({
    required this.container,
    required this.name,
    required this.typeParameters,
    required this.hasPrimaryConstructor,
    required this.hasMultipleNonRedirectingGenerativeConstructors,
    required this.isEnum,
  });
}

extension on ConstructorDeclaration {
  /// Whether this constructor is a redirecting generative constructor.
  ///
  /// This implementation takes advantage of the fact that we've already
  /// established that the constructor is a generative constructor
  bool get isRedirectingGenerativeConstructor {
    if (initializers.lastOrNull is RedirectingConstructorInvocation) {
      return true;
    }
    return false;
  }
}

extension on ClassMember {
  /// Whether this class member is a non-redirecting generative constructor.
  bool get isNonRedirectingGenerativeConstructor {
    var self = this;
    return self is ConstructorDeclaration &&
        self.factoryKeyword == null &&
        self.declaredFragment?.element.redirectedConstructor == null;
  }
}

extension on FunctionBody {
  /// Whether there is code in the function body.
  bool get isNotEmpty => switch (this) {
    BlockFunctionBody(:var block) => block.statements.isNotEmpty,
    EmptyFunctionBody() => false,
    ExpressionFunctionBody() => true,
    NativeFunctionBody() => false,
  };
}
