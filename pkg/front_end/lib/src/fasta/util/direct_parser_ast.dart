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

import 'direct_parser_ast_helper.dart';

DirectParserASTContentCompilationUnitEnd getAST(List<int> rawBytes,
    {bool includeBody: true,
    bool includeComments: false,
    bool enableExtensionMethods: false,
    bool enableNonNullable: false,
    bool enableTripleShift: false,
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
  // ignore: unnecessary_null_comparison
  if (firstToken == null) {
    throw "firstToken is null";
  }

  DirectParserASTListener listener = new DirectParserASTListener();
  Parser parser;
  if (includeBody) {
    parser = new Parser(listener,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
  } else {
    parser = new ClassMemberParser(listener,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
  }
  parser.parseUnit(firstToken);
  return listener.data.single as DirectParserASTContentCompilationUnitEnd;
}

/// Best-effort visitor for DirectParserASTContent that visits top-level entries
/// and class members only (i.e. no bodies, no field initializer content, no
/// names etc).
class DirectParserASTContentVisitor {
  void accept(DirectParserASTContent node) {
    if (node is DirectParserASTContentCompilationUnitEnd ||
        node is DirectParserASTContentTopLevelDeclarationEnd ||
        node is DirectParserASTContentClassOrMixinOrExtensionBodyEnd ||
        node is DirectParserASTContentMemberEnd) {
      visitChildren(node);
      return;
    }

    if (node.type == DirectParserASTType.BEGIN) {
      // Ignored. These are basically just dummy nodes anyway.
      assert(node.children == null);
      return;
    }
    if (node.type == DirectParserASTType.HANDLE) {
      // Ignored at least for know.
      assert(node.children == null);
      return;
    }
    if (node is DirectParserASTContentTypeVariablesEnd ||
        node is DirectParserASTContentTypeArgumentsEnd ||
        node is DirectParserASTContentTypeListEnd ||
        node is DirectParserASTContentFunctionTypeEnd ||
        node is DirectParserASTContentBlockEnd) {
      // Ignored at least for know.
      return;
    }
    if (node is DirectParserASTContentMetadataStarEnd) {
      DirectParserASTContentMetadataStarEnd metadata = node;
      visitMetadataStar(metadata);
      return;
    }
    if (node is DirectParserASTContentTypedefEnd) {
      DirectParserASTContentTypedefEnd typedefDecl = node;
      visitTypedef(
          typedefDecl, typedefDecl.typedefKeyword, typedefDecl.endToken);
      return;
    }
    if (node is DirectParserASTContentClassDeclarationEnd) {
      DirectParserASTContentClassDeclarationEnd cls = node;
      visitClass(cls, cls.beginToken, cls.endToken);
      return;
    }
    if (node is DirectParserASTContentTopLevelMethodEnd) {
      DirectParserASTContentTopLevelMethodEnd method = node;
      visitTopLevelMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is DirectParserASTContentClassMethodEnd) {
      DirectParserASTContentClassMethodEnd method = node;
      visitClassMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is DirectParserASTContentExtensionMethodEnd) {
      DirectParserASTContentExtensionMethodEnd method = node;
      visitExtensionMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is DirectParserASTContentMixinMethodEnd) {
      DirectParserASTContentMixinMethodEnd method = node;
      visitMixinMethod(method, method.beginToken, method.endToken);
      return;
    }
    if (node is DirectParserASTContentImportEnd) {
      DirectParserASTContentImportEnd import = node;
      visitImport(import, import.importKeyword, import.semicolon);
      return;
    }
    if (node is DirectParserASTContentExportEnd) {
      DirectParserASTContentExportEnd export = node;
      visitExport(export, export.exportKeyword, export.semicolon);
      return;
    }
    if (node is DirectParserASTContentTopLevelFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      DirectParserASTContentTopLevelFieldsEnd fields = node;
      visitTopLevelFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is DirectParserASTContentClassFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      DirectParserASTContentClassFieldsEnd fields = node;
      visitClassFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is DirectParserASTContentExtensionFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      DirectParserASTContentExtensionFieldsEnd fields = node;
      visitExtensionFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is DirectParserASTContentMixinFieldsEnd) {
      // TODO(jensj): Possibly this could go into more details too
      // (e.g. to split up a field declaration).
      DirectParserASTContentMixinFieldsEnd fields = node;
      visitMixinFields(fields, fields.beginToken, fields.endToken);
      return;
    }
    if (node is DirectParserASTContentNamedMixinApplicationEnd) {
      DirectParserASTContentNamedMixinApplicationEnd namedMixin = node;
      visitNamedMixin(namedMixin, namedMixin.begin, namedMixin.endToken);
      return;
    }
    if (node is DirectParserASTContentMixinDeclarationEnd) {
      DirectParserASTContentMixinDeclarationEnd declaration = node;
      visitMixin(declaration, declaration.mixinKeyword, declaration.endToken);
      return;
    }
    if (node is DirectParserASTContentEnumEnd) {
      DirectParserASTContentEnumEnd declaration = node;
      visitEnum(declaration, declaration.enumKeyword,
          declaration.leftBrace.endGroup!);
      return;
    }
    if (node is DirectParserASTContentLibraryNameEnd) {
      DirectParserASTContentLibraryNameEnd name = node;
      visitLibraryName(name, name.libraryKeyword, name.semicolon);
      return;
    }
    if (node is DirectParserASTContentPartEnd) {
      DirectParserASTContentPartEnd part = node;
      visitPart(part, part.partKeyword, part.semicolon);
      return;
    }
    if (node is DirectParserASTContentPartOfEnd) {
      DirectParserASTContentPartOfEnd partOf = node;
      visitPartOf(partOf, partOf.partKeyword, partOf.semicolon);
      return;
    }
    if (node is DirectParserASTContentExtensionDeclarationEnd) {
      DirectParserASTContentExtensionDeclarationEnd ext = node;
      visitExtension(ext, ext.extensionKeyword, ext.endToken);
      return;
    }
    if (node is DirectParserASTContentClassConstructorEnd) {
      DirectParserASTContentClassConstructorEnd decl = node;
      visitClassConstructor(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is DirectParserASTContentExtensionConstructorEnd) {
      DirectParserASTContentExtensionConstructorEnd decl = node;
      visitExtensionConstructor(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is DirectParserASTContentClassFactoryMethodEnd) {
      DirectParserASTContentClassFactoryMethodEnd decl = node;
      visitClassFactoryMethod(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is DirectParserASTContentExtensionFactoryMethodEnd) {
      DirectParserASTContentExtensionFactoryMethodEnd decl = node;
      visitExtensionFactoryMethod(decl, decl.beginToken, decl.endToken);
      return;
    }
    if (node is DirectParserASTContentMetadataEnd) {
      DirectParserASTContentMetadataEnd decl = node;
      // TODO(jensj): endToken is not part of the metadata! It's the first token
      // of the next thing.
      visitMetadata(decl, decl.beginToken, decl.endToken.previous!);
      return;
    }

    throw "Unknown: $node (${node.runtimeType} @ ${node.what})";
  }

  void visitChildren(DirectParserASTContent node) {
    if (node.children == null) return;
    final int numChildren = node.children!.length;
    for (int i = 0; i < numChildren; i++) {
      DirectParserASTContent child = node.children![i];
      accept(child);
    }
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitImport(DirectParserASTContentImportEnd node, Token startInclusive,
      Token? endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExport(DirectParserASTContentExportEnd node, Token startInclusive,
      Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitTypedef(DirectParserASTContentTypedefEnd node, Token startInclusive,
      Token endInclusive) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitMetadataStar(DirectParserASTContentMetadataStarEnd node) {
    visitChildren(node);
  }

  /// Note: Implementers can call visitChildren on this node.
  void visitClass(DirectParserASTContentClassDeclarationEnd node,
      Token startInclusive, Token endInclusive) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitTopLevelMethod(DirectParserASTContentTopLevelMethodEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassMethod(DirectParserASTContentClassMethodEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionMethod(DirectParserASTContentExtensionMethodEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMixinMethod(DirectParserASTContentMixinMethodEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitTopLevelFields(DirectParserASTContentTopLevelFieldsEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassFields(DirectParserASTContentClassFieldsEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionFields(DirectParserASTContentExtensionFieldsEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMixinFields(DirectParserASTContentMixinFieldsEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitNamedMixin(DirectParserASTContentNamedMixinApplicationEnd node,
      Token startInclusive, Token endInclusive) {
    visitChildren(node);
  }

  /// Note: Implementers can call visitChildren on this node.
  void visitMixin(DirectParserASTContentMixinDeclarationEnd node,
      Token startInclusive, Token endInclusive) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitEnum(DirectParserASTContentEnumEnd node, Token startInclusive,
      Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitLibraryName(DirectParserASTContentLibraryNameEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitPart(DirectParserASTContentPartEnd node, Token startInclusive,
      Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitPartOf(DirectParserASTContentPartOfEnd node, Token startInclusive,
      Token endInclusive) {}

  /// Note: Implementers can call visitChildren on this node.
  void visitExtension(DirectParserASTContentExtensionDeclarationEnd node,
      Token startInclusive, Token endInclusive) {
    visitChildren(node);
  }

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassConstructor(DirectParserASTContentClassConstructorEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionConstructor(
      DirectParserASTContentExtensionConstructorEnd node,
      Token startInclusive,
      Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitClassFactoryMethod(DirectParserASTContentClassFactoryMethodEnd node,
      Token startInclusive, Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitExtensionFactoryMethod(
      DirectParserASTContentExtensionFactoryMethodEnd node,
      Token startInclusive,
      Token endInclusive) {}

  /// Note: Implementers are NOT expected to call visitChildren on this node.
  void visitMetadata(DirectParserASTContentMetadataEnd node,
      Token startInclusive, Token endInclusive) {}
}

extension GeneralASTContentExtension on DirectParserASTContent {
  bool isClass() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        // ignore: lines_longer_than_80_chars
        is! DirectParserASTContentClassOrMixinOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentClassDeclarationEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentClassDeclarationEnd asClass() {
    if (!isClass()) throw "Not class";
    return children!.last as DirectParserASTContentClassDeclarationEnd;
  }

  bool isImport() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentImportEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentImportEnd asImport() {
    if (!isImport()) throw "Not import";
    return children!.last as DirectParserASTContentImportEnd;
  }

  bool isExport() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentExportEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentExportEnd asExport() {
    if (!isExport()) throw "Not export";
    return children!.last as DirectParserASTContentExportEnd;
  }

  bool isEnum() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentEnumEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentEnumEnd asEnum() {
    if (!isEnum()) throw "Not enum";
    return children!.last as DirectParserASTContentEnumEnd;
  }

  bool isTypedef() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentTypedefEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentTypedefEnd asTypedef() {
    if (!isTypedef()) throw "Not typedef";
    return children!.last as DirectParserASTContentTypedefEnd;
  }

  bool isScript() {
    if (this is! DirectParserASTContentScriptHandle) {
      return false;
    }
    return true;
  }

  DirectParserASTContentScriptHandle asScript() {
    if (!isScript()) throw "Not script";
    return this as DirectParserASTContentScriptHandle;
  }

  bool isExtension() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentExtensionDeclarationPreludeBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentExtensionDeclarationEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentExtensionDeclarationEnd asExtension() {
    if (!isExtension()) throw "Not extension";
    return children!.last as DirectParserASTContentExtensionDeclarationEnd;
  }

  bool isInvalidTopLevelDeclaration() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! DirectParserASTContentTopLevelMemberBegin) {
      return false;
    }
    if (children!.last
        is! DirectParserASTContentInvalidTopLevelDeclarationHandle) {
      return false;
    }

    return true;
  }

  bool isRecoverableError() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentRecoverableErrorHandle) {
      return false;
    }

    return true;
  }

  bool isRecoverImport() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentRecoverImportHandle) {
      return false;
    }

    return true;
  }

  bool isMixinDeclaration() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        // ignore: lines_longer_than_80_chars
        is! DirectParserASTContentClassOrMixinOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentMixinDeclarationEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentMixinDeclarationEnd asMixinDeclaration() {
    if (!isMixinDeclaration()) throw "Not mixin declaration";
    return children!.last as DirectParserASTContentMixinDeclarationEnd;
  }

  bool isNamedMixinDeclaration() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        // ignore: lines_longer_than_80_chars
        is! DirectParserASTContentClassOrMixinOrNamedMixinApplicationPreludeBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentNamedMixinApplicationEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentNamedMixinApplicationEnd asNamedMixinDeclaration() {
    if (!isNamedMixinDeclaration()) throw "Not named mixin declaration";
    return children!.last as DirectParserASTContentNamedMixinApplicationEnd;
  }

  bool isTopLevelMethod() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! DirectParserASTContentTopLevelMemberBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentTopLevelMethodEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentTopLevelMethodEnd asTopLevelMethod() {
    if (!isTopLevelMethod()) throw "Not top level method";
    return children!.last as DirectParserASTContentTopLevelMethodEnd;
  }

  bool isTopLevelFields() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first is! DirectParserASTContentTopLevelMemberBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentTopLevelFieldsEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentTopLevelFieldsEnd asTopLevelFields() {
    if (!isTopLevelFields()) throw "Not top level fields";
    return children!.last as DirectParserASTContentTopLevelFieldsEnd;
  }

  bool isLibraryName() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentLibraryNameEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentLibraryNameEnd asLibraryName() {
    if (!isLibraryName()) throw "Not library name";
    return children!.last as DirectParserASTContentLibraryNameEnd;
  }

  bool isPart() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentPartEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentPartEnd asPart() {
    if (!isPart()) throw "Not part";
    return children!.last as DirectParserASTContentPartEnd;
  }

  bool isPartOf() {
    if (this is! DirectParserASTContentTopLevelDeclarationEnd) {
      return false;
    }
    if (children!.first
        is! DirectParserASTContentUncategorizedTopLevelDeclarationBegin) {
      return false;
    }
    if (children!.last is! DirectParserASTContentPartOfEnd) {
      return false;
    }

    return true;
  }

  DirectParserASTContentPartOfEnd asPartOf() {
    if (!isPartOf()) throw "Not part of";
    return children!.last as DirectParserASTContentPartOfEnd;
  }

  bool isMetadata() {
    if (this is! DirectParserASTContentMetadataStarEnd) {
      return false;
    }
    if (children!.first is! DirectParserASTContentMetadataStarBegin) {
      return false;
    }
    return true;
  }

  DirectParserASTContentMetadataStarEnd asMetadata() {
    if (!isMetadata()) throw "Not metadata";
    return this as DirectParserASTContentMetadataStarEnd;
  }

  bool isFunctionBody() {
    if (this is DirectParserASTContentBlockFunctionBodyEnd) return true;
    return false;
  }

  DirectParserASTContentBlockFunctionBodyEnd asFunctionBody() {
    if (!isFunctionBody()) throw "Not function body";
    return this as DirectParserASTContentBlockFunctionBodyEnd;
  }

  List<E> recursivelyFind<E extends DirectParserASTContent>() {
    Set<E> result = {};
    _recursivelyFindInternal(this, result);
    return result.toList();
  }

  static void _recursivelyFindInternal<E extends DirectParserASTContent>(
      DirectParserASTContent node, Set<E> result) {
    if (node is E) {
      result.add(node);
      return;
    }
    if (node.children == null) return;
    for (DirectParserASTContent child in node.children!) {
      _recursivelyFindInternal(child, result);
    }
  }

  void debugDumpNodeRecursively({String indent = ""}) {
    print("$indent${runtimeType} (${what}) "
        "(${deprecatedArguments})");
    if (children == null) return;
    for (DirectParserASTContent child in children!) {
      child.debugDumpNodeRecursively(indent: "  $indent");
    }
  }
}

extension MetadataStarExtension on DirectParserASTContentMetadataStarEnd {
  List<DirectParserASTContentMetadataEnd> getMetadataEntries() {
    List<DirectParserASTContentMetadataEnd> result = [];
    for (DirectParserASTContent topLevel in children!) {
      if (topLevel is! DirectParserASTContentMetadataEnd) continue;
      result.add(topLevel);
    }
    return result;
  }
}

extension CompilationUnitExtension on DirectParserASTContentCompilationUnitEnd {
  List<DirectParserASTContentTopLevelDeclarationEnd> getClasses() {
    List<DirectParserASTContentTopLevelDeclarationEnd> result = [];
    for (DirectParserASTContent topLevel in children!) {
      if (!topLevel.isClass()) continue;
      result.add(topLevel as DirectParserASTContentTopLevelDeclarationEnd);
    }
    return result;
  }

  List<DirectParserASTContentTopLevelDeclarationEnd> getMixinDeclarations() {
    List<DirectParserASTContentTopLevelDeclarationEnd> result = [];
    for (DirectParserASTContent topLevel in children!) {
      if (!topLevel.isMixinDeclaration()) continue;
      result.add(topLevel as DirectParserASTContentTopLevelDeclarationEnd);
    }
    return result;
  }

  List<DirectParserASTContentImportEnd> getImports() {
    List<DirectParserASTContentImportEnd> result = [];
    for (DirectParserASTContent topLevel in children!) {
      if (!topLevel.isImport()) continue;
      result.add(topLevel.children!.last as DirectParserASTContentImportEnd);
    }
    return result;
  }

  List<DirectParserASTContentExportEnd> getExports() {
    List<DirectParserASTContentExportEnd> result = [];
    for (DirectParserASTContent topLevel in children!) {
      if (!topLevel.isExport()) continue;
      result.add(topLevel.children!.last as DirectParserASTContentExportEnd);
    }
    return result;
  }

  // List<DirectParserASTContentMetadataStarEnd> getMetadata() {
  //   List<DirectParserASTContentMetadataStarEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isMetadata()) continue;
  //     result.add(topLevel);
  //   }
  //   return result;
  // }

  // List<DirectParserASTContentEnumEnd> getEnums() {
  //   List<DirectParserASTContentEnumEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isEnum()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<DirectParserASTContentFunctionTypeAliasEnd> getTypedefs() {
  //   List<DirectParserASTContentFunctionTypeAliasEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isTypedef()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<DirectParserASTContentMixinDeclarationEnd> getMixinDeclarations() {
  //   List<DirectParserASTContentMixinDeclarationEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isMixinDeclaration()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  // List<DirectParserASTContentTopLevelMethodEnd> getTopLevelMethods() {
  //   List<DirectParserASTContentTopLevelMethodEnd> result = [];
  //   for (DirectParserASTContent topLevel in children) {
  //     if (!topLevel.isTopLevelMethod()) continue;
  //     result.add(topLevel.children.last);
  //   }
  //   return result;
  // }

  DirectParserASTContentCompilationUnitBegin getBegin() {
    return children!.first as DirectParserASTContentCompilationUnitBegin;
  }
}

extension TopLevelDeclarationExtension
    on DirectParserASTContentTopLevelDeclarationEnd {
  DirectParserASTContentIdentifierHandle getIdentifier() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentIdentifierHandle) return child;
    }
    throw "Not found.";
  }

  DirectParserASTContentClassDeclarationEnd getClassDeclaration() {
    if (!isClass()) {
      throw "Not a class";
    }
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentClassDeclarationEnd) {
        return child;
      }
    }
    throw "Not found.";
  }
}

extension MixinDeclarationExtension
    on DirectParserASTContentMixinDeclarationEnd {
  DirectParserASTContentClassOrMixinOrExtensionBodyEnd
      getClassOrMixinOrExtensionBody() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentClassOrMixinOrExtensionBodyEnd) {
        return child;
      }
    }
    throw "Not found.";
  }
}

extension ClassDeclarationExtension
    on DirectParserASTContentClassDeclarationEnd {
  DirectParserASTContentClassOrMixinOrExtensionBodyEnd
      getClassOrMixinOrExtensionBody() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentClassOrMixinOrExtensionBodyEnd) {
        return child;
      }
    }
    throw "Not found.";
  }

  DirectParserASTContentClassExtendsHandle getClassExtends() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentClassExtendsHandle) return child;
    }
    throw "Not found.";
  }

  DirectParserASTContentClassOrMixinImplementsHandle getClassImplements() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentClassOrMixinImplementsHandle) {
        return child;
      }
    }
    throw "Not found.";
  }

  DirectParserASTContentClassWithClauseHandle? getClassWithClause() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentClassWithClauseHandle) {
        return child;
      }
    }
    return null;
  }
}

extension ClassOrMixinBodyExtension
    on DirectParserASTContentClassOrMixinOrExtensionBodyEnd {
  List<DirectParserASTContentMemberEnd> getMembers() {
    List<DirectParserASTContentMemberEnd> members = [];
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentMemberEnd) {
        members.add(child);
      }
    }
    return members;
  }
}

extension MemberExtension on DirectParserASTContentMemberEnd {
  bool isClassConstructor() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentClassConstructorEnd) return true;
    return false;
  }

  DirectParserASTContentClassConstructorEnd getClassConstructor() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentClassConstructorEnd) return child;
    throw "Not found";
  }

  bool isClassFactoryMethod() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentClassFactoryMethodEnd) return true;
    return false;
  }

  DirectParserASTContentClassFactoryMethodEnd getClassFactoryMethod() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentClassFactoryMethodEnd) return child;
    throw "Not found";
  }

  bool isClassFields() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentClassFieldsEnd) return true;
    return false;
  }

  DirectParserASTContentClassFieldsEnd getClassFields() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentClassFieldsEnd) return child;
    throw "Not found";
  }

  bool isMixinFields() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentMixinFieldsEnd) return true;
    return false;
  }

  DirectParserASTContentMixinFieldsEnd getMixinFields() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentMixinFieldsEnd) return child;
    throw "Not found";
  }

  bool isMixinMethod() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentMixinMethodEnd) return true;
    return false;
  }

  DirectParserASTContentMixinMethodEnd getMixinMethod() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentMixinMethodEnd) return child;
    throw "Not found";
  }

  bool isMixinFactoryMethod() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentMixinFactoryMethodEnd) return true;
    return false;
  }

  DirectParserASTContentMixinFactoryMethodEnd getMixinFactoryMethod() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentMixinFactoryMethodEnd) return child;
    throw "Not found";
  }

  bool isMixinConstructor() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentMixinConstructorEnd) return true;
    return false;
  }

  DirectParserASTContentMixinConstructorEnd getMixinConstructor() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentMixinConstructorEnd) return child;
    throw "Not found";
  }

  bool isClassMethod() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentClassMethodEnd) return true;
    return false;
  }

  DirectParserASTContentClassMethodEnd getClassMethod() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentClassMethodEnd) return child;
    throw "Not found";
  }

  bool isClassRecoverableError() {
    DirectParserASTContent child = children![1];
    if (child is DirectParserASTContentRecoverableErrorHandle) return true;
    return false;
  }
}

extension MixinFieldsExtension on DirectParserASTContentMixinFieldsEnd {
  List<DirectParserASTContentIdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<DirectParserASTContentIdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      DirectParserASTContent child = children![i];
      if (child is DirectParserASTContentIdentifierHandle &&
          child.context == IdentifierContext.fieldDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<DirectParserASTContentIdentifierHandle>.filled(
              count, child);
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

extension ExtensionFieldsExtension on DirectParserASTContentExtensionFieldsEnd {
  List<DirectParserASTContentIdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<DirectParserASTContentIdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      DirectParserASTContent child = children![i];
      if (child is DirectParserASTContentIdentifierHandle &&
          child.context == IdentifierContext.fieldDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<DirectParserASTContentIdentifierHandle>.filled(
              count, child);
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

extension ClassFieldsExtension on DirectParserASTContentClassFieldsEnd {
  List<DirectParserASTContentIdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<DirectParserASTContentIdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      DirectParserASTContent child = children![i];
      if (child is DirectParserASTContentIdentifierHandle &&
          child.context == IdentifierContext.fieldDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<DirectParserASTContentIdentifierHandle>.filled(
              count, child);
        } else {
          identifiers[countLeft] = child;
        }
        if (countLeft == 0) break;
      }
    }
    if (countLeft != 0) throw "Didn't find the expected number of identifiers";
    return identifiers ?? [];
  }

  DirectParserASTContentTypeHandle? getFirstType() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentTypeHandle) return child;
    }
    return null;
  }

  DirectParserASTContentFieldInitializerEnd? getFieldInitializer() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentFieldInitializerEnd) return child;
    }
    return null;
  }
}

extension EnumExtension on DirectParserASTContentEnumEnd {
  List<DirectParserASTContentIdentifierHandle> getIdentifiers() {
    List<DirectParserASTContentIdentifierHandle> ids = [];
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentIdentifierHandle) ids.add(child);
    }
    return ids;
  }
}

extension ExtensionDeclarationExtension
    on DirectParserASTContentExtensionDeclarationEnd {
  List<DirectParserASTContentIdentifierHandle> getIdentifiers() {
    List<DirectParserASTContentIdentifierHandle> ids = [];
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentIdentifierHandle) ids.add(child);
    }
    return ids;
  }
}

extension TopLevelMethodExtension on DirectParserASTContentTopLevelMethodEnd {
  DirectParserASTContentIdentifierHandle getNameIdentifier() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentIdentifierHandle) {
        if (child.context == IdentifierContext.topLevelFunctionDeclaration) {
          return child;
        }
      }
    }
    throw "Didn't find the name identifier!";
  }
}

extension TypedefExtension on DirectParserASTContentTypedefEnd {
  DirectParserASTContentIdentifierHandle getNameIdentifier() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentIdentifierHandle) {
        if (child.context == IdentifierContext.typedefDeclaration) {
          return child;
        }
      }
    }
    throw "Didn't find the name identifier!";
  }
}

extension ImportExtension on DirectParserASTContentImportEnd {
  DirectParserASTContentIdentifierHandle? getImportPrefix() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentIdentifierHandle) {
        if (child.context == IdentifierContext.importPrefixDeclaration) {
          return child;
        }
      }
    }
  }

  String getImportUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentLiteralStringEnd) {
        DirectParserASTContentLiteralStringBegin uri =
            child.children!.single as DirectParserASTContentLiteralStringBegin;
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
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentConditionalUrisEnd) {
        for (DirectParserASTContent child2 in child.children!) {
          if (child2 is DirectParserASTContentConditionalUriEnd) {
            DirectParserASTContentLiteralStringEnd end =
                child2.children!.last as DirectParserASTContentLiteralStringEnd;
            DirectParserASTContentLiteralStringBegin uri = end.children!.single
                as DirectParserASTContentLiteralStringBegin;
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

extension ExportExtension on DirectParserASTContentExportEnd {
  String getExportUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentLiteralStringEnd) {
        DirectParserASTContentLiteralStringBegin uri =
            child.children!.single as DirectParserASTContentLiteralStringBegin;
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
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentConditionalUrisEnd) {
        for (DirectParserASTContent child2 in child.children!) {
          if (child2 is DirectParserASTContentConditionalUriEnd) {
            DirectParserASTContentLiteralStringEnd end =
                child2.children!.last as DirectParserASTContentLiteralStringEnd;
            DirectParserASTContentLiteralStringBegin uri = end.children!.single
                as DirectParserASTContentLiteralStringBegin;
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

extension PartExtension on DirectParserASTContentPartEnd {
  String getPartUriString() {
    StringBuffer sb = new StringBuffer();
    bool foundOne = false;
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentLiteralStringEnd) {
        DirectParserASTContentLiteralStringBegin uri =
            child.children!.single as DirectParserASTContentLiteralStringBegin;
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

extension TopLevelFieldsExtension on DirectParserASTContentTopLevelFieldsEnd {
  List<DirectParserASTContentIdentifierHandle> getFieldIdentifiers() {
    int countLeft = count;
    List<DirectParserASTContentIdentifierHandle>? identifiers;
    for (int i = children!.length - 1; i >= 0; i--) {
      DirectParserASTContent child = children![i];
      if (child is DirectParserASTContentIdentifierHandle &&
          child.context == IdentifierContext.topLevelVariableDeclaration) {
        countLeft--;
        if (identifiers == null) {
          identifiers = new List<DirectParserASTContentIdentifierHandle>.filled(
              count, child);
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

extension ClassMethodExtension on DirectParserASTContentClassMethodEnd {
  DirectParserASTContentBlockFunctionBodyEnd? getBlockFunctionBody() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentBlockFunctionBodyEnd) {
        return child;
      }
    }
    return null;
  }

  String getNameIdentifier() {
    bool foundType = false;
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentTypeHandle ||
          child is DirectParserASTContentNoTypeHandle ||
          child is DirectParserASTContentVoidKeywordHandle ||
          child is DirectParserASTContentFunctionTypeEnd) {
        foundType = true;
      }
      if (foundType && child is DirectParserASTContentIdentifierHandle) {
        return child.token.lexeme;
      } else if (foundType &&
          child is DirectParserASTContentOperatorNameHandle) {
        return child.token.lexeme;
      }
    }
    throw "No identifier found: $children";
  }
}

extension MixinMethodExtension on DirectParserASTContentMixinMethodEnd {
  String getNameIdentifier() {
    bool foundType = false;
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentTypeHandle ||
          child is DirectParserASTContentNoTypeHandle ||
          child is DirectParserASTContentVoidKeywordHandle) {
        foundType = true;
      }
      if (foundType && child is DirectParserASTContentIdentifierHandle) {
        return child.token.lexeme;
      } else if (foundType &&
          child is DirectParserASTContentOperatorNameHandle) {
        return child.token.lexeme;
      }
    }
    throw "No identifier found: $children";
  }
}

extension ExtensionMethodExtension on DirectParserASTContentExtensionMethodEnd {
  String getNameIdentifier() {
    bool foundType = false;
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentTypeHandle ||
          child is DirectParserASTContentNoTypeHandle ||
          child is DirectParserASTContentVoidKeywordHandle) {
        foundType = true;
      }
      if (foundType && child is DirectParserASTContentIdentifierHandle) {
        return child.token.lexeme;
      } else if (foundType &&
          child is DirectParserASTContentOperatorNameHandle) {
        return child.token.lexeme;
      }
    }
    throw "No identifier found: $children";
  }
}

extension ClassFactoryMethodExtension
    on DirectParserASTContentClassFactoryMethodEnd {
  List<DirectParserASTContentIdentifierHandle> getIdentifiers() {
    List<DirectParserASTContentIdentifierHandle> result = [];
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentIdentifierHandle) {
        result.add(child);
      } else if (child is DirectParserASTContentFormalParametersEnd) {
        break;
      }
    }
    return result;
  }
}

extension ClassConstructorExtension
    on DirectParserASTContentClassConstructorEnd {
  DirectParserASTContentFormalParametersEnd getFormalParameters() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentFormalParametersEnd) {
        return child;
      }
    }
    throw "Not found";
  }

  DirectParserASTContentInitializersEnd? getInitializers() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentInitializersEnd) {
        return child;
      }
    }
    return null;
  }

  DirectParserASTContentBlockFunctionBodyEnd? getBlockFunctionBody() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentBlockFunctionBodyEnd) {
        return child;
      }
    }
    return null;
  }

  List<DirectParserASTContentIdentifierHandle> getIdentifiers() {
    List<DirectParserASTContentIdentifierHandle> result = [];
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentIdentifierHandle) {
        result.add(child);
      }
    }
    return result;
  }
}

extension FormalParametersExtension
    on DirectParserASTContentFormalParametersEnd {
  List<DirectParserASTContentFormalParameterEnd> getFormalParameters() {
    List<DirectParserASTContentFormalParameterEnd> result = [];
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentFormalParameterEnd) {
        result.add(child);
      }
    }
    return result;
  }

  DirectParserASTContentOptionalFormalParametersEnd?
      getOptionalFormalParameters() {
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentOptionalFormalParametersEnd) {
        return child;
      }
    }
    return null;
  }
}

extension FormalParameterExtension on DirectParserASTContentFormalParameterEnd {
  DirectParserASTContentFormalParameterBegin getBegin() {
    return children!.first as DirectParserASTContentFormalParameterBegin;
  }
}

extension OptionalFormalParametersExtension
    on DirectParserASTContentOptionalFormalParametersEnd {
  List<DirectParserASTContentFormalParameterEnd> getFormalParameters() {
    List<DirectParserASTContentFormalParameterEnd> result = [];
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentFormalParameterEnd) {
        result.add(child);
      }
    }
    return result;
  }
}

extension InitializersExtension on DirectParserASTContentInitializersEnd {
  List<DirectParserASTContentInitializerEnd> getInitializers() {
    List<DirectParserASTContentInitializerEnd> result = [];
    for (DirectParserASTContent child in children!) {
      if (child is DirectParserASTContentInitializerEnd) {
        result.add(child);
      }
    }
    return result;
  }

  DirectParserASTContentInitializersBegin getBegin() {
    return children!.first as DirectParserASTContentInitializersBegin;
  }
}

extension InitializerExtension on DirectParserASTContentInitializerEnd {
  DirectParserASTContentInitializerBegin getBegin() {
    return children!.first as DirectParserASTContentInitializerBegin;
  }
}

void main(List<String> args) {
  File f = new File(args[0]);
  Uint8List data = f.readAsBytesSync();
  DirectParserASTContent ast = getAST(data);
  if (args.length > 1 && args[1] == "--benchmark") {
    Stopwatch stopwatch = new Stopwatch()..start();
    int numRuns = 100;
    for (int i = 0; i < numRuns; i++) {
      DirectParserASTContent ast2 = getAST(data);
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
      DirectParserASTContent ast2 = getAST(data);
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

class DirectParserASTListener extends AbstractDirectParserASTListener {
  @override
  void seen(DirectParserASTContent entry) {
    switch (entry.type) {
      case DirectParserASTType.BEGIN:
      case DirectParserASTType.HANDLE:
        // This just adds stuff.
        data.add(entry);
        break;
      case DirectParserASTType.END:
        // End should gobble up everything until the corresponding begin (which
        // should be the latest begin).
        int? beginIndex;
        for (int i = data.length - 1; i >= 0; i--) {
          if (data[i].type == DirectParserASTType.BEGIN) {
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
                end == "MixinMethod")) {
          // beginMethod is ended by one of endClassConstructor, endClassMethod,
          // endExtensionMethod, endMixinConstructor or endMixinMethod.
        } else if (begin == "Fields" &&
            (end == "TopLevelFields" ||
                end == "ClassFields" ||
                end == "MixinFields" ||
                end == "ExtensionFields")) {
          // beginFields is ended by one of endTopLevelFields, endMixinFields or
          // endExtensionFields.
        } else if (begin == "ForStatement" && end == "ForIn") {
          // beginForStatement is ended by either endForStatement or endForIn.
        } else if (begin == "FactoryMethod" &&
            (end == "ClassFactoryMethod" ||
                end == "MixinFactoryMethod" ||
                end == "ExtensionFactoryMethod")) {
          // beginFactoryMethod is ended by either endClassFactoryMethod,
          // endMixinFactoryMethod or endExtensionFactoryMethod.
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
        } else {
          throw "Unknown combination: begin$begin and end$end";
        }
        List<DirectParserASTContent> children = data.sublist(beginIndex);
        for (DirectParserASTContent child in children) {
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
