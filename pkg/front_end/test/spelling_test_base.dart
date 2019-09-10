// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show File;

import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/fasta/command_line_reporting.dart'
    as command_line_reporting;

import 'package:front_end/src/fasta/scanner.dart' show ErrorToken;

import 'package:front_end/src/fasta/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:front_end/src/scanner/token.dart'
    show Token, KeywordToken, BeginToken;

import 'package:front_end/src/scanner/token.dart';

import 'package:kernel/kernel.dart';

import 'package:testing/testing.dart'
    show ChainContext, Result, Step, TestDescription;

import 'spell_checking_utils.dart' as spell;

abstract class SpellContext extends ChainContext {
  final List<Step> steps = const <Step>[
    const SpellTest(),
  ];

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }

  List<spell.Dictionaries> get dictionaries;

  bool get onlyBlacklisted;
}

class SpellTest extends Step<TestDescription, TestDescription, SpellContext> {
  const SpellTest();

  String get name => "spell test";

  Future<Result<TestDescription>> run(
      TestDescription description, SpellContext context) async {
    File f = new File.fromUri(description.uri);
    List<int> rawBytes = f.readAsBytesSync();

    Uint8List bytes = new Uint8List(rawBytes.length + 1);
    bytes.setRange(0, rawBytes.length, rawBytes);

    Utf8BytesScanner scanner =
        new Utf8BytesScanner(bytes, includeComments: true);
    Token firstToken = scanner.tokenize();
    if (firstToken == null) return null;
    Token token = firstToken;

    List<String> errors;
    Source source = new Source(
        scanner.lineStarts, rawBytes, description.uri, description.uri);
    void addErrorMessage(int offset, int squigglyLength, String message) {
      errors ??= new List<String>();
      Location location = source.getLocation(description.uri, offset);
      errors.add(command_line_reporting.formatErrorMessage(
          source.getTextLine(location.line),
          location,
          squigglyLength,
          description.uri.toString(),
          message));
    }

    while (token != null) {
      if (token is ErrorToken) {
        // For now just accept that.
        return pass(description);
      }
      if (token.precedingComments != null) {
        Token comment = token.precedingComments;
        while (comment != null) {
          spell.SpellingResult spellingResult = spell.spellcheckString(
              comment.lexeme,
              splitAsCode: true,
              dictionaries: context.dictionaries);
          if (spellingResult.misspelledWords != null) {
            for (int i = 0; i < spellingResult.misspelledWords.length; i++) {
              bool blacklisted = spellingResult.misspelledWordsBlacklisted[i];
              if (context.onlyBlacklisted && !blacklisted) continue;
              int offset =
                  comment.offset + spellingResult.misspelledWordsOffset[i];
              String word = spellingResult.misspelledWords[i];
              addErrorMessage(offset, word.length, "Misspelled word '$word'.");
            }
          }
          comment = comment.next;
        }
      }
      if (token is StringToken) {
        spell.SpellingResult spellingResult = spell.spellcheckString(
            token.lexeme,
            splitAsCode: true,
            dictionaries: context.dictionaries);
        if (spellingResult.misspelledWords != null) {
          for (int i = 0; i < spellingResult.misspelledWords.length; i++) {
            bool blacklisted = spellingResult.misspelledWordsBlacklisted[i];
            if (context.onlyBlacklisted && !blacklisted) continue;
            int offset = token.offset + spellingResult.misspelledWordsOffset[i];
            String word = spellingResult.misspelledWords[i];
            addErrorMessage(offset, word.length, "Misspelled word '$word'.");
          }
        }
      } else if (token is KeywordToken || token is BeginToken) {
        // Ignored.
      } else if (token.runtimeType.toString() == "SimpleToken") {
        // Ignored.
      } else {
        throw "Unsupported token type: ${token.runtimeType} ($token)";
      }

      if (token.isEof) break;

      token = token.next;
    }

    if (errors == null) {
      return pass(description);
    } else {
      return fail(description, errors.join("\n\n"));
    }
  }
}
