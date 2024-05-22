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
import 'package:analyzer_utilities/package_root.dart';
import 'package:args/args.dart';
import 'package:heap_snapshot/analysis.dart';
import 'package:heap_snapshot/format.dart';
import 'package:path/path.dart';
import 'package:vm_service/vm_service.dart';

import 'result.dart';

void main(List<String> arguments) async {
  var argParser = ArgParser()..addFlag('write-file');
  var argResults = argParser.parse(arguments);

  var byteStore = MemoryByteStore();

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
  var heapBytes = await _withNewAnalysisContext(
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

  var allResults = _analyzeSnapshot(heapBytes);
  _printResults(allResults);

  if (argResults['write-file'] == true) {
    _writeResultFile(allResults);
  }
}

const String includedPath = '/Users/scheglov/dart/flutter_elements/packages';

final Stopwatch timer = Stopwatch();

String get _resultFilePath {
  return posix.join(
    packageRoot,
    'analyzer',
    'tool',
    'benchmark',
    'heap',
    'flutter_elements.xml',
  );
}

/// Analyzes all included files.
///
/// Throws if there is a compile-time error.
Future<void> _analyzeFiles(
  AnalysisContextCollectionImpl collection,
) async {
  for (var analysisContext in collection.contexts) {
    var analyzedFiles = analysisContext.contextRoot.analyzedFiles().toList();
    for (var filePath in analyzedFiles) {
      if (filePath.endsWith('.dart')) {
        var analysisSession = analysisContext.currentSession;
        await analysisSession.getUnitElement(filePath);

        // Check that there are no compile-time errors.
        // We want to be sure that we get elements models.
        var errorsResult = await analysisSession.getErrors(filePath);
        if (errorsResult is ErrorsResult) {
          var errors = errorsResult.errors
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
  var allResults = BenchmarkResultCompound(
    name: 'flutter_elements',
  );

  timer.reset();
  var graph = HeapSnapshotGraph.fromChunks(
      [bytes.buffer.asByteData(bytes.offsetInBytes, bytes.length)]);
  print('[+${timer.elapsedMilliseconds} ms] Create HeapSnapshotGraph');

  var analysis = Analysis(graph);

  // Computing reachable objects takes some time.
  timer.reset();
  analysis.reachableObjects;
  print('[+${timer.elapsedMilliseconds} ms] Compute reachable objects');
  print('');
  {
    var measure = analysis.measureObjects(analysis.reachableObjects);
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
    print('Reachable objects');
    var objects = analysis.reachableObjects;
    analysis.printObjectStats(objects, maxLines: 100);
  }

  timer.reset();

  allResults.add(
    _doUniqueUriStr(analysis),
  );

  allResults.add(
    _doInterfaceType(analysis),
  );

  allResults.add(
    _doLinkedData(analysis),
  );

  print('[+${timer.elapsedMilliseconds} ms] Compute benchmark results');
  print('');

  return allResults;
}

BenchmarkResult _doInterfaceType(Analysis analysis) {
  var objects = analysis.filterByClass(
    analysis.reachableObjects,
    libraryUri: Uri.parse('package:analyzer/src/dart/element/type.dart'),
    name: 'InterfaceTypeImpl',
  );

  var measure = analysis.measureObjects(objects);
  return BenchmarkResultCompound(name: 'InterfaceTypeImpl', children: [
    BenchmarkResultCount(
      name: 'count',
      value: measure.count,
    ),
    BenchmarkResultBytes(
      name: 'size(shallow)',
      value: measure.size,
    ),
  ]);
}

BenchmarkResult _doLinkedData(Analysis analysis) {
  var readerUri = Uri.parse(
    'package:analyzer/src/summary2/bundle_reader.dart',
  );

  var classSet = analysis.classByPredicate((e) {
    return e.libraryUri == readerUri && e.name.endsWith('LinkedData');
  });

  var objects = analysis.filterByClassId(analysis.reachableObjects, classSet);

  var measure = analysis.measureObjects(objects);
  return BenchmarkResultCompound(name: 'LinkedData', children: [
    BenchmarkResultCount(
      name: 'count',
      value: measure.count,
    ),
  ]);
}

BenchmarkResult _doUniqueUriStr(Analysis analysis) {
  var uriList = analysis.filterByClass(analysis.reachableObjects,
      libraryUri: Uri.parse('dart:core'), name: '_SimpleUri');

  var uriStringList = analysis.findReferences(uriList, [':_uri']);
  var uniqueUriStrSet = <String>{};
  var duplicateUriStrList = <String>[];
  for (var objectId in uriStringList) {
    var object = analysis.graph.objects[objectId];
    var uriStr = object.data as String;
    if (!uniqueUriStrSet.add(uriStr)) {
      duplicateUriStrList.add(uriStr);
    }
  }

  var uriListMeasure = analysis.measureObjects(uriList);
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
  for (var analysisContext in collection.contexts) {
    var analysisDriver = analysisContext.driver;
    await analysisDriver.discoverAvailableFiles();
    var knownFiles = analysisDriver.fsState.knownFiles.toList();
    for (var file in knownFiles) {
      // Skip libraries with known invalid types.
      // if (const {'dart:html', 'dart:ui_web', 'dart:_interceptors'}
      //     .contains(file.uriStr)) {
      //   continue;
      // }
      var result = await analysisDriver.getLibraryByUri(file.uriStr);
      if (result is LibraryElementResult) {
        result.element.accept(_AllElementVisitor());
      }
    }
  }
}

Uint8List _getHeapSnapshot() {
  timer.reset();
  var tmpDir = io.Directory.systemTemp.createTempSync('analyzer_heap');
  try {
    var snapshotFile = io.File('${tmpDir.path}/0.heap_snapshot');
    developer.NativeRuntime.writeHeapSnapshotToFile(snapshotFile.path);
    print('[+${timer.elapsedMilliseconds} ms] Write heap snapshot');

    timer.reset();
    var bytes = snapshotFile.readAsBytesSync();
    print(
      '[+${timer.elapsedMilliseconds} ms] '
      'Read heap snapshot, ${bytes.length ~/ (1024 * 1024)} MB',
    );
    return bytes;
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

void _printResults(BenchmarkResultCompound allResults) {
  BenchmarkResult? baseResult;
  try {
    var text = io.File(_resultFilePath).readAsStringSync();
    baseResult = BenchmarkResult.fromXmlText(text);
  } catch (e) {
    // ignore
  }

  print('All results');
  print('-' * 32);
  print(allResults.asDisplayText(baseResult));
}

Future<T> _withNewAnalysisContext<T>(
  Future<T> Function(AnalysisContextCollectionImpl collection) f, {
  required ByteStore byteStore,
}) async {
  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var fileContentCache = FileContentCache(resourceProvider);
  var unlinkedUnitStore = UnlinkedUnitStoreImpl();
  var collection = AnalysisContextCollectionImpl(
    byteStore: byteStore,
    resourceProvider: resourceProvider,
    fileContentCache: fileContentCache,
    includedPaths: [includedPath],
    unlinkedUnitStore: unlinkedUnitStore,
  );
  var result = await f(collection);
  collection.hashCode; // to keep it alive
  return result;
}

void _writeResultFile(BenchmarkResultCompound result) {
  io.File(_resultFilePath).writeAsStringSync(result.asXmlText, flush: true);
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
  IntSet classByPredicate(bool Function(HeapSnapshotClass) predicate) {
    var allClasses = graph.classes;
    var classSet = SpecializedIntSet(allClasses.length);
    for (var class_ in allClasses) {
      if (predicate(class_)) {
        classSet.add(class_.classId);
      }
    }
    return classSet;
  }

  IntSet filterByClass(
    IntSet objectIds, {
    required Uri libraryUri,
    required String name,
  }) {
    var cid = graph.classes.singleWhere((class_) {
      return class_.libraryUri == libraryUri && class_.name == name;
    }).classId;
    return filter(objectIds, (object) => object.classId == cid);
  }

  _ObjectSetMeasure measureObjects(IntSet objectIds) {
    var stats = generateObjectStats(objectIds);
    var totalSize = 0;
    var totalCount = 0;
    for (var class_ in stats.classes) {
      totalCount += stats.counts[class_.classId];
      totalSize += stats.sizes[class_.classId];
    }
    return _ObjectSetMeasure(count: totalCount, size: totalSize);
  }

  void printObjectStats(IntSet objectIds, {int maxLines = 20}) {
    var stats = generateObjectStats(objectIds);
    print(formatHeapStats(stats, maxLines: maxLines));
    print('');
  }

  // ignore: unused_element
  void printRetainers(
    IntSet objectIds, {
    int maxEntries = 3,
  }) {
    var paths = retainingPathsOf(objectIds, 20);
    for (int i = 0; i < paths.length; ++i) {
      if (i >= maxEntries) break;
      var path = paths[i];
      print('There are ${path.count} retaining paths of');
      print(formatRetainingPath(graph, paths[i]));
      print('');
    }
  }
}
