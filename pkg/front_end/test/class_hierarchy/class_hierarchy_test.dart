// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:front_end/src/fasta/kernel/class_hierarchy_builder.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<Features>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const ClassHierarchyDataComputer(), [cfeNonNullableConfig]));
}

class ClassHierarchyDataComputer extends DataComputer<Features> {
  const ClassHierarchyDataComputer();

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new InheritanceDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  void computeClassData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Class cls,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new InheritanceDataExtractor(compilerResult, actualMap)
        .computeForClass(cls);
  }

  @override
  bool get supportsErrors => true;

  @override
  Features computeErrorData(TestConfig config, InternalCompilerResult compiler,
      Id id, List<FormattedMessage> errors) {
    return null; //errorsToText(errors, useCodes: true);
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class Tag {
  static const String superclasses = 'superclasses';
  static const String interfaces = 'interfaces';
  static const String hasNoSuchMethod = 'hasNoSuchMethod';
  static const String abstractMembers = 'abstractMembers';
  static const String classBuilder = 'classBuilder';
  static const String isSourceDeclaration = 'isSourceDeclaration';
  static const String isSynthesized = 'isSynthesized';
  static const String member = 'member';
  static const String maxInheritancePath = 'maxInheritancePath';
  static const String declaredOverrides = 'declared-overrides';
  static const String mixinApplicationOverrides = 'mixin-overrides';
  static const String inheritedImplements = 'inherited-implements';
  static const String abstractForwardingStub = 'abstractForwardingStub';
  static const String concreteForwardingStub = 'concreteForwardingStub';
  static const String memberSignature = 'memberSignature';
  static const String abstractMixinStub = 'abstractMixinStub';
  static const String concreteMixinStub = 'concreteMixinStub';
  static const String declarations = 'declarations';
  static const String stubTarget = 'stubTarget';
  static const String type = 'type';
  static const String covariance = 'covariance';
}

class InheritanceDataExtractor extends CfeDataExtractor<Features> {
  final InternalCompilerResult _compilerResult;

  InheritanceDataExtractor(
      this._compilerResult, Map<Id, ActualData<Features>> actualMap)
      : super(_compilerResult, actualMap);

  CoreTypes get _coreTypes => _compilerResult.coreTypes;

  ClassHierarchyBuilder get _classHierarchyBuilder =>
      _compilerResult.kernelTargetForTesting.loader.builderHierarchy;

  @override
  void computeForClass(Class node) {
    super.computeForClass(node);
    ClassHierarchyNode classHierarchyNode =
        _classHierarchyBuilder.getNodeFromClass(node);
    ClassHierarchyNodeDataForTesting data = classHierarchyNode.dataForTesting;
    void addMember(ClassMember classMember,
        {bool isSetter, bool isClassMember}) {
      Member member = classMember.getMember(_classHierarchyBuilder);
      Member memberOrigin = member.memberSignatureOrigin ?? member;
      if (memberOrigin.enclosingClass == _coreTypes.objectClass) {
        return;
      }
      Features features = new Features();

      String memberName = classMemberName(classMember);
      memberName += isClassMember ? '#cls' : '#int';
      MemberId id = new MemberId.internal(memberName, className: node.name);

      TreeNode nodeWithOffset;
      if (member.enclosingClass == node) {
        nodeWithOffset = computeTreeNodeWithOffset(member);
      } else {
        nodeWithOffset = computeTreeNodeWithOffset(node);
      }
      if (classMember.isSourceDeclaration) {
        features.add(Tag.isSourceDeclaration);
      }
      if (classMember.isSynthesized) {
        features.add(Tag.isSynthesized);
        if (member.enclosingClass != node) {
          features[Tag.member] = memberQualifiedName(member);
        }
        if (classMember.hasDeclarations) {
          for (ClassMember declaration in classMember.declarations) {
            features.addElement(
                Tag.declarations, classMemberQualifiedName(declaration));
          }
        }
      }
      features[Tag.classBuilder] = classMember.classBuilder.name;

      Set<ClassMember> declaredOverrides =
          data.declaredOverrides[data.aliasMap[classMember] ?? classMember];
      if (declaredOverrides != null) {
        for (ClassMember override in declaredOverrides) {
          features.addElement(
              Tag.declaredOverrides, classMemberQualifiedName(override));
        }
      }

      Set<ClassMember> mixinApplicationOverrides = data
          .mixinApplicationOverrides[data.aliasMap[classMember] ?? classMember];
      if (mixinApplicationOverrides != null) {
        for (ClassMember override in mixinApplicationOverrides) {
          features.addElement(Tag.mixinApplicationOverrides,
              classMemberQualifiedName(override));
        }
      }

      Set<ClassMember> inheritedImplements =
          data.inheritedImplements[data.aliasMap[classMember] ?? classMember];
      if (inheritedImplements != null) {
        for (ClassMember implement in inheritedImplements) {
          features.addElement(
              Tag.inheritedImplements, classMemberQualifiedName(implement));
        }
      }

      if (member.enclosingClass == node && member is Procedure) {
        switch (member.stubKind) {
          case ProcedureStubKind.Regular:
            // TODO: Handle this case.
            break;
          case ProcedureStubKind.AbstractForwardingStub:
            features.add(Tag.abstractForwardingStub);
            features[Tag.type] = procedureType(member);
            features[Tag.covariance] =
                classMember.getCovariance(_classHierarchyBuilder).toString();
            break;
          case ProcedureStubKind.ConcreteForwardingStub:
            features.add(Tag.concreteForwardingStub);
            features[Tag.type] = procedureType(member);
            features[Tag.covariance] =
                classMember.getCovariance(_classHierarchyBuilder).toString();
            features[Tag.stubTarget] = memberQualifiedName(member.stubTarget);
            break;
          case ProcedureStubKind.NoSuchMethodForwarder:
            // TODO: Handle this case.
            break;
          case ProcedureStubKind.MemberSignature:
            features.add(Tag.memberSignature);
            features[Tag.type] = procedureType(member);
            features[Tag.covariance] =
                classMember.getCovariance(_classHierarchyBuilder).toString();
            break;
          case ProcedureStubKind.AbstractMixinStub:
            features.add(Tag.abstractMixinStub);
            break;
          case ProcedureStubKind.ConcreteMixinStub:
            features.add(Tag.concreteMixinStub);
            features[Tag.stubTarget] = memberQualifiedName(member.stubTarget);
            break;
        }
      }

      registerValue(nodeWithOffset?.location?.file, nodeWithOffset?.fileOffset,
          id, features, member);
    }

    classHierarchyNode.classMemberMap
        ?.forEach((Name name, ClassMember classMember) {
      addMember(classMember, isSetter: false, isClassMember: true);
    });
    classHierarchyNode.classSetterMap
        ?.forEach((Name name, ClassMember classMember) {
      addMember(classMember, isSetter: true, isClassMember: true);
    });
    classHierarchyNode.interfaceMemberMap
        ?.forEach((Name name, ClassMember classMember) {
      if (!identical(classMember, classHierarchyNode.classMemberMap[name])) {
        addMember(classMember, isSetter: false, isClassMember: false);
      }
    });
    classHierarchyNode.interfaceSetterMap
        ?.forEach((Name name, ClassMember classMember) {
      if (!identical(classMember, classHierarchyNode.classSetterMap[name])) {
        addMember(classMember, isSetter: true, isClassMember: false);
      }
    });
  }

  @override
  Features computeClassValue(Id id, Class node) {
    Features features = new Features();
    ClassHierarchyNode classHierarchyNode =
        _classHierarchyBuilder.getNodeFromClass(node);
    ClassHierarchyNodeDataForTesting data = classHierarchyNode.dataForTesting;
    classHierarchyNode.superclasses.forEach((Supertype supertype) {
      features.addElement(Tag.superclasses, supertypeToText(supertype));
    });
    classHierarchyNode.interfaces.forEach((Supertype supertype) {
      features.addElement(Tag.interfaces, supertypeToText(supertype));
    });
    if (data.abstractMembers != null) {
      for (ClassMember abstractMember in data.abstractMembers) {
        features.addElement(
            Tag.abstractMembers, classMemberQualifiedName(abstractMember));
      }
    }
    features[Tag.maxInheritancePath] =
        '${classHierarchyNode.maxInheritancePath}';
    if (classHierarchyNode.hasNoSuchMethod) {
      features.add(Tag.hasNoSuchMethod);
    }
    return features;
  }
}

String classMemberName(ClassMember classMember) {
  String name = classMember.name.text;
  if (classMember.forSetter) {
    name += '=';
  }
  return name;
}

String classMemberQualifiedName(ClassMember classMember) {
  return '${classMember.classBuilder.name}.${classMemberName(classMember)}';
}

String memberName(Member member) {
  String name = member.name.text;
  if (member is Procedure && member.isSetter) {
    name += '=';
  }
  return name;
}

String memberQualifiedName(Member member) {
  return '${member.enclosingClass.name}.${memberName(member)}';
}

String procedureType(Procedure procedure) {
  if (procedure.kind == ProcedureKind.Getter) {
    return typeToText(procedure.function.returnType,
        TypeRepresentation.analyzerNonNullableByDefault);
  } else if (procedure.kind == ProcedureKind.Setter) {
    return typeToText(procedure.function.positionalParameters.single.type,
        TypeRepresentation.analyzerNonNullableByDefault);
  } else {
    Nullability functionTypeNullability;
    if (procedure.enclosingLibrary.isNonNullableByDefault) {
      functionTypeNullability = procedure.enclosingLibrary.nonNullable;
    } else {
      // We don't create a member signature when the member is just
      // a substitution. We should still take the nullability to be
      // legacy, though.
      functionTypeNullability = procedure.enclosingLibrary.nonNullable;
    }
    return typeToText(
        procedure.function.computeThisFunctionType(functionTypeNullability),
        TypeRepresentation.analyzerNonNullableByDefault);
  }
}
