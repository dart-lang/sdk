// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Checks of the machine's setup, used by `benchmarker.dart` to warn about
/// settings that are known to make benchmark results noisy or misleading.
library;

import 'dart:io';

/// Reads the file at [path], returning `null` if it can't be read.
typedef FileReader = String? Function(String path);

String? _readFile(String path) {
  try {
    return new File(path).readAsStringSync();
  } catch (_) {
    return null;
  }
}

/// Returns an error message if [core] isn't a valid, online CPU, or `null`
/// if it is.
String? checkCore(int core, {FileReader readFile = _readFile}) {
  String cpuDir = "/sys/devices/system/cpu/cpu$core";
  if (readFile("$cpuDir/topology/thread_siblings_list") == null) {
    String? present = readFile("/sys/devices/system/cpu/present")?.trim();
    return "--core=$core doesn't seem to be a valid CPU"
        "${present == null ? "" : " (available CPUs: $present)"}.";
  }
  // `online` doesn't exist for CPUs that can't be taken offline (e.g. cpu0).
  if (readFile("$cpuDir/online")?.trim() == "0") {
    return "CPU $core (from --core=$core) is offline.";
  }
  return null;
}

/// Checks the machine's setup for things known to affect benchmark results,
/// returning a (possibly empty) list of human-readable warnings.
///
/// This samples `/proc/stat` over [sampleTime] to see whether [core] or its
/// hyperthread siblings are busy.
List<String> checkMachineSetup(
  int core, {
  FileReader readFile = _readFile,
  Duration sampleTime = const Duration(seconds: 1),
  void Function(Duration) sleepFor = sleep,
}) {
  List<String> warnings = [];
  String cpuDir = "/sys/devices/system/cpu/cpu$core";

  String? governor = readFile("$cpuDir/cpufreq/scaling_governor")?.trim();
  if (_isVirtualMachine(readFile)) {
    String frequencyNote = governor == null
        ? ", and CPU frequency settings can't be checked"
        : "";
    warnings.add(
      "This seems to be a virtual machine. Other virtual machines on the "
      "same host can affect time, cycle and cache measurements (but not "
      "instruction counts)$frequencyNote.",
    );
  }

  if (governor != null && governor != "performance") {
    warnings.add(
      "The CPU frequency governor for CPU $core is '$governor', not "
      "'performance'; the clock speed may vary during the benchmark.",
    );
  }

  String? noTurbo = readFile("/sys/devices/system/cpu/intel_pstate/no_turbo")
      ?.trim();
  String? boost = readFile("/sys/devices/system/cpu/cpufreq/boost")?.trim();
  if (noTurbo == "0" || boost == "1") {
    warnings.add(
      "Turbo boost is enabled; the clock speed may vary with temperature "
      "and with the load on other cores.",
    );
  }

  String? thp = readFile("/sys/kernel/mm/transparent_hugepage/enabled");
  if (thp != null && thp.contains("[always]")) {
    warnings.add(
      "Transparent huge pages are set to 'always'. Whether memory ends up "
      "backed by huge pages depends on memory fragmentation, which can "
      "make TLB-sensitive measurements (time, cycles) vary between runs.",
    );
  }

  String? loadavg = readFile("/proc/loadavg");
  if (loadavg != null) {
    double? load = double.tryParse(loadavg.split(" ").first);
    if (load != null && load > 1.0) {
      warnings.add(
        "The load average is $load; other processes may be competing for "
        "shared resources (caches, memory bandwidth).",
      );
    }
  }

  List<int> cpusToWatch = _parseCpuList(
    readFile("$cpuDir/topology/thread_siblings_list")?.trim() ?? "$core",
  );
  if (!cpusToWatch.contains(core)) cpusToWatch.add(core);
  Map<int, _CpuTimes>? before = _parseProcStat(readFile("/proc/stat"));
  if (before != null) {
    sleepFor(sampleTime);
    Map<int, _CpuTimes>? after = _parseProcStat(readFile("/proc/stat"));
    if (after != null) {
      for (int cpu in cpusToWatch) {
        _CpuTimes? b = before[cpu];
        _CpuTimes? a = after[cpu];
        if (a == null || b == null) continue;
        int total = a.total - b.total;
        if (total <= 0) continue;
        double busy = (a.busy - b.busy) / total;
        double steal = (a.steal - b.steal) / total;
        String which = cpu == core
            ? "CPU $core (the benchmark core)"
            : "CPU $cpu (a hyperthread sibling of CPU $core)";
        if (busy > 0.05) {
          warnings.add(
            "$which was ${(busy * 100).toStringAsFixed(0)}% busy before "
            "the benchmark started; other processes running there will "
            "affect the results.",
          );
        }
        if (steal > 0.01) {
          warnings.add(
            "$which had ${(steal * 100).toStringAsFixed(0)}% steal time; "
            "the hypervisor is giving the CPU to other virtual machines.",
          );
        }
      }
    }
  }

  return warnings;
}

bool _isVirtualMachine(FileReader readFile) {
  String? cpuinfo = readFile("/proc/cpuinfo");
  if (cpuinfo == null) return false;
  for (String line in cpuinfo.split("\n")) {
    if (line.startsWith("flags") &&
        line.split(new RegExp(r"\s+")).contains("hypervisor")) {
      return true;
    }
  }
  return false;
}

/// Parses a CPU list such as "3,27" or "0-3,8".
List<int> _parseCpuList(String list) {
  List<int> result = [];
  for (String part in list.split(",")) {
    part = part.trim();
    if (part.isEmpty) continue;
    int dash = part.indexOf("-");
    if (dash < 0) {
      int? cpu = int.tryParse(part);
      if (cpu != null) result.add(cpu);
    } else {
      int? from = int.tryParse(part.substring(0, dash));
      int? to = int.tryParse(part.substring(dash + 1));
      if (from == null || to == null) continue;
      for (int cpu = from; cpu <= to; cpu++) {
        result.add(cpu);
      }
    }
  }
  return result;
}

class _CpuTimes {
  final int total;
  final int busy;
  final int steal;

  new({required this.total, required this.busy, required this.steal});
}

/// Parses the per-CPU lines (e.g. `cpu3 100 0 50 1000 5 0 1 0 0 0`) of
/// `/proc/stat`.
Map<int, _CpuTimes>? _parseProcStat(String? contents) {
  if (contents == null) return null;
  Map<int, _CpuTimes> result = {};
  for (String line in contents.split("\n")) {
    if (!line.startsWith("cpu") || line.startsWith("cpu ")) continue;
    List<String> fields = line.split(new RegExp(r"\s+"));
    int? cpu = int.tryParse(fields[0].substring("cpu".length));
    if (cpu == null || fields.length < 5) continue;
    List<int> values = [
      for (String field in fields.skip(1))
        if (field.isNotEmpty) int.tryParse(field) ?? 0,
    ];
    // user nice system idle iowait irq softirq steal guest guest_nice.
    // guest and guest_nice are already included in user and nice.
    int total = 0;
    for (int i = 0; i < values.length && i < 8; i++) {
      total += values[i];
    }
    int idle = values[3] + (values.length > 4 ? values[4] : 0);
    int steal = values.length > 7 ? values[7] : 0;
    result[cpu] = new _CpuTimes(
      total: total,
      busy: total - idle - steal,
      steal: steal,
    );
  }
  return result;
}
