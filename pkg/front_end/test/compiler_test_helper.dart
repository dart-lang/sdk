// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/api_prototype/file_system.dart' as api;
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/constant_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/body_builder.dart';
import 'package:front_end/src/fasta/kernel/body_builder_context.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/scope.dart';
import 'package:front_end/src/fasta/source/diet_listener.dart';
import 'package:front_end/src/fasta/source/source_library_builder.dart';
import 'package:front_end/src/fasta/source/source_loader.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:testing/testing.dart';
import "package:vm/target/vm.dart" show VmTarget;

api.CompilerOptions getOptions(
    {void Function(api.DiagnosticMessage message)? onDiagnostic,
    Uri? repoDir,
    Uri? packagesFileUri,
    bool compileSdk = false}) {
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
  return options;
}

Future<void> compile(
    {required List<Uri> inputs,
    void Function(api.DiagnosticMessage message)? onDiagnostic,
    Uri? repoDir,
    Uri? packagesFileUri,
    bool compileSdk = false,
    KernelTargetCreator kernelTargetCreator = KernelTargetTest.new,
    BodyBuilderCreator bodyBuilderCreator = defaultBodyBuilderCreator}) async {
  Ticker ticker = new Ticker(isVerbose: false);
  api.CompilerOptions compilerOptions = getOptions(
      repoDir: repoDir,
      onDiagnostic: onDiagnostic,
      packagesFileUri: packagesFileUri,
      compileSdk: compileSdk);

  ProcessedOptions processedOptions =
      new ProcessedOptions(options: compilerOptions, inputs: inputs);

  await CompilerContext.runWithOptions(processedOptions,
      (CompilerContext c) async {
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    DillTarget dillTarget =
        new DillTarget(ticker, uriTranslator, c.options.target);
    KernelTarget kernelTarget = kernelTargetCreator(
        c.fileSystem, false, dillTarget, uriTranslator, bodyBuilderCreator);

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
  });
}

typedef KernelTargetCreator = KernelTargetTest Function(
    api.FileSystem fileSystem,
    bool includeComments,
    DillTarget dillTarget,
    UriTranslator uriTranslator,
    BodyBuilderCreator bodyBuilderCreator);

class KernelTargetTest extends KernelTarget {
  final BodyBuilderCreator bodyBuilderCreator;

  KernelTargetTest(
      api.FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator,
      this.bodyBuilderCreator)
      : super(fileSystem, includeComments, dillTarget, uriTranslator);

  @override
  SourceLoader createLoader() {
    return new SourceLoaderTest(
        fileSystem, includeComments, this, bodyBuilderCreator);
  }
}

class SourceLoaderTest extends SourceLoader {
  final BodyBuilderCreator bodyBuilderCreator;

  SourceLoaderTest(api.FileSystem fileSystem, bool includeComments,
      KernelTarget target, this.bodyBuilderCreator)
      : super(fileSystem, includeComments, target);

  @override
  DietListener createDietListener(SourceLibraryBuilder library) {
    return new DietListenerTest(
        library, hierarchy, coreTypes, typeInferenceEngine, bodyBuilderCreator);
  }

  @override
  BodyBuilder createBodyBuilderForOutlineExpression(
      SourceLibraryBuilder library,
      BodyBuilderContext bodyBuilderContext,
      Scope scope,
      Uri fileUri,
      {Scope? formalParameterScope}) {
    return bodyBuilderCreator.createForOutlineExpression(
        library, bodyBuilderContext, scope, fileUri,
        formalParameterScope: formalParameterScope);
  }

  @override
  BodyBuilder createBodyBuilderForField(
      SourceLibraryBuilder libraryBuilder,
      BodyBuilderContext bodyBuilderContext,
      Scope enclosingScope,
      TypeInferrer typeInferrer,
      Uri uri) {
    return bodyBuilderCreator.createForField(
        libraryBuilder, bodyBuilderContext, enclosingScope, typeInferrer, uri);
  }
}

class DietListenerTest extends DietListener {
  final BodyBuilderCreator bodyBuilderCreator;

  DietListenerTest(
      SourceLibraryBuilder library,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      TypeInferenceEngine typeInferenceEngine,
      this.bodyBuilderCreator)
      : super(library, hierarchy, coreTypes, typeInferenceEngine);

  @override
  BodyBuilder createListenerInternal(
      BodyBuilderContext bodyBuilderContext,
      Scope memberScope,
      Scope? formalParameterScope,
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
    required Scope enclosingScope,
    Scope? formalParameterScope,
    required ClassHierarchy hierarchy,
    required CoreTypes coreTypes,
    VariableDeclaration? thisVariable,
    List<TypeParameter>? thisTypeParameters,
    required Uri uri,
    required TypeInferrer typeInferrer});

typedef BodyBuilderCreatorForField = BodyBuilderTest Function(
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    Scope enclosingScope,
    TypeInferrer typeInferrer,
    Uri uri);

typedef BodyBuilderCreatorForOutlineExpression = BodyBuilderTest Function(
    SourceLibraryBuilder library,
    BodyBuilderContext bodyBuilderContext,
    Scope scope,
    Uri fileUri,
    {Scope? formalParameterScope});

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
      required Scope enclosingScope,
      Scope? formalParameterScope,
      required ClassHierarchy hierarchy,
      required CoreTypes coreTypes,
      VariableDeclaration? thisVariable,
      List<TypeParameter>? thisTypeParameters,
      required Uri uri,
      required TypeInferrer typeInferrer})
      : super(
            libraryBuilder: libraryBuilder,
            context: context,
            enclosingScope: enclosingScope,
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
      Scope enclosingScope,
      TypeInferrer typeInferrer,
      Uri uri)
      : super.forField(libraryBuilder, bodyBuilderContext, enclosingScope,
            typeInferrer, uri);

  @override
  BodyBuilderTest.forOutlineExpression(SourceLibraryBuilder library,
      BodyBuilderContext bodyBuilderContext, Scope scope, Uri fileUri,
      {Scope? formalParameterScope})
      : super.forOutlineExpression(library, bodyBuilderContext, scope, fileUri,
            formalParameterScope: formalParameterScope);
}
