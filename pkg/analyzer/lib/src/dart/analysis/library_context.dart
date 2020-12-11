// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

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
    show AnalysisContext, AnalysisOptions;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart' as link2;
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';

var counterLinkedLibraries = 0;
var counterLoadedLibraries = 0;
var timerBundleToBytes = Stopwatch(); // TODO(scheglov) use
var timerInputLibraries = Stopwatch();
var timerLinking = Stopwatch();
var timerLoad2 = Stopwatch();

/// Context information necessary to analyze one or more libraries within an
/// [AnalysisDriver].
///
/// Currently this is implemented as a wrapper around [AnalysisContext].
class LibraryContext {
  static const _maxLinkedDataInBytes = 64 * 1024 * 1024;

  final int id = fileObjectId++;
  final LibraryContextTestView testView;
  final PerformanceLog logger;
  final ByteStore byteStore;
  final AnalysisSessionImpl analysisSession;
  final SummaryDataStore externalSummaries;
  final SummaryDataStore store = SummaryDataStore([]);

  /// The size of the linked data that is loaded by this context.
  /// When it reaches [_maxLinkedDataInBytes] the whole context is thrown away.
  /// We use it as an approximation for the heap size of elements.
  final int _linkedDataInBytes = 0;

  AnalysisContextImpl analysisContext;
  LinkedElementFactory elementFactory;

  LibraryContext({
    @required this.testView,
    @required AnalysisSessionImpl session,
    @required PerformanceLog logger,
    @required ByteStore byteStore,
    @required AnalysisOptions analysisOptions,
    @required DeclaredVariables declaredVariables,
    @required SourceFactory sourceFactory,
    @required this.externalSummaries,
    @required FileState targetLibrary,
  })  : logger = logger,
        byteStore = byteStore,
        analysisSession = session {
    var synchronousSession =
        SynchronousSession(analysisOptions, declaredVariables);
    analysisContext = AnalysisContextImpl(synchronousSession, sourceFactory);

    _createElementFactory();
    load2(targetLibrary);
  }

  /// Computes a [CompilationUnitElement] for the given library/unit pair.
  CompilationUnitElement computeUnitElement(FileState library, FileState unit) {
    var reference = elementFactory.rootReference
        .getChild(library.uriStr)
        .getChild('@unit')
        .getChild(unit.uriStr);
    return elementFactory.elementOfReference(reference);
  }

  /// Get the [LibraryElement] for the given library.
  LibraryElement getLibraryElement(FileState library) {
    return elementFactory.libraryOfUri(library.uriStr);
  }

  /// Return `true` if the given [uri] is known to be a library.
  bool isLibraryUri(Uri uri) {
    String uriStr = uri.toString();
    return elementFactory.isLibraryUri(uriStr);
  }

  /// Load data required to access elements of the given [targetLibrary].
  void load2(FileState targetLibrary) {
    timerLoad2.start();
    var librariesTotal = 0;
    var librariesLoaded = 0;
    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var inputsTimer = Stopwatch();
    var bytesGet = 0;
    var bytesPut = 0;

    var thisLoadLogBuffer = StringBuffer();

    void loadBundle(LibraryCycle cycle, String debugPrefix) {
      if (cycle.libraries.isEmpty ||
          elementFactory.hasLibrary(cycle.libraries.first.uriStr)) {
        return;
      }

      thisLoadLogBuffer.writeln('$debugPrefix$cycle');

      librariesTotal += cycle.libraries.length;

      if (cycle.isUnresolvedFile) {
        return;
      }

      cycle.directDependencies.forEach(
        (e) => loadBundle(e, '$debugPrefix  '),
      );

      var uriToLibrary_uriToUnitAstBytes = <String, Map<String, Uint8List>>{};
      for (var library in cycle.libraries) {
        var uriToUnitAstBytes = <String, Uint8List>{};
        uriToLibrary_uriToUnitAstBytes[library.uriStr] = uriToUnitAstBytes;
        for (var file in library.libraryFiles) {
          uriToUnitAstBytes[file.uriStr] = file.getAstBytes();
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
        var inputLibraries = <link2.LinkInputLibrary>[];
        for (var libraryFile in cycle.libraries) {
          var librarySource = libraryFile.source;
          if (librarySource == null) continue;

          var inputUnits = <link2.LinkInputUnit>[];
          var partIndex = -1;
          for (var file in libraryFile.libraryFiles) {
            var isSynthetic = !file.exists;
            var unit = file.parse();

            String partUriStr;
            if (partIndex >= 0) {
              partUriStr = libraryFile.unlinked2.parts[partIndex];
            }
            partIndex++;

            inputUnits.add(
              link2.LinkInputUnit(
                partUriStr,
                file.source,
                isSynthetic,
                unit,
              ),
            );

            // TODO(scheglov) remove after fixing linking issues
            {
              var existingLibraryReference =
                  elementFactory.rootReference[libraryFile.uriStr];
              if (existingLibraryReference != null) {
                var existingElement = existingLibraryReference.element;
                if (existingElement != null) {
                  var buffer = StringBuffer();

                  buffer.writeln('[The library is already loaded]');
                  buffer.writeln();

                  var existingSource = existingElement?.source;
                  buffer.writeln('[oldUri: ${existingSource.uri}]');
                  buffer.writeln('[oldPath: ${existingSource.fullName}]');
                  buffer.writeln('[newUri: ${libraryFile.uriStr}]');
                  buffer.writeln('[newPath: ${libraryFile.path}]');
                  buffer.writeln('[cycle: $cycle]');
                  buffer.writeln();

                  buffer.writeln('Bundles loaded in this load2() invocation:');
                  buffer.writeln(thisLoadLogBuffer);
                  buffer.writeln();

                  var libraryRefs = elementFactory.rootReference.children;
                  var libraryUriList = libraryRefs.map((e) => e.name).toList();
                  buffer.writeln('[elementFactory.libraries: $libraryUriList]');

                  throw CaughtExceptionWithFiles(
                    'Cycle loading state error',
                    StackTrace.current,
                    {'status': buffer.toString()},
                  );
                }
              }
            }
          }

          inputLibraries.add(
            link2.LinkInputLibrary(librarySource, inputUnits),
          );
        }
        inputsTimer.stop();
        timerInputLibraries.stop();

        link2.LinkResult linkResult;
        try {
          timerLinking.start();
          linkResult = link2.link(elementFactory, inputLibraries, true);
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
      }

      elementFactory.addLibraries(
        createLibraryReadersWithAstBytes(
          elementFactory: elementFactory,
          resolutionBytes: resolutionBytes,
          uriToLibrary_uriToUnitAstBytes: uriToLibrary_uriToUnitAstBytes,
        ),
      );
    }

    logger.run('Prepare linked bundles', () {
      var libraryCycle = targetLibrary.libraryCycle;
      loadBundle(libraryCycle, '');
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

    timerLoad2.stop();
  }

  /// Return `true` if this context grew too large, and should be recreated.
  ///
  /// It might have been used to analyze libraries that we don't need anymore,
  /// and because loading libraries is not very expensive (but not free), the
  /// simplest way to get rid of the garbage is to throw away everything.
  bool pack() {
    return _linkedDataInBytes > _maxLinkedDataInBytes;
  }

  void _createElementFactory() {
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
            astBytes: bundle.astBytes,
            resolutionBytes: bundle.resolutionBytes,
          ),
        );
      }
    }
  }

  /// Ensure that type provider is created.
  void _createElementFactoryTypeProvider() {
    if (analysisContext.typeProviderNonNullableByDefault == null) {
      var dartCore = elementFactory.libraryOfUri('dart:core');
      var dartAsync = elementFactory.libraryOfUri('dart:async');
      elementFactory.createTypeProviders(dartCore, dartAsync);
    }
  }

  /// The [exception] was caught during the [cycle] linking.
  ///
  /// Throw another exception that wraps the given one, with more information.
  @alwaysThrows
  void _throwLibraryCycleLinkException(
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
