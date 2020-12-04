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

  /// Loads an entire Kernel [Component] from a file on disk.
  Future<KernelResult> load(Uri resolvedUri) {
    return measure(() async {
      String targetName =
          _options.compileForServer ? "dart2js_server" : "dart2js";

      // We defer selecting the platform until we've resolved the NNBD mode.
      String getPlatformFilename() {
        String platform = targetName;
        if (!_options.useLegacySubtyping) {
          platform += "_nnbd_strong";
        }
        platform += "_platform.dill";
        return platform;
      }

      ir.Component component;
      var isDill = resolvedUri.path.endsWith('.dill');

      void inferNullSafetyMode(bool isSound) {
        if (isSound) assert(_options.enableNonNullable);
        if (_options.nullSafetyMode == NullSafetyMode.unspecified) {
          _options.nullSafetyMode =
              isSound ? NullSafetyMode.sound : NullSafetyMode.unsound;
        }
      }

      void validateNullSafety() {
        assert(_options.nullSafetyMode != NullSafetyMode.unspecified);
        if (_options.nullSafetyMode == NullSafetyMode.sound) {
          assert(_options.enableNonNullable);
        }
      }

      if (isDill) {
        component = new ir.Component();
        Future<void> read(Uri uri) async {
          api.Input input = await _compilerInput.readFromUri(uri,
              inputKind: api.InputKind.binary);
          new BinaryBuilder(input.data).readComponent(component);
        }

        await read(resolvedUri);

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
        validateNullSafety();

        if (_options.dillDependencies != null) {
          // Modular compiles do not include the platform on the input dill
          // either.
          if (_options.platformBinaries != null) {
            await read(
                _options.platformBinaries.resolve(getPlatformFilename()));
          }
          for (Uri dependency in _options.dillDependencies) {
            await read(dependency);
          }
        }

        // This is not expected to be null when creating a whole-program .dill
        // file, but needs to be checked for modular inputs.
        if (component.mainMethod == null) {
          // TODO(sigmund): move this so that we use the same error template
          // from the CFE.
          _reporter.reportError(_reporter.createMessage(NO_LOCATION_SPANNABLE,
              MessageKind.GENERIC, {'text': "No 'main' method found."}));
          return null;
        }
      } else {
        bool verbose = false;
        Target target = Dart2jsTarget(targetName, TargetFlags());
        fe.FileSystem fileSystem = CompilerFileSystem(_compilerInput);
        fe.DiagnosticMessageHandler onDiagnostic =
            (e) => reportFrontEndMessage(_reporter, e);
        fe.CompilerOptions options = fe.CompilerOptions()
          ..target = target
          ..librariesSpecificationUri = _options.librariesSpecificationUri
          ..packagesFileUri = _options.packageConfig
          ..explicitExperimentalFlags = _options.explicitExperimentalFlags
          ..verbose = verbose
          ..fileSystem = fileSystem
          ..onDiagnostic = onDiagnostic;
        bool isLegacy =
            await fe.uriUsesLegacyLanguageVersion(resolvedUri, options);
        inferNullSafetyMode(_options.enableNonNullable && !isLegacy);

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
                : fe.NnbdMode.Strong);
        component = await fe.compile(initializedCompilerState, verbose,
            fileSystem, onDiagnostic, resolvedUri);
        if (component == null) return null;
        validateNullSafety();
      }

      if (_options.cfeOnly) {
        measureSubtask('serialize dill', () {
          _reporter.log('Writing dill to ${_options.outputUri}');
          api.BinaryOutputSink dillOutput =
              _compilerOutput.createBinarySink(_options.outputUri);
          BinaryOutputSinkAdapter irSink =
              new BinaryOutputSinkAdapter(dillOutput);
          BinaryPrinter printer = new BinaryPrinter(irSink);
          printer.writeComponentFile(component);
          irSink.close();
        });
      }

      if (forceSerialization) {
        // TODO(johnniwinther): Remove this when #34942 is fixed.
        List<int> data = serializeComponent(component);
        component = new ir.Component();
        new BinaryBuilder(data).readComponent(component);
      }
      return _toResult(component);
    });
  }

  KernelResult _toResult(ir.Component component) {
    Uri rootLibraryUri = null;
    Iterable<ir.Library> libraries = component.libraries;
    if (component.mainMethod != null) {
      var root = component.mainMethod.enclosingLibrary;
      rootLibraryUri = root.importUri;

      // Filter unreachable libraries: [Component] was built by linking in the
      // entire SDK libraries, not all of them are used. We include anything
      // that is reachable from `main`. Note that all internal libraries that
      // the compiler relies on are reachable from `dart:core`.
      var seen = new Set<Library>();
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
    return new KernelResult(component, rootLibraryUri,
        libraries.map((lib) => lib.importUri).toList());
  }
}

/// Result of invoking the CFE to produce the kernel IR.
class KernelResult {
  final ir.Component component;

  /// The [Uri] of the root library containing main.
  final Uri rootLibraryUri;

  /// Returns the [Uri]s of all libraries that have been loaded that are
  /// reachable from the [rootLibraryUri].
  ///
  /// Note that [component] may contain some libraries that are excluded here.
  final Iterable<Uri> libraries;

  KernelResult(this.component, this.rootLibraryUri, this.libraries) {
    assert(rootLibraryUri != null);
  }

  @override
  String toString() => 'root=$rootLibraryUri,libraries=${libraries}';
}
