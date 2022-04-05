// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/hybrid_file_system.dart';
import 'package:front_end/src/fasta/incremental_compiler.dart';
import 'package:front_end/src/fasta/kernel/macro/macro.dart';
import 'package:front_end/src/isolate_macro_serializer.dart';
import 'package:front_end/src/macro_serializer.dart';
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:vm/target/vm.dart';

import '../../utils/kernel_chain.dart';

Future<void> main(List<String> args) async {
  Map<String, Test> tests = {};
  Map<String, Map<Uri, Map<int, String>>> testData = {};
  Directory dataDir =
      new Directory.fromUri(Platform.script.resolve('data/tests'));

  void addFile(Test? test, FileSystemEntity file, String fileName) {
    if (file is! File || !fileName.endsWith('.dart')) {
      return;
    }
    String testFileName = fileName.substring(0, fileName.length - 5);
    int dotIndex = testFileName.lastIndexOf('.');
    int index = 1;
    if (dotIndex != -1) {
      index = int.parse(testFileName.substring(dotIndex + 1));
      testFileName = testFileName.substring(0, dotIndex);
    }
    String testName = testFileName;
    testFileName += '.dart';
    Uri uri = toTestUri(testFileName);
    test ??= new Test(testName, uri);
    tests[test.name] ??= test;
    Map<Uri, Map<int, String>> updates = testData[test.name] ??= {};
    (updates[uri] ??= {})[index] = file.readAsStringSync();
  }

  for (FileSystemEntity file in dataDir.listSync()) {
    String fileName = file.uri.pathSegments.last;
    if (file is Directory) {
      Directory dir = file;
      // Note that the last segment of a directory uri is the empty string!
      String dirName = dir.uri.pathSegments[dir.uri.pathSegments.length - 2];
      Test test = new Test('$dirName/main', toTestUri('$dirName/main.dart'));
      for (FileSystemEntity file in dir.listSync()) {
        addFile(test, file, '$dirName/${file.uri.pathSegments.last}');
      }
    } else {
      addFile(null, file, fileName);
    }
  }

  testData.forEach((String testName, Map<Uri, Map<int, String>> files) {
    Test test = tests[testName]!;
    Map<int, Map<Uri, String>> updatesMap = {};
    files.forEach((Uri uri, Map<int, String> updates) {
      test.uris.add(uri);
      updates.forEach((int index, String source) {
        (updatesMap[index] ??= {})[uri] = source;
      });
    });
    for (int index in updatesMap.keys.toList()..sort()) {
      test.updates.add(new TestUpdate(index, updatesMap[index]!));
    }
  });

  args = args.toList();
  bool generateExpectations = args.remove('-g');
  enableMacros = true;
  MacroSerializer macroSerializer = new IsolateMacroSerializer();
  MemoryFileSystem memoryFileSystem = createMemoryFileSystem();
  CompilerOptions compilerOptions = new CompilerOptions()
    ..sdkRoot = computePlatformBinariesLocation(forceBuildDir: true)
    ..packagesFileUri = Platform.script.resolve('data/package_config.json')
    ..explicitExperimentalFlags = {
      ExperimentalFlag.macros: true,
      ExperimentalFlag.alternativeInvalidationStrategy: true,
    }
    ..macroSerializer = macroSerializer
    ..macroTarget = new VmTarget(new TargetFlags())
    ..fileSystem = new HybridFileSystem(memoryFileSystem);
  compilerOptions.macroExecutor ??= new MultiMacroExecutor();

  ProcessedOptions processedOptions =
      new ProcessedOptions(options: compilerOptions);

  await CompilerContext.runWithOptions(processedOptions,
      (CompilerContext context) async {
    IncrementalCompiler compiler = new IncrementalCompiler(context);
    for (Test test in tests.values) {
      if (args.isNotEmpty && !args.contains(test.name)) {
        print('Skipped ${test.name}');
        continue;
      }
      Uri entryPoint = test.entryPoint;
      for (TestUpdate update in test.updates) {
        print('Running ${test.name} update ${update.index}');
        update.files.forEach((Uri uri, String source) {
          memoryFileSystem.entityForUri(uri).writeAsStringSync(source);
          compiler.invalidate(uri);
        });
        IncrementalCompilerResult incrementalCompilerResult =
            await compiler.computeDelta(entryPoints: [entryPoint]);
        Component component = incrementalCompilerResult.component;
        StringBuffer buffer = new StringBuffer();
        Printer printer = new Printer(buffer)
          ..writeProblemsAsJson(
              "Problems in component", component.problemsAsJson);
        component.libraries.forEach((Library library) {
          if (test.uris.contains(library.importUri)) {
            printer.writeLibraryFile(library);
            printer.endLine();
          }
        });
        printer.writeConstantTable(component);
        String actual = buffer.toString();
        String expectationFileName = '${test.name}.${update.index}.dart.expect';
        Uri expectedUri = dataDir.uri.resolve(expectationFileName);
        File expectationFile = new File.fromUri(expectedUri);
        if (expectationFile.existsSync()) {
          String expected = expectationFile.readAsStringSync();
          if (expected != actual) {
            if (generateExpectations) {
              expectationFile.writeAsStringSync(actual);
            } else {
              String diff = await runDiff(expectedUri, actual);
              throw "${expectationFileName} don't match ${expectedUri}\n$diff";
            }
          }
        } else if (generateExpectations) {
          expectationFile.writeAsStringSync(actual);
        } else {
          throw 'Please use -g option to create file ${expectationFileName} '
              'with this content:\n$actual';
        }

        /// Test serialization
        writeComponentToBytes(component);
      }
    }
  }, errorOnMissingInput: false);
  await macroSerializer.close();
}

class Test {
  final String name;
  final Uri entryPoint;
  final Set<Uri> uris = {};
  final List<TestUpdate> updates = [];

  Test(this.name, this.entryPoint);
}

class TestUpdate {
  final int index;
  final Map<Uri, String> files;

  TestUpdate(this.index, this.files);
}
