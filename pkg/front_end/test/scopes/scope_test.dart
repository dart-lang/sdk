// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/dart_scope_calculator.dart';
import 'package:kernel/src/printer.dart' show AstPrinter, AstTextStrategy;

Future<void> main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<Features>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const ScopeDataComputer(), [
        new CfeTestConfig(cfeMarker, 'cfe',
            explicitExperimentalFlags: {ExperimentalFlag.inlineClass: true}),
      ]));
}

class Tags {
  static const String cls = 'class';
  static const String member = 'member';
  static const String isStatic = 'static';
  static const String typeParameter = 'typeParameters';
  static const String variables = 'variables';
}

class ScopeDataComputer extends CfeDataComputer<Features> {
  const ScopeDataComputer();

  @override
  void computeMemberData(CfeTestResultData testResultData, Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool? verbose}) {
    member.accept(ScopeDataExtractor(member.enclosingLibrary,
        member.enclosingClass, testResultData.compilerResult, actualMap));
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class ScopeDataExtractor extends CfeDataExtractor<Features> {
  final Library library;
  final Class? cls;

  ScopeDataExtractor(
      this.library, this.cls, super.compilerResult, super.actualMap);

  Component get component => compilerResult.component!;

  @override
  Features? computeNodeValue(Id id, TreeNode node) {
    // We use references to a static variable 'x' as the marker for where we
    // want to compute the scope.
    if (node is StaticGet && node.target.name.text == 'x') {
      Location? location = node.location;
      if (location != null) {
        DartScope scope = DartScopeBuilder2.findScopeFromOffsetAndClass(
            library, location.file, cls, node.fileOffset);
        Features features = Features();
        if (scope.cls != null) {
          features[Tags.cls] = scope.cls!.name;
        }
        if (scope.member != null) {
          features[Tags.member] = scope.member!.name.text;
        }
        if (scope.isStatic) {
          features.add(Tags.isStatic);
        }
        for (TypeParameter typeParameter in scope.typeParameters) {
          AstPrinter printer = new AstPrinter(const AstTextStrategy(
              useQualifiedTypeParameterNames: true,
              useQualifiedTypeParameterNamesRecurseOnNamedLocalFunctions: true,
              includeLibraryNamesInTypes: false));
          printer.writeTypeParameterName(typeParameter);
          features.addElement(Tags.typeParameter, printer.getText());
        }
        for (String variable in scope.definitions.keys) {
          features.addElement(Tags.variables, variable);
        }
        return features;
      }
    }
    return super.computeNodeValue(id, node);
  }
}
