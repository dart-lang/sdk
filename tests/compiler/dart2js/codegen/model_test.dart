// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/util/features.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../helpers/program_lookup.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('model_data'));
    await checkTests(dataDir, const ModelDataComputer(), args: args);
  });
}

class ModelDataComputer extends DataComputer<String> {
  const ModelDataComputer();

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new ModelIrComputer(compiler.reporter, actualMap, elementMap, member,
            compiler, closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class Tags {
  static const String needsCheckedSetter = 'checked';
  static const String getterFlags = 'get';
  static const String setterFlags = 'set';
}

/// AST visitor for computing inference data for a member.
class ModelIrComputer extends IrDataExtractor<String> {
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;
  final ProgramLookup _programLookup;

  ModelIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<String>> actualMap,
      this._elementMap,
      MemberEntity member,
      Compiler compiler,
      this._closureDataLookup)
      : _programLookup = new ProgramLookup(compiler),
        super(reporter, actualMap);

  String getMemberValue(MemberEntity member) {
    if (member is FieldEntity) {
      Field field = _programLookup.getField(member);
      if (field != null) {
        Features features = new Features();
        if (field.needsCheckedSetter) {
          features.add(Tags.needsCheckedSetter);
        }
        void registerFlags(String tag, int flags) {
          switch (flags) {
            case 0:
              break;
            case 1:
              features.add(tag, value: 'simple');
              break;
            case 2:
              features.add(tag, value: 'intercepted');
              break;
            case 3:
              features.add(tag, value: 'interceptedThis');
              break;
          }
        }

        registerFlags(Tags.getterFlags, field.getterFlags);
        registerFlags(Tags.setterFlags, field.setterFlags);

        return features.getText();
      }
    }
    return null;
  }

  @override
  String computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  String computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    }
    return null;
  }
}
