// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.library_loader;

import 'dart:async';

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import 'package:kernel/kernel.dart' hide LibraryDependency, Combinator;
import 'package:kernel/target/targets.dart';

import '../compiler_new.dart' as api;
import 'kernel/front_end_adapter.dart';
import 'kernel/dart2js_target.dart' show Dart2jsTarget;

import 'common/tasks.dart' show CompilerTask, Measurer;
import 'common.dart';
import 'options.dart';

/// A loader that builds a kernel IR representation of the component.
///
/// It supports loading both .dart source files or pre-compiled .dill files.
/// When given .dart source files, it invokes the shared frontend
/// (`package:front_end`) to produce the corresponding kernel IR representation.
// TODO(sigmund): move this class to a new file under src/kernel/.
class LibraryLoaderTask extends CompilerTask {
  final DiagnosticReporter _reporter;

  final api.CompilerInput _compilerInput;

  final CompilerOptions _options;

  /// Shared state between compilations.
  fe.InitializedCompilerState initializedCompilerState;

  LibraryLoaderTask(
      this._options, this._compilerInput, this._reporter, Measurer measurer)
      : initializedCompilerState = _options.kernelInitializedCompilerState,
        super(measurer);

  /// Loads an entire Kernel [Component] from a file on disk.
  Future<LoadedLibraries> loadLibraries(Uri resolvedUri) {
    return measure(() async {
      var isDill = resolvedUri.path.endsWith('.dill');
      ir.Component component;
      if (isDill) {
        api.Input input = await _compilerInput.readFromUri(resolvedUri,
            inputKind: api.InputKind.binary);
        component = new ir.Component();
        new BinaryBuilder(input.data).readComponent(component);
      } else {
        String targetName =
            _options.compileForServer ? "dart2js_server" : "dart2js";
        String platform = '${targetName}_platform_strong.dill';
        initializedCompilerState = fe.initializeCompiler(
            initializedCompilerState,
            new Dart2jsTarget(targetName, new TargetFlags(strongMode: true)),
            _options.librariesSpecificationUri,
            _options.platformBinaries.resolve(platform),
            _options.packageConfig);
        component = await fe.compile(
            initializedCompilerState,
            _options.verbose,
            new CompilerFileSystem(_compilerInput),
            (e) => reportFrontEndMessage(_reporter, e),
            resolvedUri);
      }
      if (component == null) return null;
      return _createLoadedLibraries(component);
    });
  }

  // Only visible for unit testing.
  LoadedLibraries _createLoadedLibraries(ir.Component component) {
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
    return new LoadedLibraries(component, rootLibraryUri,
        libraries.map((lib) => lib.importUri).toList());
  }
}

/// Information on the set libraries loaded as a result of a call to
/// [LibraryLoader.loadLibrary].
class LoadedLibraries {
  final ir.Component _component;
  final Uri _rootLibraryUri;
  final List<Uri> _libraries;

  LoadedLibraries(this._component, this._rootLibraryUri, this._libraries) {
    assert(rootLibraryUri != null);
  }

  /// Returns the root component for the loaded libraries.
  ir.Component get component => _component;

  /// The [Uri] of the root library.
  Uri get rootLibraryUri => _rootLibraryUri;

  /// Returns the [Uri]s of all libraries that have been loaded.
  Iterable<Uri> get libraries => _libraries;

  /// Returns `true` if a library with canonical [uri] was loaded in this bulk.
  bool containsLibrary(Uri uri) {
    return _libraries.contains(uri);
  }

  /// Applies all library [Uri]s in this bulk to [f].
  void forEachLibrary(f(Uri Uri)) => _libraries.forEach(f);

  String toString() => 'root=$_rootLibraryUri,libraries=${_libraries}';
}
