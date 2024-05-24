// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/element/element.dart'
    show CompilationUnitElement, LibraryElement;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/info_declaration_store.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_cache.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';

/// Context information necessary to analyze one or more libraries within an
/// [AnalysisDriver].
///
/// Currently this is implemented as a wrapper around [AnalysisContext].
class LibraryContext {
  final LibraryContextTestData? testData;
  final PerformanceLog logger;
  final ByteStore byteStore;
  final InfoDeclarationStore infoDeclarationStore;
  final FileSystemState fileSystemState;
  final MacroSupport? macroSupport;
  final File? packagesFile;
  final SummaryDataStore store = SummaryDataStore();

  late final AnalysisContextImpl analysisContext;
  late final LinkedElementFactory elementFactory;

  Set<LibraryCycle> loadedBundles = Set.identity();

  LibraryContext({
    required this.testData,
    required AnalysisSessionImpl analysisSession,
    required this.logger,
    required this.byteStore,
    required this.infoDeclarationStore,
    required this.fileSystemState,
    required AnalysisOptionsMap analysisOptionsMap,
    required DeclaredVariables declaredVariables,
    required SourceFactory sourceFactory,
    required this.macroSupport,
    required this.packagesFile,
    required SummaryDataStore? externalSummaries,
  }) {
    analysisContext = AnalysisContextImpl(
      analysisOptionsMap: analysisOptionsMap,
      declaredVariables: declaredVariables,
      sourceFactory: sourceFactory,
    );

    elementFactory = LinkedElementFactory(
      analysisContext,
      analysisSession,
      Reference.root(),
      macroSupport,
    );
    if (externalSummaries != null) {
      for (var bundle in externalSummaries.bundles) {
        elementFactory.addBundle(
          BundleReader(
            elementFactory: elementFactory,
            resolutionBytes: bundle.resolutionBytes,
            unitsInformativeBytes: {},
            infoDeclarationStore: infoDeclarationStore,
          ),
        );
      }
    }
  }

  /// Computes a [CompilationUnitElement] for the given library/unit pair.
  CompilationUnitElementImpl computeUnitElement(
    LibraryFileKind library,
    FileState unit,
  ) {
    var kind = unit.kind;

    String unitContainerName;
    if (library == kind.library) {
      unitContainerName = switch (unit.kind) {
        AugmentationFileKind() => '@augmentation',
        _ => '@unit',
      };
    } else {
      // Recovery.
      library = kind.asLibrary;
      unitContainerName = '@unit';
    }

    var reference = elementFactory.rootReference
        .getChild(library.file.uriStr)
        .getChild(unitContainerName)
        .getChild(unit.uriStr);
    var element = elementFactory.elementOfReference(reference);
    return element as CompilationUnitElementImpl;
  }

  /// Notifies this object that it is about to be discarded.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> dispose() {
    var keys = unloadAll();
    elementFactory.dispose();
    return keys;
  }

  /// Get the [LibraryElement] for the given library.
  LibraryElement getLibraryElement(Uri uri) {
    _createElementFactoryTypeProvider();
    return elementFactory.libraryOfUri2(uri);
  }

  /// Load data required to access elements of the given [targetLibrary].
  Future<void> load({
    required LibraryFileKind targetLibrary,
    required OperationPerformanceImpl performance,
  }) async {
    addToLogRing('[load][targetLibrary: ${targetLibrary.file}]');
    var librariesTotal = 0;
    var librariesLoaded = 0;
    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var bytesGet = 0;
    var bytesPut = 0;

    Future<void> loadBundle(LibraryCycle cycle) async {
      if (!loadedBundles.add(cycle)) return;

      performance.getDataInt('cycleCount').increment();
      performance.getDataInt('libraryCount').add(cycle.libraries.length);

      librariesTotal += cycle.libraries.length;

      for (var directDependency in cycle.directDependencies) {
        await loadBundle(directDependency);
      }

      var unitsInformativeBytes = <Uri, Uint8List>{};
      var macroLibraries = <MacroLibrary>[];
      for (var library in cycle.libraries) {
        var macroClasses = <MacroClass>[];
        for (var file in library.files) {
          unitsInformativeBytes[file.uri] = file.unlinked2.informativeBytes;
          for (var macroClass in file.unlinked2.macroClasses) {
            macroClasses.add(
              MacroClass(
                name: macroClass.name,
                constructors: macroClass.constructors,
              ),
            );
          }
        }
        if (macroClasses.isNotEmpty) {
          macroLibraries.add(
            MacroLibrary(
              uri: library.file.uri,
              path: library.file.path,
              classes: macroClasses,
            ),
          );
        }
      }

      var macroResultKey = cycle.cachedMacrosKey;
      var inputMacroResults = <LibraryFileKind, MacroResultInput>{};
      if (byteStore.get(macroResultKey) case var bytes?) {
        _readMacroResults(
          cycle: cycle,
          bytes: bytes,
          macroResults: inputMacroResults,
        );
      }

      var linkedBytes = byteStore.get(cycle.linkedKey);

      if (linkedBytes == null) {
        librariesLinkedTimer.start();

        testData?.linkedCycles.add(
          cycle.libraries.map((e) => e.file.path).toSet(),
        );

        LinkResult linkResult;
        try {
          linkResult = await performance.runAsync(
            'link',
            (performance) async {
              return await link(
                elementFactory: elementFactory,
                performance: performance,
                inputLibraries: cycle.libraries,
                inputMacroResults: inputMacroResults,
                macroExecutor: this.macroSupport?.executor,
              );
            },
          );
          librariesLinked += cycle.libraries.length;
        } catch (exception, stackTrace) {
          _throwLibraryCycleLinkException(cycle, exception, stackTrace);
        }

        linkedBytes = linkResult.resolutionBytes;
        byteStore.putGet(cycle.linkedKey, linkedBytes);
        performance.getDataInt('bytesPut').add(linkedBytes.length);
        testData?.forCycle(cycle).putKeys.add(cycle.linkedKey);
        bytesPut += linkedBytes.length;

        _writeMacroResults(
          cycle: cycle,
          linkResult: linkResult,
          macroResultKey: macroResultKey,
        );

        librariesLinkedTimer.stop();
      } else {
        testData?.forCycle(cycle).getKeys.add(cycle.linkedKey);
        performance.getDataInt('bytesGet').add(linkedBytes.length);
        performance.getDataInt('libraryLoadCount').add(cycle.libraries.length);
        // TODO(scheglov): Take / clear parsed units in files.
        bytesGet += linkedBytes.length;
        librariesLoaded += cycle.libraries.length;
        var bundleReader = BundleReader(
          elementFactory: elementFactory,
          unitsInformativeBytes: unitsInformativeBytes,
          resolutionBytes: linkedBytes,
          infoDeclarationStore: infoDeclarationStore,
        );
        elementFactory.addBundle(bundleReader);
        _addMacroAugmentations(cycle, bundleReader);
      }

      // If we can compile to kernel, check if there are macros.
      var macroSupport = this.macroSupport;
      var packagesFile = this.packagesFile;
      if (macroSupport is KernelMacroSupport &&
          packagesFile != null &&
          macroLibraries.isNotEmpty) {
        var kernelBytes = byteStore.get(cycle.macroKey);
        if (kernelBytes == null) {
          kernelBytes = await performance.runAsync<Uint8List>(
            'macroCompileKernel',
            (performance) async {
              return await macroSupport.builder.build(
                fileSystem: _MacroFileSystem(fileSystemState),
                packageFilePath: packagesFile.path,
                libraries: macroLibraries,
              );
            },
          );
          byteStore.putGet(cycle.macroKey, kernelBytes);
          bytesPut += kernelBytes.length;
        } else {
          bytesGet += kernelBytes.length;
        }

        elementFactory.addKernelMacroBundle(
          macroSupport: macroSupport,
          kernelBytes: kernelBytes,
          libraries: cycle.libraries.map((e) => e.file.uri).toSet(),
        );
      }
    }

    await logger.runAsync('Prepare linked bundles', () async {
      var libraryCycle = targetLibrary.libraryCycle;
      await loadBundle(libraryCycle);
      logger.writeln(
        '[librariesTotal: $librariesTotal]'
        '[librariesLoaded: $librariesLoaded]'
        '[librariesLinked: $librariesLinked]'
        '[librariesLinkedTimer: ${librariesLinkedTimer.elapsedMilliseconds} ms]'
        '[bytesGet: $bytesGet][bytesPut: $bytesPut]',
      );
    });

    // There might be a rare (and wrong) situation, when the external summaries
    // already include the [targetLibrary]. When this happens, [loadBundle]
    // exists without doing any work. But the type provider must be created.
    _createElementFactoryTypeProvider();
  }

  /// Remove libraries represented by the [removed] files.
  /// If we need these libraries later, we will relink and reattach them.
  void remove(Set<FileState> removed, Set<String> removedKeys) {
    elementFactory.removeLibraries(
      removed.map((e) => e.uri).toSet(),
    );

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

  /// Create files with macro generated augmentation libraries.
  void _addMacroAugmentations(LibraryCycle cycle, BundleReader bundleReader) {
    for (var libraryReader in bundleReader.libraryMap.values) {
      var macroGeneratedCode = libraryReader.macroGeneratedCode;
      if (macroGeneratedCode != null) {
        for (var libraryKind in cycle.libraries) {
          if (libraryKind.file.uri == libraryReader.uri) {
            libraryKind.addMacroAugmentation(
              macroGeneratedCode,
              partialIndex: null,
            );
          }
        }
      }
    }
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

  /// Fills [macroResults] with results that can be reused.
  void _readMacroResults({
    required LibraryCycle cycle,
    required Uint8List bytes,
    required Map<LibraryFileKind, MacroResultInput> macroResults,
  }) {
    var bundle = MacroCacheBundle.fromBytes(cycle, bytes);
    var testUsedList = <File>[];
    for (var library in bundle.libraries) {
      // If the library itself changed, then declarations that macros see
      // could be different now.
      if (!ListEquality<int>().equals(
        library.apiSignature,
        library.kind.apiSignature,
      )) {
        continue;
      }

      // TODO(scheglov): Record more specific dependencies.
      if (library.hasAnyIntrospection) {
        continue;
      }

      testUsedList.add(library.kind.file.resource);

      macroResults[library.kind] = MacroResultInput(
        code: library.code,
      );
    }

    if (testUsedList.isNotEmpty) {
      var cycleTestData = testData?.forCycle(cycle);
      cycleTestData?.macrosUsedCached.add(testUsedList);
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

  void _writeMacroResults({
    required LibraryCycle cycle,
    required LinkResult linkResult,
    required String macroResultKey,
  }) {
    var results = linkResult.macroResults;
    if (results.isEmpty) {
      return;
    }

    testData?.forCycle(cycle).macrosGenerated.add(
          linkResult.macroResults
              .map((result) => result.library.file.resource)
              .toList(),
        );

    var bundle = MacroCacheBundle(
      libraries: results.map((result) {
        return MacroCacheLibrary(
          kind: result.library,
          apiSignature: result.library.apiSignature,
          hasAnyIntrospection: result.processing.hasAnyIntrospection,
          code: result.code,
        );
      }).toList(),
    );

    var bytes = bundle.toBytes();
    byteStore.putGet(macroResultKey, bytes);
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

  LibraryContextTestData({
    required this.fileSystemTestData,
  });

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
  final List<List<File>> macrosUsedCached = [];
  final List<List<File>> macrosGenerated = [];
}

class _MacroFileEntry implements MacroFileEntry {
  @override
  final String content;

  @override
  final bool exists;

  _MacroFileEntry({
    required this.content,
    required this.exists,
  });
}

class _MacroFileSystem implements MacroFileSystem {
  final FileSystemState fileSystemState;

  _MacroFileSystem(this.fileSystemState);

  @override
  Context get pathContext => fileSystemState.pathContext;

  @override
  MacroFileEntry getFile(String path) {
    var fileState = fileSystemState.getExistingFromPath(path);
    if (fileState != null) {
      return _MacroFileEntry(
        content: fileState.content,
        exists: fileState.exists,
      );
    }

    var fileContent = fileSystemState.fileContentStrategy.get(path);
    return _MacroFileEntry(
      content: fileContent.content,
      exists: fileContent.exists,
    );
  }
}
