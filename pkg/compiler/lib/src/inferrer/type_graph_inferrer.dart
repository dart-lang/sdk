// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_graph_inferrer;

import 'dart:collection' show Queue;

import '../compiler.dart' show Compiler;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../tree/tree.dart' as ast show Node;
import '../types/masks.dart'
    show CommonMasks, ContainerTypeMask, MapTypeMask, TypeMask;
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show ClosedWorld, ClosedWorldRefiner;
import 'ast_inferrer_engine.dart';
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
  final ClosedWorld closedWorld;
  final ClosedWorldRefiner closedWorldRefiner;

  TypeGraphInferrer(this.closedWorld, this.closedWorldRefiner,
      {bool disableTypeInference: false})
      : this._disableTypeInference = disableTypeInference;

  String get name => 'Graph inferrer';

  CommonMasks get commonMasks => closedWorld.commonMasks;

  TypeMask get _dynamicType => commonMasks.dynamicType;

  void analyzeMain(FunctionEntity main) {
    inferrer = createInferrerEngineFor(main);
    if (_disableTypeInference) return;
    inferrer.runOverAllElements();
  }

  InferrerEngine<T> createInferrerEngineFor(FunctionEntity main);

  TypeMask getReturnTypeOfMember(MemberEntity element) {
    if (_disableTypeInference) return _dynamicType;
    // Currently, closure calls return dynamic.
    if (element is! FunctionEntity) return _dynamicType;
    return inferrer.types.getInferredTypeOfMember(element).type;
  }

  TypeMask getReturnTypeOfParameter(Local element) {
    if (_disableTypeInference) return _dynamicType;
    return _dynamicType;
  }

  TypeMask getTypeOfMember(MemberEntity element) {
    if (_disableTypeInference) return _dynamicType;
    // The inferrer stores the return type for a function, so we have to
    // be careful to not return it here.
    if (element is FunctionEntity) return commonMasks.functionType;
    return inferrer.types.getInferredTypeOfMember(element).type;
  }

  TypeMask getTypeOfParameter(Local element) {
    if (_disableTypeInference) return _dynamicType;
    // The inferrer stores the return type for a function, so we have to
    // be careful to not return it here.
    return inferrer.types.getInferredTypeOfParameter(element).type;
  }

  TypeMask getTypeForNewList(T node) {
    if (_disableTypeInference) return _dynamicType;
    return inferrer.types.allocatedLists[node].type;
  }

  bool isFixedArrayCheckedForGrowable(T node) {
    if (_disableTypeInference) return true;
    ListTypeInformation info = inferrer.types.allocatedLists[node];
    return info.checksGrowable;
  }

  TypeMask getTypeOfSelector(Selector selector, TypeMask mask) {
    if (_disableTypeInference) return _dynamicType;
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall) return _dynamicType;
    if (selector.isSetter || selector.isIndexSet) {
      return _dynamicType;
    }
    if (inferrer.returnsListElementType(selector, mask)) {
      ContainerTypeMask containerTypeMask = mask;
      TypeMask elementType = containerTypeMask.elementType;
      return elementType == null ? _dynamicType : elementType;
    }
    if (inferrer.returnsMapValueType(selector, mask)) {
      MapTypeMask mapTypeMask = mask;
      TypeMask valueType = mapTypeMask.valueType;
      return valueType == null ? _dynamicType : valueType;
    }

    TypeMask result = const TypeMask.nonNullEmpty();
    Iterable<MemberEntity> elements =
        inferrer.closedWorld.locateMembers(selector, mask);
    for (MemberElement element in elements) {
      TypeMask type = inferrer.typeOfMemberWithSelector(element, selector).type;
      result = result.union(type, inferrer.closedWorld);
    }
    return result;
  }

  Iterable<MemberEntity> getCallersOf(MemberEntity element) {
    if (_disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return inferrer.getCallersOf(element);
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

class AstTypeGraphInferrer extends TypeGraphInferrer<ast.Node> {
  final Compiler _compiler;

  AstTypeGraphInferrer(
      this._compiler, ClosedWorld closedWorld, closedWorldRefiner,
      {bool disableTypeInference: false})
      : super(closedWorld, closedWorldRefiner,
            disableTypeInference: disableTypeInference);

  @override
  InferrerEngine<ast.Node> createInferrerEngineFor(FunctionEntity main) {
    return new AstInferrerEngine(
        _compiler, closedWorld, closedWorldRefiner, main);
  }

  @override
  GlobalTypeInferenceResults createResults() {
    return new AstGlobalTypeInferenceResults(this, closedWorld);
  }
}
