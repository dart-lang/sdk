// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/base/scope.dart';
import 'package:front_end/src/builder/builder.dart';
import 'package:front_end/src/source/source_class_builder.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';

import '../utils/symbolic_language_versions.dart';

Future<void> main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<Features>(
    dataDir,
    args: args,
    createUriForFileName: createUriForFileName,
    onFailure: onFailure,
    runTest: runTestFor(const PatchingDataComputer(), [
      new TestConfigWithLanguageVersion(
        cfeMarker,
        'cfe',
        librariesSpecificationUri: createUriForFileName('libraries.json'),
        experimentalFlags: {},
        allowedExperimentalFlags: const AllowedExperimentalFlags(),
      ),
    ]),
    preProcessFile: replaceMarkersWithVersions,
    postProcessFile: replaceVersionsWithMarkers,
  );
}

class TestConfigWithLanguageVersion extends CfeTestConfig {
  TestConfigWithLanguageVersion(
    String marker,
    String name, {
    Uri? librariesSpecificationUri,
    Map<ExperimentalFlag, bool> experimentalFlags = const {},
    AllowedExperimentalFlags? allowedExperimentalFlags,
  }) : super(
         marker,
         name,
         librariesSpecificationUri: librariesSpecificationUri,
         explicitExperimentalFlags: experimentalFlags,
         allowedExperimentalFlags: allowedExperimentalFlags,
       );

  @override
  void customizeCompilerOptions(CompilerOptions options, TestData testData) {
    options.currentSdkVersion = SymbolicLanguageVersion.currentVersion.version
        .toText();
  }
}

class PatchingDataComputer extends CfeDataComputer<Features> {
  const PatchingDataComputer();

  @override
  void computeMemberData(
    CfeTestResultData testResultData,
    Member member,
    Map<Id, ActualData<Features>> actualMap, {
    bool? verbose,
  }) {
    member.accept(
      new PatchingDataExtractor(testResultData.compilerResult, actualMap),
    );
  }

  @override
  void computeClassData(
    CfeTestResultData testResultData,
    Class cls,
    Map<Id, ActualData<Features>> actualMap, {
    bool? verbose,
  }) {
    new PatchingDataExtractor(
      testResultData.compilerResult,
      actualMap,
    ).computeForClass(cls);
  }

  @override
  void computeLibraryData(
    CfeTestResultData testResultData,
    Library library,
    Map<Id, ActualData<Features>> actualMap, {
    bool? verbose,
  }) {
    new PatchingDataExtractor(
      testResultData.compilerResult,
      actualMap,
    ).computeForLibrary(library);
  }

  @override
  bool get supportsErrors => true;

  @override
  Features computeErrorData(
    CfeTestResultData testResultData,
    Id id,
    List<FormattedMessage> errors,
  ) {
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
  static const String patch = 'patch';
  static const String isAbstract = 'isAbstract';
}

class PatchingDataExtractor extends CfeDataExtractor<Features> {
  PatchingDataExtractor(
    InternalCompilerResult compilerResult,
    Map<Id, ActualData<Features>> actualMap,
  ) : super(compilerResult, actualMap);

  @override
  Features computeClassValue(Id id, Class cls) {
    SourceClassBuilder clsBuilder =
        lookupClassBuilder(compilerResult, cls) as SourceClassBuilder;

    Features features = new Features();
    if (cls.isAbstract) {
      features.add(Tags.isAbstract);
    }
    clsBuilder.filteredMembersIterator(includeDuplicates: false).forEach((
      NamedBuilder builder,
    ) {
      features.addElement(Tags.scope, builder.name);
    });

    for (Member m in clsBuilder.cls.members) {
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
    return features;
  }
}
