// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/dart/element/element.dart' show CompilationUnitElement;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/kernel_metadata.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptions;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/kernel/resynthesize.dart';
import 'package:front_end/byte_store.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/libraries_specification.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/ast.dart' as kernel;
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart' as kernel;
import 'package:package_config/packages.dart';
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart' as pathos;

/**
 * Create a new [KernelDriver] for the given configuration.
 */
KernelDriver createKernelDriver(
    PerformanceLog logger,
    ByteStore byteStore,
    AnalysisOptions analysisOptions,
    Folder sdkFolder,
    SourceFactory sourceFactory,
    FileSystemState fsState,
    pathos.Context pathContext) {
  // Prepare SDK libraries.
  Map<String, LibraryInfo> dartLibraries = {};
  {
    DartSdk dartSdk = sourceFactory.dartSdk;
    dartSdk.sdkLibraries.forEach((sdkLibrary) {
      var dartUri = sdkLibrary.shortName;
      var name = Uri.parse(dartUri).path;
      var path = dartSdk.mapDartUri(dartUri).fullName;
      var fileUri = pathContext.toUri(path);
      dartLibraries[name] = new LibraryInfo(name, fileUri, const []);
    });
  }

  // Prepare packages.
  Packages packages = Packages.noPackages;
  {
    Map<String, List<Folder>> packageMap = sourceFactory.packageMap;
    if (packageMap != null) {
      var map = <String, Uri>{};
      for (var name in packageMap.keys) {
        map[name] = packageMap[name].first.toUri();
      }
      packages = new MapPackages(map);
    }
  }

  // Try to find the SDK outline.
  // It is not used for unit testing, we compile SDK sources.
  // But for running shared tests we need the patched SDK.
  List<int> sdkOutlineBytes;
  if (sdkFolder != null) {
    try {
      sdkOutlineBytes = sdkFolder
          .getChildAssumingFile('vm_platform_strong.dill')
          .readAsBytesSync();
    } catch (_) {}
  }

  var uriTranslator = new UriTranslatorImpl(
      new TargetLibrariesSpecification('none', dartLibraries), packages);
  var options = new ProcessedOptions(new CompilerOptions()
    ..target = new _AnalysisTarget(
        new TargetFlags(strongMode: analysisOptions.strongMode))
    ..reportMessages = false
    ..logger = logger
    ..fileSystem = new _FileSystemAdaptor(fsState, pathContext)
    ..byteStore = byteStore);
  return new KernelDriver(options, uriTranslator,
      metadataFactory: new AnalyzerMetadataFactory(),
      sdkOutlineBytes: sdkOutlineBytes);
}

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
      KernelDriver driver) async {
    return logger.runAsync('Create kernel context', () async {
      Uri targetUri = targetLibrary.uri;
      KernelResult kernelResult = await driver.getKernel(targetUri);

      // Remember Kernel libraries required to resynthesize the target.
      var libraryMap = <String, kernel.Library>{};
      var libraryExistMap = <String, bool>{};
      for (var cycleResult in kernelResult.results) {
        for (var library in cycleResult.kernelLibraries) {
          String uriStr = library.importUri.toString();
          libraryMap[uriStr] = library;
          FileState file = fsState.getFileForUri(library.importUri);
          libraryExistMap[uriStr] = file?.exists ?? false;
        }
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
      var resynthesizer = new KernelResynthesizer(
          analysisContext, kernelResult.types, libraryMap, libraryExistMap);

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
 * [Target] for static analysis, with all features enabled.
 */
class _AnalysisTarget extends NoneTarget {
  _AnalysisTarget(TargetFlags flags) : super(flags);

  @override
  List<String> get extraRequiredLibraries => const <String>['dart:_internal'];

  @override
  bool enableNative(Uri uri) => true;
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

class _FileSystemAdaptor implements FileSystem {
  final FileSystemState fsState;
  final pathos.Context pathContext;

  _FileSystemAdaptor(this.fsState, this.pathContext);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.isScheme('file')) {
      var path = pathContext.fromUri(uri);
      var file = fsState.getFileForPath(path);
      return new _FileSystemEntityAdaptor(uri, file);
    } else {
      throw new ArgumentError(
          'Only file:// URIs are supported, but $uri is given.');
    }
  }
}

class _FileSystemEntityAdaptor implements FileSystemEntity {
  final Uri uri;
  final FileState file;

  _FileSystemEntityAdaptor(this.uri, this.file);

  @override
  Future<bool> exists() async {
    return file.exists;
  }

  @override
  Future<List<int>> readAsBytes() async {
    // TODO(scheglov) Optimize.
    return UTF8.encode(file.content);
  }

  @override
  Future<String> readAsString() async {
    return file.content;
  }
}
