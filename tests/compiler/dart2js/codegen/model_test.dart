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
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js_backend/namer.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:compiler/src/util/features.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:js_ast/js_ast.dart' as js;
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

class ModelDataComputer extends DataComputer<Features> {
  const ModelDataComputer();

  /// Compute type inference data for [member] from kernel based inference.
  ///
  /// Fills [actualMap] with the data.
  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JsToElementMap elementMap = closedWorld.elementMap;
    MemberDefinition definition = elementMap.getMemberDefinition(member);
    new ModelIrComputer(compiler.reporter, actualMap, elementMap, member,
            compiler, closedWorld.closureDataLookup)
        .run(definition.node);
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class Tags {
  static const String needsCheckedSetter = 'checked';
  static const String getterFlags = 'get';
  static const String setterFlags = 'set';
  static const String parameterCount = 'params';
  static const String call = 'calls';
  static const String parameterStub = 'stubs';
}

/// AST visitor for computing inference data for a member.
class ModelIrComputer extends IrDataExtractor<Features> {
  final JsToElementMap _elementMap;
  final ClosureData _closureDataLookup;
  final ProgramLookup _programLookup;

  ModelIrComputer(
      DiagnosticReporter reporter,
      Map<Id, ActualData<Features>> actualMap,
      this._elementMap,
      MemberEntity member,
      Compiler compiler,
      this._closureDataLookup)
      : _programLookup = new ProgramLookup(compiler),
        super(reporter, actualMap);

  Features getMemberValue(MemberEntity member) {
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

        return features;
      }
    } else if (member is FunctionEntity) {
      Method method = _programLookup.getMethod(member);
      if (method != null) {
        Features features = new Features();
        js.Expression code = method.code;
        if (code is js.Fun) {
          features[Tags.parameterCount] = '${code.params.length}';
        }

        void registerCalls(String tag, js.Node node, [String prefix = '']) {
          forEachNode(node, onCall: (js.Call node) {
            js.Node target = node.target;
            if (target is js.PropertyAccess) {
              js.Node selector = target.selector;
              bool fixedNameCall = false;
              String name;
              if (selector is js.Name) {
                name = selector.key;
                fixedNameCall = selector is StringBackedName;
              } else if (selector is js.LiteralString) {
                /// Call to fixed backend name, so we include the argument
                /// values to test encoding of optional parameters in native
                /// methods.
                name = selector.value.substring(1, selector.value.length - 1);
                fixedNameCall = true;
              }
              if (name != null) {
                if (fixedNameCall) {
                  String arguments =
                      node.arguments.map(js.nodeToString).join(',');
                  features.addElement(tag, '${prefix}${name}(${arguments})');
                } else {
                  features.addElement(tag, '${name}(${node.arguments.length})');
                }
              }
            }
          });
        }

        registerCalls(Tags.call, code);
        if (method is DartMethod) {
          for (ParameterStubMethod stub in method.parameterStubs) {
            registerCalls(Tags.parameterStub, stub.code, '${stub.name.key}:');
          }
        }
        return features;
      }
    }
    return null;
  }

  @override
  Features computeMemberValue(Id id, ir.Member node) {
    return getMemberValue(_elementMap.getMember(node));
  }

  @override
  Features computeNodeValue(Id id, ir.TreeNode node) {
    if (node is ir.FunctionExpression || node is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
      return getMemberValue(info.callMethod);
    }
    return null;
  }
}
