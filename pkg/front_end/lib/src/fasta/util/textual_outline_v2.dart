// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/parser/class_member_parser.dart'
    show ClassMemberParser;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ErrorToken, LanguageVersionToken, Scanner;

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import '../../fasta/source/directive_listener.dart' show DirectiveListener;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

abstract class _Chunk implements Comparable<_Chunk> {
  final int originalPosition;

  List<_MetadataChunk> metadata;

  _Chunk(this.originalPosition);

  void printOn(StringBuffer sb, String indent);

  void printMetadata(StringBuffer sb, String indent) {
    if (metadata != null) {
      for (_MetadataChunk m in metadata) {
        m.printMetadataOn(sb, indent);
      }
    }
  }

  void internalMergeAndSort();

  @override
  int compareTo(_Chunk other) {
    // Generally we compare according to the original position.
    if (originalPosition < other.originalPosition) return -1;
    return 1;
  }
}

class _LanguageVersionChunk extends _Chunk {
  final int major;
  final int minor;

  _LanguageVersionChunk(int originalPosition, this.major, this.minor)
      : super(originalPosition);

  @override
  void printOn(StringBuffer sb, String indent) {
    if (sb.isNotEmpty) {
      sb.write("\n\n");
    }
    printMetadata(sb, indent);
    sb.write("// @dart = ${major}.${minor}");
  }

  @override
  void internalMergeAndSort() {
    // Cannot be sorted.
  }
}

abstract class _TokenChunk extends _Chunk {
  final Token startToken;
  final Token endToken;

  _TokenChunk(int originalPosition, this.startToken, this.endToken)
      : super(originalPosition);

  void printOn(StringBuffer sb, String indent) {
    int endOfLast = startToken.end;
    if (sb.isNotEmpty) {
      sb.write("\n");
      if (indent.isEmpty && this is! _SingleImportExportChunk) {
        // Hack to imitate v1.
        sb.write("\n");
      }
    }
    printMetadata(sb, indent);
    sb.write(indent);

    Token token = startToken;
    Token afterEnd = endToken.next;
    while (token != afterEnd) {
      if (token.offset > endOfLast) {
        sb.write(" ");
      }

      sb.write(token.lexeme);
      endOfLast = token.end;
      token = token.next;
    }
  }

  @override
  void internalMergeAndSort() {
    // Generally cannot be sorted.
  }
}

abstract class _SortableChunk extends _TokenChunk {
  _SortableChunk(int originalPosition, Token startToken, Token endToken)
      : super(originalPosition, startToken, endToken);

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
  final List<_SingleImportExportChunk> content =
      new List<_SingleImportExportChunk>();

  _ImportExportChunk(int originalPosition) : super(originalPosition);

  @override
  void printOn(StringBuffer sb, String indent) {
    if (sb.isNotEmpty) {
      sb.write("\n");
    }
    printMetadata(sb, indent);

    for (_SingleImportExportChunk chunk in content) {
      chunk.printOn(sb, indent);
    }
  }

  @override
  void internalMergeAndSort() {
    content.sort();
  }
}

class _SingleImportExportChunk extends _SortableChunk {
  _SingleImportExportChunk(
      int originalPosition, Token startToken, Token endToken)
      : super(originalPosition, startToken, endToken);
}

class _KnownUnsortableChunk extends _TokenChunk {
  _KnownUnsortableChunk(int originalPosition, Token startToken, Token endToken)
      : super(originalPosition, startToken, endToken);
}

class _ClassChunk extends _SortableChunk {
  List<_Chunk> content = new List<_Chunk>();
  Token headerEnd;
  Token footerStart;

  _ClassChunk(int originalPosition, Token startToken, Token endToken)
      : super(originalPosition, startToken, endToken);

  void printOn(StringBuffer sb, String indent) {
    int endOfLast = startToken.end;
    if (sb.isNotEmpty) {
      sb.write("\n\n");
      sb.write(indent);
    }

    printMetadata(sb, indent);

    // Header.
    Token token = startToken;
    Token afterEnd = headerEnd.next;
    while (token != afterEnd) {
      if (token.offset > endOfLast) {
        sb.write(" ");
      }

      sb.write(token.lexeme);
      endOfLast = token.end;

      token = token.next;
    }

    // Content.
    for (_Chunk chunk in content) {
      chunk.printOn(sb, "  $indent");
    }

    // Footer.
    if (footerStart != null) {
      if (content.isNotEmpty) {
        sb.write("\n");
        sb.write(indent);
      }
      endOfLast = footerStart.end;
      token = footerStart;
      afterEnd = endToken.next;
      while (token != afterEnd) {
        if (token.offset > endOfLast) {
          sb.write(" ");
        }

        sb.write(token.lexeme);
        endOfLast = token.end;

        token = token.next;
      }
    }
  }

  @override
  void internalMergeAndSort() {
    content = _mergeAndSort(content);
  }
}

class _ProcedureEtcChunk extends _SortableChunk {
  final Set<int> nonClassEndOffsets;
  _ProcedureEtcChunk(int originalPosition, Token startToken, Token endToken,
      this.nonClassEndOffsets)
      : super(originalPosition, startToken, endToken);

  void printOn(StringBuffer sb, String indent) {
    int endOfLast = startToken.end;
    if (sb.isNotEmpty) {
      sb.write("\n");
      if (indent.isEmpty) {
        // Hack to imitate v1.
        sb.write("\n");
      }
    }
    printMetadata(sb, indent);
    sb.write(indent);

    Token token = startToken;
    Token afterEnd = endToken.next;
    bool nextTokenIsEndGroup = false;
    while (token != afterEnd) {
      if (token.offset > endOfLast && !nextTokenIsEndGroup) {
        sb.write(" ");
      }

      sb.write(token.lexeme);
      endOfLast = token.end;

      if (token.endGroup != null &&
          nonClassEndOffsets.contains(token.endGroup.offset)) {
        token = token.endGroup;
        nextTokenIsEndGroup = true;
      } else {
        token = token.next;
        nextTokenIsEndGroup = false;
      }
    }
  }
}

class _MetadataChunk extends _TokenChunk {
  _MetadataChunk(int originalPosition, Token startToken, Token endToken)
      : super(originalPosition, startToken, endToken);

  void printMetadataOn(StringBuffer sb, String indent) {
    int endOfLast = startToken.end;
    sb.write(indent);
    Token token = startToken;
    Token afterEnd = endToken.next;
    while (token != afterEnd) {
      if (token.offset > endOfLast) {
        sb.write(" ");
      }

      sb.write(token.lexeme);
      endOfLast = token.end;
      token = token.next;
    }
    sb.write("\n");
  }
}

class _UnknownChunk extends _TokenChunk {
  _UnknownChunk(int originalPosition, Token startToken, Token endToken)
      : super(originalPosition, startToken, endToken);
}

class _UnknownTokenBuilder {
  Token start;
  Token interimEnd;
}

class BoxedInt {
  int value;
  BoxedInt(this.value);
}

// TODO(jensj): Better support for show/hide on imports/exports.

String textualOutline(List<int> rawBytes,
    {bool throwOnUnexpected: false,
    bool performModelling: false,
    bool addMarkerForUnknownForTest: false}) {
  // TODO(jensj): We need to specify the scanner settings to match that of the
  // compiler!
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  List<_Chunk> parsedChunks = new List<_Chunk>();

  BoxedInt originalPosition = new BoxedInt(0);

  Utf8BytesScanner scanner = new Utf8BytesScanner(bytes, includeComments: false,
      languageVersionChanged:
          (Scanner scanner, LanguageVersionToken languageVersion) {
    parsedChunks.add(new _LanguageVersionChunk(originalPosition.value++,
        languageVersion.major, languageVersion.minor));
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

    nextToken = _textualizeTokens(
        listener, nextToken, currentUnknown, parsedChunks, originalPosition);
  }
  outputUnknownChunk(currentUnknown, parsedChunks, originalPosition);

  if (nextToken == null) return null;

  if (performModelling) {
    parsedChunks = _mergeAndSort(parsedChunks);
  }

  StringBuffer sb = new StringBuffer();
  for (_Chunk chunk in parsedChunks) {
    chunk.printOn(sb, "");
  }

  return sb.toString();
}

List<_Chunk> _mergeAndSort(List<_Chunk> chunks) {
  // TODO(jensj): Only put into new list of there's metadata.
  List<_Chunk> result =
      new List<_Chunk>.filled(chunks.length, null, growable: true);
  List<_MetadataChunk> metadataChunks;
  int outSize = 0;
  for (_Chunk chunk in chunks) {
    if (chunk is _MetadataChunk) {
      metadataChunks ??= new List<_MetadataChunk>();
      metadataChunks.add(chunk);
    } else {
      chunk.metadata = metadataChunks;
      metadataChunks = null;
      chunk.internalMergeAndSort();
      result[outSize++] = chunk;
    }
  }
  if (metadataChunks != null) {
    for (_MetadataChunk metadata in metadataChunks) {
      result[outSize++] = metadata;
    }
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
    BoxedInt originalPosition) {
  Token classEndToken = listener.classStartToFinish[token];
  if (classEndToken != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition);

    _ClassChunk classChunk =
        new _ClassChunk(originalPosition.value++, token, classEndToken);
    parsedChunks.add(classChunk);
    return _textualizeClass(listener, classChunk, originalPosition);
  }

  Token isImportExportEndToken = listener.importExportsStartToFinish[token];
  if (isImportExportEndToken != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition);

    _ImportExportChunk importExportChunk =
        new _ImportExportChunk(originalPosition.value++);
    parsedChunks.add(importExportChunk);
    return _textualizeImportExports(listener, token, importExportChunk);
  }

  Token isKnownUnsortableEndToken =
      listener.unsortableElementStartToFinish[token];
  if (isKnownUnsortableEndToken != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition);

    Token beginToken = token;
    parsedChunks.add(new _KnownUnsortableChunk(
        originalPosition.value++, beginToken, isKnownUnsortableEndToken));
    return isKnownUnsortableEndToken.next;
  }

  Token elementEndToken = listener.elementStartToFinish[token];
  if (elementEndToken != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition);

    Token beginToken = token;
    parsedChunks.add(new _ProcedureEtcChunk(originalPosition.value++,
        beginToken, elementEndToken, listener.nonClassEndOffsets));
    return elementEndToken.next;
  }

  Token metadataEndToken = listener.metadataStartToFinish[token];
  if (metadataEndToken != null) {
    outputUnknownChunk(currentUnknown, parsedChunks, originalPosition);

    Token beginToken = token;
    parsedChunks.add(new _MetadataChunk(
        originalPosition.value++, beginToken, metadataEndToken));
    return metadataEndToken.next;
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

Token _textualizeImportExports(TextualOutlineListener listener, Token token,
    _ImportExportChunk importExportChunk) {
  int originalPosition = 0;
  Token endToken = listener.importExportsStartToFinish[token];
  while (endToken != null) {
    importExportChunk.content
        .add(new _SingleImportExportChunk(originalPosition++, token, endToken));
    token = endToken.next;
    endToken = listener.importExportsStartToFinish[token];
  }

  return token;
}

Token _textualizeClass(TextualOutlineListener listener, _ClassChunk classChunk,
    BoxedInt originalPosition) {
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
          classChunk.content, originalPosition);
    }
    outputUnknownChunk(currentUnknown, classChunk.content, originalPosition);
    classChunk.footerStart = classChunk.endToken;
  }

  return classChunk.endToken.next;
}

/// Outputs an unknown chunk if one has been started.
///
/// Resets the given builder.
void outputUnknownChunk(_UnknownTokenBuilder _currentUnknown,
    List<_Chunk> parsedChunks, BoxedInt originalPosition) {
  if (_currentUnknown.start == null) return;
  parsedChunks.add(new _UnknownChunk(
    originalPosition.value++,
    _currentUnknown.start,
    _currentUnknown.interimEnd,
  ));
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
    for (int i = 0; i < 100; i++) {
      String outline2 =
          textualOutline(data, throwOnUnexpected: true, performModelling: true);
      if (outline2 != outline) throw "Not the same result every time";
    }
    stopwatch.stop();
    print("First 100 took ${stopwatch.elapsedMilliseconds} ms");
    stopwatch = new Stopwatch()..start();
    for (int i = 0; i < 10000; i++) {
      String outline2 =
          textualOutline(data, throwOnUnexpected: true, performModelling: true);
      if (outline2 != outline) throw "Not the same result every time";
    }
    stopwatch.stop();
    print("Next 10,000 took ${stopwatch.elapsedMilliseconds} ms");
  } else {
    print(outline);
  }
}

class TextualOutlineListener extends DirectiveListener {
  Set<int> nonClassEndOffsets = new Set<int>();
  Map<Token, Token> classStartToFinish = {};
  Map<Token, Token> elementStartToFinish = {};
  Map<Token, Token> metadataStartToFinish = {};
  Map<Token, Token> importExportsStartToFinish = {};
  Map<Token, Token> unsortableElementStartToFinish = {};

  @override
  void endClassMethod(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    nonClassEndOffsets.add(endToken.offset);
    elementStartToFinish[beginToken] = endToken;
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    nonClassEndOffsets.add(endToken.offset);
    elementStartToFinish[beginToken] = endToken;
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    nonClassEndOffsets.add(endToken.offset);
    elementStartToFinish[beginToken] = endToken;
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
    elementStartToFinish[beginToken] = endToken;
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
    elementStartToFinish[beginToken] = endToken;
  }

  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    elementStartToFinish[typedefKeyword] = endToken;
  }

  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    elementStartToFinish[enumKeyword] = leftBrace.endGroup;
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    unsortableElementStartToFinish[libraryKeyword] = semicolon;
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    unsortableElementStartToFinish[partKeyword] = semicolon;
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    unsortableElementStartToFinish[partKeyword] = semicolon;
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    // Metadata's endToken is the one *after* the actual end of the metadata.
    metadataStartToFinish[beginToken] = endToken.previous;
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    classStartToFinish[beginToken] = endToken;
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    classStartToFinish[mixinKeyword] = endToken;
  }

  @override
  void endExtensionDeclaration(
      Token extensionKeyword, Token onKeyword, Token endToken) {
    classStartToFinish[extensionKeyword] = endToken;
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    classStartToFinish[beginToken] = endToken;
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    importExportsStartToFinish[importKeyword] = semicolon;
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    importExportsStartToFinish[exportKeyword] = semicolon;
  }
}
