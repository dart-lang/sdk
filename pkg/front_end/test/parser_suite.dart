// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show Token, Scanner, LanguageVersionToken;
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/source/diet_parser.dart'
    show useImplicitCreationExpressionInCfe;
import 'package:front_end/src/util/parser_ast.dart';
import 'package:front_end/src/util/parser_ast_helper.dart';
import 'package:kernel/ast.dart';
import 'package:testing/testing.dart'
    show Chain, ChainContext, ExpectationSet, Result, Step, TestDescription;

import 'parser_suite_utils.dart';
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

class Context extends ChainContext
    with MatchContext
    implements StandardContextAdditions {
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
  @override
  final SuiteFolderOptions folderOptions;

  @override
  final Map<ExperimentalFlag, bool> forcedExperimentalFlags;
  new({
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
    const TokenStep(true, ".scanner.directives.expect", directivesOnly: true),
    const TokenStep(true, ".scanner.expect"),
    const TokenStep(false, ".parser.expect"),
    const ParserAstStep(true),
    const ListenerStep(true),
    const CompareDirectivesStep(),
    const IntertwinedStep(),
  ];

  @override
  final ExpectationSet expectationSet = new ExpectationSet.fromJsonList(
    jsonDecode(EXPECTATIONS),
  );
}

class ContextChecksOnly extends Context {
  new({
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
    const CompareDirectivesStep(),
    const ParserAstStep(false),
  ];

  @override
  final ExpectationSet expectationSet = new ExpectationSet.fromJsonList(
    jsonDecode(EXPECTATIONS),
  );
}

class ParserAstStep extends Step<TestDescription, TestDescription, Context> {
  final bool enablePossibleExpectFile;
  const new(this.enablePossibleExpectFile);

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
  final bool compareDirectives;

  const new(this.doExpects, {this.compareDirectives = false});

  @override
  String get name => "listener";

  @override
  Future<Result<TestDescription>> run(
    TestDescription description,
    Context context,
  ) {
    Uri uri = description.uri;
    if (compareDirectives) {
      return _compareDirectives(uri, context, description);
    }
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

  Future<Result<TestDescription>> _compareDirectives(
    Uri uri,
    Context context,
    TestDescription description,
  ) {
    ParserTestListenerWithMessageFormatting? scanParseDirectivesOnly =
        doListenerParsing(
          uri,
          context.suiteName,
          description.computeExplicitExperimentalFlags(context),
          description.shortName,
          addTrace: context.addTrace,
          annotateLines: context.annotateLines,
          parseDirectivesOnly: true,
          scanDirectivesOnly: true,
        );
    ParserTestListenerWithMessageFormatting? parseDirectivesOnly =
        doListenerParsing(
          uri,
          context.suiteName,
          description.computeExplicitExperimentalFlags(context),
          description.shortName,
          addTrace: context.addTrace,
          annotateLines: context.annotateLines,
          parseDirectivesOnly: true,
          scanDirectivesOnly: false,
        );
    String? scanParseResult = scanParseDirectivesOnly?.sb.toString();
    String? parseResult = parseDirectivesOnly?.sb.toString();
    if (scanParseResult != parseResult) {
      return Future.value(
        new Result<TestDescription>.fail(
          description,
          "Different definitions:\n$scanParseResult\n\nvs\n\n$parseResult",
        ),
      );
    }
    return Future.value(new Result<TestDescription>.pass(description));
  }
}

class CompareDirectivesStep
    extends Step<TestDescription, TestDescription, Context> {
  const new();

  @override
  String get name => "compare directives";

  @override
  Future<Result<TestDescription>> run(
    TestDescription description,
    Context context,
  ) {
    Uri uri = description.uri;

    ParserTestListenerWithMessageFormatting? scanParseDirectivesOnly =
        doListenerParsing(
          uri,
          context.suiteName,
          description.computeExplicitExperimentalFlags(context),
          description.shortName,
          addTrace: context.addTrace,
          annotateLines: context.annotateLines,
          parseDirectivesOnly: true,
          scanDirectivesOnly: true,
        );
    ParserTestListenerWithMessageFormatting? parseDirectivesOnly =
        doListenerParsing(
          uri,
          context.suiteName,
          description.computeExplicitExperimentalFlags(context),
          description.shortName,
          addTrace: context.addTrace,
          annotateLines: context.annotateLines,
          parseDirectivesOnly: true,
          scanDirectivesOnly: false,
        );
    if (scanParseDirectivesOnly == null || parseDirectivesOnly == null) {
      throw "";
    }
    String? compareResult = compareTestListeners(
      scanParseDirectivesOnly,
      parseDirectivesOnly,
      filters: {"ignoreListenerArguments"},
      ignored: {"beginMetadataStar", "endMetadataStar", "handleDirectivesOnly"},
    );
    if (compareResult != null) {
      return Future.value(
        fail(
          description,
          "$compareResult\n\n"
          "Comparing:\n(scan and parse only directives:)\n\n"
          "${scanParseDirectivesOnly.sb.toString()}"
          "\n\nwith\n(scan normally, parse only directives:)\n\n"
          "${parseDirectivesOnly.sb.toString()}",
          StackTrace.current,
        ),
      );
    }

    return Future.value(new Result<TestDescription>.pass(description));
  }
}

class IntertwinedStep extends Step<TestDescription, TestDescription, Context> {
  const new();

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
  final bool directivesOnly;

  const new(this.onlyScanner, this.suffix, {this.directivesOnly = false});

  @override
  String get name =>
      "token (${directivesOnly
          ? "directives"
          : onlyScanner
          ? "scanner"
          : "parser"})";

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
    List<LanguageVersionToken> languageVersionTokensSeen = [];
    Token firstToken = scanUri(
      description.uri,
      experimentalFeatures,
      lineStarts: lineStarts,
      languageVersionChanged:
          (Scanner scanner, LanguageVersionToken languageVersion) {
            languageVersionTokensSeen.add(languageVersion);
            experimentalFeatures.onLanguageVersionChanged(
              scanner,
              languageVersion,
            );
          },
      directivesOnly: directivesOnly,
    );

    if (directivesOnly &&
        firstToken.isEof &&
        languageVersionTokensSeen.isEmpty) {
      // Expect no file.
      return context.match<TestDescription>(
        suffix,
        // An empty actual parameter deletes any existing file if asked to
        // update expectations.
        "",
        description.uri,
        description,
      );
    }

    StringBuffer beforeParser = tokenStreamToString(
      firstToken,
      lineStarts,
      languageVersionTokensSeen: languageVersionTokensSeen,
    );
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

class ParserTestListenerForIntertwined
    extends ParserTestListenerWithMessageFormatting {
  late TestParser parser;

  new(bool trace, bool annotateLines, Source source)
    : super(trace, annotateLines, source, null);

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
