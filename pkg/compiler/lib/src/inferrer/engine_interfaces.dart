// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common/elements.dart';
import '../elements/entities.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/no_such_method_registry_interfaces.dart';
import '../native/behavior.dart';
import '../universe/selector.dart';
import '../world_interfaces.dart';
import 'abstract_value_domain.dart';
import 'locals_handler.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

abstract class InferrerEngine {
  AbstractValueDomain get abstractValueDomain;
  TypeSystem get types;
  JClosedWorld get closedWorld;
  CommonElements get commonElements;
  InferredDataBuilder get inferredDataBuilder;
  FunctionEntity get mainElement;
  NoSuchMethodData get noSuchMethodData;
  Set<Selector> get returnsListElementTypeSet;

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
}
