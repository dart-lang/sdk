// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show ZoneSpecification, runZoned;

import 'dart:io' show File;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:kernel/kernel.dart' show Component;

import "../../test/incremental_utils.dart" as util;

import "../../test/incremental_suite.dart" as incrementalTest;

import '../../test/utils/io_utils.dart' show computeRepoDirUri;

final Uri repoDir = computeRepoDirUri();

class Helper {
  MemoryFileSystem? fs;
  CompilerOptions? options;
  incrementalTest.TestIncrementalCompiler? compiler;
  late final Uri base;
  late final Uri sdkSummary;
  late final List<int> sdkSummaryData;

  Future<void> setup() async {
    final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
    base = Uri.parse("org-dartlang-test:///");
    sdkSummary = base.resolve("vm_platform.dill");
    Uri platformUri = sdkRoot.resolve("vm_platform.dill");
    sdkSummaryData = await new File.fromUri(platformUri).readAsBytes();
  }

  Future<(Object, StackTrace)?> compile(String program) async {
    if (fs == null) {
      fs = new MemoryFileSystem(base);
      fs!.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);
    }

    Uri uri = base.resolve("main.dart");
    fs!.entityForUri(uri).writeAsStringSync(program);
    Map<String, int> diagnostics = {};
    options ??= incrementalTest.getOptions();
    options!.fileSystem = fs!;
    options!.sdkRoot = null;
    options!.sdkSummary = sdkSummary;
    options!.omitPlatform = true;
    options!.onDiagnostic = (DiagnosticMessage message) {
      diagnostics[message.severity.toString()] =
          (diagnostics[message.severity.toString()] ?? 0) + 1;
    };

    compiler ??= new incrementalTest.TestIncrementalCompiler(options!, uri);
    compiler!.invalidate(uri);

    try {
      ZoneSpecification specification =
          new ZoneSpecification(print: (_1, _2, _3, String line) {
        // Swallow!
      });
      await runZoned(() async {
        Stopwatch stopwatch = new Stopwatch()..start();
        IncrementalCompilerResult result = await compiler!
            .computeDelta(entryPoints: [uri], fullComponent: true);
        Component component = result.component;

        util.throwOnEmptyMixinBodies(component);
        await util.throwOnInsufficientUriToSource(component);
        print("Compile took ${stopwatch.elapsedMilliseconds} ms. "
            "Got $diagnostics");
      }, zoneSpecification: specification);
      return null;
    } catch (e, st) {
      print("Crashed on input.");
      options = null;
      compiler = null;
      return (e, st);
    }
  }
}
