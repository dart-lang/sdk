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
  final ResolutionUnit _resolutionUnit;
  final ResolutionSink _resolutionSink;

  /// TODO(scheglov) Keep it private, and write here, similarly as we do
  /// for [_classMemberIndexItems]?
  final List<_UnitMemberIndexItem> unitMemberIndexItems = [];
  final List<_ClassMemberIndexItem> _classMemberIndexItems = [];
  bool _isConstField = false;
  bool _isFinalField = false;
  bool _isConstTopLevelVariable = false;
  bool _hasConstConstructor = false;
  int _nextUnnamedExtensionId = 0;

  AstBinaryWriter({
    @required BundleWriterAst bundleWriterAst,
    @required ResolutionUnit resolutionUnit,
  })  : _withInformative = bundleWriterAst.withInformative,
        _sink = bundleWriterAst.sink,
        _stringIndexer = bundleWriterAst.stringIndexer,
        _resolutionUnit = resolutionUnit,
        _resolutionSink = resolutionUnit.library.sink;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _writeByte(Tag.AdjacentStrings);
    _writeNodeList(node.strings);
  }

  @override
  void visitAnnotation(Annotation node) {
    _writeByte(Tag.Annotation);

    _writeOptionalNode(node.name);
    _writeOptionalNode(node.constructorName);

    var arguments = node.arguments;
    if (arguments != null) {
      if (!arguments.arguments.every(_isSerializableExpression)) {
        arguments = null;
      }
    }
    _writeOptionalNode(arguments);

    _resolutionSink.writeElement(node.element);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _writeByte(Tag.ArgumentList);
    _writeNodeList(node.arguments);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _writeByte(Tag.AsExpression);
    _writeNode(node.expression);
    _writeNode(node.type);
    _storeExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _writeByte(Tag.AssertInitializer);
    _writeNode(node.condition);
    _writeOptionalNode(node.message);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _writeByte(Tag.AssignmentExpression);

    _writeNode(node.leftHandSide);
    _writeNode(node.rightHandSide);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _resolutionSink.writeElement(node.staticElement);
    _resolutionSink.writeElement(node.readElement);
    _resolutionSink.writeType(node.readType);
    _resolutionSink.writeElement(node.writeElement);
    _resolutionSink.writeType(node.writeType);
    _storeExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _writeByte(Tag.BinaryExpression);

    _writeNode(node.leftOperand);
    _writeNode(node.rightOperand);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _resolutionSink?.writeElement(node.staticElement);
    _resolutionSink?.writeType(node.staticType);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _writeByte(Tag.BooleanLiteral);
    _writeByte(node.value ? 1 : 0);
    _resolutionSink?.writeType(node.staticType);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _writeByte(Tag.CascadeExpression);
    _writeNode(node.target);
    _writeNodeList(node.cascadeSections);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var classOffset = _sink.offset;
    var resolutionIndex = _resolutionUnit.enterDeclaration();

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
    _resolutionSink.writeByte(node.declaredElement.isSimplyBounded ? 1 : 0);

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    _pushScopeTypeParameters(node.typeParameters);

    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.extendsClause);
    _writeOptionalNode(node.withClause);
    _writeOptionalNode(node.implementsClause);
    _writeOptionalNode(node.nativeClause);
    _storeNamedCompilationUnitMember(node);
    _writeUInt30(resolutionIndex);

    _classMemberIndexItems.clear();
    _writeNodeList(node.members);
    _hasConstConstructor = false;

    _resolutionSink.localElements.popScope();

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

    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _writeByte(Tag.ClassTypeAlias);
    _writeByte(
      AstBinaryFlags.encode(
        isAbstract: node.abstractKeyword != null,
      ),
    );
    _resolutionSink.writeByte(node.declaredElement.isSimplyBounded ? 1 : 0);
    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _pushScopeTypeParameters(node.typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeNode(node.superclass);
    _writeNode(node.withClause);
    _writeOptionalNode(node.implementsClause);
    _storeTypeAlias(node);
    _writeDocumentationCommentString(node.documentationComment);
    _writeUInt30(resolutionIndex);
    _resolutionSink.localElements.popScope();
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
    _writeNode(node.condition);
    _writeNode(node.thenExpression);
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

    _writeNode(node.name);
    _writeOptionalNode(node.value);
    _writeNode(node.uri);
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

    var resolutionIndex = _resolutionUnit.enterDeclaration();
    _writeNode(node.returnType);
    if (node.period != null) {
      _writeInformativeUint30(node.period.offset);
      _writeDeclarationName(node.name);
    }
    _writeNode(node.parameters);

    _resolutionSink.localElements.pushScope();
    for (var parameter in node.parameters.parameters) {
      _resolutionSink.localElements.declare(parameter.declaredElement);
    }
    _writeNodeList(node.initializers);
    _resolutionSink.localElements.popScope();

    _writeOptionalNode(node.redirectedConstructor);
    _storeClassMember(node);
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

    _writeNode(node.fieldName);
    _writeNode(node.expression);
    _storeConstructorInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _writeByte(Tag.ConstructorName);
    _writeNode(node.type);
    _writeOptionalNode(node.name);
    _resolutionSink?.writeElement(node.staticElement);
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
    _writeOptionalNode(node.type);
    _writeDeclarationName(node.identifier);
    _storeDeclaration(node);
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

    _writeNode(node.parameter);

    var defaultValue = node.defaultValue;
    if (!_isSerializableExpression(defaultValue)) {
      defaultValue = null;
    }
    _writeOptionalNode(defaultValue);
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

    _writeDeclarationName(node.name);
    _storeDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    var resolutionIndex = _resolutionUnit.enterDeclaration();
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

    _writeNodeList(node.constants);
    _storeNamedCompilationUnitMember(node);
    _writeUInt30(resolutionIndex);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _writeByte(Tag.ExportDirective);
    _storeNamespaceDirective(node);
    _writeUInt30(resolutionIndex);

    _resolutionSink?.writeElement(
      (node.element as ExportElementImpl).exportedLibrary,
    );
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _writeByte(Tag.ExtendsClause);
    _writeNode(node.superclass);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var classOffset = _sink.offset;
    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _writeByte(Tag.ExtensionDeclaration);

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    _pushScopeTypeParameters(node.typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeNode(node.extendedType);
    _writeOptionalDeclarationName(node.name);
    _storeCompilationUnitMember(node);
    _writeUInt30(resolutionIndex);

    _classMemberIndexItems.clear();
    _writeNodeList(node.members);

    _resolutionSink.localElements.popScope();

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
    _writeNode(node.extensionName);
    _writeOptionalNode(node.typeArguments);
    _writeNode(node.argumentList);
    _resolutionSink.writeType(node.extendedType);
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

    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _isConstField = node.fields.isConst;
    _isFinalField = node.fields.isFinal;
    try {
      _writeNode(node.fields);
    } finally {
      _isConstField = false;
      _isFinalField = false;
    }

    _storeClassMember(node);

    _writeUInt30(resolutionIndex);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _writeByte(Tag.FieldFormalParameter);

    _pushScopeTypeParameters(node.typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.type);
    _writeOptionalNode(node.parameters);
    _storeNormalFormalParameter(
      node,
      node.keyword,
      hasQuestion: node.question != null,
    );
    _resolutionSink.localElements.popScope();
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _writeByte(Tag.ForEachPartsWithDeclaration);
    _writeNode(node.loopVariable);
    _storeForEachParts(node);
  }

  @override
  void visitForElement(ForElement node) {
    _writeByte(Tag.ForElement);
    _writeNode(node.body);
    _storeForMixin(node as ForElementImpl);
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

    _writeNodeList(node.parameters);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _writeByte(Tag.ForPartsWithDeclarations);
    _writeNode(node.variables);
    _storeForParts(node);
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

    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _pushScopeTypeParameters(node.functionExpression.typeParameters);

    _writeNode(node.functionExpression);
    _writeOptionalNode(node.returnType);
    _storeNamedCompilationUnitMember(node);
    _writeActualReturnType(node.declaredElement.returnType);

    _resolutionSink.localElements.popScope();

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

    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.parameters);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _writeByte(Tag.FunctionExpressionInvocation);
    _writeNode(node.function);
    _storeInvocationExpression(node);
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

    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _pushScopeTypeParameters(node.typeParameters);

    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.returnType);
    _writeNode(node.parameters);

    _storeTypeAlias(node);

    var element = node.declaredElement as FunctionTypeAliasElementImpl;
    _writeActualReturnType(element.function.returnType);
    // TODO(scheglov) pack into one byte
    _resolutionSink.writeByte(element.isSimplyBounded ? 1 : 0);
    _resolutionSink.writeByte(element.hasSelfReference ? 1 : 0);

    _resolutionSink.localElements.popScope();

    _writeUInt30(resolutionIndex);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _writeByte(Tag.FunctionTypedFormalParameter);

    _pushScopeTypeParameters(node.typeParameters);
    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.returnType);
    _writeNode(node.parameters);
    _storeNormalFormalParameter(node, null);
    _resolutionSink.localElements.popScope();
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

    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.returnType);
    _writeNode(node.parameters);
    _resolutionSink?.writeType(node.type);

    _resolutionSink.localElements.popScope();
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

    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _pushScopeTypeParameters(node.typeParameters);

    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.type);
    _storeTypeAlias(node);

    var element = node.declaredElement as TypeAliasElementImpl;
    // TODO(scheglov) pack into one byte
    _resolutionSink.writeByte(element.isSimplyBounded ? 1 : 0);
    _resolutionSink.writeByte(element.hasSelfReference ? 1 : 0);

    _resolutionSink.localElements.popScope();

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
    _writeNode(node.condition);
    _writeNode(node.thenElement);
    _writeOptionalNode(node.elseElement);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _writeByte(Tag.ImplementsClause);
    _writeNodeList(node.interfaces);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var resolutionIndex = _resolutionUnit.enterDeclaration();

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

    _storeNamespaceDirective(node);
    _writeUInt30(resolutionIndex);

    var element = node.element as ImportElementImpl;
    _resolutionSink?.writeElement(element.importedLibrary);
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
    _writeOptionalNode(node.target);
    _writeNode(node.index);
    _resolutionSink.writeElement(node.staticElement);
    _storeExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _writeByte(Tag.InstanceCreationExpression);

    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.keyword?.type == Keyword.CONST,
        isNew: node.keyword?.type == Keyword.NEW,
      ),
    );

    _writeNode(node.constructorName);
    _writeNode(node.argumentList);
    _storeExpression(node);
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
    _resolutionSink?.writeType(node.staticType);
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
    _writeNode(node.expression);
    _writeNode(node.type);
    _storeExpression(node);
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

    _writeOptionalNode(node.typeArguments);
    _writeNodeList(node.elements);

    _storeExpression(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _writeByte(Tag.MapLiteralEntry);
    _writeNode(node.key);
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

    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _pushScopeTypeParameters(node.typeParameters);

    _writeDeclarationName(node.name);
    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.returnType);
    _writeOptionalNode(node.parameters);

    _storeClassMember(node);

    _writeUInt30(resolutionIndex);

    var element = node.declaredElement as ExecutableElementImpl;
    _writeActualReturnType(element.returnType);
    _writeTopLevelInferenceError(element);
    // TODO(scheglov) move this flag into ClassElementImpl?
    if (element is MethodElementImpl) {
      _resolutionSink.writeByte(
        element.isOperatorEqualWithParameterTypeFromObject ? 1 : 0,
      );
    }

    _resolutionSink.localElements.popScope();
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _writeByte(Tag.MethodInvocation);
    _writeByte(
      AstBinaryFlags.encode(
        hasPeriod: node.operator?.type == TokenType.PERIOD,
        hasPeriod2: node.operator?.type == TokenType.PERIOD_PERIOD,
      ),
    );
    _writeOptionalNode(node.target);
    _writeNode(node.methodName);
    _storeInvocationExpression(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var classOffset = _sink.offset;
    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _writeByte(Tag.MixinDeclaration);

    var element = node.declaredElement as MixinElementImpl;
    _resolutionSink.writeByte(element.isSimplyBounded ? 1 : 0);
    _resolutionSink.writeStringList(element.superInvokedNames);

    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDocumentationCommentString(node.documentationComment);

    _pushScopeTypeParameters(node.typeParameters);

    _writeOptionalNode(node.typeParameters);
    _writeOptionalNode(node.onClause);
    _writeOptionalNode(node.implementsClause);
    _storeNamedCompilationUnitMember(node);
    _writeUInt30(resolutionIndex);

    _classMemberIndexItems.clear();
    _writeNodeList(node.members);
    _hasConstConstructor = false;

    _resolutionSink.localElements.popScope();

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

    _writeNode(node.expression);
  }

  @override
  void visitNativeClause(NativeClause node) {
    _writeByte(Tag.NativeClause);
    _writeNode(node.name);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _writeByte(Tag.NullLiteral);
  }

  @override
  void visitOnClause(OnClause node) {
    _writeByte(Tag.OnClause);
    _writeNodeList(node.superclassConstraints);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _writeByte(Tag.ParenthesizedExpression);
    _writeNode(node.expression);
    _storeExpression(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _writeByte(Tag.PartDirective);
    _storeUriBasedDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _writeByte(Tag.PartOfDirective);
    _writeOptionalNode(node.libraryName);
    _writeOptionalNode(node.uri);
    _storeDirective(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _writeByte(Tag.PostfixExpression);

    _writeNode(node.operand);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _resolutionSink.writeElement(node.staticElement);
    if (operatorToken.isIncrementOperator) {
      _resolutionSink.writeElement(node.readElement);
      _resolutionSink.writeType(node.readType);
      _resolutionSink.writeElement(node.writeElement);
      _resolutionSink.writeType(node.writeType);
    }
    _storeExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _writeByte(Tag.PrefixedIdentifier);
    _writeNode(node.prefix);
    _writeNode(node.identifier);

    // TODO(scheglov) In actual prefixed identifier, the type of the identifier.
    _resolutionSink?.writeType(node.staticType);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _writeByte(Tag.PrefixExpression);

    var operatorToken = node.operator.type;
    var binaryToken = TokensWriter.astToBinaryTokenType(operatorToken);
    _writeByte(binaryToken.index);

    _writeNode(node.operand);

    _resolutionSink?.writeElement(node.staticElement);
    if (operatorToken.isIncrementOperator) {
      _resolutionSink.writeElement(node.readElement);
      _resolutionSink.writeType(node.readType);
      _resolutionSink.writeElement(node.writeElement);
      _resolutionSink.writeType(node.writeType);
    }
    _storeExpression(node);
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
    _writeOptionalNode(node.target);
    _writeNode(node.propertyName);
    // TODO(scheglov) Get from the property?
    _storeExpression(node);
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

    _writeOptionalNode(node.constructorName);
    _writeNode(node.argumentList);
    _resolutionSink?.writeElement(node.staticElement);
    _storeConstructorInitializer(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _writeByte(Tag.SetOrMapLiteral);

    // TODO(scheglov) isMap/isSet is resolution data
    _writeByte(
      AstBinaryFlags.encode(
        isConst: node.constKeyword != null,
        isMap: node.isMap,
        isSet: node.isSet,
      ),
    );

    _writeOptionalNode(node.typeArguments);
    _writeNodeList(node.elements);

    _storeExpression(node);
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

    _writeOptionalNode(node.type);
    _storeNormalFormalParameter(node, node.keyword);

    var element = node.declaredElement as ParameterElementImpl;
    _resolutionSink.writeByte(element.inheritsCovariant ? 1 : 0);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _writeByte(Tag.SimpleIdentifier);
    _writeStringReference(node.name);
    _writeInformativeUint30(node.offset);
    _resolutionSink?.writeElement(node.staticElement);
    // TODO(scheglov) It is inefficient to write many null types.
    _resolutionSink?.writeType(node.staticType);
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
    _writeNode(node.expression);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _writeByte(Tag.StringInterpolation);
    _writeNodeList(node.elements);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writeByte(Tag.SuperConstructorInvocation);

    _writeOptionalNode(node.constructorName);
    _writeNode(node.argumentList);
    _resolutionSink?.writeElement(node.staticElement);
    _storeConstructorInitializer(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _writeByte(Tag.SuperExpression);
    _storeExpression(node);
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
    _storeExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _writeByte(Tag.ThrowExpression);
    _writeNode(node.expression);
    _storeExpression(node);
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

    var resolutionIndex = _resolutionUnit.enterDeclaration();

    _isConstTopLevelVariable = node.variables.isConst;
    try {
      _writeNode(node.variables);
    } finally {
      _isConstTopLevelVariable = false;
    }

    _storeCompilationUnitMember(node);

    _writeUInt30(resolutionIndex);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _writeByte(Tag.TypeArgumentList);
    _writeNodeList(node.arguments);
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

    _writeNode(node.name);
    _writeOptionalNode(node.typeArguments);

    _resolutionSink.writeType(node.type);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _writeByte(Tag.TypeParameter);
    _writeInformativeUint30(node.offset);
    _writeInformativeUint30(node.length);
    _writeDeclarationName(node.name);
    _writeOptionalNode(node.bound);
    _storeDeclaration(node);

    var element = node.declaredElement as TypeParameterElementImpl;
    _resolutionSink.writeByte(
      _encodeVariance(element),
    );
    _resolutionSink.writeType(element.defaultType);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _writeByte(Tag.TypeParameterList);
    _writeNodeList(node.typeParameters);
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

    // TODO(scheglov) Enforce not null, remove `?` in `?.type` below.
    var element = node.declaredElement as VariableElementImpl;
    _writeActualType(element?.type);
    _writeTopLevelInferenceError(element);
    if (element is FieldElementImpl) {
      _resolutionSink.writeByte(element.inheritsCovariant ? 1 : 0);
    }

    Expression initializerToWrite;
    if (_isConstField ||
        _hasConstConstructor && _isFinalField ||
        _isConstTopLevelVariable) {
      var initializer = node.initializer;
      if (_isSerializableExpression(initializer)) {
        initializerToWrite = initializer;
      }
    }
    _writeOptionalNode(initializerToWrite);
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
    _writeOptionalNode(node.type);
    _writeNodeList(node.variables);
    _storeAnnotatedNode(node);
  }

  @override
  void visitWithClause(WithClause node) {
    _writeByte(Tag.WithClause);
    _writeNodeList(node.mixinTypes);
  }

  void _pushScopeTypeParameters(TypeParameterList node) {
    _resolutionSink.localElements.pushScope();

    if (node == null) {
      return;
    }

    for (var typeParameter in node.typeParameters) {
      _resolutionSink.localElements.declare(typeParameter.declaredElement);
    }
  }

  void _storeAnnotatedNode(AnnotatedNode node) {
    _writeNodeList(node.metadata);
  }

  void _storeClassMember(ClassMember node) {
    _storeDeclaration(node);
  }

  void _storeCompilationUnitMember(CompilationUnitMember node) {
    _storeDeclaration(node);
  }

  void _storeConstructorInitializer(ConstructorInitializer node) {}

  void _storeDeclaration(Declaration node) {
    _storeAnnotatedNode(node);
  }

  void _storeDirective(Directive node) {
    _writeInformativeUint30(node.keyword.offset);
    _storeAnnotatedNode(node);
  }

  void _storeExpression(Expression node) {
    _resolutionSink?.writeType(node.staticType);
  }

  void _storeForEachParts(ForEachParts node) {
    _writeNode(node.iterable);
    _storeForLoopParts(node);
  }

  void _storeForLoopParts(ForLoopParts node) {}

  void _storeFormalParameter(FormalParameter node) {
    _writeActualType(node.declaredElement.type);
  }

  void _storeForMixin(ForMixin node) {
    _writeByte(
      AstBinaryFlags.encode(
        hasAwait: node.awaitKeyword != null,
      ),
    );
    _writeNode(node.forLoopParts);
  }

  void _storeForParts(ForParts node) {
    _writeOptionalNode(node.condition);
    _writeNodeList(node.updaters);
    _storeForLoopParts(node);
  }

  void _storeInvocationExpression(InvocationExpression node) {
    _writeOptionalNode(node.typeArguments);
    _writeNode(node.argumentList);
    _storeExpression(node);
    // TODO(scheglov) typeArgumentTypes and staticInvokeType?
  }

  void _storeNamedCompilationUnitMember(NamedCompilationUnitMember node) {
    _writeDeclarationName(node.name);
    _storeCompilationUnitMember(node);
  }

  void _storeNamespaceDirective(NamespaceDirective node) {
    _writeNodeList(node.combinators);
    _writeNodeList(node.configurations);
    _storeUriBasedDirective(node);
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

    _writeNodeList(node.metadata);
    if (node.identifier != null) {
      _writeDeclarationName(node.identifier);
    }
    _storeFormalParameter(node);
  }

  void _storeTypeAlias(TypeAlias node) {
    _storeNamedCompilationUnitMember(node);
  }

  void _storeUriBasedDirective(UriBasedDirective node) {
    _writeNode(node.uri);
    _storeDirective(node);
  }

  void _writeActualReturnType(DartType type) {
    // TODO(scheglov) Check for `null` when writing resolved AST.
    _resolutionSink?.writeType(type);
  }

  void _writeActualType(DartType type) {
    // TODO(scheglov) Check for `null` when writing resolved AST.
    _resolutionSink?.writeType(type);
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
