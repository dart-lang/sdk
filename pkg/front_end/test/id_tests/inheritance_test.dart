// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/kernel/class_hierarchy_builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:kernel/ast.dart';

const String cfeFromBuilderMarker = 'cfe:builder';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/inheritance/data'));
  await runTests<String>(dataDir,
      args: args,
      supportedMarkers: [cfeMarker, cfeFromBuilderMarker],
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const InheritanceDataComputer(), [
        new TestConfig(cfeMarker, 'cfe with nnbd',
            experimentalFlags: const {ExperimentalFlag.nonNullable: true},
            librariesSpecificationUri: createUriForFileName('libraries.json'),
            compileSdk: true),
        new TestConfig(
            cfeFromBuilderMarker, 'cfe from builder',
            experimentalFlags: const {ExperimentalFlag.nonNullable: true},
            librariesSpecificationUri: createUriForFileName('libraries.json'),
            compileSdk: true)
      ]));
}

class InheritanceDataComputer extends DataComputer<String> {
  const InheritanceDataComputer();

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new InheritanceDataExtractor(config, compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  void computeClassData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Class cls,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new InheritanceDataExtractor(config, compilerResult, actualMap)
        .computeForClass(cls);
  }

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(TestConfig config, InternalCompilerResult compiler,
      Id id, List<FormattedMessage> errors) {
    return errorsToText(errors, useCodes: true);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class InheritanceDataExtractor extends CfeDataExtractor<String> {
  final TestConfig _config;
  final InternalCompilerResult _compilerResult;

  InheritanceDataExtractor(
      this._config, this._compilerResult, Map<Id, ActualData<String>> actualMap)
      : super(_compilerResult, actualMap);

  ClassHierarchy get _hierarchy => _compilerResult.classHierarchy;
  CoreTypes get _coreTypes => _compilerResult.coreTypes;
  ClassHierarchyBuilder get _classHierarchyBuilder =>
      _compilerResult.kernelTargetForTesting.loader.builderHierarchy;

  @override
  String computeLibraryValue(Id id, Library node) {
    return 'nnbd=${node.isNonNullableByDefault}';
  }

  @override
  void computeForClass(Class node) {
    super.computeForClass(node);
    // TODO(johnniwinther): Also compute member data from builders.
    Set<Name> getters = _hierarchy
        .getInterfaceMembers(node)
        .map((Member member) => member.name)
        .toSet();
    Set<Name> setters = _hierarchy
        .getInterfaceMembers(node, setters: true)
        .where((Member member) =>
            member is Procedure && member.kind == ProcedureKind.Setter)
        .map((Member member) => member.name)
        .toSet();

    void addMember(Name name, {bool setter}) {
      Member member = _hierarchy.getInterfaceMember(node, name, setter: setter);
      if (member.enclosingClass == _coreTypes.objectClass) {
        return;
      }
      InterfaceType supertype = _hierarchy.getTypeAsInstanceOf(
          _coreTypes.thisInterfaceType(node, node.enclosingLibrary.nonNullable),
          member.enclosingClass,
          node.enclosingLibrary,
          _coreTypes);
      Substitution substitution = Substitution.fromInterfaceType(supertype);
      DartType type;
      if (member is Procedure) {
        if (member.kind == ProcedureKind.Getter) {
          type = substitution.substituteType(member.function.returnType);
        } else if (member.kind == ProcedureKind.Setter) {
          type = substitution
              .substituteType(member.function.positionalParameters.single.type);
        } else {
          type = substitution.substituteType(member.function
              .computeThisFunctionType(member.enclosingLibrary.nonNullable));
        }
      } else if (member is Field) {
        type = substitution.substituteType(member.type);
      }
      if (type == null) {
        return;
      }

      String memberName = name.name;
      if (member is Procedure && member.kind == ProcedureKind.Setter) {
        memberName += '=';
      }
      MemberId id = new MemberId.internal(memberName, className: node.name);

      TreeNode nodeWithOffset;
      if (member.enclosingClass == node) {
        nodeWithOffset = computeTreeNodeWithOffset(member);
      } else {
        nodeWithOffset = computeTreeNodeWithOffset(node);
      }

      registerValue(
          nodeWithOffset?.location?.file,
          nodeWithOffset?.fileOffset,
          id,
          typeToText(type, TypeRepresentation.implicitUndetermined),
          member);
    }

    for (Name name in getters) {
      addMember(name, setter: false);
    }

    for (Name name in setters) {
      addMember(name, setter: true);
    }
  }

  @override
  String computeClassValue(Id id, Class node) {
    if (_config.marker == cfeMarker) {
      List<String> supertypes = <String>[];
      for (Class superclass in computeAllSuperclasses(node)) {
        Supertype supertype = _hierarchy.getClassAsInstanceOf(node, superclass);
        assert(
            supertype != null, "No instance of $superclass found for $node.");
        supertypes.add(supertypeToText(
            supertype, TypeRepresentation.implicitUndetermined));
      }
      supertypes.sort();
      return supertypes.join(',');
    } else if (_config.marker == cfeFromBuilderMarker) {
      ClassHierarchyNode classHierarchyNode =
          _classHierarchyBuilder.getNodeFromClass(node);
      Set<String> supertypes = <String>{};
      void addDartType(DartType type) {
        if (type is InterfaceType) {
          Supertype supertype =
              new Supertype(type.classNode, type.typeArguments);
          supertypes.add(supertypeToText(
              supertype, TypeRepresentation.implicitUndetermined));
        }
      }

      addDartType(_coreTypes.thisInterfaceType(
          classHierarchyNode.classBuilder.cls,
          classHierarchyNode.classBuilder.cls.enclosingLibrary.nonNullable));
      classHierarchyNode.superclasses.forEach(addDartType);
      classHierarchyNode.interfaces.forEach(addDartType);
      List<String> sorted = supertypes.toList()..sort();
      return sorted.join(',');
    }
    return null;
  }
}
