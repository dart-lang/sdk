// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/dart/element/element.dart' show CompilationUnitElement;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/frontend_resolution.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptions;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/kernel/resynthesize.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:kernel/ast.dart' as kernel;
import 'package:kernel/text/ast_to_text.dart' as kernel;

/**
 * Support for resynthesizing element model from Kernel.
 */
class KernelContext {
  static const DEBUG = false;

  /**
   * The [AnalysisContext] which is used to do the analysis.
   */
  final AnalysisContext analysisContext;

  /**
   * The resynthesizer that resynthesizes elements in [analysisContext].
   */
  final ElementResynthesizer resynthesizer;

  KernelContext._(this.analysisContext, this.resynthesizer);

  /**
   * Computes a [CompilationUnitElement] for the given library/unit pair.
   */
  CompilationUnitElement computeUnitElement(
      Source librarySource, Source unitSource) {
    String libraryUri = librarySource.uri.toString();
    String unitUri = unitSource.uri.toString();
    return resynthesizer.getElement(
        new ElementLocationImpl.con3(<String>[libraryUri, unitUri]));
  }

  /**
   * Cleans up any persistent resources used by this [KernelContext].
   *
   * Should be called once the [KernelContext] is no longer needed.
   */
  void dispose() {
    analysisContext.dispose();
  }

  /**
   * Return `true` if the given [uri] is known to be a library.
   */
  bool isLibraryUri(Uri uri) {
    // TODO(scheglov) implement
    return true;
//    String uriStr = uri.toString();
//    return store.unlinkedMap[uriStr]?.isPartOf == false;
  }

  /**
   * Create a [KernelContext] which is prepared to analyze [targetLibrary].
   */
  static Future<KernelContext> forSingleLibrary(
      FileState targetLibrary,
      PerformanceLog logger,
      AnalysisOptions analysisOptions,
      DeclaredVariables declaredVariables,
      SourceFactory sourceFactory,
      FileSystemState fsState,
      FrontEndCompiler compiler) async {
    return logger.runAsync('Create kernel context', () async {
      Uri targetUri = targetLibrary.uri;
      LibraryCompilationResult compilationResult =
          await compiler.compile(targetUri);

      // Remember Kernel libraries produced by the compiler.
      // There might be more libraries than we actually need.
      // This is probably OK, because we consume them lazily.
      var libraryMap = <String, kernel.Library>{};
      var libraryExistMap = <String, bool>{};
      for (var library in compilationResult.component.libraries) {
        String uriStr = library.importUri.toString();
        libraryMap[uriStr] = library;
        FileState file = fsState.getFileForUri(library.importUri);
        libraryExistMap[uriStr] = file?.exists ?? false;
      }

      if (DEBUG) {
        print('----------- ${targetLibrary.uriStr}');
        var libraryKernel = libraryMap[targetLibrary.uriStr];
        print(_getLibraryText(libraryKernel));
        print('--------------------------------------');
      }

      // Create and configure a new context.
      AnalysisContextImpl analysisContext =
          AnalysisEngine.instance.createAnalysisContext();
      analysisContext.useSdkCachePartition = false;
      analysisContext.analysisOptions = analysisOptions;
      analysisContext.declaredVariables.addAll(declaredVariables);
      analysisContext.sourceFactory = sourceFactory.clone();
      analysisContext.contentCache = new _ContentCacheWrapper(fsState);

      // Create the resynthesizer bound to the analysis context.
      var resynthesizer = new KernelResynthesizer(analysisContext,
          compilationResult.types, libraryMap, libraryExistMap);

      return new KernelContext._(analysisContext, resynthesizer);
    });
  }

  static String _getLibraryText(kernel.Library library) {
    StringBuffer buffer = new StringBuffer();
    new kernel.Printer(buffer, syntheticNames: new kernel.NameSystem())
        .writeLibraryFile(library);
    return buffer.toString();
  }
}

/**
 * [ContentCache] wrapper around [FileContentOverlay].
 */
class _ContentCacheWrapper implements ContentCache {
  final FileSystemState fsState;

  _ContentCacheWrapper(this.fsState);

  @override
  void accept(ContentCacheVisitor visitor) {
    throw new UnimplementedError();
  }

  @override
  String getContents(Source source) {
    return _getFileForSource(source).content;
  }

  @override
  bool getExists(Source source) {
    return _getFileForSource(source).exists;
  }

  @override
  int getModificationStamp(Source source) {
    return _getFileForSource(source).exists ? 0 : -1;
  }

  @override
  String setContents(Source source, String contents) {
    throw new UnimplementedError();
  }

  FileState _getFileForSource(Source source) {
    String path = source.fullName;
    return fsState.getFileForPath(path);
  }
}
