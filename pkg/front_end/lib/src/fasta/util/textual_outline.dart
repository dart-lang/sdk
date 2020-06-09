// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
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

// TODO: Sort imports.

class _TextualOutlineState {
  bool prevTokenKnown = false;
  Token currentElementEnd;
  List<String> currentChunk = new List<String>();
  List<String> outputLines = new List<String>();

  final bool performModelling;
  String indent = "";
  _TextualOutlineState(this.performModelling);
}

String textualOutline(List<int> rawBytes,
    {bool throwOnUnexpected: false, bool performModelling: false}) {
  // TODO(jensj): We need to specify the scanner settings to match that of the
  // compiler!
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  // Idea:
  // * Chunks are entities, e.g. whole classes, whole procedures etc.
  // * It could also be an "unknown" batch of tokens.
  // * currentChunk is a temporary buffer where we add chunks in a "run".
  // * Depending on whether we know what the previous token (and thus chunk) is
  //   or not, and what the current token (and thus chunk) is, we either flush
  //   the currentChunk buffer or not.
  // * The idea being, that if we add 3 chunks we know and then are about to add
  //   one we don't know, we can sort the 3 chunks we do know and output them.
  //   But when we go from unknown to known, we don't sort before outputting.

  _TextualOutlineState state = new _TextualOutlineState(performModelling);

  TokenPrinter tokenPrinter = new TokenPrinter();

  Utf8BytesScanner scanner = new Utf8BytesScanner(bytes, includeComments: false,
      languageVersionChanged:
          (Scanner scanner, LanguageVersionToken languageVersion) {
    flush(state, isSortable: false);
    state.prevTokenKnown = false;
    state.outputLines
        .add("// @dart = ${languageVersion.major}.${languageVersion.minor}");
  });
  Token firstToken = scanner.tokenize();
  if (firstToken == null) {
    if (throwOnUnexpected) throw "firstToken is null";
    return null;
  }

  TextualOutlineListener listener = new TextualOutlineListener();
  ClassMemberParser classMemberParser = new ClassMemberParser(listener);
  classMemberParser.parseUnit(firstToken);

  Token token = firstToken;
  while (token != null) {
    if (token is ErrorToken) {
      return null;
    }
    if (token.isEof) break;

    if (listener.classStartToFinish.containsKey(token)) {
      if (state.prevTokenKnown) {
        // TODO: Assert this instead.
        if (!tokenPrinter.isEmpty) {
          throw new StateError("Expected empty, was '${tokenPrinter.content}'");
        }
      } else if (!tokenPrinter.isEmpty) {
        // We're ending a streak of unknown: Output, and flush,
        // but it's not sortable.
        tokenPrinter.addAndClearIfHasContent(state.currentChunk);
        flush(state, isSortable: false);
      }

      Token currentClassEnd = listener.classStartToFinish[token];
      String classContent = _textualizeClass(
          listener, token, currentClassEnd, state,
          throwOnUnexpected: throwOnUnexpected);
      if (classContent == null) return null;
      state.currentChunk.add(classContent);
      token = currentClassEnd.next;
      state.prevTokenKnown = true;
      assert(tokenPrinter.isEmpty);
      continue;
    }

    token = _textualizeNonClassEntriesInsideLoop(
        listener, token, state, throwOnUnexpected, tokenPrinter);
    if (token == null) return null;
  }
  _textualizeAfterLoop(state, tokenPrinter);
  return state.outputLines.join("\n\n");
}

Token _textualizeNonClassEntriesInsideLoop(
    TextualOutlineListener listener,
    Token token,
    _TextualOutlineState state,
    bool throwOnUnexpected,
    TokenPrinter tokenPrinter) {
  if (listener.elementStartToFinish.containsKey(token)) {
    if (state.currentElementEnd != null) {
      if (throwOnUnexpected) throw "Element in element";
      return null;
    }
    if (state.prevTokenKnown) {
      if (!tokenPrinter.isEmpty) {
        throw new StateError("Expected empty, was '${tokenPrinter.content}'");
      }
    } else if (!tokenPrinter.isEmpty) {
      // We're ending a streak of unknown: Output, and flush,
      // but it's not sortable.
      tokenPrinter.addAndClearIfHasContent(state.currentChunk);
      flush(state, isSortable: false);
    }
    state.currentElementEnd = listener.elementStartToFinish[token];
    state.prevTokenKnown = true;
  } else if (state.currentElementEnd == null &&
      listener.metadataStartToFinish.containsKey(token)) {
    if (state.prevTokenKnown) {
      if (!tokenPrinter.isEmpty) {
        throw new StateError("Expected empty, was '${tokenPrinter.content}'");
      }
    } else if (!tokenPrinter.isEmpty) {
      // We're ending a streak of unknown: Output, and flush,
      // but it's not sortable.
      tokenPrinter.addAndClearIfHasContent(state.currentChunk);
      flush(state, isSortable: false);
    }
    state.currentElementEnd = listener.metadataStartToFinish[token];
    state.prevTokenKnown = true;
  }

  if (state.currentElementEnd == null && state.prevTokenKnown) {
    // We're ending a streak of known stuff.
    if (!tokenPrinter.isEmpty) {
      throw new StateError("Expected empty, was '${tokenPrinter.content}'");
    }
    flush(state, isSortable: true);
    state.prevTokenKnown = false;
  } else {
    if (state.currentElementEnd == null) {
      if (state.prevTokenKnown) {
        // known -> unknown.
        throw "This case was apparently not handled above.";
      } else {
        // OK: Streak of unknown.
      }
    } else {
      if (state.prevTokenKnown) {
        // OK: Streak of known.
      } else {
        // unknown -> known: This should have been flushed above.
        if (!tokenPrinter.isEmpty) {
          throw new StateError("Expected empty, was '${tokenPrinter.content}'");
        }
      }
    }
  }

  tokenPrinter.print(token);

  if (token == state.currentElementEnd) {
    state.currentElementEnd = null;
    tokenPrinter.addAndClearIfHasContent(state.currentChunk);
  }

  if (token.endGroup != null &&
      listener.nonClassEndOffsets.contains(token.endGroup.offset)) {
    token = token.endGroup;
    tokenPrinter.nextTokenIsEndGroup = true;
  } else {
    token = token.next;
  }
  return token;
}

void _textualizeAfterLoop(
    _TextualOutlineState state, TokenPrinter tokenPrinter) {
  // We're done, so we're logically at an unknown token.
  if (state.prevTokenKnown) {
    // We're ending a streak of known stuff.
    if (!tokenPrinter.isEmpty) {
      throw new StateError("Expected empty, was '${tokenPrinter.content}'");
    }
    flush(state, isSortable: true);
    state.prevTokenKnown = false;
  } else {
    // Streak of unknown.
    tokenPrinter.addAndClearIfHasContent(state.currentChunk);
    flush(state, isSortable: false);
    state.prevTokenKnown = false;
  }
}

void flush(_TextualOutlineState state, {bool isSortable}) {
  assert(isSortable != null);
  if (state.currentChunk.isEmpty) return;
  if (isSortable) {
    state.currentChunk = mergeAndSort(state.currentChunk, state.indent,
        isModelling: state.performModelling);
  }
  if (state.indent == "") {
    state.outputLines.addAll(state.currentChunk);
  } else {
    for (int i = 0; i < state.currentChunk.length; i++) {
      state.outputLines.add("${state.indent}${state.currentChunk[i]}");
    }
  }
  state.currentChunk.clear();
}

List<String> mergeAndSort(List<String> data, String indent,
    {bool isModelling}) {
  assert(isModelling != null);
  // If not modelling, don't sort.
  if (!isModelling) return data;

  bool hasAnnotations = false;
  for (int i = 0; i < data.length - 1; i++) {
    String element = data[i];
    if (element.startsWith("@")) {
      hasAnnotations = true;
      break;
    }
  }
  if (!hasAnnotations) {
    data.sort();
    return data;
  }

  // There's annotations: Merge them with the owner.
  List<String> merged = new List<String>();
  StringBuffer sb = new StringBuffer();
  for (int i = 0; i < data.length; i++) {
    String element = data[i];
    if (element.startsWith("@")) {
      if (sb.length > 0) sb.write(indent);
      sb.writeln(element);
    } else {
      if (sb.length > 0) sb.write(indent);
      sb.write(element);
      merged.add(sb.toString());
      sb.clear();
    }
  }
  if (sb.length > 0) {
    merged.add(sb.toString());
    sb.clear();
  }

  merged.sort();
  return merged;
}

class TokenPrinter {
  bool nextTokenIsEndGroup = false;
  int _endOfLast = -1;
  StringBuffer _sb = new StringBuffer();

  String get content => _sb.toString();

  bool get isEmpty => _sb.isEmpty;

  void clear() {
    _endOfLast = -1;
    _sb.clear();
  }

  void addAndClearIfHasContent(List<String> list) {
    if (_sb.length > 0) {
      list.add(_sb.toString());
      clear();
    }
  }

  void print(Token token) {
    if (_sb.isNotEmpty && (token.offset > _endOfLast || nextTokenIsEndGroup)) {
      _sb.write(" ");
    }

    _sb.write(token.lexeme);
    _endOfLast = token.end;
    nextTokenIsEndGroup = false;
  }

  String toString() {
    throw new UnsupportedError("toString");
  }
}

String _textualizeClass(TextualOutlineListener listener, Token beginToken,
    Token endToken, _TextualOutlineState originalState,
    {bool throwOnUnexpected: false, bool model: false}) {
  Token token = beginToken;
  TokenPrinter tokenPrinter = new TokenPrinter();
  // Class header.
  while (token != endToken) {
    tokenPrinter.print(token);
    if (token.endGroup == endToken) {
      token = token.next;
      break;
    }
    token = token.next;
  }
  _TextualOutlineState state =
      new _TextualOutlineState(originalState.performModelling);
  tokenPrinter.addAndClearIfHasContent(state.currentChunk);
  flush(state, isSortable: false);

  state.indent = "  ";
  while (token != endToken) {
    token = _textualizeNonClassEntriesInsideLoop(
        listener, token, state, throwOnUnexpected, tokenPrinter);
    if (token == null) return null;
  }
  _textualizeAfterLoop(state, tokenPrinter);

  state.indent = "";
  tokenPrinter.nextTokenIsEndGroup = true;
  tokenPrinter.print(token);
  tokenPrinter.addAndClearIfHasContent(state.currentChunk);
  flush(state, isSortable: false);
  return state.outputLines.join("\n");
}

main(List<String> args) {
  File f = new File(args[0]);
  String outline = textualOutline(f.readAsBytesSync(),
      throwOnUnexpected: true, performModelling: true);
  if (args.length > 1 && args[1] == "--overwrite") {
    f.writeAsStringSync(outline);
  } else {
    print(outline);
  }
}

class TextualOutlineListener extends DirectiveListener {
  Set<int> nonClassEndOffsets = new Set<int>();
  Map<Token, Token> classStartToFinish = {};
  Map<Token, Token> elementStartToFinish = {};
  Map<Token, Token> metadataStartToFinish = {};

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

  // @override
  // void endLibraryName(Token libraryKeyword, Token semicolon) {
  //   elementStartToFinish[libraryKeyword] = semicolon;
  // }

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
}
