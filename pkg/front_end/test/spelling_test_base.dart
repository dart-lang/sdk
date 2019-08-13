// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show File;

import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/fasta/scanner.dart' show ErrorToken;

import 'package:front_end/src/fasta/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:front_end/src/scanner/token.dart'
    show Token, KeywordToken, BeginToken;
import 'package:front_end/src/scanner/token.dart';

import 'package:testing/testing.dart'
    show ChainContext, Result, Step, TestDescription;

import 'spell_checking_utils.dart' as spell;

abstract class Context extends ChainContext {
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
}

class SpellTest extends Step<TestDescription, TestDescription, Context> {
  const SpellTest();

  String get name => "spell test";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
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

    while (token != null) {
      if (token is ErrorToken) {
        // For now just accept that.
        return pass(description);
      }
      if (token.precedingComments != null) {
        Token comment = token.precedingComments;
        while (comment != null) {
          Set<String> misspelled = spell.spellcheckString(comment.lexeme,
              splitAsCode: true, dictionaries: context.dictionaries);
          if (misspelled != null) {
            errors ??= new List<String>();
            errors.add("Misspelled words around offset ${comment.offset}: "
                "${misspelled.toList()}");
          }
          comment = comment.next;
        }
      }
      if (token is StringToken) {
        Set<String> misspelled = spell.spellcheckString(token.lexeme,
            splitAsCode: true, dictionaries: context.dictionaries);
        if (misspelled != null) {
          errors ??= new List<String>();
          errors.add("Misspelled words around offset ${token.offset}: "
              "${misspelled.toList()}");
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
      // TODO(jensj): Point properly in the source code like compilation errors
      // do.
      return fail(description, errors.join("\n"));
    }
  }
}
