// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/isolated_executor/isolated_executor.dart'
    as isolatedExecutor;
import 'package:_fe_analyzer_shared/src/testing/id.dart'
    show ActualData, ClassId, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/builder/field_builder.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';
import 'package:front_end/src/fasta/kernel/macro.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/source/source_class_builder.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart' hide Arguments;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:vm/target/vm.dart';

Future<void> main(List<String> args) async {
  enableMacros = true;

  Directory tempDirectory =
      await Directory.systemTemp.createTemp('macro_application');
  try {
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('data/tests'));
    await runTests<String>(dataDir,
        args: args,
        createUriForFileName: createUriForFileName,
        onFailure: onFailure,
        runTest: runTestFor(
            const MacroDataComputer(), [new MacroTestConfig(tempDirectory)]),
        preserveWhitespaceInAnnotations: true);
  } finally {
    await tempDirectory.delete(recursive: true);
  }
}

class MacroTestConfig extends TestConfig {
  final Directory tempDirectory;
  int precompiledCount = 0;
  final Map<MacroClass, Uri> precompiledMacroUris = {};

  MacroTestConfig(this.tempDirectory)
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
    options.macroTarget = new VmTarget(new TargetFlags());
    options.macroSerializer = (Component component) async {
      Uri uri = tempDirectory.absolute.uri
          .resolve('macros${precompiledCount++}.dill');
      await writeComponentToFile(component, uri);
      return uri;
    };
  }
}

bool _isMember(MemberBuilder memberBuilder, Member member) {
  if (memberBuilder is FieldBuilder) {
    // Only show annotations for the field or getter.
    return memberBuilder.readTarget == member;
  } else if (member is Procedure && member.isSetter) {
    return memberBuilder.writeTarget == member;
  } else if (member is Procedure && member.isGetter) {
    return memberBuilder.readTarget == member;
  } else {
    return memberBuilder.invokeTarget == member;
  }
}

class MacroDataComputer extends DataComputer<String> {
  const MacroDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  void computeClassData(TestResultData testResultData, Class cls,
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
    for (MapEntry<SourceClassBuilder, String> entry
        in macroApplicationData.classTypesResults.entries) {
      if (entry.key.cls == cls) {
        sb.write('\n${entry.value.trim()}');
      }
    }
    for (MapEntry<SourceClassBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.classDeclarationsResults.entries) {
      if (entry.key.cls == cls) {
        for (MacroExecutionResult result in entry.value) {
          sb.write('\n${codeToString(result.augmentations.first)}');
        }
      }
    }
    for (MapEntry<SourceClassBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.classDefinitionsResults.entries) {
      if (entry.key.cls == cls) {
        for (MacroExecutionResult result in entry.value) {
          sb.write('\n${codeToString(result.augmentations.first)}');
        }
      }
    }
    if (sb.isNotEmpty) {
      Id id = new ClassId(cls.name);
      registry.registerValue(
          cls.fileUri, cls.fileOffset, id, sb.toString(), cls);
    }
  }

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
    for (MapEntry<MemberBuilder, String> entry
        in macroApplicationData.memberTypesResults.entries) {
      if (_isMember(entry.key, member)) {
        sb.write('\n${entry.value.trim()}');
      }
    }
    for (MapEntry<MemberBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.memberDeclarationsResults.entries) {
      if (_isMember(entry.key, member)) {
        for (MacroExecutionResult result in entry.value) {
          sb.write('\n${codeToString(result.augmentations.first)}');
        }
      }
    }
    for (MapEntry<MemberBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.memberDefinitionsResults.entries) {
      if (_isMember(entry.key, member)) {
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
    } else if (part is Identifier) {
      sb.write(part.name);
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
