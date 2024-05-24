// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/fasta/kernel/hierarchy/hierarchy_builder.dart';
import 'package:front_end/src/fasta/kernel/hierarchy/hierarchy_node.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

const String cfeFromBuilderMarker = 'cfe:builder';

Future<void> main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/inheritance/data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const InheritanceDataComputer(), [
        new CfeTestConfig(cfeMarker, 'cfe with nnbd',
            librariesSpecificationUri: createUriForFileName('libraries.json'),
            compileSdk: true),
        new CfeTestConfig(cfeFromBuilderMarker, 'cfe from builder',
            librariesSpecificationUri: createUriForFileName('libraries.json'),
            compileSdk: true)
      ]));
}

class InheritanceDataComputer extends CfeDataComputer<String> {
  const InheritanceDataComputer();

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeLibraryData(CfeTestResultData testResultData, Library library,
      Map<Id, ActualData<String>> actualMap,
      {bool? verbose}) {
    new InheritanceDataExtractor(testResultData, actualMap)
        .computeForLibrary(library);
  }

  @override
  void computeClassData(CfeTestResultData testResultData, Class cls,
      Map<Id, ActualData<String>> actualMap,
      {bool? verbose}) {
    new InheritanceDataExtractor(testResultData, actualMap)
        .computeForClass(cls);
  }

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(
      CfeTestResultData testResultData, Id id, List<FormattedMessage> errors) {
    return errorsToText(errors, useCodes: true);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class InheritanceDataExtractor extends CfeDataExtractor<String> {
  final CfeTestResultData _testResultData;

  InheritanceDataExtractor(
      this._testResultData, Map<Id, ActualData<String>> actualMap)
      : super(_testResultData.compilerResult, actualMap);

  CfeTestConfig get _config => _testResultData.config;

  InternalCompilerResult get _compilerResult => _testResultData.compilerResult;

  ClassHierarchy get _hierarchy => _compilerResult.classHierarchy!;

  CoreTypes get _coreTypes => _compilerResult.coreTypes!;

  ClassHierarchyBuilder get _classHierarchyBuilder =>
      _compilerResult.kernelTargetForTesting!.loader.hierarchyBuilder;

  @override
  void computeForClass(Class node) {
    super.computeForClass(node);
    if (node.isAnonymousMixin) return;
    // TODO(johnniwinther): Also compute member data from builders.
    Set<Name> getters = _hierarchy
        .getInterfaceMembers(node)
        .map((Member member) => member.name)
        .toSet();
    Set<Name> setters = _hierarchy
        .getInterfaceMembers(node, setters: true)
        .where((Member member) =>
            member is Procedure && member.kind == ProcedureKind.Setter ||
            member is Field && member.hasSetter)
        .map((Member member) => member.name)
        .toSet();

    void addMember(Name name, {required bool isSetter}) {
      Member member =
          _hierarchy.getInterfaceMember(node, name, setter: isSetter)!;
      if (member.enclosingClass == _coreTypes.objectClass) {
        return;
      }
      InterfaceType supertype = _hierarchy.getInterfaceTypeAsInstanceOfClass(
          _coreTypes.thisInterfaceType(node, node.enclosingLibrary.nonNullable),
          member.enclosingClass!,
          isNonNullableByDefault: true)!;
      Substitution substitution = Substitution.fromInterfaceType(supertype);
      DartType? type;
      if (member is Procedure) {
        if (member.kind == ProcedureKind.Getter) {
          type = substitution.substituteType(member.function.returnType);
        } else if (member.kind == ProcedureKind.Setter) {
          type = substitution
              .substituteType(member.function.positionalParameters.single.type);
        } else {
          Nullability functionTypeNullability =
              member.enclosingLibrary.nonNullable;
          type = substitution.substituteType(
              member.function.computeThisFunctionType(functionTypeNullability));
        }
      } else if (member is Field) {
        type = substitution.substituteType(member.type);
      }
      if (type == null) {
        return;
      }

      String memberName = name.text;
      if (isSetter) {
        memberName += '=';
      }
      MemberId id = new MemberId.internal(memberName, className: node.name);

      TreeNode nodeWithOffset;
      if (member.enclosingClass == node) {
        nodeWithOffset = computeTreeNodeWithOffset(member)!;
      } else {
        nodeWithOffset = computeTreeNodeWithOffset(node)!;
      }

      registerValue(
          nodeWithOffset.location!.file,
          nodeWithOffset.fileOffset,
          id,
          typeToText(type, TypeRepresentation.analyzerNonNullableByDefault),
          member);
    }

    for (Name name in getters) {
      addMember(name, isSetter: false);
    }

    for (Name name in setters) {
      addMember(name, isSetter: true);
    }
  }

  @override
  String? computeClassValue(Id id, Class node) {
    if (node.isAnonymousMixin) return null;
    if (_config.marker == cfeMarker) {
      List<String> supertypes = <String>[];
      for (Class superclass in computeAllSuperclasses(node)) {
        Supertype supertype =
            _hierarchy.getClassAsInstanceOf(node, superclass)!;
        if (supertype.classNode.isAnonymousMixin) continue;
        supertypes.add(supertypeToText(
            supertype, TypeRepresentation.analyzerNonNullableByDefault));
      }
      supertypes.sort();
      return supertypes.join(',');
    } else if (_config.marker == cfeFromBuilderMarker) {
      ClassHierarchyNode classHierarchyNode =
          _classHierarchyBuilder.getNodeFromClass(node);
      Set<String> supertypes = <String>{};
      void addSupertype(Supertype supertype) {
        if (supertype.classNode.isAnonymousMixin) return;
        supertypes.add(supertypeToText(
            supertype, TypeRepresentation.analyzerNonNullableByDefault));
      }

      addSupertype(new Supertype(
          classHierarchyNode.classBuilder.cls,
          getAsTypeArguments(classHierarchyNode.classBuilder.cls.typeParameters,
              classHierarchyNode.classBuilder.libraryBuilder.library)));
      classHierarchyNode.superclasses.forEach(addSupertype);
      classHierarchyNode.interfaces.forEach(addSupertype);
      List<String> sorted = supertypes.toList()..sort();
      return sorted.join(',');
    }
    return null;
  }
}
