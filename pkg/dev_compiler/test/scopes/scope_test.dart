// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, ddcMarker, runTests;
import 'package:front_end/src/api_prototype/experimental_flags.dart' as fe;
import 'package:kernel/ast.dart';
import 'package:kernel/dart_scope_calculator.dart';
import 'package:kernel/src/printer.dart' show AstPrinter, AstTextStrategy;

import '../id_testing_helper.dart';

Future<void> main(List<String> args) async {
  var dataDir = Directory.fromUri(
      Platform.script.resolve('../../../front_end/test/scopes/data'));
  await runTests<Features>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const ScopeDataComputer(), [
        DdcTestConfig(ddcMarker, 'ddc',
            experimentalFlags: {fe.ExperimentalFlag.inlineClass: true})
      ]));
}

class Tags {
  static const String cls = 'class';
  static const String member = 'member';
  static const String isStatic = 'static';
  static const String typeParameter = 'typeParameters';
  static const String variables = 'variables';
}

class ScopeDataComputer extends DdcDataComputer<Features> {
  const ScopeDataComputer();

  @override
  void computeMemberData(DdcTestResultData testResultData, Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool? verbose}) {
    member.accept(ScopeDataExtractor(
        member.enclosingLibrary, testResultData.compilerResult, actualMap));
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class ScopeDataExtractor extends DdcDataExtractor<Features> {
  final Library library;

  ScopeDataExtractor(this.library, super.compilerResult, super.actualMap);

  Component get component => compilerResult.ddcResult.component;

  @override
  Features? computeNodeValue(Id id, TreeNode node) {
    // We use references to a static variable 'x' as the marker for where we
    // want to compute the scope.
    if (node is StaticGet && node.target.name.text == 'x') {
      var location = node.location;
      if (location != null) {
        var scope = DartScopeBuilder.findScope(
            component, library, location.line, location.column);
        if (scope != null) {
          var features = Features();
          if (scope.cls != null) {
            features[Tags.cls] = scope.cls!.name;
          }
          if (scope.member != null) {
            features[Tags.member] = scope.member!.name.text;
          }
          if (scope.isStatic) {
            features.add(Tags.isStatic);
          }
          for (var typeParameter in scope.typeParameters) {
            var printer = AstPrinter(const AstTextStrategy(
                useQualifiedTypeParameterNames: true,
                useQualifiedTypeParameterNamesRecurseOnNamedLocalFunctions:
                    true,
                includeLibraryNamesInTypes: false));
            printer.writeTypeParameterName(typeParameter);
            features.addElement(Tags.typeParameter, printer.getText());
          }
          for (var variable in scope.definitions.keys) {
            features.addElement(Tags.variables, variable);
          }
          return features;
        }
      }
    }
    return super.computeNodeValue(id, node);
  }
}
