// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'dart:io' show File;

import 'package:_fe_analyzer_shared/src/parser/class_member_parser.dart'
    show ClassMemberParser;

import 'package:_fe_analyzer_shared/src/parser/declaration_kind.dart'
    show DeclarationKind;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ErrorToken, LanguageVersionToken, Scanner;

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import '../../fasta/source/directive_listener.dart' show DirectiveListener;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

String textualOutline(List<int> rawBytes, {bool makeMoreReadable: false}) {
  // TODO(jensj): We need to specify the scanner settings to match that of the
  // compiler!
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  StringBuffer sb = new StringBuffer();

  Utf8BytesScanner scanner = new Utf8BytesScanner(bytes, includeComments: false,
      languageVersionChanged:
          (Scanner scanner, LanguageVersionToken languageVersion) {
    sb.writeln("// @dart = ${languageVersion.major}.${languageVersion.minor}");
  });
  Token firstToken = scanner.tokenize();
  if (firstToken == null) return null;
  Token token = firstToken;

  EndOffsetListener listener = new EndOffsetListener();
  ClassMemberParser classMemberParser = new ClassMemberParser(listener);
  classMemberParser.parseUnit(firstToken);

  bool printed = false;
  int endOfLast = -1;
  bool addLinebreak = false;
  while (token != null) {
    if (token is ErrorToken) {
      return null;
    }
    if (addLinebreak) {
      sb.write("\n");
    } else if (printed && token.offset > endOfLast) {
      sb.write(" ");
    }
    addLinebreak = false;

    sb.write(token.lexeme);
    printed = true;
    endOfLast = token.end;
    if (makeMoreReadable) {
      if (token.lexeme == ";") {
        addLinebreak = true;
      } else if (token.endGroup != null &&
          (listener.nonClassEndOffsets.contains(token.endGroup.offset) ||
              listener.classEndOffsets.contains(token.endGroup.offset))) {
        addLinebreak = true;
      } else if (listener.nonClassEndOffsets.contains(token.offset) ||
          listener.classEndOffsets.contains(token.offset)) {
        addLinebreak = true;
      }
    }

    if (token.isEof) break;

    if (token.endGroup != null &&
        listener.nonClassEndOffsets.contains(token.endGroup.offset)) {
      token = token.endGroup;
    } else {
      token = token.next;
    }
  }

  return sb.toString();
}

main(List<String> args) {
  File f = new File(args[0]);
  print(textualOutline(f.readAsBytesSync(), makeMoreReadable: true));
}

class EndOffsetListener extends DirectiveListener {
  Set<int> nonClassEndOffsets = new Set<int>();
  Set<int> classEndOffsets = new Set<int>();

  @override
  void endClassMethod(Token getOrSet, Token beginToken, Token beginParam,
      Token beginInitializers, Token endToken) {
    nonClassEndOffsets.add(endToken.offset);
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    nonClassEndOffsets.add(endToken.offset);
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    nonClassEndOffsets.add(endToken.offset);
  }

  @override
  void endClassOrMixinBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    classEndOffsets.add(endToken.offset);
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    // Allow native functions.
  }
}
