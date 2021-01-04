// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
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
    _expectMarker(MarkerTag.Annotation_name);
    node.name.accept(this);
    _expectMarker(MarkerTag.Annotation_constructorName);
    node.constructorName?.accept(this);
    _expectMarker(MarkerTag.Annotation_arguments);
    node.arguments?.accept(this);
    _expectMarker(MarkerTag.Annotation_element);
    node.element = _nextElement();
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _expectMarker(MarkerTag.ArgumentList_arguments);
    node.arguments.accept(this);
    _expectMarker(MarkerTag.ArgumentList_end);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _expectMarker(MarkerTag.AsExpression_expression);
    node.expression.accept(this);
    _expectMarker(MarkerTag.AsExpression_type);
    node.type.accept(this);
    _expectMarker(MarkerTag.AsExpression_expression2);
    _expression(node);
    _expectMarker(MarkerTag.AsExpression_end);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _expectMarker(MarkerTag.AssertInitializer_condition);
    node.condition.accept(this);
    _expectMarker(MarkerTag.AssertInitializer_message);
    node.message?.accept(this);
    _expectMarker(MarkerTag.AssertInitializer_end);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var nodeImpl = node as AssignmentExpressionImpl;
    _expectMarker(MarkerTag.AssignmentExpression_leftHandSide);
    node.leftHandSide.accept(this);
    _expectMarker(MarkerTag.AssignmentExpression_rightHandSide);
    node.rightHandSide.accept(this);
    _expectMarker(MarkerTag.AssignmentExpression_staticElement);
    node.staticElement = _nextElement();
    _expectMarker(MarkerTag.AssignmentExpression_readElement);
    nodeImpl.readElement = _nextElement();
    _expectMarker(MarkerTag.AssignmentExpression_readType);
    nodeImpl.readType = _nextType();
    _expectMarker(MarkerTag.AssignmentExpression_writeElement);
    nodeImpl.writeElement = _nextElement();
    _expectMarker(MarkerTag.AssignmentExpression_writeType);
    nodeImpl.writeType = _nextType();
    _expectMarker(MarkerTag.AssignmentExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.AssignmentExpression_end);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _expectMarker(MarkerTag.BinaryExpression_leftOperand);
    node.leftOperand.accept(this);
    _expectMarker(MarkerTag.BinaryExpression_rightOperand);
    node.rightOperand.accept(this);

    _expectMarker(MarkerTag.BinaryExpression_staticElement);
    node.staticElement = _nextElement();

    _expectMarker(MarkerTag.BinaryExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.BinaryExpression_end);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _expression(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _expectMarker(MarkerTag.CascadeExpression_target);
    node.target.accept(this);
    _expectMarker(MarkerTag.CascadeExpression_cascadeSections);
    node.cascadeSections.accept(this);
    _expectMarker(MarkerTag.CascadeExpression_end);
    node.staticType = node.target.staticType;
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    _assertNoLocalElements();

    var element = node.declaredElement as ClassElementImpl;
    element.isSimplyBounded = _resolution.readByte() != 0;
    _enclosingElements.add(element);

    try {
      _expectMarker(MarkerTag.ClassDeclaration_typeParameters);
      node.typeParameters?.accept(this);
      _expectMarker(MarkerTag.ClassDeclaration_extendsClause);
      node.extendsClause?.accept(this);
      _expectMarker(MarkerTag.ClassDeclaration_withClause);
      node.withClause?.accept(this);
      _expectMarker(MarkerTag.ClassDeclaration_implementsClause);
      node.implementsClause?.accept(this);
      _expectMarker(MarkerTag.ClassDeclaration_nativeClause);
      node.nativeClause?.accept(this);
      _expectMarker(MarkerTag.ClassDeclaration_namedCompilationUnitMember);
      _namedCompilationUnitMember(node);
      _expectMarker(MarkerTag.ClassDeclaration_end);
    } catch (e, stackTrace) {
      // TODO(scheglov) Remove after fixing http://dartbug.com/44449
      var headerStr = _astCodeBeforeMarkerOrMaxLength(node, '{', 1000);
      throw CaughtExceptionWithFiles(e, stackTrace, {
        'state': '''
element: ${element.reference}
header: $headerStr
resolution.bytes.length: ${_resolution.bytes.length}
resolution.byteOffset: ${_resolution.byteOffset}
''',
      });
    }

    _enclosingElements.removeLast();
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _assertNoLocalElements();
    var element = node.declaredElement as ClassElementImpl;
    _enclosingElements.add(element);

    element.isSimplyBounded = _resolution.readByte() != 0;
    _expectMarker(MarkerTag.ClassTypeAlias_typeParameters);
    node.typeParameters?.accept(this);
    _expectMarker(MarkerTag.ClassTypeAlias_superclass);
    node.superclass?.accept(this);
    _expectMarker(MarkerTag.ClassTypeAlias_withClause);
    node.withClause?.accept(this);
    _expectMarker(MarkerTag.ClassTypeAlias_implementsClause);
    node.implementsClause?.accept(this);
    _expectMarker(MarkerTag.ClassTypeAlias_typeAlias);
    _typeAlias(node);
    _expectMarker(MarkerTag.ClassTypeAlias_end);

    _enclosingElements.removeLast();
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _expectMarker(MarkerTag.ConditionalExpression_condition);
    node.condition.accept(this);
    _expectMarker(MarkerTag.ConditionalExpression_thenExpression);
    node.thenExpression.accept(this);
    _expectMarker(MarkerTag.ConditionalExpression_elseExpression);
    node.elseExpression.accept(this);
    _expression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    _expectMarker(MarkerTag.Configuration_name);
    node.name?.accept(this);
    _expectMarker(MarkerTag.Configuration_value);
    node.value?.accept(this);
    _expectMarker(MarkerTag.Configuration_uri);
    node.uri?.accept(this);
    _expectMarker(MarkerTag.Configuration_end);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _assertNoLocalElements();
    _pushEnclosingClassTypeParameters(node);

    var element = node.declaredElement as ConstructorElementImpl;
    _enclosingElements.add(element.enclosingElement);
    _enclosingElements.add(element);

    _expectMarker(MarkerTag.ConstructorDeclaration_returnType);
    node.returnType?.accept(this);
    _expectMarker(MarkerTag.ConstructorDeclaration_parameters);
    node.parameters?.accept(this);

    for (var parameter in node.parameters.parameters) {
      _localElements.add(parameter.declaredElement);
    }

    _expectMarker(MarkerTag.ConstructorDeclaration_initializers);
    node.initializers?.accept(this);
    _expectMarker(MarkerTag.ConstructorDeclaration_redirectedConstructor);
    node.redirectedConstructor?.accept(this);
    _expectMarker(MarkerTag.ConstructorDeclaration_classMember);
    _classMember(node);
    _expectMarker(MarkerTag.ConstructorDeclaration_end);

    _enclosingElements.removeLast();
    _enclosingElements.removeLast();
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _expectMarker(MarkerTag.ConstructorFieldInitializer_fieldName);
    node.fieldName.accept(this);
    _expectMarker(MarkerTag.ConstructorFieldInitializer_expression);
    node.expression.accept(this);
    _expectMarker(MarkerTag.ConstructorFieldInitializer_end);
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

    _expectMarker(MarkerTag.ConstructorName_type);
    node.type.accept(this);
    _expectMarker(MarkerTag.ConstructorName_name);
    node.name?.accept(this);
    _expectMarker(MarkerTag.ConstructorName_staticElement);
    node.staticElement = _nextElement();
    _expectMarker(MarkerTag.ConstructorName_end);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _expectMarker(MarkerTag.DeclaredIdentifier_type);
    node.type?.accept(this);
    _expectMarker(MarkerTag.DeclaredIdentifier_identifier);
    // node.identifier.accept(this);
    _expectMarker(MarkerTag.DeclaredIdentifier_declaration);
    _declaration(node);
    _expectMarker(MarkerTag.DeclaredIdentifier_end);
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

    _expectMarker(MarkerTag.DefaultFormalParameter_parameter);
    node.parameter.accept(this);
    _expectMarker(MarkerTag.DefaultFormalParameter_defaultValue);
    node.defaultValue?.accept(this);
    _expectMarker(MarkerTag.DefaultFormalParameter_end);
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
    _expectMarker(MarkerTag.EnumConstantDeclaration_name);
    _expectMarker(MarkerTag.EnumConstantDeclaration_declaration);
    _declaration(node);
    _expectMarker(MarkerTag.EnumConstantDeclaration_end);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _expectMarker(MarkerTag.EnumDeclaration_constants);
    node.constants.accept(this);
    _expectMarker(MarkerTag.EnumDeclaration_namedCompilationUnitMember);
    _namedCompilationUnitMember(node);
    _expectMarker(MarkerTag.EnumDeclaration_end);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _expectMarker(MarkerTag.ExportDirective_namespaceDirective);
    _namespaceDirective(node);
    _expectMarker(MarkerTag.ExportDirective_exportedLibrary);
    (node.element as ExportElementImpl).exportedLibrary = _nextElement();
    _expectMarker(MarkerTag.ExportDirective_end);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.expression.accept(this);
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    _expectMarker(MarkerTag.ExtendsClause_superclass);
    node.superclass.accept(this);
    _expectMarker(MarkerTag.ExtendsClause_end);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _assertNoLocalElements();

    var element = node.declaredElement as ExtensionElementImpl;
    _enclosingElements.add(element);

    _expectMarker(MarkerTag.ExtensionDeclaration_typeParameters);
    node.typeParameters?.accept(this);
    _expectMarker(MarkerTag.ExtensionDeclaration_extendedType);
    node.extendedType?.accept(this);
    _expectMarker(MarkerTag.ExtensionDeclaration_compilationUnitMember);
    _compilationUnitMember(node);
    _expectMarker(MarkerTag.ExtensionDeclaration_end);

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

    _expectMarker(MarkerTag.ExtensionOverride_extensionName);
    node.extensionName.accept(this);
    _expectMarker(MarkerTag.ExtensionOverride_typeArguments);
    node.typeArguments?.accept(this);
    _expectMarker(MarkerTag.ExtensionOverride_argumentList);
    node.argumentList.accept(this);
    _expectMarker(MarkerTag.ExtensionOverride_extendedType);
    (node as ExtensionOverrideImpl).extendedType = _nextType();
    _expectMarker(MarkerTag.ExtensionOverride_end);
    // TODO(scheglov) typeArgumentTypes?
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _assertNoLocalElements();
    _pushEnclosingClassTypeParameters(node);

    _expectMarker(MarkerTag.FieldDeclaration_fields);
    node.fields.accept(this);
    _expectMarker(MarkerTag.FieldDeclaration_classMember);
    _classMember(node);
    _expectMarker(MarkerTag.FieldDeclaration_end);
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

    _expectMarker(MarkerTag.FieldFormalParameter_typeParameters);
    node.typeParameters?.accept(this);
    _expectMarker(MarkerTag.FieldFormalParameter_type);
    node.type?.accept(this);
    _expectMarker(MarkerTag.FieldFormalParameter_parameters);
    node.parameters?.accept(this);
    _expectMarker(MarkerTag.FieldFormalParameter_normalFormalParameter);
    _normalFormalParameter(node, element);
    _expectMarker(MarkerTag.FieldFormalParameter_end);

    _localElements.length = localElementsLength;
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _expectMarker(MarkerTag.ForEachPartsWithDeclaration_loopVariable);
    node.loopVariable.accept(this);
    _expectMarker(MarkerTag.ForEachPartsWithDeclaration_forEachParts);
    _forEachParts(node);
    _expectMarker(MarkerTag.ForEachPartsWithDeclaration_end);
  }

  @override
  void visitForElement(ForElement node) {
    _expectMarker(MarkerTag.ForElement_body);
    node.body.accept(this);
    _expectMarker(MarkerTag.ForElement_forMixin);
    _forMixin(node as ForElementImpl);
    _expectMarker(MarkerTag.ForElement_end);
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    _expectMarker(MarkerTag.FormalParameterList_parameters);
    node.parameters.accept(this);
    _expectMarker(MarkerTag.FormalParameterList_end);
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
    _expectMarker(MarkerTag.ForPartsWithDeclarations_variables);
    node.variables.accept(this);
    _expectMarker(MarkerTag.ForPartsWithDeclarations_forParts);
    _forParts(node);
    _expectMarker(MarkerTag.ForPartsWithDeclarations_end);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _assertNoLocalElements();

    var element = node.declaredElement as ExecutableElementImpl;
    assert(element != null);

    _enclosingElements.add(element);

    _expectMarker(MarkerTag.FunctionDeclaration_functionExpression);
    node.functionExpression.accept(this);
    _expectMarker(MarkerTag.FunctionDeclaration_returnType);
    node.returnType?.accept(this);

    _expectMarker(MarkerTag.FunctionDeclaration_namedCompilationUnitMember);
    _namedCompilationUnitMember(node);
    _expectMarker(MarkerTag.FunctionDeclaration_returnTypeType);
    element.returnType = _nextType();
    _expectMarker(MarkerTag.FunctionDeclaration_end);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _expectMarker(MarkerTag.FunctionExpression_typeParameters);
    node.typeParameters?.accept(this);
    _expectMarker(MarkerTag.FunctionExpression_parameters);
    node.parameters?.accept(this);
    _expectMarker(MarkerTag.FunctionExpression_end);
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

    _expectMarker(MarkerTag.FunctionExpressionInvocation_function);
    node.function.accept(this);
    _expectMarker(MarkerTag.FunctionExpressionInvocation_invocationExpression);
    _invocationExpression(node);
    _expectMarker(MarkerTag.FunctionExpressionInvocation_end);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _assertNoLocalElements();

    var element = node.declaredElement as FunctionTypeAliasElementImpl;
    _enclosingElements.add(element);

    _expectMarker(MarkerTag.FunctionTypeAlias_typeParameters);
    node.typeParameters?.accept(this);

    _enclosingElements.add(element.function);
    _expectMarker(MarkerTag.FunctionTypeAlias_returnType);
    node.returnType?.accept(this);
    _expectMarker(MarkerTag.FunctionTypeAlias_parameters);
    node.parameters?.accept(this);
    _enclosingElements.removeLast();

    _expectMarker(MarkerTag.FunctionTypeAlias_typeAlias);
    _typeAlias(node);

    _expectMarker(MarkerTag.FunctionTypeAlias_returnTypeType);
    element.function.returnType = _nextType();
    _expectMarker(MarkerTag.FunctionTypeAlias_flags);
    element.isSimplyBounded = _resolution.readByte() != 0;
    element.hasSelfReference = _resolution.readByte() != 0;
    _expectMarker(MarkerTag.FunctionTypeAlias_end);

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

    _expectMarker(MarkerTag.FunctionTypedFormalParameter_typeParameters);
    node.typeParameters?.accept(this);
    _expectMarker(MarkerTag.FunctionTypedFormalParameter_returnType);
    node.returnType?.accept(this);
    _expectMarker(MarkerTag.FunctionTypedFormalParameter_parameters);
    node.parameters?.accept(this);
    _expectMarker(MarkerTag.FunctionTypedFormalParameter_normalFormalParameter);
    _normalFormalParameter(node, element);
    _expectMarker(MarkerTag.FunctionTypedFormalParameter_end);

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

    _expectMarker(MarkerTag.GenericFunctionType_typeParameters);
    node.typeParameters?.accept(this);
    _expectMarker(MarkerTag.GenericFunctionType_returnType);
    node.returnType?.accept(this);
    _expectMarker(MarkerTag.GenericFunctionType_parameters);
    node.parameters?.accept(this);
    _expectMarker(MarkerTag.GenericFunctionType_type);
    nodeImpl.type = _nextType();
    _expectMarker(MarkerTag.GenericFunctionType_end);

    _localElements.length = localElementsLength;
    _enclosingElements.removeLast();
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _assertNoLocalElements();

    var element = node.declaredElement as TypeAliasElementImpl;
    assert(element != null);

    _enclosingElements.add(element);

    _expectMarker(MarkerTag.GenericTypeAlias_typeParameters);
    node.typeParameters?.accept(this);
    _expectMarker(MarkerTag.GenericTypeAlias_type);
    node.type?.accept(this);
    _expectMarker(MarkerTag.GenericTypeAlias_typeAlias);
    _typeAlias(node);
    _expectMarker(MarkerTag.GenericTypeAlias_flags);
    element.isSimplyBounded = _resolution.readByte() != 0;
    element.hasSelfReference = _resolution.readByte() != 0;
    _expectMarker(MarkerTag.GenericTypeAlias_end);

    _enclosingElements.removeLast();
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    node.hiddenNames.accept(this);
  }

  @override
  void visitIfElement(IfElement node) {
    _expectMarker(MarkerTag.IfElement_condition);
    node.condition.accept(this);
    _expectMarker(MarkerTag.IfElement_thenElement);
    node.thenElement.accept(this);
    _expectMarker(MarkerTag.IfElement_elseElement);
    node.elseElement?.accept(this);
    _expectMarker(MarkerTag.IfElement_end);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    _expectMarker(MarkerTag.ImplementsClause_interfaces);
    node.interfaces.accept(this);
    _expectMarker(MarkerTag.ImplementsClause_end);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _expectMarker(MarkerTag.ImportDirective_namespaceDirective);
    _namespaceDirective(node);

    var element = node.element as ImportElementImpl;
    _expectMarker(MarkerTag.ImportDirective_importedLibrary);
    element.importedLibrary = _nextElement();

    _expectMarker(MarkerTag.ImportDirective_end);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _expectMarker(MarkerTag.IndexExpression_target);
    node.target?.accept(this);
    _expectMarker(MarkerTag.IndexExpression_index);
    node.index.accept(this);
    _expectMarker(MarkerTag.IndexExpression_staticElement);
    node.staticElement = _nextElement();
    _expectMarker(MarkerTag.IndexExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.IndexExpression_end);
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

    _expectMarker(MarkerTag.InstanceCreationExpression_constructorName);
    node.constructorName.accept(this);
    _expectMarker(MarkerTag.InstanceCreationExpression_argumentList);
    node.argumentList.accept(this);
    _expectMarker(MarkerTag.InstanceCreationExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.InstanceCreationExpression_end);
    _resolveNamedExpressions(
      node.constructorName.staticElement,
      node.argumentList,
    );
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _expression(node);
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
    _expectMarker(MarkerTag.IsExpression_expression);
    node.expression.accept(this);
    _expectMarker(MarkerTag.IsExpression_type);
    node.type.accept(this);
    _expectMarker(MarkerTag.IsExpression_expression2);
    _expression(node);
    _expectMarker(MarkerTag.IsExpression_end);
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
    _expectMarker(MarkerTag.ListLiteral_typeArguments);
    node.typeArguments?.accept(this);
    _expectMarker(MarkerTag.ListLiteral_elements);
    node.elements.accept(this);
    _expectMarker(MarkerTag.ListLiteral_expression);
    _expression(node);
    _expectMarker(MarkerTag.ListLiteral_end);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _expectMarker(MarkerTag.MapLiteralEntry_key);
    node.key.accept(this);
    _expectMarker(MarkerTag.MapLiteralEntry_value);
    node.value.accept(this);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    _assertNoLocalElements();
    _pushEnclosingClassTypeParameters(node);

    var element = node.declaredElement as ExecutableElementImpl;
    _enclosingElements.add(element.enclosingElement);
    _enclosingElements.add(element);

    try {
      _expectMarker(MarkerTag.MethodDeclaration_typeParameters);
      node.typeParameters?.accept(this);
      _expectMarker(MarkerTag.MethodDeclaration_returnType);
      node.returnType?.accept(this);
      _expectMarker(MarkerTag.MethodDeclaration_parameters);
      node.parameters?.accept(this);
      _expectMarker(MarkerTag.MethodDeclaration_classMember);
      _classMember(node);

      _expectMarker(MarkerTag.MethodDeclaration_returnTypeType);
      element.returnType = _nextType();
      _expectMarker(MarkerTag.MethodDeclaration_inferenceError);
      _setTopLevelInferenceError(element);
      if (element is MethodElementImpl) {
        _expectMarker(MarkerTag.MethodDeclaration_flags);
        element.isOperatorEqualWithParameterTypeFromObject =
            _resolution.readByte() != 0;
      }
      _expectMarker(MarkerTag.MethodDeclaration_end);
    } catch (e, stackTrace) {
      // TODO(scheglov) Remove after fixing http://dartbug.com/44449
      var headerStr = _astCodeBeforeMarkerOrMaxLength(node, '{', 1000);
      throw CaughtExceptionWithFiles(e, stackTrace, {
        'state': '''
element: ${element.reference}
header: $headerStr
resolution.bytes.length: ${_resolution.bytes.length}
resolution.byteOffset: ${_resolution.byteOffset}
''',
      });
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

    _expectMarker(MarkerTag.MethodInvocation_target);
    node.target?.accept(this);
    _expectMarker(MarkerTag.MethodInvocation_methodName);
    node.methodName.accept(this);
    _expectMarker(MarkerTag.MethodInvocation_invocationExpression);
    _invocationExpression(node);
    _expectMarker(MarkerTag.MethodInvocation_end);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _assertNoLocalElements();
    var element = node.declaredElement as MixinElementImpl;
    element.isSimplyBounded = _resolution.readByte() != 0;
    element.superInvokedNames = _resolution.readStringList();
    _enclosingElements.add(element);

    _expectMarker(MarkerTag.MixinDeclaration_typeParameters);
    node.typeParameters?.accept(this);
    _expectMarker(MarkerTag.MixinDeclaration_onClause);
    node.onClause?.accept(this);
    _expectMarker(MarkerTag.MixinDeclaration_implementsClause);
    node.implementsClause?.accept(this);
    _expectMarker(MarkerTag.MixinDeclaration_namedCompilationUnitMember);
    _namedCompilationUnitMember(node);
    _expectMarker(MarkerTag.MixinDeclaration_end);

    _enclosingElements.removeLast();
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _expectMarker(MarkerTag.NamedExpression_expression);
    node.expression.accept(this);
    _expectMarker(MarkerTag.NamedExpression_end);
  }

  @override
  void visitNativeClause(NativeClause node) {
    _expectMarker(MarkerTag.NativeClause_name);
    node.name.accept(this);
    _expectMarker(MarkerTag.NativeClause_end);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    // TODO(scheglov) type?
  }

  @override
  void visitOnClause(OnClause node) {
    _expectMarker(MarkerTag.OnClause_superclassConstraints);
    node.superclassConstraints.accept(this);
    _expectMarker(MarkerTag.OnClause_end);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _expectMarker(MarkerTag.ParenthesizedExpression_expression);
    node.expression.accept(this);
    _expectMarker(MarkerTag.ParenthesizedExpression_expression2);
    _expression(node);
    _expectMarker(MarkerTag.ParenthesizedExpression_end);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _uriBasedDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _expectMarker(MarkerTag.PartOfDirective_libraryName);
    node.libraryName?.accept(this);
    _expectMarker(MarkerTag.PartOfDirective_uri);
    node.uri?.accept(this);
    _expectMarker(MarkerTag.PartOfDirective_directive);
    _directive(node);
    _expectMarker(MarkerTag.PartOfDirective_end);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    var nodeImpl = node as PostfixExpressionImpl;
    _expectMarker(MarkerTag.PostfixExpression_operand);
    node.operand.accept(this);
    _expectMarker(MarkerTag.PostfixExpression_staticElement);
    node.staticElement = _nextElement();
    if (node.operator.type.isIncrementOperator) {
      _expectMarker(MarkerTag.PostfixExpression_readElement);
      nodeImpl.readElement = _nextElement();
      _expectMarker(MarkerTag.PostfixExpression_readType);
      nodeImpl.readType = _nextType();
      _expectMarker(MarkerTag.PostfixExpression_writeElement);
      nodeImpl.writeElement = _nextElement();
      _expectMarker(MarkerTag.PostfixExpression_writeType);
      nodeImpl.writeType = _nextType();
    }
    _expectMarker(MarkerTag.PostfixExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.PostfixExpression_end);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _expectMarker(MarkerTag.PrefixedIdentifier_prefix);
    node.prefix.accept(this);
    _expectMarker(MarkerTag.PrefixedIdentifier_identifier);
    node.identifier.accept(this);
    _expectMarker(MarkerTag.PrefixedIdentifier_expression);
    _expression(node);
    _expectMarker(MarkerTag.PrefixedIdentifier_end);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var nodeImpl = node as PrefixExpressionImpl;
    _expectMarker(MarkerTag.PrefixExpression_operand);
    node.operand.accept(this);
    _expectMarker(MarkerTag.PrefixExpression_staticElement);
    node.staticElement = _nextElement();
    if (node.operator.type.isIncrementOperator) {
      _expectMarker(MarkerTag.PrefixExpression_readElement);
      nodeImpl.readElement = _nextElement();
      _expectMarker(MarkerTag.PrefixExpression_readType);
      nodeImpl.readType = _nextType();
      _expectMarker(MarkerTag.PrefixExpression_writeElement);
      nodeImpl.writeElement = _nextElement();
      _expectMarker(MarkerTag.PrefixExpression_writeType);
      nodeImpl.writeType = _nextType();
    }
    _expectMarker(MarkerTag.PrefixExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.PrefixExpression_end);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _expectMarker(MarkerTag.PropertyAccess_target);
    node.target?.accept(this);
    _expectMarker(MarkerTag.PropertyAccess_propertyName);
    node.propertyName.accept(this);

    _expectMarker(MarkerTag.PropertyAccess_expression);
    _expression(node);
    _expectMarker(MarkerTag.PropertyAccess_end);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _expectMarker(MarkerTag.RedirectingConstructorInvocation_constructorName);
    node.constructorName?.accept(this);
    _expectMarker(MarkerTag.RedirectingConstructorInvocation_argumentList);
    node.argumentList.accept(this);
    _expectMarker(MarkerTag.RedirectingConstructorInvocation_staticElement);
    node.staticElement = _nextElement();
    _resolveNamedExpressions(node.staticElement, node.argumentList);
    _expectMarker(MarkerTag.RedirectingConstructorInvocation_end);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _expectMarker(MarkerTag.SetOrMapLiteral_flags);
    var mapOrSetBits = _resolution.readByte();
    if ((mapOrSetBits & 0x01) != 0) {
      (node as SetOrMapLiteralImpl).becomeMap();
    } else if ((mapOrSetBits & 0x02) != 0) {
      (node as SetOrMapLiteralImpl).becomeSet();
    }

    _expectMarker(MarkerTag.SetOrMapLiteral_typeArguments);
    node.typeArguments?.accept(this);
    _expectMarker(MarkerTag.SetOrMapLiteral_elements);
    node.elements.accept(this);
    _expectMarker(MarkerTag.SetOrMapLiteral_expression);
    _expression(node);
    _expectMarker(MarkerTag.SetOrMapLiteral_end);
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

    _expectMarker(MarkerTag.SimpleFormalParameter_type);
    node.type?.accept(this);
    _expectMarker(MarkerTag.SimpleFormalParameter_normalFormalParameter);
    _normalFormalParameter(node, element);

    _expectMarker(MarkerTag.SimpleFormalParameter_flags);
    element.inheritsCovariant = _resolution.readByte() != 0;
    _expectMarker(MarkerTag.SimpleFormalParameter_end);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    _expectMarker(MarkerTag.SimpleIdentifier_staticElement);
    node.staticElement = _nextElement();
    _expectMarker(MarkerTag.SimpleIdentifier_expression);
    _expression(node);
    _expectMarker(MarkerTag.SimpleIdentifier_end);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // TODO(scheglov) type?
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _expectMarker(MarkerTag.SpreadElement_expression);
    node.expression.accept(this);
    _expectMarker(MarkerTag.SpreadElement_end);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _expectMarker(MarkerTag.StringInterpolation_elements);
    node.elements.accept(this);
    _expectMarker(MarkerTag.StringInterpolation_end);
    // TODO(scheglov) type?
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _expectMarker(MarkerTag.SuperConstructorInvocation_constructorName);
    node.constructorName?.accept(this);
    _expectMarker(MarkerTag.SuperConstructorInvocation_argumentList);
    node.argumentList.accept(this);
    _expectMarker(MarkerTag.SuperConstructorInvocation_staticElement);
    node.staticElement = _nextElement();
    _resolveNamedExpressions(node.staticElement, node.argumentList);
    _expectMarker(MarkerTag.SuperConstructorInvocation_end);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _expectMarker(MarkerTag.SuperExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.SuperExpression_end);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _expression(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _expectMarker(MarkerTag.ThisExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.ThisExpression_end);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _expectMarker(MarkerTag.ThrowExpression_expression);
    node.expression.accept(this);
    _expectMarker(MarkerTag.ThrowExpression_expression2);
    _expression(node);
    _expectMarker(MarkerTag.ThrowExpression_end);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _expectMarker(MarkerTag.TopLevelVariableDeclaration_variables);
    node.variables.accept(this);
    _expectMarker(MarkerTag.TopLevelVariableDeclaration_compilationUnitMember);
    _compilationUnitMember(node);
    _expectMarker(MarkerTag.TopLevelVariableDeclaration_end);
  }

  @override
  visitTypeArgumentList(TypeArgumentList node) {
    _expectMarker(MarkerTag.TypeArgumentList_arguments);
    node.arguments?.accept(this);
    _expectMarker(MarkerTag.TypeArgumentList_end);
  }

  @override
  visitTypeName(TypeName node) {
    _expectMarker(MarkerTag.TypeName_name);
    node.name.accept(this);
    _expectMarker(MarkerTag.TypeName_typeArguments);
    node.typeArguments?.accept(this);

    _expectMarker(MarkerTag.TypeName_type);
    node.type = _nextType();

    _expectMarker(MarkerTag.TypeName_end);
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

    _expectMarker(MarkerTag.TypeParameterList_typeParameters);
    for (var node in node.typeParameters) {
      var nodeImpl = node as TypeParameterImpl;
      var element = node.declaredElement as TypeParameterElementImpl;

      var summaryData = nodeImpl.summaryData as SummaryDataForTypeParameter;
      element.setCodeRange(summaryData.codeOffset, summaryData.codeLength);

      _expectMarker(MarkerTag.TypeParameter_bound);
      node.bound?.accept(this);
      element.bound = node.bound?.type;

      _expectMarker(MarkerTag.TypeParameter_declaration);
      _declaration(node);
      element.metadata = _buildAnnotations(
        _unitContext.element,
        node.metadata,
      );

      _expectMarker(MarkerTag.TypeParameter_variance);
      element.variance = _decodeVariance(_resolution.readByte());
      _expectMarker(MarkerTag.TypeParameter_defaultType);
      element.defaultType = _nextType();
      _expectMarker(MarkerTag.TypeParameter_end);

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
    _expectMarker(MarkerTag.TypeParameterList_end);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var element = node.declaredElement as VariableElementImpl;
    _expectMarker(MarkerTag.VariableDeclaration_type);
    element.type = _nextType();
    _expectMarker(MarkerTag.VariableDeclaration_inferenceError);
    _setTopLevelInferenceError(element);
    if (element is FieldElementImpl) {
      _expectMarker(MarkerTag.VariableDeclaration_inheritsCovariant);
      element.inheritsCovariant = _resolution.readByte() != 0;
    }

    _expectMarker(MarkerTag.VariableDeclaration_initializer);
    node.initializer?.accept(this);
    _expectMarker(MarkerTag.VariableDeclaration_end);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _expectMarker(MarkerTag.VariableDeclarationList_type);
    node.type?.accept(this);
    _expectMarker(MarkerTag.VariableDeclarationList_variables);
    node.variables.accept(this);
    _expectMarker(MarkerTag.VariableDeclarationList_annotatedNode);
    _annotatedNode(node);
    _expectMarker(MarkerTag.VariableDeclarationList_end);
  }

  @override
  void visitWithClause(WithClause node) {
    _expectMarker(MarkerTag.WithClause_mixinTypes);
    node.mixinTypes.accept(this);
    _expectMarker(MarkerTag.WithClause_end);
  }

  void _annotatedNode(AnnotatedNode node) {
    _expectMarker(MarkerTag.AnnotatedNode_metadata);
    node.metadata?.accept(this);
    _expectMarker(MarkerTag.AnnotatedNode_end);
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

  void _classMember(ClassMember node) {
    _expectMarker(MarkerTag.ClassMember_declaration);
    _declaration(node);
  }

  void _compilationUnitMember(CompilationUnitMember node) {
    _declaration(node);
  }

  void _declaration(Declaration node) {
    _annotatedNode(node);
  }

  void _directive(Directive node) {
    _annotatedNode(node);
  }

  void _expectMarker(MarkerTag tag) {
    if (enableDebugResolutionMarkers) {
      var actualIndex = _resolution.readUInt30();
      if (actualIndex != tag.index) {
        if (actualIndex < MarkerTag.values.length) {
          var actualTag = MarkerTag.values[actualIndex];
          throw StateError('Expected $tag, found $actualIndex = $actualTag');
        } else {
          throw StateError('Expected $tag, found $actualIndex');
        }
      }
    }
  }

  void _expression(Expression node) {
    _expectMarker(MarkerTag.Expression_staticType);
    node.staticType = _nextType();
  }

  void _forEachParts(ForEachParts node) {
    _expectMarker(MarkerTag.ForEachParts_iterable);
    node.iterable.accept(this);
    _expectMarker(MarkerTag.ForEachParts_forLoopParts);
    _forLoopParts(node);
    _expectMarker(MarkerTag.ForEachParts_end);
  }

  void _forLoopParts(ForLoopParts node) {}

  void _formalParameter(FormalParameter node) {
    _expectMarker(MarkerTag.FormalParameter_type);
    (node.declaredElement as ParameterElementImpl).type = _nextType();
  }

  void _forMixin(ForMixin node) {
    _expectMarker(MarkerTag.ForMixin_forLoopParts);
    node.forLoopParts.accept(this);
  }

  void _forParts(ForParts node) {
    _expectMarker(MarkerTag.ForParts_condition);
    node.condition?.accept(this);
    _expectMarker(MarkerTag.ForParts_updaters);
    node.updaters.accept(this);
    _expectMarker(MarkerTag.ForParts_forLoopParts);
    _forLoopParts(node);
    _expectMarker(MarkerTag.ForParts_end);
  }

  void _invocationExpression(InvocationExpression node) {
    _expectMarker(MarkerTag.InvocationExpression_typeArguments);
    node.typeArguments?.accept(this);
    _expectMarker(MarkerTag.InvocationExpression_argumentList);
    node.argumentList.accept(this);
    _expectMarker(MarkerTag.InvocationExpression_expression);
    _expression(node);
    _expectMarker(MarkerTag.InvocationExpression_end);
    // TODO(scheglov) typeArgumentTypes and staticInvokeType?
    var nodeImpl = node as InvocationExpressionImpl;
    nodeImpl.typeArgumentTypes = [];
  }

  void _namedCompilationUnitMember(NamedCompilationUnitMember node) {
    _compilationUnitMember(node);
  }

  void _namespaceDirective(NamespaceDirective node) {
    _expectMarker(MarkerTag.NamespaceDirective_combinators);
    node.combinators?.accept(this);
    _expectMarker(MarkerTag.NamespaceDirective_configurations);
    node.configurations?.accept(this);
    _expectMarker(MarkerTag.NamespaceDirective_uriBasedDirective);
    _uriBasedDirective(node);
    _expectMarker(MarkerTag.NamespaceDirective_end);
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

    _expectMarker(MarkerTag.NormalFormalParameter_metadata);
    node.metadata?.accept(this);
    _expectMarker(MarkerTag.NormalFormalParameter_formalParameter);
    _formalParameter(node);
    _expectMarker(MarkerTag.NormalFormalParameter_end);
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

  void _typeAlias(TypeAlias node) {
    _namedCompilationUnitMember(node);
  }

  void _uriBasedDirective(UriBasedDirective node) {
    _expectMarker(MarkerTag.UriBasedDirective_uri);
    node.uri.accept(this);
    _expectMarker(MarkerTag.UriBasedDirective_directive);
    _directive(node);
    _expectMarker(MarkerTag.UriBasedDirective_end);
  }

  /// TODO(scheglov) Remove after fixing http://dartbug.com/44449
  static String _astCodeBeforeMarkerOrMaxLength(
      AstNode node, String marker, int maxLength) {
    var nodeStr = '$node';
    var indexOfBody = nodeStr.indexOf(marker);
    if (indexOfBody == -1) {
      indexOfBody = min(maxLength, nodeStr.length);
    }
    return nodeStr.substring(0, indexOfBody);
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
