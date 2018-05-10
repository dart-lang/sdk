// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
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
import 'package:front_end/src/fasta/kernel/body_builder.dart';
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
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_test.dart';

main() async {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolutionTest);
  });
}

/**
 * Implementation of [AbstractParserTestCase] specialized for testing building
 * Analyzer AST using the fasta [Forest] API.
 */
class FastaParserTestCase {
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

  TypeProvider get typeProvider => _typeProvider;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Expression parseExpression(String code) {
    ScannerResult scan = scanString(code);

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
      )..constantContext = ConstantContext.none; // .inferred ?

      Parser parser = new Parser(builder);
      parser.parseExpression(parser.syntheticPreviousToken(scan.tokens));
      return builder.pop();
    });
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
        print(problem.formatted);
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
}

// TODO(ahe): Remove this class when we no longer need to override `forest`.
/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
@reflectiveTest
class ResolutionTest extends FastaParserTestCase {
  @failingTest
  test_booleanLiteral_false() {
    Expression result = parseExpression('false');
    expect(result, new isInstanceOf<BooleanLiteral>());
    expect((result as BooleanLiteral).staticType,
        FastaParserTestCase._typeProvider.boolType);
  }

  @failingTest
  test_booleanLiteral_true() {
    Expression result = parseExpression('true');
    expect(result, new isInstanceOf<BooleanLiteral>());
    expect((result as BooleanLiteral).staticType,
        FastaParserTestCase._typeProvider.boolType);
  }

  @failingTest
  test_doubleLiteral_negative() {
    Expression result = parseExpression('-5.1');
    expect(result, new isInstanceOf<DoubleLiteral>());
    expect((result as DoubleLiteral).staticType,
        FastaParserTestCase._typeProvider.doubleType);
  }

  @failingTest
  test_doubleLiteral_positive() {
    Expression result = parseExpression('4.2');
    expect(result, new isInstanceOf<DoubleLiteral>());
    expect((result as DoubleLiteral).staticType,
        FastaParserTestCase._typeProvider.doubleType);
  }

  @failingTest
  test_integerLiteral_negative() {
    Expression result = parseExpression('-6');
    expect(result, new isInstanceOf<IntegerLiteral>());
    expect((result as IntegerLiteral).staticType,
        FastaParserTestCase._typeProvider.intType);
  }

  @failingTest
  test_integerLiteral_positive() {
    Expression result = parseExpression('3');
    expect(result, new isInstanceOf<IntegerLiteral>());
    expect((result as IntegerLiteral).staticType,
        FastaParserTestCase._typeProvider.intType);
  }

  @failingTest
  test_listLiteral_explicitType() {
    Expression result = parseExpression('<int>[]');
    expect(result, new isInstanceOf<ListLiteral>());
    InterfaceType listType = FastaParserTestCase._typeProvider.listType;
    expect((result as ListLiteral).staticType,
        listType.instantiate([FastaParserTestCase._typeProvider.intType]));
  }

  @failingTest
  test_listLiteral_noType() {
    Expression result = parseExpression('[]');
    expect(result, new isInstanceOf<ListLiteral>());
    InterfaceType listType = FastaParserTestCase._typeProvider.listType;
    expect((result as ListLiteral).staticType,
        listType.instantiate([FastaParserTestCase._typeProvider.dynamicType]));
  }

  @failingTest
  test_mapLiteral_explicitType() {
    Expression result = parseExpression('<String, int>{}');
    expect(result, new isInstanceOf<MapLiteral>());
    InterfaceType mapType = FastaParserTestCase._typeProvider.mapType;
    expect(
        (result as MapLiteral).staticType,
        mapType.instantiate([
          FastaParserTestCase._typeProvider.stringType,
          FastaParserTestCase._typeProvider.intType
        ]));
  }

  @failingTest
  test_mapLiteral_noType() {
    Expression result = parseExpression('{}');
    expect(result, new isInstanceOf<MapLiteral>());
    InterfaceType mapType = FastaParserTestCase._typeProvider.mapType;
    expect(
        (result as MapLiteral).staticType,
        mapType.instantiate([
          FastaParserTestCase._typeProvider.dynamicType,
          FastaParserTestCase._typeProvider.dynamicType
        ]));
  }

  @failingTest
  test_nullLiteral_negative() {
    Expression result = parseExpression('null');
    expect(result, new isInstanceOf<NullLiteral>());
    expect((result as NullLiteral).staticType,
        FastaParserTestCase._typeProvider.nullType);
  }

  @failingTest
  test_simpleStringLiteral() {
    Expression result = parseExpression('"abc"');
    expect(result, new isInstanceOf<SimpleStringLiteral>());
    expect((result as SimpleStringLiteral).staticType,
        FastaParserTestCase._typeProvider.stringType);
  }
}
