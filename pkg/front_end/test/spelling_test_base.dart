// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show ErrorToken;

import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show Token, KeywordToken, BeginToken;

import 'package:_fe_analyzer_shared/src/scanner/token.dart';

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:front_end/src/fasta/command_line_reporting.dart'
    as command_line_reporting;

import 'package:kernel/kernel.dart';

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, TestDescription;

import 'spell_checking_utils.dart' as spell;

import 'testing_utils.dart' show filterList;

abstract class SpellContext extends ChainContext {
  final List<Step> steps = const <Step>[
    const SpellTest(),
  ];

  final bool interactive;
  final bool onlyInGit;

  SpellContext({this.interactive, this.onlyInGit});

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }

  List<spell.Dictionaries> get dictionaries;

  bool get onlyDenylisted;

  String get repoRelativeSuitePath;

  Set<String> reportedWords = {};
  Set<String> reportedWordsDenylisted = {};

  @override
  Stream<TestDescription> list(Chain suite) {
    return filterList(suite, onlyInGit, super.list(suite));
  }

  @override
  Future<void> postRun() {
    String dartPath = Platform.resolvedExecutable;
    Uri suiteUri = spell.repoDir.resolve(repoRelativeSuitePath);
    File suiteFile = new File.fromUri(suiteUri).absolute;
    if (!suiteFile.existsSync()) {
      throw "Specified suite path is invalid.";
    }
    String suitePath = suiteFile.path;
    spell.spellSummarizeAndInteractiveMode(
        reportedWords,
        reportedWordsDenylisted,
        dictionaries,
        interactive,
        '"$dartPath" "$suitePath" -DonlyInGit=$onlyInGit -Dinteractive=true');
    return null;
  }
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
    void addErrorMessage(
        int offset, String word, bool denylisted, List<String> alternatives) {
      errors ??= <String>[];
      String message;
      if (denylisted) {
        message = "Misspelled word: '$word' has explicitly been denylisted.";
        context.reportedWordsDenylisted.add(word);
      } else {
        message = "The word '$word' is not in our dictionary.";
        context.reportedWords.add(word);
      }
      if (alternatives != null && alternatives.isNotEmpty) {
        message += "\n\nThe following word(s) was 'close' "
            "and in our dictionary: "
            "${alternatives.join(", ")}\n";
      }
      if (context.dictionaries.isNotEmpty) {
        String dictionaryPathString = context.dictionaries
            .map((d) => spell.dictionaryToUri(d).toString())
            .join("\n- ");
        message += "\n\nIf the word is correctly spelled please add "
            "it to one of these files:\n"
            "- $dictionaryPathString\n";
      }
      Location location = source.getLocation(description.uri, offset);
      errors.add(command_line_reporting.formatErrorMessage(
          source.getTextLine(location.line),
          location,
          word.length,
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
              bool denylisted = spellingResult.misspelledWordsDenylisted[i];
              if (context.onlyDenylisted && !denylisted) continue;
              int offset =
                  comment.offset + spellingResult.misspelledWordsOffset[i];
              addErrorMessage(offset, spellingResult.misspelledWords[i],
                  denylisted, spellingResult.misspelledWordsAlternatives[i]);
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
            bool denylisted = spellingResult.misspelledWordsDenylisted[i];
            if (context.onlyDenylisted && !denylisted) continue;
            int offset = token.offset + spellingResult.misspelledWordsOffset[i];
            addErrorMessage(offset, spellingResult.misspelledWords[i],
                denylisted, spellingResult.misspelledWordsAlternatives[i]);
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
