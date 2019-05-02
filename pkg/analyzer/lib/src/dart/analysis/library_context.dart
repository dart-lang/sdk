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
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptions;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/link.dart' as link2;
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';

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
  final SummaryDataStore store = new SummaryDataStore([]);

  /// The size of the linked data that is loaded by this context.
  /// When it reaches [_maxLinkedDataInBytes] the whole context is thrown away.
  /// We use it as an approximation for the heap size of elements.
  int _linkedDataInBytes = 0;

  RestrictedAnalysisContext analysisContext;
  SummaryResynthesizer resynthesizer;
  LinkedElementFactory elementFactory;
  InheritanceManager2 inheritanceManager;

  LibraryContext({
    @required AnalysisSession session,
    @required PerformanceLog logger,
    @required ByteStore byteStore,
    @required FileSystemState fsState,
    @required AnalysisOptions analysisOptions,
    @required DeclaredVariables declaredVariables,
    @required SourceFactory sourceFactory,
    @required SummaryDataStore externalSummaries,
    @required FileState targetLibrary,
    @required bool useSummary2,
  })  : this.logger = logger,
        this.byteStore = byteStore,
        this.analysisSession = session {
    if (externalSummaries != null) {
      store.addStore(externalSummaries);
    }

    analysisContext = new RestrictedAnalysisContext(
      analysisOptions,
      declaredVariables,
      sourceFactory,
    );

    if (useSummary2) {
      load2(targetLibrary);
    } else {
      // Fill the store with summaries required for the initial library.
      load(targetLibrary);

      resynthesizer = new StoreBasedSummaryResynthesizer(
          analysisContext, session, sourceFactory, true, store);
      analysisContext.typeProvider = resynthesizer.typeProvider;
      resynthesizer.finishCoreAsyncLibraries();
    }

    inheritanceManager = new InheritanceManager2(analysisContext.typeSystem);
  }

  /**
   * The type provider used in this context.
   */
  TypeProvider get typeProvider => analysisContext.typeProvider;

  /**
   * Computes a [CompilationUnitElement] for the given library/unit pair.
   */
  CompilationUnitElement computeUnitElement(FileState library, FileState unit) {
    if (elementFactory != null) {
      var reference = elementFactory.rootReference
          .getChild(library.uriStr)
          .getChild('@unit')
          .getChild(unit.uriStr);
      return elementFactory.elementOfReference(reference);
    } else {
      return resynthesizer.getElement(new ElementLocationImpl.con3(<String>[
        library.uriStr,
        unit.uriStr,
      ]));
    }
  }

  /**
   * Get the [LibraryElement] for the given library.
   */
  LibraryElement getLibraryElement(FileState library) {
    return resynthesizer.getLibraryElement(library.uriStr);
  }

  /**
   * Return `true` if the given [uri] is known to be a library.
   */
  bool isLibraryUri(Uri uri) {
    String uriStr = uri.toString();
    if (elementFactory != null) {
      return elementFactory.isLibraryUri(uriStr);
    } else {
      return store.unlinkedMap[uriStr]?.isPartOf == false;
    }
  }

  /// Load data required to access elements of the given [targetLibrary].
  void load(FileState targetLibrary) {
    // The library is already a part of the context, nothing to do.
    if (store.linkedMap.containsKey(targetLibrary.uriStr)) {
      return;
    }

    var libraries = <String, FileState>{};
    void appendLibraryFiles(FileState library) {
      // Stop if this library is already a part of the context.
      // Libraries from external summaries are also covered by this.
      if (store.linkedMap.containsKey(library.uriStr)) {
        return;
      }

      // Stop if we have already scheduled loading of this library.
      if (libraries.containsKey(library.uriStr)) {
        return;
      }

      // Schedule the library for loading or linking.
      libraries[library.uriStr] = library;

      // Append library units.
      for (FileState part in library.libraryFiles) {
        store.addUnlinkedUnit(part.uriStr, part.unlinked);
      }

      // Append referenced libraries.
      library.importedFiles.forEach(appendLibraryFiles);
      library.exportedFiles.forEach(appendLibraryFiles);
    }

    logger.run('Append library files', () {
      appendLibraryFiles(targetLibrary);
    });

    var libraryUrisToLink = new Set<String>();
    logger.run('Load linked bundles', () {
      for (FileState library in libraries.values) {
        if (library.exists || library == targetLibrary) {
          String key = library.transitiveSignatureLinked;
          List<int> bytes = byteStore.get(key);
          if (bytes != null) {
            LinkedLibrary linked = new LinkedLibrary.fromBuffer(bytes);
            store.addLinkedLibrary(library.uriStr, linked);
            _linkedDataInBytes += bytes.length;
          } else {
            libraryUrisToLink.add(library.uriStr);
          }
        }
      }
      int numOfLoaded = libraries.length - libraryUrisToLink.length;
      logger.writeln('Loaded $numOfLoaded linked bundles.');
    });

    var linkedLibraries = <String, LinkedLibraryBuilder>{};
    logger.run('Link libraries', () {
      linkedLibraries = link(libraryUrisToLink, (String uri) {
        LinkedLibrary linkedLibrary = store.linkedMap[uri];
        return linkedLibrary;
      }, (String uri) {
        UnlinkedUnit unlinkedUnit = store.unlinkedMap[uri];
        return unlinkedUnit;
      }, DeclaredVariables(), analysisContext.analysisOptions);
      logger.writeln('Linked ${linkedLibraries.length} libraries.');
    });

    // Store freshly linked libraries into the byte store.
    // Append them to the context.
    for (String uri in linkedLibraries.keys) {
      FileState library = libraries[uri];
      String key = library.transitiveSignatureLinked;

      LinkedLibraryBuilder linkedBuilder = linkedLibraries[uri];
      List<int> bytes = linkedBuilder.toBuffer();
      byteStore.put(key, bytes);

      LinkedLibrary linked = new LinkedLibrary.fromBuffer(bytes);
      store.addLinkedLibrary(uri, linked);
      _linkedDataInBytes += bytes.length;
    }
  }

  /// Load data required to access elements of the given [targetLibrary].
  void load2(FileState targetLibrary) {
    var loadedBundles = Set<LibraryCycle>.identity();
    var inputBundles = <LinkedNodeBundle>[];

    void loadBundle(LibraryCycle cycle) {
      if (!loadedBundles.add(cycle)) return;

      logger.run('Prepare linked bundle', () {
        logger.writeln('Libraries: ${cycle.libraries}');
        cycle.directDependencies.forEach(loadBundle);

        var key = cycle.transitiveSignature + '.linked_bundle';
        var bytes = byteStore.get(key);

        if (bytes == null) {
          var inputLibraries = <link2.LinkInputLibrary>[];
          logger.run('Prepare input libraries', () {
            for (var libraryFile in cycle.libraries) {
              var librarySource = libraryFile.source;
              if (librarySource == null) continue;

              var inputUnits = <link2.LinkInputUnit>[];
              for (var file in libraryFile.libraryFiles) {
                var isSynthetic = !file.exists;
                inputUnits.add(
                  link2.LinkInputUnit(file.source, isSynthetic, file.parse()),
                );
              }

              inputLibraries.add(
                link2.LinkInputLibrary(librarySource, inputUnits),
              );
            }
            logger.writeln('Prepared ${inputLibraries.length} libraries.');
          });

          link2.LinkResult linkResult;
          logger.run('Link libraries', () {
            linkResult = link2.link(
              analysisContext.analysisOptions,
              analysisContext.sourceFactory,
              analysisContext.declaredVariables,
              inputBundles,
              inputLibraries,
            );
            logger.writeln('Linked ${inputLibraries.length} libraries.');
          });

          bytes = linkResult.bundle.toBuffer();
          byteStore.put(key, bytes);
          logger.writeln('Stored ${bytes.length} bytes.');
        } else {
          logger.writeln('Loaded ${bytes.length} bytes.');
        }

        inputBundles.add(
          LinkedNodeBundle.fromBuffer(bytes),
        );
      });
    }

    logger.run('Prepare linked bundles', () {
      var libraryCycle = targetLibrary.libraryCycle;
      loadBundle(libraryCycle);
    });

    var rootReference = Reference.root();
    rootReference.getChild('dart:core').getChild('dynamic').element =
        DynamicElementImpl.instance;
    rootReference.getChild('dart:core').getChild('Never').element =
        NeverElementImpl.instance;

    elementFactory = LinkedElementFactory(
      analysisContext,
      analysisSession,
      rootReference,
    );

    for (var bundle in inputBundles) {
      elementFactory.addBundle(
        LinkedBundleContext(elementFactory, bundle),
      );
    }

    var dartCore = elementFactory.libraryOfUri('dart:core');
    var dartAsync = elementFactory.libraryOfUri('dart:async');
    var typeProvider = SummaryTypeProvider()
      ..initializeCore(dartCore)
      ..initializeAsync(dartAsync);
    analysisContext.typeProvider = typeProvider;

    dartCore.createLoadLibraryFunction(typeProvider);
    dartAsync.createLoadLibraryFunction(typeProvider);
  }

  /// Return `true` if this context grew too large, and should be recreated.
  ///
  /// It might have been used to analyze libraries that we don't need anymore,
  /// and because loading libraries is not very expensive (but not free), the
  /// simplest way to get rid of the garbage is to throw away everything.
  bool pack() {
    return _linkedDataInBytes > _maxLinkedDataInBytes;
  }
}
