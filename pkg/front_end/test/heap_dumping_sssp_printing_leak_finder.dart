import 'dart:async';
import 'dart:typed_data';

import 'package:heap_snapshot/analysis.dart';

import "vm_service_heap_helper.dart" as helper;
import "vm_service_helper.dart";

void _printShortestPath(DijkstrasAlgorithm d, Analysis analysis, int libId) {
  List<int> pathFromTarget = d.getPathToTarget(libId);
  for (int i = 0; i < pathFromTarget.length; i++) {
    int path = pathFromTarget[i];
    HeapSnapshotObject object = analysis.graph.objects[path];
    final HeapSnapshotClass klass = object.klass;
    bool isList =
        (klass.name == "_List" || klass.name == "_ImmutableList") &&
        (klass.libraryUri.scheme == 'dart' ||
            klass.libraryUri.toString() == '');

    String viaField = "";
    String extra = "";
    final Uint32List refs = object.references;
    final List<HeapSnapshotField> fs = klass.fields.toList()
      ..sort((HeapSnapshotField a, HeapSnapshotField b) => a.index - b.index);

    if (klass.libraryUri.toString() == "package:kernel/ast.dart") {
      if (klass.name == "Library") {
        HeapSnapshotObject? importUri = _getUriString(
          _getField(analysis, object, "importUri"),
          analysis,
        );
        if (_getDataOrNull(importUri) != null) {
          extra += " (importUri ${_getDataOrNull(importUri)})";
        }
      } else if (klass.name == "Class") {
        HeapSnapshotObject? className = _getField(analysis, object, "name");
        if (className != null) {
          extra = " (class '${className.data}')";
        }
        HeapSnapshotObject? fileUri = _getUriString(
          _getField(analysis, object, "fileUri"),
          analysis,
        );
        if (_getDataOrNull(fileUri) != null) {
          extra += " (fileUri ${_getDataOrNull(fileUri)})";
        }
      } else if (klass.name == "Procedure") {
        HeapSnapshotObject? procedureName = _getField(analysis, object, "name");
        if (procedureName != null) {
          procedureName = _getField(analysis, procedureName, "text");
        }
        if (_getDataOrNull(procedureName) != null) {
          extra = " (procedure '${_getDataOrNull(procedureName)}')";
        }
      }
    }

    if (i + 1 < pathFromTarget.length) {
      int next = pathFromTarget[i + 1];

      if (isList) {
        int maxFieldIndex = -1;
        if (fs.isNotEmpty) {
          maxFieldIndex = fs.last.index;
        }
        int length = refs.length - (maxFieldIndex + 1);
        for (int listIndex = 0; listIndex < length; ++listIndex) {
          if (refs[1 + maxFieldIndex + listIndex] == next) {
            viaField = "[$listIndex]";
            break;
          }
        }
      } else {
        for (final HeapSnapshotField field in fs) {
          final int fieldValueId = refs[field.index];
          if (fieldValueId == next) {
            viaField = ".${field.name}";
            break;
          }
        }
      }
    }

    print('${klass.name}$viaField$extra');
  }
}

String? _getDataOrNull(HeapSnapshotObject? object) {
  if (object == null) return null;
  dynamic data = object.data;
  if (data == null) return null;
  if (data is HeapSnapshotObjectNoData) return null;
  if (data is HeapSnapshotObjectNullData) return null;
  if (data is HeapSnapshotObjectLengthData) return null;
  return data.toString();
}

HeapSnapshotObject? _getField(
  Analysis analysis,
  HeapSnapshotObject object,
  String field,
) {
  final HeapSnapshotClass klass = object.klass;
  Iterable<HeapSnapshotField> fieldObjects = klass.fields.where(
    (HeapSnapshotField f) => f.name == field,
  );
  if (fieldObjects.length != 1) return null;
  return analysis.graph.objects[object.references[fieldObjects.single.index]];
}

HeapSnapshotObject? _getUriString(HeapSnapshotObject? uri, Analysis analysis) {
  if (uri != null) {
    if (uri.klass.name == "_SimpleUri") {
      uri = _getField(analysis, uri, "_uri");
    } else if (uri.klass.name == "_Uri") {
      uri = _getField(analysis, uri, "path");
    }
  }
  return uri;
}

DijkstrasAlgorithm _initializeDijkstrasAlgorithm(Analysis analysis) {
  Set<int> bad = <int>{};
  for (int i = 0; i < analysis.graph.objects.length; i++) {
    HeapSnapshotObject object = analysis.graph.objects[i];
    // "Root slice" has been seen to just point to the library we're looking for
    // but is fake somehow - and thus not a route we want to take.
    if (object.klass.name == "Root slice") {
      bad.add(i);
    }
  }
  print("Added ${bad.length} bad objects.");
  int largestBad = -1;
  for (int x in bad) {
    if (x > largestBad) largestBad = x;
  }

  return new DijkstrasAlgorithm(
    maxValue: analysis.graph.objects.length,
    roots: analysis.roots,
    outgoingFor: (int from) {
      return analysis.graph.objects[from].references;
    },
    distance: (int a, int b) {
      if (identical(a, b)) return 0;
      if ((a <= largestBad && bad.contains(a)) ||
          (b <= largestBad && bad.contains(b))) {
        return 1000;
      }
      // Assumed that it's connected.
      return 1;
    },
  );
}

class DijkstrasAlgorithm {
  Uint32List _dist;
  Uint32List _prev;

  new({
    required int maxValue,
    required Set<int> roots,
    required Iterable<int> outgoingFor(int item),
    required int Function(int, int) distance,
  }) : _dist = Uint32List(maxValue),
       _prev = Uint32List(maxValue) {
    MinHeap minHeap = new MinHeap(maxValue, getDistance);
    for (int root in roots) {
      setDistance(root, 0);
      minHeap.add(root);
    }

    while (minHeap.length > 0) {
      int u = minHeap.extractMin();
      int? distToU = getDistance(u)!;
      for (int v in outgoingFor(u)) {
        if (v < 0) throw "What for $u: $v";
        // Wikipedia says "only v that are still in Q" but it shouldn't matter
        // --- the length via u would be longer.
        int distanceUToV = distance(u, v);
        if (distanceUToV < 0) throw "Got negative distance. That's not allowed";
        int alt = distToU + distanceUToV;
        int? distToV = getDistance(v);
        if (distToV == null || alt < distToV) {
          minHeap.remove(v);

          setDistance(v, alt);
          setPrevious(v, u);
          minHeap.add(v);
        }
      }
    }
  }

  int? getDistance(int i) {
    int value = _dist[i] - 1;
    if (value < 0) return null;
    return value;
  }

  List<int> getPathToTarget(int target) {
    List<int> path = <int>[];
    path.add(target);
    int? prev = getPrevious(target);
    while (prev != null) {
      path.add(prev);
      prev = getPrevious(prev);
    }
    return path.reversed.toList();
  }

  int? getPrevious(int i) {
    int value = _prev[i] - 1;
    if (value < 0) return null;
    return value;
  }

  void setDistance(int i, int distance) {
    _dist[i] = distance + 1;
  }

  void setPrevious(int i, int previous) {
    _prev[i] = previous + 1;
  }
}

class HeapDumpingSsspPrintingLeakFinder
    extends helper.VMServiceHeapHelperSpecificExactLeakFinder {
  new({super.interests, super.prettyPrints, super.throwOnPossibleLeak});

  // Copied almost verbatim from
  // pkg/vm_service/test/common/service_test_common.dart
  Future<HeapSnapshotGraph> fetchHeapSnapshot() async {
    final completer = Completer<void>();
    late final StreamSubscription sub;
    final data = <ByteData>[];
    sub = serviceClient.onHeapSnapshotEvent.listen((event) async {
      data.add(event.data!);
      if (event.last == true) {
        await sub.cancel();
        await serviceClient.streamCancel(EventStreams.kHeapSnapshot);
        completer.complete();
      }
    });
    await serviceClient.streamListen(EventStreams.kHeapSnapshot);
    await serviceClient.requestHeapSnapshot(await getIsolateId());
    await completer.future;
    return HeapSnapshotGraph.fromChunks(data);
  }

  @override
  Future<void> leakDetected(
    String duplicate,
    int count,
    List<String> prettyPrints,
  ) async {
    await super.leakDetected(duplicate, count, prettyPrints);

    if (!duplicate.startsWith("Library[")) return;
    int? smallestId;
    for (String prettyPrint in prettyPrints) {
      const String lookingFor = 'libraryIdForTesting: "';
      int index = prettyPrint.indexOf(lookingFor);
      if (index < 0) return;
      String cutString = prettyPrint.substring(index + lookingFor.length);
      index = cutString.indexOf('"');
      if (index < 0) return;
      cutString = cutString.substring(0, index);
      int? asInt = int.tryParse(cutString);
      if (asInt == null) return;
      if (smallestId == null || asInt < smallestId) {
        smallestId = asInt;
      }
    }
    if (smallestId == null) return;

    print("Will try to find path to Library with id $smallestId");

    HeapSnapshotGraph heapSnapshot = await fetchHeapSnapshot();
    Analysis analysis = new Analysis(heapSnapshot);
    print("Getting closure of roots.");
    Set<int> all = analysis.transitiveGraph(analysis.roots);

    print("Filtering to kernels Library");
    int? kernelLibraryClassId;
    for (final HeapSnapshotClass klass in analysis.graph.classes) {
      if (klass.name == "Library" &&
          klass.libraryUri.toString() == "package:kernel/ast.dart") {
        kernelLibraryClassId = klass.classId;
      }
    }
    if (kernelLibraryClassId == null) throw "Didn't find kernels Library class";
    Set<int> libs = analysis.filter(all, (HeapSnapshotObject object) {
      return object.classId == kernelLibraryClassId;
    });
    print(" => Found ${libs.length} Library classes");

    print("Trying to initialize Dijkstra's algorithm");
    DijkstrasAlgorithm d = _initializeDijkstrasAlgorithm(analysis);

    for (int libId in libs) {
      HeapSnapshotObject lib = analysis.graph.objects[libId];
      final List<HeapSnapshotField> fs = lib.klass.fields.toList()
        ..sort((HeapSnapshotField a, HeapSnapshotField b) => a.index - b.index);

      for (final HeapSnapshotField field in fs) {
        if (field.name != "_libraryId") continue;
        final int valueId = lib.references[field.index];
        if (valueId == 0) continue;
        HeapSnapshotObject fieldData = analysis.graph.objects[valueId];
        dynamic unaltered = fieldData.data;
        if (unaltered is int && unaltered == smallestId) {
          print("Found lib $unaltered");
          print("--------");
          _printShortestPath(d, analysis, libId);
          print("--------");
        }
      }
    }
  }
}

class MinHeap {
  /// Setting this to true will enable (very) expensive asserts.
  static const bool debug = false;

  Uint32List _data;
  Uint32List _elementToIdx;
  int length = 0;
  int? Function(int) getDistance;

  new(int maxLength, this.getDistance)
    : _data = new Uint32List(maxLength),
      _elementToIdx = new Uint32List(maxLength);

  void add(int value) {
    _data[length] = value;
    _elementToIdx[value] = length + 1;
    _bubbleUp(length);
    length++;
    assert(!debug || isGoodForTesting());
  }

  int extractMin() {
    if (length == 0) throw "Empty";
    int returnMe = _data[0];
    _elementToIdx[returnMe] = 0;
    length--;
    if (length > 0) {
      int value = _data[0] = _data[length];
      _data[length] = 0;
      _elementToIdx[_data[0]] = 1;
      _bubbleDown(0, value, getDistance(value)!);
    }
    assert(!debug || isGoodForTesting());
    return returnMe;
  }

  bool isGoodForTesting() {
    Set<int> known = <int>{};
    for (int i = 0; i < length; i++) {
      int value = _data[i];
      known.add(value);
      int allegedIdx = _elementToIdx[value] - 1;
      if (allegedIdx != i) {
        return false;
      }

      int leftIndex = 2 * i + 1;
      if (leftIndex < length) {
        int valueLeft = _data[leftIndex];
        if (getDistance(value)! > getDistance(valueLeft)!) {
          return false;
        }

        int rightIndex = 2 * i + 2;
        if (rightIndex < length) {
          int valueRight = _data[rightIndex];
          if (getDistance(value)! > getDistance(valueRight)!) {
            return false;
          }
        }
      }
    }

    for (int i = 0; i < _elementToIdx.length; i++) {
      if (_elementToIdx[i] != 0 && !known.contains(i)) {
        return false;
      }
    }
    return true;
  }

  void remove(int valueToRemove) {
    int idx = _elementToIdx[valueToRemove] - 1;
    if (idx < 0) return;
    _elementToIdx[valueToRemove] = 0;
    length--;
    if (length > 0) {
      int value = _data[idx] = _data[length];
      _data[length] = 0;
      if (idx == length) return;
      _elementToIdx[_data[idx]] = idx + 1;

      if (!_bubbleUp(idx)) {
        _bubbleDown(idx, value, getDistance(value)!);
      }
    }
    assert(!debug || isGoodForTesting());
  }

  void _bubbleDown(int index, int value, int valueDistance) {
    if (index + 1 >= length) return;

    int leftIndex = 2 * index + 1;
    if (leftIndex >= length) return;
    int rightIndex = leftIndex + 1; // 2 * index + 2;

    int left = _data[leftIndex];
    int leftDistance = getDistance(left)!;

    int? right = rightIndex >= length ? null : _data[rightIndex];
    int? rightDistance = right == null ? null : getDistance(right)!;

    if (valueDistance <= leftDistance &&
        (rightDistance == null || leftDistance <= rightDistance)) {
      return;
    }
    if (rightDistance != null &&
        rightDistance <= leftDistance &&
        valueDistance <= rightDistance) {
      return;
    }

    if (valueDistance > leftDistance &&
        (rightDistance == null || leftDistance < rightDistance)) {
      // Go left.
      _data[index] = left;
      _elementToIdx[left] = index + 1;
      _data[leftIndex] = value;
      _elementToIdx[value] = leftIndex + 1;
      _bubbleDown(leftIndex, value, valueDistance);
    } else {
      // Go right.
      _data[index] = right!;
      _elementToIdx[right] = index + 1;
      _data[rightIndex] = value;
      _elementToIdx[value] = rightIndex + 1;
      _bubbleDown(rightIndex, value, valueDistance);
    }
  }

  /// Bubble up and returns if it moved the data.
  bool _bubbleUp(int index) {
    if (index == 0) return false;
    int value = _data[index];
    int valueDistance = getDistance(value)!;
    int parentIndex = (index - 1) ~/ 2;
    int parentValue = _data[parentIndex];
    int parentValueDistance = getDistance(_data[parentIndex])!;
    if (parentValueDistance > valueDistance) {
      _data[parentIndex] = value;
      _elementToIdx[value] = parentIndex + 1;
      _data[index] = parentValue;
      _elementToIdx[parentValue] = index + 1;
      _bubbleUp(parentIndex);
      return true;
    }
    return false;
  }
}
