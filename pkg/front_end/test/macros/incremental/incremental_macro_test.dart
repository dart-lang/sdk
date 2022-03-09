// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/macros/executor/isolated_executor.dart'
    as isolatedExecutor;
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/hybrid_file_system.dart';
import 'package:front_end/src/fasta/incremental_compiler.dart';
import 'package:front_end/src/fasta/kernel/macro.dart';
import 'package:front_end/src/isolate_macro_serializer.dart';
import 'package:front_end/src/macro_serializer.dart';
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:vm/target/vm.dart';

import '../../utils/kernel_chain.dart';

Future<void> main(List<String> args) async {
  Map<String, Map<int, String>> testData = {};
  Directory dataDir =
      new Directory.fromUri(Platform.script.resolve('data/tests'));
  for (FileSystemEntity file in dataDir.listSync()) {
    String fileName = file.uri.pathSegments.last;
    if (file is! File || !fileName.endsWith('.dart')) {
      continue;
    }
    String testName = fileName.substring(0, fileName.length - 5);
    int dotIndex = testName.lastIndexOf('.');
    int index = 1;
    if (dotIndex != -1) {
      index = int.parse(testName.substring(dotIndex + 1));
      testName = testName.substring(0, dotIndex);
    }
    (testData[testName] ??= {})[index] = file.readAsStringSync();
  }

  List<Test> tests = [];
  testData.forEach((String name, Map<int, String> files) {
    List<TestUpdate> updates = [];
    for (int index in files.keys.toList()..sort()) {
      String file = files[index]!;
      // TODO(johnniwinther): Support multiple files in the same test.
      updates.add(new TestUpdate(index, {toTestUri(name): file}));
    }
    tests.add(new Test(name, updates));
  });

  args = args.toList();
  bool generateExpectations = args.remove('-g');
  enableMacros = true;
  MacroSerializer macroSerializer = new IsolateMacroSerializer();
  MemoryFileSystem memoryFileSystem = createMemoryFileSystem();
  CompilerOptions compilerOptions = new CompilerOptions()
    ..sdkRoot = computePlatformBinariesLocation(forceBuildDir: true)
    ..packagesFileUri = Platform.script.resolve('data/package_config.json')
    ..explicitExperimentalFlags = {ExperimentalFlag.macros: true}
    ..macroSerializer = macroSerializer
    ..precompiledMacroUris = {}
    ..macroExecutorProvider = () async {
      return await isolatedExecutor.start(SerializationMode.byteDataServer);
    }
    ..macroTarget = new VmTarget(new TargetFlags())
    ..fileSystem = new HybridFileSystem(memoryFileSystem);

  ProcessedOptions processedOptions =
      new ProcessedOptions(options: compilerOptions);

  await CompilerContext.runWithOptions(processedOptions,
      (CompilerContext context) async {
    IncrementalCompiler compiler = new IncrementalCompiler(context);
    for (Test test in tests) {
      Uri mainUri = toTestUri(test.name);
      for (TestUpdate update in test.updates) {
        update.files.forEach((Uri uri, String source) {
          memoryFileSystem.entityForUri(uri).writeAsStringSync(source);
          compiler.invalidate(uri);
        });
        IncrementalCompilerResult incrementalCompilerResult =
            await compiler.computeDelta(entryPoints: [mainUri]);
        Component component = incrementalCompilerResult.component;
        StringBuffer buffer = new StringBuffer();
        Printer printer = new Printer(buffer)
          ..writeProblemsAsJson(
              "Problems in component", component.problemsAsJson);
        component.libraries.forEach((Library library) {
          if (library.importUri == mainUri) {
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
          throw 'Please use -g option to create file ${expectedUri} with this '
              'content:\n$actual';
        }
      }
    }
  }, errorOnMissingInput: false);
  await macroSerializer.close();
}

class Test {
  final String name;
  final List<TestUpdate> updates;

  Test(this.name, this.updates);
}

class TestUpdate {
  final int index;
  final Map<Uri, String> files;

  TestUpdate(this.index, this.files);
}
