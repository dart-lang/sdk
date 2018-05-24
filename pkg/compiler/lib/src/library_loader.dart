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
import 'elements/entities.dart' show LibraryEntity;
import 'kernel/element_map_impl.dart' show KernelToElementMapForImpactImpl;
import 'resolved_uri_translator.dart';
import 'util/util.dart' show Link;

/**
 * [CompilerTask] for loading libraries and setting up the import/export scopes.
 *
 * The library loader uses four different kinds of URIs in different parts of
 * the loading process.
 *
 * ## User URI ##
 *
 * A 'user URI' is a URI provided by the user in code and as the main entry URI
 * at the command line. These generally come in 3 versions:
 *
 *   * A relative URI such as 'foo.dart', '../bar.dart', and 'baz/boz.dart'.
 *
 *   * A dart URI such as 'dart:core' and 'dart:_js_helper'.
 *
 *   * A package URI such as 'package:foo.dart' and 'package:bar/baz.dart'.
 *
 * A user URI can also be absolute, like 'file:///foo.dart' or
 * 'http://example.com/bar.dart', but such URIs cannot necessarily be used for
 * locating source files, since the scheme must be supported by the input
 * provider. The standard input provider for dart2js only supports the 'file'
 * and 'http' scheme.
 *
 * ## Resolved URI ##
 *
 * A 'resolved URI' is a (user) URI that has been resolved to an absolute URI
 * based on the readable URI (see below) from which it was loaded. A URI with an
 * explicit scheme (such as 'dart:', 'package:' or 'file:') is already resolved.
 * A relative URI like for instance '../foo/bar.dart' is translated into an
 * resolved URI in one of three ways:
 *
 *  * If provided as the main entry URI at the command line, the URI is resolved
 *    relative to the current working directory, say
 *    'file:///current/working/dir/', and the resolved URI is therefore
 *    'file:///current/working/foo/bar.dart'.
 *
 *  * If the relative URI is provided in an import, export or part tag, and the
 *    readable URI of the enclosing compilation unit is a file URI,
 *    'file://some/path/baz.dart', then the resolved URI is
 *    'file://some/foo/bar.dart'.
 *
 *  * If the relative URI is provided in an import, export or part tag, and the
 *    readable URI of the enclosing compilation unit is a package URI,
 *    'package:some/path/baz.dart', then the resolved URI is
 *    'package:some/foo/bar.dart'.
 *
 * The resolved URI thus preserves the scheme through resolution: A readable
 * file URI results in an resolved file URI and a readable package URI results
 * in an resolved package URI. Note that since a dart URI is not a readable URI,
 * import, export or part tags within platform libraries are not interpreted as
 * dart URIs but instead relative to the library source file location.
 *
 * The resolved URI of a library is also used as the canonical URI
 * ([LibraryElement.canonicalUri]) by which we identify which libraries are
 * identical. This means that libraries loaded through the 'package' scheme will
 * resolve to the same library when loaded from within using relative URIs (see
 * for instance the test 'standalone/package/package1_test.dart'). But loading a
 * platform library using a relative URI will _not_ result in the same library
 * as when loaded through the dart URI.
 *
 * ## Readable URI ##
 *
 * A 'readable URI' is an absolute URI whose scheme is either 'package' or
 * something supported by the input provider, normally 'file'. Dart URIs such as
 * 'dart:core' and 'dart:_js_helper' are not readable themselves but are instead
 * resolved into a readable URI using the library root URI provided from the
 * command line and the list of platform libraries found in
 * 'sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart'. This is done
 * through a [ResolvedUriTranslator] provided from the compiler. The translator
 * checks whether a library by that name exists and in case of internal
 * libraries whether access is granted.
 *
 * ## Resource URI ##
 *
 * A 'resource URI' is an absolute URI with a scheme supported by the input
 * provider. For the standard implementation this means a URI with the 'file'
 * scheme. Readable URIs are converted into resource URIs as part of the
 * [ScriptLoader.readScript] method. In the standard implementation the package
 * URIs are converted to file URIs using the package root URI provided on the
 * command line as base. If the package root URI is
 * 'file:///current/working/dir/' then the package URI 'package:foo/bar.dart'
 * will be resolved to the resource URI
 * 'file:///current/working/dir/foo/bar.dart'.
 *
 * The distinction between readable URI and resource URI is necessary to ensure
 * that these imports
 *
 *     import 'package:foo.dart' as a;
 *     import 'packages/foo.dart' as b;
 *
 * do _not_ resolve to the same library when the package root URI happens to
 * point to the 'packages' folder.
 *
 */
abstract class LibraryLoaderTask implements LibraryProvider, CompilerTask {
  /// Returns all libraries that have been loaded.
  Iterable<LibraryEntity> get libraries;

  /// Loads the library specified by the [resolvedUri] and returns the
  /// [LoadedLibraries] that were loaded to load the specified uri. The
  /// [LibraryElement] itself can be found by calling
  /// `loadedLibraries.rootLibrary`.
  ///
  /// If the library is not already loaded, the method creates the
  /// [LibraryElement] for the library and computes the import/export scope,
  /// loading and computing the import/export scopes of all required libraries
  /// in the process. The method handles cyclic dependency between libraries.
  Future<LoadedLibraries> loadLibrary(Uri resolvedUri);
}

/// Interface for an entity that provide libraries.
abstract class LibraryProvider {
  /// Looks up the library with the [canonicalUri].
  LibraryEntity lookupLibrary(Uri canonicalUri);
}

/// A loader that builds a kernel IR representation of the component.
///
/// It supports loading both .dart source files or pre-compiled .dill files.
/// When given .dart source files, it invokes the shared frontend
/// (`package:front_end`) to produce the corresponding kernel IR representation.
// TODO(sigmund): move this class to a new file under src/kernel/.
class KernelLibraryLoaderTask extends CompilerTask
    implements LibraryLoaderTask {
  final Uri librariesSpecification;
  final Uri platformBinaries;
  final Uri _packageConfig;

  final DiagnosticReporter reporter;

  final api.CompilerInput compilerInput;

  /// Holds the mapping of Kernel IR to KElements that is constructed as a
  /// result of loading a component.
  final KernelToElementMapForImpactImpl _elementMap;

  final bool verbose;

  List<LibraryEntity> _allLoadedLibraries;

  fe.InitializedCompilerState initializedCompilerState;

  KernelLibraryLoaderTask(
      this.librariesSpecification,
      this.platformBinaries,
      this._packageConfig,
      this._elementMap,
      this.compilerInput,
      this.reporter,
      Measurer measurer,
      {this.verbose: false,
      this.initializedCompilerState})
      : _allLoadedLibraries = new List<LibraryEntity>(),
        super(measurer);

  /// Loads an entire Kernel [Component] from a file on disk (note, not just a
  /// library, so this name is actually a bit of a misnomer).
  // TODO(efortuna): Rename this once the Element library loader class goes
  // away.
  Future<LoadedLibraries> loadLibrary(Uri resolvedUri) {
    return measure(() async {
      var isDill = resolvedUri.path.endsWith('.dill');
      ir.Component component;
      if (isDill) {
        api.Input input = await compilerInput.readFromUri(resolvedUri,
            inputKind: api.InputKind.binary);
        component = new ir.Component();
        new BinaryBuilder(input.data).readComponent(component);
      } else {
        bool strongMode = _elementMap.options.strongMode;
        String targetName =
            _elementMap.options.compileForServer ? "dart2js_server" : "dart2js";
        String platform = strongMode
            ? '${targetName}_platform_strong.dill'
            : '${targetName}_platform.dill';
        initializedCompilerState = fe.initializeCompiler(
            initializedCompilerState,
            new Dart2jsTarget(
                targetName, new TargetFlags(strongMode: strongMode)),
            librariesSpecification,
            platformBinaries.resolve(platform),
            _packageConfig);
        component = await fe.compile(
            initializedCompilerState,
            verbose,
            new CompilerFileSystem(compilerInput),
            (e) => reportFrontEndMessage(reporter, e),
            resolvedUri);
      }
      if (component == null) return null;
      return createLoadedLibraries(component);
    });
  }

  // Only visible for unit testing.
  LoadedLibraries createLoadedLibraries(ir.Component component) {
    _elementMap.addComponent(component);
    LibraryEntity rootLibrary = null;
    Iterable<ir.Library> libraries = component.libraries;
    if (component.mainMethod != null) {
      var root = component.mainMethod.enclosingLibrary;
      rootLibrary = _elementMap.lookupLibrary(root.importUri);

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
    _allLoadedLibraries.addAll(
        libraries.map((lib) => _elementMap.lookupLibrary(lib.importUri)));
    return new _LoadedLibrariesAdapter(
        rootLibrary, _allLoadedLibraries, _elementMap);
  }

  KernelToElementMapForImpactImpl get elementMap => _elementMap;

  Iterable<LibraryEntity> get libraries => _allLoadedLibraries;

  LibraryEntity lookupLibrary(Uri canonicalUri) {
    return _elementMap?.lookupLibrary(canonicalUri);
  }
}

/// Information on the set libraries loaded as a result of a call to
/// [LibraryLoader.loadLibrary].
abstract class LoadedLibraries {
  /// The access the library object created corresponding to the library
  /// passed to [LibraryLoader.loadLibrary].
  LibraryEntity get rootLibrary;

  /// Returns `true` if a library with canonical [uri] was loaded in this bulk.
  bool containsLibrary(Uri uri);

  /// Returns the library with canonical [uri] that was loaded in this bulk.
  LibraryEntity getLibrary(Uri uri);

  /// Applies all libraries in this bulk to [f].
  void forEachLibrary(f(LibraryEntity library));

  /// Applies all imports chains of [uri] in this bulk to [callback].
  ///
  /// The argument [importChainReversed] to [callback] contains the chain of
  /// imports uris that lead to importing [uri] starting in [uri] and ending in
  /// the uri that was passed in with [loadLibrary].
  ///
  /// [callback] is called once for each chain of imports leading to [uri] until
  /// [callback] returns `false`.
  void forEachImportChain(Uri uri,
      {bool callback(Link<Uri> importChainReversed)});
}

/// Adapter class to mimic the behavior of LoadedLibraries for Kernel element
/// behavior. Ultimately we'll just access worldBuilder instead.
class _LoadedLibrariesAdapter implements LoadedLibraries {
  final LibraryEntity rootLibrary;
  final List<LibraryEntity> _newLibraries;
  final KernelToElementMapForImpactImpl worldBuilder;

  _LoadedLibrariesAdapter(
      this.rootLibrary, this._newLibraries, this.worldBuilder) {
    assert(rootLibrary != null);
  }

  bool containsLibrary(Uri uri) {
    var lib = getLibrary(uri);
    return lib != null && _newLibraries.contains(lib);
  }

  LibraryEntity getLibrary(Uri uri) => worldBuilder.lookupLibrary(uri);

  void forEachLibrary(f(LibraryEntity library)) => _newLibraries.forEach(f);

  void forEachImportChain(Uri uri,
      {bool callback(Link<Uri> importChainReversed)}) {
    // Currently a no-op. This seems wrong.
  }

  String toString() => 'root=$rootLibrary,libraries=${_newLibraries}';
}
