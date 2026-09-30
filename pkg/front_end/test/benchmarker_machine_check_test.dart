// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import '../tool/benchmarker_machine_check.dart';

void main() {
  testCheckCore();
  testNoWarnings();
  testFrequencyAndTurboWarnings();
  testVmAndThpWarnings();
  testLoadWarning();
  testBusyCoreAndSibling();
}

const String cpu = "/sys/devices/system/cpu";

/// A fake file system; `/proc/stat` returns successive entries of
/// [procStats] on successive reads.
FileReader fakeFiles(
  Map<String, String> files, {
  List<String> procStats = const [],
}) {
  int procStatReads = 0;
  return (String path) {
    if (path == "/proc/stat") {
      if (procStatReads >= procStats.length) return null;
      return procStats[procStatReads++];
    }
    return files[path];
  };
}

List<String> check(
  Map<String, String> files, {
  int core = 3,
  List<String> procStats = const [],
}) => checkMachineSetup(
  core,
  readFile: fakeFiles(files, procStats: procStats),
  sleepFor: (_) {},
);

void expectWarning(List<String> warnings, String substring) {
  Expect.isTrue(
    warnings.any((w) => w.contains(substring)),
    "Expected a warning containing '$substring' in $warnings",
  );
}

void testCheckCore() {
  Map<String, String> files = {
    "$cpu/present": "0-7\n",
    "$cpu/cpu3/topology/thread_siblings_list": "3,7\n",
    "$cpu/cpu5/topology/thread_siblings_list": "1,5\n",
    "$cpu/cpu5/online": "0\n",
  };
  Expect.isNull(checkCore(3, readFile: fakeFiles(files)));
  String? error = checkCore(9, readFile: fakeFiles(files));
  Expect.isNotNull(error);
  Expect.contains("available CPUs: 0-7", error!);
  Expect.contains("offline", checkCore(5, readFile: fakeFiles(files))!);
}

void testNoWarnings() {
  Expect.listEquals(
    [],
    check({
      "$cpu/cpu3/cpufreq/scaling_governor": "performance\n",
      "$cpu/intel_pstate/no_turbo": "1\n",
      "/sys/kernel/mm/transparent_hugepage/enabled": "always [madvise] never\n",
      "/proc/loadavg": "0.12 0.20 0.30 1/100 1234\n",
      "/proc/cpuinfo": "processor : 0\nflags : fpu vme sse2\n",
    }),
  );
}

void testFrequencyAndTurboWarnings() {
  List<String> warnings = check({
    "$cpu/cpu3/cpufreq/scaling_governor": "powersave\n",
    "$cpu/cpufreq/boost": "1\n",
  });
  Expect.equals(2, warnings.length);
  expectWarning(warnings, "'powersave'");
  expectWarning(warnings, "Turbo boost");
  expectWarning(check({"$cpu/intel_pstate/no_turbo": "0\n"}), "Turbo boost");
}

void testVmAndThpWarnings() {
  List<String> warnings = check({
    "/proc/cpuinfo": "processor : 0\nflags : fpu hypervisor sse2\n",
    "/sys/kernel/mm/transparent_hugepage/enabled": "[always] madvise never\n",
  });
  Expect.equals(2, warnings.length);
  expectWarning(warnings, "virtual machine");
  expectWarning(warnings, "Transparent huge pages");
}

void testLoadWarning() {
  expectWarning(
    check({"/proc/loadavg": "3.50 2.00 1.00 5/100 1234\n"}),
    "load average is 3.5",
  );
}

void testBusyCoreAndSibling() {
  // Fields: user nice system idle iowait irq softirq steal guest guest_nice.
  String before = """
cpu  1000 0 0 1000 0 0 0 0 0 0
cpu3 100 0 0 1000 0 0 0 0 0 0
cpu7 100 0 0 1000 0 0 0 0 0 0
cpu9 100 0 0 1000 0 0 0 0 0 0
""";
  // CPU 3 idle (except a little steal), CPU 7 (its sibling) 50% busy, CPU 9
  // (unrelated) fully busy.
  String after = """
cpu  1000 0 0 1000 0 0 0 0 0 0
cpu3 100 0 0 1090 0 0 0 10 0 0
cpu7 150 0 0 1050 0 0 0 0 0 0
cpu9 200 0 0 1000 0 0 0 0 0 0
""";
  List<String> warnings = check(
    {"$cpu/cpu3/topology/thread_siblings_list": "3,7\n"},
    procStats: [before, after],
  );
  Expect.equals(2, warnings.length, "$warnings");
  expectWarning(warnings, "CPU 7 (a hyperthread sibling of CPU 3) was 50%");
  expectWarning(warnings, "CPU 3 (the benchmark core) had 10% steal time");
}
