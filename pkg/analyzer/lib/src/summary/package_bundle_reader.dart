// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:math' show min;

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';

/**
 * A [ConflictingSummaryException] indicates that two different summaries
 * provided to a [SummaryDataStore] conflict.
 */
class ConflictingSummaryException implements Exception {
  final String duplicatedUri;
  final String summary1Uri;
  final String summary2Uri;
  String _message;

  ConflictingSummaryException(Iterable<String> summaryPaths, this.duplicatedUri,
      this.summary1Uri, this.summary2Uri) {
    // Paths are often quite long.  Find and extract out a common prefix to
    // build a more readable error message.
    var prefix = _commonPrefix(summaryPaths.toList());
    _message = '''
These summaries conflict because they overlap:
- ${summary1Uri.substring(prefix)}
- ${summary2Uri.substring(prefix)}
Both contain the file: $duplicatedUri.
This typically indicates an invalid build rule where two or more targets
include the same source.
  ''';
  }

  String toString() => _message;

  /// Given a set of file paths, find a common prefix.
  int _commonPrefix(List<String> strings) {
    if (strings.isEmpty) return 0;
    var first = strings.first;
    int common = first.length;
    for (int i = 1; i < strings.length; ++i) {
      var current = strings[i];
      common = min(common, current.length);
      for (int j = 0; j < common; ++j) {
        if (first[j] != current[j]) {
          common = j;
          if (common == 0) return 0;
          break;
        }
      }
    }
    // The prefix should end with a file separator.
    var last =
        first.substring(0, common).lastIndexOf(io.Platform.pathSeparator);
    return last < 0 ? 0 : last + 1;
  }
}

/**
 * The [UriResolver] that knows about sources that are served from their
 * summaries.
 */
@deprecated
class InSummaryPackageUriResolver extends UriResolver {
  final SummaryDataStore _dataStore;

  InSummaryPackageUriResolver(this._dataStore);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    actualUri ??= uri;
    String uriString = uri.toString();
    UnlinkedUnit unit = _dataStore.unlinkedMap[uriString];
    if (unit != null) {
      String summaryPath = _dataStore.uriToSummaryPath[uriString];
      return new InSummarySource(actualUri, summaryPath);
    }
    return null;
  }
}

/**
 * A placeholder of a source that is part of a package whose analysis results
 * are served from its summary.  This source uses its URI as [fullName] and has
 * empty contents.
 */
class InSummarySource extends BasicSource {
  /**
   * The summary file where this source was defined.
   */
  final String summaryPath;

  InSummarySource(Uri uri, this.summaryPath) : super(uri);

  @override
  TimestampedData<String> get contents => new TimestampedData<String>(0, '');

  @override
  int get modificationStamp => 0;

  @override
  UriKind get uriKind => UriKind.PACKAGE_URI;

  @override
  bool exists() => true;

  @override
  String toString() => uri.toString();
}

/**
 * The [UriResolver] that knows about sources that are served from their
 * summaries.
 */
class InSummaryUriResolver extends UriResolver {
  ResourceProvider resourceProvider;
  final SummaryDataStore _dataStore;

  InSummaryUriResolver(this.resourceProvider, this._dataStore);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    actualUri ??= uri;
    String uriString = uri.toString();
    UnlinkedUnit unit = _dataStore.unlinkedMap[uriString];
    if (unit != null) {
      String summaryPath = _dataStore.uriToSummaryPath[uriString];
      return new InSummarySource(actualUri, summaryPath);
    }
    return null;
  }
}

/**
 * A concrete resynthesizer that serves summaries from [SummaryDataStore].
 */
class StoreBasedSummaryResynthesizer extends SummaryResynthesizer {
  final SummaryDataStore _dataStore;

  StoreBasedSummaryResynthesizer(
      AnalysisContext context,
      AnalysisSession session,
      SourceFactory sourceFactory,
      bool _,
      this._dataStore)
      : super(context, session, sourceFactory, true);

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    return _dataStore.linkedMap[uri];
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    return _dataStore.unlinkedMap[uri];
  }

  @override
  bool hasLibrarySummary(String uri) {
    LinkedLibrary linkedLibrary = _dataStore.linkedMap[uri];
    return linkedLibrary != null;
  }
}

/**
 * A [SummaryDataStore] is a container for the data extracted from a set of
 * summary package bundles.  It contains maps which can be used to find linked
 * and unlinked summaries by URI.
 */
class SummaryDataStore {
  /**
   * List of all [PackageBundle]s.
   */
  final List<PackageBundle> bundles = <PackageBundle>[];

  /**
   * Map from the URI of a compilation unit to the unlinked summary of that
   * compilation unit.
   */
  final Map<String, UnlinkedUnit> unlinkedMap = <String, UnlinkedUnit>{};

  /**
   * Map from the URI of a library to the linked summary of that library.
   */
  final Map<String, LinkedLibrary> linkedMap = <String, LinkedLibrary>{};

  /**
   * Map from the URI of a library to the summary path that contained it.
   */
  final Map<String, String> uriToSummaryPath = <String, String>{};

  /**
   * List of summary paths.
   */
  final Iterable<String> _summaryPaths;

  /**
   * If true, do not accept multiple summaries that contain the same Dart uri.
   */
  bool _disallowOverlappingSummaries;

  /**
   * Create a [SummaryDataStore] and populate it with the summaries in
   * [summaryPaths].
   */
  SummaryDataStore(Iterable<String> summaryPaths,
      {bool disallowOverlappingSummaries: false,
      ResourceProvider resourceProvider})
      : _summaryPaths = summaryPaths,
        _disallowOverlappingSummaries = disallowOverlappingSummaries {
    summaryPaths.forEach((String path) => _fillMaps(path, resourceProvider));
  }

  /**
   * Add the given [bundle] loaded from the file with the given [path].
   */
  void addBundle(String path, PackageBundle bundle) {
    bundles.add(bundle);
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      String uri = bundle.unlinkedUnitUris[i];
      if (_disallowOverlappingSummaries &&
          uriToSummaryPath.containsKey(uri) &&
          (uriToSummaryPath[uri] != path)) {
        throw new ConflictingSummaryException(
            _summaryPaths, uri, uriToSummaryPath[uri], path);
      }
      uriToSummaryPath[uri] = path;
      addUnlinkedUnit(uri, bundle.unlinkedUnits[i]);
    }
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      String uri = bundle.linkedLibraryUris[i];
      addLinkedLibrary(uri, bundle.linkedLibraries[i]);
    }
  }

  /**
   * Add the given [linkedLibrary] with the given [uri].
   */
  void addLinkedLibrary(String uri, LinkedLibrary linkedLibrary) {
    linkedMap[uri] = linkedLibrary;
  }

  /**
   * Add into this store the unlinked units and linked libraries of [other].
   */
  void addStore(SummaryDataStore other) {
    unlinkedMap.addAll(other.unlinkedMap);
    linkedMap.addAll(other.linkedMap);
  }

  /**
   * Add the given [unlinkedUnit] with the given [uri].
   */
  void addUnlinkedUnit(String uri, UnlinkedUnit unlinkedUnit) {
    unlinkedMap[uri] = unlinkedUnit;
  }

  /**
   * Return a list of absolute URIs of the libraries that contain the unit with
   * the given [unitUriString], or `null` if no such library is in the store.
   */
  List<String> getContainingLibraryUris(String unitUriString) {
    // The unit is the defining unit of a library.
    if (linkedMap.containsKey(unitUriString)) {
      return <String>[unitUriString];
    }
    // Check every unlinked unit whether it uses [unitUri] as a part.
    List<String> libraryUriStrings = <String>[];
    unlinkedMap.forEach((unlinkedUnitUriString, unlinkedUnit) {
      Uri libraryUri = Uri.parse(unlinkedUnitUriString);
      for (String partUriString in unlinkedUnit.publicNamespace.parts) {
        Uri partUri = Uri.parse(partUriString);
        String partAbsoluteUriString =
            resolveRelativeUri(libraryUri, partUri).toString();
        if (partAbsoluteUriString == unitUriString) {
          libraryUriStrings.add(unlinkedUnitUriString);
        }
      }
    });
    return libraryUriStrings.isNotEmpty ? libraryUriStrings : null;
  }

  /**
   * Return `true` if the store contains the linked summary for the library
   * with the given absolute [uri].
   */
  bool hasLinkedLibrary(String uri) {
    return linkedMap.containsKey(uri);
  }

  /**
   * Return `true` if the store contains the unlinked summary for the unit
   * with the given absolute [uri].
   */
  bool hasUnlinkedUnit(String uri) {
    return unlinkedMap.containsKey(uri);
  }

  void _fillMaps(String path, ResourceProvider resourceProvider) {
    List<int> buffer;
    if (resourceProvider != null) {
      var file = resourceProvider.getFile(path);
      buffer = file.readAsBytesSync();
    } else {
      io.File file = new io.File(path);
      buffer = file.readAsBytesSync();
    }
    PackageBundle bundle = new PackageBundle.fromBuffer(buffer);
    addBundle(path, bundle);
  }
}
