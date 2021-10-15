// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.library_loader;

import 'dart:async';

import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:kernel/kernel.dart' hide LibraryDependency, Combinator;
import 'package:kernel/target/targets.dart' hide DiagnosticReporter;

import '../../compiler_new.dart' as api;
import '../commandline_options.dart' show Flags;
import '../common/tasks.dart' show CompilerTask, Measurer;
import '../common.dart';
import '../options.dart';
import '../util/sink_adapter.dart';

import 'front_end_adapter.dart';
import 'dart2js_target.dart' show Dart2jsTarget;

/// A task that produces the kernel IR representation of the application.
///
/// It supports loading both .dart source files or pre-compiled .dill files.
/// When given .dart source files, it invokes the common front-end (CFE)
/// to produce the corresponding kernel IR representation.
class KernelLoaderTask extends CompilerTask {
  final DiagnosticReporter _reporter;

  final api.CompilerInput _compilerInput;
  final api.CompilerOutput _compilerOutput;

  final CompilerOptions _options;

  /// Shared state between compilations.
  fe.InitializedCompilerState initializedCompilerState;

  // TODO(johnniwinther): Remove this when #34942 is fixed.
  /// Force in-memory serialization/deserialization of the loaded component.
  ///
  /// This is used for testing.
  bool forceSerialization = false;

  KernelLoaderTask(this._options, this._compilerInput, this._compilerOutput,
      this._reporter, Measurer measurer)
      : initializedCompilerState = _options.kernelInitializedCompilerState,
        super(measurer);

  @override
  String get name => 'kernel loader';

  ir.Reference findMainMethod(Component component, Uri entryUri) {
    var entryLibrary = component.libraries
        .firstWhere((l) => l.fileUri == entryUri, orElse: () => null);
    if (entryLibrary == null) {
      throw ArgumentError('Entry uri $entryUri not found in dill.');
    }
    var mainMethod = entryLibrary.procedures
        .firstWhere((p) => p.name.text == 'main', orElse: () => null);

    // In some cases, a main method is defined in another file, and then
    // exported. In these cases, we search for the main method in
    // [additionalExports].
    ir.Reference mainMethodReference;
    if (mainMethod == null) {
      mainMethodReference = entryLibrary.additionalExports.firstWhere(
          (p) => p.canonicalName.name == 'main',
          orElse: () => null);
    } else {
      mainMethodReference = mainMethod.reference;
    }
    if (mainMethodReference == null) {
      throw ArgumentError('Entry uri $entryUri has no main method.');
    }
    return mainMethodReference;
  }

  /// Loads an entire Kernel [Component] from a file on disk.
  Future<KernelResult> load() {
    return measure(() async {
      String targetName =
          _options.compileForServer ? "dart2js_server" : "dart2js";

      // We defer selecting the platform until we've resolved the null safety
      // mode.
      String getPlatformFilename() {
        String unsoundMarker = _options.useLegacySubtyping ? "_unsound" : "";
        return "${targetName}_platform$unsoundMarker.dill";
      }

      var resolvedUri = _options.compilationTarget;
      ir.Component component;
      List<Uri> moduleLibraries = const [];
      var isDill = resolvedUri.path.endsWith('.dill') ||
          resolvedUri.path.endsWith('.gdill') ||
          resolvedUri.path.endsWith('.mdill');

      void inferNullSafetyMode(bool isSound) {
        if (_options.nullSafetyMode == NullSafetyMode.unspecified) {
          _options.nullSafetyMode =
              isSound ? NullSafetyMode.sound : NullSafetyMode.unsound;
        }
      }

      void validateNullSafetyMode() {
        assert(_options.nullSafetyMode != NullSafetyMode.unspecified);
      }

      if (isDill) {
        component = ir.Component();
        Future<void> read(Uri uri) async {
          api.Input input = await _compilerInput.readFromUri(uri,
              inputKind: api.InputKind.binary);
          BinaryBuilder(input.data).readComponent(component);
        }

        await read(resolvedUri);

        // If an entryUri is supplied, we use it to manually select the main
        // method.
        if (_options.entryUri != null) {
          var mainMethod = findMainMethod(component, _options.entryUri);
          component.setMainMethodAndMode(mainMethod, true, component.mode);
        }

        if (_options.modularMode) {
          moduleLibraries =
              component.libraries.map((lib) => lib.importUri).toList();
        }

        var isStrongDill =
            component.mode == ir.NonNullableByDefaultCompiledMode.Strong;
        var incompatibleNullSafetyMode =
            isStrongDill ? NullSafetyMode.unsound : NullSafetyMode.sound;
        if (_options.nullSafetyMode == incompatibleNullSafetyMode) {
          var dillMode = isStrongDill ? 'sound' : 'unsound';
          var option =
              isStrongDill ? Flags.noSoundNullSafety : Flags.soundNullSafety;
          throw ArgumentError("$resolvedUri was compiled with $dillMode null "
              "safety and is incompatible with the '$option' option");
        }
        inferNullSafetyMode(isStrongDill);
        validateNullSafetyMode();

        // Modular compiles do not include the platform on the input dill
        // either.
        if (_options.platformBinaries != null) {
          var platformUri =
              _options.platformBinaries.resolve(getPlatformFilename());
          // Modular analysis can be run on the sdk by providing directly the
          // path to the platform.dill file. In that case, we do not load the
          // platform file implicitly.
          // TODO(joshualitt): Change how we detect this case so it is less
          // brittle.
          if (platformUri != resolvedUri) await read(platformUri);
        }

        // Concatenate dills and then reset main method.
        var mainMethod = component.mainMethodName;
        var mainMode = component.mode;
        if (_options.dillDependencies != null) {
          for (Uri dependency in _options.dillDependencies) {
            await read(dependency);
          }
        }
        component.setMainMethodAndMode(mainMethod, true, mainMode);

        // This is not expected to be null when creating a whole-program .dill
        // file, but needs to be checked for modular inputs.
        if (component.mainMethod == null && !_options.modularMode) {
          // TODO(sigmund): move this so that we use the same error template
          // from the CFE.
          _reporter.reportError(_reporter.createMessage(NO_LOCATION_SPANNABLE,
              MessageKind.GENERIC, {'text': "No 'main' method found."}));
          return null;
        }
      } else {
        bool verbose = false;
        Target target =
            Dart2jsTarget(targetName, TargetFlags(), options: _options);
        fe.FileSystem fileSystem = CompilerFileSystem(_compilerInput);
        fe.Verbosity verbosity = _options.verbosity;
        fe.DiagnosticMessageHandler onDiagnostic =
            (fe.DiagnosticMessage message) {
          if (fe.Verbosity.shouldPrint(verbosity, message)) {
            reportFrontEndMessage(_reporter, message);
          }
        };
        fe.CompilerOptions options = fe.CompilerOptions()
          ..target = target
          ..librariesSpecificationUri = _options.librariesSpecificationUri
          ..packagesFileUri = _options.packageConfig
          ..explicitExperimentalFlags = _options.explicitExperimentalFlags
          ..verbose = verbose
          ..fileSystem = fileSystem
          ..onDiagnostic = onDiagnostic
          ..verbosity = verbosity;
        bool isLegacy =
            await fe.uriUsesLegacyLanguageVersion(resolvedUri, options);
        inferNullSafetyMode(!isLegacy);

        List<Uri> dependencies = [];
        if (_options.platformBinaries != null) {
          dependencies
              .add(_options.platformBinaries.resolve(getPlatformFilename()));
        }
        if (_options.dillDependencies != null) {
          dependencies.addAll(_options.dillDependencies);
        }

        initializedCompilerState = fe.initializeCompiler(
            initializedCompilerState,
            target,
            _options.librariesSpecificationUri,
            dependencies,
            _options.packageConfig,
            explicitExperimentalFlags: _options.explicitExperimentalFlags,
            nnbdMode: _options.useLegacySubtyping
                ? fe.NnbdMode.Weak
                : fe.NnbdMode.Strong,
            invocationModes: _options.cfeInvocationModes,
            verbosity: verbosity);
        component = await fe.compile(initializedCompilerState, verbose,
            fileSystem, onDiagnostic, resolvedUri);
        if (component == null) return null;
        validateNullSafetyMode();
      }

      if (_options.cfeOnly) {
        measureSubtask('serialize dill', () {
          _reporter.log('Writing dill to ${_options.outputUri}');
          api.BinaryOutputSink dillOutput =
              _compilerOutput.createBinarySink(_options.outputUri);
          BinaryOutputSinkAdapter irSink = BinaryOutputSinkAdapter(dillOutput);
          BinaryPrinter printer = BinaryPrinter(irSink);
          printer.writeComponentFile(component);
          irSink.close();
        });
      }

      if (forceSerialization) {
        // TODO(johnniwinther): Remove this when #34942 is fixed.
        List<int> data = serializeComponent(component);
        component = ir.Component();
        BinaryBuilder(data).readComponent(component);
      }
      return _toResult(component, moduleLibraries);
    });
  }

  KernelResult _toResult(ir.Component component, List<Uri> moduleLibraries) {
    Uri rootLibraryUri = null;
    Iterable<ir.Library> libraries = component.libraries;
    if (!_options.modularMode && component.mainMethod != null) {
      var root = component.mainMethod.enclosingLibrary;
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

      // Libraries dependencies do not show implicit imports to `dart:core`.
      var dartCore = component.libraries.firstWhere((lib) {
        return lib.importUri.scheme == 'dart' && lib.importUri.path == 'core';
      });
      search(dartCore);

      libraries = libraries.where(seen.contains);
    }
    return KernelResult(component, rootLibraryUri,
        libraries.map((lib) => lib.importUri).toList(), moduleLibraries);
  }
}

/// Result of invoking the CFE to produce the kernel IR.
class KernelResult {
  final ir.Component component;

  /// The [Uri] of the root library containing main.
  /// Note: rootLibraryUri will be null for some modules, for example in the
  /// case of dependent libraries processed modularly.
  final Uri rootLibraryUri;

  /// Returns the [Uri]s of all libraries that have been loaded that are
  /// reachable from the [rootLibraryUri].
  ///
  /// Note that [component] may contain some libraries that are excluded here.
  final Iterable<Uri> libraries;

  /// When running only dart2js modular analysis, returns the [Uri]s for
  /// libraries loaded in the input module.
  ///
  /// This excludes other libraries reachable from them that were loaded as
  /// dependencies. The result of [moduleLibraries] is always a subset of
  /// [libraries].
  final Iterable<Uri> moduleLibraries;

  KernelResult(this.component, this.rootLibraryUri, this.libraries,
      this.moduleLibraries);

  @override
  String toString() =>
      'root=$rootLibraryUri,libraries=$libraries,module=$moduleLibraries';
}
