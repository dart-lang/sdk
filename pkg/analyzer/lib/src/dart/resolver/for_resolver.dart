// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [ForStatement]s and [ForElement]s.
class ForResolver {
  final ResolverVisitor _resolver;

  ForResolver({required ResolverVisitor resolver}) : _resolver = resolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolveElement(ForElementImpl node, CollectionLiteralContext? context) {
    var forLoopParts = node.forLoopParts;
    void visitBody() {
      _resolver.dispatchCollectionElement(node.body2, context);
    }

    if (forLoopParts is ForPartsImpl) {
      _forParts(
        node,
        forLoopParts,
        visitBody,
        rightParenOffset: node.rightParenthesis.offset,
        endOffset: node.end,
      );
    } else if (forLoopParts is ForEachPartsWithPatternImpl) {
      _analyzePatternForIn(
        node: node,
        awaitKeyword: node.awaitKeyword,
        forLoopParts: forLoopParts,
        dispatchBody: () {
          _resolver.dispatchCollectionElement(node.body2, context);
        },
        rightParenthesisOffset: node.rightParenthesis.offset,
      );
    } else if (forLoopParts is ForEachPartsImpl) {
      _forEachParts(
        node,
        node.awaitKeyword != null,
        forLoopParts,
        visitBody,
        rightParenthesisOffset: node.rightParenthesis.offset,
        bodyEndOffset: node.body.end,
      );
    }
  }

  void resolveStatement(ForStatementImpl node) {
    var forLoopParts = node.forLoopParts;
    void visitBody() {
      node.body.accept2(_resolver);
    }

    if (forLoopParts is ForPartsImpl) {
      _forParts(
        node,
        forLoopParts,
        visitBody,
        rightParenOffset: node.rightParenthesis.offset,
        endOffset: node.end,
      );
    } else if (forLoopParts is ForEachPartsWithPatternImpl) {
      _analyzePatternForIn(
        node: node,
        awaitKeyword: node.awaitKeyword,
        forLoopParts: forLoopParts,
        dispatchBody: () {
          _resolver.dispatchStatement(node.body);
        },
        rightParenthesisOffset: node.rightParenthesis.offset,
      );
    } else if (forLoopParts is ForEachPartsImpl) {
      _forEachParts(
        node,
        node.awaitKeyword != null,
        forLoopParts,
        visitBody,
        rightParenthesisOffset: node.rightParenthesis.offset,
        bodyEndOffset: node.body.end,
      );
    }
  }

  void _analyzePatternForIn({
    required AstNodeImpl node,
    required Token? awaitKeyword,
    required ForEachPartsWithPatternImpl forLoopParts,
    required void Function() dispatchBody,
    required int rightParenthesisOffset,
  }) {
    forLoopParts.metadata.accept2(_resolver);
    _resolver.analyzePatternForIn(
      node: node,
      hasAwait: awaitKeyword != null,
      pattern: forLoopParts.pattern,
      expression: forLoopParts.iterable2,
      dispatchBody: dispatchBody,
      beforePatternOffset: node.offset,
      beforeExpressionOffset: forLoopParts.inKeyword.offset,
      bodyBeginOffset: rightParenthesisOffset,
      endOffset: node.end,
    );
    _resolver.popRewrite();
    _resolver.nullableDereferenceVerifier.expression(
      diag.uncheckedUseOfNullableValueAsIterator,
      forLoopParts.iterable2,
    );
  }

  /// Given an iterable expression from a foreach loop, attempt to infer
  /// a type for the elements being iterated over.  Inference is based
  /// on the type of the iterator or stream over which the foreach loop
  /// is defined.
  TypeImpl _computeForEachElementType(ExpressionImpl iterable, bool isAsync) {
    var iterableType = iterable.staticType;
    if (iterableType == null) {
      return InvalidTypeImpl.instance;
    }

    iterableType = _typeSystem.resolveToBound(iterableType);
    if (iterableType is DynamicType) {
      return DynamicTypeImpl.instance;
    }

    ClassElement iteratedElement = isAsync
        ? _resolver.typeProvider.streamElement
        : _resolver.typeProvider.iterableElement;

    var iteratedType = iterableType.asInstanceOf(iteratedElement);
    if (iteratedType == null) {
      return InvalidTypeImpl.instance;
    }

    return iteratedType.typeArguments.single;
  }

  void _forEachParts(
    AstNodeImpl node,
    bool isAsync,
    ForEachPartsImpl forEachParts,
    void Function() visitBody, {
    required int rightParenthesisOffset,
    required int bodyEndOffset,
  }) {
    ExpressionImpl iterable = forEachParts.iterable2;
    DeclaredIdentifierImpl? loopVariable;
    ForEachPartsWithIdentifierImpl? identifierParts;
    Element? identifierElement;
    if (forEachParts is ForEachPartsWithDeclarationImpl) {
      loopVariable = forEachParts.loopVariable;
    } else if (forEachParts is ForEachPartsWithIdentifierImpl) {
      identifierParts = forEachParts;
      var write = PropertyElementResolver(
        _resolver,
      ).resolveForEachPartsWithIdentifier(forEachParts);
      forEachParts.write = write;
      AssignmentExpressionShared(
        resolver: _resolver,
      ).checkFinalForEachIdentifier(forEachParts);
      identifierElement = forEachParts.writeElement;

      var identifierStaticType = switch (write) {
        VariableWriteResolutionImpl(:var element) =>
          _resolver.localVariableTypeProvider.getWriteType(element),
        SetterInvocationResolutionImpl(:var acceptedType) => acceptedType,
        _ => InvalidTypeImpl.instance,
      };
      forEachParts.setIdentifierStaticType(identifierStaticType);
    }

    TypeImpl? valueType;
    if (loopVariable != null) {
      var typeAnnotation = loopVariable.type;
      valueType = typeAnnotation?.type ?? UnknownInferredType.instance;
    }
    if (identifierParts?.write case VariableWriteResolutionImpl(:var element)) {
      valueType = _resolver.localVariableTypeProvider.getWriteType(element);
    } else if (identifierParts?.write case SetterInvocationResolutionImpl(
      :var acceptedType,
    )) {
      valueType = acceptedType;
    }
    InterfaceTypeImpl? targetType;
    if (valueType != null) {
      targetType = isAsync
          ? _resolver.typeProvider.streamType(valueType)
          : _resolver.typeProvider.iterableType(valueType);
    }

    _resolver.analyzeExpression(
      iterable,
      SharedTypeSchemaView(targetType ?? UnknownInferredType.instance),
    );
    iterable = _resolver.popRewrite()!;

    _resolver.nullableDereferenceVerifier.expression(
      diag.uncheckedUseOfNullableValueAsIterator,
      iterable,
    );

    loopVariable?.accept2(_resolver);
    var elementType = _computeForEachElementType(iterable, isAsync);
    if (loopVariable != null && loopVariable.type == null) {
      var loopVariableElement =
          loopVariable.declaredFragment?.element as LocalVariableElementImpl;
      loopVariableElement.type = elementType;
    }

    if (loopVariable != null) {
      var declaredElement = loopVariable.declaredFragment!.element;
      _resolver.flowAnalysis.flow?.declare(
        declaredElement,
        SharedTypeView(declaredElement.type),
        initialized: true,
        offset: rightParenthesisOffset,
      );
    }

    _resolver.flowAnalysis.flow?.forEach_bodyBegin(
      node,
      offset: rightParenthesisOffset,
    );
    if (identifierElement is PromotableElementImpl &&
        forEachParts is ForEachPartsWithIdentifier) {
      _resolver.flowAnalysis.flow?.write(
        forEachParts,
        identifierElement,
        SharedTypeView(elementType),
        null,
        offset: rightParenthesisOffset,
      );
    }

    visitBody();

    _resolver.flowAnalysis.flow?.forEach_end(offset: bodyEndOffset);
  }

  void _forParts(
    AstNodeImpl node,
    ForPartsImpl forParts,
    void Function() visitBody, {
    required int rightParenOffset,
    required int endOffset,
  }) {
    if (forParts is ForPartsWithDeclarationsImpl) {
      forParts.variables.accept2(_resolver);
    } else if (forParts is ForPartsWithExpressionImpl) {
      if (forParts.initialization2 case var initialization?) {
        _resolver.analyzeExpression(
          initialization,
          _resolver.operations.unknownType,
        );
        _resolver.popRewrite();
      }
    } else if (forParts is ForPartsWithPatternImpl) {
      forParts.variables.accept2(_resolver);
    } else {
      throw StateError('Unrecognized for loop parts');
    }

    _resolver.flowAnalysis.for_conditionBegin(
      node,
      offset: forParts.leftSeparator.offset,
    );

    var condition = forParts.condition2;
    if (condition != null) {
      _resolver.analyzeExpression(
        condition,
        SharedTypeSchemaView(_resolver.typeProvider.boolType),
      );
      condition = _resolver.popRewrite()!;
      var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
        _resolver.flowAnalysis.getExpressionInfo(condition),
      );
      _resolver.boolExpressionVerifier.checkForNonBoolCondition(
        condition,
        whyNotPromoted: whyNotPromoted,
      );
    }

    var deadCodeForPartsState = _resolver.nullSafetyDeadCodeVerifier
        .for_conditionEnd();
    _resolver.flowAnalysis.for_bodyBegin(
      node,
      condition,
      offset: rightParenOffset,
    );
    visitBody();

    _resolver.flowAnalysis.flow?.for_updaterBegin(
      offset: forParts.rightSeparator.offset,
    );
    _resolver.nullSafetyDeadCodeVerifier.for_updaterBegin(
      forParts.updaters2,
      deadCodeForPartsState,
    );
    for (var updater in forParts.updaters2) {
      _resolver.analyzeExpression(updater, _resolver.operations.unknownType);
      _resolver.popRewrite();
    }

    _resolver.flowAnalysis.flow?.for_end(offset: endOffset);
  }
}
