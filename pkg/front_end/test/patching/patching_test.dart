// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/fasta/builder/builder.dart';
import 'package:front_end/src/fasta/builder/class_builder.dart';

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<Features>(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const PatchingDataComputer(), [
        new TestConfig(cfeMarker, 'cfe with libraries specification',
            librariesSpecificationUri: createUriForFileName('libraries.json'))
      ]));
}

class PatchingDataComputer extends DataComputer<Features> {
  const PatchingDataComputer();

  @override
  void computeMemberData(InternalCompilerResult compilerResult, Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    member.accept(new PatchingDataExtractor(compilerResult, actualMap));
  }

  @override
  void computeClassData(InternalCompilerResult compilerResult, Class cls,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new PatchingDataExtractor(compilerResult, actualMap).computeForClass(cls);
  }

  void computeLibraryData(InternalCompilerResult compilerResult,
      Library library, Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new PatchingDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class Tags {
  static const String scope = 'scope';
  static const String kernelMembers = 'kernel-members';
  static const String initializers = 'initializers';
}

class PatchingDataExtractor extends CfeDataExtractor<Features> {
  PatchingDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<Features>> actualMap)
      : super(compilerResult, actualMap);

  @override
  Features computeClassValue(Id id, Class cls) {
    ClassBuilder clsBuilder = lookupClassBuilder(compilerResult, cls);

    Features features = new Features();
    clsBuilder.scope.forEach((String name, Builder builder) {
      features.addElement(Tags.scope, name);
    });

    for (Member m in clsBuilder.actualCls.members) {
      String name = m.name.name;
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
