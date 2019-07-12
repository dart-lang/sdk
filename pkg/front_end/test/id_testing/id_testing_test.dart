// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart'
    show DataInterpreter, StringDataInterpreter, runTests;
import 'package:front_end/src/testing/id_testing.dart';
import 'package:front_end/src/testing/id_testing_helper.dart'
    show
        CfeDataExtractor,
        CompilerResult,
        DataComputer,
        defaultCfeConfig,
        createUriForFileName,
        onFailure,
        runTestFor;
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart'
    show Class, Member, FunctionDeclaration, FunctionExpression, TreeNode;

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: [cfeMarker],
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const MemberNameDataComputer(), [defaultCfeConfig]));
}

class MemberNameDataComputer extends DataComputer<String> {
  const MemberNameDataComputer();

  @override
  void computeMemberData(CompilerResult compilerResult, Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    member.accept(new MemberNameDataExtractor(compilerResult, actualMap));
  }

  @override
  void computeClassData(CompilerResult compilerResult, Class cls,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new MemberNameDataExtractor(compilerResult, actualMap).computeForClass(cls);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class MemberNameDataExtractor extends CfeDataExtractor<String> {
  MemberNameDataExtractor(
      CompilerResult compilerResult, Map<Id, ActualData<String>> actualMap)
      : super(compilerResult, actualMap);

  String computeClassName(Class cls) {
    return cls.name;
  }

  String computeMemberName(Member member) {
    if (member.enclosingClass != null) {
      return '${computeClassName(member.enclosingClass)}.'
          '${getMemberName(member)}';
    }
    return getMemberName(member);
  }

  @override
  String computeClassValue(Id id, Class cls) {
    return computeClassName(cls);
  }

  @override
  String computeNodeValue(Id id, TreeNode node) {
    if (node is FunctionDeclaration) {
      return '${computeMemberName(getEnclosingMember(node))}.'
          '${node.variable.name}';
    } else if (node is FunctionExpression) {
      return '${computeMemberName(getEnclosingMember(node))}.'
          '<anonymous>';
    }
    return null;
  }

  @override
  String computeMemberValue(Id id, Member member) {
    return computeMemberName(member);
  }
}
