// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/experiments/errors.dart'
    show getExperimentNotEnabledMessage;
import 'package:_fe_analyzer_shared/src/experiments/flags.dart'
    as shared
    show ExperimentalFlag;
import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show Parser, lengthOfSpan;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show
        ErrorToken,
        ScannerConfiguration,
        ScannerResult,
        Token,
        scan,
        LanguageVersionChanged;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show SyntheticStringToken;
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/base/command_line_reporting.dart'
    as command_line_reporting;
import 'package:front_end/src/base/messages.dart' show Message;
import 'package:front_end/src/source/diet_parser.dart'
    show useImplicitCreationExpressionInCfe;
import 'package:front_end/src/source/stack_listener_impl.dart'
    show offsetForToken;
import 'package:front_end/src/util/parser_ast.dart';
import 'package:front_end/src/util/parser_ast_helper.dart';
import 'package:kernel/ast.dart';
import 'package:testing/testing.dart'
    show Chain, ChainContext, ExpectationSet, Result, Step, TestDescription;

import 'parser_test_listener.dart' show ParserTestListener;
import 'parser_test_parser.dart' show TestParser;
import 'testing/environment_keys.dart';
import 'testing/experimental_features.dart';
import 'testing/folder_options.dart';
import 'testing_utils.dart' show checkEnvironment;
import 'utils/kernel_chain.dart' show MatchContext;
import 'utils/suite_utils.dart';

const String EXPECTATIONS = '''
[
  {
    "name": "ExpectationFileMismatch",
    "group": "Fail"
  },
  {
    "name": "ExpectationFileMissing",
    "group": "Fail"
  }
]
''';

void main([List<String> arguments = const []]) => internalMain(
  createContext,
  arguments: arguments,
  displayName: "parser suite",
  configurationPath: "../testing.json",
);

Future<Context> createContext(Chain suite, Map<String, String> environment) {
  const Set<String> knownEnvironmentKeys = {
    EnvironmentKeys.updateExpectations,
    EnvironmentKeys.trace,
    EnvironmentKeys.annotateLines,
  };
  checkEnvironment(environment, knownEnvironmentKeys);

  bool updateExpectations =
      environment[EnvironmentKeys.updateExpectations] == "true";
  bool trace = environment[EnvironmentKeys.trace] == "true";
  bool annotateLines = environment[EnvironmentKeys.annotateLines] == "true";

  return new Future.value(
    new Context(
      baseUri: suite.root,
      suiteName: suite.name,
      updateExpectations: updateExpectations,
      addTrace: trace,
      annotateLines: annotateLines,
      environment: environment,
    ),
  );
}

ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
  enableTripleShift: true,
  forAugmentationLibrary: false,
);

ScannerConfiguration scannerConfigurationNonTripleShift =
    new ScannerConfiguration(
      enableTripleShift: false,
      forAugmentationLibrary: false,
    );

ScannerConfiguration scannerConfigurationAugmentation =
    new ScannerConfiguration(
      enableTripleShift: true,
      forAugmentationLibrary: true,
    );

class Context extends ChainContext with MatchContext {
  @override
  final bool updateExpectations;

  @override
  String get updateExpectationsOption =>
      '${EnvironmentKeys.updateExpectations}=true';

  @override
  bool get canBeFixWithUpdateExpectations => true;

  final bool addTrace;
  final bool annotateLines;
  final String suiteName;
  final SuiteFolderOptions folderOptions;

  final Map<ExperimentalFlag, bool> forcedExperimentalFlags;
  Context({
    required Uri baseUri,
    required this.suiteName,
    required this.updateExpectations,
    required this.addTrace,
    required this.annotateLines,
    required Map<String, String> environment,
  }) : folderOptions = new SuiteFolderOptions(baseUri),
       forcedExperimentalFlags =
           SuiteFolderOptions.computeForcedExperimentalFlags(environment);

  @override
  final List<Step> steps = const <Step>[
    const TokenStep(true, ".scanner.expect"),
    const TokenStep(false, ".parser.expect"),
    const ParserAstStep(true),
    const ListenerStep(true),
    const IntertwinedStep(),
  ];

  @override
  final ExpectationSet expectationSet = new ExpectationSet.fromJsonList(
    jsonDecode(EXPECTATIONS),
  );
}

class ContextChecksOnly extends Context {
  ContextChecksOnly({
    required Uri baseUri,
    required String suiteName,
    required Map<String, String> environment,
  }) : super(
         baseUri: baseUri,
         suiteName: suiteName,
         updateExpectations: false,
         addTrace: false,
         annotateLines: false,
         environment: environment,
       );

  @override
  final List<Step> steps = const <Step>[
    const ListenerStep(false),
    const ParserAstStep(false),
  ];

  @override
  final ExpectationSet expectationSet = new ExpectationSet.fromJsonList(
    jsonDecode(EXPECTATIONS),
  );
}

class ParserAstStep extends Step<TestDescription, TestDescription, Context> {
  final bool enablePossibleExpectFile;
  const ParserAstStep(this.enablePossibleExpectFile);

  @override
  String get name => "ParserAst";

  @override
  Future<Result<TestDescription>> run(
    TestDescription description,
    Context context,
  ) {
    FolderOptions folderOptions = description.computeFolderOptions(context);
    Uri uri = description.uri;
    File f = new File.fromUri(uri);
    Uint8List rawBytes = f.readAsBytesSync();
    ParserAstNode ast = getAST(rawBytes);
    if (ast.what != "CompilationUnit") {
      throw "Expected a single element for 'CompilationUnit' "
          "but got ${ast.what}";
    }
    if (enablePossibleExpectFile && folderOptions.withOutline) {
      ExtractSomeMembers indexer = new ExtractSomeMembers();
      ast.accept(indexer);
      return context.match<TestDescription>(
        ".outline.expect",
        indexer.sb.toString(),
        description.uri,
        description,
      );
    }
    return new Future.value(new Result<TestDescription>.pass(description));
  }
}

class ExtractSomeMembers extends RecursiveParserAstVisitor {
  StringBuffer sb = new StringBuffer();
  String? currentContainerName;

  @override
  void visitClassDeclarationEnd(ClassDeclarationEnd node) {
    currentContainerName = node.getClassIdentifier().token.lexeme;
    sb.writeln("Class: $currentContainerName");
    super.visitClassDeclarationEnd(node);
    currentContainerName = null;
  }

  @override
  void visitTopLevelMethodEnd(TopLevelMethodEnd node) {
    String name = node.getNameIdentifier().token.lexeme;
    sb.writeln("Top-level method: $name");
  }

  @override
  void visitMethodEnd(MethodEnd node) {
    sb.writeln("Method: $currentContainerName.${node.getNameIdentifier()}");
  }
}

class ListenerStep extends Step<TestDescription, TestDescription, Context> {
  final bool doExpects;

  const ListenerStep(this.doExpects);

  @override
  String get name => "listener";

  /// Scans the uri, parses it with the test listener and returns it.
  ///
  /// Returns null if scanner doesn't return any Token.
  static ParserTestListenerWithMessageFormatting? doListenerParsing(
    Uri uri,
    String suiteName,
    Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    String shortName, {
    bool addTrace = false,
    bool annotateLines = false,
  }) {
    ExperimentalFeaturesFromFlags experimentalFeatures =
        new ExperimentalFeaturesFromFlags(explicitExperimentalFlags);
    List<int> lineStarts = <int>[];
    Token firstToken = scanUri(
      uri,
      experimentalFeatures,
      lineStarts: lineStarts,
      languageVersionChanged: experimentalFeatures.onLanguageVersionChanged,
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
    parser.parseUnit(firstToken);
    return parserTestListener;
  }

  @override
  Future<Result<TestDescription>> run(
    TestDescription description,
    Context context,
  ) {
    Uri uri = description.uri;
    ParserTestListenerWithMessageFormatting? parserTestListener =
        doListenerParsing(
          uri,
          context.suiteName,
          description.computeExplicitExperimentalFlags(context),
          description.shortName,
          addTrace: context.addTrace,
          annotateLines: context.annotateLines,
        );
    if (parserTestListener == null) {
      return Future.value(crash(description, StackTrace.current));
    }

    String errors = "";
    if (parserTestListener.errors.isNotEmpty) {
      errors =
          "Problems reported:\n\n"
          "${parserTestListener.errors.join("\n\n")}\n\n";
    }

    if (doExpects) {
      return context.match<TestDescription>(
        ".expect",
        "${errors}${parserTestListener.sb}",
        uri,
        description,
      );
    } else {
      return new Future.value(new Result<TestDescription>.pass(description));
    }
  }
}

class IntertwinedStep extends Step<TestDescription, TestDescription, Context> {
  const IntertwinedStep();

  @override
  String get name => "intertwined";

  @override
  Future<Result<TestDescription>> run(
    TestDescription description,
    Context context,
  ) {
    List<int> lineStarts = <int>[];
    Map<ExperimentalFlag, bool> explicitExperimentalFlags = description
        .computeExplicitExperimentalFlags(context);
    ExperimentalFeaturesFromFlags experimentalFeatures =
        new ExperimentalFeaturesFromFlags(explicitExperimentalFlags);
    Token firstToken = scanUri(
      description.uri,
      experimentalFeatures,
      lineStarts: lineStarts,
      languageVersionChanged: experimentalFeatures.onLanguageVersionChanged,
    );

    File f = new File.fromUri(description.uri);
    Uint8List rawBytes = f.readAsBytesSync();
    Source source = new Source(
      lineStarts,
      rawBytes,
      description.uri,
      description.uri,
    );

    ParserTestListenerForIntertwined parserTestListener =
        new ParserTestListenerForIntertwined(
          context.addTrace,
          context.annotateLines,
          source,
        );
    TestParser parser = new TestParser(
      parserTestListener,
      context.addTrace,
      experimentalFeatures: experimentalFeatures,
    );
    parserTestListener.parser = parser;
    parser.sb = parserTestListener.sb;
    parser.parseUnit(firstToken);

    return context.match<TestDescription>(
      ".intertwined.expect",
      "${parser.sb}",
      description.uri,
      description,
    );
  }
}

class TokenStep extends Step<TestDescription, TestDescription, Context> {
  final bool onlyScanner;
  final String suffix;

  const TokenStep(this.onlyScanner, this.suffix);

  @override
  String get name => "token";

  @override
  Future<Result<TestDescription>> run(
    TestDescription description,
    Context context,
  ) {
    Map<ExperimentalFlag, bool> explicitExperimentalFlags = description
        .computeExplicitExperimentalFlags(context);
    ExperimentalFeaturesFromFlags experimentalFeatures =
        new ExperimentalFeaturesFromFlags(explicitExperimentalFlags);
    List<int> lineStarts = <int>[];
    Token firstToken = scanUri(
      description.uri,
      experimentalFeatures,
      lineStarts: lineStarts,
      languageVersionChanged: experimentalFeatures.onLanguageVersionChanged,
    );

    StringBuffer beforeParser = tokenStreamToString(firstToken, lineStarts);
    StringBuffer beforeParserWithTypes = tokenStreamToString(
      firstToken,
      lineStarts,
      addTypes: true,
    );
    if (onlyScanner) {
      return context.match<TestDescription>(
        suffix,
        "${beforeParser}\n\n${beforeParserWithTypes}",
        description.uri,
        description,
      );
    }

    ParserTestListener parserTestListener = new ParserTestListener(
      context.addTrace,
    );
    Parser parser = new Parser(
      parserTestListener,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: experimentalFeatures,
    );
    bool parserCrashed = false;
    dynamic parserCrashedE;
    StackTrace? parserCrashedSt;
    try {
      parser.parseUnit(firstToken);
    } catch (e, st) {
      parserCrashed = true;
      parserCrashedE = e;
      parserCrashedSt = st;
    }

    StringBuffer afterParser = tokenStreamToString(firstToken, lineStarts);
    StringBuffer afterParserWithTypes = tokenStreamToString(
      firstToken,
      lineStarts,
      addTypes: true,
    );

    bool rewritten =
        beforeParserWithTypes.toString() != afterParserWithTypes.toString();
    String rewrittenString = rewritten
        ? "NOTICE: Stream was rewritten by parser!\n\n"
        : "";

    Future<Result<TestDescription>> result = context.match<TestDescription>(
      suffix,
      "${rewrittenString}${afterParser}\n\n${afterParserWithTypes}",
      description.uri,
      description,
    );
    return result.then((result) {
      if (parserCrashed) {
        return crash("Parser crashed: $parserCrashedE", parserCrashedSt!);
      } else {
        return result;
      }
    });
  }
}

StringBuffer tokenStreamToString(
  Token firstToken,
  List<int> lineStarts, {
  bool addTypes = false,
}) {
  StringBuffer sb = new StringBuffer();
  Token? token = firstToken;

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

Token scanUri(
  Uri uri,
  ExperimentalFeaturesFromFlags experimentalFeatures, {
  List<int>? lineStarts,
  LanguageVersionChanged? languageVersionChanged,
}) {
  File f = new File.fromUri(uri);
  Uint8List rawBytes = f.readAsBytesSync();
  return scanRawBytes(
    rawBytes,
    experimentalFeatures.scannerConfiguration,
    lineStarts,
    languageVersionChanged: languageVersionChanged,
  );
}

Token scanRawBytes(
  Uint8List rawBytes,
  ScannerConfiguration config,
  List<int>? lineStarts, {
  LanguageVersionChanged? languageVersionChanged,
}) {
  ScannerResult scanResult = scan(
    rawBytes,
    configuration: config,
    includeComments: true,
    languageVersionChanged: languageVersionChanged,
  );
  Token firstToken = scanResult.tokens;
  if (lineStarts != null) {
    lineStarts.addAll(scanResult.lineStarts);
  }
  return firstToken;
}

class ParserTestListenerWithMessageFormatting extends ParserTestListener {
  final bool annotateLines;
  final Source? source;
  final String? shortName;
  final List<String> errors = <String>[];
  Location? latestSeenLocation;

  ParserTestListenerWithMessageFormatting(
    bool trace,
    this.annotateLines,
    this.source,
    this.shortName,
  ) : super(trace);

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

  @override
  bool checkEof(Token token) {
    bool result = super.checkEof(token);
    if (result) {
      errors.add("WARNING: Reporting at eof --- see below for details.");
    }
    return result;
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
}

class ParserTestListenerForIntertwined
    extends ParserTestListenerWithMessageFormatting {
  late TestParser parser;

  ParserTestListenerForIntertwined(
    bool trace,
    bool annotateLines,
    Source source,
  ) : super(trace, annotateLines, source, null);

  @override
  void doPrint(String s) {
    int prevIndent = super.indent;
    super.indent = parser.indent;
    if (s.trim() == "") {
      super.doPrint("");
    } else {
      super.doPrint("listener: " + s);
    }
    super.indent = prevIndent;
  }
}

extension on TestDescription {
  FolderOptions computeFolderOptions(Context context) {
    return context.folderOptions.computeFolderOptions(this);
  }

  Map<ExperimentalFlag, bool> computeExplicitExperimentalFlags(
    Context context,
  ) {
    return computeFolderOptions(
      context,
    ).computeExplicitExperimentalFlags(context.forcedExperimentalFlags);
  }
}
