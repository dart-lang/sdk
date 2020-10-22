// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';

class ApplyResolutionVisitor extends ThrowingAstVisitor<void> {
  final LinkedUnitContext _unitContext;
  final LinkedNodeResolution _resolution;

  int _elementPtr = 0;
  int _typePtr = 0;

  ApplyResolutionVisitor(this._unitContext, this._resolution);

  void addParentTypeParameters(AstNode node) {
    var enclosing = node.parent;
    if (enclosing is ClassOrMixinDeclaration) {
      var typeParameterList = enclosing.typeParameters;
      if (typeParameterList == null) return;

      for (var typeParameter in typeParameterList.typeParameters) {
        var element = typeParameter.declaredElement;
        _unitContext.typeParameterStack.add(element);
      }
    } else if (enclosing is ExtensionDeclaration) {
      // TODO
      var typeParameterList = enclosing.typeParameters;
      if (typeParameterList == null) return;

      for (var typeParameter in typeParameterList.typeParameters) {
        var element = typeParameter.declaredElement;
        _unitContext.typeParameterStack.add(element);
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
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    node.condition.accept(this);
    node.message?.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);
    _expression(node);
    node.staticElement = _nextElement();
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);
    node.rightOperand.accept(this);

    node.staticType = _nextType();
    node.staticElement = _nextElement();
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    node.staticType = _nextType();
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    node.target.accept(this);
    node.cascadeSections.accept(this);
    _expression(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.nativeClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    _namedCompilationUnitMember(node);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.superclass?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    node.metadata?.accept(this);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
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
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    node.initializers?.accept(this);
    node.redirectedConstructor?.accept(this);
    node.metadata?.accept(this);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.fieldName.accept(this);
    node.expression.accept(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.type.accept(this);
    node.name?.accept(this);

    node.staticElement = _nextElement();
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.type?.accept(this);
    node.identifier.accept(this);
    _declaration(node);
  }

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
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
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.extendedType?.accept(this);
    node.metadata?.accept(this);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    node.extensionName.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
    (node as ExtensionOverrideImpl).extendedType = _nextType();
    // TODO(scheglov) typeArgumentTypes?
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    node.fields.accept(this);
    node.metadata?.accept(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.type?.accept(this);
    node.parameters?.accept(this);

    _normalFormalParameter(node);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
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
    node.variables.accept(this);
    _forParts(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    var node2 = node.functionExpression;
    node2.typeParameters?.accept(this);
    node2.parameters?.accept(this);
    node2.body?.accept(this);

    node.returnType?.accept(this);
    node.metadata?.accept(this);
    _setActualReturnType(node);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    node.body?.accept(this);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function.accept(this);
    _invocationExpression(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    node.metadata?.accept(this);
    _setActualReturnType(node);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    _normalFormalParameter(node);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    (node as GenericFunctionTypeImpl).type = _nextType();
    _setActualReturnType(node);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.functionType?.accept(this);
    node.metadata?.accept(this);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitHideCombinator(HideCombinator node) {}

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
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);
    node.index.accept(this);
    node.staticElement = _nextElement();
    _expression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.constructorName.accept(this);
    (node as InstanceCreationExpressionImpl).typeArguments?.accept(this);
    node.argumentList.accept(this);
    node.staticType = _nextType();
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
  }

  @override
  void visitLabel(Label node) {
    node.label.accept(this);
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
    node.elements.accept(this);
    node.staticType = _nextType();
    node.typeArguments?.accept(this);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    node.key.accept(this);
    node.value.accept(this);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.returnType?.accept(this);
    node.parameters?.accept(this);
    node.metadata?.accept(this);
    _setActualReturnType(node);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    node.methodName.accept(this);
    _invocationExpression(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var typeParameterStackHeight = _unitContext.typeParameterStack.length;

    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
    node.metadata?.accept(this);

    _unitContext.typeParameterStack.length = typeParameterStackHeight;
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.name.accept(this);
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
  void visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    node.staticElement = _nextElement();
    _expression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    node.identifier.accept(this);

    node.staticType = _nextType();
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    node.operand.accept(this);
    node.staticElement = _nextElement();
    _expression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target.accept(this);
    node.propertyName.accept(this);

    node.staticType = _nextType();
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    node.constructorName?.accept(this);
    node.argumentList.accept(this);
    node.staticElement = _nextElement();
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    node.elements.accept(this);
    node.staticType = _nextType();
    node.typeArguments?.accept(this);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {}

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.type?.accept(this);
    _normalFormalParameter(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    var data = LazyAst.getData(node);

    node.staticElement = _nextElement();

    if (AstBinaryFlags.hasType(data.flags)) {
      node.staticType = _nextType();
    }
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
    // print('[node: $node][type: ${node.type}]');
  }

  @override
  visitTypeParameterList(TypeParameterList node) {
    for (var typeParameter in node.typeParameters) {
      var name = typeParameter.name;
      var element = TypeParameterElementImpl(name.name, name.offset);
      name.staticElement = element;
      _unitContext.typeParameterStack.add(element);
    }

    for (var typeParameter in node.typeParameters) {
      var element = typeParameter.declaredElement as TypeParameterElementImpl;
      element.variance = LazyAst.getVariance(typeParameter);

      typeParameter.bound?.accept(this);
      element.bound = typeParameter.bound?.type;

      element.defaultType = _nextType();

      typeParameter.metadata?.accept(this);
      element.metadata = _buildAnnotations2(
        _unitContext.reference.element,
        typeParameter.metadata,
      );

      {
        var lazy = LazyTypeParameter.get(typeParameter);
        var informative = _unitContext.getInformativeData(lazy.data);
        element.setCodeRange(
          informative?.codeOffset ?? 0,
          informative?.codeLength ?? 0,
        );
      }

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
    node.initializer?.accept(this);
    _setActualType(node);
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

  /// Return annotations for the given [nodeList] in the [unit].
  List<ElementAnnotation> _buildAnnotations2(
      CompilationUnitElementImpl unit, List<Annotation> nodeList) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotation>[];
    }

    var annotations = List<ElementAnnotation>(length);
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
    _setActualType(node);
  }

  void _forParts(ForParts node) {
    _forLoopParts(node);
    node.condition?.accept(this);
    node.updaters.accept(this);
  }

  void _invocationExpression(InvocationExpression node) {
    _expression(node);
    node.argumentList.accept(this);
    node.staticInvokeType = _nextType();
    node.typeArguments?.accept(this);
  }

  void _namedCompilationUnitMember(NamedCompilationUnitMember node) {
    _compilationUnitMember(node);
  }

  void _namespaceDirective(NamespaceDirective node) {
    _uriBasedDirective(node);
    node.combinators?.accept(this);
    node.configurations?.accept(this);
  }

  Element _nextElement() {
    var ptr = _elementPtr++;
    var elementIndex = _resolution.elements[ptr];
    var element = _unitContext.elementOfIndex(elementIndex);

    var substitutionNode = _resolution.substitutions[ptr];
    if (substitutionNode.typeArguments.isNotEmpty) {
      var typeParameters =
          (element.enclosingElement as TypeParameterizedElement).typeParameters;
      var typeArguments = substitutionNode.typeArguments
          .map(_unitContext.readType)
          .toList(growable: false);
      var substitution = Substitution.fromPairs(typeParameters, typeArguments);
      element = ExecutableMember.from2(element, substitution);
    }

    if (substitutionNode.isLegacy) {
      element = Member.legacy(element);
    }

    return element;
  }

  DartType _nextType() {
    var id = _typePtr++;
    var data = _resolution.types[id];
    var type = _unitContext.readType(data);
    return type;
  }

  void _normalFormalParameter(NormalFormalParameter node) {
    _formalParameter(node);
    node.metadata?.accept(this);
  }

  void _setActualReturnType(AstNode node) {
    var type = _nextType();
    LazyAst.setReturnType(node, type);
  }

  void _setActualType(AstNode node) {
    var type = _nextType();
    LazyAst.setType(node, type);
  }

  void _uriBasedDirective(UriBasedDirective node) {
    _directive(node);
    node.uri.accept(this);
  }
}
