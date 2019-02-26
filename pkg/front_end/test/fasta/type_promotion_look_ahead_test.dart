// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/builder/builder.dart' show Declaration;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/messages.dart'
    show LocatedMessage, templateUnspecified;

import 'package:front_end/src/fasta/parser.dart' show Parser;

import 'package:front_end/src/fasta/scanner.dart' show Token;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:front_end/src/fasta/source/type_promotion_look_ahead_listener.dart'
    show
        TypePromotionLookAheadListener,
        TypePromotionState,
        UnspecifiedDeclaration;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show MatchContext;

import 'package:front_end/src/fasta/testing/scanner_chain.dart'
    show Read, Scan, ScannedFile;

import 'package:kernel/ast.dart' show Source;

import 'package:testing/testing.dart';

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

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  CompilerContext context =
      await CompilerContext.runWithOptions<CompilerContext>(
          new ProcessedOptions(),
          (CompilerContext context) =>
              new Future<CompilerContext>.value(context),
          errorOnMissingInput: false);
  context.disableColors();
  return new TypePromotionLookAheadContext(
      context, environment["updateExpectations"] == "true");
}

class TypePromotionLookAheadContext extends ChainContext with MatchContext {
  final CompilerContext context;

  final List<Step> steps = const <Step>[
    const Read(),
    const Scan(),
    const TypePromotionLookAheadStep(),
    const CheckTypePromotionResult(),
  ];

  final bool updateExpectations;

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));

  TypePromotionLookAheadContext(this.context, this.updateExpectations);
}

class TypePromotionLookAheadStep extends Step<ScannedFile, TypePromotionResult,
    TypePromotionLookAheadContext> {
  const TypePromotionLookAheadStep();

  String get name => "Type Promotion Look Ahead";

  Future<Result<TypePromotionResult>> run(
      ScannedFile file, TypePromotionLookAheadContext context) async {
    return context.context
        .runInContext<Result<TypePromotionResult>>((CompilerContext c) async {
      Uri uri = file.file.uri;
      c.uriToSource[uri] = new Source(file.result.lineStarts, file.file.bytes);
      StringBuffer buffer = new StringBuffer();
      Parser parser = new Parser(new TestListener(uri, buffer));
      try {
        parser.parseUnit(file.result.tokens);
      } finally {
        c.uriToSource.remove(uri);
      }
      return pass(new TypePromotionResult(uri, "$buffer"));
    });
  }
}

class TestState extends TypePromotionState {
  final StringBuffer buffer;

  TestState(Uri uri, this.buffer) : super(uri);

  void note(String message, Token token) {
    buffer.writeln(CompilerContext.current.format(
        debugMessage(message, uri, token.charOffset, token.lexeme.length),
        Severity.context));
  }

  @override
  void checkEmpty(Token token) {
    if (stack.isNotEmpty) {
      throw CompilerContext.current.format(
          debugMessage("Stack not empty", uri, token?.charOffset ?? -1,
              token?.length ?? 1),
          Severity.internalProblem);
    }
  }

  @override
  void declareIdentifier(Token token) {
    super.declareIdentifier(token);
    trace("Declared ${token.lexeme}", token);
  }

  @override
  Declaration nullValue(String name, Token token) {
    return new DebugDeclaration(name, uri, token?.charOffset ?? -1);
  }

  @override
  void registerWrite(UnspecifiedDeclaration declaration, Token token) {
    note("Write to ${declaration.name}@${declaration.charOffset}", token);
  }

  @override
  void registerPromotionCandidate(
      UnspecifiedDeclaration declaration, Token token) {
    note("Possible promotion of ${declaration.name}@${declaration.charOffset}",
        token);
  }

  @override
  void report(LocatedMessage message, Severity severity,
      {List<LocatedMessage> context}) {
    CompilerContext.current.report(message, severity, context: context);
  }

  @override
  void trace(String message, Token token) {
    report(
        debugMessage(message, uri, token?.charOffset ?? -1, token?.length ?? 1),
        Severity.warning);
    for (Object o in stack) {
      String s = "  $o";
      int index = s.indexOf("\n");
      if (index != -1) {
        s = s.substring(0, index) + "...";
      }
      print(s);
    }
    print('------------------\n');
  }
}

LocatedMessage debugMessage(String text, Uri uri, int offset, int length) {
  return templateUnspecified
      .withArguments(text)
      .withLocation(uri, offset, length);
}

class TestListener extends TypePromotionLookAheadListener {
  TestListener(Uri uri, StringBuffer buffer)
      : super(new TestState(uri, buffer));

  @override
  void debugEvent(String name, Token token) {
    state.trace(name, token);
  }
}

class DebugDeclaration extends Declaration {
  final String name;

  @override
  final Uri fileUri;

  @override
  int charOffset;

  DebugDeclaration(this.name, this.fileUri, this.charOffset);

  Declaration get parent => null;

  String get fullNameForErrors => name;

  String toString() => "<<$name@$charOffset>>";
}

class TypePromotionResult {
  final Uri uri;

  final String trace;

  const TypePromotionResult(this.uri, this.trace);
}

class CheckTypePromotionResult
    extends Step<TypePromotionResult, Null, TypePromotionLookAheadContext> {
  const CheckTypePromotionResult();

  String get name => "Check Type Promotion Result";

  Future<Result<Null>> run(
      TypePromotionResult result, TypePromotionLookAheadContext context) {
    return context.match<Null>(
        ".type_promotion.expect", result.trace, result.uri, null);
  }
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../../testing.json");
