// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/bundle_writer.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';

/// Serializer of fully resolved ASTs.
class AstBinaryWriter extends ThrowingAstVisitor2<void> {
  final ResolutionSink _sink;

  AstBinaryWriter({required ResolutionSink sink}) : _sink = sink;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _sink.writeEnum(AstNodeTag.AdjacentStrings);
    _writeNodeList(node.strings);
    _storeExpression(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _sink.writeEnum(AstNodeTag.Annotation);

    _writeNode(node.name);
    _writeOptionalNode(node.typeArguments);
    _writeOptionalNode(node.constructorName);

    var arguments = node.arguments;
    if (arguments != null) {
      if (!arguments.arguments2.every((argument) {
        return _isSerializableExpression(argument.argumentExpression2);
      })) {
        arguments = null;
      }
    }
    _writeOptionalNode(arguments);

    _sink.writeElement(node.element);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _sink.writeEnum(AstNodeTag.ArgumentList);
    _writeNodeList(node.arguments2);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _sink.writeEnum(AstNodeTag.AsExpression);

    _writeNode(node.expression2);

    _writeNode(node.type);

    _storeExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _sink.writeEnum(AstNodeTag.AssertInitializer);
    _writeNode(node.condition2);
    _writeOptionalNode(node.message2);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _sink.writeEnum(AstNodeTag.AssignmentExpression);

    _writeNode(node.leftHandSide2);
    _writeNode(node.rightHandSide2);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _sink.writeEnum(binaryToken);

    _sink.writeElement(node.element);
    _sink.writeElement(node.readElement);
    _sink.writeType(node.readType);
    _sink.writeElement(node.writeElement);
    _sink.writeType(node.writeType);
    _storeExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _sink.writeEnum(AstNodeTag.AwaitExpression);

    _writeNode(node.expression2);

    _storeExpression(node);
  }

  @override
  void visitBinaryOperatorInvocation(BinaryOperatorInvocation node) {
    _sink.writeEnum(AstNodeTag.BinaryOperatorInvocation);

    _writeNode(node.leftOperand);
    _writeNode(node.rightOperand);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _sink.writeEnum(binaryToken);

    _sink.writeElement(node.element);
    _storeExpression(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _sink.writeEnum(AstNodeTag.BooleanLiteral);
    _writeByte(node.value ? 1 : 0);
    _storeExpression(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _sink.writeEnum(AstNodeTag.CascadeExpression);
    _writeNode(node.target2);
    _writeNodeList(node.sections);
  }

  @override
  void visitCascadeIndexAssignmentTarget(
    covariant CascadeIndexAssignmentTargetImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.CascadeIndexAssignmentTarget);
    _writeNode(node.index);
    _sink.writeOptionalObject(node.read, _writeIndexReadResolution);
    _sink.writeOptionalObject(node.write, _writeIndexWriteResolution);
  }

  @override
  void visitCascadeIndexExpression(covariant CascadeIndexExpressionImpl node) {
    _sink.writeEnum(AstNodeTag.CascadeIndexExpression);
    _writeNode(node.index);
    _sink.writeOptionalObject(node.resolution, _writeIndexReadResolution);
    _storeExpression(node);
  }

  @override
  void visitCascadePropertyAssignmentTarget(
    covariant CascadePropertyAssignmentTargetImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.CascadePropertyAssignmentTarget);
    _writeStringReference(node.propertyName.lexeme);
    _sink.writeOptionalObject(node.read, _writeNamedReadResolution);
    _sink.writeOptionalObject(node.write, _writeNamedWriteResolution);
  }

  @override
  void visitCascadePropertyExtraction(
    covariant CascadePropertyExtractionImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.CascadePropertyExtraction);
    _writeStringReference(node.propertyName.lexeme);
    _sink.writeOptionalObject(node.resolution, _writeNamedReadResolution);
    _storeExpression(node);
  }

  @override
  void visitCascadeSection(CascadeSection node) {
    _sink.writeEnum(AstNodeTag.CascadeSection);
    _writeByte(node.isNullAware ? 1 : 0);
    _writeNode(node.body);
  }

  @override
  void visitCompoundAssignment(CompoundAssignment node) {
    _sink.writeEnum(AstNodeTag.CompoundAssignment);
    _writeNode(node.target);
    _writeNode(node.value);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _sink.writeEnum(binaryToken);

    _sink.writeElement(node.element);
    _sink.writeType(node.operatorResultType);
    _storeExpression(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _sink.writeEnum(AstNodeTag.ConditionalExpression);
    _writeNode(node.condition2);
    _writeNode(node.thenExpression2);
    _writeNode(node.elseExpression2);
    _storeExpression(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _sink.writeEnum(AstNodeTag.ConstructorFieldInitializer);

    _writeByte(AstBinaryFlags.encode(hasThis: node.thisKeyword != null));

    _writeStringReference(node.fieldName2.lexeme);
    _sink.writeElement(node.fieldElement);
    _writeNode(node.expression2);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    _sink.writeEnum(AstNodeTag.ConstructorInvocation);

    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.keyword?.type == Keyword.CONST,
        isNew: node.keyword?.type == Keyword.NEW,
      ),
    );

    _writeNode(node.constructorReference);
    _writeNode(node.argumentList);
    _storeExpression(node);
  }

  @override
  void visitConstructorReference2(ConstructorReference2 node) {
    _sink.writeEnum(AstNodeTag.ConstructorReference2);
    _writeNode(node.typeReference);
    _writeOptionalNode(node.selector);
    _sink.writeElement(node.element);
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    _sink.writeEnum(AstNodeTag.ConstructorSelector);
    _writeStringReference(node.name2.lexeme);
  }

  @override
  void visitConstructorTearOff(ConstructorTearOff node) {
    _sink.writeEnum(AstNodeTag.ConstructorTearOff);
    _writeNode(node.typeReference);
    _writeNode(node.selector);
    // A substituted element can refer to type parameters declared by the
    // tear-off's function type. Those parameters aren't in scope while the
    // element is written, so store the declaration and recreate the
    // substitution from the function type when reading.
    _sink.writeElement(node.element?.baseElement);
    _storeExpression(node);
  }

  @override
  void visitConstructorTypeReference(ConstructorTypeReference node) {
    _sink.writeEnum(AstNodeTag.ConstructorTypeReference);
    _writeOptionalNode(node.importPrefix);
    _writeStringReference(node.name.lexeme);
    _writeOptionalNode(node.typeArguments);
    _sink.writeElement(node.element);
    _sink.writeType((node as ConstructorTypeReferenceImpl).type);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _sink.writeEnum(AstNodeTag.DeclaredIdentifier);
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.keyword?.keyword == Keyword.CONST,
        isFinal: node.keyword?.keyword == Keyword.FINAL,
        isVar: node.keyword?.keyword == Keyword.VAR,
      ),
    );
    _writeOptionalNode(node.type);
    _writeDeclarationName(node.name);
    _storeDeclaration(node);
  }

  @override
  void visitDelimitedFormalParameters(DelimitedFormalParameters node) {
    _sink.writeEnum(AstNodeTag.DelimitedFormalParameters);
    _writeByte(AstBinaryFlags.encode(isNamed: node.isNamed));
    _writeNodeList(node.formalParameters);
  }

  @override
  void visitDirectAssignment(DirectAssignment node) {
    _sink.writeEnum(AstNodeTag.DirectAssignment);
    _writeNode(node.target);
    _writeNode(node.value);
    _storeExpression(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    covariant DotShorthandConstructorInvocationImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.DotShorthandConstructorInvocation);
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.constKeyword?.type == Keyword.CONST,
        isDotShorthand: node.isDotShorthand,
      ),
    );
    _writeNode(node.constructorName);
    _writeNode(node.argumentList);
    _storeExpression(node);
  }

  @override
  void visitDotShorthandInvocation(covariant DotShorthandInvocationImpl node) {
    _sink.writeEnum(AstNodeTag.DotShorthandInvocation);
    _writeByte(AstBinaryFlags.encode(isDotShorthand: node.isDotShorthand));
    _writeNode(node.memberName);
    _storeInvocationExpression(node);
  }

  @override
  void visitDotShorthandPropertyAccess(
    covariant DotShorthandPropertyAccessImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.DotShorthandPropertyAccess);
    _writeByte(AstBinaryFlags.encode(isDotShorthand: node.isDotShorthand));
    _writeNode(node.propertyName);
    _storeExpression(node);
  }

  @override
  void visitDottedName(DottedName node) {
    _sink.writeEnum(AstNodeTag.DottedName);
    _writeUint32(node.tokens.length);
    for (var i = 0; i < node.tokens.length; i++) {
      _writeStringReference(node.tokens[i].lexeme);
    }
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _sink.writeEnum(AstNodeTag.DoubleLiteral);
    _writeDouble(node.value);
    _storeExpression(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _sink.writeEnum(AstNodeTag.ExtensionOverride);

    _writeOptionalNode(node.importPrefix);
    _writeStringReference(node.name.lexeme);
    _writeOptionalNode(node.typeArguments);
    _writeNode(node.argumentList);

    _sink.writeElement(node.element);
    _sink.writeType(node.extendedType);

    // TODO(scheglov): typeArgumentTypes?
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    _sink.writeEnum(AstNodeTag.FieldFormalParameter);

    _withTypeParameters(node.functionTypedSuffix?.typeParameters, () {
      _writeOptionalNode(node.functionTypedSuffix?.typeParameters);
      _writeOptionalNode(node.type);
      _writeOptionalNode(node.functionTypedSuffix?.formalParameters);
      _storeRegularFormalParameter(node, node.constFinalOrVarKeyword);
    });
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _sink.writeEnum(AstNodeTag.ForEachPartsWithDeclaration);
    _writeNode(node.loopVariable);
    _storeForEachParts(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _sink.writeEnum(AstNodeTag.FormalParameterList);
    _writeNodeList(node.requiredPositionalFormalParameters);
    _writeOptionalNode(node.delimitedFormalParameters);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _sink.writeEnum(AstNodeTag.ForPartsWithDeclarations);
    _writeNode(node.variables);
    _storeForParts(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _sink.writeEnum(AstNodeTag.ForPartsWithExpression);
    _writeOptionalNode(node.initialization2);
    _storeForParts(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _sink.writeEnum(AstNodeTag.FunctionExpressionInvocation);

    _writeNode(node.function2);
    _storeInvocationExpression(node);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _sink.writeEnum(AstNodeTag.FunctionReference);
    _writeNode(node.function2);
    _writeOptionalNode(node.typeArguments);
    _sink.writeOptionalTypeList(node.typeArgumentTypes);
    _storeExpression(node);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    _sink.writeEnum(AstNodeTag.GenericFunctionType);

    _writeByte(AstBinaryFlags.encode(hasQuestion: node.question != null));

    _withTypeParameters(node.typeParameters, () {
      _writeOptionalNode(node.typeParameters);
      _writeOptionalNode(node.returnType);
      _writeNode(node.parameters);
      _sink.writeType(node.type);
      _storeFormalParameterListResolution(node.parameters);
    });
  }

  @override
  void visitIfElement(IfElement node) {
    _sink.writeEnum(AstNodeTag.IfElement);
    _writeNode(node.expression2);
    _writeNode(node.thenElement2);
    _writeOptionalNode(node.elseElement2);
  }

  @override
  void visitIfNull(IfNull node) {
    _sink.writeEnum(AstNodeTag.IfNull);
    _writeNode(node.leftOperand);
    _writeNode(node.rightOperand);
    _storeExpression(node);
  }

  @override
  void visitIfNullAssignment(IfNullAssignment node) {
    _sink.writeEnum(AstNodeTag.IfNullAssignment);
    _writeNode(node.target);
    _writeNode(node.value);
    _storeExpression(node);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    _sink.writeEnum(AstNodeTag.ImplicitCallReference);
    _writeNode(node.expression2);
    _writeOptionalNode(node.typeArguments);
    _sink.writeOptionalTypeList(node.typeArgumentTypes);

    _sink.writeElement(node.element);

    _storeExpression(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _sink.writeEnum(AstNodeTag.ImportPrefixReference);
    _writeStringReference(node.name.lexeme);
    _sink.writeElement(node.element);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _sink.writeEnum(AstNodeTag.IndexExpression);
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod: node.period != null,
        hasQuestion: node.question != null,
      ),
    );
    _writeOptionalNode(node.target2);
    _writeNode(node.index2);

    _sink.writeElement(node.element);

    _storeExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    var value = node.value;

    if (value == null) {
      _sink.writeEnum(AstNodeTag.IntegerLiteralNull);
      _writeStringReference(node.literal.lexeme);
    } else {
      var isPositive = value >= 0;
      if (!isPositive) {
        value = -value;
      }

      if (value & 0xFF == value) {
        _sink.writeEnum(
          isPositive
              ? AstNodeTag.IntegerLiteralPositive1
              : AstNodeTag.IntegerLiteralNegative1,
        );
        _writeStringReference(node.literal.lexeme);
        _writeByte(value);
      } else {
        _sink.writeEnum(
          isPositive
              ? AstNodeTag.IntegerLiteralPositive
              : AstNodeTag.IntegerLiteralNegative,
        );
        _writeStringReference(node.literal.lexeme);
        _writeUint32(value >> 32);
        _writeUint32(value & 0xFFFFFFFF);
      }
    }

    // TODO(scheglov): Don't write type, AKA separate true `int` and `double`?
    _storeExpression(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _sink.writeEnum(AstNodeTag.InterpolationExpression);
    _writeByte(
      AstBinaryFlags.encode(
        isStringInterpolationIdentifier:
            node.leftBracket.type == TokenType.STRING_INTERPOLATION_IDENTIFIER,
      ),
    );
    _writeNode(node.expression2);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _sink.writeEnum(AstNodeTag.InterpolationString);
    _writeStringReference(node.contents.lexeme);
    _writeStringReference(node.value);
  }

  @override
  void visitInvalidExpressionAssignmentTarget(
    InvalidExpressionAssignmentTarget node,
  ) {
    _sink.writeEnum(AstNodeTag.InvalidExpressionAssignmentTarget);
    _writeNode(node.expression);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _sink.writeEnum(AstNodeTag.IsExpression);
    _writeByte(AstBinaryFlags.encode(hasNot: node.notOperator != null));
    _writeNode(node.expression2);
    _writeNode(node.type);
    _storeExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _sink.writeEnum(AstNodeTag.ListLiteral);

    _writeByte(AstBinaryFlags.encode(isConst: node.constKeyword != null));

    _writeOptionalNode(node.typeArguments);
    _writeNodeList(node.elements2);

    _storeExpression(node);
  }

  @override
  void visitLogicalAnd(LogicalAnd node) {
    _sink.writeEnum(AstNodeTag.LogicalAnd);
    _writeNode(node.leftOperand);
    _writeNode(node.rightOperand);
    _storeExpression(node);
  }

  @override
  void visitLogicalNot(LogicalNot node) {
    _sink.writeEnum(AstNodeTag.LogicalNot);
    _writeNode(node.operand);
    _storeExpression(node);
  }

  @override
  void visitLogicalOr(LogicalOr node) {
    _sink.writeEnum(AstNodeTag.LogicalOr);
    _writeNode(node.leftOperand);
    _writeNode(node.rightOperand);
    _storeExpression(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _sink.writeEnum(AstNodeTag.MapLiteralEntry);
    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion: node.keyQuestion?.type == TokenType.QUESTION,
      ),
    );
    _writeNode(node.key2);
    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion: node.valueQuestion?.type == TokenType.QUESTION,
      ),
    );
    _writeNode(node.value2);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _sink.writeEnum(AstNodeTag.MethodInvocation);

    var operatorType = node.operator?.type;
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod:
            operatorType == TokenType.PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD,
        hasPeriod2:
            operatorType == TokenType.PERIOD_PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD_PERIOD,
        hasQuestion:
            operatorType == TokenType.QUESTION_PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD_PERIOD,
      ),
    );

    _writeOptionalNode(node.target2);
    _writeNode(node.methodName);
    _storeInvocationExpression(node);
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    _sink.writeEnum(AstNodeTag.NamedArgument);

    _writeStringReference(node.name.lexeme);

    _writeNode(node.argumentExpression2);
  }

  @override
  void visitNamedType(NamedType node) {
    _sink.writeEnum(AstNodeTag.NamedType);

    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion: node.question != null,
        hasTypeArguments: node.typeArguments != null,
      ),
    );

    _writeOptionalNode(node.importPrefix);
    _writeStringReference(node.name.lexeme);
    _writeOptionalNode(node.typeArguments);

    _sink.writeElement(node.element);
    _sink.writeType(node.type);
  }

  @override
  void visitNullAssertionExpression(NullAssertionExpression node) {
    _sink.writeEnum(AstNodeTag.NullAssertionExpression);
    _writeNode(node.operand);
    _storeExpression(node);
  }

  @override
  void visitNullAwareElement(NullAwareElement node) {
    _sink.writeEnum(AstNodeTag.NullAwareElement);
    _writeNode(node.value2);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _sink.writeEnum(AstNodeTag.NullLiteral);
    _storeExpression(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _sink.writeEnum(AstNodeTag.ParenthesizedExpression);
    _writeNode(node.expression2);
    _storeExpression(node);
  }

  @override
  void visitPostfixDecrement(PostfixDecrement node) {
    _sink.writeEnum(AstNodeTag.PostfixDecrement);
    _writeNode(node.target);
    _writeIncrementOrDecrementResolution(node);
  }

  @override
  void visitPostfixIncrement(PostfixIncrement node) {
    _sink.writeEnum(AstNodeTag.PostfixIncrement);
    _writeNode(node.target);
    _writeIncrementOrDecrementResolution(node);
  }

  @override
  void visitPrefixDecrement(PrefixDecrement node) {
    _sink.writeEnum(AstNodeTag.PrefixDecrement);
    _writeNode(node.target);
    _writeIncrementOrDecrementResolution(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _sink.writeEnum(AstNodeTag.PrefixedIdentifier);
    _writeNode(node.prefix);
    _writeNode(node.identifier);

    // TODO(scheglov): In actual prefixed identifier, the type of the identifier.
    _storeExpression(node);
  }

  @override
  void visitPrefixIncrement(PrefixIncrement node) {
    _sink.writeEnum(AstNodeTag.PrefixIncrement);
    _writeNode(node.target);
    _writeIncrementOrDecrementResolution(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _sink.writeEnum(AstNodeTag.PropertyAccess);

    var operatorType = node.operator.type;
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod:
            operatorType == TokenType.PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD,
        hasPeriod2:
            operatorType == TokenType.PERIOD_PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD_PERIOD,
        hasQuestion:
            operatorType == TokenType.QUESTION_PERIOD ||
            operatorType == TokenType.QUESTION_PERIOD_PERIOD,
      ),
    );

    _writeOptionalNode(node.target2);
    _writeNode(node.propertyName);
    // TODO(scheglov): Get from the property?
    _storeExpression(node);
  }

  @override
  void visitReceiverIndexAssignmentTarget(
    covariant ReceiverIndexAssignmentTargetImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.ReceiverIndexAssignmentTarget);
    _writeByte(AstBinaryFlags.encode(hasQuestion: node.question != null));
    _writeNode(node.receiver);
    _writeNode(node.index);
    _sink.writeOptionalObject(node.read, _writeIndexReadResolution);
    _sink.writeOptionalObject(node.write, _writeIndexWriteResolution);
  }

  @override
  void visitReceiverIndexExpression(
    covariant ReceiverIndexExpressionImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.ReceiverIndexExpression);
    _writeByte(AstBinaryFlags.encode(hasQuestion: node.question != null));
    _writeNode(node.receiver);
    _writeNode(node.index);
    _sink.writeOptionalObject(node.resolution, _writeIndexReadResolution);
    _storeExpression(node);
  }

  @override
  void visitReceiverPropertyAssignmentTarget(
    covariant ReceiverPropertyAssignmentTargetImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.ReceiverPropertyAssignmentTarget);
    _writeNode(node.receiver);
    _sink.writeEnum(TokensWriter.astToBinaryTokenType(node.operator.type));
    _writeStringReference(node.propertyName.lexeme);
    _sink.writeOptionalObject(node.read, _writeNamedReadResolution);
    _sink.writeOptionalObject(node.write, _writeNamedWriteResolution);
  }

  @override
  void visitReceiverPropertyExtraction(
    covariant ReceiverPropertyExtractionImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.ReceiverPropertyExtraction);
    _writeNode(node.receiver);
    _sink.writeEnum(TokensWriter.astToBinaryTokenType(node.operator.type));
    _writeStringReference(node.propertyName.lexeme);
    _sink.writeOptionalObject(node.resolution, _writeNamedReadResolution);
    _storeExpression(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _sink.writeEnum(AstNodeTag.RecordLiteral);
    _writeByte(AstBinaryFlags.encode(isConst: node.constKeyword != null));
    _writeNodeList(node.fields2);
    _storeExpression(node);
  }

  @override
  void visitRecordLiteralNamedField(RecordLiteralNamedField node) {
    _sink.writeEnum(AstNodeTag.RecordLiteralNamedField);
    _writeStringReference(node.name.lexeme);
    _writeNode(node.fieldExpression2);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    _sink.writeEnum(AstNodeTag.RecordTypeAnnotation);

    _writeByte(AstBinaryFlags.encode(hasQuestion: node.question != null));

    _writeNodeList(node.positionalFields);
    _writeOptionalNode(node.namedFields);

    _sink.writeType(node.type);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    _sink.writeEnum(AstNodeTag.RecordTypeAnnotationNamedField);
    _writeNodeList(node.metadata);
    _writeNode(node.type);
    _writeStringReference(node.name.lexeme);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    _sink.writeEnum(AstNodeTag.RecordTypeAnnotationNamedFields);
    _writeNodeList(node.fields);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    _sink.writeEnum(AstNodeTag.RecordTypeAnnotationPositionalField);
    _writeNodeList(node.metadata);
    _writeNode(node.type);
    _sink.writeOptionalObject(node.name, (name) {
      _writeStringReference(name.lexeme);
    });
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _sink.writeEnum(AstNodeTag.RedirectingConstructorInvocation);

    _writeOptionalNode(node.constructorSelector);
    _writeNode(node.argumentList);

    _sink.writeElement(node.element);
  }

  @override
  void visitRegularFormalParameter(covariant RegularFormalParameterImpl node) {
    _sink.writeEnum(AstNodeTag.RegularFormalParameter);

    _withTypeParameters(node.functionTypedSuffix?.typeParameters, () {
      _writeOptionalNode(node.functionTypedSuffix?.typeParameters);
      _writeOptionalNode(node.type);
      _writeOptionalNode(node.functionTypedSuffix?.formalParameters);
      _storeRegularFormalParameter(node, node.constFinalOrVarKeyword);
    });
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _sink.writeEnum(AstNodeTag.SetOrMapLiteral);

    _writeByte(AstBinaryFlags.encode(isConst: node.constKeyword != null));

    var isMapBit = node.isMap ? (1 << 0) : 0;
    var isSetBit = node.isSet ? (1 << 1) : 0;
    _sink.writeByte(isMapBit | isSetBit);

    _writeOptionalNode(node.typeArguments);
    _writeNodeList(node.elements2);

    _storeExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _sink.writeEnum(AstNodeTag.SimpleIdentifier);
    _writeStringReference(node.name);

    _sink.writeElement(node.element);
    _sink.writeOptionalTypeList(node.tearOffTypeArgumentTypes);

    _storeExpression(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _sink.writeEnum(AstNodeTag.SimpleStringLiteral);
    _writeStringReference(node.literal.lexeme);
    _writeStringReference(node.value);
    _storeExpression(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _sink.writeEnum(AstNodeTag.SpreadElement);
    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion:
            node.spreadOperator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION,
      ),
    );
    _writeNode(node.expression2);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _sink.writeEnum(AstNodeTag.StringInterpolation);
    _writeNodeList(node.elements);
    _storeExpression(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _sink.writeEnum(AstNodeTag.SuperConstructorInvocation);

    _writeOptionalNode(node.constructorSelector);
    _writeNode(node.argumentList);

    _sink.writeElement(node.element);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _sink.writeEnum(AstNodeTag.SuperExpression);
    _storeExpression(node);
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    _sink.writeEnum(AstNodeTag.SuperFormalParameter);

    _withTypeParameters(node.functionTypedSuffix?.typeParameters, () {
      _writeOptionalNode(node.functionTypedSuffix?.typeParameters);
      _writeOptionalNode(node.type);
      _writeOptionalNode(node.functionTypedSuffix?.formalParameters);
      _storeRegularFormalParameter(node, node.constFinalOrVarKeyword);
    });
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _sink.writeEnum(AstNodeTag.SymbolLiteral);

    var components = node.components;
    _writeUint30(components.length);
    for (var token in components) {
      _writeStringReference(token.lexeme);
    }
    _storeExpression(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _sink.writeEnum(AstNodeTag.ThisExpression);
    _storeExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _sink.writeEnum(AstNodeTag.ThrowExpression);
    _writeNode(node.expression2);
    _storeExpression(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _sink.writeEnum(AstNodeTag.TypeArgumentList);
    _writeNodeList(node.arguments);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _sink.writeEnum(AstNodeTag.TypeLiteral);
    _writeNode(node.type);
    _storeExpression(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _sink.writeEnum(AstNodeTag.TypeParameter);
    _writeDeclarationName(node.name);
    _writeOptionalNode(node.bound);
    _storeDeclaration(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _sink.writeEnum(AstNodeTag.TypeParameterList);
    _writeNodeList(node.typeParameters);
  }

  @override
  void visitUnaryOperatorInvocation(UnaryOperatorInvocation node) {
    _sink.writeEnum(AstNodeTag.UnaryOperatorInvocation);

    var binaryToken = TokensWriter.astToBinaryTokenType(node.operator.type);
    _sink.writeEnum(binaryToken);
    _writeNode(node.operand);

    _storeExpression(node);
    _sink.writeElement(node.element);
  }

  @override
  void visitUnqualifiedNameAssignmentTarget(
    covariant UnqualifiedNameAssignmentTargetImpl node,
  ) {
    _sink.writeEnum(AstNodeTag.UnqualifiedNameAssignmentTarget);
    _writeStringReference(node.name.lexeme);
    _sink.writeOptionalObject(node.read, _writeNamedReadResolution);
    _sink.writeOptionalObject(node.write, _writeNamedWriteResolution);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _sink.writeEnum(AstNodeTag.VariableDeclarationList);
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.isConst,
        isFinal: node.isFinal,
        isLate: node.lateKeyword != null,
        isVar: node.keyword?.keyword == Keyword.VAR,
      ),
    );
    _writeOptionalNode(node.type);
    _writeNodeList(node.variables);
    _storeAnnotatedNode(node);
  }

  void _storeAnnotatedNode(AnnotatedNode node) {
    _writeNodeList(node.metadata);
  }

  void _storeDeclaration(Declaration node) {
    _storeAnnotatedNode(node);
  }

  void _storeExpression(Expression node) {
    _sink.writeType(node.staticType);
  }

  void _storeForEachParts(ForEachParts node) {
    _writeNode(node.iterable2);
    _storeForLoopParts(node);
  }

  void _storeForLoopParts(ForLoopParts node) {}

  void _storeFormalParameter(FormalParameterImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    _writeActualType(_sink, element.type);
  }

  void _storeFormalParameterListResolution(FormalParameterListImpl node) {
    for (var formalParameter in node.allFormalParameters) {
      var functionTypedSuffix = formalParameter.functionTypedSuffix;
      _withTypeParameters(functionTypedSuffix?.typeParameters, () {
        _storeFormalParameter(formalParameter);
        if (functionTypedSuffix != null) {
          _storeFormalParameterListResolution(
            functionTypedSuffix.formalParameters,
          );
        }
      });
    }
  }

  void _storeForParts(ForParts node) {
    _writeOptionalNode(node.condition2);
    _writeNodeList(node.updaters2);
    _storeForLoopParts(node);
  }

  void _storeInvocationExpression(InvocationExpression node) {
    _writeOptionalNode(node.typeArguments);
    _writeNode(node.argumentList);
    _sink.writeType(node.staticInvokeType);
    _sink.writeOptionalTypeList(node.typeArgumentTypes);
    _storeExpression(node);
  }

  void _storeRegularFormalParameter(FormalParameterImpl node, Token? keyword) {
    _writeByte(
      AstBinaryFlags.encodeFormalParameter(
        hasInitializer: node.defaultClause != null,
        hasName: node.name != null,
        hasQuestion: node.functionTypedSuffix?.question != null,
        isConst: keyword?.type == Keyword.CONST,
        isCovariant: node.covariantKeyword != null,
        isFinal: keyword?.type == Keyword.FINAL,
        isPositional: node.isPositional,
        isRequired: node.isRequired,
        isVar: keyword?.type == Keyword.VAR,
      ),
    );

    _writeNodeList(node.metadata);
    if (node.name != null) {
      _writeDeclarationName(node.name!);
    }
    if (node.defaultClause case var defaultClause?) {
      _writeNode(defaultClause.value2);
    }
  }

  void _withTypeParameters(TypeParameterListImpl? node, void Function() f) {
    if (node == null) {
      f();
    } else {
      var typeParameterElements = node.typeParameters
          .map((typeParameter) => typeParameter.declaredFragment!.element)
          .toList();
      _sink.localElements.withElements(typeParameterElements, () {
        f();
      });
    }
  }

  void _writeActualType(ResolutionSink resolutionSink, DartType type) {
    resolutionSink.writeType(type);
  }

  void _writeByte(int byte) {
    assert((byte & 0xFF) == byte);
    _sink.writeByte(byte);
  }

  void _writeDeclarationName(Token token) {
    _writeStringReference(token.lexeme);
  }

  void _writeDouble(double value) {
    _sink.writeDouble(value);
  }

  void _writeIncrementOrDecrementResolution(
    IncrementOrDecrementExpression node,
  ) {
    _sink.writeElement(node.element);
    _sink.writeType(node.operatorResultType);
    _storeExpression(node);
  }

  void _writeIndexReadResolution(IndexReadResolutionImpl resolution) {
    switch (resolution) {
      case DynamicIndexReadResolutionImpl():
        _sink.writeEnum(IndexReadResolutionTag.dynamic_);
      case InvalidIndexReadResolutionImpl(:var recovery):
        _sink.writeEnum(IndexReadResolutionTag.invalid);
        _sink.writeOptionalObject(recovery, _writeIndexReadResolution);
      case MethodIndexReadResolutionImpl(:var element, :var type):
        _sink.writeEnum(IndexReadResolutionTag.method);
        _sink.writeElement(element);
        _sink.writeType(type);
    }
  }

  void _writeIndexWriteResolution(IndexWriteResolutionImpl resolution) {
    switch (resolution) {
      case DynamicIndexWriteResolutionImpl():
        _sink.writeEnum(IndexWriteResolutionTag.dynamic_);
      case InvalidIndexWriteResolutionImpl(:var recovery):
        _sink.writeEnum(IndexWriteResolutionTag.invalid);
        _sink.writeOptionalObject(recovery, _writeIndexWriteResolution);
      case MethodIndexWriteResolutionImpl(:var element):
        _sink.writeEnum(IndexWriteResolutionTag.method);
        _sink.writeElement(element);
    }
  }

  void _writeNamedReadResolution(NamedReadResolutionImpl resolution) {
    switch (resolution) {
      case DynamicPropertyReadResolutionImpl():
        _sink.writeEnum(NamedReadResolutionTag.dynamicPropertyRead);
      case ExecutableTearOffResolutionImpl():
        _sink.writeEnum(NamedReadResolutionTag.executableTearOff);
        _sink.writeElement(resolution.element);
      case FunctionCallTearOffResolutionImpl():
        _sink.writeEnum(NamedReadResolutionTag.functionCallTearOff);
        _sink.writeType(resolution.type);
        _sink.writeType(resolution.associatedFunctionType);
      case FunctionInterfaceCallTearOffResolutionImpl():
        _sink.writeEnum(NamedReadResolutionTag.functionInterfaceCallTearOff);
        _sink.writeType(resolution.type);
      case GetterInvocationResolutionImpl():
        _sink.writeEnum(NamedReadResolutionTag.getterInvocation);
        _sink.writeElement(resolution.element);
        _sink.writeType(resolution.type);
      case InvalidNamedReadResolutionImpl():
        _sink.writeEnum(NamedReadResolutionTag.invalid);
        _sink.writeType(resolution.type);
        _sink.writeList(resolution.candidates, _sink.writeElement);
        _sink.writeOptionalObject(resolution.recovery, (recovery) {
          _writeNamedReadResolution(recovery);
        });
      case RecordFieldReadResolutionImpl():
        _sink.writeEnum(NamedReadResolutionTag.recordFieldRead);
        _sink.writeType(resolution.type);
      case VariableReadResolutionImpl():
        _sink.writeEnum(NamedReadResolutionTag.variableRead);
        _sink.writeElement(resolution.element);
        _sink.writeType(resolution.type);
    }
  }

  void _writeNamedWriteResolution(NamedWriteResolutionImpl resolution) {
    switch (resolution) {
      case InvalidNamedWriteResolutionImpl():
        _sink.writeEnum(NamedWriteResolutionTag.invalid);
        _sink.writeType(resolution.acceptedType);
        _sink.writeList(resolution.candidates, _sink.writeElement);
        _sink.writeOptionalObject(resolution.recovery, (recovery) {
          _writeNamedWriteResolution(recovery);
        });
      case SetterInvocationResolutionImpl():
        _sink.writeEnum(NamedWriteResolutionTag.setterInvocation);
        _sink.writeElement(resolution.element);
      case VariableWriteResolutionImpl():
        _sink.writeEnum(NamedWriteResolutionTag.variableWrite);
        _sink.writeElement(resolution.element);
        _sink.writeType(resolution.acceptedType);
      case DynamicPropertyWriteResolutionImpl():
        _sink.writeEnum(NamedWriteResolutionTag.dynamicPropertyWrite);
    }
  }

  void _writeNode(AstNode node) {
    node.accept2(this);
  }

  void _writeNodeList(List<AstNode> nodeList) {
    _writeUint30(nodeList.length);
    for (var i = 0; i < nodeList.length; ++i) {
      nodeList[i].accept2(this);
    }
  }

  void _writeOptionalNode(AstNode? node) {
    _sink.writeOptionalObject(node, _writeNode);
  }

  void _writeStringReference(String string) {
    _sink.writeStringReference(string);
  }

  @pragma("vm:prefer-inline")
  void _writeUint30(int value) {
    _sink.writeUint30(value);
  }

  void _writeUint32(int value) {
    _sink.writeUint32(value);
  }

  /// Return `true` if the expression might be successfully serialized.
  ///
  /// This does not mean that the expression is constant, it just means that
  /// we know that it might be serialized and deserialized. For example
  /// function expressions are problematic, and are not necessary to
  /// deserialize, so we choose not to do this.
  static bool _isSerializableExpression(Expression? node) {
    if (node == null) return false;

    var visitor = _IsSerializableExpressionVisitor();
    node.accept2(visitor);
    return visitor.result;
  }
}

class _IsSerializableExpressionVisitor extends RecursiveAstVisitor2<void> {
  bool result = true;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    result = false;
  }
}
