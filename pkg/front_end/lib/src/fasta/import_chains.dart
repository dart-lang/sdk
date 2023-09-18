// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:_fe_analyzer_shared/src/util/relativize.dart' as uri_extras;
import 'builder/library_builder.dart';

/// Compute the set of distinct import chains to the library at [uri] within
/// [loadedLibraries].
///
/// The chains are strings of the form
///
///       <main-uri> => <intermediate-uri1> => <intermediate-uri2> => <uri>
///
Set<String> computeImportChainsFor(
    Uri entryPoint, LoadedLibraries loadedLibraries, Uri uri,
    {required bool verbose}) {
  // TODO(johnniwinther): Move computation of dependencies to the library
  // loader.
  Set<String> importChains = new Set<String>();
  // The maximum number of full imports chains to process.
  final int chainLimit = 10000;
  // The maximum number of imports chains to show.
  final int compactChainLimit = verbose ? 20 : 10;
  int chainCount = 0;
  loadedLibraries.forEachImportChain(uri,
      callback: (Link<Uri> importChainReversed) {
    // The import chain is provided in reverse order, from the target to the
    // entry point. To reverse it, we create a new chain, prepending the uris
    // of the reversed chain.
    Link<CodeLocation> compactImportChain = const Link<CodeLocation>();
    CodeLocation currentCodeLocation =
        new UriLocation(importChainReversed.head);
    compactImportChain = compactImportChain.prepend(currentCodeLocation);
    for (Link<Uri> link = importChainReversed.tail!;
        !link.isEmpty;
        link = link.tail!) {
      Uri uri = link.head;
      if (!currentCodeLocation.inSameLocation(uri)) {
        // When [verbose] is `false` we use the [CodeLocation] of the [uri]
        // rather than the [UriLocation], which means that we group all
        // libraries with the same package into one location, thereby shortening
        // the path from, for instance,
        //
        //     package:foo/foo1.dart => package:foo/foo2.dart =>
        //     package:bar/bar1.dart => package:bar/bar2.dart =>
        //     package:baz/baz1.dart => package:baz/baz2.dart
        //
        // to
        //
        //     package:foo => package:bar => package:baz
        //
        currentCodeLocation =
            verbose ? new UriLocation(uri) : new CodeLocation(uri);
        compactImportChain = compactImportChain.prepend(currentCodeLocation);
      }
    }
    String importChain = compactImportChain.map((CodeLocation codeLocation) {
      return codeLocation.relativize(entryPoint);
    }).join(' => ');

    if (!importChains.contains(importChain)) {
      if (importChains.length > compactChainLimit) {
        importChains.add('...');
        return false;
      } else {
        importChains.add(importChain);
      }
    }

    chainCount++;
    if (chainCount > chainLimit) {
      // Assume there are more import chains.
      importChains.add('...');
      return false;
    }
    return true;
  });
  return importChains;
}

/// Interface for computing import chains on a set of libraries.
abstract class LoadedLibraries {
  /// Applies all imports chains of [uri] with the set of libraries to
  /// [callback].
  ///
  /// The argument [importChainReversed] to [callback] contains the chain of
  /// imports uris that lead to importing [uri] starting in [uri] and ending in
  /// the entry point uri.
  ///
  /// [callback] is called once for each chain of imports leading to [uri] until
  /// [callback] returns `false`.
  void forEachImportChain(Uri uri,
      {required bool callback(Link<Uri> importChainReversed)});
}

class LoadedLibrariesImpl implements LoadedLibraries {
  /// The library of the compilation entry point.
  final LibraryBuilder rootLibrary;
  final Map<Uri, LibraryBuilder> libraryBuilders = <Uri, LibraryBuilder>{};

  // TODO(johnniwinther): Support multiple entry-points.
  LoadedLibrariesImpl(this.rootLibrary, Iterable<LibraryBuilder> libraries) {
    libraries.forEach((LibraryBuilder libraryBuilder) {
      libraryBuilders[libraryBuilder.importUri] = libraryBuilder;
    });
  }

  @override
  void forEachImportChain(Uri targetUri,
      {required bool callback(Link<Uri> importChainReversed)}) {
    bool aborted = false;

    /// Map from libraries to the set of (unreversed) paths to [targetUri].
    Map<LibraryBuilder, Iterable<Link<Uri>>> suffixChainMap =
        <LibraryBuilder, Iterable<Link<Uri>>>{};

    /// Computes the set of (unreversed) paths to [targetUri].
    ///
    /// Finds all paths (suffixes) from the current [library] to [targetUri] and
    /// stores it in [suffixChainMap].
    ///
    /// For every found suffix it prepends the given [prefix] and the [library]
    /// and invokes the [callback] with the concatenated chain.
    void computeSuffixes(LibraryBuilder library, Link<Uri> prefix) {
      if (aborted) return;

      Uri canonicalUri = library.importUri;
      prefix = prefix.prepend(canonicalUri);
      suffixChainMap[library] = const <Link<Uri>>[];
      List<Link<Uri>> suffixes = [];
      if (targetUri != canonicalUri) {
        /// Process the import (or export) of [importedLibrary].
        void processLibrary(LibraryBuilder importedLibrary) {
          bool suffixesArePrecomputed =
              suffixChainMap.containsKey(importedLibrary);

          if (!suffixesArePrecomputed) {
            computeSuffixes(importedLibrary, prefix);
            if (aborted) return;
          }

          for (Link<Uri> suffix in suffixChainMap[importedLibrary]!) {
            suffixes.add(suffix.prepend(canonicalUri));

            if (suffixesArePrecomputed) {
              // Only report chains through [importedLibrary] if the suffixes
              // had already been computed, otherwise [computeSuffixes] have
              // reported the paths through [prefix].
              Link<Uri> chain = prefix.reversePrependAll(suffix);
              if (!callback(chain)) {
                aborted = true;
                return;
              }
            }
          }
        }

        for (Uri dependency in library.dependencies) {
          LibraryBuilder? libraryBuilder = libraryBuilders[dependency];
          if (libraryBuilder != null) {
            // Library builder is only available if the dependency has been
            // loaded.
            processLibrary(libraryBuilder);
          }
          if (aborted) return;
        }
      } else {
        // Here `targetUri == canonicalUri`.
        if (!callback(prefix)) {
          aborted = true;
          return;
        }
        suffixes.add(const Link<Uri>().prepend(canonicalUri));
      }
      suffixChainMap[library] = suffixes;
      return;
    }

    computeSuffixes(rootLibrary, const Link<Uri>());
  }

  @override
  String toString() => 'root=$rootLibrary,libraries=${libraryBuilders.keys}';
}

/// [CodeLocation] divides uris into different classes.
///
/// These are used to group uris from user code, platform libraries and
/// packages.
abstract class CodeLocation {
  /// Returns `true` if [uri] is in this code location.
  bool inSameLocation(Uri uri);

  /// Returns the uri of this location relative to [baseUri].
  String relativize(Uri baseUri);

  factory CodeLocation(Uri uri) {
    if (uri.isScheme('package')) {
      int slashPos = uri.path.indexOf('/');
      if (slashPos != -1) {
        String packageName = uri.path.substring(0, slashPos);
        return new PackageLocation(packageName);
      } else {
        // This is an invalid import uri, like "package:foo.dart".
        return new UriLocation(uri);
      }
    } else {
      return new SchemeLocation(uri);
    }
  }
}

/// A code location defined by the scheme of the uri.
///
/// Used for non-package uris, such as 'dart', 'file', and 'http'.
class SchemeLocation implements CodeLocation {
  final Uri uri;

  SchemeLocation(this.uri);

  @override
  bool inSameLocation(Uri uri) {
    return this.uri.scheme == uri.scheme;
  }

  @override
  String relativize(Uri baseUri) {
    return uri_extras.relativizeUri(baseUri, uri, false);
  }
}

/// A code location defined by the package name.
///
/// Used for package uris, separated by their `package names`, that is, the
/// 'foo' of 'package:foo/bar.dart'.
class PackageLocation implements CodeLocation {
  final String packageName;

  PackageLocation(this.packageName);

  @override
  bool inSameLocation(Uri uri) {
    return uri.scheme == 'package' && uri.path.startsWith('$packageName/');
  }

  @override
  String relativize(Uri baseUri) => 'package:$packageName';
}

/// A code location defined by the whole uri.
///
/// Used for package uris with no package name. For instance 'package:foo.dart'.
class UriLocation implements CodeLocation {
  final Uri uri;

  UriLocation(this.uri);

  @override
  bool inSameLocation(Uri uri) => this.uri == uri;

  @override
  String relativize(Uri baseUri) {
    return uri_extras.relativizeUri(baseUri, uri, false);
  }
}
