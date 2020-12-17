// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/parser/class_member_parser.dart'
    show ClassMemberParser;

import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart';

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show ScannerConfiguration;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ErrorToken, LanguageVersionToken, Scanner;

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:_fe_analyzer_shared/src/parser/listener.dart';

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

abstract class _Chunk implements Comparable<_Chunk> {
  int originalPosition;

  List<_MetadataChunk> metadata;

  void _printNormalHeaderWithMetadata(
      StringBuffer sb, bool extraLine, String indent) {
    if (sb.isNotEmpty) {
      sb.write("\n");
      if (extraLine) sb.write("\n");
    }
    printMetadata(sb, indent);
    sb.write(indent);
  }

  void printOn(StringBuffer sb, {String indent: "", bool extraLine: true});

  void printMetadata(StringBuffer sb, String indent) {
    if (metadata != null) {
      for (_MetadataChunk m in metadata) {
        m.printMetadataOn(sb, indent);
      }
    }
  }

  /// Merge and sort this chunk internally (e.g. a class might merge and sort
  /// its members).
  /// The provided [sb] should be clean and be thought of as dirty after this
  /// call.
  void internalMergeAndSort(StringBuffer sb);

  @override
  int compareTo(_Chunk other) {
    // Generally we compare according to the original position.
    if (originalPosition < other.originalPosition) return -1;
    return 1;
  }

  /// Prints tokens from [fromToken] to [toToken] into [sb].
  ///
  /// Adds space as "normal" given the tokens start and end.
  ///
  /// If [skipContentOnEndGroupUntilToToken] is true, upon meeting a token that
  /// has an endGroup where the endGroup is [toToken] the Tokens between that
  /// and [toToken] is skipped, i.e. it jumps directly to [toToken].
  void printTokenRange(Token fromToken, Token toToken, StringBuffer sb,
      {bool skipContentOnEndGroupUntilToToken: false,
      bool includeToToken: true}) {
    int endOfLast = fromToken.end;
    Token token = fromToken;
    Token afterEnd = toToken;
    if (includeToToken) afterEnd = toToken.next;
    bool nextTokenIsEndGroup = false;
    while (token != afterEnd) {
      if (token.offset > endOfLast && !nextTokenIsEndGroup) {
        sb.write(" ");
      }

      sb.write(token.lexeme);
      endOfLast = token.end;
      if (skipContentOnEndGroupUntilToToken &&
          token.endGroup != null &&
          token.endGroup == toToken) {
        token = token.endGroup;
        nextTokenIsEndGroup = true;
      } else {
        token = token.next;
        nextTokenIsEndGroup = false;
      }
    }
  }
}

class _LanguageVersionChunk extends _Chunk {
  final int major;
  final int minor;

  _LanguageVersionChunk(this.major, this.minor);

  @override
  void printOn(StringBuffer sb, {String indent: "", bool extraLine: true}) {
    _printNormalHeaderWithMetadata(sb, extraLine, indent);
    sb.write("// @dart = ${major}.${minor}");
  }

  @override
  void internalMergeAndSort(StringBuffer sb) {
    // Cannot be sorted.
    assert(sb.isEmpty);
  }
}

abstract class _TokenChunk extends _Chunk {
  final Token startToken;
  final Token endToken;

  _TokenChunk(this.startToken, this.endToken);

  void _printOnWithoutHeaderAndMetadata(StringBuffer sb) {
    printTokenRange(startToken, endToken, sb);
  }

  @override
  void printOn(StringBuffer sb, {String indent: "", bool extraLine: true}) {
    _printNormalHeaderWithMetadata(sb, extraLine, indent);
    _printOnWithoutHeaderAndMetadata(sb);
  }

  @override
  void internalMergeAndSort(StringBuffer sb) {
    // Generally cannot be sorted.
    assert(sb.isEmpty);
  }
}

abstract class _SortableChunk extends _TokenChunk {
  _SortableChunk(Token startToken, Token endToken)
      : super(startToken, endToken);

  @override
  int compareTo(_Chunk o) {
    if (o is! _SortableChunk) return super.compareTo(o);

    _SortableChunk other = o;

    // Compare lexemes from startToken and at most the next 10 tokens.
    // For valid code this should be more than enough. Note that this won't
    // sort as a text-sort would as for instance "C<Foo>" and "C2<Foo>" will
    // say "C" < "C2" where a text-sort would say "C<" > "C2". This doesn't
    // really matter as long as the sorting is consistent (i.e. the textual
    // outline always sorts like this).
    Token thisToken = startToken;
    Token otherToken = other.startToken;
    int steps = 0;
    while (thisToken.lexeme == otherToken.lexeme) {
      if (steps++ > 10) break;
      thisToken = thisToken.next;
      otherToken = otherToken.next;
    }
    if (thisToken.lexeme == otherToken.lexeme) return super.compareTo(o);
    return thisToken.lexeme.compareTo(otherToken.lexeme);
  }
}

class _ImportExportChunk extends _Chunk {
  final List<_SingleImportExportChunk> content;

  _ImportExportChunk(this.content, int originalPosition) {
    this.originalPosition = originalPosition;
  }

  @override
  void printOn(StringBuffer sb, {String indent: "", bool extraLine: true}) {
    if (sb.isNotEmpty) {
      sb.write("\n");
    }

    for (int i = 0; i < content.length; i++) {
      _SingleImportExportChunk chunk = content[i];
      chunk.printOn(sb,
          indent: indent,
          // add extra space if there's metadata
          extraLine: chunk.metadata != null);
    }
  }

  @override
  void internalMergeAndSort(StringBuffer sb) {
    assert(sb.isEmpty);
    content.sort();
  }
}

abstract class _SingleImportExportChunk extends _SortableChunk {
  final Token firstShowOrHide;
  final List<_NamespaceCombinator> combinators;
  String sortedShowAndHide;

  _SingleImportExportChunk(
      Token startToken, Token endToken, this.firstShowOrHide, this.combinators)
      : super(startToken, endToken);

  @override
  void internalMergeAndSort(StringBuffer sb) {
    assert(sb.isEmpty);
    if (firstShowOrHide == null) return;
    for (int i = 0; i < combinators.length; i++) {
      sb.write(" ");
      _NamespaceCombinator combinator = combinators[i];
      sb.write(combinator.isShow ? "show " : "hide ");
      List<String> sorted = combinator.names.toList()..sort();
      for (int j = 0; j < sorted.length; j++) {
        if (j > 0) sb.write(", ");
        sb.write(sorted[j]);
      }
    }
    sb.write(";");
    sortedShowAndHide = sb.toString();
  }

  @override
  void _printOnWithoutHeaderAndMetadata(StringBuffer sb) {
    if (sortedShowAndHide == null) {
      return super._printOnWithoutHeaderAndMetadata(sb);
    }
    printTokenRange(startToken, firstShowOrHide, sb, includeToToken: false);
    sb.write(sortedShowAndHide);
  }
}

class _ImportChunk extends _SingleImportExportChunk {
  _ImportChunk(Token startToken, Token endToken, Token firstShowOrHide,
      List<_NamespaceCombinator> combinators)
      : super(startToken, endToken, firstShowOrHide, combinators);
}

class _ExportChunk extends _SingleImportExportChunk {
  _ExportChunk(Token startToken, Token endToken, Token firstShowOrHide,
      List<_NamespaceCombinator> combinators)
      : super(startToken, endToken, firstShowOrHide, combinators);
}

class _NamespaceCombinator {
  final bool isShow;
  final Set<String> names;

  _NamespaceCombinator.hide(List<String> names)
      : isShow = false,
        names = names.toSet();

  _NamespaceCombinator.show(List<String> names)
      : isShow = true,
        names = names.toSet();
}

class _LibraryNameChunk extends _TokenChunk {
  _LibraryNameChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _PartChunk extends _TokenChunk {
  _PartChunk(Token startToken, Token endToken) : super(startToken, endToken);
}

class _PartOfChunk extends _TokenChunk {
  _PartOfChunk(Token startToken, Token endToken) : super(startToken, endToken);
}

abstract class _ClassChunk extends _SortableChunk {
  List<_Chunk> content = <_Chunk>[];
  Token headerEnd;
  Token footerStart;

  _ClassChunk(Token startToken, Token endToken) : super(startToken, endToken);

  @override
  void printOn(StringBuffer sb, {String indent: "", bool extraLine: true}) {
    _printNormalHeaderWithMetadata(sb, extraLine, indent);

    // Header.
    printTokenRange(startToken, headerEnd, sb);

    // Content.
    for (int i = 0; i < content.length; i++) {
      _Chunk chunk = content[i];
      chunk.printOn(sb, indent: "  $indent", extraLine: false);
    }

    // Footer.
    if (footerStart != null) {
      if (content.isNotEmpty) {
        sb.write("\n");
      }
      sb.write(indent);

      printTokenRange(footerStart, endToken, sb);
    }
  }

  @override
  void internalMergeAndSort(StringBuffer sb) {
    assert(sb.isEmpty);
    content = _mergeAndSort(content);
  }
}

class _ClassDeclarationChunk extends _ClassChunk {
  _ClassDeclarationChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _MixinDeclarationChunk extends _ClassChunk {
  _MixinDeclarationChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _ExtensionDeclarationChunk extends _ClassChunk {
  _ExtensionDeclarationChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _NamedMixinApplicationChunk extends _ClassChunk {
  _NamedMixinApplicationChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

abstract class _ProcedureEtcChunk extends _SortableChunk {
  _ProcedureEtcChunk(Token startToken, Token endToken)
      : super(startToken, endToken);

  void _printOnWithoutHeaderAndMetadata(StringBuffer sb) {
    printTokenRange(startToken, endToken, sb,
        skipContentOnEndGroupUntilToToken: true);
  }
}

class _ClassMethodChunk extends _ProcedureEtcChunk {
  _ClassMethodChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _TopLevelMethodChunk extends _ProcedureEtcChunk {
  _TopLevelMethodChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _ClassFactoryMethodChunk extends _ProcedureEtcChunk {
  _ClassFactoryMethodChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _ClassFieldsChunk extends _ProcedureEtcChunk {
  _ClassFieldsChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _TopLevelFieldsChunk extends _ProcedureEtcChunk {
  _TopLevelFieldsChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _FunctionTypeAliasChunk extends _ProcedureEtcChunk {
  _FunctionTypeAliasChunk(Token startToken, Token endToken)
      : super(startToken, endToken);
}

class _EnumChunk extends _SortableChunk {
  _EnumChunk(Token startToken, Token endToken) : super(startToken, endToken);
}

class _MetadataChunk extends _TokenChunk {
  _MetadataChunk(Token startToken, Token endToken)
      : super(startToken, endToken);

  void printMetadataOn(StringBuffer sb, String indent) {
    sb.write(indent);
    printTokenRange(startToken, endToken, sb);
    sb.write("\n");
  }
}

class _UnknownChunk extends _TokenChunk {
  final bool addMarkerForUnknownForTest;
  _UnknownChunk(
      this.addMarkerForUnknownForTest, Token startToken, Token endToken)
      : super(startToken, endToken);

  void _printOnWithoutHeaderAndMetadata(StringBuffer sb) {
    if (addMarkerForUnknownForTest) {
      sb.write("---- unknown chunk starts ----\n");
      super._printOnWithoutHeaderAndMetadata(sb);
      sb.write("\n---- unknown chunk ends ----");
      return;
    }
    super._printOnWithoutHeaderAndMetadata(sb);
  }
}

class _UnknownTokenBuilder {
  Token start;
  Token interimEnd;
}

class BoxedInt {
  int value;
  BoxedInt(this.value);
}

// TODO(jensj): Better support for not carring about preexisting spaces, e.g.
//              "foo(int a, int b)" will be different from "foo(int a,int b)".
// TODO(jensj): Specify scanner settings to match that of the compiler.
// TODO(jensj): Canonicalize show/hides on imports/exports. E.g.
//              "show A hide B" could just be "show A".
//              "show A show B" could just be "show A, B".
//              "show A, B, C hide A show A" would be empty.

String textualOutline(List<int> rawBytes,
    {ScannerConfiguration configuration,
    bool throwOnUnexpected: false,
    bool performModelling: false,
    bool addMarkerForUnknownForTest: false}) {
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  List<_Chunk> parsedChunks = <_Chunk>[];

  BoxedInt originalPosition = new BoxedInt(0);

  Utf8BytesScanner scanner = new Utf8BytesScanner(bytes,
      includeComments: false,
      configuration: configuration, languageVersionChanged:
          (Scanner scanner, LanguageVersionToken languageVersion) {
    parsedChunks.add(
        new _LanguageVersionChunk(languageVersion.major, languageVersion.minor)
          ..originalPosition = originalPosition.value++);
  });
  Token firstToken = scanner.tokenize();
  if (firstToken == null) {
    if (throwOnUnexpected) throw "firstToken is null";
    return null;
  }

  TextualOutlineListener listener = new TextualOutlineListener();
  ClassMemberParser classMemberParser = new ClassMemberParser(listener);
  classMemberParser.parseUnit(firstToken);

  Token nextToken = firstToken;
  _UnknownTokenBuilder currentUnknown = new _UnknownTokenBuilder();
  while (nextToken != null) {
    if (nextToken is ErrorToken) {
      return null;
    }
    if (nextToken.isEof) break;

    nextToken = _textualizeTokens(listener, nextToken, currentUnknown,
        parsedChunks, originalPosition, addMarkerForUnknownForTest);
  }
  outputUnknownChunk(currentUnknown, parsedChunks, originalPosition,
      addMarkerForUnknownForTest);

  if (nextToken == null) return null;

  if (performModelling) {
    parsedChunks = _mergeAndSort(parsedChunks);
  }

  StringBuffer sb = new StringBuffer();
  for (_Chunk chunk in parsedChunks) {
    chunk.printOn(sb);
  }

  return sb.toString();
}

List<_Chunk> _mergeAndSort(List<_Chunk> chunks) {
  List<_Chunk> result =
      new List<_Chunk>.filled(chunks.length, null, growable: true);
  List<_MetadataChunk> metadataChunks;
  List<_SingleImportExportChunk> importExportChunks;
  int outSize = 0;
  StringBuffer sb = new StringBuffer();
  for (_Chunk chunk in chunks) {
    if (chunk is _MetadataChunk) {
      metadataChunks ??= <_MetadataChunk>[];
      metadataChunks.add(chunk);
    } else {
      chunk.metadata = metadataChunks;
      metadataChunks = null;
      chunk.internalMergeAndSort(sb);
      sb.clear();

      if (chunk is _SingleImportExportChunk) {
        importExportChunks ??= <_SingleImportExportChunk>[];
        importExportChunks.add(chunk);
      } else {
        if (importExportChunks != null) {
          _ImportExportChunk importExportChunk = new _ImportExportChunk(
              importExportChunks, importExportChunks.first.originalPosition);
          importExportChunk.internalMergeAndSort(sb);
          sb.clear();
          result[outSize++] = importExportChunk;
          importExportChunks = null;
        }
        result[outSize++] = chunk;
      }
    }
  }
  if (metadataChunks != null) {
    for (_MetadataChunk metadata in metadataChunks) {
      result[outSize++] = metadata;
    }
  }
  if (importExportChunks != null) {
    _ImportExportChunk importExportChunk = new _ImportExportChunk(
        importExportChunks, importExportChunks.first.originalPosition);
    importExportChunk.internalMergeAndSort(sb);
    sb.clear();
    result[outSize++] = importExportChunk;
    importExportChunks = null;
  }
  result.length = outSize;

  result.sort();
  return result;
}

/// Parses a chunk of tokens and returns the next - unparsed - token or null
/// on error.
Token _textualizeTokens(
    TextualOutlineListener listener,
    Token token,
    _UnknownTokenBuilder currentUnknown,
    List<_Chunk> parsedChunks,
    BoxedInt originalPosition,
    bool addMarkerForUnknownForTest) {
  _ClassChunk classChunk = listener.classStartToChunk[token];
  if (classChunk != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition,
        addMarkerForUnknownForTest);
    parsedChunks.add(classChunk..originalPosition = originalPosition.value++);
    return _textualizeClass(
        listener, classChunk, originalPosition, addMarkerForUnknownForTest);
  }

  _SingleImportExportChunk singleImportExport =
      listener.importExportsStartToChunk[token];
  if (singleImportExport != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition,
        addMarkerForUnknownForTest);
    parsedChunks
        .add(singleImportExport..originalPosition = originalPosition.value++);
    return singleImportExport.endToken.next;
  }

  _TokenChunk knownUnsortableChunk =
      listener.unsortableElementStartToChunk[token];
  if (knownUnsortableChunk != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition,
        addMarkerForUnknownForTest);
    parsedChunks
        .add(knownUnsortableChunk..originalPosition = originalPosition.value++);
    return knownUnsortableChunk.endToken.next;
  }

  _TokenChunk elementChunk = listener.elementStartToChunk[token];
  if (elementChunk != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition,
        addMarkerForUnknownForTest);
    parsedChunks.add(elementChunk..originalPosition = originalPosition.value++);
    return elementChunk.endToken.next;
  }

  _MetadataChunk metadataChunk = listener.metadataStartToChunk[token];
  if (metadataChunk != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition,
        addMarkerForUnknownForTest);
    parsedChunks
        .add(metadataChunk..originalPosition = originalPosition.value++);
    return metadataChunk.endToken.next;
  }

  // This token --- and whatever else tokens until we reach a start token we
  // know is an unknown chunk. We don't yet know the end.
  if (currentUnknown.start == null) {
    // Start of unknown chunk.
    currentUnknown.start = token;
    currentUnknown.interimEnd = token;
  } else {
    // Continued unknown chunk.
    currentUnknown.interimEnd = token;
  }
  return token.next;
}

Token _textualizeClass(TextualOutlineListener listener, _ClassChunk classChunk,
    BoxedInt originalPosition, bool addMarkerForUnknownForTest) {
  Token token = classChunk.startToken;
  // Class header.
  while (token != classChunk.endToken) {
    if (token.endGroup == classChunk.endToken) {
      break;
    }
    token = token.next;
  }
  classChunk.headerEnd = token;

  if (token == classChunk.endToken) {
    // This for instance happens on named mixins, e.g.
    // class C<T> = Object with A<Function(T)>;
    // or when the class has no content, e.g.
    // class C { }
    // either way, output the end token right away to avoid a weird line break.
  } else {
    token = token.next;
    // "Normal" class with (possibly) content.
    _UnknownTokenBuilder currentUnknown = new _UnknownTokenBuilder();
    while (token != classChunk.endToken) {
      token = _textualizeTokens(listener, token, currentUnknown,
          classChunk.content, originalPosition, addMarkerForUnknownForTest);
    }
    outputUnknownChunk(currentUnknown, classChunk.content, originalPosition,
        addMarkerForUnknownForTest);
    classChunk.footerStart = classChunk.endToken;
  }

  return classChunk.endToken.next;
}

/// Outputs an unknown chunk if one has been started.
///
/// Resets the given builder.
void outputUnknownChunk(
    _UnknownTokenBuilder _currentUnknown,
    List<_Chunk> parsedChunks,
    BoxedInt originalPosition,
    bool addMarkerForUnknownForTest) {
  if (_currentUnknown.start == null) return;
  parsedChunks.add(new _UnknownChunk(addMarkerForUnknownForTest,
      _currentUnknown.start, _currentUnknown.interimEnd)
    ..originalPosition = originalPosition.value++);
  _currentUnknown.start = null;
  _currentUnknown.interimEnd = null;
}

main(List<String> args) {
  File f = new File(args[0]);
  Uint8List data = f.readAsBytesSync();
  String outline =
      textualOutline(data, throwOnUnexpected: true, performModelling: true);
  if (args.length > 1 && args[1] == "--overwrite") {
    f.writeAsStringSync(outline);
  } else if (args.length > 1 && args[1] == "--benchmark") {
    Stopwatch stopwatch = new Stopwatch()..start();
    int numRuns = 100;
    for (int i = 0; i < numRuns; i++) {
      String outline2 =
          textualOutline(data, throwOnUnexpected: true, performModelling: true);
      if (outline2 != outline) throw "Not the same result every time";
    }
    stopwatch.stop();
    print("First $numRuns took ${stopwatch.elapsedMilliseconds} ms "
        "(i.e. ${stopwatch.elapsedMilliseconds / numRuns}ms/iteration)");
    stopwatch = new Stopwatch()..start();
    numRuns = 2500;
    for (int i = 0; i < numRuns; i++) {
      String outline2 =
          textualOutline(data, throwOnUnexpected: true, performModelling: true);
      if (outline2 != outline) throw "Not the same result every time";
    }
    stopwatch.stop();
    print("Next $numRuns took ${stopwatch.elapsedMilliseconds} ms "
        "(i.e. ${stopwatch.elapsedMilliseconds / numRuns}ms/iteration)");
  } else {
    print(outline);
  }
}

class TextualOutlineListener extends Listener {
  Map<Token, _ClassChunk> classStartToChunk = {};
  Map<Token, _TokenChunk> elementStartToChunk = {};
  Map<Token, _MetadataChunk> metadataStartToChunk = {};
  Map<Token, _SingleImportExportChunk> importExportsStartToChunk = {};
  Map<Token, _TokenChunk> unsortableElementStartToChunk = {};

  @override
  void endClassMethod(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    elementStartToChunk[beginToken] =
        new _ClassMethodChunk(beginToken, endToken);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    elementStartToChunk[beginToken] =
        new _TopLevelMethodChunk(beginToken, endToken);
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    elementStartToChunk[beginToken] =
        new _ClassFactoryMethodChunk(beginToken, endToken);
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    // Allow native functions.
  }

  @override
  void endClassFields(
      Token abstractToken,
      Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token lateToken,
      Token varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    elementStartToChunk[beginToken] =
        new _ClassFieldsChunk(beginToken, endToken);
  }

  @override
  void endTopLevelFields(
      Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token lateToken,
      Token varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    elementStartToChunk[beginToken] =
        new _TopLevelFieldsChunk(beginToken, endToken);
  }

  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    elementStartToChunk[typedefKeyword] =
        new _FunctionTypeAliasChunk(typedefKeyword, endToken);
  }

  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    elementStartToChunk[enumKeyword] =
        new _EnumChunk(enumKeyword, leftBrace.endGroup);
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    unsortableElementStartToChunk[libraryKeyword] =
        new _LibraryNameChunk(libraryKeyword, semicolon);
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    unsortableElementStartToChunk[partKeyword] =
        new _PartChunk(partKeyword, semicolon);
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    unsortableElementStartToChunk[partKeyword] =
        new _PartOfChunk(partKeyword, semicolon);
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    // Metadata's endToken is the one *after* the actual end of the metadata.
    metadataStartToChunk[beginToken] =
        new _MetadataChunk(beginToken, endToken.previous);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    classStartToChunk[beginToken] =
        new _ClassDeclarationChunk(beginToken, endToken);
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    classStartToChunk[mixinKeyword] =
        new _MixinDeclarationChunk(mixinKeyword, endToken);
  }

  @override
  void endExtensionDeclaration(
      Token extensionKeyword, Token onKeyword, Token endToken) {
    classStartToChunk[extensionKeyword] =
        new _ExtensionDeclarationChunk(extensionKeyword, endToken);
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    classStartToChunk[beginToken] =
        new _NamedMixinApplicationChunk(beginToken, endToken);
  }

  Token firstShowOrHide;
  List<_NamespaceCombinator> _combinators;
  List<String> _combinatorNames;

  @override
  beginExport(Token export) {
    _combinators = <_NamespaceCombinator>[];
  }

  @override
  beginImport(Token import) {
    _combinators = <_NamespaceCombinator>[];
  }

  @override
  void beginShow(Token show) {
    if (firstShowOrHide == null) firstShowOrHide = show;
    _combinatorNames = <String>[];
  }

  @override
  void beginHide(Token hide) {
    if (firstShowOrHide == null) firstShowOrHide = hide;
    _combinatorNames = <String>[];
  }

  @override
  void endHide(Token hide) {
    _combinators.add(new _NamespaceCombinator.hide(_combinatorNames));
    _combinatorNames = null;
  }

  @override
  void endShow(Token show) {
    _combinators.add(new _NamespaceCombinator.show(_combinatorNames));
    _combinatorNames = null;
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    if (_combinatorNames != null && context == IdentifierContext.combinator) {
      _combinatorNames.add(token.lexeme);
    }
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    if (importKeyword != null && semicolon != null) {
      importExportsStartToChunk[importKeyword] = new _ImportChunk(
          importKeyword, semicolon, firstShowOrHide, _combinators);
    }
    _combinators = null;
    firstShowOrHide = null;
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    importExportsStartToChunk[exportKeyword] = new _ExportChunk(
        exportKeyword, semicolon, firstShowOrHide, _combinators);
    _combinators = null;
    firstShowOrHide = null;
  }
}
