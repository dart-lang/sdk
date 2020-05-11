// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common/codegen.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js_backend/namer.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/element_map.dart';
import 'package:compiler/src/js_model/js_world.dart';
import 'package:js_ast/js_ast.dart' as js;
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../helpers/program_lookup.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir =
        new Directory.fromUri(Platform.script.resolve('model_data'));
    await checkTests(dataDir, const ModelDataComputer(),
        args: args, testedConfigs: allInternalConfigs);
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
      const FeaturesDataInterpreter(wildcard: '*');
}

class Tags {
  static const String needsCheckedSetter = 'checked';
  static const String getterFlags = 'get';
  static const String setterFlags = 'set';
  static const String parameterCount = 'params';
  static const String call = 'calls';
  static const String parameterStub = 'stubs';
  static const String callStubCall = 'stubCalls';
  static const String callStubAccesses = 'stubAccesses';
  static const String isEmitted = 'emitted';
  static const String isElided = 'elided';
  static const String assignment = 'assign';
  static const String isLazy = 'lazy';
  static const String propertyAccess = 'access';
  static const String switchCase = 'switch';
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
      : _programLookup = new ProgramLookup(compiler.backendStrategy),
        super(reporter, actualMap);

  void registerCalls(Features features, String tag, js.Node node,
      {String prefix = '', Set<js.PropertyAccess> handledAccesses}) {
    forEachNode(node, onCall: (js.Call node) {
      js.Node target = undefer(node.target);
      if (target is js.PropertyAccess) {
        js.Node selector = undefer(target.selector);
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
            String arguments = node.arguments.map(js.nodeToString).join(',');
            features.addElement(tag, '${prefix}${name}(${arguments})');
          } else {
            features.addElement(
                tag, '${prefix}${name}(${node.arguments.length})');
          }
          handledAccesses?.add(target);
        }
      }
    });
  }

  void registerAccesses(Features features, String tag, js.Node code,
      {String prefix = '', Set<js.PropertyAccess> handledAccesses}) {
    forEachNode(code, onPropertyAccess: (js.PropertyAccess node) {
      if (handledAccesses?.contains(node) ?? false) {
        return;
      }

      js.Node receiver = undefer(node.receiver);
      String receiverName;
      if (receiver is js.VariableUse) {
        receiverName = receiver.name;
        if (receiverName == receiverName.toUpperCase() &&
            receiverName != r'$') {
          // Skip holder access.
          receiverName = null;
        }
      } else if (receiver is js.This) {
        receiverName = 'this';
      }

      js.Node selector = undefer(node.selector);
      String name;
      if (selector is js.Name) {
        name = selector.key;
      } else if (selector is js.LiteralString) {
        /// Call to fixed backend name, so we include the argument
        /// values to test encoding of optional parameters in native
        /// methods.
        name = selector.value.substring(1, selector.value.length - 1);
      }

      if (receiverName != null && name != null) {
        features.addElement(tag, '${prefix}${name}');
      }
    });
  }

  Features getMemberValue(MemberEntity member) {
    if (member is FieldEntity) {
      Field field = _programLookup.getField(member);
      if (field != null) {
        Features features = new Features();
        if (field.needsCheckedSetter) {
          features.add(Tags.needsCheckedSetter);
        }
        if (field.isElided) {
          features.add(Tags.isElided);
        } else {
          features.add(Tags.isEmitted);
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

        Class cls = _programLookup.getClass(member.enclosingClass);
        for (StubMethod stub in cls.callStubs) {
          if (stub.element == member) {
            registerCalls(features, Tags.callStubCall, stub.code,
                prefix: '${stub.name.key}:');
            registerAccesses(features, Tags.callStubAccesses, stub.code,
                prefix: '${stub.name.key}:');
          }
        }

        return features;
      }
      StaticField staticField = _programLookup.getStaticField(member);
      if (staticField != null) {
        Features features = new Features();
        features.add(Tags.isEmitted);
        if (staticField.isLazy) {
          features.add(Tags.isLazy);
        }
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

        Set<js.PropertyAccess> handledAccesses = new Set();

        registerCalls(features, Tags.call, code,
            handledAccesses: handledAccesses);
        if (method is DartMethod) {
          for (ParameterStubMethod stub in method.parameterStubs) {
            registerCalls(features, Tags.parameterStub, stub.code,
                prefix: '${stub.name.key}:', handledAccesses: handledAccesses);
          }
        }

        forEachNode(code, onAssignment: (js.Assignment node) {
          js.Expression leftHandSide = undefer(node.leftHandSide);
          if (leftHandSide is js.PropertyAccess) {
            js.Node selector = undefer(leftHandSide.selector);
            String name;
            if (selector is js.Name) {
              name = selector.key;
            } else if (selector is js.LiteralString) {
              name = selector.value.substring(1, selector.value.length - 1);
            }
            if (name != null) {
              features.addElement(Tags.assignment, '${name}');
              handledAccesses.add(leftHandSide);
            }
          }
        });

        registerAccesses(features, Tags.propertyAccess, code,
            handledAccesses: handledAccesses);

        forEachNode(code, onSwitch: (js.Switch node) {
          features.add(Tags.switchCase);
        });

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

js.Node undefer(js.Node node) {
  if (node is js.DeferredExpression) return undefer(node.value);
  if (node is ModularName) return undefer(node.value);
  return node;
}
