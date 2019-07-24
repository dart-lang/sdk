// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:front_end/src/fasta/builder/builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/features.dart';
import 'package:front_end/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:front_end/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart'
    show
        CfeDataExtractor,
        CompilerResult,
        DataComputer,
        cfeExtensionMethodsConfig,
        createUriForFileName,
        onFailure,
        runTestFor;
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart' show Class, Member, TreeNode;
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const ExtensionsDataComputer(), [cfeExtensionMethodsConfig]));
}

class ExtensionsDataComputer extends DataComputer<Features> {
  const ExtensionsDataComputer();

  @override
  void computeMemberData(CompilerResult compilerResult, Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    member.accept(new ExtensionsDataExtractor(compilerResult, actualMap));
  }

  @override
  void computeClassData(CompilerResult compilerResult, Class cls,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new ExtensionsDataExtractor(compilerResult, actualMap).computeForClass(cls);
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class Tags {
  static const String builderName = 'builder-name';
  static const String builderTypeParameters = 'builder-type-params';
  static const String builderSupertype = 'builder-supertype';
  static const String builderInterfaces = 'builder-interfaces';
  static const String builderOnTypes = 'builder-onTypes';
  static const String builderParameters = 'builder-params';

  static const String clsName = 'cls-name';
  static const String clsTypeParameters = 'cls-type-params';
  static const String clsSupertype = 'cls-supertype';
  static const String clsInterfaces = 'cls-interfaces';

  static const String memberName = 'member-name';
  static const String memberTypeParameters = 'member-type-params';
  static const String memberParameters = 'member-params';
}

class ExtensionsDataExtractor extends CfeDataExtractor<Features> {
  ExtensionsDataExtractor(
      CompilerResult compilerResult, Map<Id, ActualData<Features>> actualMap)
      : super(compilerResult, actualMap);

  @override
  Features computeClassValue(Id id, Class cls) {
    ClassBuilder clsBuilder = lookupClassBuilder(compilerResult, cls);
    if (!clsBuilder.isExtension) {
      return null;
    }
    Features features = new Features();
    features[Tags.builderName] = clsBuilder.name;
    if (clsBuilder.typeVariables != null) {
      for (TypeVariableBuilder typeVariable in clsBuilder.typeVariables) {
        features.addElement(Tags.builderTypeParameters,
            typeVariableBuilderToText(typeVariable));
      }
    }

    features[Tags.builderSupertype] = clsBuilder.supertype?.name;
    if (clsBuilder.interfaces != null) {
      for (TypeBuilder superinterface in clsBuilder.interfaces) {
        features.addElement(Tags.builderInterfaces, superinterface.name);
      }
    }
    if (clsBuilder.onTypes != null) {
      for (TypeBuilder onType in clsBuilder.onTypes) {
        features.addElement(Tags.builderOnTypes, typeBuilderToText(onType));
      }
    }

    features[Tags.clsName] = cls.name;
    for (TypeParameter typeParameter in cls.typeParameters) {
      features.addElement(
          Tags.clsTypeParameters, typeParameterToText(typeParameter));
    }
    features[Tags.clsSupertype] = cls.supertype?.classNode?.name;
    for (Supertype superinterface in cls.implementedTypes) {
      features.addElement(Tags.clsInterfaces, superinterface.classNode.name);
    }
    return features;
  }

  @override
  Features computeNodeValue(Id id, TreeNode node) {
    return null;
  }

  @override
  Features computeMemberValue(Id id, Member member) {
    if (member.enclosingClass == null) {
      return null;
    }
    ClassBuilder clsBuilder =
        lookupClassBuilder(compilerResult, member.enclosingClass);
    if (!clsBuilder.isExtension) {
      return null;
    }
    MemberBuilder memberBuilder = lookupMemberBuilder(compilerResult, member);
    Features features = new Features();
    features[Tags.builderName] = memberBuilder.name;
    if (memberBuilder is ProcedureBuilder) {
      if (memberBuilder.formals != null) {
        for (FormalParameterBuilder parameter in memberBuilder.formals) {
          features.addElement(Tags.builderParameters, parameter.name);
        }
        features.markAsUnsorted(Tags.builderParameters);
      }
      if (memberBuilder.typeVariables != null) {
        for (TypeVariableBuilder typeVariable in memberBuilder.typeVariables) {
          features.addElement(Tags.builderTypeParameters,
              typeVariableBuilderToText(typeVariable));
        }
        features.markAsUnsorted(Tags.builderTypeParameters);
      }
    }
    features[Tags.memberName] = getMemberName(member);
    if (member.function != null) {
      for (VariableDeclaration parameter
          in member.function.positionalParameters) {
        features.addElement(Tags.memberParameters, parameter.name);
      }
      features.markAsUnsorted(Tags.memberParameters);
      for (TypeParameter typeParameter in member.function.typeParameters) {
        features.addElement(
            Tags.memberTypeParameters, typeParameterToText(typeParameter));
      }
      features.markAsUnsorted(Tags.memberTypeParameters);
    }
    return features;
  }
}
