// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';

import 'package:front_end/src/fasta/builder/class_builder.dart';
import 'package:front_end/src/fasta/builder/extension_builder.dart';
import 'package:front_end/src/fasta/builder/formal_parameter_builder.dart';
import 'package:front_end/src/fasta/builder/function_builder.dart';
import 'package:front_end/src/fasta/builder/library_builder.dart';
import 'package:front_end/src/fasta/builder/member_builder.dart';
import 'package:front_end/src/fasta/builder/type_builder.dart';
import 'package:front_end/src/fasta/builder/type_variable_builder.dart';
import 'package:front_end/src/fasta/source/source_library_builder.dart';
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
      runTest: runTestFor(const ExtensionsDataComputer(), [
        new TestConfig(cfeMarker, 'cfe',
            librariesSpecificationUri: createUriForFileName('libraries.json'),
            allowedExperimentalFlags: const AllowedExperimentalFlags())
      ]));
}

class ExtensionsDataComputer extends DataComputer<Features> {
  const ExtensionsDataComputer();

  @override
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    member.accept(new ExtensionsDataExtractor(compilerResult, actualMap));
  }

  @override
  void computeClassData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Class cls,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new ExtensionsDataExtractor(compilerResult, actualMap).computeForClass(cls);
  }

  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new ExtensionsDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  void computeExtensionData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Extension extension,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new ExtensionsDataExtractor(compilerResult, actualMap)
        .computeForExtension(extension);
  }

  @override
  bool get supportsErrors => true;

  @override
  Features computeErrorData(TestConfig config, InternalCompilerResult compiler,
      Id id, List<FormattedMessage> errors) {
    Features features = new Features();
    for (FormattedMessage error in errors) {
      if (error.message.contains(',')) {
        // TODO(johnniwinther): Support escaping of , in Features.
        features.addElement(Tags.errors, error.code);
      } else {
        features.addElement(Tags.errors, error.message);
      }
    }
    return features;
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
  static const String builderOnType = 'builder-onType';
  static const String builderRequiredParameters = 'builder-params';
  static const String builderPositionalParameters = 'builder-pos-params';
  static const String builderNamedParameters = 'builder-named-params';
  static const String builderScope = 'scope';

  static const String clsName = 'cls-name';
  static const String clsTypeParameters = 'cls-type-params';
  static const String clsSupertype = 'cls-supertype';
  static const String clsInterfaces = 'cls-interfaces';

  static const String extensionName = 'extension-name';
  static const String extensionTypeParameters = 'extension-type-params';
  static const String extensionOnType = 'extension-onType';
  static const String extensionMembers = 'extension-members';

  static const String memberName = 'member-name';
  static const String memberTypeParameters = 'member-type-params';
  static const String memberRequiredParameters = 'member-params';
  static const String memberPositionalParameters = 'member-pos-params';
  static const String memberNamedParameters = 'member-named-params';

  static const String errors = 'errors';

  static const String hasThis = 'this';
}

class ExtensionsDataExtractor extends CfeDataExtractor<Features> {
  ExtensionsDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<Features>> actualMap)
      : super(compilerResult, actualMap);

  @override
  Features computeLibraryValue(Id id, Library library) {
    Features features = new Features();
    SourceLibraryBuilder libraryBuilder =
        lookupLibraryBuilder(compilerResult, library);
    libraryBuilder.forEachExtensionInScope((ExtensionBuilder extension) {
      LibraryBuilder library = extension.parent;
      String libraryPrefix = '';
      if (library != libraryBuilder) {
        libraryPrefix = '${library.fileUri.pathSegments.last}.';
      }
      features.addElement(Tags.builderScope, '$libraryPrefix${extension.name}');
    });
    return features;
  }

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

    features[Tags.builderSupertype] = clsBuilder.supertypeBuilder?.name;
    if (clsBuilder.interfaceBuilders != null) {
      for (TypeBuilder superinterface in clsBuilder.interfaceBuilders) {
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
  Features computeExtensionValue(Id id, Extension extension) {
    ExtensionBuilder extensionBuilder =
        lookupExtensionBuilder(compilerResult, extension);
    if (!extensionBuilder.isExtension) {
      return null;
    }
    Features features = new Features();
    features[Tags.builderName] = extensionBuilder.name;
    if (extensionBuilder.typeParameters != null) {
      for (TypeVariableBuilder typeVariable
          in extensionBuilder.typeParameters) {
        features.addElement(Tags.builderTypeParameters,
            typeVariableBuilderToText(typeVariable));
      }
    }
    if (extensionBuilder.onType != null) {
      features[Tags.builderOnType] = typeBuilderToText(extensionBuilder.onType);
    }

    features[Tags.extensionName] = extension.name;
    if (extension.onType != null) {
      features[Tags.extensionOnType] = typeToText(extension.onType);
    }
    for (TypeParameter typeParameter in extension.typeParameters) {
      features.addElement(
          Tags.extensionTypeParameters, typeParameterToText(typeParameter));
    }
    for (ExtensionMemberDescriptor descriptor in extension.members) {
      features.addElement(
          Tags.extensionMembers, extensionMethodDescriptorToText(descriptor));
    }
    return features;
  }

  @override
  Features computeMemberValue(Id id, Member member) {
    if (!member.isExtensionMember) {
      return null;
    }

    MemberBuilder memberBuilder = lookupMemberBuilder(compilerResult, member);
    Features features = new Features();
    features[Tags.builderName] = memberBuilder.name;
    if (memberBuilder is FunctionBuilder) {
      if (memberBuilder.formals != null) {
        for (FormalParameterBuilder parameter in memberBuilder.formals) {
          if (parameter.isRequired) {
            features.addElement(Tags.builderRequiredParameters, parameter.name);
          } else if (parameter.isPositional) {
            features.addElement(
                Tags.builderPositionalParameters, parameter.name);
          } else {
            assert(parameter.isNamed);
            features.addElement(Tags.builderNamedParameters, parameter.name);
          }
        }
        features.markAsUnsorted(Tags.builderRequiredParameters);
        features.markAsUnsorted(Tags.builderPositionalParameters);
        features.markAsUnsorted(Tags.builderNamedParameters);
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
      for (int index = 0;
          index < member.function.positionalParameters.length;
          index++) {
        VariableDeclaration parameter =
            member.function.positionalParameters[index];
        if (index < member.function.requiredParameterCount) {
          features.addElement(Tags.memberRequiredParameters, parameter.name);
        } else {
          features.addElement(Tags.memberPositionalParameters, parameter.name);
        }
      }
      for (VariableDeclaration parameter in member.function.namedParameters) {
        features.addElement(Tags.memberNamedParameters, parameter.name);
      }
      features.markAsUnsorted(Tags.memberRequiredParameters);
      features.markAsUnsorted(Tags.memberPositionalParameters);
      features.markAsUnsorted(Tags.memberNamedParameters);
      for (TypeParameter typeParameter in member.function.typeParameters) {
        features.addElement(
            Tags.memberTypeParameters, typeParameterToText(typeParameter));
      }
      features.markAsUnsorted(Tags.memberTypeParameters);
    }
    return features;
  }

  @override
  Features computeNodeValue(Id id, TreeNode node) {
    if (node is ThisExpression) {
      Features features = new Features();
      features.add(Tags.hasThis);
      return features;
    }
    return null;
  }
}
