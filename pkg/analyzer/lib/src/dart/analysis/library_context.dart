// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as macro;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/element/element.dart'
    show CompilationUnitElement, LibraryElement;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:path/src/context.dart';

var counterLinkedLibraries = 0;
var counterLoadedLibraries = 0;
var timerBundleToBytes = Stopwatch(); // TODO(scheglov) use
var timerInputLibraries = Stopwatch();
var timerLinking = Stopwatch();
var timerLoad = Stopwatch();

/// Context information necessary to analyze one or more libraries within an
/// [AnalysisDriver].
///
/// Currently this is implemented as a wrapper around [AnalysisContext].
class LibraryContext {
  final LibraryContextTestView testView;
  final PerformanceLog logger;
  final ByteStore byteStore;
  final FileSystemState fileSystemState;
  final MacroKernelBuilder? macroKernelBuilder;
  final macro.MultiMacroExecutor? macroExecutor;
  final SummaryDataStore store = SummaryDataStore();

  late final AnalysisContextImpl analysisContext;
  late LinkedElementFactory elementFactory;

  LibraryContext({
    required this.testView,
    required AnalysisSessionImpl analysisSession,
    required this.logger,
    required this.byteStore,
    required this.fileSystemState,
    required AnalysisOptionsImpl analysisOptions,
    required DeclaredVariables declaredVariables,
    required SourceFactory sourceFactory,
    required this.macroKernelBuilder,
    required this.macroExecutor,
    required SummaryDataStore? externalSummaries,
  }) {
    var synchronousSession =
        SynchronousSession(analysisOptions, declaredVariables);
    analysisContext = AnalysisContextImpl(synchronousSession, sourceFactory);

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
          ),
        );
      }
    }
  }

  /// Computes a [CompilationUnitElement] for the given library/unit pair.
  CompilationUnitElement computeUnitElement(FileState library, FileState unit) {
    var reference = elementFactory.rootReference
        .getChild(library.uriStr)
        .getChild('@unit')
        .getChild(unit.uriStr);
    var element = elementFactory.elementOfReference(reference);
    return element as CompilationUnitElement;
  }

  void dispose() {
    elementFactory.dispose();
  }

  /// Get the [LibraryElement] for the given library.
  LibraryElement getLibraryElement(Uri uri) {
    _createElementFactoryTypeProvider();
    return elementFactory.libraryOfUri2('$uri');
  }

  /// Return [LibraryElement] if it is ready.
  LibraryElement? getLibraryElementIfReady(String uriStr) {
    return elementFactory.libraryOfUriIfReady(uriStr);
  }

  /// Load data required to access elements of the given [targetLibrary].
  Future<void> load(FileState targetLibrary) async {
    timerLoad.start();
    var librariesTotal = 0;
    var librariesLoaded = 0;
    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var inputsTimer = Stopwatch();
    var bytesGet = 0;
    var bytesPut = 0;

    Future<void> loadBundle(LibraryCycle cycle) async {
      if (cycle.libraries.isEmpty ||
          elementFactory.hasLibrary(cycle.libraries.first.uriStr)) {
        return;
      }

      librariesTotal += cycle.libraries.length;

      for (var directDependency in cycle.directDependencies) {
        await loadBundle(directDependency);
      }

      var unitsInformativeBytes = <Uri, Uint8List>{};
      var macroLibraries = <MacroLibrary>[];
      for (var library in cycle.libraries) {
        var macroClasses = <MacroClass>[];
        for (var file in library.libraryFiles) {
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
              uri: library.uri,
              path: library.path,
              classes: macroClasses,
            ),
          );
        }
      }

      var resolutionKey = cycle.transitiveSignature + '.linked_bundle';
      var resolutionBytes = byteStore.get(resolutionKey);

      if (resolutionBytes == null) {
        librariesLinkedTimer.start();

        testView.linkedCycles.add(
          cycle.libraries.map((e) => e.path).toSet(),
        );

        timerInputLibraries.start();
        inputsTimer.start();
        var inputLibraries = <LinkInputLibrary>[];
        for (var libraryFile in cycle.libraries) {
          var librarySource = libraryFile.source;

          var inputUnits = <LinkInputUnit>[];
          var partIndex = -1;
          for (var file in libraryFile.libraryFiles) {
            var isSynthetic = !file.exists;
            var unit = file.parse();

            String? partUriStr;
            if (partIndex >= 0) {
              partUriStr = libraryFile.unlinked2.parts[partIndex];
            }
            partIndex++;

            inputUnits.add(
              LinkInputUnit(
                // TODO(scheglov) bad, group part data
                partDirectiveIndex: partIndex - 1,
                partUriStr: partUriStr,
                source: file.source,
                sourceContent: file.content,
                isSynthetic: isSynthetic,
                unit: unit,
              ),
            );
          }

          inputLibraries.add(
            LinkInputLibrary(
              source: librarySource,
              units: inputUnits,
            ),
          );
        }
        inputsTimer.stop();
        timerInputLibraries.stop();

        LinkResult linkResult;
        try {
          timerLinking.start();
          linkResult = await link(elementFactory, inputLibraries,
              macroExecutor: macroExecutor);
          librariesLinked += cycle.libraries.length;
          counterLinkedLibraries += inputLibraries.length;
          timerLinking.stop();
        } catch (exception, stackTrace) {
          _throwLibraryCycleLinkException(cycle, exception, stackTrace);
        }

        resolutionBytes = linkResult.resolutionBytes;
        byteStore.put(resolutionKey, resolutionBytes);
        bytesPut += resolutionBytes.length;
        counterUnlinkedLinkedBytes += resolutionBytes.length;

        librariesLinkedTimer.stop();
      } else {
        // TODO(scheglov) Take / clear parsed units in files.
        bytesGet += resolutionBytes.length;
        librariesLoaded += cycle.libraries.length;
        elementFactory.addBundle(
          BundleReader(
            elementFactory: elementFactory,
            unitsInformativeBytes: unitsInformativeBytes,
            resolutionBytes: resolutionBytes,
          ),
        );
      }

      final macroKernelBuilder = this.macroKernelBuilder;
      if (macroKernelBuilder != null && macroLibraries.isNotEmpty) {
        var macroKernelKey = cycle.transitiveSignature + '.macro_kernel';
        var macroKernelBytes = byteStore.get(macroKernelKey);
        if (macroKernelBytes == null) {
          macroKernelBytes = macroKernelBuilder.build(
            fileSystem: _MacroFileSystem(fileSystemState),
            libraries: macroLibraries,
          );
          byteStore.put(macroKernelKey, macroKernelBytes);
          bytesPut += macroKernelBytes.length;
        } else {
          bytesGet += macroKernelBytes.length;
        }

        final macroExecutor = this.macroExecutor;
        if (macroExecutor != null) {
          var bundleMacroExecutor = BundleMacroExecutor(
            macroExecutor: macroExecutor,
            kernelBytes: macroKernelBytes,
            libraries: cycle.libraries.map((e) => e.uri).toSet(),
          );
          for (var libraryFile in cycle.libraries) {
            var libraryUriStr = libraryFile.uriStr;
            var libraryElement = elementFactory.libraryOfUri2(libraryUriStr);
            libraryElement.bundleMacroExecutor = bundleMacroExecutor;
          }
        }
      }
    }

    await logger.runAsync('Prepare linked bundles', () async {
      var libraryCycle = targetLibrary.libraryCycle;
      await loadBundle(libraryCycle);
      logger.writeln(
        '[librariesTotal: $librariesTotal]'
        '[librariesLoaded: $librariesLoaded]'
        '[inputsTimer: ${inputsTimer.elapsedMilliseconds} ms]'
        '[librariesLinked: $librariesLinked]'
        '[librariesLinkedTimer: ${librariesLinkedTimer.elapsedMilliseconds} ms]'
        '[bytesGet: $bytesGet][bytesPut: $bytesPut]',
      );
    });

    // There might be a rare (and wrong) situation, when the external summaries
    // already include the [targetLibrary]. When this happens, [loadBundle]
    // exists without doing any work. But the type provider must be created.
    _createElementFactoryTypeProvider();

    timerLoad.stop();
  }

  /// Ensure that type provider is created.
  void _createElementFactoryTypeProvider() {
    if (!analysisContext.hasTypeProvider) {
      var dartCore = elementFactory.libraryOfUri2('dart:core');
      var dartAsync = elementFactory.libraryOfUri2('dart:async');
      elementFactory.createTypeProviders(dartCore, dartAsync);
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
    for (var libraryFile in cycle.libraries) {
      for (var file in libraryFile.libraryFiles) {
        fileContentMap[file.path] = file.content;
      }
    }
    throw CaughtExceptionWithFiles(exception, stackTrace, fileContentMap);
  }
}

class LibraryContextTestView {
  final List<Set<String>> linkedCycles = [];
}

class _MacroFileEntry implements MacroFileEntry {
  final FileState fileState;

  _MacroFileEntry(this.fileState);

  @override
  String get content => fileState.content;

  @override
  bool get exists => fileState.exists;
}

class _MacroFileSystem implements MacroFileSystem {
  final FileSystemState fileSystemState;

  _MacroFileSystem(this.fileSystemState);

  @override
  Context get pathContext => fileSystemState.pathContext;

  @override
  MacroFileEntry getFile(String path) {
    var fileState = fileSystemState.getFileForPath(path);
    return _MacroFileEntry(fileState);
  }
}
