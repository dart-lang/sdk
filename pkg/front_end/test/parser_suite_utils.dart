// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/experiments/errors.dart'
    show getExperimentNotEnabledMessage;
import 'package:_fe_analyzer_shared/src/experiments/flags.dart'
    as shared
    show ExperimentalFlag;
import 'package:_fe_analyzer_shared/src/parser/experimental_features.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show Parser, lengthOfSpan;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show
        ErrorToken,
        LanguageVersionChanged,
        LanguageVersionToken,
        ScannerConfiguration,
        ScannerResult,
        Token,
        scan,
        scanDirectives;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show SyntheticStringToken;
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;
import 'package:front_end/src/base/command_line_reporting.dart'
    as command_line_reporting;
import 'package:front_end/src/base/messages.dart' show Message;
import 'package:front_end/src/source/diet_parser.dart'
    show useImplicitCreationExpressionInCfe;
import 'package:front_end/src/source/stack_listener_impl.dart'
    show offsetForToken;
import 'package:kernel/ast.dart';
import 'package:testing/testing.dart' show TestDescription;

import 'parser_test_listener.dart' show ParserTestListener;
import 'testing/experimental_features.dart' show ExperimentalFeaturesFromFlags;
import 'testing/folder_options.dart' show FolderOptions, SuiteFolderOptions;

String? compareTestListeners(
  ParserTestListenerWithMessageFormatting a,
  ParserTestListenerWithMessageFormatting b, {
  required Set<String> filters,
  required Set<String> ignored,
}) {
  List<String> aLines = a.sb.toString().split("\n");
  List<String> bLines = b.sb.toString().split("\n");

  bool doRemoveListenerArguments = filters.contains("ignoreListenerArguments");

  int aIndex = 0;
  int bIndex = 0;
  while (aIndex < aLines.length && bIndex < bLines.length) {
    String aLine = aLines[aIndex];
    String bLine = bLines[bIndex];
    if (doRemoveListenerArguments) {
      aLine = removeListenerArguments(aLine);
      bLine = removeListenerArguments(bLine);
    }
    bool anyIgnored = false;
    if (ignored.contains(aLine.trim())) {
      anyIgnored = true;
      aIndex++;
    }
    if (ignored.contains(bLine.trim())) {
      anyIgnored = true;
      bIndex++;
    }
    if (anyIgnored) continue;
    if (aLine.trim() != bLine.trim()) {
      return "Disagreement: '${aLine}' vs '${bLine}'";
    }
    aIndex++;
    bIndex++;
  }

  // Any trailing lines?
  while (aIndex < aLines.length) {
    String aLine = aLines[aIndex];
    if (doRemoveListenerArguments) {
      aLine = removeListenerArguments(aLine);
    }
    if (ignored.contains(aLine.trim())) {
      aIndex++;
      continue;
    }
    return "Unmatched line at end: '$aLine'";
  }
  while (bIndex < bLines.length) {
    String bLine = bLines[bIndex];
    if (doRemoveListenerArguments) {
      bLine = removeListenerArguments(bLine);
    }
    if (ignored.contains(bLine.trim())) {
      bIndex++;
      continue;
    }
    return "Unmatched line at end: '$bLine'";
  }
  return null;
}

/// Scans the uri, parses it with the test listener and returns it.
///
/// Returns null if scanner doesn't return any Token.
ParserTestListenerWithMessageFormatting? doListenerParsing(
  Uri uri,
  String suiteName,
  Map<ExperimentalFlag, bool> explicitExperimentalFlags,
  String shortName, {
  bool addTrace = false,
  bool annotateLines = false,
  bool scanDirectivesOnly = false,
  bool parseDirectivesOnly = false,
}) {
  ExperimentalFeaturesFromFlags experimentalFeatures =
      new ExperimentalFeaturesFromFlags(explicitExperimentalFlags);
  List<int> lineStarts = <int>[];
  Token firstToken = scanUri(
    uri,
    experimentalFeatures,
    lineStarts: lineStarts,
    languageVersionChanged: experimentalFeatures.onLanguageVersionChanged,
    directivesOnly: scanDirectivesOnly,
  );

  File f = new File.fromUri(uri);
  Uint8List rawBytes = f.readAsBytesSync();
  Source source = new Source(lineStarts, rawBytes, uri, uri);
  String shortNameId = "${suiteName}/${shortName}";
  ParserTestListenerWithMessageFormatting parserTestListener =
      new ParserTestListenerWithMessageFormatting(
        addTrace,
        annotateLines,
        source,
        shortNameId,
      );
  Parser parser = new Parser(
    parserTestListener,
    useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
    experimentalFeatures: experimentalFeatures,
  );
  if (parseDirectivesOnly) {
    parser.parseDirectives(firstToken);
  } else {
    parser.parseUnit(firstToken);
  }
  return parserTestListener;
}

String removeListenerArguments(String s) {
  int index = s.indexOf("(");
  if (index < 0) return s;
  return s.substring(0, index);
}

Token scanRawBytes(
  Uint8List rawBytes,
  ScannerConfiguration config,
  List<int>? lineStarts, {
  LanguageVersionChanged? languageVersionChanged,
  bool directivesOnly = false,
}) {
  ScannerResult scanResult;
  if (directivesOnly) {
    scanResult = scanDirectives(
      rawBytes,
      configuration: config,
      languageVersionChanged: languageVersionChanged,
    );
  } else {
    scanResult = scan(
      rawBytes,
      configuration: config,
      includeComments: true,
      languageVersionChanged: languageVersionChanged,
    );
  }
  Token firstToken = scanResult.tokens;
  if (lineStarts != null) {
    lineStarts.addAll(scanResult.lineStarts);
  }
  return firstToken;
}

Token scanUri(
  Uri uri,
  ExperimentalFeaturesFromFlags experimentalFeatures, {
  List<int>? lineStarts,
  LanguageVersionChanged? languageVersionChanged,
  bool directivesOnly = false,
}) {
  File f = new File.fromUri(uri);
  Uint8List rawBytes = f.readAsBytesSync();
  return scanRawBytes(
    rawBytes,
    experimentalFeatures.buildScannerConfiguration(),
    lineStarts,
    languageVersionChanged: languageVersionChanged,
    directivesOnly: directivesOnly,
  );
}

StringBuffer tokenStreamToString(
  Token firstToken,
  List<int> lineStarts, {
  bool addTypes = false,
  List<LanguageVersionToken>? languageVersionTokensSeen,
}) {
  StringBuffer sb = new StringBuffer();
  Token? token = firstToken;

  if (languageVersionTokensSeen != null) {
    for (LanguageVersionToken languageVersion in languageVersionTokensSeen) {
      sb.writeln(
        "// @dart = ${languageVersion.major}.${languageVersion.minor}",
      );
    }
  }

  Token? process(Token? token, bool errorTokens) {
    bool printed = false;
    int endOfLast = -1;
    int lineStartsIteratorLine = 1;
    Iterator<int> lineStartsIterator = lineStarts.iterator;
    lineStartsIterator.moveNext();
    lineStartsIterator.moveNext();
    lineStartsIteratorLine++;

    Set<Token> seenTokens = new Set<Token>.identity();
    while (token != null) {
      if (errorTokens && token is! ErrorToken) return token;
      if (!errorTokens && token is ErrorToken) {
        if (token == token.next) break;
        token = token.next;
        continue;
      }

      int prevLine = lineStartsIteratorLine;
      while (token.offset >= lineStartsIterator.current &&
          lineStartsIterator.moveNext()) {
        lineStartsIteratorLine++;
      }
      if (printed &&
          (token.offset > endOfLast || prevLine < lineStartsIteratorLine)) {
        if (prevLine < lineStartsIteratorLine) {
          for (int i = prevLine; i < lineStartsIteratorLine; i++) {
            sb.write("\n");
          }
        } else {
          sb.write(" ");
        }
      }
      if (token is! ErrorToken) {
        sb.write(token.lexeme);
        if (!addTypes && token.lexeme == "" && token is SyntheticStringToken) {
          sb.write("*synthetic*");
        }
      }
      if (addTypes) {
        // Avoid 6000+ changes caused by "Impl" being added to some token
        // classes.
        String type = token.runtimeType.toString().replaceFirst("Impl", "");
        sb.write("[$type]");
      }
      printed = true;
      endOfLast = token.end;
      if (token == token.next) break;
      token = token.next;
      if (!seenTokens.add(token!)) {
        // Loop in tokens: Print error and break to avoid infinite loop.
        sb.write(
          "\n\nERROR: Loop in tokens: $token "
          "(${token.runtimeType}, ${token.type}, ${token.offset})) "
          "was seen before "
          "(linking to ${token.next}, ${token.next.runtimeType}, "
          "${token.next!.type}, ${token.next!.offset})!\n\n",
        );
        break;
      }
    }

    return token;
  }

  if (addTypes) {
    token = process(token, true);
  }
  token = process(token, false);

  return sb;
}

class ParserTestListenerWithMessageFormatting extends ParserTestListener {
  final bool annotateLines;
  final Source? source;
  final String? shortName;
  final List<String> errors = <String>[];
  Location? latestSeenLocation;

  new(bool trace, this.annotateLines, this.source, this.shortName)
    : super(trace);

  @override
  bool checkEof(Token token) {
    bool result = super.checkEof(token);
    if (result) {
      errors.add("WARNING: Reporting at eof --- see below for details.");
    }
    return result;
  }

  @override
  void doPrint(String s) {
    super.doPrint(s);
    if (!annotateLines) {
      if (s.startsWith("beginCompilationUnit(") ||
          s.startsWith("endCompilationUnit(")) {
        if (indent != 0) {
          throw "Incorrect indents: '$s' (indent = $indent).\n\n"
              "${sb.toString()}";
        }
      } else {
        if (indent <= 0) {
          throw "Incorrect indents: '$s' (indent = $indent).\n\n"
              "${sb.toString()}";
        }
      }
    }
  }

  @override
  void handleExperimentNotEnabled(
    shared.ExperimentalFlag experimentalFlag,
    Token startToken,
    Token endToken,
  ) {
    _reportMessage(
      getExperimentNotEnabledMessage(experimentalFlag),
      startToken,
      endToken,
    );
    super.handleExperimentNotEnabled(experimentalFlag, startToken, endToken);
  }

  @override
  void handleRecoverableError(
    Message message,
    Token startToken,
    Token endToken,
  ) {
    _reportMessage(message, startToken, endToken);
    super.handleRecoverableError(message, startToken, endToken);
  }

  @override
  void seen(Token? token) {
    if (!annotateLines) return;
    if (token == null) return;
    if (source == null) return;
    if (offsetForToken(token) < 0) return;
    Location location = source!.getLocation(
      source!.fileUri!,
      offsetForToken(token),
    );
    if (latestSeenLocation == null ||
        location.line > latestSeenLocation!.line) {
      latestSeenLocation = location;
      String? sourceLine = source!.getTextLine(location.line);
      doPrint("");
      doPrint("// Line ${location.line}: $sourceLine");
    }
  }

  void _reportMessage(Message message, Token startToken, Token endToken) {
    if (source != null) {
      Location location = source!.getLocation(
        source!.fileUri!,
        offsetForToken(startToken),
      );
      int length = lengthOfSpan(startToken, endToken);
      if (length <= 0) length = 1;
      errors.add(
        command_line_reporting.formatErrorMessage(
          source!.getTextLine(location.line),
          location,
          length,
          shortName,
          message.problemMessage,
        ),
      );
    } else {
      errors.add(message.problemMessage);
    }
  }
}

abstract interface class StandardContextAdditions {
  SuiteFolderOptions get folderOptions;
  Map<ExperimentalFlag, bool> get forcedExperimentalFlags;
}

extension TestDescriptionHelper on TestDescription {
  Map<ExperimentalFlag, bool> computeExplicitExperimentalFlags(
    StandardContextAdditions context,
  ) {
    return computeFolderOptions(context)
        .computeExplicitExperimentalFlags(context.forcedExperimentalFlags);
  }

  FolderOptions computeFolderOptions(StandardContextAdditions context) {
    return context.folderOptions.computeFolderOptions(this);
  }
}
