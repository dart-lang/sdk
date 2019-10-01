// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart'
    show CompilationUnitElement, LibraryElement;
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/restricted_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptions;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart' as link2;
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';

var counterLinkedLibraries = 0;
var counterLoadedLibraries = 0;
var timerBundleToBytes = Stopwatch();
var timerInputLibraries = Stopwatch();
var timerLinking = Stopwatch();
var timerLoad2 = Stopwatch();

/**
 * Context information necessary to analyze one or more libraries within an
 * [AnalysisDriver].
 *
 * Currently this is implemented as a wrapper around [AnalysisContext].
 */
class LibraryContext {
  static const _maxLinkedDataInBytes = 64 * 1024 * 1024;

  final PerformanceLog logger;
  final ByteStore byteStore;
  final AnalysisSession analysisSession;
  final SummaryDataStore externalSummaries;
  final SummaryDataStore store = new SummaryDataStore([]);

  /// The size of the linked data that is loaded by this context.
  /// When it reaches [_maxLinkedDataInBytes] the whole context is thrown away.
  /// We use it as an approximation for the heap size of elements.
  int _linkedDataInBytes = 0;

  RestrictedAnalysisContext analysisContext;
  LinkedElementFactory elementFactory;
  InheritanceManager3 inheritanceManager;

  var loadedBundles = Set<LibraryCycle>.identity();

  LibraryContext({
    @required AnalysisSession session,
    @required PerformanceLog logger,
    @required ByteStore byteStore,
    @required FileSystemState fsState,
    @required AnalysisOptions analysisOptions,
    @required DeclaredVariables declaredVariables,
    @required SourceFactory sourceFactory,
    @required this.externalSummaries,
    @required FileState targetLibrary,
  })  : this.logger = logger,
        this.byteStore = byteStore,
        this.analysisSession = session {
    if (externalSummaries != null) {
      store.addStore(externalSummaries);
    }

    var synchronousSession =
        SynchronousSession(analysisOptions, declaredVariables);
    analysisContext = new RestrictedAnalysisContext(
      synchronousSession,
      sourceFactory,
    );

    _createElementFactory();
    load2(targetLibrary);

    inheritanceManager = new InheritanceManager3(analysisContext.typeSystem);
  }

  /**
   * The type provider used in this context.
   */
  TypeProvider get typeProvider => analysisContext.typeProvider;

  /**
   * Computes a [CompilationUnitElement] for the given library/unit pair.
   */
  CompilationUnitElement computeUnitElement(FileState library, FileState unit) {
    var reference = elementFactory.rootReference
        .getChild(library.uriStr)
        .getChild('@unit')
        .getChild(unit.uriStr);
    return elementFactory.elementOfReference(reference);
  }

  /**
   * Get the [LibraryElement] for the given library.
   */
  LibraryElement getLibraryElement(FileState library) {
    return elementFactory.libraryOfUri(library.uriStr);
  }

  /**
   * Return `true` if the given [uri] is known to be a library.
   */
  bool isLibraryUri(Uri uri) {
    String uriStr = uri.toString();
    return elementFactory.isLibraryUri(uriStr);
  }

  /// Load data required to access elements of the given [targetLibrary].
  void load2(FileState targetLibrary) {
    timerLoad2.start();
    var inputBundles = <LinkedNodeBundle>[];

    var librariesTotal = 0;
    var librariesLoaded = 0;
    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var inputsTimer = Stopwatch();
    var bytesGet = 0;
    var bytesPut = 0;

    void loadBundle(LibraryCycle cycle) {
      if (!loadedBundles.add(cycle)) return;

      librariesTotal += cycle.libraries.length;

      cycle.directDependencies.forEach(loadBundle);

      var key = cycle.transitiveSignature + '.linked_bundle';
      var bytes = byteStore.get(key);

      if (bytes == null) {
        librariesLinkedTimer.start();

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
          }

          inputLibraries.add(
            link2.LinkInputLibrary(librarySource, inputUnits),
          );
        }
        inputsTimer.stop();
        timerInputLibraries.stop();

        timerLinking.start();
        var linkResult = link2.link(elementFactory, inputLibraries);
        librariesLinked += cycle.libraries.length;
        counterLinkedLibraries += linkResult.bundle.libraries.length;
        timerLinking.stop();

        timerBundleToBytes.start();
        bytes = linkResult.bundle.toBuffer();
        timerBundleToBytes.stop();

        byteStore.put(key, bytes);
        bytesPut += bytes.length;
        counterUnlinkedLinkedBytes += bytes.length;

        librariesLinkedTimer.stop();
      } else {
        // TODO(scheglov) Take / clear parsed units in files.
        bytesGet += bytes.length;
        librariesLoaded += cycle.libraries.length;
      }

      // We are about to load dart:core, but if we have just linked it, the
      // linker might have set the type provider. So, clear it, and recreate
      // the element factory - it is empty anyway.
      if (!elementFactory.hasDartCore) {
        analysisContext.clearTypeProvider();
        _createElementFactory();
      }

      var bundle = LinkedNodeBundle.fromBuffer(bytes);
      inputBundles.add(bundle);
      elementFactory.addBundle(
        LinkedBundleContext(elementFactory, bundle),
      );
      counterLoadedLibraries += bundle.libraries.length;

      // Set informative data.
      for (var libraryFile in cycle.libraries) {
        for (var unitFile in libraryFile.libraryFiles) {
          elementFactory.setInformativeData(
            libraryFile.uriStr,
            unitFile.uriStr,
            unitFile.unlinked2.informativeData,
          );
        }
      }

      // We might have just linked dart:core, ensure the type provider.
      _createElementFactoryTypeProvider();
    }

    logger.run('Prepare linked bundles', () {
      var libraryCycle = targetLibrary.libraryCycle;
      loadBundle(libraryCycle);
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
          LinkedBundleContext(elementFactory, bundle.bundle2),
        );
      }
    }
  }

  /// Ensure that type provider is created.
  void _createElementFactoryTypeProvider() {
    if (analysisContext.typeProvider != null) return;

    var dartCore = elementFactory.libraryOfUri('dart:core');
    var dartAsync = elementFactory.libraryOfUri('dart:async');
    var typeProvider = TypeProviderImpl(dartCore, dartAsync);
    analysisContext.typeProvider = typeProvider;

    dartCore.createLoadLibraryFunction(typeProvider);
    dartAsync.createLoadLibraryFunction(typeProvider);
  }
}
