import 'dart:async';
import 'dart:io';

import 'heap_dumping_sssp_printing_leak_finder.dart';
import "vm_service_heap_helper.dart" as helper;

Future<void> main() async {
  testMinHeap();
  testDijkstrasAlgorithm();
  await testHeapDumpingSsspPrintingLeakFinder();
}

const bool debug = false;

void testDijkstrasAlgorithm() {
  DijkstrasAlgorithm sssp = new DijkstrasAlgorithm(
    maxValue: 6,
    roots: {0},
    outgoingFor: (from) {
      switch (from) {
        case 0:
          return const [1, 2, 4];
        case 1:
          return const [2];
        case 2:
          return const [3, 4, 5];
        case 3:
          return const [];
        case 4:
          return const [3];
        case 5:
          return const [4];
        default:
          throw "Unexpected from $from";
      }
    },
    distance: (a, b) => 1,
  );
  String answer = sssp.getPathToTarget(3).join(", ");
  if (answer != "0, 4, 3") throw "Got bad answer $answer";

  sssp = new DijkstrasAlgorithm(
    maxValue: 6,
    roots: {0},
    outgoingFor: (from) {
      switch (from) {
        case 0:
          return const [1, 2, 4];
        case 1:
          return const [2, 3];
        case 2:
          return const [3, 4, 5];
        case 3:
          return const [];
        case 4:
          return const [5];
        case 5:
          return const [3];
        default:
          throw "Unexpected from $from";
      }
    },
    distance: (a, b) => 1,
  );
  answer = sssp.getPathToTarget(3).join(", ");
  if (answer != "0, 1, 3" && answer != "0, 2, 3") {
    throw "Got bad answer $answer";
  }
}

Future<void> testHeapDumpingSsspPrintingLeakFinder() async {
  List<String> logs = [];
  ZoneSpecification specification = new ZoneSpecification(
    print: (_, _, _, String line) {
      if (debug) stdout.writeln("From inside zone: $line");
      logs.add(line);
    },
  );
  await runZoned(() async {
    HeapDumpingSsspPrintingLeakFinder heapHelper =
        new HeapDumpingSsspPrintingLeakFinder(
          interests: [
            new helper.Interest(
              Uri.parse("package:kernel/ast.dart"),
              "Library",
              ["fileUri"],
              expectToAlwaysFind: true,
            ),
          ],
          prettyPrints: [
            new helper.Interest(
              Uri.parse("package:kernel/ast.dart"),
              "Library",
              ["fileUri", "libraryIdForTesting"],
              expectToAlwaysFind: true,
            ),
          ],
          throwOnPossibleLeak: false,
        );

    await heapHelper.start([
      "--enable-asserts",
      Platform.script
          .resolve("heap_dumping_sssp_printing_leak_finder_test_helper.dart")
          .toString(),
    ]);
    int exitCode = await heapHelper.process.exitCode;
    print("Exited with exit code $exitCode");
  }, zoneSpecification: specification);

  String log = logs.join("\n");
  if (!log.contains("Will try to find path to Library with id 1")) {
    throw "Didn't find expected line in \n\n$log";
  }
  if (!log.contains("Found 2 Library classes")) {
    throw "Didn't find expected line in \n\n$log";
  }
  if (!log.contains("Found lib 1")) {
    throw "Didn't find expected line in \n\n$log";
  }
  if (!log.contains("Foo.leakViaField\nLibrary (importUri foo:bar/baz.dart)")) {
    throw "Didn't find expected line in \n\n$log";
  }
}

void testMinHeap() {
  int count = 0;
  _allOrderings(0, 7, {}, true, (List<int> ordering) {
    count++;
    List<int> allNumbers = _testExtractMin(
      _createHeapFromList(ordering),
      ordering,
    );
    for (int num in allNumbers) {
      MinHeap heap = _createHeapFromList(ordering);
      heap.remove(num);
      heap.isGoodForTesting() || (throw "Bad after remove $num with $ordering");
    }
  });
  print("Tested $count permutations");
}

void _allOrderings(
  int from,
  int to,
  Set<int> picks,
  bool includeNotFull,
  void Function(List<int>) onPick,
) {
  int total = to - from + 1;
  for (int i = from; i <= to; i++) {
    if (picks.contains(i)) continue;
    picks.add(i);
    if (picks.length == total || includeNotFull) {
      onPick(picks.toList());
    }
    if (picks.length < total) {
      _allOrderings(from, to, picks, includeNotFull, onPick);
    }
    picks.remove(i);
  }
}

MinHeap _createHeapFromList(List<int> ordering) {
  MinHeap heap = new MinHeap(32, (int i) => i);
  for (int i in ordering) {
    heap.add(i);
  }
  return heap;
}

List<int> _testExtractMin(MinHeap heap, List<int> orderingForDebugging) {
  int prev = -1;
  List<int> result = [];
  while (heap.length > 0) {
    int element = heap.extractMin();
    if (element < prev) throw "Bad";
    heap.isGoodForTesting() ||
        (throw "Bad extracting min $element with $orderingForDebugging");
    result.add(element);
  }
  return result;
}
