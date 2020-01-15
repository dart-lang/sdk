// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/inheritance/data'));
  await runTests<String>(dataDir,
      args: args,
      supportedMarkers: [cfeMarker],
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const InheritanceDataComputer(), [cfeNonNullableOnlyConfig]));
}

class InheritanceDataComputer extends DataComputer<String> {
  const InheritanceDataComputer();

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(InternalCompilerResult compilerResult,
      Library library, Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new InheritanceDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  void computeClassData(InternalCompilerResult compilerResult, Class cls,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new InheritanceDataExtractor(compilerResult, actualMap)
        .computeForClass(cls);
  }

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(
      InternalCompilerResult compiler, Id id, List<FormattedMessage> errors) {
    return errorsToText(errors, useCodes: true);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class InheritanceDataExtractor extends CfeDataExtractor<String> {
  final ClassHierarchy _hierarchy;
  final CoreTypes _coreTypes;

  InheritanceDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap)
      : _hierarchy = compilerResult.classHierarchy,
        _coreTypes = compilerResult.coreTypes,
        super(compilerResult, actualMap);

  @override
  String computeLibraryValue(Id id, Library node) {
    return 'nnbd=${node.isNonNullableByDefault}';
  }

  @override
  void computeForClass(Class node) {
    super.computeForClass(node);

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
    List<String> supertypes = <String>[];
    for (Class superclass in computeAllSuperclasses(node)) {
      Supertype supertype = _hierarchy.getClassAsInstanceOf(node, superclass);
      assert(supertype != null, "No instance of $superclass found for $node.");
      supertypes.add(
          supertypeToText(supertype, TypeRepresentation.implicitUndetermined));
    }
    supertypes.sort();
    return supertypes.join(',');
  }
}
