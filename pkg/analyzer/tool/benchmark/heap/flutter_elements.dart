// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer' as developer;
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:heap_snapshot/analysis.dart';
import 'package:heap_snapshot/format.dart';
import 'package:vm_service/vm_service.dart';

import '../../../test/util/tree_string_sink.dart';
import 'result.dart';

void main() async {
  final byteStore = MemoryByteStore();

  print('First pass, fill ByteStore');
  await _withNewAnalysisContext<void>(
    byteStore: byteStore,
    (collection) async {
      print('  Analysis contexts: ${collection.contexts.length}');

      timer.start();
      await _analyzeFiles(collection);
      print('  [+${timer.elapsedMilliseconds} ms] Analyze');

      timer.reset();
      await _getAvailableLibraries(collection);
      print('  [+${timer.elapsedMilliseconds} ms] Get available libraries');
      print('');
    },
  );

  timer.reset();
  print('Second pass, read elements');
  final heapBytes = await _withNewAnalysisContext(
    byteStore: byteStore,
    (collection) async {
      print('  Analysis contexts: ${collection.contexts.length}');

      await _analyzeFiles(collection);
      print('  [+${timer.elapsedMilliseconds} ms] Analyze');

      timer.reset();
      await _getAvailableLibraries(collection);
      print('  [+${timer.elapsedMilliseconds} ms] Get available libraries');
      print('');

      return _getHeapSnapshot();
    },
  );

  final allResults = _analyzeSnapshot(heapBytes);

  {
    final buffer = StringBuffer();
    final sink = TreeStringSink(sink: buffer, indent: '');
    writeBenchmarkResult(sink, allResults);
    print('All results');
    print('-' * 32);
    print(buffer);
  }
}

const String includedPath = '/Users/scheglov/dart/flutter_multi/packages';

final Stopwatch timer = Stopwatch();

/// Analyzes all included files.
///
/// Throws if there is a compile-time error.
Future<void> _analyzeFiles(
  AnalysisContextCollectionImpl collection,
) async {
  for (final analysisContext in collection.contexts) {
    final analyzedFiles = analysisContext.contextRoot.analyzedFiles().toList();
    for (final filePath in analyzedFiles) {
      if (filePath.endsWith('.dart')) {
        final analysisSession = analysisContext.currentSession;
        await analysisSession.getUnitElement(filePath);

        // Check that there are no compile-time errors.
        // We want to be sure that we get elements models.
        final errorsResult = await analysisSession.getErrors(filePath);
        if (errorsResult is ErrorsResult) {
          final errors = errorsResult.errors
              .where((element) =>
                  element.errorCode.type == ErrorType.COMPILE_TIME_ERROR)
              .toList();
          if (errors.isNotEmpty) {
            throw StateError('Errors in $filePath\n$errors');
          }
        }
      }
    }
  }
}

BenchmarkResultCompound _analyzeSnapshot(Uint8List bytes) {
  final allResults = BenchmarkResultCompound(
    name: 'flutter_elements',
  );

  timer.reset();
  final graph = HeapSnapshotGraph.fromChunks(
      [bytes.buffer.asByteData(bytes.offsetInBytes, bytes.length)]);
  print('[+${timer.elapsedMilliseconds} ms] Create HeapSnapshotGraph');

  final analysis = Analysis(graph);

  // Computing reachable objects takes some time.
  timer.reset();
  analysis.reachableObjects;
  print('[+${timer.elapsedMilliseconds} ms] Compute reachable objects');
  print('');
  {
    final measure = analysis.measureObjects(analysis.reachableObjects);
    allResults.add(
      BenchmarkResultCompound(name: 'reachableObjects', children: [
        BenchmarkResultCount(
          name: 'count',
          value: measure.count,
        ),
        BenchmarkResultBytes(
          name: 'size',
          value: measure.size,
        ),
      ]),
    );
  }

  // It is interesting to see all reachable objects.
  {
    timer.reset();
    print('Reachable objects');
    final objects = analysis.reachableObjects;
    analysis.printObjectStats(objects, maxLines: 100);
    print('');
  }

  allResults.add(
    _doUniqueUriStr(analysis),
  );

  return allResults;
}

BenchmarkResult _doUniqueUriStr(Analysis analysis) {
  print('Instances of: _SimpleUri');
  final uriList = analysis.filterByClass(analysis.reachableObjects,
      libraryUri: Uri.parse('dart:core'), name: '_SimpleUri');
  analysis.printObjectStats(uriList);
  print('');

  final uriStringList = analysis.findReferences(uriList, [':_uri']);

  final uniqueUriStrSet = <String>{};
  final duplicateUriStrList = <String>[];
  for (final objectId in uriStringList) {
    final object = analysis.graph.objects[objectId];
    final uriStr = object.data as String;
    if (!uniqueUriStrSet.add(uriStr)) {
      duplicateUriStrList.add(uriStr);
    }
  }
  print('');

  final uriListMeasure = analysis.measureObjects(uriList);
  return BenchmarkResultCompound(name: '_SimpleUri', children: [
    BenchmarkResultCount(
      name: 'count',
      value: uriListMeasure.count,
    ),
    BenchmarkResultBytes(
      name: 'size(shallow)',
      value: uriListMeasure.size,
    ),
    BenchmarkResultCount(
      name: 'duplicateCount',
      value: duplicateUriStrList.length,
    ),
  ]);
}

/// Loads all libraries available in the analysis contexts, and deserializes
/// every element in them.
Future<void> _getAvailableLibraries(
  AnalysisContextCollectionImpl collection,
) async {
  for (final analysisContext in collection.contexts) {
    final analysisDriver = analysisContext.driver;
    await analysisDriver.discoverAvailableFiles();
    final knownFiles = analysisDriver.fsState.knownFiles.toList();
    for (final file in knownFiles) {
      // Skip libraries with known invalid types.
      // if (const {'dart:html', 'dart:ui_web', 'dart:_interceptors'}
      //     .contains(file.uriStr)) {
      //   continue;
      // }
      final result = await analysisDriver.getLibraryByUri(file.uriStr);
      if (result is LibraryElementResult) {
        result.element.accept(_AllElementVisitor());
      }
    }
  }
}

Uint8List _getHeapSnapshot() {
  timer.reset();
  final tmpDir = io.Directory.systemTemp.createTempSync('analyzer_heap');
  try {
    final snapshotFile = io.File('${tmpDir.path}/0.heap_snapshot');
    developer.NativeRuntime.writeHeapSnapshotToFile(snapshotFile.path);
    print('[+${timer.elapsedMilliseconds} ms] Write heap snapshot');

    timer.reset();
    final bytes = snapshotFile.readAsBytesSync();
    print(
      '[+${timer.elapsedMilliseconds} ms] '
      'Read heap snapshot, ${bytes.length ~/ (1024 * 1024)} MB',
    );
    return bytes;
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

Future<T> _withNewAnalysisContext<T>(
  Future<T> Function(AnalysisContextCollectionImpl collection) f, {
  required ByteStore byteStore,
}) async {
  final resourceProvider = PhysicalResourceProvider.INSTANCE;
  final fileContentCache = FileContentCache(resourceProvider);
  final unlinkedUnitStore = UnlinkedUnitStoreImpl();
  final collection = AnalysisContextCollectionImpl(
    byteStore: byteStore,
    resourceProvider: resourceProvider,
    fileContentCache: fileContentCache,
    includedPaths: [includedPath],
    unlinkedUnitStore: unlinkedUnitStore,
  );
  final result = await f(collection);
  collection.hashCode; // to keep it alive
  return result;
}

class _AllElementVisitor extends GeneralizingElementVisitor<void> {
  @override
  void visitElement(Element element) {
    // This triggers lazy reading.
    element.metadata;
    super.visitElement(element);
  }
}

class _ObjectSetMeasure {
  final int count;
  final int size;

  _ObjectSetMeasure({required this.count, required this.size});
}

extension on Analysis {
  IntSet filterByClass(
    IntSet objectIds, {
    required Uri libraryUri,
    required String name,
  }) {
    final cid = graph.classes.singleWhere((class_) {
      return class_.libraryUri == libraryUri && class_.name == name;
    }).classId;
    return filter(objectIds, (object) => object.classId == cid);
  }

  _ObjectSetMeasure measureObjects(IntSet objectIds) {
    final stats = generateObjectStats(objectIds);
    var totalSize = 0;
    var totalCount = 0;
    for (final class_ in stats.classes) {
      totalCount += stats.counts[class_.classId];
      totalSize += stats.sizes[class_.classId];
    }
    return _ObjectSetMeasure(count: totalCount, size: totalSize);
  }

  void printObjectStats(IntSet objectIds, {int maxLines = 20}) {
    final stats = generateObjectStats(objectIds);
    print(formatHeapStats(stats, maxLines: maxLines));
    print('');
  }

  // ignore: unused_element
  void printRetainers(
    IntSet objectIds, {
    int maxEntries = 3,
  }) {
    final paths = retainingPathsOf(objectIds, 20);
    for (int i = 0; i < paths.length; ++i) {
      if (i >= maxEntries) break;
      final path = paths[i];
      print('There are ${path.count} retaining paths of');
      print(formatRetainingPath(graph, paths[i]));
      print('');
    }
  }
}
