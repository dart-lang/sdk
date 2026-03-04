// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/api_prototype/file_system.dart' as api;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/base/compiler_context.dart';
import 'package:front_end/src/base/constant_context.dart';
import 'package:front_end/src/base/extension_scope.dart';
import 'package:front_end/src/base/incremental_compiler.dart';
import 'package:front_end/src/base/local_scope.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/scope.dart';
import 'package:front_end/src/base/ticker.dart';
import 'package:front_end/src/base/uri_translator.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/dill/dill_target.dart';
import 'package:front_end/src/kernel/assigned_variables_impl.dart';
import 'package:front_end/src/kernel/body_builder.dart';
import 'package:front_end/src/kernel/body_builder_context.dart';
import 'package:front_end/src/kernel/kernel_target.dart';
import 'package:front_end/src/kernel/resolver.dart';
import 'package:front_end/src/source/source_library_builder.dart';
import 'package:front_end/src/source/source_loader.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:testing/testing.dart';
import "package:vm/modular/target/vm.dart" show VmTarget;

api.CompilerOptions getOptions({
  void Function(api.CfeDiagnosticMessage message)? onDiagnostic,
  Uri? repoDir,
  Uri? packagesFileUri,
  bool compileSdk = false,
  bool omitPlatform = true,
  api.FileSystem? fileSystem,
}) {
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  api.CompilerOptions options = new api.CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = compileSdk
    ..target = new VmTarget(new TargetFlags())
    ..librariesSpecificationUri = (repoDir ?? Uri.base).resolve(
      "sdk/lib/libraries.json",
    )
    ..omitPlatform = omitPlatform
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
Future<BuildResult> compile({
  required List<Uri> inputs,
  void Function(api.CfeDiagnosticMessage message)? onDiagnostic,
  Uri? repoDir,
  Uri? packagesFileUri,
  bool compileSdk = false,
  bool omitPlatform = true,
  KernelTargetCreator kernelTargetCreator = KernelTargetTest.new,
  BodyBuilderCreator bodyBuilderCreator = defaultBodyBuilderCreator,
  api.FileSystem? fileSystem,
  bool splitCompileAndCompileLess = false,
}) async {
  Ticker ticker = new Ticker(isVerbose: false);
  api.CompilerOptions compilerOptions = getOptions(
    repoDir: repoDir,
    onDiagnostic: onDiagnostic,
    packagesFileUri: packagesFileUri,
    compileSdk: compileSdk,
    omitPlatform: omitPlatform,
    fileSystem: fileSystem,
  );

  ProcessedOptions processedOptions = new ProcessedOptions(
    options: compilerOptions,
    inputs: inputs,
  );

  return await CompilerContext.runWithOptions(processedOptions, (
    CompilerContext c,
  ) async {
    if (splitCompileAndCompileLess) {
      TestIncrementalCompiler outlineIncrementalCompiler =
          new TestIncrementalCompiler(bodyBuilderCreator, c, outlineOnly: true);
      // Outline
      IncrementalCompilerResult outlineResult = await outlineIncrementalCompiler
          .computeDelta(entryPoints: c.options.inputs);
      print(
        "Build outline of "
        "${outlineResult.component.libraries.length} libraries",
      );

      // Full of the asked inputs.
      TestIncrementalCompiler incrementalCompiler =
          new TestIncrementalCompiler.fromComponent(
            bodyBuilderCreator,
            c,
            outlineResult.component,
          );
      for (Uri uri in c.options.inputs) {
        incrementalCompiler.invalidate(uri);
      }
      IncrementalCompilerResult result = await incrementalCompiler.computeDelta(
        entryPoints: c.options.inputs,
        fullComponent: true,
      );
      print(
        "Build bodies of "
        "${incrementalCompiler.recorderForTesting.rebuildBodiesCount} "
        "libraries.",
      );

      return new BuildResult(component: result.component);
    } else {
      UriTranslator uriTranslator = await c.options.getUriTranslator();
      DillTarget dillTarget = new DillTarget(
        c,
        ticker,
        uriTranslator,
        c.options.target,
      );
      KernelTarget kernelTarget = kernelTargetCreator(
        c,
        c.fileSystem,
        false,
        dillTarget,
        uriTranslator,
        bodyBuilderCreator,
      );

      Uri? platform = c.options.sdkSummary;
      if (platform != null) {
        var bytes = new File.fromUri(platform).readAsBytesSync();
        var platformComponent = loadComponentFromBytes(bytes);
        dillTarget.loader.appendLibraries(
          platformComponent,
          byteCount: bytes.length,
        );
      }

      kernelTarget.setEntryPoints(c.options.inputs);
      dillTarget.buildOutlines();
      BuildResult buildResult = await kernelTarget.buildOutlines();
      buildResult = await kernelTarget.buildComponent();
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
    this.bodyBuilderCreator,
    super.context,
    super._componentToInitializeFrom,
  ) : super.fromComponent();

  @override
  bool get skipExperimentalInvalidationChecksForTesting => true;

  @override
  IncrementalKernelTarget createIncrementalKernelTarget(
    api.FileSystem fileSystem,
    bool includeComments,
    DillTarget dillTarget,
    UriTranslator uriTranslator,
  ) {
    return new KernelTargetTest(
      context,
      fileSystem,
      includeComments,
      dillTarget,
      uriTranslator,
      bodyBuilderCreator,
    )..skipTransformations = true;
  }
}

class TestRecorderForTesting extends RecorderForTesting {
  int rebuildBodiesCount = 0;

  @override
  void recordRebuildBodiesCount(int count) {
    rebuildBodiesCount = count;
  }
}

typedef KernelTargetCreator =
    KernelTargetTest Function(
      CompilerContext compilerContext,
      api.FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator,
      BodyBuilderCreator bodyBuilderCreator,
    );

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
  ) : super(
        compilerContext,
        fileSystem,
        includeComments,
        dillTarget,
        uriTranslator,
      );

  @override
  SourceLoader createLoader() {
    return new SourceLoaderTest(
      fileSystem,
      includeComments,
      this,
      bodyBuilderCreator,
    );
  }

  @override
  void runBuildTransformations() {
    if (skipTransformations) return;
    super.runBuildTransformations();
  }
}

class SourceLoaderTest extends SourceLoader {
  final BodyBuilderCreator bodyBuilderCreator;

  SourceLoaderTest(
    api.FileSystem fileSystem,
    bool includeComments,
    KernelTarget target,
    this.bodyBuilderCreator,
  ) : super(fileSystem, includeComments, target);

  @override
  Resolver createResolver() {
    return new ResolverForTesting(
      classHierarchy: hierarchy,
      coreTypes: coreTypes,
      typeInferenceEngine: typeInferenceEngine,
      benchmarker: target.benchmarker,
      bodyBuilderCreator: bodyBuilderCreator,
    );
  }
}

const BodyBuilderCreator defaultBodyBuilderCreator = BodyBuilderTest.new;

class BodyBuilderTest extends BodyBuilderImpl {
  BodyBuilderTest({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext context,
    required ExtensionScope extensionScope,
    required LookupScope enclosingScope,
    LocalScope? formalParameterScope,
    required ClassHierarchy hierarchy,
    required CoreTypes coreTypes,
    VariableDeclaration? thisVariable,
    List<TypeParameter>? thisTypeParameters,
    required Uri uri,
    required AssignedVariablesImpl assignedVariables,
    required TypeEnvironment typeEnvironment,
    required ConstantContext constantContext,
  }) : super(
         libraryBuilder: libraryBuilder,
         context: context,
         enclosingScope: new EnclosingLocalScope(enclosingScope),
         extensionScope: extensionScope,
         formalParameterScope: formalParameterScope,
         hierarchy: hierarchy,
         coreTypes: coreTypes,
         thisVariable: thisVariable,
         thisTypeParameters: thisTypeParameters,
         uri: uri,
         assignedVariables: assignedVariables,
         typeEnvironment: typeEnvironment,
         constantContext: constantContext,
         internalThisVariable: null,
       );
}
