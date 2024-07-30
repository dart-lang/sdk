// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'vm_service_helper.dart';

Future<Coverage?> collectCoverage({
  required String displayName,
  bool getKernelServiceCoverageToo = false,
  bool forceCompile = false,
}) async {
  ServiceProtocolInfo service =
      await Service.controlWebServer(enable: true, silenceOutput: true);
  if (service.serverUri == null) {
    return null;
  }
  VMServiceHelper helper = new VMServiceHelper();
  await helper.connect(service.serverUri!);

  Coverage? result = await collectCoverageWithHelper(
    helper: helper,
    getKernelServiceCoverageToo: getKernelServiceCoverageToo,
    displayName: displayName,
    forceCompile: forceCompile,
  );
  await helper.disconnect();
  return result;
}

Future<Coverage?> collectCoverageWithHelper(
    {required VMServiceHelper helper,
    required final bool getKernelServiceCoverageToo,
    required final String displayName,
    bool forceCompile = false}) async {
  VM vm = await helper.serviceClient.getVM();
  final List<String> isolateIds = [];
  if (getKernelServiceCoverageToo) {
    List<IsolateRef> kernelServiceIsolates = vm.systemIsolates!
        .where((element) => element.name == "kernel-service")
        .toList();

    if (kernelServiceIsolates.length < 1) {
      print("Expected (at least) 1 kernel-service isolate, "
          "got ${kernelServiceIsolates.length}");
      return null;
    }

    // TODO(jensj): I guess we should look at the isolate group; also we could
    // just iterate through them to get all coverage...
    if (kernelServiceIsolates.length != 1) {
      print("Got ${kernelServiceIsolates.length} kernel-service isolates. "
          "Picking the first one.");
    }
    isolateIds.add(kernelServiceIsolates.first.id!);
  }

  if (vm.isolates!.isEmpty) {
    print("Expected (at least) 1 isolate, got ${vm.isolates!.length}");
    return null;
  }

  // TODO(jensj): I guess we should look at the isolate group; also we could
  // just iterate through them to get all coverage...
  if (vm.isolates!.length != 1) {
    print("Got ${vm.isolates!.length} isolates. Picking the first one.");
  }
  isolateIds.add(vm.isolates!.first.id!);

  List<SourceReport> sourceReports = [];
  for (String isolateId in isolateIds) {
    final Stopwatch stopwatch = new Stopwatch()..start();
    sourceReports.add(await helper.serviceClient.getSourceReport(
        isolateId, [SourceReportKind.kCoverage],
        forceCompile: forceCompile));
    print("Got source report from VM in ${stopwatch.elapsedMilliseconds} ms");
  }

  bool includeCoverageFor(Uri uri) {
    if (uri.isScheme("package")) {
      return uri.pathSegments.first == "front_end" ||
          uri.pathSegments.first == "frontend_server" ||
          uri.pathSegments.first == "_fe_analyzer_shared" ||
          uri.pathSegments.first == "testing" ||
          uri.pathSegments.first == "kernel";
    }
    return false;
  }

  final Stopwatch stopwatch = new Stopwatch()..start();
  Coverage coverage = getCoverageFromSourceReport(
    sourceReports,
    includeCoverageFor,
    displayName: displayName,
  );
  print("Done in ${stopwatch.elapsed}");
  return coverage;
}

Coverage getCoverageFromSourceReport(
  List<SourceReport> sourceReports,
  bool Function(Uri) shouldIncludeCoverageFor, {
  String? displayName,
}) {
  Coverage coverage = new Coverage(displayName ?? "");
  for (SourceReport sourceReport in sourceReports) {
    for (SourceReportRange range in sourceReport.ranges!) {
      ScriptRef script = sourceReport.scripts![range.scriptIndex!];
      Uri scriptUri = Uri.parse(script.uri!);
      if (!shouldIncludeCoverageFor(scriptUri)) continue;

      final FileCoverage fileCoverage =
          coverage.getOrAddFileCoverage(scriptUri);
      SourceReportCoverage? sourceReportCoverage = range.coverage;
      if (sourceReportCoverage == null) {
        // Range not compiled. Record the range if provided.
        assert(!range.compiled!);
        if (range.startPos! >= 0 || range.endPos! >= 0) {
          fileCoverage.notCompiled
              .add(new StartEndPair(range.startPos!, range.endPos!));
        }
        continue;
      }
      fileCoverage.hits.addAll(sourceReportCoverage.hits!);
      fileCoverage.misses.addAll(sourceReportCoverage.misses!);
    }
  }
  return coverage;
}

class Coverage {
  final Map<Uri, FileCoverage> _coverages = {};
  final String displayName;

  Coverage(this.displayName);

  FileCoverage getOrAddFileCoverage(Uri uri) {
    return _coverages[uri] ??= new FileCoverage._(uri);
  }

  List<FileCoverage> getAllFileCoverages() {
    return _coverages.values.toList();
  }

  void printCoverage(bool printHits) {
    for (FileCoverage fileCoverage in _coverages.values) {
      if (fileCoverage.hits.isEmpty &&
          fileCoverage.misses.isEmpty &&
          fileCoverage.notCompiled.isEmpty) {
        continue;
      }
      print(fileCoverage.uri);
      if (printHits) {
        print("Hits: ${fileCoverage.hits.toList()..sort()}");
      }
      print("Misses: ${fileCoverage.misses.toList()..sort()}");
      print("Not compiled: ${fileCoverage.notCompiled.toList()..sort()}");
      print("");
    }
  }

  Map<String, Object?> toJson() {
    return {
      "displayName": displayName,
      "coverages": _coverages.values.toList(),
    };
  }

  factory Coverage.fromJson(Map<String, Object?> json) {
    Coverage result = new Coverage(json["displayName"] as String? ?? "");
    List coverages = json["coverages"] as List;
    for (Map<String, dynamic> entry in coverages) {
      FileCoverage fileCoverage = FileCoverage.fromJson(entry);
      result._coverages[fileCoverage.uri] = fileCoverage;
    }
    return result;
  }

  factory Coverage.loadFromFile(File f) {
    return Coverage.fromJson(jsonDecode(f.readAsStringSync()));
  }

  void writeToFile(File f) {
    const JsonEncoder encoder = const JsonEncoder.withIndent("  ");
    // We don't want it to fail because the parent dir didn't exist.
    f.createSync(recursive: true);
    f.writeAsStringSync(encoder.convert(this));
    print("Wrote coverage to $f");
  }
}

class FileCoverage {
  final Uri uri;
  // File offset maps.
  final Set<int> hits = {};
  final Set<int> misses = {};
  final Set<StartEndPair> notCompiled = {};

  FileCoverage._(this.uri);

  Map<String, Object?> toJson() {
    List<int> notCompiledRanges = [];
    for (var pair in notCompiled.toList()
      ..sort((a, b) => a.startPos.compareTo(b.startPos))) {
      notCompiledRanges.add(pair.startPos);
      notCompiledRanges.add(pair.endPos);
    }
    misses.removeAll(hits);
    return {
      "uri": uri.toString(),
      "hits": hits.toList()..sort(),
      "misses": misses.toList()..sort(),
      "notCompiledRanges": notCompiledRanges,
    };
  }

  factory FileCoverage.fromJson(Map<String, Object?> json) {
    FileCoverage result = new FileCoverage._(Uri.parse(json["uri"] as String));
    List hits = json["hits"] as List;
    for (int hit in hits) {
      result.hits.add(hit);
    }
    List misses = json["misses"] as List;
    for (int mis in misses) {
      result.misses.add(mis);
    }
    List notCompiledRanges = json["notCompiledRanges"] as List;
    for (int i = 0; i < notCompiledRanges.length; i += 2) {
      result.notCompiled.add(
          new StartEndPair(notCompiledRanges[i], notCompiledRanges[i + 1]));
    }
    return result;
  }
}

class StartEndPair implements Comparable {
  final int startPos;
  final int endPos;

  StartEndPair(this.startPos, this.endPos);

  @override
  String toString() => "[$startPos - $endPos]";

  @override
  int compareTo(dynamic other) {
    if (other is! StartEndPair) return -1;
    StartEndPair o = other;
    return startPos - o.startPos;
  }

  @override
  int get hashCode => Object.hash(startPos, endPos);
}
