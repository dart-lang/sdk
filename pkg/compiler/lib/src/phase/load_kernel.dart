// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_js_interop_checks/src/transformations/static_interop_class_eraser.dart';
import 'package:collection/collection.dart';
import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/kernel.dart' hide LibraryDependency, Combinator;
import 'package:kernel/target/targets.dart' hide DiagnosticReporter;
import 'package:kernel/type_environment.dart' as ir;
import 'package:kernel/verifier.dart';

import '../../compiler_api.dart' as api;
import '../commandline_options.dart';
import '../common.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../environment.dart';
import '../ir/annotations.dart';
import '../ir/constants.dart';
import '../kernel/dart2js_target.dart'
    show
        Dart2jsConstantsBackend,
        Dart2jsDartLibrarySupport,
        Dart2jsTarget,
        implicitlyUsedLibraries;
import '../kernel/front_end_adapter.dart';
import '../kernel/transformations/global/transform.dart' as globalTransforms;
import '../options.dart';

class Input {
  final CompilerOptions options;
  final api.CompilerInput compilerInput;
  final DiagnosticReporter reporter;

  /// Shared state between compilations. Only used when loading from source.
  final fe.InitializedCompilerState? initializedCompilerState;

  // TODO(johnniwinther): Remove this when #34942 is fixed.
  /// Force in-memory serialization/deserialization of the loaded component.
  ///
  /// This is used for testing.
  final bool forceSerialization;

  Input(this.options, this.compilerInput, this.reporter,
      this.initializedCompilerState, this.forceSerialization);
}

/// Result of invoking the CFE to produce the kernel IR.
class Output {
  final ir.Component component;

  /// The [Uri] of the root library containing main.
  /// Note: rootLibraryUri will be null for some modules, for example in the
  /// case of dependent libraries processed modularly.
  final Uri? rootLibraryUri;

  /// Returns the [Uri]s of all libraries that have been loaded that are
  /// reachable from the [rootLibraryUri].
  ///
  /// Note that [component] may contain some libraries that are excluded here.
  final List<Uri>? libraries;

  final fe.InitializedCompilerState? initializedCompilerState;

  Output withNewComponent(ir.Component component) =>
      Output(component, rootLibraryUri, libraries, initializedCompilerState);

  Output(this.component, this.rootLibraryUri, this.libraries,
      this.initializedCompilerState);
}

Library _findEntryLibrary(Component component, Uri entryUri) {
  final entryLibrary =
      component.libraries.firstWhereOrNull((l) => l.fileUri == entryUri);
  if (entryLibrary == null) {
    throw ArgumentError('Entry uri $entryUri not found in dill.');
  }
  return entryLibrary;
}

ir.Reference _findMainMethod(Library entryLibrary) {
  var mainMethod =
      entryLibrary.procedures.firstWhereOrNull((p) => p.name.text == 'main');

  // In some cases, a main method is defined in another file, and then
  // exported. In these cases, we search for the main method in
  // [additionalExports].
  ir.Reference? mainMethodReference;
  if (mainMethod == null) {
    mainMethodReference = entryLibrary.additionalExports
        .firstWhereOrNull((p) => p.canonicalName?.name == 'main');
  } else {
    mainMethodReference = mainMethod.reference;
  }
  if (mainMethodReference == null) {
    throw ArgumentError(
        'Entry uri ${entryLibrary.fileUri} has no main method.');
  }
  return mainMethodReference;
}

String _getPlatformFilename(CompilerOptions options, String targetName) {
  String unsoundMarker = options.useLegacySubtyping ? "_unsound" : "";
  return "${targetName}_platform$unsoundMarker.dill";
}

class _LoadFromKernelResult {
  final ir.Component? component;
  final Library? entryLibrary;

  _LoadFromKernelResult(this.component, this.entryLibrary);
}

void _simplifyConstConditionals(ir.Component component, CompilerOptions options,
    ir.ClassHierarchy classHierarchy, DiagnosticReporter reporter) {
  void reportMessage(
      fe.LocatedMessage message, List<fe.LocatedMessage>? context) {
    reportLocatedMessage(reporter, message, context);
  }

  bool shouldNotInline(ir.TreeNode node) {
    if (node is! ir.Annotatable) {
      return false;
    }
    return computePragmaAnnotationDataFromIr(node).any((pragma) =>
        pragma == const PragmaAnnotationData('noInline') ||
        pragma == const PragmaAnnotationData('never-inline'));
  }

  fe.ConstConditionalSimplifier(
          const Dart2jsDartLibrarySupport(),
          const Dart2jsConstantsBackend(supportsUnevaluatedConstants: false),
          component,
          reportMessage,
          environmentDefines: options.environment,
          classHierarchy: classHierarchy,
          evaluationMode: options.useLegacySubtyping
              ? fe.EvaluationMode.weak
              : fe.EvaluationMode.strong,
          shouldNotInline: shouldNotInline)
      .run();
}

// Perform any backend-specific transforms here that can be done on both
// serialized components and components from source.
void _doTransformsOnKernelLoad(
    Component component, CompilerOptions options, DiagnosticReporter reporter) {
  if (options.stage.shouldRunGlobalTransforms) {
    ir.CoreTypes coreTypes = ir.CoreTypes(component);
    // Ignore ambiguous supertypes.
    final classHierarchy = ir.ClassHierarchy(component, coreTypes,
        onAmbiguousSupertypes: (_, __, ___) {});
    ir.TypeEnvironment typeEnvironment =
        ir.TypeEnvironment(coreTypes, classHierarchy);
    final constantsEvaluator = Dart2jsConstantEvaluator(
        component,
        typeEnvironment,
        (fe.LocatedMessage message, List<fe.LocatedMessage>? context) =>
            reportLocatedMessage(reporter, message, context),
        environment: Environment(options.environment),
        evaluationMode: options.useLegacySubtyping
            ? fe.EvaluationMode.weak
            : fe.EvaluationMode.strong);
    StaticInteropClassEraser(coreTypes).visitComponent(component);
    globalTransforms.transformLibraries(
        component.libraries, constantsEvaluator, coreTypes, options);
    _simplifyConstConditionals(component, options, classHierarchy, reporter);
  }
}

Future<_LoadFromKernelResult> _loadFromKernel(
    CompilerOptions options,
    api.CompilerInput compilerInput,
    String targetName,
    DiagnosticReporter reporter) async {
  Library? entryLibrary;
  var resolvedUri = options.compilationTarget;
  ir.Component component = ir.Component();

  Future<void> read(Uri uri) async {
    api.Input input =
        await compilerInput.readFromUri(uri, inputKind: api.InputKind.binary);
    BinaryBuilder(input.data).readComponent(component);
  }

  await read(resolvedUri);

  var isStrongDill =
      component.mode == ir.NonNullableByDefaultCompiledMode.Strong;
  var incompatibleNullSafetyMode =
      isStrongDill ? NullSafetyMode.unsound : NullSafetyMode.sound;
  if (options.nullSafetyMode == incompatibleNullSafetyMode) {
    var dillMode = isStrongDill ? 'sound' : 'unsound';
    var option = isStrongDill ? Flags.noSoundNullSafety : Flags.soundNullSafety;
    throw ArgumentError("$resolvedUri was compiled with $dillMode null "
        "safety and is incompatible with the '$option' option");
  }

  if (options.platformBinaries != null &&
      options.stage.shouldReadPlatformBinaries) {
    var platformUri = options.platformBinaries
        ?.resolve(_getPlatformFilename(options, targetName));
    // TODO(joshualitt): Change how we detect this case so it is less
    // brittle.
    if (platformUri != resolvedUri) await read(platformUri!);
  }

  // Concatenate dills.
  if (options.dillDependencies != null) {
    for (Uri dependency in options.dillDependencies!) {
      await read(dependency);
    }
  }

  if (options.entryUri != null) {
    entryLibrary = _findEntryLibrary(component, options.entryUri!);
    var mainMethod = _findMainMethod(entryLibrary);
    component.setMainMethodAndMode(mainMethod, true, component.mode);
  }

  _doTransformsOnKernelLoad(component, options, reporter);
  registerSources(component, compilerInput);
  return _LoadFromKernelResult(component, entryLibrary);
}

class _LoadFromSourceResult {
  final ir.Component? component;
  final fe.InitializedCompilerState initializedCompilerState;

  _LoadFromSourceResult(this.component, this.initializedCompilerState);
}

Future<_LoadFromSourceResult> _loadFromSource(
    CompilerOptions options,
    api.CompilerInput compilerInput,
    DiagnosticReporter reporter,
    fe.InitializedCompilerState? initializedCompilerState,
    String targetName) async {
  bool verbose = false;
  bool cfeConstants = options.features.cfeConstants.isEnabled;
  Map<String, String>? environment = cfeConstants ? options.environment : null;
  Target target = Dart2jsTarget(
      targetName,
      TargetFlags(
          soundNullSafety: options.nullSafetyMode == NullSafetyMode.sound),
      options: options,
      supportsUnevaluatedConstants: !cfeConstants);
  fe.FileSystem fileSystem = CompilerFileSystem(compilerInput);
  fe.Verbosity verbosity = options.verbosity;
  fe.DiagnosticMessageHandler onDiagnostic = (fe.DiagnosticMessage message) {
    if (fe.Verbosity.shouldPrint(verbosity, message)) {
      reportFrontEndMessage(reporter, message);
    }
  };

  List<Uri> sources = [options.compilationTarget];

  fe.CompilerOptions feOptions = fe.CompilerOptions()
    ..target = target
    ..librariesSpecificationUri = options.librariesSpecificationUri
    ..packagesFileUri = options.packageConfig
    ..explicitExperimentalFlags = options.explicitExperimentalFlags
    ..environmentDefines = environment
    ..verbose = verbose
    ..fileSystem = fileSystem
    ..onDiagnostic = onDiagnostic
    ..verbosity = verbosity;
  Uri resolvedUri = options.compilationTarget;
  bool isLegacy = await fe.uriUsesLegacyLanguageVersion(resolvedUri, feOptions);
  if (isLegacy && options.experimentNullSafetyChecks) {
    reporter.reportErrorMessage(NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {
      'text': 'The ${Flags.experimentNullSafetyChecks} option may be used '
          'only after all libraries have been migrated to null safety. Some '
          'libraries reached from $resolvedUri are still opted out of null '
          'safety. Please migrate these libraries before passing '
          '${Flags.experimentNullSafetyChecks}.',
    });
  }
  if (isLegacy && options.nullSafetyMode == NullSafetyMode.sound) {
    reporter.reportErrorMessage(NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {
      'text': "Starting with Dart 3.0, `dart compile js` expects programs to "
          "be null-safe by default. Some libraries reached from $resolvedUri "
          "are opted out of null safety. You can temporarily compile this "
          "application using the deprecated '${Flags.noSoundNullSafety}' "
          "option."
    });
  }

  List<Uri> dependencies = [];
  if (options.platformBinaries != null) {
    dependencies.add(options.platformBinaries!
        .resolve(_getPlatformFilename(options, targetName)));
  }
  if (options.dillDependencies != null) {
    dependencies.addAll(options.dillDependencies!);
  }

  initializedCompilerState = fe.initializeCompiler(
      initializedCompilerState,
      target,
      options.librariesSpecificationUri,
      dependencies,
      options.packageConfig,
      explicitExperimentalFlags: options.explicitExperimentalFlags,
      environmentDefines: environment,
      nnbdMode:
          options.useLegacySubtyping ? fe.NnbdMode.Weak : fe.NnbdMode.Strong,
      invocationModes: options.cfeInvocationModes,
      verbosity: verbosity);
  ir.Component? component = await fe.compile(
      initializedCompilerState, verbose, fileSystem, onDiagnostic, sources);

  if (component != null) {
    assert(() {
      verifyComponent(
          target, VerificationStage.afterModularTransformations, component);
      return true;
    }());

    _doTransformsOnKernelLoad(component, options, reporter);

    registerSources(component, compilerInput);
  }

  return _LoadFromSourceResult(component, initializedCompilerState);
}

Output _createOutput(
    CompilerOptions options,
    DiagnosticReporter reporter,
    Library? entryLibrary,
    ir.Component component,
    fe.InitializedCompilerState? initializedCompilerState) {
  Uri? rootLibraryUri = null;
  Iterable<ir.Library> libraries = component.libraries;
  if (component.mainMethod == null) {
    // TODO(sigmund): move this so that we use the same error template
    // from the CFE.
    reporter.reportError(reporter.createMessage(NO_LOCATION_SPANNABLE,
        MessageKind.GENERIC, {'text': "No 'main' method found."}));
  }

  // If we are building from dill and are passed an [entryUri], then we use
  // that to find the appropriate [entryLibrary]. Otherwise, we fallback to
  // the [enclosingLibrary] of the [mainMethod].
  // NOTE: Under some circumstances, the [entryLibrary] exports the
  // [mainMethod] from another library, and thus the [enclosingLibrary] of
  // the [mainMethod] may not be the same as the [entryLibrary].
  var root = entryLibrary ?? component.mainMethod!.enclosingLibrary;
  rootLibraryUri = root.importUri;

  // Filter unreachable libraries: [Component] was built by linking in the
  // entire SDK libraries, not all of them are used. We include anything
  // that is reachable from `main`. Note that all internal libraries that
  // the compiler relies on are reachable from `dart:core`.
  var seen = Set<Library>();
  search(ir.Library current) {
    if (!seen.add(current)) return;
    for (ir.LibraryDependency dep in current.dependencies) {
      search(dep.targetLibrary);
    }
  }

  search(root);

  // Libraries dependencies do not show implicit imports to certain internal
  // libraries.
  const Set<String> alwaysInclude = {
    'dart:_internal',
    'dart:core',
    'dart:async',
    ...implicitlyUsedLibraries,
  };
  for (String uri in alwaysInclude) {
    Library library = component.libraries.firstWhere((lib) {
      return '${lib.importUri}' == uri;
    });
    search(library);
  }

  libraries = libraries.where(seen.contains);
  return Output(component, rootLibraryUri,
      libraries.map((lib) => lib.importUri).toList(), initializedCompilerState);
}

/// Loads an entire Kernel [Component] from a file on disk.
Future<Output?> run(Input input) async {
  CompilerOptions options = input.options;
  api.CompilerInput compilerInput = input.compilerInput;
  DiagnosticReporter reporter = input.reporter;

  String targetName = options.compileForServer ? "dart2js_server" : "dart2js";

  Library? entryLibrary;
  ir.Component? component;
  fe.InitializedCompilerState? initializedCompilerState =
      input.initializedCompilerState;
  if (options.stage.shouldLoadFromDill) {
    _LoadFromKernelResult result =
        await _loadFromKernel(options, compilerInput, targetName, reporter);
    component = result.component;
    entryLibrary = result.entryLibrary;
  } else {
    _LoadFromSourceResult result = await _loadFromSource(options, compilerInput,
        reporter, input.initializedCompilerState, targetName);
    component = result.component;
    initializedCompilerState = result.initializedCompilerState;
  }
  if (component == null) return null;
  if (input.forceSerialization) {
    // TODO(johnniwinther): Remove this when #34942 is fixed.
    List<int> data = serializeComponent(component);
    component = ir.Component();
    BinaryBuilder(data).readComponent(component);
    // Ensure we use the new deserialized entry point library.
    entryLibrary = _findEntryLibrary(component, options.entryUri!);
  }
  return _createOutput(
      options, reporter, entryLibrary, component, initializedCompilerState);
}

/// Registers with the dart2js compiler all sources embedded in a kernel
/// component. This may include sources that were read from disk directly as
/// files, but also sources that were embedded in binary `.dill` files (like the
/// platform kernel file).
///
/// This registration improves how locations are presented when errors
/// or crashes are reported by the dart2js compiler.
void registerSources(ir.Component component, api.CompilerInput compilerInput) {
  component.uriToSource.forEach((uri, source) {
    compilerInput.registerUtf8ContentsForDiagnostics(uri, source.source);
  });
}
