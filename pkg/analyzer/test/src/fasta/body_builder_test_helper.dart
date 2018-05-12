// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/fasta/ast_body_builder.dart';
import 'package:analyzer/src/generated/resolver.dart';
import "package:front_end/src/api_prototype/front_end.dart";
import "package:front_end/src/api_prototype/memory_file_system.dart";
import "package:front_end/src/base/processed_options.dart";
import "package:front_end/src/compute_platform_binaries_location.dart";
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/constant_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import "package:front_end/src/fasta/fasta_codes.dart";
import 'package:front_end/src/fasta/kernel/body_builder.dart' hide Identifier;
import 'package:front_end/src/fasta/kernel/forest.dart';
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import "package:front_end/src/fasta/kernel/kernel_target.dart";
import 'package:front_end/src/fasta/modifier.dart' as Modifier;
import 'package:front_end/src/fasta/parser/parser.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:kernel/class_hierarchy.dart' as kernel;
import 'package:kernel/core_types.dart' as kernel;
import 'package:kernel/kernel.dart' as kernel;
import 'package:test/test.dart';

import '../../generated/parser_test.dart';
import '../../generated/test_support.dart';

/**
 * Implementation of [AbstractParserTestCase] specialized for testing building
 * Analyzer AST using the fasta [Forest] API.
 */
class FastaBodyBuilderTestCase extends Object
    with ParserTestHelpers
    implements AbstractParserTestCase {
  // TODO(danrubel): Consider HybridFileSystem.
  static final MemoryFileSystem fs =
      new MemoryFileSystem(Uri.parse("org-dartlang-test:///"));

  /// The custom URI used to locate the dill file in the MemoryFileSystem.
  static final Uri sdkSummary = fs.currentDirectory.resolve("vm_platform.dill");

  /// The in memory test code URI
  static final Uri entryPoint = fs.currentDirectory.resolve("main.dart");

  static ProcessedOptions options;

  static KernelTarget kernelTarget;

  static TypeProvider _typeProvider;

  final bool resolveTypes;

  String content;

  /// The expected offset of the next token to be parsed after the parser has
  /// finished parsing, or `null` (the default) if EOF is expected.
  int expectedEndOffset;

  FastaBodyBuilderTestCase(this.resolveTypes);

  TypeProvider get typeProvider => _typeProvider;

  @override
  void assertNoErrors() {
    // TODO(brianwilkerson) Implement this.
  }

  void createParser(String content, {int expectedEndOffset}) {
    this.content = content;
    this.expectedEndOffset = expectedEndOffset;
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Expression parseAdditiveExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseAssignableExpression(String code, bool primaryAllowed) {
    return parseExpression(code);
  }

  @override
  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional: true}) {
    return parseExpression(code);
  }

  @override
  AwaitExpression parseAwaitExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseBitwiseAndExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseBitwiseOrExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseBitwiseXorExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseCascadeSection(String code) {
    return parseExpression(code);
  }

  @override
  CompilationUnit parseCompilationUnit(String source,
      {List<ErrorCode> codes, List<ExpectedError> errors}) {
    return _parse(source, (parser, token) => parser.parseUnit(token.next));
  }

  @override
  ConditionalExpression parseConditionalExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseConstExpression(String code) {
    return parseExpression(code);
  }

  @override
  ConstructorInitializer parseConstructorInitializer(String code) {
    throw new UnimplementedError();
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    return parseCompilationUnit(content, codes: errorCodes);
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseExpression(String source,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      int expectedEndOffset}) {
    // TODO(brianwilkerson) Check error codes.
    return _parse(source, (parser, token) => parser.parseExpression(token));
  }

  @override
  List<Expression> parseExpressionList(String code) {
    throw new UnimplementedError();
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    return parseExpression(code);
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    throw new UnimplementedError();
  }

  @override
  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[],
      List<ExpectedError> errors}) {
    throw new UnimplementedError();
  }

  @override
  CompilationUnitMember parseFullCompilationUnitMember() {
    CompilationUnit unit = parseCompilationUnit(content);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
    return unit.declarations[0];
  }

  @override
  Directive parseFullDirective() {
    CompilationUnit unit = parseCompilationUnit(content);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
    return unit.directives[0];
  }

  @override
  FunctionExpression parseFunctionExpression(String code) {
    return parseExpression(code);
  }

  @override
  InstanceCreationExpression parseInstanceCreationExpression(
      String code, Token newToken) {
    return parseExpression(code);
  }

  @override
  ListLiteral parseListLiteral(
      Token token, String typeArgumentsCode, String code) {
    return parseExpression(code);
  }

  @override
  TypedLiteral parseListOrMapLiteral(Token modifier, String code) {
    return parseExpression(code);
  }

  @override
  Expression parseLogicalAndExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseLogicalOrExpression(String code) {
    return parseExpression(code);
  }

  @override
  MapLiteral parseMapLiteral(
      Token token, String typeArgumentsCode, String code) {
    return parseExpression(code);
  }

  @override
  MapLiteralEntry parseMapLiteralEntry(String code) {
    Expression expression = parseExpression('{$code}');
    expect(expression, new isInstanceOf<MapLiteral>());
    MapLiteral literal = expression;
    expect(literal.entries, hasLength(1));
    return literal.entries[0];
  }

  @override
  Expression parseMultiplicativeExpression(String code) {
    return parseExpression(code);
  }

  @override
  InstanceCreationExpression parseNewExpression(String code) {
    return parseExpression(code);
  }

  @override
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    throw new UnimplementedError();
  }

  @override
  Expression parsePostfixExpression(String code) {
    return parseExpression(code);
  }

  @override
  Identifier parsePrefixedIdentifier(String code) {
    return parseExpression(code);
  }

  @override
  Expression parsePrimaryExpression(String code,
      {int expectedEndOffset, List<ExpectedError> errors}) {
    return parseExpression(code,
        expectedEndOffset: expectedEndOffset, errors: errors);
  }

  @override
  Expression parseRelationalExpression(String code) {
    return parseExpression(code);
  }

  @override
  RethrowExpression parseRethrowExpression(String code) {
    return parseExpression(code);
  }

  @override
  BinaryExpression parseShiftExpression(String code) {
    return parseExpression(code);
  }

  @override
  SimpleIdentifier parseSimpleIdentifier(String code) {
    return parseExpression(code);
  }

  @override
  Statement parseStatement(String source,
      {bool enableLazyAssignmentOperators, int expectedEndOffset}) {
    // TODO(brianwilkerson) Check error codes.
    return _parse(source, (parser, token) => parser.parseStatement(token));
  }

  @override
  Expression parseStringLiteral(String code) {
    return parseExpression(code);
  }

  @override
  SymbolLiteral parseSymbolLiteral(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseThrowExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseThrowExpressionWithoutCascade(String code) {
    return parseExpression(code);
  }

  @override
  PrefixExpression parseUnaryExpression(String code) {
    return parseExpression(code);
  }

  @override
  VariableDeclarationList parseVariableDeclarationList(String source) {
    throw new UnimplementedError();
  }

  Future setUp() async {
    // TODO(danrubel): Tear down once all tests in group have been run.
    if (options != null) {
      return;
    }

    // Read the dill file containing kernel platform summaries into memory.
    List<int> sdkSummaryBytes = await new File.fromUri(
            computePlatformBinariesLocation().resolve("vm_platform.dill"))
        .readAsBytes();
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryBytes);

    final CompilerOptions optionBuilder = new CompilerOptions()
      ..strongMode = false // TODO(danrubel): enable strong mode.
      ..reportMessages = true
      ..verbose = false
      ..fileSystem = fs
      ..sdkSummary = sdkSummary
      ..onProblem = (FormattedMessage problem, Severity severity,
          List<FormattedMessage> context) {
        // TODO(danrubel): Capture problems and check against expectations.
//        print(problem.formatted);
      };

    options = new ProcessedOptions(optionBuilder, false, [entryPoint]);

    UriTranslatorImpl uriTranslator = await options.getUriTranslator();

    await CompilerContext.runWithOptions(options, (CompilerContext c) async {
      DillTarget dillTarget = new DillTarget(
          new Ticker(isVerbose: false), uriTranslator, options.target);

      kernelTarget = new KernelTarget(fs, true, dillTarget, uriTranslator);

      // Load the dill file containing platform code.
      dillTarget.loader.read(Uri.parse('dart:core'), -1, fileUri: sdkSummary);
      kernel.Component sdkComponent =
          kernel.loadComponentFromBytes(sdkSummaryBytes);
      dillTarget.loader
          .appendLibraries(sdkComponent, byteCount: sdkSummaryBytes.length);
      await dillTarget.buildOutlines();
      await kernelTarget.buildOutlines();
      kernelTarget.computeCoreTypes();
      assert(kernelTarget.loader.coreTypes != null);

      // Initialize the typeProvider if types should be resolved.
      Map<String, Element> map = <String, Element>{};
      var coreTypes = kernelTarget.loader.coreTypes;
      for (var coreType in [
        coreTypes.boolClass,
        coreTypes.doubleClass,
        coreTypes.functionClass,
        coreTypes.futureClass,
        coreTypes.futureOrClass,
        coreTypes.intClass,
        coreTypes.iterableClass,
        coreTypes.iteratorClass,
        coreTypes.listClass,
        coreTypes.mapClass,
        coreTypes.nullClass,
        coreTypes.numClass,
        coreTypes.objectClass,
        coreTypes.stackTraceClass,
        coreTypes.streamClass,
        coreTypes.stringClass,
        coreTypes.symbolClass,
        coreTypes.typeClass
      ]) {
        map[coreType.name] = _buildElement(coreType);
      }
      Namespace namespace = new Namespace(map);
      _typeProvider = new TypeProviderImpl.forNamespaces(namespace, namespace);
    });
  }

  Element _buildElement(kernel.Class coreType) {
    ClassElementImpl element =
        new ClassElementImpl(coreType.name, coreType.fileOffset);
    element.typeParameters = coreType.typeParameters.map((parameter) {
      TypeParameterElementImpl element =
          new TypeParameterElementImpl(parameter.name, parameter.fileOffset);
      element.type = new TypeParameterTypeImpl(element);
      return element;
    }).toList();
    return element;
  }

  T _parse<T>(
      String source, void parseFunction(Parser parser, Token previousToken)) {
    ScannerResult scan = scanString(source);

    return CompilerContext.runWithOptions(options, (CompilerContext c) {
      KernelLibraryBuilder library = new KernelLibraryBuilder(
        entryPoint,
        entryPoint,
        kernelTarget.loader,
        null /* actualOrigin */,
        null /* enclosingLibrary */,
      );
      List<KernelTypeVariableBuilder> typeVariableBuilders =
          <KernelTypeVariableBuilder>[];
      List<KernelFormalParameterBuilder> formalParameterBuilders =
          <KernelFormalParameterBuilder>[];
      KernelProcedureBuilder procedureBuilder = new KernelProcedureBuilder(
          null /* metadata */,
          Modifier.staticMask /* or Modifier.varMask */,
          kernelTarget.dynamicType,
          "analyzerTest",
          typeVariableBuilders,
          formalParameterBuilders,
          kernel.ProcedureKind.Method,
          library,
          -1 /* charOffset */,
          -1 /* charOpenParenOffset */,
          -1 /* charEndOffset */);

      TypeInferrerDisabled typeInferrer =
          new TypeInferrerDisabled(new TypeSchemaEnvironment(
        kernelTarget.loader.coreTypes,
        kernelTarget.loader.hierarchy,
        // TODO(danrubel): Enable strong mode.
        false /* strong mode */,
      ));

      BodyBuilder builder = new AstBodyBuilder(
        library,
        procedureBuilder,
        library.scope,
        procedureBuilder.computeFormalParameterScope(library.scope),
        kernelTarget.loader.hierarchy,
        kernelTarget.loader.coreTypes,
        null /* classBuilder */,
        false /* isInstanceMember */,
        null /* uri */,
        typeInferrer,
        typeProvider,
      )..constantContext = ConstantContext.none; // .inferred ?

      Parser parser = new Parser(builder);
      parseFunction(parser, parser.syntheticPreviousToken(scan.tokens));
      // TODO(brianwilkerson) Check `expectedEndOffset` if it is not `null`.
      return builder.pop();
    });
  }
}
