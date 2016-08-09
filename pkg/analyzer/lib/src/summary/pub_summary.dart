// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core' hide Resource;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show ResynthesizerResultProvider;
import 'package:analyzer/src/summary/summarize_ast.dart'
    show serializeAstUnlinked;
import 'package:analyzer/src/summary/summarize_elements.dart'
    show PackageBundleAssembler;
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:path/path.dart' as pathos;

/**
 * A package in the pub cache.
 */
class PubPackage {
  final String name;
  final Folder libFolder;

  PubPackage(this.name, this.libFolder);

  Folder get folder => libFolder.parent;

  @override
  int get hashCode => libFolder.hashCode;

  @override
  bool operator ==(other) {
    return other is PubPackage && other.libFolder == libFolder;
  }

  @override
  String toString() => '($name in $folder)';
}

/**
 * Class that manages summaries for pub packages.
 *
 * The client should call [getLinkedBundles] after creating a new
 * [AnalysisContext] and configuring its source factory, but before computing
 * any analysis results.  The returned linked bundles can be used to create and
 * configure [ResynthesizerResultProvider] for the context.
 */
class PubSummaryManager {
  static const UNLINKED_BUNDLE_FILE_NAME = 'unlinked.ds';

  final ResourceProvider resourceProvider;

  /**
   * The name of the temporary file that is used for atomic writes.
   */
  final String tempFileName;

  /**
   * The map from [PubPackage]s to their unlinked [PackageBundle]s in the pub
   * cache.
   */
  final Map<PubPackage, PackageBundle> unlinkedBundleMap =
      new HashMap<PubPackage, PackageBundle>();

  /**
   * The set of packages to compute unlinked summaries for.
   */
  final Set<PubPackage> packagesToComputeUnlinked = new Set<PubPackage>();

  /**
   * The set of already processed packages, which we have already checked
   * for their unlinked bundle existence, or scheduled its computing.
   */
  final Set<PubPackage> seenPackages = new Set<PubPackage>();

  /**
   * The [Completer] that completes when computing of all scheduled unlinked
   * bundles is complete.
   */
  Completer _onUnlinkedCompleteCompleter;

  PubSummaryManager(this.resourceProvider, this.tempFileName);

  /**
   * The [Future] that completes when computing of all scheduled unlinked
   * bundles is complete.
   */
  Future get onUnlinkedComplete {
    if (packagesToComputeUnlinked.isEmpty) {
      return new Future.value();
    }
    _onUnlinkedCompleteCompleter ??= new Completer();
    return _onUnlinkedCompleteCompleter.future;
  }

  /**
   * Return the [pathos.Context] corresponding to the [resourceProvider].
   */
  pathos.Context get pathContext => resourceProvider.pathContext;

  /**
   * Return the list of linked [PackageBundle]s that can be provided at this
   * time for a subset of the packages used by the given [context].  If
   * information about some of the used packages is not available yet, schedule
   * its computation, so that it might be available later for other contexts
   * referencing the same packages.
   */
  List<PackageBundle> getLinkedBundles(AnalysisContext context) {
    Map<String, PackageBundle> unlinkedBundles = getUnlinkedBundles(context);
    // TODO(scheglov) actually compute available linked bundles
    return <PackageBundle>[];
  }

  /**
   * Return all available unlinked [PackageBundle]s for the given [context],
   * maybe an empty list, but not `null`.
   */
  Map<String, PackageBundle> getUnlinkedBundles(AnalysisContext context) {
    Map<String, PackageBundle> unlinkedBundles =
        new HashMap<String, PackageBundle>();
    Map<String, List<Folder>> packageMap = context.sourceFactory.packageMap;
    if (packageMap != null) {
      packageMap.forEach((String packageName, List<Folder> libFolders) {
        if (libFolders.length == 1) {
          Folder libFolder = libFolders.first;
          if (isPathInPubCache(pathContext, libFolder.path)) {
            PubPackage package = new PubPackage(packageName, libFolder);
            PackageBundle unlinkedBundle = _getUnlinkedOrSchedule(package);
            if (unlinkedBundle != null) {
              unlinkedBundles[packageName] = unlinkedBundle;
            }
          }
        }
      });
    }
    return unlinkedBundles;
  }

  /**
   * Compute unlinked bundle for a package from [packagesToComputeUnlinked],
   * and schedule delayed computation for the next package, if any.
   */
  void _computeNextUnlinked() {
    if (packagesToComputeUnlinked.isNotEmpty) {
      PubPackage package = packagesToComputeUnlinked.first;
      _computeUnlinked(package);
      packagesToComputeUnlinked.remove(package);
      _scheduleNextUnlinked();
    } else {
      if (_onUnlinkedCompleteCompleter != null) {
        _onUnlinkedCompleteCompleter.complete(true);
        _onUnlinkedCompleteCompleter = null;
      }
    }
  }

  /**
   * Compute the unlinked bundle for the package with the given path, put
   * it in the [unlinkedBundleMap] and store into the [resourceProvider].
   *
   * TODO(scheglov) Consider moving into separate isolate(s).
   */
  void _computeUnlinked(PubPackage package) {
    Folder libFolder = package.libFolder;
    String libPath = libFolder.path + pathContext.separator;
    PackageBundleAssembler assembler = new PackageBundleAssembler();

    /**
     * Return the `package` [Uri] for the given [path] in the `lib` folder
     * of the current package.
     */
    Uri getUri(String path) {
      String pathInLib = path.substring(libPath.length);
      String uriPath = pathos.posix.joinAll(pathContext.split(pathInLib));
      String uriStr = 'package:${package.name}/$uriPath';
      return FastUri.parse(uriStr);
    }

    /**
     * If the given [file] is a Dart file, add its unlinked unit.
     */
    void addDartFile(File file) {
      String path = file.path;
      if (AnalysisEngine.isDartFileName(path)) {
        Uri uri = getUri(path);
        Source source = file.createSource(uri);
        CompilationUnit unit = _parse(source);
        UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
        assembler.addUnlinkedUnit(source, unlinkedUnit);
      }
    }

    /**
     * Visit the [folder] recursively.
     */
    void addDartFiles(Folder folder) {
      List<Resource> children = folder.getChildren();
      for (Resource child in children) {
        if (child is File) {
          addDartFile(child);
        }
      }
      for (Resource child in children) {
        if (child is Folder) {
          addDartFiles(child);
        }
      }
    }

    try {
      addDartFiles(libFolder);
      List<int> bytes = assembler.assemble().toBuffer();
      _writeAtomic(package.folder, UNLINKED_BUNDLE_FILE_NAME, bytes);
    } on FileSystemException {
      // Ignore file system exceptions.
    }
  }

  /**
   * Return the unlinked [PackageBundle] for the given [package]. If the bundle
   * has not been compute yet, return `null` and schedule its computation.
   */
  PackageBundle _getUnlinkedOrSchedule(PubPackage package) {
    // Try to find in the cache.
    PackageBundle bundle = unlinkedBundleMap[package];
    if (bundle != null) {
      return bundle;
    }
    // Try to read from the file system.
    File unlinkedFile =
        package.folder.getChildAssumingFile(UNLINKED_BUNDLE_FILE_NAME);
    if (unlinkedFile.exists) {
      try {
        List<int> bytes = unlinkedFile.readAsBytesSync();
        bundle = new PackageBundle.fromBuffer(bytes);
        unlinkedBundleMap[package] = bundle;
        return bundle;
      } on FileSystemException {
        // Ignore file system exceptions.
      }
    }
    // Schedule computation in the background.
    if (package != null && seenPackages.add(package)) {
      if (packagesToComputeUnlinked.isEmpty) {
        _scheduleNextUnlinked();
      }
      packagesToComputeUnlinked.add(package);
    }
    // The bundle is for available.
    return null;
  }

  /**
   * Parse the given [source] into AST.
   */
  CompilationUnit _parse(Source source) {
    String code = source.contents.data;
    AnalysisErrorListener errorListener = AnalysisErrorListener.NULL_LISTENER;
    CharSequenceReader reader = new CharSequenceReader(code);
    Scanner scanner = new Scanner(source, reader, errorListener);
    Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);
    Parser parser = new Parser(source, errorListener);
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    return unit;
  }

  /**
   * Schedule delayed computation of the next package unlinked bundle from the
   * set of [packagesToComputeUnlinked].  We delay each computation because we
   * want operations in analysis server to proceed, and computing bundles of
   * packages is a background task.
   */
  void _scheduleNextUnlinked() {
    new Future.delayed(new Duration(milliseconds: 10), _computeNextUnlinked);
  }

  /**
   * Atomically write the given [bytes] into the file in the [folder].
   */
  void _writeAtomic(Folder folder, String fileName, List<int> bytes) {
    String filePath = folder.getChildAssumingFile(fileName).path;
    File tempFile = folder.getChildAssumingFile(tempFileName);
    tempFile.writeAsBytesSync(bytes);
    tempFile.renameSync(filePath);
  }

  /**
   * Return `true` if the given absolute [path] is in the pub cache.
   */
  static bool isPathInPubCache(pathos.Context pathContext, String path) {
    List<String> parts = pathContext.split(path);
    for (int i = 0; i < parts.length - 1; i++) {
      if (parts[i] == '.pub-cache') {
        return true;
      }
      if (parts[i] == 'Pub' && parts[i + 1] == 'Cache') {
        return true;
      }
    }
    return false;
  }
}
