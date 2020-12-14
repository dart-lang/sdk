// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/task/inference_error.dart';

class ApplyResolutionVisitor extends ThrowingAstVisitor<void> {
  final LinkedUnitContext _unitContext;
  final LinkedResolutionReader _resolution;

  /// The stack of [TypeParameterElement]s and [ParameterElement] that are
  /// available in the scope of [_nextElement] and [_nextType].
  ///
  /// This stack is shared with [_resolution].
  final List<Element> _localElements;

  final List<ElementImpl> _enclosingElements = [];

  ApplyResolutionVisitor(
    this._unitContext,
    this._localElements,
    this._resolution,
  ) {
    _enclosingElements.add(_unitContext.element);
  }

  /// TODO(scheglov) make private
  void addParentTypeParameters(AstNode node) {
    var enclosing = node.parent;
    if (enclosing is ClassOrMixinDeclaration) {
      var typeParameterList = enclosing.typeParameters;
      if (typeParameterList == null) return;

      for (var typeParameter in typeParameterList.typeParameters) {
        var element = typeParameter.declaredElement;
        _localElements.add(element);
      }
    } else if (enclosing is ExtensionDeclaration) {
      var typeParameterList = enclosing.typeParameters;
      if (typeParameterList == null) return;

      for (var typeParameter in typeParameterList.typeParameters) {
        var element = typeParameter.declaredElement;
        _localElements.add(element);
      }
    } else if (enclosing is VariableDeclarationList) {
      var enclosing2 = enclosing.parent;
      if (enclosing2 is FieldDeclaration) {
        return addParentTypeParameters(enclosing2);
      } else if (enclosing2 is TopLevelVariableDeclaration) {
        return;
      } else {
        throw UnimplementedError('${enclosing2.runtimeType}');
      }
    } else {
      throw UnimplementedError('${enclosing.runtimeType}');
    }
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    node.strings.accept(this);
    // TODO(scheglov) type?
  }

  @override
  void visitAnnotation(Annotation node) {
    node.name.accept(this);
    node.constructorName?.accept(this);
    node.arguments?.accept(this);
    node.element = _nextElement();
  }

  @override
  void visitArgumentList(ArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitAsExpression(AsExpression node) {
    node.expression.accept(this);
    node.type.accept(this);
    _expression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    node.condition.accept(this);
    node.message?.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var nodeImpl = node as AssignmentExpressionImpl;
    node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);
    node.staticElement = _nextElement();
    nodeImpl.readElement = _nextElement();
    nodeImpl.readType = _nextType();
    nodeImpl.writeElement = _nextElement();
    nodeImpl.writeType = _nextType();
    _expression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);
    node.rightOperand.accept(this);

    node.staticElement = _nextElement();
    node.staticType = _nextType();
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    node.staticType = _nextType();
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    node.target.accept(this);
    node.cascadeSections.accept(this);
    node.staticType = node.target.staticType;
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    _assertNoLocalElements();

    var element = node.declaredElement as ClassElementImpl;
    element.isSimplyBounded = _resolution.readByte() != 0;
    _enclosingElements.add(element);

    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.nativeClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    _namedCompilationUnitMember(node);

    _enclosingElements.removeLast();
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _assertNoLocalElements();
    var element = node.declaredElement as ClassElementImpl;
    _enclosingElements.add(element);

    element.isSimplyBounded = _resolution.readByte() != 0;
    node.typeParameters?.accept(this);
    node.superclass?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    node.metadata?.accept(this);

    _enclosingElements.removeLast();
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
    node.staticType = _nextType();
  }

  @override
  void visitConfiguration(Configuration node) {
    node.name?.accept(this);
    node.value?.accept(this);
    node.uri?.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _assertNoLocalElements();
    _pushEnclosingClassTypeParameters(node);

    var element = node.declaredElement as ConstructorElementImpl;
    _enclosingElements.add(element.enclosingElement);
    _enclosingElements.add(element);

    node.returnType?.accept(this);
    node.parameters?.accept(this);

    for (var parameter in node.parameters.parameters) {
      _localElements.add(parameter.declaredElement);
    }

    node.initializers?.accept(this);
    node.redirectedConstructor?.accept(this);
    node.metadata?.accept(this);

    _enclosingElements.removeLast();
    _enclosingElements.removeLast();
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.fieldName.accept(this);
    node.expression.accept(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    // Rewrite:
    //   ConstructorName
    //     type: TypeName
    //       name: PrefixedIdentifier
    //     name: null
    // into:
    //    ConstructorName
    //      type: TypeName
    //        name: SimpleIdentifier
    //      name: SimpleIdentifier
    var hasName = _resolution.readByte() != 0;
    if (hasName && node.name == null) {
      var typeName = node.type.name as PrefixedIdentifier;
      NodeReplacer.replace(
        node.type,
        astFactory.typeName(typeName.prefix, null),
      );
      node.name = typeName.identifier;
    }

    node.type.accept(this);
    node.name?.accept(this);
    node.staticElement = _nextElement();
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.type?.accept(this);
    // node.identifier.accept(this);
    _declaration(node);
  }

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
    var nodeImpl = node as DefaultFormalParameterImpl;

    var enclosing = _enclosingElements.last;
    var name = node.identifier?.name ?? '';
    var reference = node.isNamed && enclosing.reference != null
        ? enclosing.reference.getChild('@parameter').getChild(name)
        : null;
    ParameterElementImpl element;
    if (node.parameter is FieldFormalParameter) {
      element = DefaultFieldFormalParameterElementImpl.forLinkedNode(
          enclosing, reference, node);
    } else {
      element =
          DefaultParameterElementImpl.forLinkedNode(enclosing, reference, node);
    }

    var summaryData = nodeImpl.summaryData as SummaryDataForFormalParameter;
    element.setCodeRange(summaryData.codeOffset, summaryData.codeLength);

    node.parameter.accept(this);
    node.defaultValue?.accept(this);
  }

  @override
  void visitDottedName(DottedName node) {
    node.components.accept(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    // TODO(scheglov) type?
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.metadata?.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    node.constants.accept(this);
    node.metadata?.accept(this);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _namespaceDirective(node);
    (node.element as ExportElementImpl).exportedLibrary = _nextElement();
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.expression.accept(this);
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _assertNoLocalElements();

    var element = node.declaredElement as ExtensionElementImpl;
    _enclosingElements.add(element);

    node.typeParameters?.accept(this);
    node.extendedType?.accept(this);
    node.metadata?.accept(this);

    _enclosingElements.removeLast();
  }

  @override
  void visitExtensionOverride(
    ExtensionOverride node, {
    bool readRewrite = true,
  }) {
    // Read possible rewrite of `MethodInvocation`.
    // If we are here, we don't need it.
    if (readRewrite) {
      _resolution.readByte();
    }

    node.extensionName.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
    (node as ExtensionOverrideImpl).extendedType = _nextType();
    // TODO(scheglov) typeArgumentTypes?
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _assertNoLocalElements();
    _pushEnclosingClassTypeParameters(node);

    node.fields.accept(this);
    node.metadata?.accept(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    ParameterElement element;
    if (node.parent is! DefaultFormalParameter) {
      var enclosing = _enclosingElements.last;
      element =
          FieldFormalParameterElementImpl.forLinkedNode(enclosing, null, node);
    }

    var localElementsLength = _localElements.length;

    node.typeParameters?.accept(this);
    node.type?.accept(this);
    node.parameters?.accept(this);
    _normalFormalParameter(node, element);

    _localElements.length = localElementsLength;
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    node.loopVariable.accept(this);
    _forEachParts(node);
  }

  @override
  void visitForElement(ForElement node) {
    node.body.accept(this);
    node.forLoopParts.accept(this);
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    for (var variable in node.variables.variables) {
      var nameNode = variable.name;
      nameNode.staticElement = LocalVariableElementImpl(
        nameNode.name,
        nameNode.offset,
      );
    }
    node.variables.accept(this);
    _forParts(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _assertNoLocalElements();

    var element = node.declaredElement as ExecutableElementImpl;
    assert(element != null);

    _enclosingElements.add(element);

    node.functionExpression.accept(this);
    node.returnType?.accept(this);

    node.metadata?.accept(this);
    element.returnType = _nextType();
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFunctionExpressionInvocation(
    FunctionExpressionInvocation node, {
    bool readRewrite = true,
  }) {
    // Read possible rewrite of `MethodInvocation`.
    // If we are here, we don't need it.
    if (readRewrite) {
      _resolution.readByte();
    }

    node.function.accept(this);
    _invocationExpression(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _assertNoLocalElements();

    var element = node.declaredElement as FunctionTypeAliasElementImpl;
    _enclosingElements.add(element);

    node.typeParameters?.accept(this);

    _enclosingElements.add(element.function);
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    _enclosingElements.removeLast();

    node.metadata?.accept(this);

    element.function.returnType = _nextType();
    element.isSimplyBounded = _resolution.readByte() != 0;
    element.hasSelfReference = _resolution.readByte() != 0;

    _enclosingElements.removeLast();
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var element = node.declaredElement;
    if (node.parent is! DefaultFormalParameter) {
      var enclosing = _enclosingElements.last;
      element =
          ParameterElementImpl.forLinkedNodeFactory(enclosing, null, node);
    }

    var localElementsLength = _localElements.length;

    node.typeParameters?.accept(this);
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    _normalFormalParameter(node, element);

    _localElements.length = localElementsLength;
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var nodeImpl = node as GenericFunctionTypeImpl;
    var localElementsLength = _localElements.length;

    var element = nodeImpl.declaredElement as GenericFunctionTypeElementImpl;
    element ??= GenericFunctionTypeElementImpl.forLinkedNode(
        _enclosingElements.last, null, node);
    _enclosingElements.add(element);

    node.typeParameters?.accept(this);
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    nodeImpl.type = _nextType();

    _localElements.length = localElementsLength;
    _enclosingElements.removeLast();
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _assertNoLocalElements();

    var element = node.declaredElement as TypeAliasElementImpl;
    assert(element != null);

    _enclosingElements.add(element);

    node.typeParameters?.accept(this);
    node.type?.accept(this);
    node.metadata?.accept(this);
    element.isSimplyBounded = _resolution.readByte() != 0;
    element.hasSelfReference = _resolution.readByte() != 0;

    _enclosingElements.removeLast();
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    node.hiddenNames.accept(this);
  }

  @override
  void visitIfElement(IfElement node) {
    node.condition.accept(this);
    node.thenElement.accept(this);
    node.elseElement?.accept(this);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    node.interfaces.accept(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _namespaceDirective(node);

    var element = node.element as ImportElementImpl;
    element.importedLibrary = _nextElement();
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    node.index.accept(this);
    node.staticElement = _nextElement();
    _expression(node);
  }

  @override
  void visitInstanceCreationExpression(
    InstanceCreationExpression node, {
    bool readRewrite = true,
  }) {
    // Read possible rewrite of `MethodInvocation`.
    // If we are here, we don't need it.
    if (readRewrite) {
      _resolution.readByte();
    }

    node.constructorName.accept(this);
    (node as InstanceCreationExpressionImpl).typeArguments?.accept(this);
    node.argumentList.accept(this);
    node.staticType = _nextType();
    _resolveNamedExpressions(
      node.constructorName.staticElement,
      node.argumentList,
    );
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    node.staticType = _nextType();
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    // TODO(scheglov) type?
  }

  @override
  void visitIsExpression(IsExpression node) {
    node.expression.accept(this);
    node.type.accept(this);
    _expression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    node.name.accept(this);
    _directive(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    node.components.accept(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    node.typeArguments?.accept(this);
    node.elements.accept(this);
    node.staticType = _nextType();
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    node.key.accept(this);
    node.value.accept(this);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    _assertNoLocalElements();
    _pushEnclosingClassTypeParameters(node);

    var element = node.declaredElement as ExecutableElementImpl;
    _enclosingElements.add(element.enclosingElement);
    _enclosingElements.add(element);

    node.typeParameters?.accept(this);
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    node.metadata?.accept(this);

    element.returnType = _nextType();
    _setTopLevelInferenceError(element);
    if (element is MethodElementImpl) {
      element.isOperatorEqualWithParameterTypeFromObject =
          _resolution.readByte() != 0;
    }

    _enclosingElements.removeLast();
    _enclosingElements.removeLast();
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var rewriteTag = _resolution.readByte();
    if (rewriteTag == MethodInvocationRewriteTag.none) {
      // No rewrite necessary.
    } else if (rewriteTag == MethodInvocationRewriteTag.extensionOverride) {
      Identifier identifier;
      if (node.target == null) {
        identifier = node.methodName;
      } else {
        identifier = astFactory.prefixedIdentifier(
          node.target as SimpleIdentifier,
          node.operator,
          node.methodName,
        );
      }
      var replacement = astFactory.extensionOverride(
        extensionName: identifier,
        typeArguments: node.typeArguments,
        argumentList: node.argumentList,
      );
      NodeReplacer.replace(node, replacement);
      visitExtensionOverride(replacement, readRewrite: false);
      return;
    } else if (rewriteTag ==
        MethodInvocationRewriteTag.functionExpressionInvocation) {
      var target = node.target;
      Expression expression;
      if (target == null) {
        expression = node.methodName;
      } else {
        expression = astFactory.propertyAccess(
          target,
          node.operator,
          node.methodName,
        );
      }
      var replacement = astFactory.functionExpressionInvocation(
        expression,
        node.typeArguments,
        node.argumentList,
      );
      NodeReplacer.replace(node, replacement);
      visitFunctionExpressionInvocation(replacement, readRewrite: false);
      return;
    } else if (rewriteTag ==
        MethodInvocationRewriteTag.instanceCreationExpression_withName) {
      var replacement = astFactory.instanceCreationExpression(
        null,
        astFactory.constructorName(
          astFactory.typeName(node.target as Identifier, null),
          node.operator,
          node.methodName,
        ),
        node.argumentList,
      );
      NodeReplacer.replace(node, replacement);
      visitInstanceCreationExpression(replacement, readRewrite: false);
      return;
    } else if (rewriteTag ==
        MethodInvocationRewriteTag.instanceCreationExpression_withoutName) {
      var typeNameName = node.target == null
          ? node.methodName
          : astFactory.prefixedIdentifier(
              node.target as SimpleIdentifier,
              node.operator,
              node.methodName,
            );
      var replacement = astFactory.instanceCreationExpression(
        null,
        astFactory.constructorName(
          astFactory.typeName(typeNameName, node.typeArguments),
          null,
          null,
        ),
        node.argumentList,
      );
      NodeReplacer.replace(node, replacement);
      visitInstanceCreationExpression(replacement, readRewrite: false);
      return;
    } else {
      throw StateError('[rewriteTag: $rewriteTag][node: $node]');
    }

    node.target?.accept(this);
    node.methodName.accept(this);
    _invocationExpression(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _assertNoLocalElements();
    var element = node.declaredElement as MixinElementImpl;
    element.isSimplyBounded = _resolution.readByte() != 0;
    element.superInvokedNames = _resolution.readStringList();
    _enclosingElements.add(element);

    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
    node.metadata?.accept(this);

    _enclosingElements.removeLast();
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitNativeClause(NativeClause node) {
    node.name.accept(this);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    // TODO(scheglov) type?
  }

  @override
  void visitOnClause(OnClause node) {
    node.superclassConstraints.accept(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.expression.accept(this);
    node.staticType = _nextType();
  }

  @override
  void visitPartDirective(PartDirective node) {
    _uriBasedDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    node.uri?.accept(this);
    _directive(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    var nodeImpl = node as PostfixExpressionImpl;
    node.operand.accept(this);
    node.staticElement = _nextElement();
    if (node.operator.type.isIncrementOperator) {
      nodeImpl.readElement = _nextElement();
      nodeImpl.readType = _nextType();
      nodeImpl.writeElement = _nextElement();
      nodeImpl.writeType = _nextType();
    }
    _expression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    node.identifier.accept(this);
    _expression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var nodeImpl = node as PrefixExpressionImpl;
    node.operand.accept(this);
    node.staticElement = _nextElement();
    if (node.operator.type.isIncrementOperator) {
      nodeImpl.readElement = _nextElement();
      nodeImpl.readType = _nextType();
      nodeImpl.writeElement = _nextElement();
      nodeImpl.writeType = _nextType();
    }
    _expression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    node.propertyName.accept(this);

    node.staticType = _nextType();
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    node.constructorName?.accept(this);
    node.argumentList.accept(this);
    node.staticElement = _nextElement();
    _resolveNamedExpressions(node.staticElement, node.argumentList);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    var mapOrSetBits = _resolution.readByte();
    if ((mapOrSetBits & 0x01) != 0) {
      (node as SetOrMapLiteralImpl).becomeMap();
    } else if ((mapOrSetBits & 0x02) != 0) {
      (node as SetOrMapLiteralImpl).becomeSet();
    }

    node.typeArguments?.accept(this);
    node.elements.accept(this);
    node.staticType = _nextType();
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    node.shownNames.accept(this);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    var element = node.declaredElement as ParameterElementImpl;
    if (node.parent is! DefaultFormalParameter) {
      var enclosing = _enclosingElements.last;
      element =
          ParameterElementImpl.forLinkedNodeFactory(enclosing, null, node);
    }

    node.type?.accept(this);
    _normalFormalParameter(node, element);

    element.inheritsCovariant = _resolution.readByte() != 0;
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    node.staticElement = _nextElement();
    node.staticType = _nextType();
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // TODO(scheglov) type?
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    node.expression.accept(this);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    node.elements.accept(this);
    // TODO(scheglov) type?
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.constructorName?.accept(this);
    node.argumentList.accept(this);
    node.staticElement = _nextElement();
    _resolveNamedExpressions(node.staticElement, node.argumentList);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    node.staticType = _nextType();
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    node.staticType = _nextType();
  }

  @override
  void visitThisExpression(ThisExpression node) {
    node.staticType = _nextType();
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    node.expression.accept(this);
    node.staticType = _nextType();
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.variables.accept(this);
    node.metadata?.accept(this);
  }

  @override
  visitTypeArgumentList(TypeArgumentList node) {
    node.arguments?.accept(this);
  }

  @override
  visitTypeName(TypeName node) {
    node.name.accept(this);
    node.typeArguments?.accept(this);

    node.type = _nextType();
  }

  @override
  visitTypeParameterList(TypeParameterList node) {
    for (var typeParameter in node.typeParameters) {
      var element = TypeParameterElementImpl.forLinkedNode(
        _enclosingElements.last,
        typeParameter,
      );
      _localElements.add(element);
    }

    for (var node in node.typeParameters) {
      var nodeImpl = node as TypeParameterImpl;
      var element = node.declaredElement as TypeParameterElementImpl;

      var summaryData = nodeImpl.summaryData as SummaryDataForTypeParameter;
      element.setCodeRange(summaryData.codeOffset, summaryData.codeLength);

      node.bound?.accept(this);
      element.bound = node.bound?.type;

      node.metadata.accept(this);
      element.metadata = _buildAnnotations(
        _unitContext.element,
        node.metadata,
      );

      element.variance = _decodeVariance(_resolution.readByte());
      element.defaultType = _nextType();

      // TODO(scheglov) We used to do this with the previous elements impl.
      // We probably still do this.
      // But the code below is bad and incomplete.
      // And why does this affect MethodMember(s)?
      {
        var parent = node.parent;
        if (parent is ClassDeclaration) {
          (parent.declaredElement as ElementImpl).encloseElement(element);
        } else if (parent is ClassTypeAlias) {
          (parent.declaredElement as ElementImpl).encloseElement(element);
        } else if (parent is ExtensionDeclaration) {
          (parent.declaredElement as ElementImpl).encloseElement(element);
        } else if (parent is FunctionExpression) {
          var parent2 = parent.parent;
          if (parent2 is FunctionDeclaration) {
            (parent2.declaredElement as ElementImpl).encloseElement(element);
          }
        } else if (parent is FunctionTypeAlias) {
          (parent.declaredElement as ElementImpl).encloseElement(element);
        } else if (parent is GenericTypeAlias) {
          (parent.declaredElement as ElementImpl).encloseElement(element);
        } else if (parent is MethodDeclaration) {
          (parent.declaredElement as ElementImpl).encloseElement(element);
        } else if (parent is MixinDeclaration) {
          (parent.declaredElement as ElementImpl).encloseElement(element);
        }
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var element = node.declaredElement as VariableElementImpl;
    element.type = _nextType();
    _setTopLevelInferenceError(element);
    if (element is FieldElementImpl) {
      element.inheritsCovariant = _resolution.readByte() != 0;
    }

    node.initializer?.accept(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    node.type?.accept(this);
    node.variables.accept(this);
    node.metadata?.accept(this);
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.accept(this);
  }

  void _annotatedNode(AnnotatedNode node) {
    node.metadata?.accept(this);
  }

  void _assertNoLocalElements() {
    assert(_localElements.isEmpty);
    assert(_enclosingElements.length == 1 &&
        _enclosingElements.first is CompilationUnitElement);
  }

  /// Return annotations for the given [nodeList] in the [unit].
  List<ElementAnnotation> _buildAnnotations(
      CompilationUnitElementImpl unit, List<Annotation> nodeList) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotation>[];
    }

    var annotations = List<ElementAnnotation>.filled(length, null);
    for (int i = 0; i < length; i++) {
      var ast = nodeList[i];
      annotations[i] = ElementAnnotationImpl(unit)
        ..annotationAst = ast
        ..element = ast.element;
    }
    return annotations;
  }

  void _compilationUnitMember(CompilationUnitMember node) {
    _declaration(node);
  }

  void _declaration(Declaration node) {
    _annotatedNode(node);
  }

  void _directive(Directive node) {
    node.metadata?.accept(this);
  }

  void _expression(Expression node) {
    node.staticType = _nextType();
  }

  void _forEachParts(ForEachParts node) {
    _forLoopParts(node);
    node.iterable.accept(this);
  }

  void _forLoopParts(ForLoopParts node) {}

  void _formalParameter(FormalParameter node) {
    (node.declaredElement as ParameterElementImpl).type = _nextType();
  }

  void _forParts(ForParts node) {
    node.condition?.accept(this);
    node.updaters.accept(this);
    _forLoopParts(node);
  }

  void _invocationExpression(InvocationExpression node) {
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
    _expression(node);
    // TODO(scheglov) typeArgumentTypes and staticInvokeType?
    var nodeImpl = node as InvocationExpressionImpl;
    nodeImpl.typeArgumentTypes = [];
  }

  void _namedCompilationUnitMember(NamedCompilationUnitMember node) {
    _compilationUnitMember(node);
  }

  void _namespaceDirective(NamespaceDirective node) {
    node.combinators?.accept(this);
    node.configurations?.accept(this);
    _uriBasedDirective(node);
  }

  Element _nextElement() {
    return _resolution.nextElement();
  }

  DartType _nextType() {
    return _resolution.nextType();
  }

  void _normalFormalParameter(
    NormalFormalParameter node,
    ParameterElementImpl element,
  ) {
    if (node.parent is! DefaultFormalParameter) {
      var nodeImpl = node as NormalFormalParameterImpl;
      var summaryData = nodeImpl.summaryData as SummaryDataForFormalParameter;
      element.setCodeRange(summaryData.codeOffset, summaryData.codeLength);
    }

    node.metadata?.accept(this);
    _formalParameter(node);
  }

  /// TODO(scheglov) also enclosing elements
  void _pushEnclosingClassTypeParameters(ClassMember node) {
    var parent = node.parent;
    if (parent is ClassOrMixinDeclaration) {
      var classElement = parent.declaredElement;
      _localElements.addAll(classElement.typeParameters);
    } else {
      var extension = parent as ExtensionDeclaration;
      var classElement = extension.declaredElement;
      _localElements.addAll(classElement.typeParameters);
    }
  }

  TopLevelInferenceError _readTopLevelInferenceError() {
    var kindIndex = _resolution.readByte();
    var kind = TopLevelInferenceErrorKind.values[kindIndex];
    if (kind == TopLevelInferenceErrorKind.none) {
      return null;
    }
    return TopLevelInferenceError(
      kind: kind,
      arguments: _resolution.readStringList(),
    );
  }

  void _resolveNamedExpressions(
    Element executable,
    ArgumentList argumentList,
  ) {
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        var nameNode = argument.name.label;
        if (executable is ExecutableElement) {
          var parameters = executable.parameters;
          var name = nameNode.name;
          nameNode.staticElement = parameters.firstWhere((e) {
            return e.name == name;
          }, orElse: () => null);
        }
      }
    }
  }

  void _setTopLevelInferenceError(ElementImpl element) {
    if (element is MethodElementImpl) {
      element.typeInferenceError = _readTopLevelInferenceError();
    } else if (element is PropertyInducingElementImpl) {
      element.typeInferenceError = _readTopLevelInferenceError();
    }
  }

  void _uriBasedDirective(UriBasedDirective node) {
    _directive(node);
    node.uri.accept(this);
  }

  static Variance _decodeVariance(int encoding) {
    if (encoding == 0) {
      return null;
    } else if (encoding == 1) {
      return Variance.unrelated;
    } else if (encoding == 2) {
      return Variance.covariant;
    } else if (encoding == 3) {
      return Variance.contravariant;
    } else if (encoding == 4) {
      return Variance.invariant;
    } else {
      throw UnimplementedError('encoding: $encoding');
    }
  }
}
