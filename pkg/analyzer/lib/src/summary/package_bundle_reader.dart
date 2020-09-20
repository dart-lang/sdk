// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:math' show min;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/idl.dart';

/// A [ConflictingSummaryException] indicates that two different summaries
/// provided to a [SummaryDataStore] conflict.
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

  @override
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

/// A placeholder of a source that is part of a package whose analysis results
/// are served from its summary.  This source uses its URI as [fullName] and has
/// empty contents.
class InSummarySource extends BasicSource {
  /// The summary file where this source was defined.
  final String summaryPath;

  InSummarySource(Uri uri, this.summaryPath) : super(uri);

  @override
  TimestampedData<String> get contents => TimestampedData<String>(0, '');

  @override
  int get modificationStamp => 0;

  @override
  UriKind get uriKind => UriKind.PACKAGE_URI;

  @override
  bool exists() => true;

  @override
  String toString() => uri.toString();
}

/// The [UriResolver] that knows about sources that are served from their
/// summaries.
class InSummaryUriResolver extends UriResolver {
  ResourceProvider resourceProvider;
  final SummaryDataStore _dataStore;

  InSummaryUriResolver(this.resourceProvider, this._dataStore);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    actualUri ??= uri;
    String uriString = uri.toString();
    String summaryPath = _dataStore.uriToSummaryPath[uriString];
    if (summaryPath != null) {
      return InSummarySource(actualUri, summaryPath);
    }
    return null;
  }
}

/// A [SummaryDataStore] is a container for the data extracted from a set of
/// summary package bundles.  It contains maps which can be used to find linked
/// and unlinked summaries by URI.
class SummaryDataStore {
  /// List of all [PackageBundle]s.
  final List<PackageBundle> bundles = <PackageBundle>[];

  /// Map from the URI of a unit to the summary path that contained it.
  final Map<String, String> uriToSummaryPath = <String, String>{};

  final Set<String> _libraryUris = <String>{};
  final Set<String> _partUris = <String>{};

  /// Create a [SummaryDataStore] and populate it with the summaries in
  /// [summaryPaths].
  SummaryDataStore(Iterable<String> summaryPaths,
      {ResourceProvider resourceProvider}) {
    summaryPaths.forEach((String path) => _fillMaps(path, resourceProvider));
  }

  /// Add the given [bundle] loaded from the file with the given [path].
  void addBundle(String path, PackageBundle bundle) {
    bundles.add(bundle);

    if (bundle.bundle2 != null) {
      for (var library in bundle.bundle2.libraries) {
        var libraryUri = library.uriStr;
        _libraryUris.add(libraryUri);
        for (var unit in library.units) {
          var unitUri = unit.uriStr;
          uriToSummaryPath[unitUri] = path;
          if (unitUri != libraryUri) {
            _partUris.add(unitUri);
          }
        }
      }
    }
  }

  /// Return `true` if the store contains the linked summary for the library
  /// with the given absolute [uri].
  bool hasLinkedLibrary(String uri) {
    return _libraryUris.contains(uri);
  }

  /// Return `true` if the store contains the unlinked summary for the unit
  /// with the given absolute [uri].
  bool hasUnlinkedUnit(String uri) {
    return uriToSummaryPath.containsKey(uri);
  }

  /// Return `true` if the unit with the [uri] is a part unit in the store.
  bool isPartUnit(String uri) {
    return _partUris.contains(uri);
  }

  void _fillMaps(String path, ResourceProvider resourceProvider) {
    List<int> buffer;
    if (resourceProvider != null) {
      var file = resourceProvider.getFile(path);
      buffer = file.readAsBytesSync();
    } else {
      io.File file = io.File(path);
      buffer = file.readAsBytesSync();
    }
    PackageBundle bundle = PackageBundle.fromBuffer(buffer);
    addBundle(path, bundle);
  }
}
