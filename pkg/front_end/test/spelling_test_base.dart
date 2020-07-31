// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show File, Platform, stdin, stdout;

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
    show ChainContext, Result, Step, TestDescription;

import 'spell_checking_utils.dart' as spell;

abstract class SpellContext extends ChainContext {
  final List<Step> steps = const <Step>[
    const SpellTest(),
  ];

  final bool interactive;

  SpellContext({this.interactive});

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }

  List<spell.Dictionaries> get dictionaries;

  bool get onlyDenylisted;

  Set<String> reportedWords = {};
  Set<String> reportedWordsDenylisted = {};

  @override
  Future<void> postRun() {
    if (reportedWordsDenylisted.isNotEmpty) {
      print("\n\n\n");
      print("================");
      print("The following words was reported as used and denylisted:");
      print("----------------");
      for (String s in reportedWordsDenylisted) {
        print("$s");
      }
      print("================");
    }
    if (reportedWords.isNotEmpty) {
      print("\n\n\n");
      print("================");
      print("The following word(s) were reported as unknown:");
      print("----------------");

      spell.Dictionaries dictionaryToUse;
      if (dictionaries.contains(spell.Dictionaries.cfeTests)) {
        dictionaryToUse = spell.Dictionaries.cfeTests;
      } else if (dictionaries.contains(spell.Dictionaries.cfeMessages)) {
        dictionaryToUse = spell.Dictionaries.cfeMessages;
      } else if (dictionaries.contains(spell.Dictionaries.cfeCode)) {
        dictionaryToUse = spell.Dictionaries.cfeCode;
      } else {
        for (spell.Dictionaries dictionary in dictionaries) {
          if (dictionaryToUse == null ||
              dictionary.index < dictionaryToUse.index) {
            dictionaryToUse = dictionary;
          }
        }
      }

      if (interactive && dictionaryToUse != null) {
        List<String> addedWords = new List<String>();
        for (String s in reportedWords) {
          print("- $s");
          stdout.write("Do you want to add the word to the dictionary "
              "$dictionaryToUse (y/n)? ");
          String answer = stdin.readLineSync().trim().toLowerCase();
          bool add;
          switch (answer) {
            case "y":
            case "yes":
            case "true":
              add = true;
              break;
            case "n":
            case "no":
            case "false":
              add = false;
              break;
            default:
              throw "Didn't understand '$answer'";
          }
          if (add) {
            addedWords.add(s);
          }
        }
        if (addedWords.isNotEmpty) {
          File dictionaryFile =
              new File.fromUri(spell.dictionaryToUri(dictionaryToUse));
          List<String> lines = dictionaryFile.readAsLinesSync();
          List<String> header = new List<String>();
          List<String> sortThis = new List<String>();
          for (String line in lines) {
            if (line.startsWith("#")) {
              header.add(line);
            } else if (line.trim().isEmpty && sortThis.isEmpty) {
              header.add(line);
            } else if (line.trim().isNotEmpty) {
              sortThis.add(line);
            }
          }
          sortThis.addAll(addedWords);
          sortThis.sort();
          lines = new List<String>();
          lines.addAll(header);
          if (header.isEmpty || header.last.isNotEmpty) {
            lines.add("");
          }
          lines.addAll(sortThis);
          lines.add("");
          dictionaryFile.writeAsStringSync(lines.join("\n"));
        }
      } else {
        for (String s in reportedWords) {
          print("$s");
        }
        if (dictionaries.isNotEmpty) {
          print("----------------");
          print("If the word(s) are correctly spelled please add it to one of "
              "these files:");
          for (spell.Dictionaries dictionary in dictionaries) {
            print(" - ${spell.dictionaryToUri(dictionary)}");
          }

          print("");
          print("To add words easily, try to run this script in interactive "
              "mode via the command");
          print("dart ${Platform.script.toFilePath()} -Dinteractive=true");
        }
      }
      print("================");
    }
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
      errors ??= new List<String>();
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
