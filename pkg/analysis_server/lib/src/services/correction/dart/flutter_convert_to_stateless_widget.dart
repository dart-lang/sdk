// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterConvertToStatelessWidget extends ResolvedCorrectionProducer {
  @override
  AssistKind get assistKind =>
      DartAssistKind.FLUTTER_CONVERT_TO_STATELESS_WIDGET;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetClass = node.thisOrAncestorOfType<ClassDeclaration>();
    var superclass = widgetClass?.extendsClause?.superclass;
    if (widgetClass == null || superclass == null) return;

    // Don't spam, activate only from the `class` keyword to the class body.
    if (selectionOffset < widgetClass.classKeyword.offset ||
        selectionOffset > widgetClass.leftBracket.end) {
      return;
    }

    // Must be a StatefulWidget subclass.
    var widgetClassElement = widgetClass.declaredElement!;
    var superType = widgetClassElement.supertype;
    if (superType == null || !flutter.isExactlyStatefulWidgetType(superType)) {
      return;
    }

    var createStateMethod = _findCreateStateMethod(widgetClass);
    if (createStateMethod == null) return;

    var stateClass = _findStateClass(widgetClassElement);
    var stateClassElement = stateClass?.declaredElement;
    if (stateClass == null ||
        stateClassElement == null ||
        !Identifier.isPrivateName(stateClass.name.lexeme) ||
        !_isSameTypeParameters(widgetClass, stateClass)) {
      return;
    }

    var verifier = _StatelessVerifier();
    var fieldFinder = _FieldFinder();

    for (var member in stateClass.members) {
      if (member is ConstructorDeclaration) {
        member.accept(fieldFinder);
      } else if (member is MethodDeclaration) {
        member.accept(verifier);
        if (!verifier.canBeStateless) {
          return;
        }
      }
    }

    var usageVerifier =
        _StateUsageVisitor(widgetClassElement, stateClassElement);
    unit.visitChildren(usageVerifier);
    if (usageVerifier.used) return;

    var fieldsAssignedInConstructors = fieldFinder.fieldsAssignedInConstructors;

    // Prepare nodes to move.
    var nodesToMove = <ClassMember>[];
    var elementsToMove = <Element>{};
    for (var member in stateClass.members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          return;
        }
        for (var fieldNode in member.fields.variables) {
          var fieldElement = fieldNode.declaredElement as FieldElement;
          if (!fieldsAssignedInConstructors.contains(fieldElement)) {
            nodesToMove.add(member);
            elementsToMove.add(fieldElement);

            var getter = fieldElement.getter;
            if (getter != null) {
              elementsToMove.add(getter);
            }

            var setter = fieldElement.setter;
            if (setter != null) {
              elementsToMove.add(setter);
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          return;
        }
        if (!_isDefaultOverride(member)) {
          nodesToMove.add(member);
          elementsToMove.add(member.declaredElement!);
        }
      }
    }

    /// Return the code for the [movedNode], so that qualification of the
    /// references to the widget (`widget.` or static `MyWidgetClass.`)
    /// is removed
    String rewriteWidgetMemberReferences(AstNode movedNode) {
      var linesRange = utils.getLinesRange(range.node(movedNode));
      var text = utils.getRangeText(linesRange);

      // Remove `widget.` before references to the widget instance members.
      var visitor = _ReplacementEditBuilder(
          widgetClassElement, elementsToMove, linesRange);
      movedNode.accept(visitor);
      return SourceEdit.applySequence(text, visitor.edits.reversed);
    }

    var statelessWidgetClass = await sessionHelper.getClass(
      flutter.widgetsUri,
      'StatelessWidget',
    );
    if (statelessWidgetClass == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(superclass), (builder) {
        builder.writeReference(statelessWidgetClass);
      });

      builder.addDeletion(range.deletionRange(stateClass));

      var createStateNextToEnd = createStateMethod.endToken.next!;
      createStateNextToEnd =
          createStateNextToEnd.precedingComments ?? createStateNextToEnd;
      var createStateRange = range.startOffsetEndOffset(
          utils.getLineContentStart(createStateMethod.offset),
          utils.getLineContentStart(createStateNextToEnd.offset));

      var newLine = createStateNextToEnd.type != TokenType.CLOSE_CURLY_BRACKET;

      builder.addReplacement(createStateRange, (builder) {
        for (var i = 0; i < nodesToMove.length; i++) {
          var member = nodesToMove[i];
          var comments = member.beginToken.precedingComments;
          if (comments != null) {
            var offset = utils.getLineContentStart(comments.offset);
            var length = comments.end - offset;
            builder.writeln(utils.getText(offset, length));
          }

          var text = rewriteWidgetMemberReferences(member);
          builder.write(text);
          if (newLine || i < nodesToMove.length - 1) {
            builder.writeln();
          }
        }
      });
    });
  }

  MethodDeclaration? _findCreateStateMethod(ClassDeclaration widgetClass) {
    for (var member in widgetClass.members) {
      if (member is MethodDeclaration && member.name.lexeme == 'createState') {
        var parameters = member.parameters;
        if (parameters?.parameters.isEmpty ?? false) {
          return member;
        }
        break;
      }
    }
    return null;
  }

  ClassDeclaration? _findStateClass(ClassElement widgetClassElement) {
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        var type = declaration.extendsClause?.superclass.type;

        if (_isState(widgetClassElement, type)) {
          return declaration;
        }
      }
    }
    return null;
  }

  bool _isSameTypeParameters(
      ClassDeclaration widgetClass, ClassDeclaration stateClass) {
    List<TypeParameter>? parameters(ClassDeclaration declaration) =>
        declaration.typeParameters?.typeParameters;

    var widgetParams = parameters(widgetClass);
    var stateParams = parameters(stateClass);

    if (widgetParams == null && stateParams == null) {
      return true;
    }
    if (widgetParams == null || stateParams == null) {
      return false;
    }
    if (widgetParams.length < stateParams.length) {
      return false;
    }
    outer:
    for (var stateParam in stateParams) {
      for (var widgetParam in widgetParams) {
        if (stateParam.name.lexeme == widgetParam.name.lexeme &&
            stateParam.bound?.type == widgetParam.bound?.type) {
          continue outer;
        }
      }
      return false;
    }
    return true;
  }

  static bool _isDefaultOverride(MethodDeclaration? methodDeclaration) {
    var body = methodDeclaration?.body;
    if (body != null) {
      Expression expression;
      if (body is BlockFunctionBody) {
        var statements = body.block.statements;
        if (statements.isEmpty) return true;
        if (statements.length > 1) return false;
        var first = statements.first;
        if (first is! ExpressionStatement) return false;
        expression = first.expression;
      } else if (body is ExpressionFunctionBody) {
        expression = body.expression;
      } else {
        return false;
      }
      if (expression is MethodInvocation &&
          expression.target is SuperExpression &&
          methodDeclaration!.name.lexeme == expression.methodName.name) {
        return true;
      }
    }
    return false;
  }

  static bool _isState(ClassElement widgetClassElement, DartType? type) {
    if (type is! InterfaceType) return false;

    final firstArgument = type.typeArguments.singleOrNull;
    if (firstArgument is! InterfaceType ||
        firstArgument.element != widgetClassElement) {
      return false;
    }

    var classElement = type.element;
    return classElement is ClassElement &&
        Flutter.instance.isExactState(classElement);
  }
}

class _FieldFinder extends RecursiveAstVisitor<void> {
  Set<FieldElement> fieldsAssignedInConstructors = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is FieldFormalParameter) {
      var element = node.staticElement;
      if (element is FieldFormalParameterElement) {
        var field = element.field;
        if (field != null) {
          fieldsAssignedInConstructors.add(field);
        }
      }
    }
    if (node.parent is ConstructorFieldInitializer) {
      var element = node.staticElement;
      if (element is FieldElement) {
        fieldsAssignedInConstructors.add(element);
      }
    }
    if (node.inSetterContext()) {
      var element = node.writeOrReadElement;
      if (element is PropertyAccessorElement) {
        var field = element.variable;
        if (field is FieldElement) {
          fieldsAssignedInConstructors.add(field);
        }
      }
    }
  }
}

class _ReplacementEditBuilder extends RecursiveAstVisitor<void> {
  final ClassElement widgetClassElement;

  final Set<Element> elementsToMove;

  final SourceRange linesRange;

  List<SourceEdit> edits = [];

  _ReplacementEditBuilder(
      this.widgetClassElement, this.elementsToMove, this.linesRange);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    var element = node.staticElement;
    if (element is ExecutableElement &&
        element.enclosingElement2 == widgetClassElement &&
        !elementsToMove.contains(element)) {
      var parent = node.parent;
      if (parent is PrefixedIdentifier) {
        var grandParent = parent.parent;
        SourceEdit? rightBracketEdit;
        if (!node.name.contains('\$') &&
            grandParent is InterpolationExpression &&
            grandParent.leftBracket.type ==
                TokenType.STRING_INTERPOLATION_EXPRESSION) {
          edits.add(SourceEdit(
              grandParent.leftBracket.end - 1 - linesRange.offset, 1, ''));
          var offset = grandParent.rightBracket?.offset;
          if (offset != null) {
            rightBracketEdit = SourceEdit(offset - linesRange.offset, 1, '');
          }
        }
        var offset = parent.prefix.offset;
        var length = parent.period.end - offset;
        edits.add(SourceEdit(offset - linesRange.offset, length, ''));
        if (rightBracketEdit != null) {
          edits.add(rightBracketEdit);
        }
      } else if (parent is MethodInvocation) {
        var target = parent.target;
        var operator = parent.operator;
        if (target != null && operator != null) {
          var offset = target.offset;
          var length = operator.end - offset;
          edits.add(SourceEdit(offset - linesRange.offset, length, ''));
        }
      } else if (parent is PropertyAccess) {
        var target = parent.target;
        var operator = parent.operator;
        if (target != null) {
          var offset = target.offset;
          var length = operator.end - offset;
          edits.add(SourceEdit(offset - linesRange.offset, length, ''));
        }
      }
    }
  }
}

class _StatelessVerifier extends RecursiveAstVisitor<void> {
  var canBeStateless = true;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var methodElement = node.methodName.staticElement?.declaration;
    if (methodElement is ClassMemberElement) {
      var classElement = methodElement.enclosingElement2;
      if (classElement is ClassElement &&
          Flutter.instance.isExactState(classElement) &&
          !FlutterConvertToStatelessWidget._isDefaultOverride(
              node.thisOrAncestorOfType<MethodDeclaration>())) {
        canBeStateless = false;
        return;
      }
    }
    super.visitMethodInvocation(node);
  }
}

class _StateUsageVisitor extends RecursiveAstVisitor<void> {
  bool used = false;
  ClassElement widgetClassElement;
  ClassElement stateClassElement;

  _StateUsageVisitor(this.widgetClassElement, this.stateClassElement);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    final type = node.staticType;
    if (type is! InterfaceType || type.element != stateClassElement) {
      return;
    }
    var methodDeclaration = node.thisOrAncestorOfType<MethodDeclaration>();
    var classDeclaration =
        methodDeclaration?.thisOrAncestorOfType<ClassDeclaration>();

    if (methodDeclaration?.name.lexeme != 'createState' ||
        classDeclaration?.declaredElement != widgetClassElement) {
      used = true;
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var type = node.staticType;
    if (type is InterfaceType &&
        node.methodName.name == 'createState' &&
        (FlutterConvertToStatelessWidget._isState(widgetClassElement, type) ||
            type.element == stateClassElement)) {
      used = true;
    }
  }
}
