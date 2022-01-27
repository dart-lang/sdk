// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/isolated_executor/isolated_executor.dart'
    as isolatedExecutor;
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';
import 'package:front_end/src/fasta/kernel/macro.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart' hide Arguments;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:vm/target/vm.dart';

const Map<String, Map<String, List<String>>> macroDeclarations = {
  'package:macro/macro.dart': {
    'FunctionDefinitionMacro1': [''],
    'FunctionDefinitionMacro2': [''],
    'FunctionTypesMacro1': [''],
    'FunctionDeclarationsMacro1': [''],
  }
};

Future<Uri> compileMacros(Directory directory) async {
  CompilerOptions options = new CompilerOptions();
  options.target = new VmTarget(new TargetFlags());
  options.explicitExperimentalFlags[ExperimentalFlag.macros] = true;
  options.environmentDefines = {};
  options.packagesFileUri = Platform.script.resolve('data/package_config.json');

  CompilerResult? compilerResult = await compileScript(
      {'main.dart': bootstrapMacroIsolate(macroDeclarations)},
      options: options, requireMain: false);
  Uri uri = directory.absolute.uri.resolve('macros.dill');
  await writeComponentToFile(compilerResult!.component!, uri);
  return uri;
}

Future<void> main(List<String> args) async {
  enableMacros = true;

  Directory tempDirectory =
      await Directory.systemTemp.createTemp('macro_application');

  Uri macrosUri = await compileMacros(tempDirectory);
  Map<MacroClass, Uri> precompiledMacroUris = {};
  macroDeclarations
      .forEach((String macroUri, Map<String, List<String>> macroClasses) {
    macroClasses.forEach((String macroClass, List<String> constructorNames) {
      precompiledMacroUris[new MacroClass(Uri.parse(macroUri), macroClass)] =
          macrosUri;
    });
  });

  Directory dataDir =
      new Directory.fromUri(Platform.script.resolve('data/tests'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const MacroDataComputer(),
          [new MacroTestConfig(precompiledMacroUris)]),
      preserveWhitespaceInAnnotations: true);
}

class MacroTestConfig extends TestConfig {
  final Map<MacroClass, Uri> precompiledMacroUris;

  MacroTestConfig(this.precompiledMacroUris)
      : super(cfeMarker, 'cfe',
            explicitExperimentalFlags: {ExperimentalFlag.macros: true},
            packageConfigUri:
                Platform.script.resolve('data/package_config.json'));

  @override
  void customizeCompilerOptions(CompilerOptions options, TestData testData) {
    options.macroExecutorProvider = () async {
      return await isolatedExecutor.start();
    };
    options.precompiledMacroUris = precompiledMacroUris;
  }
}

class MacroDataComputer extends DataComputer<String> {
  const MacroDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  void computeMemberData(TestResultData testResultData, Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool? verbose}) {
    CfeDataRegistry<String> registry =
        new CfeDataRegistry(testResultData.compilerResult, actualMap);
    MacroApplicationDataForTesting macroApplicationData = testResultData
        .compilerResult
        .kernelTargetForTesting!
        .loader
        .dataForTesting!
        .macroApplicationData;
    StringBuffer sb = new StringBuffer();
    for (MapEntry<MemberBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.memberTypesResults.entries) {
      if (entry.key.member == member) {
        for (MacroExecutionResult result in entry.value) {
          sb.write('\n${codeToString(result.augmentations.first)}');
        }
      }
    }
    for (MapEntry<MemberBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.memberDeclarationsResults.entries) {
      if (entry.key.member == member) {
        for (MacroExecutionResult result in entry.value) {
          sb.write('\n${codeToString(result.augmentations.first)}');
        }
      }
    }
    for (MapEntry<MemberBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.memberDefinitionsResults.entries) {
      if (entry.key.member == member) {
        for (MacroExecutionResult result in entry.value) {
          sb.write('\n${codeToString(result.augmentations.first)}');
        }
      }
    }
    if (sb.isNotEmpty) {
      Id id = computeMemberId(member);
      registry.registerValue(
          member.fileUri, member.fileOffset, id, sb.toString(), member);
    }
  }
}

void _codeToString(StringBuffer sb, Code code) {
  for (Object part in code.parts) {
    if (part is Code) {
      _codeToString(sb, part);
    } else if (part is TypeAnnotation) {
      _codeToString(sb, part.code);
    } else {
      sb.write(part);
    }
  }
}

String codeToString(Code code) {
  StringBuffer sb = new StringBuffer();
  _codeToString(sb, code);
  return sb.toString();
}
