// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, Platform;

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart'
    show ActualData, ClassId, Id, LibraryId;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/builder/field_builder.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';
import 'package:front_end/src/fasta/kernel/macro/macro.dart';
import 'package:front_end/src/fasta/source/source_class_builder.dart';
import 'package:front_end/src/fasta/source/source_library_builder.dart';
import 'package:front_end/src/macro_serializer.dart';
import 'package:front_end/src/temp_dir_macro_serializer.dart';
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' hide Arguments;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:vm/target/vm.dart';

import '../../utils/kernel_chain.dart';

Future<void> main(List<String> args) async {
  bool generateExpectations = args.contains('-g');
  enableMacros = true;

  MacroSerializer macroSerializer =
      new TempDirMacroSerializer('macro_application');
  try {
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('data/tests'));
    await runTests<String>(dataDir,
        args: args,
        createUriForFileName: createUriForFileName,
        onFailure: onFailure,
        runTest: runTestFor(const MacroDataComputer(), [
          new MacroTestConfig(dataDir, macroSerializer,
              generateExpectations: generateExpectations)
        ]),
        preserveWhitespaceInAnnotations: true);
  } finally {
    await macroSerializer.close();
  }
}

class MacroTestConfig extends TestConfig {
  final Directory dataDir;
  final MacroSerializer macroSerializer;
  final bool generateExpectations;

  MacroTestConfig(this.dataDir, this.macroSerializer,
      {required this.generateExpectations})
      : super(cfeMarker, 'cfe',
            explicitExperimentalFlags: {ExperimentalFlag.macros: true},
            packageConfigUri:
                Platform.script.resolve('data/package_config.json'));

  @override
  void customizeCompilerOptions(CompilerOptions options, TestData testData) {
    options.macroTarget = new VmTarget(new TargetFlags());
    options.macroSerializer = macroSerializer;
  }

  @override
  Future<void> onCompilationResult(
      TestData testData, TestResultData testResultData) async {
    Component component = testResultData.compilerResult.component!;
    StringBuffer buffer = new StringBuffer();
    Printer printer = new Printer(buffer)
      ..writeProblemsAsJson("Problems in component", component.problemsAsJson);
    component.libraries.forEach((Library library) {
      if (isTestUri(library.importUri)) {
        printer.writeLibraryFile(library);
        printer.endLine();
      }
    });
    printer.writeConstantTable(component);
    String actual = buffer.toString();
    String expectationFileName = '${testData.name}.expect';
    Uri expectedUri = dataDir.uri.resolve(expectationFileName);
    File file = new File.fromUri(expectedUri);
    if (file.existsSync()) {
      String expected = file.readAsStringSync();
      if (expected != actual) {
        if (generateExpectations) {
          file.writeAsStringSync(actual);
        } else {
          String diff = await runDiff(expectedUri, actual);
          throw "${testData.name} don't match ${expectedUri}\n$diff";
        }
      }
    } else if (generateExpectations) {
      file.writeAsStringSync(actual);
    } else {
      throw 'Please use -g option to create file ${expectedUri} with this '
          'content:\n$actual';
    }
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
  void computeLibraryData(TestResultData testResultData, Library library,
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
    if (testResultData.compilerResult.kernelTargetForTesting!.loader.roots
        .contains(library.importUri)) {
      if (macroApplicationData.typesApplicationOrder.isNotEmpty) {
        sb.write('\nTypes Order:');
        for (ApplicationDataForTesting application
            in macroApplicationData.typesApplicationOrder) {
          sb.write('\n ${application}');
        }
      }
      if (macroApplicationData.declarationsApplicationOrder.isNotEmpty) {
        sb.write('\nDeclarations Order:');
        for (ApplicationDataForTesting application
            in macroApplicationData.declarationsApplicationOrder) {
          sb.write('\n ${application}');
        }
      }
      if (macroApplicationData.definitionApplicationOrder.isNotEmpty) {
        sb.write('\nDefinition Order:');
        for (ApplicationDataForTesting application
            in macroApplicationData.definitionApplicationOrder) {
          sb.write('\n ${application}');
        }
      }
    }
    for (SourceLibraryBuilder sourceLibraryBuilder
        in macroApplicationData.libraryTypesResult.keys) {
      if (sourceLibraryBuilder.library == library) {
        String source =
            macroApplicationData.libraryTypesResult[sourceLibraryBuilder]!;
        sb.write('\nTypes:');
        sb.write('\n${source}');
      }
    }
    for (SourceLibraryBuilder sourceLibraryBuilder
        in macroApplicationData.libraryDefinitionResult.keys) {
      if (sourceLibraryBuilder.library == library) {
        String source =
            macroApplicationData.libraryDefinitionResult[sourceLibraryBuilder]!;
        sb.write('\nDefinitions:');
        sb.write('\n${source}');
      }
    }
    if (sb.isNotEmpty) {
      Id id = new LibraryId(library.fileUri);
      registry.registerValue(
          library.fileUri, library.fileOffset, id, sb.toString(), library);
    }
  }

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

    StringBuffer typesSources = new StringBuffer();
    List<DeclarationCode> mergedClassTypes = [];
    for (MapEntry<SourceClassBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.classTypesResults.entries) {
      if (entry.key.cls == cls) {
        for (MacroExecutionResult result in entry.value) {
          if (result.libraryAugmentations.isNotEmpty) {
            if (result.libraryAugmentations.isNotEmpty) {
              typesSources.write(
                  '\n${codeToString(result.libraryAugmentations.single)}');
            }
            for (var identifier in result.typeAugmentations.keys) {
              if (identifier.name == entry.key.name) {
                mergedClassTypes.addAll(result.typeAugmentations[identifier]!);
              }
            }
          }
        }
      }
    }
    if (mergedClassTypes.isNotEmpty) {
      typesSources.write('\naugment class ${cls.name} {');
      for (var result in mergedClassTypes) {
        typesSources.write('\n${codeToString(result)}');
      }
      typesSources.write('\n}');
    }
    if (typesSources.isNotEmpty) {
      sb.write('types:');
      sb.write(typesSources);
    }

    StringBuffer declarationsSources = new StringBuffer();
    for (MapEntry<SourceClassBuilder, List<String>> entry
        in macroApplicationData.classDeclarationsSources.entries) {
      if (entry.key.cls == cls) {
        for (String result in entry.value) {
          if (result.isNotEmpty) {
            declarationsSources.write('\n${result}');
          }
        }
      }
    }
    if (declarationsSources.isNotEmpty) {
      sb.write('declarations:');
      sb.write(declarationsSources);
    }

    StringBuffer definitionsSources = new StringBuffer();
    List<DeclarationCode> mergedClassDefinitions = [];
    for (MapEntry<SourceClassBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.classDefinitionsResults.entries) {
      if (entry.key.cls == cls) {
        for (MacroExecutionResult result in entry.value) {
          if (result.libraryAugmentations.isNotEmpty) {
            definitionsSources
                .write('\n${codeToString(result.libraryAugmentations.single)}');
          }
          for (var identifier in result.typeAugmentations.keys) {
            if (identifier.name == entry.key.name) {
              mergedClassDefinitions
                  .addAll(result.typeAugmentations[identifier]!);
            }
          }
        }
      }
    }
    if (mergedClassDefinitions.isNotEmpty) {
      definitionsSources.write('\naugment class ${cls.name} {');
      for (var result in mergedClassDefinitions) {
        definitionsSources.write('\n${codeToString(result)}');
      }
      definitionsSources.write('\n}');
    }
    if (definitionsSources.isNotEmpty) {
      sb.write('definitions:');
      sb.write(definitionsSources);
    }

    if (sb.isNotEmpty) {
      Id id = new ClassId(cls.name);
      registry.registerValue(cls.fileUri, cls.fileOffset, id, '\n$sb', cls);
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
    StringBuffer sb = StringBuffer();

    StringBuffer typesSources = new StringBuffer();
    for (MapEntry<MemberBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.memberTypesResults.entries) {
      if (_isMember(entry.key, member)) {
        for (MacroExecutionResult result in entry.value) {
          if (result.libraryAugmentations.isNotEmpty) {
            if (result.libraryAugmentations.isNotEmpty) {
              typesSources.write(
                  '\n${codeToString(result.libraryAugmentations.single)}');
            }
          }
        }
      }
    }
    if (typesSources.isNotEmpty) {
      sb.write('types:');
      sb.write(typesSources);
    }

    StringBuffer declarationsSources = new StringBuffer();
    for (MapEntry<MemberBuilder, List<String>> entry
        in macroApplicationData.memberDeclarationsSources.entries) {
      if (_isMember(entry.key, member)) {
        for (String result in entry.value) {
          if (result.isNotEmpty) {
            declarationsSources.write('\n${result}');
          }
        }
      }
    }
    if (declarationsSources.isNotEmpty) {
      sb.write('declarations:');
      sb.write(declarationsSources);
    }

    StringBuffer definitionsSources = new StringBuffer();
    for (MapEntry<MemberBuilder, List<MacroExecutionResult>> entry
        in macroApplicationData.memberDefinitionsResults.entries) {
      if (_isMember(entry.key, member)) {
        for (MacroExecutionResult result in entry.value) {
          if (result.libraryAugmentations.isNotEmpty) {
            definitionsSources
                .write('\n${codeToString(result.libraryAugmentations.single)}');
          }
        }
      }
    }
    if (definitionsSources.isNotEmpty) {
      sb.write('definitions:');
      sb.write(definitionsSources);
    }
    if (sb.isNotEmpty) {
      Id id = computeMemberId(member);
      MemberBuilder memberBuilder =
          lookupMemberBuilder(testResultData.compilerResult, member)!;
      registry.registerValue(memberBuilder.fileUri!, memberBuilder.charOffset,
          id, '\n$sb', member);
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
