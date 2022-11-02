// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common/elements.dart';
import '../common/metrics.dart' show Metrics;
import '../elements/entities.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../native/behavior.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import '../world.dart';
import '../inferrer/abstract_value_domain.dart';
import 'locals_handler.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';
import 'types.dart';

abstract class InferrerEngine {
  AbstractValueDomain get abstractValueDomain;
  TypeSystem get types;
  JClosedWorld get closedWorld;
  CommonElements get commonElements;
  InferredDataBuilder get inferredDataBuilder;
  FunctionEntity get mainElement;
  NoSuchMethodData get noSuchMethodData;
  Set<Selector> get returnsListElementTypeSet;
  Map<ir.TreeNode, TypeInformation> get concreteTypes;
  Metrics get metrics;

  TypeInformation typeOfNativeBehavior(NativeBehavior nativeBehavior);
  bool canFieldBeUsedForGlobalOptimizations(FieldEntity element);
  bool assumeDynamic(MemberEntity member);
  TypeInformation getDefaultTypeOfParameter(Local parameter);
  bool canFunctionParametersBeUsedForGlobalOptimizations(
      FunctionEntity function);
  TypeInformation typeOfMemberWithSelector(
      MemberEntity element, Selector? selector);
  void updateSelectorInMember(MemberEntity owner, CallType callType,
      ir.Node? node, Selector? selector, AbstractValue? mask);
  void updateParameterInputs(TypeInformation caller, MemberEntity callee,
      ArgumentsTypes? arguments, Selector? selector,
      {required bool remove, bool addToQueue = true});
  bool returnsListElementType(Selector selector, AbstractValue mask);
  bool returnsMapValueType(Selector selector, AbstractValue mask);
  void analyzeListAndEnqueue(ListTypeInformation info);
  void analyzeSetAndEnqueue(SetTypeInformation info);
  void analyzeMapAndEnqueue(MapTypeInformation info);

  GlobalTypeInferenceElementData dataOfMember(MemberEntity element);
  TypeInformation addReturnTypeForMethod(
      FunctionEntity element, TypeInformation unused, TypeInformation newType);
  TypeInformation registerAwait(ir.Node node, TypeInformation argument);
  TypeInformation registerCalledClosure(
      ir.Node node,
      Selector selector,
      TypeInformation closure,
      MemberEntity caller,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      {bool inLoop});
  TypeInformation registerCalledMember(
      Object node,
      Selector selector,
      MemberEntity caller,
      MemberEntity callee,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      bool inLoop);
  TypeInformation registerCalledSelector(
      CallType callType,
      ir.Node node,
      Selector selector,
      AbstractValue mask,
      TypeInformation receiverType,
      MemberEntity caller,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      {bool inLoop,
      bool isConditional});
  TypeInformation registerYield(ir.Node node, TypeInformation argument);
  TypeInformation returnTypeOfMember(MemberEntity element);
  TypeInformation typeOfMember(MemberEntity element);
  TypeInformation typeOfParameter(Local element);
  void analyze(MemberEntity element);
  void forEachElementMatching(
      Selector selector, AbstractValue mask, bool f(MemberEntity element));
  bool checkIfExposesThis(ConstructorEntity element);
  void recordExposesThis(ConstructorEntity element, bool exposesThis);
  void recordReturnType(FunctionEntity element, TypeInformation type);
  void recordTypeOfField(FieldEntity element, TypeInformation type);
  void setDefaultTypeOfParameter(Local parameter, TypeInformation type);
  void runOverAllElements();
  Iterable<MemberEntity> getCallersOfForTesting(MemberEntity element);
  void close();
  void clear();
}

abstract class KernelGlobalTypeInferenceElementData
    implements GlobalTypeInferenceElementData {
  void setReceiverTypeMask(ir.TreeNode node, AbstractValue mask);
}
