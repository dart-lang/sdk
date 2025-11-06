// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:io" as io;
import "dart:math";

final buildDirs = [
  "out/ReleaseX64",
  "out/ReleaseX64C",
  "out/ReleaseSIMARM64",
  "out/ReleaseSIMARM64C",
  "out/ReleaseSIMRISCV64",
  "out/DebugX64",
  "out/DebugX64C",
  "out/DebugSIMARM64",
  "out/DebugSIMARM64C",
  "out/DebugSIMRISCV64",
];

final profilerFlags = [
  "--profile_vm=true", // default is different for simulators
  "--profile_vm=false",
  "--profile_period=${range(500, 10000)}",
  "--max_profile_depth=${range(8, 256)}",
  "--sample_buffer_duration=${range(30, 60)}",
];

final gcFlags = [
  "--compactor_tasks=${range(1, 3)}",
  "--dontneed_on_sweep",
  "--force_evacuation",
  "--mark_when_idle",
  "--marker_tasks=${range(1, 3)}",
  "--no_concurrent_mark",
  "--no_concurrent_sweep",
  "--no_inline_alloc",
  "--runtime_allocate_old",
  "--runtime_allocate_spill_tlab",
  "--scavenger_tasks=${range(1, 3)}",
  "--use_compactor",
  "--verify_after_gc",
  "--verify_after_marking",
  "--verify_before_gc",
  "--verify_store_buffer",
  "--write_protect_code",
  "--gc_at_throw",
];

final compilerFlags = [
  "--branch_coverage",
  "--code_comments",
  "--force_clone_compiler_objects",
  "--force_indirect_calls",
  "--force_switch_dispatch_type=${range(0, 2)}",
  "--inlining_callee_call_sites_threshold=${range(1, 3)}",
  "--inlining_callee_size_threshold=${range(100, 300)}",
  "--inlining_caller_size_threshold=${range(10000, 100000)}",
  "--inlining_depth_threshold=${range(2, 8)}",
  "--inlining_hotness=${range(5, 20)}",
  "--inlining_recursion_depth_threshold=${range(0, 3)}",
  "--inlining_size_threshold=${range(15, 35)}",
  "--inlining_small_leaf_size_threshold=${range(40, 60)}",
  "--link_natives_lazily",
  "--max_equality_polymorphic_checks=${range(8, 256)}",
  "--max_polymorphic_checks=${range(4, 12)}",
  "--no_array_bounds_check_elimination",
  "--no_background_compilation",
  "--no_compress_deopt_info",
  "--no_dead_store_elimination",
  "--no_enable_peephole",
  "--no_guess_icdata_cid",
  "--no_intrinsify",
  "--no_load_cse",
  "--no_polymorphic_with_deopt",
  "--no_propagate_ic_data",
  "--no_prune_dead_locals",
  "--no_remove_redundant_phis",
  "--no_reorder_basic_blocks",
  "--no_truncating_left_shift",
  "--no_two_args_smi_icd",
  "--no_unopt_megamorphic_calls",
  "--no_unopt_monomorphic_calls",
  "--no_use_cha_deopt",
  "--no_use_field_guards",
  "--no_use_osr",
  "--no_use_register_cc",
  "--optimization_counter_threshold=${range(1000, 50000)}",
  "--optimization_level=${range(1, 3)}",
  "--target_unknown_cpu",
  "--test_il_serialization",
  "--use_slow_path",
];

final random = new Random();
int range(int min, int max) {
  return random.nextInt(max - min + 1) + min;
}

String oneOf(List<String> choices) {
  return choices[random.nextInt(choices.length)];
}

List<String> someOf(List<String> choices) {
  var result = <String>[];
  for (var i = 0, n = range(0, 2); i < n; i++) {
    result.add(oneOf(choices));
  }
  return result;
}

List<String> someJitRuntimeFlags() {
  return [
    "--profiler", // Off by default unless VM service enabled
    ...someOf(profilerFlags),
    ...someOf(gcFlags),
    ...someOf(compilerFlags),
  ];
}

List<String> someAotRuntimeFlags() {
  return [
    "--profiler", // Off by default unless VM service enabled
    ...someOf(profilerFlags),
    ...someOf(gcFlags),
  ];
}

List<String> someGenSnapshotFlags() {
  return [...someOf(gcFlags), ...someOf(compilerFlags)];
}

Stopwatch stopwatch = new Stopwatch();

const overallTimeout = Duration(minutes: 30);
Duration get remainingTimeout => overallTimeout - stopwatch.elapsed;

// LUCI will kill recipe steps if they go 1200 seconds without any output.
const statusTimeout = Duration(minutes: 5);
int pendingTaskCount = 0;
late Timer pendingTimer;
taskStart() {
  if (pendingTaskCount++ == 0) {
    pendingTimer = new Timer.periodic(statusTimeout, (timer) {
      print(
        "$pendingTaskCount tasks still running after "
        "${stopwatch.elapsed.inMinutes} minutes",
      );
    });
  }
}

taskEnd() {
  if (--pendingTaskCount == 0) {
    pendingTimer.cancel();
  }
}

test(List<String> Function(String) createDartCommand, int taskIndex) async {
  taskStart();

  var dartCommand = createDartCommand("out/dartfuzz/$taskIndex.js");
  var dartScript = dartCommand[0];
  var dartArguments = dartCommand.getRange(1, dartCommand.length).toList();

  var buildDir = oneOf(buildDirs);
  var commands;
  if (random.nextBool()) {
    // JIT
    commands = [
      [
        "$buildDir/dart",
        ...someJitRuntimeFlags(),
        dartScript,
        ...dartArguments,
      ],
      ["diff", "out/dartfuzz/expected.js", "out/dartfuzz/$taskIndex.js"],
    ];
  } else {
    // AOT
    commands = [
      [
        "out/ReleaseX64/dart",
        "pkg/vm/bin/gen_kernel.dart",
        "--platform=$buildDir/vm_platform.dill",
        "--aot",
        "--output=out/dartfuzz/$taskIndex.dill",
        dartScript,
      ],
      [
        "$buildDir/gen_snapshot",
        ...someGenSnapshotFlags(),
        "--snapshot_kind=app-aot-elf",
        "--elf=out/dartfuzz/$taskIndex.elf",
        "out/dartfuzz/$taskIndex.dill",
      ],
      [
        "$buildDir/dartaotruntime",
        ...someAotRuntimeFlags(),
        "out/dartfuzz/$taskIndex.elf",
        ...dartArguments,
      ],
      ["diff", "out/dartfuzz/expected.js", "out/dartfuzz/$taskIndex.js"],
    ];
  }

  for (int commandIndex = 0; commandIndex < commands.length; commandIndex++) {
    var command = commands[commandIndex];
    var executable = command[0];
    var arguments = command.getRange(1, command.length).toList();
    var cmdline = command.join(' ');
    print("Start: $cmdline");
    var timeout = remainingTimeout;
    if (timeout.isNegative) {
      print("Timeout: $cmdline");
      break;
    }
    var process = await Process.start(executable, arguments);
    var timedOut = false;
    var timer = new Timer(timeout, () {
      timedOut = true;
      Process.killPid(process.pid);
    });
    var exitCode = await process.exitCode;
    timer.cancel();
    if (timedOut) {
      print("Timeout: $cmdline");
      break;
    } else if (exitCode == 0) {
      print("Success: $cmdline");
      process.stdout.drain();
      process.stderr.drain();
    } else {
      var stdout = await utf8.decodeStream(process.stdout);
      var stderr = await utf8.decodeStream(process.stderr);
      print("");
      print("=== FAILURE ===");
      for (int i = 0; i <= commandIndex; i++) {
        print("command: ${commands[i].join(' ')}");
      }
      print("exitCode: $exitCode");
      print("stdout:");
      print(stdout);
      print("stderr:");
      print(stderr);
      io.exitCode = 1;
      break;
    }
  }

  taskEnd();
}

shard(List<String> Function(String) createDartCommand, int shardIndex) async {
  while (!remainingTimeout.isNegative) {
    await test(createDartCommand, shardIndex);
  }
}

flagFuzz(List<String> Function(String) createDartCommand) async {
  stopwatch.start();

  await Directory("out/dartfuzz").create();

  var executable = "out/ReleaseX64/dart";
  var arguments = createDartCommand("out/dartfuzz/expected.js");
  var processResult = await Process.run(executable, arguments);
  if (processResult.exitCode != 0) {
    print("=== FAILURE ===");
    print("command: $executable ${arguments.join(' ')}");
    print("stdout:");
    print(processResult.stdout);
    print("stderr:");
    print(processResult.stderr);
    io.exitCode = 1;
    return;
  }

  for (var i = 0; i < Platform.numberOfProcessors; i++) {
    shard(createDartCommand, i);
  }
}
