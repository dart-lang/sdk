// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_graph_inferrer;

import 'dart:collection' show Queue;

import '../elements/entities.dart';
import '../types/abstract_value_domain.dart';
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show JClosedWorld;
import 'inferrer_engine.dart';
import 'type_graph_nodes.dart';

/**
 * A work queue for the inferrer. It filters out nodes that are tagged as
 * [TypeInformation.doNotEnqueue], as well as ensures through
 * [TypeInformation.inQueue] that a node is in the queue only once at
 * a time.
 */
class WorkQueue {
  final Queue<TypeInformation> queue = new Queue<TypeInformation>();

  void add(TypeInformation element) {
    if (element.doNotEnqueue) return;
    if (element.inQueue) return;
    queue.addLast(element);
    element.inQueue = true;
  }

  void addAll(Iterable<TypeInformation> all) {
    all.forEach(add);
  }

  TypeInformation remove() {
    TypeInformation element = queue.removeFirst();
    element.inQueue = false;
    return element;
  }

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;
}

abstract class TypeGraphInferrer<T> implements TypesInferrer<T> {
  InferrerEngine<T> inferrer;
  final bool _disableTypeInference;
  final JClosedWorld closedWorld;

  TypeGraphInferrer(this.closedWorld, {bool disableTypeInference: false})
      : this._disableTypeInference = disableTypeInference;

  String get name => 'Graph inferrer';

  AbstractValueDomain get abstractValueDomain =>
      closedWorld.abstractValueDomain;

  AbstractValue get _dynamicType => abstractValueDomain.dynamicType;

  void analyzeMain(FunctionEntity main) {
    inferrer = createInferrerEngineFor(main);
    if (_disableTypeInference) return;
    inferrer.runOverAllElements();
  }

  InferrerEngine<T> createInferrerEngineFor(FunctionEntity main);

  AbstractValue getReturnTypeOfMember(MemberEntity element) {
    if (_disableTypeInference) return _dynamicType;
    // Currently, closure calls return dynamic.
    if (element is! FunctionEntity) return _dynamicType;
    return inferrer.types.getInferredTypeOfMember(element).type;
  }

  AbstractValue getReturnTypeOfParameter(Local element) {
    if (_disableTypeInference) return _dynamicType;
    return _dynamicType;
  }

  AbstractValue getTypeOfMember(MemberEntity element) {
    if (_disableTypeInference) return _dynamicType;
    // The inferrer stores the return type for a function, so we have to
    // be careful to not return it here.
    if (element is FunctionEntity) return abstractValueDomain.functionType;
    return inferrer.types.getInferredTypeOfMember(element).type;
  }

  AbstractValue getTypeOfParameter(Local element) {
    if (_disableTypeInference) return _dynamicType;
    // The inferrer stores the return type for a function, so we have to
    // be careful to not return it here.
    return inferrer.types.getInferredTypeOfParameter(element).type;
  }

  AbstractValue getTypeForNewList(T node) {
    if (_disableTypeInference) return _dynamicType;
    return inferrer.types.allocatedLists[node].type;
  }

  bool isFixedArrayCheckedForGrowable(T node) {
    if (_disableTypeInference) return true;
    ListTypeInformation info = inferrer.types.allocatedLists[node];
    return info.checksGrowable;
  }

  AbstractValue getTypeOfSelector(Selector selector, AbstractValue receiver) {
    if (_disableTypeInference) return _dynamicType;
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall) return _dynamicType;
    if (selector.isSetter || selector.isIndexSet) {
      return _dynamicType;
    }
    if (inferrer.returnsListElementType(selector, receiver)) {
      return abstractValueDomain.getContainerElementType(receiver);
    }
    if (inferrer.returnsMapValueType(selector, receiver)) {
      return abstractValueDomain.getMapValueType(receiver);
    }

    if (inferrer.closedWorld.includesClosureCall(selector, receiver)) {
      return abstractValueDomain.dynamicType;
    } else {
      Iterable<MemberEntity> elements =
          inferrer.closedWorld.locateMembers(selector, receiver);
      List<AbstractValue> types = <AbstractValue>[];
      for (MemberEntity element in elements) {
        AbstractValue type =
            inferrer.typeOfMemberWithSelector(element, selector).type;
        types.add(type);
      }
      return abstractValueDomain.unionOfMany(types);
    }
  }

  Iterable<MemberEntity> getCallersOfForTesting(MemberEntity element) {
    if (_disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return inferrer.getCallersOfForTesting(element);
  }

  bool isMemberCalledOnce(MemberEntity element) {
    if (_disableTypeInference) return false;
    MemberTypeInformation info =
        inferrer.types.getInferredTypeOfMember(element);
    return info.isCalledOnce();
  }

  void clear() {
    inferrer.clear();
  }
}
