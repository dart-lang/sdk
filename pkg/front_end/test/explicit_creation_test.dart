// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/severity.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/api_prototype/file_system.dart' as api;
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/fasta/builder/declaration_builder.dart';
import 'package:front_end/src/fasta/builder/field_builder.dart';
import 'package:front_end/src/fasta/builder/library_builder.dart';
import 'package:front_end/src/fasta/builder/modifier_builder.dart';
import 'package:front_end/src/fasta/builder/type_declaration_builder.dart';
import 'package:front_end/src/fasta/builder/unresolved_type.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/constant_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/fasta_codes.dart' as fasta;
import 'package:front_end/src/fasta/kernel/body_builder.dart';
import 'package:front_end/src/fasta/kernel/constness.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/scope.dart';
import 'package:front_end/src/fasta/source/diet_listener.dart';
import 'package:front_end/src/fasta/source/source_library_builder.dart';
import 'package:front_end/src/fasta/source/source_loader.dart';
import 'package:front_end/src/fasta/source/stack_listener_impl.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import "package:vm/target/vm.dart" show VmTarget;

import 'testing_utils.dart' show getGitFiles;
import "utils/io_utils.dart";

final Uri repoDir = computeRepoDirUri();

Set<Uri> libUris = {};

Future<void> main(List<String> args) async {
  Ticker ticker = new Ticker(isVerbose: false);
  api.CompilerOptions compilerOptions = getOptions();

  Uri dotPackagesUri = repoDir.resolve(".packages");
  if (!new File.fromUri(dotPackagesUri).existsSync()) {
    throw "Couldn't find .packages";
  }
  compilerOptions.packagesFileUri = dotPackagesUri;

  ProcessedOptions options = new ProcessedOptions(options: compilerOptions);

  if (args.isEmpty) {
    libUris.add(repoDir.resolve("pkg/front_end/lib/"));
    libUris.add(repoDir.resolve("pkg/_fe_analyzer_shared/lib/"));
  } else {
    if (args[0] == "--front-end-only") {
      libUris.add(repoDir.resolve("pkg/front_end/lib/"));
    } else if (args[0] == "--shared-only") {
      libUris.add(repoDir.resolve("pkg/_fe_analyzer_shared/lib/"));
    } else {
      throw "Unsupported arguments: $args";
    }
  }
  for (Uri uri in libUris) {
    Set<Uri> gitFiles = await getGitFiles(uri);
    List<FileSystemEntity> entities =
        new Directory.fromUri(uri).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File &&
          entity.path.endsWith(".dart") &&
          gitFiles.contains(entity.uri)) {
        options.inputs.add(entity.uri);
      }
    }
  }

  Stopwatch stopwatch = new Stopwatch()..start();

  await CompilerContext.runWithOptions<List<Uri>>(options,
      (CompilerContext c) async {
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    DillTarget dillTarget =
        new DillTarget(ticker, uriTranslator, c.options.target);
    KernelTarget kernelTarget =
        new KernelTargetTest(c.fileSystem, false, dillTarget, uriTranslator);

    Uri platform = c.options.sdkSummary;
    if (platform != null) {
      var bytes = new File.fromUri(platform).readAsBytesSync();
      var platformComponent = loadComponentFromBytes(bytes);
      dillTarget.loader
          .appendLibraries(platformComponent, byteCount: bytes.length);
    }

    kernelTarget.setEntryPoints(c.options.inputs);
    await dillTarget.buildOutlines();
    await kernelTarget.buildOutlines();
    await kernelTarget.buildComponent();
    return null;
  });

  print("Done in ${stopwatch.elapsedMilliseconds} ms. "
      "Found $errorCount errors.");
}

class KernelTargetTest extends KernelTarget {
  KernelTargetTest(api.FileSystem fileSystem, bool includeComments,
      DillTarget dillTarget, UriTranslator uriTranslator)
      : super(fileSystem, includeComments, dillTarget, uriTranslator);

  @override
  SourceLoader createLoader() {
    return new SourceLoaderTest(fileSystem, includeComments, this);
  }
}

class SourceLoaderTest extends SourceLoader {
  SourceLoaderTest(
      api.FileSystem fileSystem, bool includeComments, KernelTarget target)
      : super(fileSystem, includeComments, target);

  @override
  DietListener createDietListener(SourceLibraryBuilder library) {
    return new DietListenerTest(
        library, hierarchy, coreTypes, typeInferenceEngine);
  }

  BodyBuilder createBodyBuilderForOutlineExpression(
      LibraryBuilder library,
      DeclarationBuilder declarationBuilder,
      ModifierBuilder member,
      Scope scope,
      Uri fileUri) {
    return new BodyBuilderTest.forOutlineExpression(
        library, declarationBuilder, member, scope, fileUri);
  }

  BodyBuilder createBodyBuilderForField(
      FieldBuilder field, TypeInferrer typeInferrer) {
    return new BodyBuilderTest.forField(field, typeInferrer);
  }
}

class DietListenerTest extends DietListener {
  DietListenerTest(SourceLibraryBuilder library, ClassHierarchy hierarchy,
      CoreTypes coreTypes, TypeInferenceEngine typeInferenceEngine)
      : super(library, hierarchy, coreTypes, typeInferenceEngine);

  @override
  StackListenerImpl createListenerInternal(
      ModifierBuilder builder,
      Scope memberScope,
      Scope formalParameterScope,
      bool isDeclarationInstanceMember,
      VariableDeclaration extensionThis,
      List<TypeParameter> extensionTypeParameters,
      TypeInferrer typeInferrer,
      ConstantContext constantContext) {
    return new BodyBuilderTest(
        libraryBuilder: libraryBuilder,
        member: builder,
        enclosingScope: memberScope,
        formalParameterScope: formalParameterScope,
        hierarchy: hierarchy,
        coreTypes: coreTypes,
        declarationBuilder: currentDeclaration,
        isDeclarationInstanceMember: isDeclarationInstanceMember,
        extensionThis: extensionThis,
        extensionTypeParameters: extensionTypeParameters,
        uri: uri,
        typeInferrer: typeInferrer)
      ..constantContext = constantContext;
  }
}

class BodyBuilderTest extends BodyBuilder {
  @override
  BodyBuilderTest(
      {libraryBuilder,
      member,
      enclosingScope,
      formalParameterScope,
      hierarchy,
      coreTypes,
      declarationBuilder,
      isDeclarationInstanceMember,
      extensionThis,
      extensionTypeParameters,
      uri,
      typeInferrer})
      : super(
            libraryBuilder: libraryBuilder,
            member: member,
            enclosingScope: enclosingScope,
            formalParameterScope: formalParameterScope,
            hierarchy: hierarchy,
            coreTypes: coreTypes,
            declarationBuilder: declarationBuilder,
            isDeclarationInstanceMember: isDeclarationInstanceMember,
            extensionThis: extensionThis,
            extensionTypeParameters: extensionTypeParameters,
            uri: uri,
            typeInferrer: typeInferrer);

  @override
  BodyBuilderTest.forField(FieldBuilder field, TypeInferrer typeInferrer)
      : super.forField(field, typeInferrer);

  @override
  BodyBuilderTest.forOutlineExpression(
      SourceLibraryBuilder library,
      DeclarationBuilder declarationBuilder,
      ModifierBuilder member,
      Scope scope,
      Uri fileUri)
      : super.forOutlineExpression(
            library, declarationBuilder, member, scope, fileUri);

  @override
  Expression buildConstructorInvocation(
      TypeDeclarationBuilder type,
      Token nameToken,
      Token nameLastToken,
      Arguments arguments,
      String name,
      List<UnresolvedType> typeArguments,
      int charOffset,
      Constness constness,
      {bool isTypeArgumentsInForest = false}) {
    Token maybeNewOrConst = nameToken.previous;
    bool doReport = true;
    if (maybeNewOrConst is KeywordToken) {
      if (maybeNewOrConst.lexeme == "new" ||
          maybeNewOrConst.lexeme == "const") {
        doReport = false;
      }
    } else if (maybeNewOrConst is SimpleToken) {
      if (maybeNewOrConst.lexeme == "@") {
        doReport = false;
      }
    }
    if (doReport) {
      bool match = false;
      for (Uri libUri in libUris) {
        if (uri.toString().startsWith(libUri.toString())) {
          match = true;
          break;
        }
      }
      if (!match) {
        doReport = false;
      }
    }
    if (doReport) {
      addProblem(
          fasta.templateUnspecified.withArguments("Should use new or const"),
          nameToken.charOffset,
          nameToken.length);
    }
    return super.buildConstructorInvocation(type, nameToken, nameLastToken,
        arguments, name, typeArguments, charOffset, constness,
        isTypeArgumentsInForest: isTypeArgumentsInForest);
  }
}

int errorCount = 0;

api.CompilerOptions getOptions() {
  // Compile sdk because when this is run from a lint it uses the checked-in sdk
  // and we might not have a suitable compiled platform.dill file.
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  api.CompilerOptions options = new api.CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = true
    ..target = new VmTarget(new TargetFlags())
    ..librariesSpecificationUri = repoDir.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (api.DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        print(message.plainTextFormatted.join('\n'));
        errorCount++;
        exitCode = 1;
      }
    }
    ..environmentDefines = const {};
  return options;
}
