// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart';
import 'package:_fe_analyzer_shared/src/parser/listener.dart'
    show UnescapeErrorListener;
import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show ClassMemberParser, Parser;
import 'package:_fe_analyzer_shared/src/parser/quote.dart' show unescapeString;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration, ScannerResult, scan;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import '../source/diet_parser.dart';
import 'parser_ast_helper.dart';

// TODO(jensj): Possibly all the enableX bools should be replaced by an
// "assumed version" (from package config probably) which is then updated if
// a language version is seen which will then implicitly answer these questions.
CompilationUnitEnd getAST(
  Uint8List rawBytes, {
  bool includeBody = true,
  bool includeComments = false,
  bool enableTripleShift = false,
  bool allowPatterns = false,
  bool enableEnhancedParts = false,
  List<Token>? languageVersionsSeen,
  List<int>? lineStarts,
}) {
  ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
    enableTripleShift: enableTripleShift,
  );

  ScannerResult scanResult = scan(
    rawBytes,
    includeComments: includeComments,
    configuration: scannerConfiguration,
    languageVersionChanged: (scanner, languageVersion) {
      // Coverage-ignore-block(suite): Not run.
      // For now don't do anything, but having it (making it non-null) means the
      // configuration won't be reset.
      languageVersionsSeen?.add(languageVersion);
      // TODO(jensj): Should we perhaps update "allowPatterns" here? E.g. if
      // on or after ExperimentalFlag.patterns.enabledVersion or something
    },
  );

  Token firstToken = scanResult.tokens;
  if (lineStarts != null) {
    // Coverage-ignore-block(suite): Not run.
    lineStarts.addAll(scanResult.lineStarts);
  }
  ParserASTListener listener = new ParserASTListener();
  Parser parser;
  if (includeBody) {
    parser = new Parser(
      listener,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      allowPatterns: allowPatterns,
      enableFeatureEnhancedParts: enableEnhancedParts,
    );
  } else {
    parser = new ClassMemberParser(
      listener,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      allowPatterns: allowPatterns,
      enableFeatureEnhancedParts: enableEnhancedParts,
    );
  }
  parser.parseUnit(firstToken);
  return listener.data.single as CompilationUnitEnd;
}

/// Recursive Parser AST Visitor that ignores (and thus doesn't recursively
/// visit) a few classes for compatibility with the previous
/// on-the-side-visitor. For instance visiting all the nodes for
/// ```
///   @Const()
///   extension Extension<@Const() T> on Class<T> {
///   }
/// ```
/// will visit the first metadata, then the type variables which itself has the
/// second metadata, only then it visits the extension - which old "visitor"
/// code doesn't handle. This visitor for instance ignores the type variables
/// to "fix" this case.
class IgnoreSomeForCompatibilityAstVisitor extends RecursiveParserAstVisitor {
  @override
  void visitTypeVariablesEnd(TypeVariablesEnd node) {
    // Ignored
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitTypeArgumentsEnd(TypeArgumentsEnd node) {
    // Ignored
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitTypeListEnd(TypeListEnd node) {
    // Ignored
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitFunctionTypeEnd(FunctionTypeEnd node) {
    // Ignored
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitBlockEnd(BlockEnd node) {
    // Ignored
  }
}

// Coverage-ignore(suite): Not run.
/// Best-effort visitor for ParserAstNode that visits top-level entries
/// and class members only (i.e. no bodies, no field initializer content, no
/// names etc).
class BestEffortParserAstVisitor {
  void accept(ParserAstNode node) {
    if (node is CompilationUnitEnd ||
        node is TopLevelDeclarationEnd ||
        node is ClassOrMixinOrExtensionBodyEnd ||
        node is MemberEnd) {
      visitChildren(node);
      return;
    }

    if (node.type == ParserAstType.BEGIN) {
      // Ignored. These are basically just dummy nodes anyway.
      assert(node.children == null);
      return;
    }
    if (node.type == ParserAstType.HANDLE) {
      // Ignored at least for know.
      assert(node.children == null);
      return;
    }
    if (node is TypeVariablesEnd ||
        node is TypeArgumentsEnd ||
        node is TypeListEnd ||
        node is FunctionTypeEnd ||
        node is BlockEnd) {
      // Ignored at least for know.
      return;
    }
    if (node is MetadataStarEnd) {
      MetadataStarEnd metadata = node;
      visitMetadataStar(metadata);
      return;
    }
    if (node is TypedefEnd) {
      TypedefEnd typedefDecl = node;
      visitTypedef(
        typedefDecl,
        typedefDecl.typedefKeyword,
        typedefDecl.endToken,
      );
      return;
    }
    if (node is ClassDeclarationEnd) {
      ClassDeclarationEnd cls = node;
      visitClass(cls, cls.beginToken, cls.endToken);
      return;
    }
    if (node is TopLevelMethodEnd) {
      TopLevelMethodEnd method = node;
      visitTopLevelMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is ClassMethodEnd) {
      ClassMethodEnd method = node;
      visitClassMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is ExtensionMethodEnd) {
      ExtensionMethodEnd method = node;
      visitExtensionMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is ExtensionTypeMethodEnd) {
      ExtensionTypeMethodEnd method = node;
      visitExtensionTypeMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is MixinMethodEnd) {
      MixinMethodEnd method = node;
      visitMixinMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is ImportEnd) {
      ImportEnd import = node;
      visitImport(import, import.importKeyword, import.semicolon);
      return;
    }
    if (node is ExportEnd) {
      ExportEnd export = node;
      visitExport(export, export.exportKeyword, export.semicolon);
      return;
    }
    if (node is TopLevelFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      TopLevelFieldsEnd fields = node;
      visitTopLevelFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is ClassFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      ClassFieldsEnd fields = node;
      visitClassFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is ExtensionFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      ExtensionFieldsEnd fields = node;
      visitExtensionFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is ExtensionTypeFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      ExtensionTypeFieldsEnd fields = node;
      visitExtensionTypeFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is MixinFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      MixinFieldsEnd fields = node;
      visitMixinFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is NamedMixinApplicationEnd) {
      NamedMixinApplicationEnd namedMixin = node;
      visitNamedMixin(namedMixin, namedMixin.begin, namedMixin.endToken);
      return;
    }
    if (node is MixinDeclarationEnd) {
      MixinDeclarationEnd declaration = node;
      visitMixin(declaration, declaration.beginToken, declaration.endToken);
      return;
    }
    if (node is EnumEnd) {
      EnumEnd declaration = node;
      visitEnum(
        declaration,
        declaration.enumKeyword,
        declaration.leftBrace.endGroup!,
      );
      return;
    }
    if (node is LibraryNameEnd) {
      LibraryNameEnd name = node;
      visitLibraryName(name, name.libraryKeyword, name.semicolon);
      return;
    }
    if (node is PartEnd) {
      PartEnd part = node;
      visitPart(part, part.partKeyword, part.semicolon);
      return;
    }
    if (node is PartOfEnd) {
      PartOfEnd partOf = node;
      visitPartOf(partOf, partOf.partKeyword, partOf.semicolon);
      return;
    }
    if (node is ExtensionDeclarationEnd) {
      ExtensionDeclarationEnd ext = node;
      visitExtension(ext, ext.beginToken, ext.endToken);
      return;
    }
    if (node is ExtensionTypeDeclarationEnd) {
      ExtensionTypeDeclarationEnd ext = node;
      visitExtensionTypeDeclaration(ext, ext.extensionKeyword, ext.endToken);
      return;
    }
    if (node is ClassConstructorEnd) {
      ClassConstructorEnd decl = node;
      visitClassConstructor(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is ExtensionConstructorEnd) {
      ExtensionConstructorEnd decl = node;
      visitExtensionConstructor(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is ExtensionTypeConstructorEnd) {
      ExtensionTypeConstructorEnd decl = node;
      visitExtensionTypeConstructor(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is ClassFactoryMethodEnd) {
      ClassFactoryMethodEnd decl = node;
      visitClassFactoryMethod(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is ExtensionFactoryMethodEnd) {
      ExtensionFactoryMethodEnd decl = node;
      visitExtensionFactoryMethod(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is ExtensionTypeFactoryMethodEnd) {
      ExtensionTypeFactoryMethodEnd decl = node;
      visitExtensionTypeFactoryMethod(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is MetadataEnd) {
      MetadataEnd decl = node;
      visitMetadata(decl, decl.beginToken, decl.endToken);
      return;
    }

    throw "Unknown: $node (${node.runtimeType} @ ${node.what})";
  }

  void visitChildren(ParserAstNode node) {
    if (node.children == null) return;
    final int numChildren = node.children!.length;
    for (int i = 0; i < numChildren; i++) {
      ParserAstNode child = node.children![i];
      accept(child);
    }
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitImport(ImportEnd node, Token startInclusive, Token? endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExport(ExportEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitTypedef(
    TypedefEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitMetadataStar(MetadataStarEnd node) {
    visitChildren(node);
  }

  /// Note: Implementers can call visitChildren on this node.
  void visitClass(
    ClassDeclarationEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitTopLevelMethod(
    TopLevelMethodEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassMethod(
    ClassMethodEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionMethod(
    ExtensionMethodEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionTypeMethod(
    ExtensionTypeMethodEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMixinMethod(
    MixinMethodEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitTopLevelFields(
    TopLevelFieldsEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassFields(
    ClassFieldsEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionFields(
    ExtensionFieldsEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionTypeFields(
    ExtensionTypeFieldsEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMixinFields(
    MixinFieldsEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitNamedMixin(
    NamedMixinApplicationEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {
    visitChildren(node);
  }

  /// Note: Implementers can call visitChildren on this node.
  void visitMixin(
    MixinDeclarationEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitEnum(EnumEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitLibraryName(
    LibraryNameEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitPart(PartEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitPartOf(PartOfEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitExtension(
    ExtensionDeclarationEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {
    visitChildren(node);
  }

  /// Note: Implementers can call visitChildren on this node.
  void visitExtensionTypeDeclaration(
    ExtensionTypeDeclarationEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassConstructor(
    ClassConstructorEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionConstructor(
    ExtensionConstructorEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionTypeConstructor(
    ExtensionTypeConstructorEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassFactoryMethod(
    ClassFactoryMethodEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionFactoryMethod(
    ExtensionFactoryMethodEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionTypeFactoryMethod(
    ExtensionTypeFactoryMethodEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMetadata(
    MetadataEnd node,
    Token startInclusive,
    Token endInclusive,
  ) {}
}

enum MemberContentType {
  ClassConstructor,
  ClassFactoryMethod,
  ClassFields,
  ClassMethod,
  ClassRecoverableError,
  EnumConstructor,
  EnumFactoryMethod,
  EnumFields,
  EnumMethod,
  ExperimentNotEnabled,
  ExtensionConstructor,
  ExtensionFactoryMethod,
  ExtensionFields,
  ExtensionMethod,
  ExtensionTypeConstructor,
  ExtensionTypeFactoryMethod,
  ExtensionTypeFields,
  ExtensionTypeMethod,
  MixinConstructor,
  MixinFactoryMethod,
  MixinFields,
  MixinMethod,
  Unknown,
}

enum GeneralAstContentType {
  Class,
  Import,
  Export,
  Unknown,
  Enum,
  Typedef,
  Script,
  Extension,
  ExtensionType,
  InvalidTopLevelDeclaration,
  RecoverableError,
  RecoverImport,
  MixinDeclaration,
  NamedMixinDeclaration,
  TopLevelMethod,
  TopLevelFields,
  LibraryName,
  Part,
  PartOf,
  Metadata,
  FunctionBody,
}

// Coverage-ignore(suite): Not run.
extension GeneralASTContentExtension on ParserAstNode {
  // TODO(jensj): This might not actually be useful - we're doing a lot of if's
  // here, but will then have to do more if's or a switch at the call site to
  // do anything useful with it, which might not be optimal.
  GeneralAstContentType getType() {
    if (isClass()) return GeneralAstContentType.Class;
    if (isImport()) return GeneralAstContentType.Import;
    if (isExport()) return GeneralAstContentType.Export;
    if (isExport()) return GeneralAstContentType.Export;
    if (isEnum()) return GeneralAstContentType.Enum;
    if (isTypedef()) return GeneralAstContentType.Typedef;
    if (isScript()) return GeneralAstContentType.Script;
    if (isExtension()) return GeneralAstContentType.Extension;
    if (isExtensionType()) return GeneralAstContentType.ExtensionType;
    if (isInvalidTopLevelDeclaration()) {
      return GeneralAstContentType.InvalidTopLevelDeclaration;
    }
    if (isRecoverableError()) return GeneralAstContentType.RecoverableError;
    if (isRecoverImport()) return GeneralAstContentType.RecoverImport;
    if (isMixinDeclaration()) return GeneralAstContentType.MixinDeclaration;
    if (isNamedMixinDeclaration()) {
      return GeneralAstContentType.NamedMixinDeclaration;
    }
    if (isTopLevelMethod()) return GeneralAstContentType.TopLevelMethod;
    if (isTopLevelFields()) return GeneralAstContentType.TopLevelFields;
    if (isLibraryName()) return GeneralAstContentType.LibraryName;
    if (isPart()) return GeneralAstContentType.Part;
    if (isPartOf()) return GeneralAstContentType.PartOf;
    if (isMetadata()) return GeneralAstContentType.Metadata;
    if (isFunctionBody()) return GeneralAstContentType.FunctionBody;
    return GeneralAstContentType.Unknown;
  }

  bool isClass() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        // ignore: lines_longer_than_80_chars
        is! ClassOrMixinOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children!.last is! ClassDeclarationEnd) {
      return false;
    }

    return true;
  }

  ClassDeclarationEnd asClass() {
    if (!isClass()) throw "Not class";
    return children!.last as ClassDeclarationEnd;
  }

  bool isImport() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! ImportEnd) {
      return false;
    }

    return true;
  }

  ImportEnd asImport() {
    if (!isImport()) throw "Not import";
    return children!.last as ImportEnd;
  }

  bool isExport() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! ExportEnd) {
      return false;
    }

    return true;
  }

  ExportEnd asExport() {
    if (!isExport()) throw "Not export";
    return children!.last as ExportEnd;
  }

  bool isEnum() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! EnumEnd) {
      return false;
    }

    return true;
  }

  EnumEnd asEnum() {
    if (!isEnum()) throw "Not enum";
    return children!.last as EnumEnd;
  }

  bool isTypedef() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! TypedefEnd) {
      return false;
    }

    return true;
  }

  TypedefEnd asTypedef() {
    if (!isTypedef()) throw "Not typedef";
    return children!.last as TypedefEnd;
  }

  bool isScript() {
    if (this is! ScriptHandle) {
      return false;
    }
    return true;
  }

  ScriptHandle asScript() {
    if (!isScript()) throw "Not script";
    return this as ScriptHandle;
  }

  bool isExtension() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! ExtensionDeclarationPreludeBegin) {
      return false;
    }
    if (children!.last is! ExtensionDeclarationEnd) {
      return false;
    }

    return true;
  }

  ExtensionDeclarationEnd asExtension() {
    if (!isExtension()) throw "Not extension";
    return children!.last as ExtensionDeclarationEnd;
  }

  bool isExtensionType() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! ExtensionDeclarationPreludeBegin) {
      return false;
    }
    if (children!.last is! ExtensionTypeDeclarationEnd) {
      return false;
    }

    return true;
  }

  ExtensionTypeDeclarationEnd asExtensionType() {
    if (!isExtensionType()) throw "Not extension type";
    return children!.last as ExtensionTypeDeclarationEnd;
  }

  bool isInvalidTopLevelDeclaration() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! TopLevelMemberBegin) {
      return false;
    }
    if (children!.last is! InvalidTopLevelDeclarationHandle) {
      return false;
    }

    return true;
  }

  bool isRecoverableError() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! RecoverableErrorHandle) {
      return false;
    }

    return true;
  }

  bool isRecoverImport() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! RecoverImportHandle) {
      return false;
    }

    return true;
  }

  bool isMixinDeclaration() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        // ignore: lines_longer_than_80_chars
        is! ClassOrMixinOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children!.last is! MixinDeclarationEnd) {
      return false;
    }

    return true;
  }

  MixinDeclarationEnd asMixinDeclaration() {
    if (!isMixinDeclaration()) throw "Not mixin declaration";
    return children!.last as MixinDeclarationEnd;
  }

  bool isNamedMixinDeclaration() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        // ignore: lines_longer_than_80_chars
        is! ClassOrMixinOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children!.last is! NamedMixinApplicationEnd) {
      return false;
    }

    return true;
  }

  NamedMixinApplicationEnd asNamedMixinDeclaration() {
    if (!isNamedMixinDeclaration()) throw "Not named mixin declaration";
    return children!.last as NamedMixinApplicationEnd;
  }

  bool isTopLevelMethod() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! TopLevelMemberBegin) {
      return false;
    }
    if (children!.last is! TopLevelMethodEnd) {
      return false;
    }

    return true;
  }

  TopLevelMethodEnd asTopLevelMethod() {
    if (!isTopLevelMethod()) throw "Not top level method";
    return children!.last as TopLevelMethodEnd;
  }

  bool isTopLevelFields() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! TopLevelMemberBegin) {
      return false;
    }
    if (children!.last is! TopLevelFieldsEnd) {
      return false;
    }

    return true;
  }

  TopLevelFieldsEnd asTopLevelFields() {
    if (!isTopLevelFields()) throw "Not top level fields";
    return children!.last as TopLevelFieldsEnd;
  }

  bool isLibraryName() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! LibraryNameEnd) {
      return false;
    }

    return true;
  }

  LibraryNameEnd asLibraryName() {
    if (!isLibraryName()) throw "Not library name";
    return children!.last as LibraryNameEnd;
  }

  bool isPart() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! PartEnd) {
      return false;
    }

    return true;
  }

  PartEnd asPart() {
    if (!isPart()) throw "Not part";
    return children!.last as PartEnd;
  }

  bool isPartOf() {
    if (this is! TopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! UncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! PartOfEnd) {
      return false;
    }

    return true;
  }

  PartOfEnd asPartOf() {
    if (!isPartOf()) throw "Not part of";
    return children!.last as PartOfEnd;
  }

  bool isMetadata() {
    if (this is! MetadataStarEnd) {
      return false;
    }
    if (children!.first is! MetadataStarBegin) {
      return false;
    }
    return true;
  }

  MetadataStarEnd asMetadata() {
    if (!isMetadata()) throw "Not metadata";
    return this as MetadataStarEnd;
  }

  bool isFunctionBody() {
    if (this is BlockFunctionBodyEnd) return true;
    return false;
  }

  BlockFunctionBodyEnd asFunctionBody() {
    if (!isFunctionBody()) throw "Not function body";
    return this as BlockFunctionBodyEnd;
  }

  List<E> recursivelyFind<E extends ParserAstNode>() {
    Set<E> result = {};
    _recursivelyFindInternal(this, result);
    return result.toList();
  }

  static void _recursivelyFindInternal<E extends ParserAstNode>(
    ParserAstNode node,
    Set<E> result,
  ) {
    if (node is E) {
      result.add(node);
      return;
    }
    if (node.children == null) return;
    for (ParserAstNode child in node.children!) {
      _recursivelyFindInternal(child, result);
    }
  }

  void debugDumpNodeRecursively({String indent = ""}) {
    print(
      "$indent${runtimeType} (${what}) "
      "(${deprecatedArguments})",
    );
    if (children == null) return;
    for (ParserAstNode child in children!) {
      child.debugDumpNodeRecursively(indent: "  $indent");
    }
  }
}

// Coverage-ignore(suite): Not run.
extension MetadataStarExtension on MetadataStarEnd {
  List<MetadataEnd> getMetadataEntries() {
    List<MetadataEnd> result = [];
    for (ParserAstNode topLevel in children!) {
      if (topLevel is! MetadataEnd) continue;
      result.add(topLevel);
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension MetadataExtension on MetadataEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension CompilationUnitExtension on CompilationUnitEnd {
  List<TopLevelDeclarationEnd> getClasses() {
    List<TopLevelDeclarationEnd> result = [];
    for (ParserAstNode topLevel in children!) {
      if (!topLevel.isClass()) continue;
      result.add(topLevel as TopLevelDeclarationEnd);
    }
    return result;
  }

  List<TopLevelDeclarationEnd> getMixinDeclarations() {
    List<TopLevelDeclarationEnd> result = [];
    for (ParserAstNode topLevel in children!) {
      if (!topLevel.isMixinDeclaration()) continue;
      result.add(topLevel as TopLevelDeclarationEnd);
    }
    return result;
  }

  List<ImportEnd> getImports() {
    List<ImportEnd> result = [];
    for (ParserAstNode topLevel in children!) {
      if (!topLevel.isImport()) continue;
      result.add(topLevel.children!.last as ImportEnd);
    }
    return result;
  }

  List<ExportEnd> getExports() {
    List<ExportEnd> result = [];
    for (ParserAstNode topLevel in children!) {
      if (!topLevel.isExport()) continue;
      result.add(topLevel.children!.last as ExportEnd);
    }
    return result;
  }

  // List<MetadataStarEnd> getMetadata() {
  //   List<MetadataStarEnd> result = [];
  //   for (ParserAstNode topLevel in children) {
  //     if (!topLevel.isMetadata()) continue;
  //     result.add(topLevel);
  //   }
  //   return result;
  // }

  // List<EnumEnd> getEnums() {
  //   List<EnumEnd> result = [];
  //   for (ParserAstNode topLevel in children) {
  //     if (!topLevel.isEnum()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<FunctionTypeAliasEnd> getTypedefs() {
  //   List<FunctionTypeAliasEnd> result = [];
  //   for (ParserAstNode topLevel in children) {
  //     if (!topLevel.isTypedef()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<MixinDeclarationEnd> getMixinDeclarations() {
  //   List<MixinDeclarationEnd> result = [];
  //   for (ParserAstNode topLevel in children) {
  //     if (!topLevel.isMixinDeclaration()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<TopLevelMethodEnd> getTopLevelMethods() {
  //   List<TopLevelMethodEnd> result = [];
  //   for (ParserAstNode topLevel in children) {
  //     if (!topLevel.isTopLevelMethod()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  CompilationUnitBegin getBegin() {
    return children!.first as CompilationUnitBegin;
  }
}

extension TopLevelDeclarationExtension on TopLevelDeclarationEnd {
  IdentifierHandle getIdentifier() {
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) return child;
    }
    throw "Not found.";
  }

  // Coverage-ignore(suite): Not run.
  ClassDeclarationEnd getClassDeclaration() {
    if (!isClass()) {
      throw "Not a class";
    }
    for (ParserAstNode child in children!) {
      if (child is ClassDeclarationEnd) {
        return child;
      }
    }
    throw "Not found.";
  }
}

// Coverage-ignore(suite): Not run.
extension MixinDeclarationExtension on MixinDeclarationEnd {
  ClassOrMixinOrExtensionBodyEnd getClassOrMixinOrExtensionBody() {
    for (ParserAstNode child in children!) {
      if (child is ClassOrMixinOrExtensionBodyEnd) {
        return child;
      }
    }
    throw "Not found.";
  }

  IdentifierHandle getMixinIdentifier() {
    ParserAstNode? parent = this.parent;
    if (parent is! TopLevelDeclarationEnd) throw "Now nested as expected";
    return parent.getIdentifier();
  }
}

// Coverage-ignore(suite): Not run.
extension NamedMixinApplicationExtension on NamedMixinApplicationEnd {
  IdentifierHandle getMixinIdentifier() {
    ParserAstNode? parent = this.parent;
    if (parent is! TopLevelDeclarationEnd) throw "Now nested as expected";
    return parent.getIdentifier();
  }
}

extension ClassDeclarationExtension on ClassDeclarationEnd {
  // Coverage-ignore(suite): Not run.
  ClassOrMixinOrExtensionBodyEnd getClassOrMixinOrExtensionBody() {
    for (ParserAstNode child in children!) {
      if (child is ClassOrMixinOrExtensionBodyEnd) {
        return child;
      }
    }
    throw "Not found.";
  }

  // Coverage-ignore(suite): Not run.
  ClassExtendsHandle getClassExtends() {
    for (ParserAstNode child in children!) {
      if (child is ClassExtendsHandle) return child;
    }
    throw "Not found.";
  }

  // Coverage-ignore(suite): Not run.
  ImplementsHandle getClassImplements() {
    for (ParserAstNode child in children!) {
      if (child is ImplementsHandle) {
        return child;
      }
    }
    throw "Not found.";
  }

  // Coverage-ignore(suite): Not run.
  ClassWithClauseHandle? getClassWithClause() {
    for (ParserAstNode child in children!) {
      if (child is ClassWithClauseHandle) {
        return child;
      }
    }
    return null;
  }

  IdentifierHandle getClassIdentifier() {
    ParserAstNode? parent = this.parent;
    if (parent is! TopLevelDeclarationEnd) throw "Now nested as expected";
    return parent.getIdentifier();
  }
}

// Coverage-ignore(suite): Not run.
extension ClassOrMixinBodyExtension on ClassOrMixinOrExtensionBodyEnd {
  List<MemberEnd> getMembers() {
    List<MemberEnd> members = [];
    for (ParserAstNode child in children!) {
      if (child is MemberEnd) {
        members.add(child);
      }
    }
    return members;
  }
}

// Coverage-ignore(suite): Not run.
extension MemberExtension on MemberEnd {
  // TODO(jensj): This might not actually be useful - we're doing a lot of if's
  // here, but will then have to do more if's or a switch at the call site to
  // do anything useful with it, which might not be optimal.
  MemberContentType getMemberType() {
    if (isClassConstructor()) return MemberContentType.ClassConstructor;
    if (isClassFactoryMethod()) return MemberContentType.ClassFactoryMethod;
    if (isClassFields()) return MemberContentType.ClassFields;
    if (isClassMethod()) return MemberContentType.ClassMethod;

    if (isMixinConstructor()) return MemberContentType.MixinConstructor;
    if (isMixinFactoryMethod()) return MemberContentType.MixinFactoryMethod;
    if (isMixinFields()) return MemberContentType.MixinFields;
    if (isMixinMethod()) return MemberContentType.MixinMethod;

    if (isExtensionConstructor()) return MemberContentType.ExtensionConstructor;
    if (isExtensionFactoryMethod()) {
      return MemberContentType.ExtensionFactoryMethod;
    }
    if (isExtensionFields()) return MemberContentType.ExtensionFields;
    if (isExtensionMethod()) return MemberContentType.ExtensionMethod;

    if (isExtensionTypeConstructor()) {
      return MemberContentType.ExtensionTypeConstructor;
    }
    if (isExtensionTypeFactoryMethod()) {
      return MemberContentType.ExtensionTypeFactoryMethod;
    }
    if (isExtensionTypeFields()) return MemberContentType.ExtensionTypeFields;
    if (isExtensionTypeMethod()) return MemberContentType.ExtensionTypeMethod;

    if (isEnumConstructor()) return MemberContentType.EnumConstructor;
    if (isEnumFactoryMethod()) return MemberContentType.EnumFactoryMethod;
    if (isEnumFields()) return MemberContentType.EnumFields;
    if (isEnumMethod()) return MemberContentType.EnumMethod;

    if (isClassRecoverableError()) {
      return MemberContentType.ClassRecoverableError;
    }
    if (isExperimentNotEnabled()) return MemberContentType.ExperimentNotEnabled;

    return MemberContentType.Unknown;
  }

  bool isClassConstructor() {
    ParserAstNode child = children![1];
    if (child is ClassConstructorEnd) return true;
    return false;
  }

  ClassConstructorEnd getClassConstructor() {
    ParserAstNode child = children![1];
    if (child is ClassConstructorEnd) return child;
    throw "Not found";
  }

  bool isClassFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is ClassFactoryMethodEnd) return true;
    return false;
  }

  ClassFactoryMethodEnd getClassFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is ClassFactoryMethodEnd) return child;
    throw "Not found";
  }

  bool isClassFields() {
    ParserAstNode child = children![1];
    if (child is ClassFieldsEnd) return true;
    return false;
  }

  ClassFieldsEnd getClassFields() {
    ParserAstNode child = children![1];
    if (child is ClassFieldsEnd) return child;
    throw "Not found";
  }

  bool isMixinFields() {
    ParserAstNode child = children![1];
    if (child is MixinFieldsEnd) return true;
    return false;
  }

  MixinFieldsEnd getMixinFields() {
    ParserAstNode child = children![1];
    if (child is MixinFieldsEnd) return child;
    throw "Not found";
  }

  bool isMixinMethod() {
    ParserAstNode child = children![1];
    if (child is MixinMethodEnd) return true;
    return false;
  }

  MixinMethodEnd getMixinMethod() {
    ParserAstNode child = children![1];
    if (child is MixinMethodEnd) return child;
    throw "Not found";
  }

  bool isMixinFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is MixinFactoryMethodEnd) return true;
    return false;
  }

  MixinFactoryMethodEnd getMixinFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is MixinFactoryMethodEnd) return child;
    throw "Not found";
  }

  bool isMixinConstructor() {
    ParserAstNode child = children![1];
    if (child is MixinConstructorEnd) return true;
    return false;
  }

  MixinConstructorEnd getMixinConstructor() {
    ParserAstNode child = children![1];
    if (child is MixinConstructorEnd) return child;
    throw "Not found";
  }

  bool isClassMethod() {
    ParserAstNode child = children![1];
    if (child is ClassMethodEnd) return true;
    return false;
  }

  ClassMethodEnd getClassMethod() {
    ParserAstNode child = children![1];
    if (child is ClassMethodEnd) return child;
    throw "Not found";
  }

  bool isClassRecoverableError() {
    ParserAstNode child = children![1];
    if (child is RecoverableErrorHandle) return true;
    return false;
  }

  bool isExperimentNotEnabled() {
    ParserAstNode child = children![1];
    if (child is ExperimentNotEnabledHandle) return true;
    return false;
  }

  bool isExtensionMethod() {
    ParserAstNode child = children![1];
    if (child is ExtensionMethodEnd) return true;
    return false;
  }

  ExtensionMethodEnd getExtensionMethod() {
    ParserAstNode child = children![1];
    if (child is ExtensionMethodEnd) return child;
    throw "Not found";
  }

  bool isExtensionFields() {
    ParserAstNode child = children![1];
    if (child is ExtensionFieldsEnd) return true;
    return false;
  }

  ExtensionFieldsEnd getExtensionFields() {
    ParserAstNode child = children![1];
    if (child is ExtensionFieldsEnd) return child;
    throw "Not found";
  }

  bool isExtensionConstructor() {
    ParserAstNode child = children![1];
    if (child is ExtensionConstructorEnd) return true;
    return false;
  }

  ExtensionConstructorEnd getExtensionConstructor() {
    ParserAstNode child = children![1];
    if (child is ExtensionConstructorEnd) return child;
    throw "Not found";
  }

  bool isExtensionFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is ExtensionFactoryMethodEnd) return true;
    return false;
  }

  ExtensionFactoryMethodEnd getExtensionFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is ExtensionFactoryMethodEnd) return child;
    throw "Not found";
  }

  bool isExtensionTypeMethod() {
    ParserAstNode child = children![1];
    if (child is ExtensionTypeMethodEnd) return true;
    return false;
  }

  ExtensionTypeMethodEnd getExtensionTypeMethod() {
    ParserAstNode child = children![1];
    if (child is ExtensionTypeMethodEnd) return child;
    throw "Not found";
  }

  bool isExtensionTypeFields() {
    ParserAstNode child = children![1];
    if (child is ExtensionTypeFieldsEnd) return true;
    return false;
  }

  ExtensionTypeFieldsEnd getExtensionTypeFields() {
    ParserAstNode child = children![1];
    if (child is ExtensionTypeFieldsEnd) return child;
    throw "Not found";
  }

  bool isExtensionTypeConstructor() {
    ParserAstNode child = children![1];
    if (child is ExtensionTypeConstructorEnd) return true;
    return false;
  }

  ExtensionTypeConstructorEnd getExtensionTypeConstructor() {
    ParserAstNode child = children![1];
    if (child is ExtensionTypeConstructorEnd) return child;
    throw "Not found";
  }

  bool isExtensionTypeFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is ExtensionTypeFactoryMethodEnd) return true;
    return false;
  }

  ExtensionTypeFactoryMethodEnd getExtensionTypeFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is ExtensionTypeFactoryMethodEnd) return child;
    throw "Not found";
  }

  bool isEnumMethod() {
    ParserAstNode child = children![1];
    if (child is EnumMethodEnd) return true;
    return false;
  }

  EnumMethodEnd getEnumMethod() {
    ParserAstNode child = children![1];
    if (child is EnumMethodEnd) return child;
    throw "Not found";
  }

  bool isEnumFields() {
    ParserAstNode child = children![1];
    if (child is EnumFieldsEnd) return true;
    return false;
  }

  EnumFieldsEnd getEnumFields() {
    ParserAstNode child = children![1];
    if (child is EnumFieldsEnd) return child;
    throw "Not found";
  }

  bool isEnumConstructor() {
    ParserAstNode child = children![1];
    if (child is EnumConstructorEnd) return true;
    return false;
  }

  EnumConstructorEnd getEnumConstructor() {
    ParserAstNode child = children![1];
    if (child is EnumConstructorEnd) return child;
    throw "Not found";
  }

  bool isEnumFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is EnumFactoryMethodEnd) return true;
    return false;
  }

  EnumFactoryMethodEnd getEnumFactoryMethod() {
    ParserAstNode child = children![1];
    if (child is EnumFactoryMethodEnd) return child;
    throw "Not found";
  }
}

// Coverage-ignore(suite): Not run.
extension MixinFieldsExtension on MixinFieldsEnd {
  List<IdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<IdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      ParserAstNode child = children![i];
      if (child is IdentifierHandle &&
          child.context == IdentifierContext.fieldDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<IdentifierHandle>.filled(count, child);
        } else {
          identifiers[countLeft] = child;
        }
        if (countLeft == 0) break;
      }
    }
    if (countLeft != 0) throw "Didn't find the expected number of identifiers";
    return identifiers ?? [];
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionFieldsExtension on ExtensionFieldsEnd {
  List<IdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<IdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      ParserAstNode child = children![i];
      if (child is IdentifierHandle &&
          child.context == IdentifierContext.fieldDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<IdentifierHandle>.filled(count, child);
        } else {
          identifiers[countLeft] = child;
        }
        if (countLeft == 0) break;
      }
    }
    if (countLeft != 0) throw "Didn't find the expected number of identifiers";
    return identifiers ?? [];
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionTypeFieldsExtension on ExtensionTypeFieldsEnd {
  List<IdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<IdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      ParserAstNode child = children![i];
      if (child is IdentifierHandle &&
          child.context == IdentifierContext.fieldDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<IdentifierHandle>.filled(count, child);
        } else {
          identifiers[countLeft] = child;
        }
        if (countLeft == 0) break;
      }
    }
    if (countLeft != 0) throw "Didn't find the expected number of identifiers";
    return identifiers ?? [];
  }
}

// Coverage-ignore(suite): Not run.
extension EnumFieldsExtension on EnumFieldsEnd {
  List<IdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<IdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      ParserAstNode child = children![i];
      if (child is IdentifierHandle &&
          child.context == IdentifierContext.fieldDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<IdentifierHandle>.filled(count, child);
        } else {
          identifiers[countLeft] = child;
        }
        if (countLeft == 0) break;
      }
    }
    if (countLeft != 0) throw "Didn't find the expected number of identifiers";
    return identifiers ?? [];
  }
}

// Coverage-ignore(suite): Not run.
extension ClassFieldsExtension on ClassFieldsEnd {
  List<IdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<IdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      ParserAstNode child = children![i];
      if (child is IdentifierHandle &&
          child.context == IdentifierContext.fieldDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<IdentifierHandle>.filled(count, child);
        } else {
          identifiers[countLeft] = child;
        }
        if (countLeft == 0) break;
      }
    }
    if (countLeft != 0) throw "Didn't find the expected number of identifiers";
    return identifiers ?? [];
  }

  TypeHandle? getFirstType() {
    for (ParserAstNode child in children!) {
      if (child is TypeHandle) return child;
    }
    return null;
  }

  FieldInitializerEnd? getFieldInitializer() {
    for (ParserAstNode child in children!) {
      if (child is FieldInitializerEnd) return child;
    }
    return null;
  }
}

// Coverage-ignore(suite): Not run.
extension EnumExtension on EnumEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> ids = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) ids.add(child);
    }
    return ids;
  }

  IdentifierHandle getEnumIdentifier() {
    ParserAstNode? parent = this.parent;
    if (parent is! TopLevelDeclarationEnd) throw "Not nested as expected";
    return parent.getIdentifier();
  }

  List<MemberEnd> getMembers() {
    List<MemberEnd> members = [];
    for (ParserAstNode child in children!) {
      if (child is MemberEnd) {
        members.add(child);
      }
    }
    return members;
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionDeclarationExtension on ExtensionDeclarationEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> ids = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) ids.add(child);
    }
    return ids;
  }

  Token? getExtensionName() {
    ExtensionDeclarationBegin begin =
        children!.first as ExtensionDeclarationBegin;
    return begin.name;
  }

  ClassOrMixinOrExtensionBodyEnd getClassOrMixinOrExtensionBody() {
    for (ParserAstNode child in children!) {
      if (child is ClassOrMixinOrExtensionBodyEnd) {
        return child;
      }
    }
    throw "Not found.";
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionTypeDeclarationExtension on ExtensionTypeDeclarationEnd {
  Token? getExtensionTypeName() {
    ExtensionTypeDeclarationBegin begin =
        children!.first as ExtensionTypeDeclarationBegin;
    return begin.name;
  }

  ClassOrMixinOrExtensionBodyEnd getClassOrMixinOrExtensionBody() {
    for (ParserAstNode child in children!) {
      if (child is ClassOrMixinOrExtensionBodyEnd) {
        return child;
      }
    }
    throw "Not found.";
  }
}

extension TopLevelMethodExtension on TopLevelMethodEnd {
  IdentifierHandle getNameIdentifier() {
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        if (child.context == IdentifierContext.topLevelFunctionDeclaration) {
          return child;
        }
      }
    }
    throw "Didn't find the name identifier!";
  }

  // Coverage-ignore(suite): Not run.
  Token getNameIdentifierToken() {
    return getNameIdentifier().token;
  }
}

// Coverage-ignore(suite): Not run.
extension TypedefExtension on TypedefEnd {
  IdentifierHandle getNameIdentifier() {
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        if (child.context == IdentifierContext.typedefDeclaration) {
          return child;
        }
      }
    }
    throw "Didn't find the name identifier!";
  }
}

// Coverage-ignore(suite): Not run.
extension ImportExtension on ImportEnd {
  IdentifierHandle? getImportPrefix() {
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        if (child.context == IdentifierContext.importPrefixDeclaration) {
          return child;
        }
      }
    }
    return null;
  }

  String getImportUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (ParserAstNode child in children!) {
      if (child is LiteralStringEnd) {
        LiteralStringBegin uri = child.children!.single as LiteralStringBegin;
        sb.write(
          unescapeString(
            uri.token.lexeme,
            uri.token,
            const UnescapeErrorListenerDummy(),
          ),
        );
        foundOne = true;
      }
    }
    if (!foundOne) throw "Didn't find any";
    return sb.toString();
  }

  List<String>? getConditionalImportUriStrings() {
    List<String>? result;
    for (ParserAstNode child in children!) {
      if (child is ConditionalUrisEnd) {
        for (ParserAstNode child2 in child.children!) {
          if (child2 is ConditionalUriEnd) {
            LiteralStringEnd end = child2.children!.last as LiteralStringEnd;
            LiteralStringBegin uri = end.children!.single as LiteralStringBegin;
            (result ??= []).add(
              unescapeString(
                uri.token.lexeme,
                uri.token,
                const UnescapeErrorListenerDummy(),
              ),
            );
          }
        }
        return result;
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension ExportExtension on ExportEnd {
  String getExportUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (ParserAstNode child in children!) {
      if (child is LiteralStringEnd) {
        LiteralStringBegin uri = child.children!.single as LiteralStringBegin;
        sb.write(
          unescapeString(
            uri.token.lexeme,
            uri.token,
            const UnescapeErrorListenerDummy(),
          ),
        );
        foundOne = true;
      }
    }
    if (!foundOne) throw "Didn't find any";
    return sb.toString();
  }

  List<String>? getConditionalExportUriStrings() {
    List<String>? result;
    for (ParserAstNode child in children!) {
      if (child is ConditionalUrisEnd) {
        for (ParserAstNode child2 in child.children!) {
          if (child2 is ConditionalUriEnd) {
            LiteralStringEnd end = child2.children!.last as LiteralStringEnd;
            LiteralStringBegin uri = end.children!.single as LiteralStringBegin;
            (result ??= []).add(
              unescapeString(
                uri.token.lexeme,
                uri.token,
                const UnescapeErrorListenerDummy(),
              ),
            );
          }
        }
        return result;
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension PartExtension on PartEnd {
  String getPartUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (ParserAstNode child in children!) {
      if (child is LiteralStringEnd) {
        LiteralStringBegin uri = child.children!.single as LiteralStringBegin;
        sb.write(
          unescapeString(
            uri.token.lexeme,
            uri.token,
            const UnescapeErrorListenerDummy(),
          ),
        );
        foundOne = true;
      }
    }
    if (!foundOne) throw "Didn't find any";
    return sb.toString();
  }
}

// Coverage-ignore(suite): Not run.
extension PartOfExtension on PartOfEnd {
  String? getPartOfUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (ParserAstNode child in children!) {
      if (child is LiteralStringEnd) {
        LiteralStringBegin uri = child.children!.single as LiteralStringBegin;
        sb.write(
          unescapeString(
            uri.token.lexeme,
            uri.token,
            const UnescapeErrorListenerDummy(),
          ),
        );
        foundOne = true;
      }
    }
    if (!foundOne) return null;
    return sb.toString();
  }

  List<String> getPartOfIdentifiers() {
    List<String> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child.token.lexeme);
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension LibraryNameExtension on LibraryNameEnd {
  List<String> getNameIdentifiers() {
    List<String> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child.token.lexeme);
      }
    }
    return result;
  }
}

class UnescapeErrorListenerDummy implements UnescapeErrorListener {
  const UnescapeErrorListenerDummy();

  @override
  // Coverage-ignore(suite): Not run.
  void handleUnescapeError(
    Message message,
    covariant location,
    int offset,
    int length,
  ) {
    // Purposely doesn't do anything.
  }
}

// Coverage-ignore(suite): Not run.
extension TopLevelFieldsExtension on TopLevelFieldsEnd {
  List<IdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<IdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      ParserAstNode child = children![i];
      if (child is IdentifierHandle &&
          child.context == IdentifierContext.topLevelVariableDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<IdentifierHandle>.filled(count, child);
        } else {
          identifiers[countLeft] = child;
        }
        if (countLeft == 0) break;
      }
    }
    if (countLeft != 0) throw "Didn't find the expected number of identifiers";
    return identifiers ?? [];
  }
}

bool _isTypeOrNoType(ParserAstNode node) {
  return node is TypeHandle ||
      node is RecordTypeEnd ||
      node is NoTypeHandle ||
      node is VoidKeywordHandle ||
      node is FunctionTypeEnd;
}

extension ClassMethodExtension on ClassMethodEnd {
  // Coverage-ignore(suite): Not run.
  BlockFunctionBodyEnd? getBlockFunctionBody() {
    for (ParserAstNode child in children!) {
      if (child is BlockFunctionBodyEnd) {
        return child;
      }
    }
    return null;
  }

  Token getNameIdentifierToken() {
    bool foundType = false;
    for (ParserAstNode child in children!) {
      if (_isTypeOrNoType(child)) {
        foundType = true;
      }
      if (foundType && child is IdentifierHandle) {
        return child.token;
      } else if (foundType && child is OperatorNameHandle) {
        // Coverage-ignore-block(suite): Not run.
        return child.token;
      }
    }
    // Coverage-ignore-block(suite): Not run.
    throw "No identifier found: $children";
  }

  String getNameIdentifier() {
    return getNameIdentifierToken().lexeme;
  }
}

// Coverage-ignore(suite): Not run.
extension MixinMethodExtension on MixinMethodEnd {
  Token getNameIdentifierToken() {
    bool foundType = false;
    for (ParserAstNode child in children!) {
      if (_isTypeOrNoType(child)) {
        foundType = true;
      }
      if (foundType && child is IdentifierHandle) {
        return child.token;
      } else if (foundType && child is OperatorNameHandle) {
        return child.token;
      }
    }
    throw "No identifier found: $children";
  }

  String getNameIdentifier() {
    return getNameIdentifierToken().lexeme;
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionMethodExtension on ExtensionMethodEnd {
  Token getNameIdentifierToken() {
    bool foundType = false;
    for (ParserAstNode child in children!) {
      if (_isTypeOrNoType(child)) {
        foundType = true;
      }
      if (foundType && child is IdentifierHandle) {
        return child.token;
      } else if (foundType && child is OperatorNameHandle) {
        return child.token;
      }
    }
    throw "No identifier found: $children";
  }

  String getNameIdentifier() {
    return getNameIdentifierToken().lexeme;
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionTypeMethodExtension on ExtensionTypeMethodEnd {
  Token getNameIdentifierToken() {
    bool foundType = false;
    for (ParserAstNode child in children!) {
      if (_isTypeOrNoType(child)) {
        foundType = true;
      }
      if (foundType && child is IdentifierHandle) {
        return child.token;
      } else if (foundType && child is OperatorNameHandle) {
        return child.token;
      }
    }
    throw "No identifier found: $children";
  }

  String getNameIdentifier() {
    return getNameIdentifierToken().lexeme;
  }
}

// Coverage-ignore(suite): Not run.
extension EnumMethodExtension on EnumMethodEnd {
  String getNameIdentifier() {
    bool foundType = false;
    for (ParserAstNode child in children!) {
      if (_isTypeOrNoType(child)) {
        foundType = true;
      }
      if (foundType && child is IdentifierHandle) {
        return child.token.lexeme;
      } else if (foundType && child is OperatorNameHandle) {
        return child.token.lexeme;
      }
    }
    throw "No identifier found: $children";
  }
}

// Coverage-ignore(suite): Not run.
extension ClassFactoryMethodExtension on ClassFactoryMethodEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      } else if (child is FormalParametersEnd) {
        break;
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension MixinFactoryMethodExtension on MixinFactoryMethodEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      } else if (child is FormalParametersEnd) {
        break;
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionFactoryMethodExtension on ExtensionFactoryMethodEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      } else if (child is FormalParametersEnd) {
        break;
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionTypeFactoryMethodExtension on ExtensionTypeFactoryMethodEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      } else if (child is FormalParametersEnd) {
        break;
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension EnumFactoryMethodExtension on EnumFactoryMethodEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      } else if (child is FormalParametersEnd) {
        break;
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension ClassConstructorExtension on ClassConstructorEnd {
  FormalParametersEnd getFormalParameters() {
    for (ParserAstNode child in children!) {
      if (child is FormalParametersEnd) {
        return child;
      }
    }
    throw "Not found";
  }

  InitializersEnd? getInitializers() {
    for (ParserAstNode child in children!) {
      if (child is InitializersEnd) {
        return child;
      }
    }
    return null;
  }

  BlockFunctionBodyEnd? getBlockFunctionBody() {
    for (ParserAstNode child in children!) {
      if (child is BlockFunctionBodyEnd) {
        return child;
      }
    }
    return null;
  }

  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionConstructorExtension on ExtensionConstructorEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension ExtensionTypeConstructorExtension on ExtensionTypeConstructorEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension EnumConstructorExtension on EnumConstructorEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension MixinConstructorExtension on MixinConstructorEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> result = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) {
        result.add(child);
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension FormalParametersExtension on FormalParametersEnd {
  List<FormalParameterEnd> getFormalParameters() {
    List<FormalParameterEnd> result = [];
    for (ParserAstNode child in children!) {
      if (child is FormalParameterEnd) {
        result.add(child);
      }
    }
    return result;
  }

  OptionalFormalParametersEnd? getOptionalFormalParameters() {
    for (ParserAstNode child in children!) {
      if (child is OptionalFormalParametersEnd) {
        return child;
      }
    }
    return null;
  }
}

// Coverage-ignore(suite): Not run.
extension FormalParameterExtension on FormalParameterEnd {
  FormalParameterBegin getBegin() {
    return children!.first as FormalParameterBegin;
  }
}

// Coverage-ignore(suite): Not run.
extension OptionalFormalParametersExtension on OptionalFormalParametersEnd {
  List<FormalParameterEnd> getFormalParameters() {
    List<FormalParameterEnd> result = [];
    for (ParserAstNode child in children!) {
      if (child is FormalParameterEnd) {
        result.add(child);
      }
    }
    return result;
  }
}

// Coverage-ignore(suite): Not run.
extension InitializersExtension on InitializersEnd {
  List<InitializerEnd> getInitializers() {
    List<InitializerEnd> result = [];
    for (ParserAstNode child in children!) {
      if (child is InitializerEnd) {
        result.add(child);
      }
    }
    return result;
  }

  InitializersBegin getBegin() {
    return children!.first as InitializersBegin;
  }
}

// Coverage-ignore(suite): Not run.
extension InitializerExtension on InitializerEnd {
  InitializerBegin getBegin() {
    return children!.first as InitializerBegin;
  }
}

// Coverage-ignore(suite): Not run.
void main(List<String> args) {
  File f = new File(args[0]);
  Uint8List data = f.readAsBytesSync();
  ParserAstNode ast = getAST(data);
  if (args.length > 1 && args[1] == "--benchmark") {
    Stopwatch stopwatch = new Stopwatch()..start();
    int numRuns = 100;
    for (int i = 0; i < numRuns; i++) {
      ParserAstNode ast2 = getAST(data);
      if (ast.what != ast2.what) {
        throw "Not the same result every time";
      }
    }
    stopwatch.stop();
    print(
      "First $numRuns took ${stopwatch.elapsedMilliseconds} ms "
      "(i.e. ${stopwatch.elapsedMilliseconds / numRuns}ms/iteration)",
    );
    stopwatch = new Stopwatch()..start();
    numRuns = 2500;
    for (int i = 0; i < numRuns; i++) {
      ParserAstNode ast2 = getAST(data);
      if (ast.what != ast2.what) {
        throw "Not the same result every time";
      }
    }
    stopwatch.stop();
    print(
      "Next $numRuns took ${stopwatch.elapsedMilliseconds} ms "
      "(i.e. ${stopwatch.elapsedMilliseconds / numRuns}ms/iteration)",
    );
  } else {
    print(ast);
  }
}

class ParserASTListener extends AbstractParserAstListener {
  @override
  void seen(ParserAstNode entry) {
    switch (entry.type) {
      case ParserAstType.BEGIN:
      case ParserAstType.HANDLE:
        // This just adds stuff.
        data.add(entry);
        break;
      case ParserAstType.END:
        // End should gobble up everything until the corresponding begin (which
        // should be the latest begin).
        int? beginIndex;
        for (int i = data.length - 1; i >= 0; i--) {
          if (data[i].type == ParserAstType.BEGIN) {
            beginIndex = i;
            break;
          }
        }
        if (beginIndex == null) {
          // Coverage-ignore-block(suite): Not run.
          throw "Couldn't find a begin for ${entry.what}. Has:\n"
              "${data.map((e) => "${e.what}: ${e.type}").join("\n")}";
        }
        String begin = data[beginIndex].what;
        String end = entry.what;
        if (begin == end) {
          // Exact match.
        } else if (end == "TopLevelDeclaration" &&
            (begin == "ExtensionDeclarationPrelude" ||
                begin == "ClassOrMixinOrNamedMixinApplicationPrelude" ||
                begin == "TopLevelMember" ||
                begin == "UncategorizedTopLevelDeclaration")) {
          // endTopLevelDeclaration is started by one of
          // beginExtensionDeclarationPrelude,
          // beginClassOrNamedMixinApplicationPrelude
          // beginTopLevelMember or beginUncategorizedTopLevelDeclaration.
        } else if (begin == "Method" &&
            (end == "ClassConstructor" ||
                end == "ClassMethod" ||
                end == "ExtensionConstructor" ||
                end == "ExtensionMethod" ||
                end == "ExtensionTypeConstructor" ||
                end == "ExtensionTypeMethod" ||
                end == "MixinConstructor" ||
                end == "MixinMethod" ||
                end == "EnumConstructor" ||
                end == "EnumMethod")) {
          // beginMethod is ended by one of endClassConstructor,
          // endClassMethod, endExtensionMethod, endMixinConstructor,
          // endMixinMethod, endEnumMethod or endEnumConstructor.
        } else if (begin == "Fields" &&
            (end == "TopLevelFields" ||
                end == "ClassFields" ||
                end == "MixinFields" ||
                end == "ExtensionFields" ||
                end == "ExtensionTypeFields" ||
                end == "EnumFields")) {
          // beginFields is ended by one of endTopLevelFields, endMixinFields,
          // endEnumFields or endExtensionFields.
        } else if (begin == "ForStatement" && end == "ForIn") {
          // beginForStatement is ended by either endForStatement or endForIn.
        } else if (begin == "FactoryMethod" &&
            (end == "ClassFactoryMethod" ||
                end == "MixinFactoryMethod" ||
                end == "ExtensionFactoryMethod" ||
                end == "ExtensionTypeFactoryMethod" ||
                end == "EnumFactoryMethod")) {
          // beginFactoryMethod is ended by either endClassFactoryMethod,
          // endMixinFactoryMethod, endExtensionFactoryMethod, or
          // endEnumFactoryMethod.
        } else if (begin == "ForControlFlow" && (end == "ForInControlFlow")) {
          // beginForControlFlow is ended by either endForControlFlow or
          // endForInControlFlow.
        } else if (begin == "IfControlFlow" && (end == "IfElseControlFlow")) {
          // beginIfControlFlow is ended by either endIfControlFlow or
          // endIfElseControlFlow.
        } else if (begin == "AwaitExpression" &&
            (end == "InvalidAwaitExpression")) {
          // beginAwaitExpression is ended by either endAwaitExpression or
          // endInvalidAwaitExpression.
        } else if (begin == "YieldStatement" &&
            (end == "InvalidYieldStatement")) {
          // beginYieldStatement is ended by either endYieldStatement or
          // endInvalidYieldStatement.
        } else if (begin == "ParenthesizedExpressionOrRecordLiteral" &&
            (end == "ParenthesizedExpression" || end == "RecordLiteral")) {
          // beginParenthesizedExpressionOrRecordLiteral is ended by either
          // endParenthesizedExpression or endRecordLiteral.
        } else {
          // Coverage-ignore-block(suite): Not run.
          throw "Unknown combination: begin$begin and end$end";
        }
        List<ParserAstNode> children = data.sublist(beginIndex);
        for (ParserAstNode child in children) {
          child.parent = entry;
        }
        data.length = beginIndex;
        data.add(entry..children = children);
        break;
    }
  }

  @override
  void reportVarianceModifierNotEnabled(Token? variance) {
    throw new UnimplementedError();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Uri get uri => throw new UnimplementedError();

  @override
  void logEvent(String name) {
    throw new UnimplementedError();
  }
}
