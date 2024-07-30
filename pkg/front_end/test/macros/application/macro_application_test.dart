// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart'
    show ActualData, ClassId, Id, LibraryId;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/builder/field_builder.dart';
import 'package:front_end/src/builder/member_builder.dart';
import 'package:front_end/src/kernel/macro/macro.dart';
import 'package:front_end/src/kernel/macro/offset_checker.dart';
import 'package:front_end/src/macros/macro_serializer.dart';
import 'package:front_end/src/macros/temp_dir_macro_serializer.dart';
import 'package:front_end/src/source/source_class_builder.dart';
import 'package:front_end/src/source/source_library_builder.dart';
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' hide Arguments;
import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:macros/macros.dart' hide Library;
import 'package:macros/src/executor.dart';

import '../../utils/kernel_chain.dart';

Future<void> main(List<String> args) async {
  bool generateExpectations = args.contains('-g');

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

class MacroTestConfig extends CfeTestConfig {
  final Directory dataDir;
  final MacroSerializer macroSerializer;
  final bool generateExpectations;
  final List<String> offsetErrors = [];

  MacroTestConfig(this.dataDir, this.macroSerializer,
      {required this.generateExpectations})
      : super(cfeMarker, 'cfe',
            explicitExperimentalFlags: {ExperimentalFlag.macros: true},
            packageConfigUri:
                Platform.script.resolve('data/package_config.json'));

  @override
  void customizeCompilerOptions(CompilerOptions options, TestData testData) {
    options.macroSerializer = macroSerializer;
    options.hooksForTesting = new MacroOffsetCheckerHook(offsetErrors);
  }

  @override
  Future<void> onCompilationResult(MarkerOptions markerOptions,
      TestData testData, CfeTestResultData testResultData) async {
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
          print("ERROR: ${testData.name} don't match ${expectedUri}\n$diff");
          onFailure(generateErrorMessage(markerOptions, mismatches: {
            testData.name: {testResultData.config.marker}
          }));
        }
      }
    } else if (generateExpectations) {
      file.writeAsStringSync(actual);
    } else {
      print('Please use -g option to create file ${expectedUri} with this '
          'content:\n$actual');
      onFailure(generateErrorMessage(markerOptions, errors: {
        testData.name: {testResultData.config.marker}
      }));
    }
    if (offsetErrors.isNotEmpty) {
      offsetErrors.forEach(print);
      offsetErrors.clear();
      print("ERROR: ${testData.name} has macro offset errors.");
      onFailure(generateErrorMessage(markerOptions, errors: {
        testData.name: {testResultData.config.marker}
      }));
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

class MacroDataComputer extends CfeDataComputer<String> {
  const MacroDataComputer();

  @override
  bool get supportsErrors => true;

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  void computeLibraryData(CfeTestResultData testResultData, Library library,
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
    for (MapEntry<SourceLibraryBuilder, MacroExecutionResultsForTesting> entry
        in macroApplicationData.libraryResults.entries) {
      if (entry.key.library == library) {
        String resultsText = macroExecutionResultsToText(entry.value);
        if (resultsText.isNotEmpty) {
          sb.write('\nApplications:');
          sb.write('\n$resultsText');
        }
      }
    }

    if (sb.isNotEmpty) {
      Id id = new LibraryId(library.fileUri);
      registry.registerValue(
          library.fileUri, library.fileOffset, id, sb.toString(), library);
    }
  }

  @override
  void computeClassData(CfeTestResultData testResultData, Class cls,
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

    for (MapEntry<SourceClassBuilder, MacroExecutionResultsForTesting> entry
        in macroApplicationData.classResults.entries) {
      if (entry.key.cls == cls) {
        String resultsText =
            macroExecutionResultsToText(entry.value, className: cls.name);
        if (resultsText.isNotEmpty) {
          Id id = new ClassId(cls.name);
          registry.registerValue(
              cls.fileUri, cls.fileOffset, id, '\n$resultsText', cls);
        }
      }
    }
  }

  @override
  void computeMemberData(CfeTestResultData testResultData, Member member,
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

    for (MapEntry<MemberBuilder, MacroExecutionResultsForTesting> entry
        in macroApplicationData.memberResults.entries) {
      if (_isMember(entry.key, member)) {
        String resultsText = macroExecutionResultsToText(entry.value);
        Id id = computeMemberId(member);
        MemberBuilder memberBuilder =
            lookupMemberBuilder(testResultData.compilerResult, member)!;
        if (resultsText.isNotEmpty) {
          registry.registerValue(memberBuilder.fileUri!,
              memberBuilder.charOffset, id, '\n$resultsText', member);
        }
      }
    }
  }
}

String macroExecutionResultsToText(MacroExecutionResultsForTesting results,
    {String? className}) {
  StringBuffer sb = new StringBuffer();

  StringBuffer typesSources = new StringBuffer();
  List<DeclarationCode> mergedClassTypes = [];

  for (MacroExecutionResult result in results.typesResults) {
    if (result.libraryAugmentations.isNotEmpty) {
      if (result.libraryAugmentations.isNotEmpty) {
        typesSources
            .write('\n${codeToString(result.libraryAugmentations.single)}');
      }
      for (var identifier in result.typeAugmentations.keys) {
        if (identifier.name == className) {
          mergedClassTypes.addAll(result.typeAugmentations[identifier]!);
        }
      }
    }
  }

  if (mergedClassTypes.isNotEmpty) {
    typesSources.write('\naugment class ${className} {');
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
  for (String result in results.declarationsSources) {
    if (result.isNotEmpty) {
      declarationsSources.write('\n${result}');
    }
  }

  if (declarationsSources.isNotEmpty) {
    sb.write('declarations:');
    sb.write(declarationsSources);
  }

  StringBuffer definitionsSources = new StringBuffer();
  List<DeclarationCode> mergedClassDefinitions = [];
  for (MacroExecutionResult result in results.definitionsResults) {
    if (result.libraryAugmentations.isNotEmpty) {
      definitionsSources
          .write('\n${codeToString(result.libraryAugmentations.single)}');
    }
    for (var identifier in result.typeAugmentations.keys) {
      if (identifier.name == className) {
        mergedClassDefinitions.addAll(result.typeAugmentations[identifier]!);
      }
    }
  }

  if (mergedClassDefinitions.isNotEmpty) {
    definitionsSources.write('\naugment class ${className} {');
    for (var result in mergedClassDefinitions) {
      definitionsSources.write('\n${codeToString(result)}');
    }
    definitionsSources.write('\n}');
  }
  if (definitionsSources.isNotEmpty) {
    sb.write('definitions:');
    sb.write(definitionsSources);
  }

  return sb.toString();
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
