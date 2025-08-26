// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:meta/meta.dart';

final _logRing = Queue<String>();

void addToLogRing(String entry) {
  _logRing.add(entry);
  if (_logRing.length > 10) {
    _logRing.removeFirst();
  }
}

class LinkedElementFactory {
  static final _dartCoreUri = uriCache.parse('dart:core');
  static final _dartAsyncUri = uriCache.parse('dart:async');

  final AnalysisContextImpl analysisContext;
  AnalysisSessionImpl analysisSession;
  final Reference rootReference;
  final Map<Uri, LibraryReader> _libraryReaders = {};
  bool isApplyingInformativeData = false;
  final Map<Uri, LibraryManifest> libraryManifests = {};

  LinkedElementFactory(
    this.analysisContext,
    this.analysisSession,
    this.rootReference,
  ) {
    ArgumentError.checkNotNull(analysisContext, 'analysisContext');
    ArgumentError.checkNotNull(analysisSession, 'analysisSession');
  }

  LibraryElementImpl get dartAsyncElement {
    return libraryOfUri2(_dartAsyncUri);
  }

  LibraryElementImpl get dartCoreElement {
    return libraryOfUri2(_dartCoreUri);
  }

  Reference get dynamicRef {
    return rootReference.getChild('dart:core').getChild('dynamic');
  }

  /// Returns URIs for which [LibraryElementImpl] is ready.
  @visibleForTesting
  List<Uri> get uriListWithLibraryElements {
    return rootReference.children
        .map((reference) => reference.element)
        .whereType<LibraryElementImpl>()
        .map((e) => e.uri)
        .toList();
  }

  /// Returns URIs for which we have readers, but not elements.
  @visibleForTesting
  List<Uri> get uriListWithLibraryReaders {
    return _libraryReaders.keys.toList();
  }

  void addBundle(BundleReader bundle) {
    addLibraries(bundle.libraryMap);
  }

  void addLibraries(Map<Uri, LibraryReader> libraries) {
    _libraryReaders.addAll(libraries);
  }

  Namespace buildExportNamespace(
    Uri uri,
    List<ExportedReference> exportedReferences,
  ) {
    var exportedNames = <String, Element>{};

    for (var exportedReference in exportedReferences) {
      var element = elementOfReference3(exportedReference.reference);
      exportedNames[element.lookupName!] = element;
    }

    return Namespace(exportedNames);
  }

  void createTypeProviders(
    LibraryElementImpl dartCore,
    LibraryElementImpl dartAsync,
  ) {
    if (analysisContext.hasTypeProvider) {
      return;
    }

    analysisContext.setTypeProviders(
      typeProvider: TypeProviderImpl(
        coreLibrary: dartCore,
        asyncLibrary: dartAsync,
      ),
    );

    // During linking we create libraries when typeProvider is not ready.
    // Update these libraries now, when typeProvider is ready.
    for (var reference in rootReference.children) {
      var libraryElement = reference.element as LibraryElementImpl?;
      if (libraryElement != null && !libraryElement.hasTypeProviderSystemSet) {
        setLibraryTypeSystem(libraryElement);
      }
    }
  }

  void dispose() {
    for (var libraryReference in rootReference.children) {
      _disposeLibrary(libraryReference.element);
    }
  }

  ElementImpl elementOfReference3(Reference reference) {
    if (reference.element case var element?) {
      return element;
    }

    if (reference.isLibrary) {
      var uri = uriCache.parse(reference.name);
      var result = _createLibraryElementForReading(uri);
      result ?? _reportMissingLibrary(uri);
      return result;
    }

    var parentRef = reference.parentNotContainer;
    var parentElement = elementOfReference3(parentRef);

    // Only classes delay creating children.
    if (parentElement is ClassElementImpl) {
      parentElement.ensureReadMembers();
    }

    var element = reference.element;
    if (element == null) {
      throw StateError('Expected existing element: $reference');
    }
    return element;
  }

  LibraryElementImpl? libraryOfUri(Uri uri) {
    var reference = rootReference.getChild('$uri');
    if (reference.element case LibraryElementImpl element) {
      return element;
    }
    return _createLibraryElementForReading(uri);
  }

  LibraryElementImpl libraryOfUri2(Uri uri) {
    var element = libraryOfUri(uri);
    element ?? _reportMissingLibrary(uri);
    return element;
  }

  /// We have linked the bundle, and need to disconnect its libraries, so
  /// that the client can re-add the bundle, this time read from bytes.
  void removeBundle(Set<Uri> uriSet) {
    removeLibraries(uriSet);
  }

  /// Remove libraries with the specified URIs from the reference tree, and
  /// any session level caches.
  void removeLibraries(Set<Uri> uriSet) {
    addToLogRing('[removeLibraries][uriSet: $uriSet][${StackTrace.current}]');
    for (var uri in uriSet) {
      _libraryReaders.remove(uri);
      libraryManifests.remove(uri);
      var libraryReference = rootReference.removeChild('$uri');
      _disposeLibrary(libraryReference?.element);
    }

    analysisSession.classHierarchy.removeOfLibraries(uriSet);
    analysisSession.inheritanceManager.removeOfLibraries(uriSet);

    // If we discard `dart:core` and `dart:async`, we should also discard
    // the type provider.
    if (uriSet.contains(_dartCoreUri)) {
      // Most of the time, if the `uriSet` contains `dart:core`, then it will
      // also contain `dart:async`, since `dart:core` and `dart:async` are part
      // of the same library cycle. However, if an event triggers `dart:core` to
      // be discarded at a time when no library cycle information has been built
      // yet, then just `dart:core` will be in `uriSet`. This can happen, for
      // example, if two events trigger invalidation of `dart:core` in rapid
      // succession. Fortunately, if this happens, it is benign; since no
      // library cycle information has been built yet, there is nothing that
      // that needs to be discarded.

      if (_libraryReaders.isNotEmpty) {
        throw StateError(
          'Expected to link dart:core and dart:async first: '
          '${_libraryReaders.keys.toList()}',
        );
      }
      analysisContext.clearTypeProvider();
    }
  }

  void replaceAnalysisSession(AnalysisSessionImpl newSession) {
    analysisSession = newSession;
    for (var libraryReference in rootReference.children) {
      var libraryElement = libraryReference.element;
      if (libraryElement is LibraryElementImpl) {
        libraryElement.session = newSession;
      }
    }
  }

  void setLibraryTypeSystem(LibraryElementImpl libraryElement) {
    // During linking we create libraries when typeProvider is not ready.
    // And if we link dart:core and dart:async, we cannot create it.
    // We will set typeProvider later, during [createTypeProviders].
    if (!analysisContext.hasTypeProvider) {
      return;
    }

    libraryElement.typeProvider = analysisContext.typeProvider;
    libraryElement.typeSystem = analysisContext.typeSystem;
    libraryElement.hasTypeProviderSystemSet = true;
  }

  LibraryElementImpl? _createLibraryElementForReading(Uri uri) {
    var sourceFactory = analysisContext.sourceFactory;
    var librarySource = sourceFactory.forUri2(uri);
    if (librarySource == null) {
      return null;
    }

    var reader = _libraryReaders[uri];
    if (reader == null) {
      return null;
    }

    var libraryElement = reader.readElement(librarySource: librarySource);
    setLibraryTypeSystem(libraryElement);
    return libraryElement;
  }

  void _disposeLibrary(ElementImpl? libraryElement) {}

  Never _reportMissingLibrary(Uri uri) {
    var rootChildren = rootReference.children.map((e) => e.name).toList();
    if (rootChildren.length > 50) {
      rootChildren = [
        ...rootChildren.take(50),
        '... (${rootChildren.length} total)',
      ];
    }
    var readers = _libraryReaders.keys.map((uri) => uri.toString()).toList();
    if (readers.length > 50) {
      readers = [...readers.take(50), '... (${readers.length} total)'];
    }
    throw ArgumentError(
      'Missing library: $uri\n'
      'Libraries: $uriListWithLibraryElements\n'
      'Root children: $rootChildren\n'
      'Readers: $readers\n'
      'Log: ${_logRing.join('\n')}\n',
    );
  }
}
