// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/api_prototype/file_system.dart' as api;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/base/compiler_context.dart';
import 'package:front_end/src/base/constant_context.dart';
import 'package:front_end/src/base/incremental_compiler.dart';
import 'package:front_end/src/base/local_scope.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/scope.dart';
import 'package:front_end/src/base/ticker.dart';
import 'package:front_end/src/base/uri_translator.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/dill/dill_target.dart';
import 'package:front_end/src/kernel/body_builder.dart';
import 'package:front_end/src/kernel/body_builder_context.dart';
import 'package:front_end/src/kernel/kernel_target.dart';
import 'package:front_end/src/source/diet_listener.dart';
import 'package:front_end/src/source/offset_map.dart';
import 'package:front_end/src/source/source_library_builder.dart';
import 'package:front_end/src/source/source_loader.dart';
import 'package:front_end/src/type_inference/type_inferrer.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:testing/testing.dart';
import "package:vm/modular/target/vm.dart" show VmTarget;

api.CompilerOptions getOptions(
    {void Function(api.DiagnosticMessage message)? onDiagnostic,
    Uri? repoDir,
    Uri? packagesFileUri,
    bool compileSdk = false,
    api.FileSystem? fileSystem}) {
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  api.CompilerOptions options = new api.CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = compileSdk
    ..target = new VmTarget(new TargetFlags())
    ..librariesSpecificationUri =
        (repoDir ?? Uri.base).resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = onDiagnostic
    ..packagesFileUri = packagesFileUri
    ..environmentDefines = const {};

  if (fileSystem != null) {
    options.fileSystem = fileSystem;
  }
  return options;
}

/// [splitCompileAndCompileLess] Will use the incremental compiler to compile
/// an outline of everything, then compile the bodies of the [input]. This also
/// makes the compile pipeline skip transformations as for instance the VMs
/// mixin transformation isn't compatible (and will actively crash).
Future<BuildResult> compile(
    {required List<Uri> inputs,
    void Function(api.DiagnosticMessage message)? onDiagnostic,
    Uri? repoDir,
    Uri? packagesFileUri,
    bool compileSdk = false,
    KernelTargetCreator kernelTargetCreator = KernelTargetTest.new,
    BodyBuilderCreator bodyBuilderCreator = defaultBodyBuilderCreator,
    api.FileSystem? fileSystem,
    bool splitCompileAndCompileLess = false}) async {
  Ticker ticker = new Ticker(isVerbose: false);
  api.CompilerOptions compilerOptions = getOptions(
      repoDir: repoDir,
      onDiagnostic: onDiagnostic,
      packagesFileUri: packagesFileUri,
      compileSdk: compileSdk,
      fileSystem: fileSystem);

  ProcessedOptions processedOptions =
      new ProcessedOptions(options: compilerOptions, inputs: inputs);

  return await CompilerContext.runWithOptions(processedOptions,
      (CompilerContext c) async {
    if (splitCompileAndCompileLess) {
      TestIncrementalCompiler outlineIncrementalCompiler =
          new TestIncrementalCompiler(bodyBuilderCreator, c, outlineOnly: true);
      // Outline
      IncrementalCompilerResult outlineResult = await outlineIncrementalCompiler
          .computeDelta(entryPoints: c.options.inputs);
      print("Build outline of "
          "${outlineResult.component.libraries.length} libraries");

      // Full of the asked inputs.
      TestIncrementalCompiler incrementalCompiler =
          new TestIncrementalCompiler.fromComponent(
              bodyBuilderCreator, c, outlineResult.component);
      for (Uri uri in c.options.inputs) {
        incrementalCompiler.invalidate(uri);
      }
      IncrementalCompilerResult result = await incrementalCompiler.computeDelta(
          entryPoints: c.options.inputs, fullComponent: true);
      print("Build bodies of "
          "${incrementalCompiler.recorderForTesting.rebuildBodiesCount} "
          "libraries.");

      return new BuildResult(component: result.component);
    } else {
      UriTranslator uriTranslator = await c.options.getUriTranslator();
      DillTarget dillTarget =
          new DillTarget(c, ticker, uriTranslator, c.options.target);
      KernelTarget kernelTarget = kernelTargetCreator(c, c.fileSystem, false,
          dillTarget, uriTranslator, bodyBuilderCreator);

      Uri? platform = c.options.sdkSummary;
      if (platform != null) {
        var bytes = new File.fromUri(platform).readAsBytesSync();
        var platformComponent = loadComponentFromBytes(bytes);
        dillTarget.loader
            .appendLibraries(platformComponent, byteCount: bytes.length);
      }

      kernelTarget.setEntryPoints(c.options.inputs);
      dillTarget.buildOutlines();
      BuildResult buildResult = await kernelTarget.buildOutlines();
      buildResult = await kernelTarget.buildComponent(
          macroApplications: buildResult.macroApplications);
      buildResult.macroApplications?.close();
      return buildResult;
    }
  });
}

class TestIncrementalCompiler extends IncrementalCompiler {
  final BodyBuilderCreator bodyBuilderCreator;

  @override
  final TestRecorderForTesting recorderForTesting =
      new TestRecorderForTesting();

  TestIncrementalCompiler(
    this.bodyBuilderCreator,
    CompilerContext context, {
    Uri? initializeFromDillUri,
    required bool outlineOnly,
  }) : super(context, initializeFromDillUri, outlineOnly);

  TestIncrementalCompiler.fromComponent(
      this.bodyBuilderCreator, super.context, super._componentToInitializeFrom)
      : super.fromComponent();

  @override
  bool get skipExperimentalInvalidationChecksForTesting => true;

  @override
  IncrementalKernelTarget createIncrementalKernelTarget(
      api.FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator) {
    return new KernelTargetTest(context, fileSystem, includeComments,
        dillTarget, uriTranslator, bodyBuilderCreator)
      ..skipTransformations = true;
  }
}

class TestRecorderForTesting extends RecorderForTesting {
  int rebuildBodiesCount = 0;

  @override
  void recordRebuildBodiesCount(int count) {
    rebuildBodiesCount = count;
  }
}

typedef KernelTargetCreator = KernelTargetTest Function(
    CompilerContext compilerContext,
    api.FileSystem fileSystem,
    bool includeComments,
    DillTarget dillTarget,
    UriTranslator uriTranslator,
    BodyBuilderCreator bodyBuilderCreator);

class KernelTargetTest extends IncrementalKernelTarget {
  final BodyBuilderCreator bodyBuilderCreator;
  bool skipTransformations = false;

  KernelTargetTest(
    CompilerContext compilerContext,
    api.FileSystem fileSystem,
    bool includeComments,
    DillTarget dillTarget,
    UriTranslator uriTranslator,
    this.bodyBuilderCreator,
  ) : super(compilerContext, fileSystem, includeComments, dillTarget,
            uriTranslator);

  @override
  SourceLoader createLoader() {
    return new SourceLoaderTest(
        fileSystem, includeComments, this, bodyBuilderCreator);
  }

  @override
  void runBuildTransformations() {
    if (skipTransformations) return;
    super.runBuildTransformations();
  }
}

class SourceLoaderTest extends SourceLoader {
  final BodyBuilderCreator bodyBuilderCreator;

  SourceLoaderTest(api.FileSystem fileSystem, bool includeComments,
      KernelTarget target, this.bodyBuilderCreator)
      : super(fileSystem, includeComments, target);

  @override
  DietListener createDietListener(
      SourceLibraryBuilder library, OffsetMap offsetMap) {
    return new DietListenerTest(library, hierarchy, coreTypes,
        typeInferenceEngine, offsetMap, bodyBuilderCreator);
  }

  @override
  BodyBuilder createBodyBuilderForOutlineExpression(
      SourceLibraryBuilder library,
      BodyBuilderContext bodyBuilderContext,
      LookupScope scope,
      Uri fileUri,
      {LocalScope? formalParameterScope}) {
    return bodyBuilderCreator.createForOutlineExpression(
        library, bodyBuilderContext, scope, fileUri,
        formalParameterScope: formalParameterScope);
  }

  @override
  BodyBuilder createBodyBuilderForField(
      SourceLibraryBuilder libraryBuilder,
      BodyBuilderContext bodyBuilderContext,
      LookupScope enclosingScope,
      TypeInferrer typeInferrer,
      Uri uri) {
    return bodyBuilderCreator.createForField(
        libraryBuilder, bodyBuilderContext, enclosingScope, typeInferrer, uri);
  }
}

class DietListenerTest extends DietListener {
  final BodyBuilderCreator bodyBuilderCreator;

  DietListenerTest(super.library, super.hierarchy, super.coreTypes,
      super.typeInferenceEngine, super.offsetMap, this.bodyBuilderCreator);

  @override
  BodyBuilder createListenerInternal(
      BodyBuilderContext bodyBuilderContext,
      LookupScope memberScope,
      LocalScope? formalParameterScope,
      VariableDeclaration? extensionThis,
      List<TypeParameter>? extensionTypeParameters,
      TypeInferrer typeInferrer,
      ConstantContext constantContext) {
    return bodyBuilderCreator.create(
        libraryBuilder: libraryBuilder,
        context: bodyBuilderContext,
        enclosingScope: memberScope,
        formalParameterScope: formalParameterScope,
        hierarchy: hierarchy,
        coreTypes: coreTypes,
        thisVariable: extensionThis,
        thisTypeParameters: extensionTypeParameters,
        uri: uri,
        typeInferrer: typeInferrer)
      ..constantContext = constantContext;
  }
}

typedef BodyBuilderCreatorUnnamed = BodyBuilderTest Function(
    {required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext context,
    required LookupScope enclosingScope,
    LocalScope? formalParameterScope,
    required ClassHierarchy hierarchy,
    required CoreTypes coreTypes,
    VariableDeclaration? thisVariable,
    List<TypeParameter>? thisTypeParameters,
    required Uri uri,
    required TypeInferrer typeInferrer});

typedef BodyBuilderCreatorForField = BodyBuilderTest Function(
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    LookupScope enclosingScope,
    TypeInferrer typeInferrer,
    Uri uri);

typedef BodyBuilderCreatorForOutlineExpression = BodyBuilderTest Function(
    SourceLibraryBuilder library,
    BodyBuilderContext bodyBuilderContext,
    LookupScope scope,
    Uri fileUri,
    {LocalScope? formalParameterScope});

typedef BodyBuilderCreator = ({
  BodyBuilderCreatorUnnamed create,
  BodyBuilderCreatorForField createForField,
  BodyBuilderCreatorForOutlineExpression createForOutlineExpression
});

const BodyBuilderCreator defaultBodyBuilderCreator = (
  create: BodyBuilderTest.new,
  createForField: BodyBuilderTest.forField,
  createForOutlineExpression: BodyBuilderTest.forOutlineExpression
);

class BodyBuilderTest extends BodyBuilder {
  @override
  BodyBuilderTest(
      {required SourceLibraryBuilder libraryBuilder,
      required BodyBuilderContext context,
      required LookupScope enclosingScope,
      LocalScope? formalParameterScope,
      required ClassHierarchy hierarchy,
      required CoreTypes coreTypes,
      VariableDeclaration? thisVariable,
      List<TypeParameter>? thisTypeParameters,
      required Uri uri,
      required TypeInferrer typeInferrer})
      : super(
            libraryBuilder: libraryBuilder,
            context: context,
            enclosingScope: new EnclosingLocalScope(enclosingScope),
            formalParameterScope: formalParameterScope,
            hierarchy: hierarchy,
            coreTypes: coreTypes,
            thisVariable: thisVariable,
            thisTypeParameters: thisTypeParameters,
            uri: uri,
            typeInferrer: typeInferrer);

  @override
  BodyBuilderTest.forField(
      SourceLibraryBuilder libraryBuilder,
      BodyBuilderContext bodyBuilderContext,
      LookupScope enclosingScope,
      TypeInferrer typeInferrer,
      Uri uri)
      : super.forField(libraryBuilder, bodyBuilderContext, enclosingScope,
            typeInferrer, uri);

  @override
  BodyBuilderTest.forOutlineExpression(SourceLibraryBuilder library,
      BodyBuilderContext bodyBuilderContext, LookupScope scope, Uri fileUri,
      {LocalScope? formalParameterScope})
      : super.forOutlineExpression(library, bodyBuilderContext, scope, fileUri,
            formalParameterScope: formalParameterScope);
}
