// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/builder/builder.dart';
import 'package:front_end/src/fasta/builder/class_builder.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<Features>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const PatchingDataComputer(), [
        new TestConfigWithLanguageVersion(
            cfeMarker, 'cfe with libraries specification',
            librariesSpecificationUri: createUriForFileName('libraries.json'),
            experimentalFlags: {ExperimentalFlag.nonNullable: false},
            allowedExperimentalFlags: const AllowedExperimentalFlags()),
        new TestConfigWithLanguageVersion(cfeWithNnbdMarker,
            'cfe with libraries specification and non-nullable',
            librariesSpecificationUri: createUriForFileName('libraries.json'),
            experimentalFlags: {ExperimentalFlag.nonNullable: true},
            allowedExperimentalFlags: const AllowedExperimentalFlags())
      ]),
      skipMap: {
        cfeMarker: [
          'opt_in',
          'opt_in_patch',
          'opt_out',
          'opt_out_patch',
        ]
      });
}

class TestConfigWithLanguageVersion extends TestConfig {
  TestConfigWithLanguageVersion(String marker, String name,
      {Uri librariesSpecificationUri,
      Map<ExperimentalFlag, bool> experimentalFlags = const {},
      AllowedExperimentalFlags allowedExperimentalFlags})
      : super(marker, name,
            librariesSpecificationUri: librariesSpecificationUri,
            explicitExperimentalFlags: experimentalFlags,
            allowedExperimentalFlags: allowedExperimentalFlags);

  @override
  void customizeCompilerOptions(CompilerOptions options, TestData testData) {
    options.currentSdkVersion = "2.9999";
  }
}

class PatchingDataComputer extends DataComputer<Features> {
  const PatchingDataComputer();

  @override
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    member.accept(new PatchingDataExtractor(compilerResult, actualMap));
  }

  @override
  void computeClassData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Class cls,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new PatchingDataExtractor(compilerResult, actualMap).computeForClass(cls);
  }

  @override
  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new PatchingDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  bool get supportsErrors => true;

  @override
  Features computeErrorData(TestConfig config, InternalCompilerResult compiler,
      Id id, List<FormattedMessage> errors) {
    Features features = new Features();
    features[Tags.error] = errorsToText(errors);
    return features;
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class Tags {
  static const String scope = 'scope';
  static const String kernelMembers = 'kernel-members';
  static const String initializers = 'initializers';
  static const String error = 'message';
  static const String isNonNullableByDefault = 'nnbd';
  static const String patch = 'patch';
}

class PatchingDataExtractor extends CfeDataExtractor<Features> {
  PatchingDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<Features>> actualMap)
      : super(compilerResult, actualMap);

  @override
  Features computeLibraryValue(Id id, Library library) {
    Features features = new Features();
    features[Tags.isNonNullableByDefault] = '${library.isNonNullableByDefault}';
    return features;
  }

  @override
  Features computeClassValue(Id id, Class cls) {
    ClassBuilder clsBuilder = lookupClassBuilder(compilerResult, cls);

    Features features = new Features();
    clsBuilder.scope.forEach((String name, Builder builder) {
      features.addElement(Tags.scope, name);
    });

    for (Member m in clsBuilder.actualCls.members) {
      if (m is Procedure &&
          (m.isMemberSignature ||
              (m.isForwardingStub && !m.isForwardingSemiStub))) {
        // Don't include member signatures.
        continue;
      }
      String name = m.name.text;
      if (m is Constructor) {
        name = '${m.enclosingClass.name}.${name}';
      }
      features.addElement(Tags.kernelMembers, name);
    }

    return features;
  }

  @override
  Features computeMemberValue(Id id, Member member) {
    Features features = new Features();
    if (member is Constructor) {
      for (Initializer initializer in member.initializers) {
        String desc = initializer.runtimeType.toString();
        if (initializer is FieldInitializer) {
          desc = 'FieldInitializer(${getMemberName(initializer.field)})';
        }
        features.addElement(Tags.initializers, desc);
      }
    }
    MemberBuilderImpl memberBuilder =
        lookupMemberBuilder(compilerResult, member, required: false);
    MemberBuilder patchMember = memberBuilder?.dataForTesting?.patchForTesting;
    if (patchMember != null) {
      features.add(Tags.patch);
    }

    return features;
  }
}
