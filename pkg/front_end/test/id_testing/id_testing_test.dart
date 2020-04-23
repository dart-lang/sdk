// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, StringDataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'dart:io' show Directory, Platform;
import 'package:front_end/src/fasta/messages.dart' show FormattedMessage;
import 'package:front_end/src/testing/id_testing_helper.dart'
    show
        CfeDataExtractor,
        InternalCompilerResult,
        DataComputer,
        TestConfig,
        defaultCfeConfig,
        createUriForFileName,
        onFailure,
        runTestFor;
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart'
    show
        Class,
        Member,
        FunctionDeclaration,
        FunctionExpression,
        Library,
        TreeNode;

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<String>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const IdTestingDataComputer(), [defaultCfeConfig]));
}

class IdTestingDataComputer extends DataComputer<String> {
  const IdTestingDataComputer();

  @override
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    member.accept(new IdTestingDataExtractor(compilerResult, actualMap));
  }

  @override
  void computeClassData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Class cls,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new IdTestingDataExtractor(compilerResult, actualMap).computeForClass(cls);
  }

  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new IdTestingDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  bool get supportsErrors => true;

  String computeErrorData(TestConfig config, InternalCompilerResult compiler,
      Id id, List<FormattedMessage> errors) {
    return errorsToText(errors);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class IdTestingDataExtractor extends CfeDataExtractor<String> {
  IdTestingDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap)
      : super(compilerResult, actualMap);

  @override
  String computeLibraryValue(Id id, Library library) {
    StringBuffer sb = new StringBuffer();
    sb.write('file=${library.importUri.pathSegments.last}');
    if (library.name != null) {
      sb.write(',name=${library.name}');
    }
    return sb.toString();
  }

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
