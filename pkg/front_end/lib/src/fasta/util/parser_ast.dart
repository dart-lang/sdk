// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show ClassMemberParser, Parser;

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:_fe_analyzer_shared/src/parser/listener.dart'
    show UnescapeErrorListener;

import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart';

import 'package:_fe_analyzer_shared/src/parser/quote.dart' show unescapeString;

import '../source/diet_parser.dart';

import 'parser_ast_helper.dart';

CompilationUnitEnd getAST(List<int> rawBytes,
    {bool includeBody = true,
    bool includeComments = false,
    bool enableExtensionMethods = false,
    bool enableNonNullable = false,
    bool enableTripleShift = false,
    bool allowPatterns = false,
    List<Token>? languageVersionsSeen}) {
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
      enableExtensionMethods: enableExtensionMethods,
      enableNonNullable: enableNonNullable,
      enableTripleShift: enableTripleShift);

  Utf8BytesScanner scanner = new Utf8BytesScanner(
    bytes,
    includeComments: includeComments,
    configuration: scannerConfiguration,
    languageVersionChanged: (scanner, languageVersion) {
      // For now don't do anything, but having it (making it non-null) means the
      // configuration won't be reset.
      languageVersionsSeen?.add(languageVersion);
    },
  );
  Token firstToken = scanner.tokenize();
  ParserASTListener listener = new ParserASTListener();
  Parser parser;
  if (includeBody) {
    parser = new Parser(
      listener,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      allowPatterns: allowPatterns,
    );
  } else {
    parser = new ClassMemberParser(
      listener,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      allowPatterns: allowPatterns,
    );
  }
  parser.parseUnit(firstToken);
  return listener.data.single as CompilationUnitEnd;
}

/// Best-effort visitor for ParserAstNode that visits top-level entries
/// and class members only (i.e. no bodies, no field initializer content, no
/// names etc).
class ParserAstVisitor {
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
          typedefDecl, typedefDecl.typedefKeyword, typedefDecl.endToken);
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
      visitMixin(declaration, declaration.mixinKeyword, declaration.endToken);
      return;
    }
    if (node is EnumEnd) {
      EnumEnd declaration = node;
      visitEnum(declaration, declaration.enumKeyword,
          declaration.leftBrace.endGroup!);
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
      visitExtension(ext, ext.extensionKeyword, ext.endToken);
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
    if (node is MetadataEnd) {
      MetadataEnd decl = node;
      // TODO(jensj): endToken is not part of the metadata! It's the first token
      // of the next thing.
      visitMetadata(decl, decl.beginToken, decl.endToken.previous!);
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
      TypedefEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitMetadataStar(MetadataStarEnd node) {
    visitChildren(node);
  }

  /// Note: Implementers can call visitChildren on this node.
  void visitClass(
      ClassDeclarationEnd node, Token startInclusive, Token endInclusive) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitTopLevelMethod(
      TopLevelMethodEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassMethod(
      ClassMethodEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionMethod(
      ExtensionMethodEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMixinMethod(
      MixinMethodEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitTopLevelFields(
      TopLevelFieldsEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassFields(
      ClassFieldsEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionFields(
      ExtensionFieldsEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMixinFields(
      MixinFieldsEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitNamedMixin(
      NamedMixinApplicationEnd node, Token startInclusive, Token endInclusive) {
    visitChildren(node);
  }

  /// Note: Implementers can call visitChildren on this node.
  void visitMixin(
      MixinDeclarationEnd node, Token startInclusive, Token endInclusive) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitEnum(EnumEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitLibraryName(
      LibraryNameEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitPart(PartEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitPartOf(PartOfEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitExtension(
      ExtensionDeclarationEnd node, Token startInclusive, Token endInclusive) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassConstructor(
      ClassConstructorEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionConstructor(
      ExtensionConstructorEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassFactoryMethod(
      ClassFactoryMethodEnd node, Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionFactoryMethod(ExtensionFactoryMethodEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMetadata(
      MetadataEnd node, Token startInclusive, Token endInclusive) {}
}

extension GeneralASTContentExtension on ParserAstNode {
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
      ParserAstNode node, Set<E> result) {
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
    print("$indent${runtimeType} (${what}) "
        "(${deprecatedArguments})");
    if (children == null) return;
    for (ParserAstNode child in children!) {
      child.debugDumpNodeRecursively(indent: "  $indent");
    }
  }
}

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

extension MixinDeclarationExtension on MixinDeclarationEnd {
  ClassOrMixinOrExtensionBodyEnd getClassOrMixinOrExtensionBody() {
    for (ParserAstNode child in children!) {
      if (child is ClassOrMixinOrExtensionBodyEnd) {
        return child;
      }
    }
    throw "Not found.";
  }
}

extension ClassDeclarationExtension on ClassDeclarationEnd {
  ClassOrMixinOrExtensionBodyEnd getClassOrMixinOrExtensionBody() {
    for (ParserAstNode child in children!) {
      if (child is ClassOrMixinOrExtensionBodyEnd) {
        return child;
      }
    }
    throw "Not found.";
  }

  ClassExtendsHandle getClassExtends() {
    for (ParserAstNode child in children!) {
      if (child is ClassExtendsHandle) return child;
    }
    throw "Not found.";
  }

  ImplementsHandle getClassImplements() {
    for (ParserAstNode child in children!) {
      if (child is ImplementsHandle) {
        return child;
      }
    }
    throw "Not found.";
  }

  ClassWithClauseHandle? getClassWithClause() {
    for (ParserAstNode child in children!) {
      if (child is ClassWithClauseHandle) {
        return child;
      }
    }
    return null;
  }
}

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

extension MemberExtension on MemberEnd {
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
}

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

extension EnumExtension on EnumEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> ids = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) ids.add(child);
    }
    return ids;
  }
}

extension ExtensionDeclarationExtension on ExtensionDeclarationEnd {
  List<IdentifierHandle> getIdentifiers() {
    List<IdentifierHandle> ids = [];
    for (ParserAstNode child in children!) {
      if (child is IdentifierHandle) ids.add(child);
    }
    return ids;
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
}

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
        sb.write(unescapeString(
            uri.token.lexeme, uri.token, const UnescapeErrorListenerDummy()));
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
            (result ??= []).add(unescapeString(uri.token.lexeme, uri.token,
                const UnescapeErrorListenerDummy()));
          }
        }
        return result;
      }
    }
    return result;
  }
}

extension ExportExtension on ExportEnd {
  String getExportUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (ParserAstNode child in children!) {
      if (child is LiteralStringEnd) {
        LiteralStringBegin uri = child.children!.single as LiteralStringBegin;
        sb.write(unescapeString(
            uri.token.lexeme, uri.token, const UnescapeErrorListenerDummy()));
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
            (result ??= []).add(unescapeString(uri.token.lexeme, uri.token,
                const UnescapeErrorListenerDummy()));
          }
        }
        return result;
      }
    }
    return result;
  }
}

extension PartExtension on PartEnd {
  String getPartUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (ParserAstNode child in children!) {
      if (child is LiteralStringEnd) {
        LiteralStringBegin uri = child.children!.single as LiteralStringBegin;
        sb.write(unescapeString(
            uri.token.lexeme, uri.token, const UnescapeErrorListenerDummy()));
        foundOne = true;
      }
    }
    if (!foundOne) throw "Didn't find any";
    return sb.toString();
  }
}

class UnescapeErrorListenerDummy implements UnescapeErrorListener {
  const UnescapeErrorListenerDummy();

  @override
  void handleUnescapeError(
      Message message, covariant location, int offset, int length) {
    // Purposely doesn't do anything.
  }
}

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

extension ClassMethodExtension on ClassMethodEnd {
  BlockFunctionBodyEnd? getBlockFunctionBody() {
    for (ParserAstNode child in children!) {
      if (child is BlockFunctionBodyEnd) {
        return child;
      }
    }
    return null;
  }

  String getNameIdentifier() {
    bool foundType = false;
    for (ParserAstNode child in children!) {
      if (child is TypeHandle ||
          child is NoTypeHandle ||
          child is VoidKeywordHandle ||
          child is FunctionTypeEnd) {
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

extension MixinMethodExtension on MixinMethodEnd {
  String getNameIdentifier() {
    bool foundType = false;
    for (ParserAstNode child in children!) {
      if (child is TypeHandle ||
          child is NoTypeHandle ||
          child is VoidKeywordHandle ||
          child is FunctionTypeEnd) {
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

extension ExtensionMethodExtension on ExtensionMethodEnd {
  String getNameIdentifier() {
    bool foundType = false;
    for (ParserAstNode child in children!) {
      if (child is TypeHandle ||
          child is NoTypeHandle ||
          child is VoidKeywordHandle ||
          child is FunctionTypeEnd) {
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

extension FormalParameterExtension on FormalParameterEnd {
  FormalParameterBegin getBegin() {
    return children!.first as FormalParameterBegin;
  }
}

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

extension InitializerExtension on InitializerEnd {
  InitializerBegin getBegin() {
    return children!.first as InitializerBegin;
  }
}

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
    print("First $numRuns took ${stopwatch.elapsedMilliseconds} ms "
        "(i.e. ${stopwatch.elapsedMilliseconds / numRuns}ms/iteration)");
    stopwatch = new Stopwatch()..start();
    numRuns = 2500;
    for (int i = 0; i < numRuns; i++) {
      ParserAstNode ast2 = getAST(data);
      if (ast.what != ast2.what) {
        throw "Not the same result every time";
      }
    }
    stopwatch.stop();
    print("Next $numRuns took ${stopwatch.elapsedMilliseconds} ms "
        "(i.e. ${stopwatch.elapsedMilliseconds / numRuns}ms/iteration)");
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
                end == "EnumFields")) {
          // beginFields is ended by one of endTopLevelFields, endMixinFields,
          // endEnumFields or endExtensionFields.
        } else if (begin == "ForStatement" && end == "ForIn") {
          // beginForStatement is ended by either endForStatement or endForIn.
        } else if (begin == "FactoryMethod" &&
            (end == "ClassFactoryMethod" ||
                end == "MixinFactoryMethod" ||
                end == "ExtensionFactoryMethod" ||
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
  Uri get uri => throw new UnimplementedError();

  @override
  void logEvent(String name) {
    throw new UnimplementedError();
  }
}
