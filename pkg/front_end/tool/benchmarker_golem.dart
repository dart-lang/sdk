// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "benchmarker.dart";

void main(List<String> args) {
  checkEnvironment();
  String? name;
  String? aotRuntime;
  String? snapshot;
  List<String> arguments = [];
  for (String arg in args) {
    if (arg.startsWith("--aotruntime=")) {
      aotRuntime = arg.substring("--aotruntime=".length);
    } else if (arg.startsWith("--snapshot=")) {
      snapshot = arg.substring("--snapshot=".length);
    } else if (arg.startsWith("--arguments=")) {
      arguments.add(arg.substring("--arguments=".length));
    } else if (arg.startsWith("--name=")) {
      name = arg.substring("--name=".length);
    } else {
      throw "Don't know argument '$arg'";
    }
  }
  aotRuntime!;
  snapshot!;
  name!;

  printData(
    benchmark(
      snapshot,
      [],
      arguments,
      aotRuntime: aotRuntime,
      cacheBenchmarking: false,
      core: 3,
    ),
    "${name}_",
  );
  printData(
    benchmark(
      snapshot,
      [],
      arguments,
      aotRuntime: aotRuntime,
      cacheBenchmarking: true,
      core: 3,
    ),
    "${name}_cache_",
  );
  printData(
    benchmark(
      snapshot,
      ["--new_gen_semi_initial_size=10000", "--new_gen_semi_max_size=20000"],
      arguments,
      aotRuntime: aotRuntime,
      cacheBenchmarking: false,
      core: 3,
    ),
    "${name}_no_gc_",
  );
}

void printData(Map<String, num> data, String prefix) {
  printElement(
    "cpu_time",
    data["msec task-clock:u"],
    prefix,
    "RunTimeRaw",
    "ms",
  );
  printElement(
    "wall_clock",
    data["seconds time elapsed"],
    prefix,
    "RunTimeRaw",
    "s",
  );
  printElement(
    "L1_icache_load_misses",
    data["L1-icache-load-misses"],
    prefix,
    "PerfCount",
  );
  printElement("LLC_loads", data["LLC-loads"], prefix, "PerfCount");
  printElement("LLC_load_misses", data["LLC-load-misses"], prefix, "PerfCount");
  printElement("cycles", data["cycles:u"], prefix, "CpuCycles", "CpuCycles");
  printElement(
    "instructions",
    data["instructions:u"],
    prefix,
    "PerfInstructions",
  );
  printElement("branch_misses", data["branch-misses:u"], prefix, "PerfCount");
  printElement("max_rss_bytes", data["maxRssBytes"], prefix, "MemoryUse", "b");
}

void printElement(
  String name,
  num? data,
  String prefix,
  String type, [
  String? unit,
]) {
  if (data == null) return;
  if (unit == null) {
    print("${prefix}${name}($type): $data");
  } else {
    print("${prefix}${name}($type): $data $unit");
  }
}
