// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/generated/engine.dart';
library;

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_event.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/fine/library_manifest.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:collection/collection.dart';

/// Context information necessary to analyze one or more libraries within an
/// [AnalysisDriver].
///
/// Currently this is implemented as a wrapper around [AnalysisContext].
class LibraryContext {
  final LibraryContextTestData? testData;
  final PerformanceLog logger;
  final ByteStore byteStore;
  final StreamController<Object>? eventsController;
  final FileSystemState fileSystemState;
  final File? packagesFile;
  final bool withFineDependencies;
  final SummaryDataStore store = SummaryDataStore();

  late final AnalysisContextImpl analysisContext;
  late final LinkedElementFactory elementFactory;

  Set<LibraryCycle> loadedBundles = Set.identity();
  final LinkedBundleProvider linkedBundleProvider;

  LibraryContext({
    required this.testData,
    required AnalysisSessionImpl analysisSession,
    required this.logger,
    required this.byteStore,
    required this.eventsController,
    required this.fileSystemState,
    required this.linkedBundleProvider,
    required AnalysisOptionsMap analysisOptionsMap,
    required DeclaredVariables declaredVariables,
    required SourceFactory sourceFactory,
    required this.packagesFile,
    required this.withFineDependencies,
    required SummaryDataStore? externalSummaries,
  }) {
    testData?.instance = this;

    analysisContext = AnalysisContextImpl(
      analysisOptionsMap: analysisOptionsMap,
      declaredVariables: declaredVariables,
      sourceFactory: sourceFactory,
    );

    elementFactory = LinkedElementFactory(
      analysisContext,
      analysisSession,
      Reference.root(),
    );
    if (externalSummaries != null) {
      for (var bundle in externalSummaries.bundles) {
        elementFactory.addBundle(
          BundleReader(
            elementFactory: elementFactory,
            resolutionBytes: bundle.resolutionBytes,
            unitsInformativeBytes: {},
            libraryManifests: {},
          ),
        );
      }
    }
  }

  /// Computes a [LibraryFragmentImpl] for the given library/unit pair.
  LibraryFragmentImpl computeUnitElement(
    LibraryFileKind library,
    FileState unit,
  ) {
    var libraryElement = elementFactory.libraryOfUri2(library.file.uri);
    return libraryElement.fragments.singleWhere(
      (fragment) => fragment.source.uri == unit.uri,
    );
  }

  /// Notifies this object that it is about to be discarded.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> dispose() {
    var keys = unloadAll();
    elementFactory.dispose();
    testData?.instance = null;
    return keys;
  }

  /// Get the [LibraryElementImpl] for the given library.
  LibraryElementImpl getLibraryElement(Uri uri) {
    _createElementFactoryTypeProvider();
    return elementFactory.libraryOfUri2(uri);
  }

  /// Load data required to access elements of the given [targetLibrary].
  void load({
    required LibraryFileKind targetLibrary,
    required OperationPerformanceImpl performance,
  }) {
    var libraryCycle = performance.run('libraryCycle', (performance) {
      fileSystemState.newFileOperationPerformance = performance;
      try {
        return targetLibrary.libraryCycle;
      } finally {
        fileSystemState.newFileOperationPerformance = null;
      }
    });

    if (loadedBundles.contains(libraryCycle)) {
      return;
    }

    performance.run('loadBundle', (performance) {
      _loadBundle(cycle: libraryCycle, performance: performance);
    });

    // There might be a rare (and wrong) situation, when the external summaries
    // already include the [targetLibrary]. When this happens, [loadBundle]
    // exists without doing any work. But the type provider must be created.
    _createElementFactoryTypeProvider();
  }

  /// Remove libraries represented by the [removed] files.
  /// If we need these libraries later, we will relink and reattach them.
  void remove(Set<FileState> removed, Set<String> removedKeys) {
    elementFactory.removeLibraries(removed.map((e) => e.uri).toSet());

    loadedBundles.removeWhere((cycle) {
      var cycleFiles = cycle.libraries.map((e) => e.file);
      if (cycleFiles.any(removed.contains)) {
        removedKeys.add(cycle.linkedKey);
        return true;
      }
      return false;
    });
  }

  /// Unloads all loaded bundles.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> unloadAll() {
    var keySet = <String>{};
    var uriSet = <Uri>{};

    for (var cycle in loadedBundles) {
      keySet.add(cycle.linkedKey);
      uriSet.addAll(cycle.libraries.map((e) => e.file.uri));
    }

    elementFactory.removeLibraries(uriSet);
    loadedBundles.clear();

    return keySet;
  }

  /// Ensure that type provider is created.
  void _createElementFactoryTypeProvider() {
    if (!analysisContext.hasTypeProvider) {
      elementFactory.createTypeProviders(
        elementFactory.dartCoreElement,
        elementFactory.dartAsyncElement,
      );
    }
  }

  /// Returns a previously linked bundle entry for [cycle] if present and
  /// reusable; otherwise returns `null`. Always returns the last known
  /// [LibraryManifest]s from the stored entry (if any) so they can be reused
  /// to preserve item versions during relinking.
  _LinkedBundleEntryResult _getLinkedBundleEntry({
    required LibraryCycle cycle,
    required OperationPerformanceImpl performance,
  }) {
    return performance.run('getLinkedBundleEntry', (performance) {
      var entry = performance.run('bundleProvider.get', (performance) {
        return linkedBundleProvider.get(
          key: cycle.linkedKey,
          performance: performance,
        );
      });

      // Nothing cached at all.
      if (entry == null) {
        return _LinkedBundleEntryResult(entry: null, libraryManifests: {});
      }

      // If we don't track fine dependencies, any hit is good enough.
      // The key already depends on the transitive API signature.
      if (!withFineDependencies) {
        return _LinkedBundleEntryResult(entry: entry, libraryManifests: {});
      }

      // If anything changed in the API signature, relink the cycle.
      // But keep previous manifests to reuse item IDs.
      if (entry.nonTransitiveApiSignature != cycle.nonTransitiveApiSignature) {
        return _LinkedBundleEntryResult(
          entry: null,
          libraryManifests: entry.libraryManifests,
        );
      }

      // Already validated for this transitive state? Skip.
      if (entry.isValidated(cycle.apiSignature)) {
        return _LinkedBundleEntryResult(
          entry: entry,
          libraryManifests: entry.libraryManifests,
        );
      }

      var failure = performance.run('checkRequirements', (performance) {
        return entry.requirements.isSatisfied(
          elementFactory: elementFactory,
          libraryManifests: elementFactory.libraryManifests,
        );
      });

      eventsController?.add(
        CheckLinkedBundleRequirements(cycle: cycle, failure: failure),
      );

      if (failure != null) {
        return _LinkedBundleEntryResult(
          entry: null,
          libraryManifests: entry.libraryManifests,
        );
      }

      entry.addValidated(cycle.apiSignature);

      return _LinkedBundleEntryResult(
        entry: entry,
        libraryManifests: entry.libraryManifests,
      );
    });
  }

  /// Recursively load the linked bundle for [cycle], link if not available.
  ///
  /// Uses the same [performance] during recursion, so has single aggregate
  /// set of operations.
  void _loadBundle({
    required LibraryCycle cycle,
    required OperationPerformanceImpl performance,
  }) {
    if (!loadedBundles.add(cycle)) return;
    addToLogRing('[load][cycle: $cycle]');

    performance.getDataInt('cycleCount').increment();
    performance.getDataInt('libraryCount').add(cycle.libraries.length);

    for (var directDependency in cycle.directDependencies) {
      _loadBundle(cycle: directDependency, performance: performance);
    }

    var unitsInformativeBytes = <Uri, Uint8List>{};
    for (var library in cycle.libraries) {
      for (var file in library.files) {
        unitsInformativeBytes[file.uri] = file.unlinked2.informativeBytes;
      }
    }

    var bundleLookup = _getLinkedBundleEntry(
      cycle: cycle,
      performance: performance,
    );
    var bundleEntry = bundleLookup.entry;

    if (bundleEntry == null) {
      testData?.linkedCycles.add(
        cycle.libraries.map((e) => e.file.path).toSet(),
      );

      Uint8List linkedBytes;
      try {
        if (withFineDependencies) {
          var requirements = RequirementsManifest();
          globalResultRequirements = requirements;

          var linkResult = performance.run('link', (performance) {
            return link(
              elementFactory: elementFactory,
              apiSignature: cycle.nonTransitiveApiSignature,
              performance: performance,
              inputLibraries: cycle.libraries,
            );
          });
          linkedBytes = linkResult.resolutionBytes;

          var newLibraryManifests = <Uri, LibraryManifest>{};
          performance.run('computeManifests', (performance) {
            newLibraryManifests = LibraryManifestBuilder(
              elementFactory: elementFactory,
              inputLibraries: cycle.libraries,
              inputManifests: bundleLookup.libraryManifests,
            ).computeManifests(performance: performance);
            elementFactory.libraryManifests.addAll(newLibraryManifests);
          });

          requirements.addExports(
            elementFactory: elementFactory,
            libraryUriSet: cycle.libraryUris,
          );
          globalResultRequirements?.stopRecording();
          globalResultRequirements = null;
          requirements.removeReqForLibs(cycle.libraryUris);
          assert(requirements.assertSerialization());

          bundleEntry = LinkedBundleEntry(
            nonTransitiveApiSignature: cycle.nonTransitiveApiSignature,
            libraryManifests: newLibraryManifests,
            requirements: requirements,
            linkedBytes: linkedBytes,
          );
          bundleEntry.addValidated(cycle.apiSignature);

          performance.run('bundleProvider.put', (performance) {
            linkedBundleProvider.put(
              key: cycle.linkedKey,
              entry: bundleEntry!,
              performance: performance,
            );
          });

          eventsController?.add(
            LinkLibraryCycle(
              elementFactory: elementFactory,
              cycle: cycle,
              requirements: requirements,
            ),
          );
        } else {
          var linkResult = performance.run('link', (performance) {
            return link(
              elementFactory: elementFactory,
              apiSignature: cycle.nonTransitiveApiSignature,
              performance: performance,
              inputLibraries: cycle.libraries,
            );
          });
          linkedBytes = linkResult.resolutionBytes;

          bundleEntry = LinkedBundleEntry(
            nonTransitiveApiSignature: cycle.nonTransitiveApiSignature,
            libraryManifests: {},
            requirements: RequirementsManifest(),
            linkedBytes: linkedBytes,
          );
          performance.run('bundleProvider.put', (performance) {
            linkedBundleProvider.put(
              key: cycle.linkedKey,
              entry: bundleEntry!,
              performance: performance,
            );
          });

          eventsController?.add(
            LinkLibraryCycle(
              elementFactory: elementFactory,
              cycle: cycle,
              requirements: null,
            ),
          );
        }
      } catch (exception, stackTrace) {
        _throwLibraryCycleLinkException(cycle, exception, stackTrace);
      }

      performance.getDataInt('bytesPut').add(linkedBytes.length);
      testData?.forCycle(cycle).putKeys.add(cycle.linkedKey);
    } else {
      var linkedBytes = bundleEntry.linkedBytes;
      testData?.forCycle(cycle).getKeys.add(cycle.linkedKey);
      performance.getDataInt('bytesGet').add(linkedBytes.length);
      performance.getDataInt('libraryLoadCount').add(cycle.libraries.length);
      // TODO(scheglov): Take / clear parsed units in files.
      eventsController?.add(ReuseLinkedBundle(cycle: cycle));
      var bundleReader = performance.run('bundleReader', (performance) {
        return BundleReader(
          elementFactory: elementFactory,
          unitsInformativeBytes: unitsInformativeBytes,
          resolutionBytes: linkedBytes,
          libraryManifests: bundleEntry!.libraryManifests,
        );
      });
      elementFactory.addBundle(bundleReader);
      elementFactory.libraryManifests.addAll(bundleEntry.libraryManifests);
      addToLogRing('[load][addedBundle][cycle: $cycle]');
    }
  }

  /// The [exception] was caught during the [cycle] linking.
  ///
  /// Throw another exception that wraps the given one, with more information.
  Never _throwLibraryCycleLinkException(
    LibraryCycle cycle,
    Object exception,
    StackTrace stackTrace,
  ) {
    var fileContentMap = <String, String>{};
    for (var library in cycle.libraries) {
      for (var file in library.files) {
        fileContentMap[file.path] = file.content;
      }
    }
    throw CaughtExceptionWithFiles(exception, stackTrace, fileContentMap);
  }
}

class LibraryContextTestData {
  final FileSystemTestData fileSystemTestData;

  // TODO(scheglov): Use [libraryCycles] and textual dumps for the driver too.
  final List<Set<String>> linkedCycles = [];

  /// Keys: the sorted list of library files.
  final Map<List<FileTestData>, LibraryCycleTestData> libraryCycles =
      LinkedHashMap(
        hashCode: Object.hashAll,
        equals: const ListEquality<FileTestData>().equals,
      );

  /// The current instance of [LibraryContext].
  LibraryContext? instance;

  LibraryContextTestData({required this.fileSystemTestData});

  LibraryCycleTestData forCycle(LibraryCycle cycle) {
    var files = cycle.libraries.map((library) {
      var file = library.file;
      return fileSystemTestData.forFile(file.resource, file.uri);
    }).toList();
    files.sortBy((fileData) => fileData.file.path);

    return libraryCycles[files] ??= LibraryCycleTestData();
  }
}

class LibraryCycleTestData {
  final List<String> getKeys = [];
  final List<String> putKeys = [];
}

/// The entry in [LinkedBundleProvider].
class LinkedBundleEntry {
  /// See [LibraryCycle.nonTransitiveApiSignature].
  final String nonTransitiveApiSignature;

  /// The manifests of libraries in [linkedBytes].
  ///
  /// If we have to relink libraries, we will match new elements against
  /// these old manifests, and reuse IDs for not affected elements.
  final Map<Uri, LibraryManifest> libraryManifests;

  /// The requirements of libraries in [linkedBytes].
  ///
  /// These requirements are to the libraries in dependencies.
  ///
  /// Without fine-grained dependencies, the requirements are empty.
  final RequirementsManifest requirements;

  /// Last transitive API signature for which [requirements] were verified.
  String? _validatedApiSignature;

  /// The serialized libraries, for [BundleReader].
  final Uint8List linkedBytes;

  LinkedBundleEntry({
    required this.nonTransitiveApiSignature,
    required this.libraryManifests,
    required this.requirements,
    required this.linkedBytes,
  });

  void addValidated(String apiSignature) {
    _validatedApiSignature = apiSignature;
  }

  bool isValidated(String apiSignature) {
    return _validatedApiSignature == apiSignature;
  }
}

/// The cache of serialized libraries.
///
/// It is used for performance reasons to avoid reading requirements again
/// and again. Currently after a change to a file with many transitive clients
/// we discard all libraries, and then try to load them again, checking the
/// requirements.
///
/// We also use [BundleReader] to read library headers (not full libraries),
/// but this is relatively cheap.
class LinkedBundleProvider {
  final ByteStore byteStore;
  final bool withFineDependencies;

  /// The cache of deserialized bundles, used only when [withFineDependencies]
  /// to avoid reading requirements and manifests again and again.
  ///
  /// The keys are [LibraryCycle.linkedKey].
  final Map<String, LinkedBundleEntry> map = {};

  LinkedBundleProvider({
    required this.byteStore,
    required this.withFineDependencies,
  });

  LinkedBundleEntry? get({
    required String key,
    required OperationPerformanceImpl performance,
  }) {
    if (map[key] case var entry?) {
      return entry;
    }

    performance.getDataInt('bytesCount').increment();
    var bytes = byteStore.get(key);
    if (bytes == null) {
      return null;
    }

    performance.getDataInt('bytesLength').add(bytes.length);
    var reader = SummaryDataReader(bytes);
    var nonTransitiveApiSignature = reader.readStringUtf8();
    var libraryManifests = reader.readMap(
      readKey: () => reader.readUri(),
      readValue: () => LibraryManifest.read(reader),
    );
    var requirements = RequirementsManifest.read(reader);
    var linkedBytes = reader.readUint8List();

    var result = LinkedBundleEntry(
      nonTransitiveApiSignature: nonTransitiveApiSignature,
      libraryManifests: libraryManifests,
      requirements: requirements,
      linkedBytes: linkedBytes,
    );

    if (withFineDependencies) {
      map[key] = result;
    }

    // We have copies of all data.
    byteStore.release([key]);

    return result;
  }

  void put({
    required String key,
    required LinkedBundleEntry entry,
    required OperationPerformanceImpl performance,
  }) {
    var sink = BufferedSink();

    sink.writeStringUtf8(entry.nonTransitiveApiSignature);
    sink.writeMap(
      entry.libraryManifests,
      writeKey: (uri) => sink.writeUri(uri),
      writeValue: (manifest) => manifest.write(sink),
    );
    entry.requirements.write(sink);
    sink.writeUint8List(entry.linkedBytes);

    var bytes = sink.takeBytes();
    byteStore.putGet(key, bytes);
    performance.getDataInt('bytes').add(bytes.length);

    if (withFineDependencies) {
      map[key] = entry;
    }
  }
}

class _LinkedBundleEntryResult {
  final LinkedBundleEntry? entry;
  final Map<Uri, LibraryManifest> libraryManifests;

  _LinkedBundleEntryResult({
    required this.entry,
    required this.libraryManifests,
  });
}
