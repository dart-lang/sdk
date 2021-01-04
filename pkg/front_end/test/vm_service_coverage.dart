import 'dart:async';

import 'vm_service_helper.dart' as vmService;

main(List<String> args) async {
  CoverageHelper coverageHelper = new CoverageHelper();

  List<String> allArgs = <String>[];
  allArgs.addAll([
    "--disable-dart-dev",
    "--enable-asserts",
    "--pause_isolates_on_exit",
  ]);
  allArgs.addAll(args);

  coverageHelper.start(allArgs);
}

class CoverageHelper extends vmService.LaunchingVMServiceHelper {
  final bool forceCompilation;
  final bool printHits;

  CoverageHelper({this.forceCompilation: false, this.printHits: true});

  @override
  Future<void> run() async {
    vmService.VM vm = await serviceClient.getVM();
    if (vm.isolates.length != 1) {
      throw "Expected 1 isolate, got ${vm.isolates.length}";
    }
    vmService.IsolateRef isolateRef = vm.isolates.single;
    await waitUntilIsolateIsRunnable(isolateRef.id);
    await serviceClient.resume(isolateRef.id);
    Completer<String> cTimeout = new Completer();
    Timer timer = new Timer(new Duration(minutes: 20), () {
      cTimeout.complete("Timeout");
      killProcess();
    });

    Completer<String> cRunDone = new Completer();
    // ignore: unawaited_futures
    waitUntilPaused(isolateRef.id).then((value) => cRunDone.complete("Done"));

    await Future.any([cRunDone.future, cTimeout.future, cProcessExited.future]);

    timer.cancel();

    if (!await isPausedAtExit(isolateRef.id)) {
      killProcess();
      throw "Expected to be paused at exit, but is just paused!";
    }

    // Get and process coverage information.
    Stopwatch stopwatch = new Stopwatch()..start();
    vmService.SourceReport sourceReport = await serviceClient.getSourceReport(
        isolateRef.id, [vmService.SourceReportKind.kCoverage],
        forceCompile: forceCompilation);
    print("Got source report from VM in ${stopwatch.elapsedMilliseconds} ms");
    stopwatch.reset();
    Map<Uri, Coverage> coverages = {};
    for (vmService.SourceReportRange range in sourceReport.ranges) {
      vmService.ScriptRef script = sourceReport.scripts[range.scriptIndex];
      Uri scriptUri = Uri.parse(script.uri);
      if (!includeCoverageFor(scriptUri)) continue;
      Coverage coverage = coverages[scriptUri] ??= new Coverage();

      vmService.SourceReportCoverage sourceReportCoverage = range.coverage;
      if (sourceReportCoverage == null) {
        // Range not compiled. Record the range if provided.
        assert(!range.compiled);
        if (range.startPos >= 0 || range.endPos >= 0) {
          coverage.notCompiled
              .add(new StartEndPair(range.startPos, range.endPos));
        }
        continue;
      }
      coverage.hits.addAll(sourceReportCoverage.hits);
      coverage.misses.addAll(sourceReportCoverage.misses);
    }
    print("Processed source report from VM in "
        "${stopwatch.elapsedMilliseconds} ms");
    stopwatch.reset();

    // It's paused at exit, so resuming should allow us to exit.
    await serviceClient.resume(isolateRef.id);

    for (MapEntry<Uri, Coverage> entry in coverages.entries) {
      assert(entry.value.hits.intersection(entry.value.misses).isEmpty);
      if (entry.value.hits.isEmpty &&
          entry.value.misses.isEmpty &&
          entry.value.notCompiled.isEmpty) {
        continue;
      }
      print(entry.key);
      if (printHits) {
        print("Hits: ${entry.value.hits.toList()..sort()}");
      }
      print("Misses: ${entry.value.misses.toList()..sort()}");
      print("Not compiled: ${entry.value.notCompiled.toList()..sort()}");
      print("");
    }
  }

  Completer<String> cProcessExited = new Completer();
  void processExited(int exitCode) {
    cProcessExited.complete("Exit");
  }

  bool includeCoverageFor(Uri uri) {
    if (uri.scheme == "dart") {
      return false;
    }
    if (uri.scheme == "package") {
      return uri.pathSegments.first == "front_end" ||
          uri.pathSegments.first == "_fe_analyzer_shared" ||
          uri.pathSegments.first == "kernel";
    }
    return true;
  }
}

class Coverage {
  final Set<int> hits = {};
  final Set<int> misses = {};
  final Set<StartEndPair> notCompiled = {};
}

class StartEndPair implements Comparable {
  final int startPos;
  final int endPos;

  StartEndPair(this.startPos, this.endPos);

  String toString() => "[$startPos - $endPos]";

  @override
  int compareTo(Object other) {
    if (other is! StartEndPair) return -1;
    StartEndPair o = other;
    return startPos - o.startPos;
  }
}
