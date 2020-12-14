// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/bundle_writer.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:meta/meta.dart';

/// Serializer of fully resolved ASTs.
class AstBinaryWriter extends ThrowingAstVisitor<void> {
  final bool _withInformative;
  final BufferedSink _sink;
  final StringIndexer _stringIndexer;
  final int Function() _getNextResolutionIndex;
  final ResolutionSink _resolutionSink;
  final bool _shouldWriteResolution;

  /// TODO(scheglov) Keep it private, and write here, similarly as we do
  /// for [_classMemberIndexItems]?
  final List<_UnitMemberIndexItem> unitMemberIndexItems = [];
  final List<_ClassMemberIndexItem> _classMemberIndexItems = [];
  bool _shouldStoreVariableInitializers = false;
  bool _hasConstConstructor = false;
  int _nextUnnamedExtensionId = 0;

  AstBinaryWriter({
    @required bool withInformative,
    @required BufferedSink sink,
    @required StringIndexer stringIndexer,
    @required int Function() getNextResolutionIndex,
    @required ResolutionSink resolutionSink,
  })  : _withInformative = withInformative,
        _sink = sink,
        _stringIndexer = stringIndexer,
        _getNextResolutionIndex = getNextResolutionIndex,
        _resolutionSink = resolutionSink,
        _shouldWriteResolution = resolutionSink != null;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _writeByte(Tag.AdjacentStrings);
    _writeNodeList(node.strings);
  }

  @override
  void visitAnnotation(Annotation node) {
    _writeByte(Tag.Annotation);

    _writeMarker(MarkerTag.Annotation_name);
    _writeOptionalNode(node.name);
    _writeMarker(MarkerTag.Annotation_constructorName);
    _writeOptionalNode(node.constructorName);

    _writeMarker(MarkerTag.Annotation_arguments);
    var arguments = node.arguments;
    if (arguments != null) {
      if (!arguments.arguments.every(_isSerializableExpression)) {
        arguments = null;
      }
    }
    _writeOptionalNode(arguments);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.Annotation_element);
      _resolutionSink.writeElement(node.element);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _writeByte(Tag.ArgumentList);
    _writeMarker(MarkerTag.ArgumentList_arguments);
    _writeNodeList(node.arguments);
    _writeMarker(MarkerTag.ArgumentList_end);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _writeByte(Tag.AsExpression);

    _writeMarker(MarkerTag.AsExpression_expression);
    _writeNode(node.expression);

    _writeMarker(MarkerTag.AsExpression_type);
    _writeNode(node.type);

    _writeMarker(MarkerTag.AsExpression_expression2);
    _storeExpression(node);

    _writeMarker(MarkerTag.AsExpression_end);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _writeByte(Tag.AssertInitializer);
    _writeMarker(MarkerTag.AssertInitializer_condition);
    _writeNode(node.condition);
    _writeMarker(MarkerTag.AssertInitializer_message);
    _writeOptionalNode(node.message);
    _writeMarker(MarkerTag.AssertInitializer_end);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _writeByte(Tag.AssignmentExpression);

    _writeMarker(MarkerTag.AssignmentExpression_leftHandSide);
    _writeNode(node.leftHandSide);
    _writeMarker(MarkerTag.AssignmentExpression_rightHandSide);
    _writeNode(node.rightHandSide);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.AssignmentExpression_staticElement);
      _resolutionSink.writeElement(node.staticElement);
      _writeMarker(MarkerTag.AssignmentExpression_readElement);
      _resolutionSink.writeElement(node.readElement);
      _writeMarker(MarkerTag.AssignmentExpression_readType);
      _resolutionSink.writeType(node.readType);
      _writeMarker(MarkerTag.AssignmentExpression_writeElement);
      _resolutionSink.writeElement(node.writeElement);
      _writeMarker(MarkerTag.AssignmentExpression_writeType);
      _resolutionSink.writeType(node.writeType);
    }
    _writeMarker(MarkerTag.AssignmentExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.AssignmentExpression_end);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _writeByte(Tag.BinaryExpression);

    _writeMarker(MarkerTag.BinaryExpression_leftOperand);
    _writeNode(node.leftOperand);
    _writeMarker(MarkerTag.BinaryExpression_rightOperand);
    _writeNode(node.rightOperand);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.BinaryExpression_staticElement);
      _resolutionSink.writeElement(node.staticElement);
    }
    _writeMarker(MarkerTag.BinaryExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.BinaryExpression_end);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _writeByte(Tag.BooleanLiteral);
    _writeByte(node.value ? 1 : 0);
    if (_shouldWriteResolution) {
      _storeExpression(node);
    }
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _writeByte(Tag.CascadeExpression);
    _writeMarker(MarkerTag.CascadeExpression_target);
    _writeNode(node.target);
    _writeMarker(MarkerTag.CascadeExpression_cascadeSections);
    _writeNodeList(node.cascadeSections);
    _writeMarker(MarkerTag.CascadeExpression_end);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var classOffset = _sink.offset;
    var resolutionIndex = _getNextResolutionIndex();

    _hasConstConstructor = false;
    for (var member in node.members) {
      if (member is ConstructorDeclaration && member.constKeyword != null) {
        _hasConstConstructor = true;
        break;
      }
    }

    _writeByte(Tag.Class);
    _writeByte(
      AstBinaryFlags.encode(
        hasConstConstructor: _hasConstConstructor,
        isAbstract: node.abstractKeyword != null,
      ),
    );
    if (_shouldWriteResolution) {
      _resolutionSink.writeByte(node.declaredElement.isSimplyBounded ? 1 : 0);
    }

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    _pushScopeTypeParameters(node.typeParameters);

    _writeMarker(MarkerTag.ClassDeclaration_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.ClassDeclaration_extendsClause);
    _writeOptionalNode(node.extendsClause);
    _writeMarker(MarkerTag.ClassDeclaration_withClause);
    _writeOptionalNode(node.withClause);
    _writeMarker(MarkerTag.ClassDeclaration_implementsClause);
    _writeOptionalNode(node.implementsClause);
    _writeMarker(MarkerTag.ClassDeclaration_nativeClause);
    _writeOptionalNode(node.nativeClause);
    _writeMarker(MarkerTag.ClassDeclaration_namedCompilationUnitMember);
    _storeNamedCompilationUnitMember(node);
    _writeMarker(MarkerTag.ClassDeclaration_end);
    _writeUInt30(resolutionIndex);

    _classMemberIndexItems.clear();
    _writeNodeList(node.members);
    _hasConstConstructor = false;

    if (_shouldWriteResolution) {
      _resolutionSink.localElements.popScope();
    }

    // TODO(scheglov) write member index
    var classIndexOffset = _sink.offset;
    _writeClassMemberIndex();

    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: classOffset,
        tag: Tag.Class,
        name: node.name.name,
        classIndexOffset: classIndexOffset,
      ),
    );
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: _sink.offset,
        tag: Tag.ClassTypeAlias,
        name: node.name.name,
      ),
    );

    var resolutionIndex = _getNextResolutionIndex();

    _writeByte(Tag.ClassTypeAlias);
    _writeByte(
      AstBinaryFlags.encode(
        isAbstract: node.abstractKeyword != null,
      ),
    );
    if (_shouldWriteResolution) {
      _resolutionSink.writeByte(node.declaredElement.isSimplyBounded ? 1 : 0);
    }
    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _pushScopeTypeParameters(node.typeParameters);
    _writeMarker(MarkerTag.ClassTypeAlias_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.ClassTypeAlias_superclass);
    _writeNode(node.superclass);
    _writeMarker(MarkerTag.ClassTypeAlias_withClause);
    _writeNode(node.withClause);
    _writeMarker(MarkerTag.ClassTypeAlias_implementsClause);
    _writeOptionalNode(node.implementsClause);
    _writeMarker(MarkerTag.ClassTypeAlias_typeAlias);
    _storeTypeAlias(node);
    _writeMarker(MarkerTag.ClassTypeAlias_end);
    _writeDocumentationCommentString(node.documentationComment);
    _writeUInt30(resolutionIndex);
    if (_shouldWriteResolution) {
      _resolutionSink.localElements.popScope();
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var nodeImpl = node as CompilationUnitImpl;
    _writeLanguageVersion(nodeImpl.languageVersion);
    _writeFeatureSet(node.featureSet);
    _writeLineInfo(node.lineInfo);
    _writeUInt30(_withInformative ? node.length : 0);
    _writeNodeList(node.directives);
    for (var declaration in node.declarations) {
      declaration.accept(this);
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _writeByte(Tag.ConditionalExpression);
    _writeMarker(MarkerTag.ConditionalExpression_condition);
    _writeNode(node.condition);
    _writeMarker(MarkerTag.ConditionalExpression_thenExpression);
    _writeNode(node.thenExpression);
    _writeMarker(MarkerTag.ConditionalExpression_elseExpression);
    _writeNode(node.elseExpression);
    _storeExpression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    _writeByte(Tag.Configuration);

    _writeByte(
      AstBinaryFlags.encode(
        hasEqual: node.equalToken != null,
      ),
    );

    _writeMarker(MarkerTag.Configuration_name);
    _writeNode(node.name);
    _writeMarker(MarkerTag.Configuration_value);
    _writeOptionalNode(node.value);
    _writeMarker(MarkerTag.Configuration_uri);
    _writeNode(node.uri);
    _writeMarker(MarkerTag.Configuration_end);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _classMemberIndexItems.add(
      _ClassMemberIndexItem(
        offset: _sink.offset,
        tag: Tag.ConstructorDeclaration,
        name: node.name?.name ?? '',
      ),
    );

    _writeByte(Tag.ConstructorDeclaration);

    _writeByte(
      AstBinaryFlags.encode(
        hasName: node.name != null,
        hasSeparatorColon: node.separator?.type == TokenType.COLON,
        hasSeparatorEquals: node.separator?.type == TokenType.EQ,
        isAbstract: node.body is EmptyFunctionBody,
        isConst: node.constKeyword != null,
        isExternal: node.externalKeyword != null,
        isFactory: node.factoryKeyword != null,
      ),
    );

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    var resolutionIndex = _getNextResolutionIndex();
    _writeMarker(MarkerTag.ConstructorDeclaration_returnType);
    _writeNode(node.returnType);
    if (node.period != null) {
      _writeInformativeUint30(node.period.offset);
      _writeDeclarationName(node.name);
    }
    _writeMarker(MarkerTag.ConstructorDeclaration_parameters);
    _writeNode(node.parameters);

    if (_shouldWriteResolution) {
      _resolutionSink.localElements.pushScope();
      for (var parameter in node.parameters.parameters) {
        _resolutionSink.localElements.declare(parameter.declaredElement);
      }
    }

    // TODO(scheglov) Not nice, we skip both resolution and AST.
    // But eventually we want to store full AST, and partial resolution.
    _writeMarker(MarkerTag.ConstructorDeclaration_initializers);
    if (node.constKeyword != null) {
      _writeNodeList(node.initializers);
    } else {
      _writeNodeList(const <ConstructorInitializer>[]);
    }

    if (_shouldWriteResolution) {
      _resolutionSink.localElements.popScope();
    }

    _writeMarker(MarkerTag.ConstructorDeclaration_redirectedConstructor);
    _writeOptionalNode(node.redirectedConstructor);
    _writeMarker(MarkerTag.ConstructorDeclaration_classMember);
    _storeClassMember(node);
    _writeMarker(MarkerTag.ConstructorDeclaration_end);
    _writeUInt30(resolutionIndex);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _writeByte(Tag.ConstructorFieldInitializer);

    _writeByte(
      AstBinaryFlags.encode(
        hasThis: node.thisKeyword != null,
      ),
    );

    _writeMarker(MarkerTag.ConstructorFieldInitializer_fieldName);
    _writeNode(node.fieldName);
    _writeMarker(MarkerTag.ConstructorFieldInitializer_expression);
    _writeNode(node.expression);
    _writeMarker(MarkerTag.ConstructorFieldInitializer_end);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _writeByte(Tag.ConstructorName);

    if (_shouldWriteResolution) {
      // When we parse `C() = A.named` we don't know that `A` is a class name.
      // We parse it as a `TypeName(PrefixedIdentifier)`.
      // But when we resolve, we rewrite it.
      // We need to inform the applier about the right shape of the AST.
      _resolutionSink.writeByte(node.name != null ? 1 : 0);
    }

    _writeMarker(MarkerTag.ConstructorName_type);
    _writeNode(node.type);
    _writeMarker(MarkerTag.ConstructorName_name);
    _writeOptionalNode(node.name);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.ConstructorName_staticElement);
      _resolutionSink.writeElement(node.staticElement);
    }

    _writeMarker(MarkerTag.ConstructorName_end);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _writeByte(Tag.DeclaredIdentifier);
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.keyword?.keyword == Keyword.CONST,
        isFinal: node.keyword?.keyword == Keyword.FINAL,
        isVar: node.keyword?.keyword == Keyword.VAR,
      ),
    );
    _writeMarker(MarkerTag.DeclaredIdentifier_type);
    _writeOptionalNode(node.type);
    _writeMarker(MarkerTag.DeclaredIdentifier_identifier);
    _writeDeclarationName(node.identifier);
    _writeMarker(MarkerTag.DeclaredIdentifier_declaration);
    _storeDeclaration(node);
    _writeMarker(MarkerTag.DeclaredIdentifier_end);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _writeByte(Tag.DefaultFormalParameter);

    _writeByte(
      AstBinaryFlags.encode(
        hasInitializer: node.defaultValue != null,
        isPositional: node.isPositional,
        isRequired: node.isRequired,
      ),
    );

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);

    _writeMarker(MarkerTag.DefaultFormalParameter_parameter);
    _writeNode(node.parameter);

    var defaultValue = node.defaultValue;
    if (!_isSerializableExpression(defaultValue)) {
      defaultValue = null;
    }
    _writeMarker(MarkerTag.DefaultFormalParameter_defaultValue);
    _writeOptionalNode(defaultValue);
    _writeMarker(MarkerTag.DefaultFormalParameter_end);
  }

  @override
  void visitDottedName(DottedName node) {
    _writeByte(Tag.DottedName);
    _writeNodeList(node.components);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _writeByte(Tag.DoubleLiteral);
    _writeDouble(node.value);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _writeByte(Tag.EnumConstantDeclaration);

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    _writeMarker(MarkerTag.EnumConstantDeclaration_name);
    _writeDeclarationName(node.name);
    _writeMarker(MarkerTag.EnumConstantDeclaration_declaration);
    _storeDeclaration(node);
    _writeMarker(MarkerTag.EnumConstantDeclaration_end);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    var resolutionIndex = _getNextResolutionIndex();
    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: _sink.offset,
        tag: Tag.EnumDeclaration,
        name: node.name.name,
      ),
    );

    _writeByte(Tag.EnumDeclaration);

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    _writeMarker(MarkerTag.EnumDeclaration_constants);
    _writeNodeList(node.constants);
    _writeMarker(MarkerTag.EnumDeclaration_namedCompilationUnitMember);
    _storeNamedCompilationUnitMember(node);
    _writeMarker(MarkerTag.EnumDeclaration_end);
    _writeUInt30(resolutionIndex);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var resolutionIndex = _getNextResolutionIndex();

    _writeByte(Tag.ExportDirective);
    _writeMarker(MarkerTag.ExportDirective_namespaceDirective);
    _storeNamespaceDirective(node);
    _writeUInt30(resolutionIndex);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.ExportDirective_exportedLibrary);
      _resolutionSink.writeElement(
        (node.element as ExportElementImpl).exportedLibrary,
      );
    }

    _writeMarker(MarkerTag.ExportDirective_end);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _writeByte(Tag.ExtendsClause);
    _writeMarker(MarkerTag.ExtendsClause_superclass);
    _writeNode(node.superclass);
    _writeMarker(MarkerTag.ExtendsClause_end);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var classOffset = _sink.offset;
    var resolutionIndex = _getNextResolutionIndex();

    _writeByte(Tag.ExtensionDeclaration);

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    _pushScopeTypeParameters(node.typeParameters);
    _writeMarker(MarkerTag.ExtensionDeclaration_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.ExtensionDeclaration_extendedType);
    _writeNode(node.extendedType);
    _writeOptionalDeclarationName(node.name);
    _writeMarker(MarkerTag.ExtensionDeclaration_compilationUnitMember);
    _storeCompilationUnitMember(node);
    _writeMarker(MarkerTag.ExtensionDeclaration_end);
    _writeUInt30(resolutionIndex);

    _classMemberIndexItems.clear();
    _writeNodeList(node.members);

    if (_shouldWriteResolution) {
      _resolutionSink.localElements.popScope();
    }

    // TODO(scheglov) write member index
    var classIndexOffset = _sink.offset;
    _writeClassMemberIndex();

    var nameIdentifier = node.name;
    var indexName = nameIdentifier != null
        ? nameIdentifier.name
        : 'extension-${_nextUnnamedExtensionId++}';
    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: classOffset,
        tag: Tag.ExtensionDeclaration,
        name: indexName,
        classIndexOffset: classIndexOffset,
      ),
    );
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _writeByte(Tag.ExtensionOverride);

    if (_shouldWriteResolution) {
      _resolutionSink.writeByte(MethodInvocationRewriteTag.extensionOverride);
    }

    _writeMarker(MarkerTag.ExtensionOverride_extensionName);
    _writeNode(node.extensionName);
    _writeMarker(MarkerTag.ExtensionOverride_typeArguments);
    _writeOptionalNode(node.typeArguments);
    _writeMarker(MarkerTag.ExtensionOverride_argumentList);
    _writeNode(node.argumentList);
    _writeMarker(MarkerTag.ExtensionOverride_extendedType);
    _resolutionSink.writeType(node.extendedType);
    _writeMarker(MarkerTag.ExtensionOverride_end);
    // TODO(scheglov) typeArgumentTypes?
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _classMemberIndexItems.add(
      _ClassMemberIndexItem(
        offset: _sink.offset,
        tag: Tag.FieldDeclaration,
        fieldNames: node.fields.variables.map((e) => e.name.name).toList(),
      ),
    );

    _writeByte(Tag.FieldDeclaration);
    _writeByte(
      AstBinaryFlags.encode(
        isAbstract: node.abstractKeyword != null,
        isCovariant: node.covariantKeyword != null,
        isExternal: node.externalKeyword != null,
        isStatic: node.staticKeyword != null,
      ),
    );

    _writeInformativeVariableCodeRanges(node.offset, node.fields);
    _writeDocumentationCommentString(node.documentationComment);

    var resolutionIndex = _getNextResolutionIndex();

    _shouldStoreVariableInitializers = node.fields.isConst ||
        _hasConstConstructor && node.fields.isFinal && !node.isStatic;
    try {
      _writeMarker(MarkerTag.FieldDeclaration_fields);
      _writeNode(node.fields);
    } finally {
      _shouldStoreVariableInitializers = false;
    }

    _writeMarker(MarkerTag.FieldDeclaration_classMember);
    _storeClassMember(node);
    _writeMarker(MarkerTag.FieldDeclaration_end);

    _writeUInt30(resolutionIndex);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _writeByte(Tag.FieldFormalParameter);

    _pushScopeTypeParameters(node.typeParameters);
    _writeMarker(MarkerTag.FieldFormalParameter_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.FieldFormalParameter_type);
    _writeOptionalNode(node.type);
    _writeMarker(MarkerTag.FieldFormalParameter_parameters);
    _writeOptionalNode(node.parameters);
    _writeMarker(MarkerTag.FieldFormalParameter_normalFormalParameter);
    _storeNormalFormalParameter(
      node,
      node.keyword,
      hasQuestion: node.question != null,
    );
    _writeMarker(MarkerTag.FieldFormalParameter_end);

    if (_shouldWriteResolution) {
      _resolutionSink.localElements.popScope();
    }
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _writeByte(Tag.ForEachPartsWithDeclaration);
    _writeMarker(MarkerTag.ForEachPartsWithDeclaration_loopVariable);
    _writeNode(node.loopVariable);
    _writeMarker(MarkerTag.ForEachPartsWithDeclaration_forEachParts);
    _storeForEachParts(node);
    _writeMarker(MarkerTag.ForEachPartsWithDeclaration_end);
  }

  @override
  void visitForElement(ForElement node) {
    _writeByte(Tag.ForElement);
    _writeMarker(MarkerTag.ForElement_body);
    _writeNode(node.body);
    _writeMarker(MarkerTag.ForElement_forMixin);
    _storeForMixin(node as ForElementImpl);
    _writeMarker(MarkerTag.ForElement_end);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _writeByte(Tag.FormalParameterList);

    var leftDelimiter = node.leftDelimiter?.type;
    _writeByte(
      AstBinaryFlags.encode(
        isDelimiterCurly: leftDelimiter == TokenType.OPEN_CURLY_BRACKET,
        isDelimiterSquare: leftDelimiter == TokenType.OPEN_SQUARE_BRACKET,
      ),
    );

    _writeMarker(MarkerTag.FormalParameterList_parameters);
    _writeNodeList(node.parameters);
    _writeMarker(MarkerTag.FormalParameterList_end);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _writeByte(Tag.ForPartsWithDeclarations);
    _writeMarker(MarkerTag.ForPartsWithDeclarations_variables);
    _writeNode(node.variables);
    _writeMarker(MarkerTag.ForPartsWithDeclarations_forParts);
    _storeForParts(node);
    _writeMarker(MarkerTag.ForPartsWithDeclarations_end);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var indexTag = Tag.FunctionDeclaration;
    if (node.isGetter) {
      indexTag = Tag.FunctionDeclaration_getter;
    } else if (node.isSetter) {
      indexTag = Tag.FunctionDeclaration_setter;
    }
    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: _sink.offset,
        tag: indexTag,
        name: node.name.name,
        variableNames: null,
      ),
    );

    _writeByte(Tag.FunctionDeclaration);

    _writeByte(
      AstBinaryFlags.encode(
        isExternal: node.externalKeyword != null,
        isGet: node.isGetter,
        isSet: node.isSetter,
      ),
    );

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    var resolutionIndex = _getNextResolutionIndex();

    _pushScopeTypeParameters(node.functionExpression.typeParameters);

    _writeMarker(MarkerTag.FunctionDeclaration_functionExpression);
    _writeNode(node.functionExpression);
    _writeMarker(MarkerTag.FunctionDeclaration_returnType);
    _writeOptionalNode(node.returnType);
    _writeMarker(MarkerTag.FunctionDeclaration_namedCompilationUnitMember);
    _storeNamedCompilationUnitMember(node);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.FunctionDeclaration_returnTypeType);
      _writeActualReturnType(node.declaredElement.returnType);
      _resolutionSink.localElements.popScope();
    }

    _writeMarker(MarkerTag.FunctionDeclaration_end);

    _writeUInt30(resolutionIndex);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _writeByte(Tag.FunctionExpression);

    var body = node.body;
    _writeByte(
      AstBinaryFlags.encode(
        isAsync: body?.isAsynchronous ?? false,
        isGenerator: body?.isGenerator ?? false,
      ),
    );

    _writeMarker(MarkerTag.FunctionExpression_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.FunctionExpression_parameters);
    _writeOptionalNode(node.parameters);
    _writeMarker(MarkerTag.FunctionExpression_end);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _writeByte(Tag.FunctionExpressionInvocation);

    if (_shouldWriteResolution) {
      _resolutionSink
          .writeByte(MethodInvocationRewriteTag.functionExpressionInvocation);
    }

    _writeMarker(MarkerTag.FunctionExpressionInvocation_function);
    _writeNode(node.function);
    _writeMarker(MarkerTag.FunctionExpressionInvocation_invocationExpression);
    _storeInvocationExpression(node);
    _writeMarker(MarkerTag.FunctionExpressionInvocation_end);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: _sink.offset,
        tag: Tag.FunctionTypeAlias,
        name: node.name.name,
        variableNames: null,
      ),
    );

    _writeByte(Tag.FunctionTypeAlias);

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    var resolutionIndex = _getNextResolutionIndex();

    _pushScopeTypeParameters(node.typeParameters);

    _writeMarker(MarkerTag.FunctionTypeAlias_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.FunctionTypeAlias_returnType);
    _writeOptionalNode(node.returnType);
    _writeMarker(MarkerTag.FunctionTypeAlias_parameters);
    _writeNode(node.parameters);

    _writeMarker(MarkerTag.FunctionTypeAlias_typeAlias);
    _storeTypeAlias(node);

    if (_shouldWriteResolution) {
      var element = node.declaredElement as FunctionTypeAliasElementImpl;
      _writeMarker(MarkerTag.FunctionTypeAlias_returnTypeType);
      _writeActualReturnType(element.function.returnType);
      // TODO(scheglov) pack into one byte
      _writeMarker(MarkerTag.FunctionTypeAlias_flags);
      _resolutionSink.writeByte(element.isSimplyBounded ? 1 : 0);
      _resolutionSink.writeByte(element.hasSelfReference ? 1 : 0);

      _resolutionSink.localElements.popScope();
    }

    _writeMarker(MarkerTag.FunctionTypeAlias_end);

    _writeUInt30(resolutionIndex);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _writeByte(Tag.FunctionTypedFormalParameter);

    _pushScopeTypeParameters(node.typeParameters);
    _writeMarker(MarkerTag.FunctionTypedFormalParameter_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.FunctionTypedFormalParameter_returnType);
    _writeOptionalNode(node.returnType);
    _writeMarker(MarkerTag.FunctionTypedFormalParameter_parameters);
    _writeNode(node.parameters);
    _writeMarker(MarkerTag.FunctionTypedFormalParameter_normalFormalParameter);
    _storeNormalFormalParameter(node, null);
    _writeMarker(MarkerTag.FunctionTypedFormalParameter_end);

    if (_shouldWriteResolution) {
      _resolutionSink.localElements.popScope();
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _writeByte(Tag.GenericFunctionType);

    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion: node.question != null,
      ),
    );

    _pushScopeTypeParameters(node.typeParameters);

    _writeMarker(MarkerTag.GenericFunctionType_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.GenericFunctionType_returnType);
    _writeOptionalNode(node.returnType);
    _writeMarker(MarkerTag.GenericFunctionType_parameters);
    _writeNode(node.parameters);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.GenericFunctionType_type);
      _resolutionSink.writeType(node.type);
      _resolutionSink.localElements.popScope();
    }

    _writeMarker(MarkerTag.GenericFunctionType_end);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: _sink.offset,
        tag: Tag.GenericTypeAlias,
        name: node.name.name,
      ),
    );

    _writeByte(Tag.GenericTypeAlias);

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    var resolutionIndex = _getNextResolutionIndex();

    _pushScopeTypeParameters(node.typeParameters);

    _writeMarker(MarkerTag.GenericTypeAlias_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.GenericTypeAlias_type);
    _writeOptionalNode(node.type);
    _writeMarker(MarkerTag.GenericTypeAlias_typeAlias);
    _storeTypeAlias(node);

    if (_shouldWriteResolution) {
      var element = node.declaredElement as TypeAliasElementImpl;
      // TODO(scheglov) pack into one byte
      _writeMarker(MarkerTag.GenericTypeAlias_flags);
      _resolutionSink.writeByte(element.isSimplyBounded ? 1 : 0);
      _resolutionSink.writeByte(element.hasSelfReference ? 1 : 0);
      _resolutionSink.localElements.popScope();
    }

    _writeMarker(MarkerTag.GenericTypeAlias_end);

    _writeUInt30(resolutionIndex);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _writeByte(Tag.HideCombinator);
    _writeInformativeUint30(node.keyword.offset);
    _writeNodeList(node.hiddenNames);
  }

  @override
  void visitIfElement(IfElement node) {
    _writeByte(Tag.IfElement);
    _writeMarker(MarkerTag.IfElement_condition);
    _writeNode(node.condition);
    _writeMarker(MarkerTag.IfElement_thenElement);
    _writeNode(node.thenElement);
    _writeMarker(MarkerTag.IfElement_elseElement);
    _writeOptionalNode(node.elseElement);
    _writeMarker(MarkerTag.IfElement_end);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _writeByte(Tag.ImplementsClause);
    _writeMarker(MarkerTag.ImplementsClause_interfaces);
    _writeNodeList(node.interfaces);
    _writeMarker(MarkerTag.ImplementsClause_end);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var resolutionIndex = _getNextResolutionIndex();

    _writeByte(Tag.ImportDirective);

    var prefix = node.prefix;
    _writeByte(
      AstBinaryFlags.encode(
        hasPrefix: prefix != null,
        isDeferred: node.deferredKeyword != null,
      ),
    );

    if (prefix != null) {
      _writeStringReference(prefix.name);
      _writeInformativeUint30(prefix.offset);
    }

    _writeMarker(MarkerTag.ImportDirective_namespaceDirective);
    _storeNamespaceDirective(node);
    _writeUInt30(resolutionIndex);

    if (_shouldWriteResolution) {
      var element = node.element as ImportElementImpl;
      _writeMarker(MarkerTag.ImportDirective_importedLibrary);
      _resolutionSink.writeElement(element.importedLibrary);
    }

    _writeMarker(MarkerTag.ImportDirective_end);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _writeByte(Tag.IndexExpression);
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod: node.period != null,
        hasQuestion: node.question != null,
      ),
    );
    _writeMarker(MarkerTag.IndexExpression_target);
    _writeOptionalNode(node.target);
    _writeMarker(MarkerTag.IndexExpression_index);
    _writeNode(node.index);
    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.IndexExpression_staticElement);
      _resolutionSink.writeElement(node.staticElement);
    }
    _writeMarker(MarkerTag.IndexExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.IndexExpression_end);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _writeByte(Tag.InstanceCreationExpression);

    if (_shouldWriteResolution) {
      if (node.constructorName.name != null) {
        _resolutionSink.writeByte(
          MethodInvocationRewriteTag.instanceCreationExpression_withName,
        );
      } else {
        _resolutionSink.writeByte(
          MethodInvocationRewriteTag.instanceCreationExpression_withoutName,
        );
      }
    }

    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.keyword?.type == Keyword.CONST,
        isNew: node.keyword?.type == Keyword.NEW,
      ),
    );

    _writeMarker(MarkerTag.InstanceCreationExpression_constructorName);
    _writeNode(node.constructorName);
    _writeMarker(MarkerTag.InstanceCreationExpression_argumentList);
    _writeNode(node.argumentList);
    _writeMarker(MarkerTag.InstanceCreationExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.InstanceCreationExpression_end);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    var value = node.value;

    if (value == null) {
      _writeByte(Tag.IntegerLiteralNull);
      _writeStringReference(node.literal.lexeme);
    } else {
      var isPositive = value >= 0;
      if (!isPositive) {
        value = -value;
      }

      if (value & 0xFF == value) {
        _writeByte(
          isPositive
              ? Tag.IntegerLiteralPositive1
              : Tag.IntegerLiteralNegative1,
        );
        _writeByte(value);
      } else {
        _writeByte(
          isPositive ? Tag.IntegerLiteralPositive : Tag.IntegerLiteralNegative,
        );
        _writeUInt32(value >> 32);
        _writeUInt32(value & 0xFFFFFFFF);
      }
    }

    // TODO(scheglov) Dont write type, AKA separate true `int` and `double`?
    _storeExpression(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _writeByte(Tag.InterpolationExpression);
    _writeByte(
      AstBinaryFlags.encode(
        isStringInterpolationIdentifier:
            node.leftBracket.type == TokenType.STRING_INTERPOLATION_IDENTIFIER,
      ),
    );
    _writeNode(node.expression);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _writeByte(Tag.InterpolationString);
    _writeStringReference(node.value);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _writeByte(Tag.IsExpression);
    _writeByte(
      AstBinaryFlags.encode(
        hasNot: node.notOperator != null,
      ),
    );
    _writeMarker(MarkerTag.IsExpression_expression);
    _writeNode(node.expression);
    _writeMarker(MarkerTag.IsExpression_type);
    _writeNode(node.type);
    _writeMarker(MarkerTag.IsExpression_expression2);
    _storeExpression(node);
    _writeMarker(MarkerTag.IsExpression_end);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _writeByte(Tag.LibraryDirective);
    _writeDocumentationCommentString(node.documentationComment);
    visitLibraryIdentifier(node.name);
    _storeDirective(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _writeByte(Tag.LibraryIdentifier);
    _writeNodeList(node.components);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _writeByte(Tag.ListLiteral);

    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.constKeyword != null,
      ),
    );

    _writeMarker(MarkerTag.ListLiteral_typeArguments);
    _writeOptionalNode(node.typeArguments);
    _writeMarker(MarkerTag.ListLiteral_elements);
    _writeNodeList(node.elements);

    _writeMarker(MarkerTag.ListLiteral_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.ListLiteral_end);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _writeByte(Tag.MapLiteralEntry);
    _writeMarker(MarkerTag.MapLiteralEntry_key);
    _writeNode(node.key);
    _writeMarker(MarkerTag.MapLiteralEntry_value);
    _writeNode(node.value);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var indexTag = Tag.MethodDeclaration;
    if (node.isGetter) {
      indexTag = Tag.MethodDeclaration_getter;
    } else if (node.isSetter) {
      indexTag = Tag.MethodDeclaration_setter;
    }
    _classMemberIndexItems.add(
      _ClassMemberIndexItem(
        offset: _sink.offset,
        tag: indexTag,
        name: node.name.name,
      ),
    );

    _writeByte(Tag.MethodDeclaration);

    _writeUInt30(
      AstBinaryFlags.encode(
        isAbstract: node.body is EmptyFunctionBody,
        isAsync: node.body?.isAsynchronous ?? false,
        isExternal: node.externalKeyword != null,
        isGenerator: node.body?.isGenerator ?? false,
        isGet: node.isGetter,
        isNative: node.body is NativeFunctionBody,
        isOperator: node.operatorKeyword != null,
        isSet: node.isSetter,
        isStatic: node.isStatic,
      ),
    );

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    var resolutionIndex = _getNextResolutionIndex();

    _pushScopeTypeParameters(node.typeParameters);

    _writeDeclarationName(node.name);
    _writeMarker(MarkerTag.MethodDeclaration_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.MethodDeclaration_returnType);
    _writeOptionalNode(node.returnType);
    _writeMarker(MarkerTag.MethodDeclaration_parameters);
    _writeOptionalNode(node.parameters);

    _writeMarker(MarkerTag.MethodDeclaration_classMember);
    _storeClassMember(node);

    _writeUInt30(resolutionIndex);

    if (_shouldWriteResolution) {
      var element = node.declaredElement as ExecutableElementImpl;
      _writeMarker(MarkerTag.MethodDeclaration_returnTypeType);
      _writeActualReturnType(element.returnType);
      _writeMarker(MarkerTag.MethodDeclaration_inferenceError);
      _writeTopLevelInferenceError(element);
      // TODO(scheglov) move this flag into ClassElementImpl?
      if (element is MethodElementImpl) {
        _writeMarker(MarkerTag.MethodDeclaration_flags);
        _resolutionSink.writeByte(
          element.isOperatorEqualWithParameterTypeFromObject ? 1 : 0,
        );
      }
      _resolutionSink.localElements.popScope();
    }

    _writeMarker(MarkerTag.MethodDeclaration_end);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _writeByte(Tag.MethodInvocation);

    if (_shouldWriteResolution) {
      _resolutionSink.writeByte(MethodInvocationRewriteTag.none);
    }

    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod: node.operator?.type == TokenType.PERIOD,
        hasPeriod2: node.operator?.type == TokenType.PERIOD_PERIOD,
      ),
    );
    _writeMarker(MarkerTag.MethodInvocation_target);
    _writeOptionalNode(node.target);
    _writeMarker(MarkerTag.MethodInvocation_methodName);
    _writeNode(node.methodName);
    _writeMarker(MarkerTag.MethodInvocation_invocationExpression);
    _storeInvocationExpression(node);
    _writeMarker(MarkerTag.MethodInvocation_end);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var classOffset = _sink.offset;
    var resolutionIndex = _getNextResolutionIndex();

    _writeByte(Tag.MixinDeclaration);

    if (_shouldWriteResolution) {
      var element = node.declaredElement as MixinElementImpl;
      _resolutionSink.writeByte(element.isSimplyBounded ? 1 : 0);
      _resolutionSink.writeStringList(element.superInvokedNames);
    }

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    _pushScopeTypeParameters(node.typeParameters);

    _writeMarker(MarkerTag.MixinDeclaration_typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeMarker(MarkerTag.MixinDeclaration_onClause);
    _writeOptionalNode(node.onClause);
    _writeMarker(MarkerTag.MixinDeclaration_implementsClause);
    _writeOptionalNode(node.implementsClause);
    _writeMarker(MarkerTag.MixinDeclaration_namedCompilationUnitMember);
    _storeNamedCompilationUnitMember(node);
    _writeMarker(MarkerTag.MixinDeclaration_end);
    _writeUInt30(resolutionIndex);

    _classMemberIndexItems.clear();
    _writeNodeList(node.members);
    _hasConstConstructor = false;

    if (_shouldWriteResolution) {
      _resolutionSink.localElements.popScope();
    }

    // TODO(scheglov) write member index
    var classIndexOffset = _sink.offset;
    _writeClassMemberIndex();

    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: classOffset,
        tag: Tag.MixinDeclaration,
        name: node.name.name,
        classIndexOffset: classIndexOffset,
      ),
    );
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _writeByte(Tag.NamedExpression);

    var nameNode = node.name.label;
    _writeStringReference(nameNode.name);
    _writeInformativeUint30(nameNode.offset);

    _writeMarker(MarkerTag.NamedExpression_expression);
    _writeNode(node.expression);
    _writeMarker(MarkerTag.NamedExpression_end);
  }

  @override
  void visitNativeClause(NativeClause node) {
    _writeByte(Tag.NativeClause);
    _writeMarker(MarkerTag.NativeClause_name);
    _writeNode(node.name);
    _writeMarker(MarkerTag.NativeClause_end);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _writeByte(Tag.NullLiteral);
  }

  @override
  void visitOnClause(OnClause node) {
    _writeByte(Tag.OnClause);
    _writeMarker(MarkerTag.OnClause_superclassConstraints);
    _writeNodeList(node.superclassConstraints);
    _writeMarker(MarkerTag.OnClause_end);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _writeByte(Tag.ParenthesizedExpression);
    _writeMarker(MarkerTag.ParenthesizedExpression_expression);
    _writeNode(node.expression);
    _writeMarker(MarkerTag.ParenthesizedExpression_expression2);
    _storeExpression(node);
    _writeMarker(MarkerTag.ParenthesizedExpression_end);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _writeByte(Tag.PartDirective);
    _storeUriBasedDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _writeByte(Tag.PartOfDirective);
    _writeMarker(MarkerTag.PartOfDirective_libraryName);
    _writeOptionalNode(node.libraryName);
    _writeMarker(MarkerTag.PartOfDirective_uri);
    _writeOptionalNode(node.uri);
    _writeMarker(MarkerTag.PartOfDirective_directive);
    _storeDirective(node);
    _writeMarker(MarkerTag.PartOfDirective_end);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _writeByte(Tag.PostfixExpression);

    _writeMarker(MarkerTag.PostfixExpression_operand);
    _writeNode(node.operand);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.PostfixExpression_staticElement);
      _resolutionSink.writeElement(node.staticElement);
      if (operatorToken.isIncrementOperator) {
        _writeMarker(MarkerTag.PostfixExpression_readElement);
        _resolutionSink.writeElement(node.readElement);
        _writeMarker(MarkerTag.PostfixExpression_readType);
        _resolutionSink.writeType(node.readType);
        _writeMarker(MarkerTag.PostfixExpression_writeElement);
        _resolutionSink.writeElement(node.writeElement);
        _writeMarker(MarkerTag.PostfixExpression_writeType);
        _resolutionSink.writeType(node.writeType);
      }
    }
    _writeMarker(MarkerTag.PostfixExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.PostfixExpression_end);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _writeByte(Tag.PrefixedIdentifier);
    _writeMarker(MarkerTag.PrefixedIdentifier_prefix);
    _writeNode(node.prefix);
    _writeMarker(MarkerTag.PrefixedIdentifier_identifier);
    _writeNode(node.identifier);

    // TODO(scheglov) In actual prefixed identifier, the type of the identifier.
    _writeMarker(MarkerTag.PrefixedIdentifier_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.PrefixedIdentifier_end);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _writeByte(Tag.PrefixExpression);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _writeMarker(MarkerTag.PrefixExpression_operand);
    _writeNode(node.operand);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.PrefixExpression_staticElement);
      _resolutionSink.writeElement(node.staticElement);
      if (operatorToken.isIncrementOperator) {
        _writeMarker(MarkerTag.PrefixExpression_readElement);
        _resolutionSink.writeElement(node.readElement);
        _writeMarker(MarkerTag.PrefixExpression_readType);
        _resolutionSink.writeType(node.readType);
        _writeMarker(MarkerTag.PrefixExpression_writeElement);
        _resolutionSink.writeElement(node.writeElement);
        _writeMarker(MarkerTag.PrefixExpression_writeType);
        _resolutionSink.writeType(node.writeType);
      }
    }

    _writeMarker(MarkerTag.PrefixExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.PrefixExpression_end);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _writeByte(Tag.PropertyAccess);
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod: node.operator?.type == TokenType.PERIOD,
        hasPeriod2: node.operator?.type == TokenType.PERIOD_PERIOD,
      ),
    );
    _writeMarker(MarkerTag.PropertyAccess_target);
    _writeOptionalNode(node.target);
    _writeMarker(MarkerTag.PropertyAccess_propertyName);
    _writeNode(node.propertyName);
    // TODO(scheglov) Get from the property?
    _writeMarker(MarkerTag.PropertyAccess_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.PropertyAccess_end);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _writeByte(Tag.RedirectingConstructorInvocation);

    _writeByte(
      AstBinaryFlags.encode(
        hasThis: node.thisKeyword != null,
      ),
    );

    _writeMarker(MarkerTag.RedirectingConstructorInvocation_constructorName);
    _writeOptionalNode(node.constructorName);
    _writeMarker(MarkerTag.RedirectingConstructorInvocation_argumentList);
    _writeNode(node.argumentList);
    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.RedirectingConstructorInvocation_staticElement);
      _resolutionSink.writeElement(node.staticElement);
    }
    _writeMarker(MarkerTag.RedirectingConstructorInvocation_end);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _writeByte(Tag.SetOrMapLiteral);

    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.constKeyword != null,
      ),
    );

    if (_shouldWriteResolution) {
      var isMapBit = node.isMap ? (1 << 0) : 0;
      var isSetBit = node.isSet ? (1 << 1) : 0;
      _writeMarker(MarkerTag.SetOrMapLiteral_flags);
      _resolutionSink.writeByte(isMapBit | isSetBit);
    }

    _writeMarker(MarkerTag.SetOrMapLiteral_typeArguments);
    _writeOptionalNode(node.typeArguments);
    _writeMarker(MarkerTag.SetOrMapLiteral_elements);
    _writeNodeList(node.elements);

    _writeMarker(MarkerTag.SetOrMapLiteral_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.SetOrMapLiteral_end);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _writeByte(Tag.ShowCombinator);
    _writeInformativeUint30(node.keyword.offset);
    _writeNodeList(node.shownNames);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _writeByte(Tag.SimpleFormalParameter);

    _writeMarker(MarkerTag.SimpleFormalParameter_type);
    _writeOptionalNode(node.type);
    _writeMarker(MarkerTag.SimpleFormalParameter_normalFormalParameter);
    _storeNormalFormalParameter(node, node.keyword);

    if (_shouldWriteResolution) {
      var element = node.declaredElement as ParameterElementImpl;
      _writeMarker(MarkerTag.SimpleFormalParameter_flags);
      _resolutionSink.writeByte(element.inheritsCovariant ? 1 : 0);
    }
    _writeMarker(MarkerTag.SimpleFormalParameter_end);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _writeByte(Tag.SimpleIdentifier);
    _writeStringReference(node.name);
    _writeInformativeUint30(node.offset);
    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.SimpleIdentifier_staticElement);
      _resolutionSink.writeElement(node.staticElement);
      // TODO(scheglov) It is inefficient to write many null types.
    }
    _writeMarker(MarkerTag.SimpleIdentifier_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.SimpleIdentifier_end);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _writeByte(Tag.SimpleStringLiteral);
    _writeStringReference(node.literal.lexeme);
    _writeStringReference(node.value);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _writeByte(Tag.SpreadElement);
    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion:
            node.spreadOperator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION,
      ),
    );
    _writeMarker(MarkerTag.SpreadElement_expression);
    _writeNode(node.expression);
    _writeMarker(MarkerTag.SpreadElement_end);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _writeByte(Tag.StringInterpolation);
    _writeMarker(MarkerTag.StringInterpolation_elements);
    _writeNodeList(node.elements);
    _writeMarker(MarkerTag.StringInterpolation_end);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writeByte(Tag.SuperConstructorInvocation);

    _writeMarker(MarkerTag.SuperConstructorInvocation_constructorName);
    _writeOptionalNode(node.constructorName);
    _writeMarker(MarkerTag.SuperConstructorInvocation_argumentList);
    _writeNode(node.argumentList);
    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.SuperConstructorInvocation_staticElement);
      _resolutionSink.writeElement(node.staticElement);
    }
    _writeMarker(MarkerTag.SuperConstructorInvocation_end);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _writeByte(Tag.SuperExpression);
    _writeMarker(MarkerTag.SuperExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.SuperExpression_end);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _writeByte(Tag.SymbolLiteral);

    var components = node.components;
    _writeUInt30(components.length);
    for (var token in components) {
      _writeStringReference(token.lexeme);
    }
    _storeExpression(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _writeByte(Tag.ThisExpression);
    _writeMarker(MarkerTag.ThisExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.ThisExpression_end);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _writeByte(Tag.ThrowExpression);
    _writeMarker(MarkerTag.ThrowExpression_expression);
    _writeNode(node.expression);
    _writeMarker(MarkerTag.ThrowExpression_expression2);
    _storeExpression(node);
    _writeMarker(MarkerTag.ThrowExpression_end);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    unitMemberIndexItems.add(
      _UnitMemberIndexItem(
        offset: _sink.offset,
        tag: Tag.TopLevelVariableDeclaration,
        variableNames: node.variables.variables
            .map((variable) => variable.name.name)
            .toList(),
      ),
    );

    _writeByte(Tag.TopLevelVariableDeclaration);
    _writeByte(
      AstBinaryFlags.encode(
        isExternal: node.externalKeyword != null,
      ),
    );

    _writeInformativeVariableCodeRanges(node.offset, node.variables);
    _writeDocumentationCommentString(node.documentationComment);

    var resolutionIndex = _getNextResolutionIndex();

    _shouldStoreVariableInitializers = node.variables.isConst;
    try {
      _writeMarker(MarkerTag.TopLevelVariableDeclaration_variables);
      _writeNode(node.variables);
    } finally {
      _shouldStoreVariableInitializers = false;
    }

    _writeMarker(MarkerTag.TopLevelVariableDeclaration_compilationUnitMember);
    _storeCompilationUnitMember(node);
    _writeMarker(MarkerTag.TopLevelVariableDeclaration_end);

    _writeUInt30(resolutionIndex);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _writeByte(Tag.TypeArgumentList);
    _writeMarker(MarkerTag.TypeArgumentList_arguments);
    _writeNodeList(node.arguments);
    _writeMarker(MarkerTag.TypeArgumentList_end);
  }

  @override
  void visitTypeName(TypeName node) {
    _writeByte(Tag.TypeName);

    _writeByte(
      AstBinaryFlags.encode(
        hasQuestion: node.question != null,
        hasTypeArguments: node.typeArguments != null,
      ),
    );

    _writeMarker(MarkerTag.TypeName_name);
    _writeNode(node.name);
    _writeMarker(MarkerTag.TypeName_typeArguments);
    _writeOptionalNode(node.typeArguments);

    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.TypeName_type);
      _resolutionSink.writeType(node.type);
    }
    _writeMarker(MarkerTag.TypeName_end);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _writeByte(Tag.TypeParameter);
    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDeclarationName(node.name);
    _writeMarker(MarkerTag.TypeParameter_bound);
    _writeOptionalNode(node.bound);
    _writeMarker(MarkerTag.TypeParameter_declaration);
    _storeDeclaration(node);

    if (_shouldWriteResolution) {
      var element = node.declaredElement as TypeParameterElementImpl;
      _writeMarker(MarkerTag.TypeParameter_variance);
      _resolutionSink.writeByte(
        _encodeVariance(element),
      );
      _writeMarker(MarkerTag.TypeParameter_defaultType);
      _resolutionSink.writeType(element.defaultType);
    }
    _writeMarker(MarkerTag.TypeParameter_end);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _writeByte(Tag.TypeParameterList);
    _writeMarker(MarkerTag.TypeParameterList_typeParameters);
    _writeNodeList(node.typeParameters);
    _writeMarker(MarkerTag.TypeParameterList_end);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _writeByte(Tag.VariableDeclaration);
    _writeByte(
      AstBinaryFlags.encode(
        hasInitializer: node.initializer != null,
      ),
    );
    _writeDeclarationName(node.name);

    if (_shouldWriteResolution) {
      // TODO(scheglov) Enforce not null, remove `?` in `?.type` below.
      var element = node.declaredElement as VariableElementImpl;
      _writeMarker(MarkerTag.VariableDeclaration_type);
      _writeActualType(element?.type);
      _writeMarker(MarkerTag.VariableDeclaration_inferenceError);
      _writeTopLevelInferenceError(element);
      if (element is FieldElementImpl) {
        _writeMarker(MarkerTag.VariableDeclaration_inheritsCovariant);
        _resolutionSink.writeByte(element.inheritsCovariant ? 1 : 0);
      }
    }

    Expression initializerToWrite;
    if (_shouldStoreVariableInitializers) {
      var initializer = node.initializer;
      if (_isSerializableExpression(initializer)) {
        initializerToWrite = initializer;
      }
    }
    _writeMarker(MarkerTag.VariableDeclaration_initializer);
    _writeOptionalNode(initializerToWrite);
    _writeMarker(MarkerTag.VariableDeclaration_end);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _writeByte(Tag.VariableDeclarationList);
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.isConst,
        isFinal: node.isFinal,
        isLate: node.lateKeyword != null,
        isVar: node.keyword?.keyword == Keyword.VAR,
      ),
    );
    _writeMarker(MarkerTag.VariableDeclarationList_type);
    _writeOptionalNode(node.type);
    _writeMarker(MarkerTag.VariableDeclarationList_variables);
    _writeNodeList(node.variables);
    _writeMarker(MarkerTag.VariableDeclarationList_annotatedNode);
    _storeAnnotatedNode(node);
    _writeMarker(MarkerTag.VariableDeclarationList_end);
  }

  @override
  void visitWithClause(WithClause node) {
    _writeByte(Tag.WithClause);
    _writeMarker(MarkerTag.WithClause_mixinTypes);
    _writeNodeList(node.mixinTypes);
    _writeMarker(MarkerTag.WithClause_end);
  }

  void _pushScopeTypeParameters(TypeParameterList node) {
    if (!_shouldWriteResolution) {
      return;
    }

    _resolutionSink.localElements.pushScope();

    if (node == null) {
      return;
    }

    for (var typeParameter in node.typeParameters) {
      _resolutionSink.localElements.declare(typeParameter.declaredElement);
    }
  }

  void _storeAnnotatedNode(AnnotatedNode node) {
    _writeMarker(MarkerTag.AnnotatedNode_metadata);
    _writeNodeList(node.metadata);
    _writeMarker(MarkerTag.AnnotatedNode_end);
  }

  void _storeClassMember(ClassMember node) {
    _writeMarker(MarkerTag.ClassMember_declaration);
    _storeDeclaration(node);
  }

  void _storeCompilationUnitMember(CompilationUnitMember node) {
    _storeDeclaration(node);
  }

  void _storeDeclaration(Declaration node) {
    _storeAnnotatedNode(node);
  }

  void _storeDirective(Directive node) {
    _writeInformativeUint30(node.keyword.offset);
    _storeAnnotatedNode(node);
  }

  void _storeExpression(Expression node) {
    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.Expression_staticType);
      _resolutionSink.writeType(node.staticType);
    }
  }

  void _storeForEachParts(ForEachParts node) {
    _writeMarker(MarkerTag.ForEachParts_iterable);
    _writeNode(node.iterable);
    _writeMarker(MarkerTag.ForEachParts_forLoopParts);
    _storeForLoopParts(node);
    _writeMarker(MarkerTag.ForEachParts_end);
  }

  void _storeForLoopParts(ForLoopParts node) {}

  void _storeFormalParameter(FormalParameter node) {
    if (_shouldWriteResolution) {
      _writeMarker(MarkerTag.FormalParameter_type);
      _writeActualType(node.declaredElement.type);
    }
  }

  void _storeForMixin(ForMixin node) {
    _writeByte(
      AstBinaryFlags.encode(
        hasAwait: node.awaitKeyword != null,
      ),
    );
    _writeMarker(MarkerTag.ForMixin_forLoopParts);
    _writeNode(node.forLoopParts);
  }

  void _storeForParts(ForParts node) {
    _writeMarker(MarkerTag.ForParts_condition);
    _writeOptionalNode(node.condition);
    _writeMarker(MarkerTag.ForParts_updaters);
    _writeNodeList(node.updaters);
    _writeMarker(MarkerTag.ForParts_forLoopParts);
    _storeForLoopParts(node);
    _writeMarker(MarkerTag.ForParts_end);
  }

  void _storeInvocationExpression(InvocationExpression node) {
    _writeMarker(MarkerTag.InvocationExpression_typeArguments);
    _writeOptionalNode(node.typeArguments);
    _writeMarker(MarkerTag.InvocationExpression_argumentList);
    _writeNode(node.argumentList);
    _writeMarker(MarkerTag.InvocationExpression_expression);
    _storeExpression(node);
    _writeMarker(MarkerTag.InvocationExpression_end);
    // TODO(scheglov) typeArgumentTypes and staticInvokeType?
  }

  void _storeNamedCompilationUnitMember(NamedCompilationUnitMember node) {
    _writeDeclarationName(node.name);
    _storeCompilationUnitMember(node);
  }

  void _storeNamespaceDirective(NamespaceDirective node) {
    _writeMarker(MarkerTag.NamespaceDirective_combinators);
    _writeNodeList(node.combinators);
    _writeMarker(MarkerTag.NamespaceDirective_configurations);
    _writeNodeList(node.configurations);
    _writeMarker(MarkerTag.NamespaceDirective_uriBasedDirective);
    _storeUriBasedDirective(node);
    _writeMarker(MarkerTag.NamespaceDirective_end);
  }

  void _storeNormalFormalParameter(
    NormalFormalParameter node,
    Token keyword, {
    bool hasQuestion = false,
  }) {
    _writeByte(
      AstBinaryFlags.encode(
        hasName: node.identifier != null,
        hasQuestion: hasQuestion,
        isConst: keyword?.type == Keyword.CONST,
        isCovariant: node.covariantKeyword != null,
        isFinal: keyword?.type == Keyword.FINAL,
        isRequired: node.requiredKeyword != null,
        isVar: keyword?.type == Keyword.VAR,
      ),
    );

    // TODO(scheglov) Don't store when in DefaultFormalParameter?
    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);

    _writeMarker(MarkerTag.NormalFormalParameter_metadata);
    _writeNodeList(node.metadata);
    if (node.identifier != null) {
      _writeDeclarationName(node.identifier);
    }
    _writeMarker(MarkerTag.NormalFormalParameter_formalParameter);
    _storeFormalParameter(node);
    _writeMarker(MarkerTag.NormalFormalParameter_end);
  }

  void _storeTypeAlias(TypeAlias node) {
    _storeNamedCompilationUnitMember(node);
  }

  void _storeUriBasedDirective(UriBasedDirective node) {
    _writeMarker(MarkerTag.UriBasedDirective_uri);
    _writeNode(node.uri);
    _writeMarker(MarkerTag.UriBasedDirective_directive);
    _storeDirective(node);
    _writeMarker(MarkerTag.UriBasedDirective_end);
  }

  void _writeActualReturnType(DartType type) {
    // TODO(scheglov) Check for `null` when writing resolved AST.
    _resolutionSink.writeType(type);
  }

  void _writeActualType(DartType type) {
    // TODO(scheglov) Check for `null` when writing resolved AST.
    _resolutionSink.writeType(type);
  }

  void _writeByte(int byte) {
    assert((byte & 0xFF) == byte);
    _sink.addByte(byte);
  }

  void _writeClassMemberIndex() {
    _writeUInt30(_classMemberIndexItems.length);
    for (var declaration in _classMemberIndexItems) {
      _writeUInt30(declaration.offset);
      _writeByte(declaration.tag);
      if (declaration.name != null) {
        _writeStringReference(declaration.name);
      } else {
        _writeUInt30(declaration.fieldNames.length);
        for (var name in declaration.fieldNames) {
          _writeStringReference(name);
        }
      }
    }
  }

  void _writeDeclarationName(SimpleIdentifier node) {
    _writeByte(Tag.SimpleIdentifier);
    _writeStringReference(node.name);
    _writeInformativeUint30(node.offset);
  }

  /// We write tokens as a list, so this must be the last entity written.
  void _writeDocumentationCommentString(Comment node) {
    if (node != null && _withInformative) {
      var tokens = node.tokens;
      _writeUInt30(tokens.length);
      for (var token in tokens) {
        _writeStringReference(token.lexeme);
      }
    } else {
      _writeUInt30(0);
    }
  }

  _writeDouble(double value) {
    _sink.addDouble(value);
  }

  void _writeFeatureSet(FeatureSet featureSet) {
    var experimentStatus = featureSet as ExperimentStatus;
    var encoded = experimentStatus.toStorage();
    _writeUint8List(encoded);
  }

  void _writeInformativeUint30(int value) {
    if (_withInformative) {
      _writeUInt30(value);
    }
  }

  void _writeInformativeVariableCodeRanges(
    int firstOffset,
    VariableDeclarationList node,
  ) {
    if (_withInformative) {
      var variables = node.variables;
      _writeUInt30(variables.length * 2);
      var isFirst = true;
      for (var variable in variables) {
        var offset = isFirst ? firstOffset : variable.offset;
        var end = variable.end;
        _writeUInt30(offset);
        _writeUInt30(end - offset);
        isFirst = false;
      }
    }
  }

  void _writeLanguageVersion(LibraryLanguageVersion languageVersion) {
    _writeUInt30(languageVersion.package.major);
    _writeUInt30(languageVersion.package.minor);

    var override = languageVersion.override;
    if (override != null) {
      _writeUInt30(override.major + 1);
      _writeUInt30(override.minor + 1);
    } else {
      _writeUInt30(0);
      _writeUInt30(0);
    }
  }

  void _writeLineInfo(LineInfo lineInfo) {
    if (_withInformative) {
      _writeUint30List(lineInfo.lineStarts);
    } else {
      _writeUint30List(const <int>[0]);
    }
  }

  void _writeMarker(MarkerTag tag) {
    if (enableDebugResolutionMarkers) {
      if (_shouldWriteResolution) {
        _resolutionSink.writeUInt30(tag.index);
      }
    }
  }

  void _writeNode(AstNode node) {
    node.accept(this);
  }

  void _writeNodeList(List<AstNode> nodeList) {
    _writeUInt30(nodeList.length);
    for (var i = 0; i < nodeList.length; ++i) {
      nodeList[i].accept(this);
    }
  }

  void _writeOptionalDeclarationName(SimpleIdentifier node) {
    if (node == null) {
      _writeByte(Tag.Nothing);
    } else {
      _writeByte(Tag.Something);
      _writeDeclarationName(node);
    }
  }

  void _writeOptionalNode(AstNode node) {
    if (node == null) {
      _writeByte(Tag.Nothing);
    } else {
      _writeByte(Tag.Something);
      _writeNode(node);
    }
  }

  void _writeStringReference(String string) {
    assert(string != null);
    var index = _stringIndexer[string];
    _writeUInt30(index);
  }

  void _writeTopLevelInferenceError(ElementImpl element) {
    TopLevelInferenceError error;
    if (element is MethodElementImpl) {
      error = element.typeInferenceError;
    } else if (element is PropertyInducingElementImpl) {
      error = element.typeInferenceError;
    } else {
      return;
    }

    if (error != null) {
      _resolutionSink.writeByte(error.kind.index);
      _resolutionSink.writeStringList(error.arguments);
    } else {
      _resolutionSink.writeByte(TopLevelInferenceErrorKind.none.index);
    }
  }

  @pragma("vm:prefer-inline")
  void _writeUInt30(int value) {
    _sink.writeUInt30(value);
  }

  void _writeUint30List(List<int> values) {
    var length = values.length;
    _writeUInt30(length);
    for (var i = 0; i < length; i++) {
      _writeUInt30(values[i]);
    }
  }

  void _writeUInt32(int value) {
    _sink.addByte4((value >> 24) & 0xFF, (value >> 16) & 0xFF,
        (value >> 8) & 0xFF, value & 0xFF);
  }

  void _writeUint8List(List<int> values) {
    var length = values.length;
    _writeUInt30(length);
    for (var i = 0; i < length; i++) {
      _writeByte(values[i]);
    }
  }

  static int _encodeVariance(TypeParameterElementImpl element) {
    if (element.isLegacyCovariant) {
      return 0;
    }

    var variance = element.variance;
    if (variance == Variance.unrelated) {
      return 1;
    } else if (variance == Variance.covariant) {
      return 2;
    } else if (variance == Variance.contravariant) {
      return 3;
    } else if (variance == Variance.invariant) {
      return 4;
    } else {
      throw UnimplementedError('$variance');
    }
  }

  /// Return `true` if the expression might be successfully serialized.
  ///
  /// This does not mean that the expression is constant, it just means that
  /// we know that it might be serialized and deserialized. For example
  /// function expressions are problematic, and are not necessary to
  /// deserialize, so we choose not to do this.
  static bool _isSerializableExpression(Expression node) {
    if (node == null) return false;

    var visitor = _IsSerializableExpressionVisitor();
    node.accept(visitor);
    return visitor.result;
  }
}

/// An item in the class index, used to read only requested class members.
class _ClassMemberIndexItem {
  final int offset;
  final int tag;
  final String name;
  final List<String> fieldNames;

  _ClassMemberIndexItem({
    @required this.offset,
    @required this.tag,
    this.name,
    this.fieldNames,
  });
}

class _IsSerializableExpressionVisitor extends RecursiveAstVisitor<void> {
  bool result = true;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    result = false;
  }
}

/// An item in the unit index, used to read only requested unit members.
class _UnitMemberIndexItem {
  final int offset;
  final int tag;
  final String name;
  final List<String> variableNames;

  /// The absolute offset of the index of class members, `0` if not a class.
  final int classIndexOffset;

  _UnitMemberIndexItem({
    @required this.offset,
    @required this.tag,
    this.name,
    this.variableNames,
    this.classIndexOffset = 0,
  });
}
