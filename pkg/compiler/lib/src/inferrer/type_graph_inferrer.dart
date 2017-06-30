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
import '../types/types.dart' show TypesInferrer;
import '../universe/selector.dart' show Selector;
import '../world.dart' show ClosedWorld, ClosedWorldRefiner;
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

class TypeGraphInferrer implements TypesInferrer {
  InferrerEngine inferrer;
  final Compiler compiler;
  final ClosedWorld closedWorld;
  final ClosedWorldRefiner closedWorldRefiner;

  TypeGraphInferrer(this.compiler, this.closedWorld, this.closedWorldRefiner);

  String get name => 'Graph inferrer';

  CommonMasks get commonMasks => closedWorld.commonMasks;

  TypeMask get _dynamicType => commonMasks.dynamicType;

  void analyzeMain(FunctionEntity main) {
    inferrer =
        new InferrerEngine(compiler, closedWorld, closedWorldRefiner, main);
    inferrer.runOverAllElements();
  }

  @deprecated
  TypeMask getReturnTypeOfLocalFunction(LocalFunctionElement element) {
    if (compiler.disableTypeInference) return _dynamicType;
    return inferrer.types.getInferredTypeOfLocalFunction(element).type;
  }

  TypeMask getReturnTypeOfMember(MemberElement element) {
    if (compiler.disableTypeInference) return _dynamicType;
    // Currently, closure calls return dynamic.
    if (element is! MethodElement) return _dynamicType;
    return inferrer.types.getInferredTypeOfMember(element).type;
  }

  TypeMask getReturnTypeOfParameter(ParameterElement element) {
    if (compiler.disableTypeInference) return _dynamicType;
    return _dynamicType;
  }

  @deprecated
  TypeMask getTypeOfLocalFunction(LocalFunctionElement element) {
    if (compiler.disableTypeInference) return _dynamicType;
    return commonMasks.functionType;
  }

  TypeMask getTypeOfMember(MemberElement element) {
    if (compiler.disableTypeInference) return _dynamicType;
    // The inferrer stores the return type for a function, so we have to
    // be careful to not return it here.
    if (element is MethodElement) return commonMasks.functionType;
    return inferrer.types.getInferredTypeOfMember(element).type;
  }

  TypeMask getTypeOfParameter(ParameterElement element) {
    if (compiler.disableTypeInference) return _dynamicType;
    // The inferrer stores the return type for a function, so we have to
    // be careful to not return it here.
    return inferrer.types.getInferredTypeOfParameter(element).type;
  }

  TypeMask getTypeForNewList(ast.Node node) {
    if (compiler.disableTypeInference) return _dynamicType;
    return inferrer.types.allocatedLists[node].type;
  }

  bool isFixedArrayCheckedForGrowable(ast.Node node) {
    if (compiler.disableTypeInference) return true;
    ListTypeInformation info = inferrer.types.allocatedLists[node];
    return info.checksGrowable;
  }

  TypeMask getTypeOfSelector(Selector selector, TypeMask mask) {
    if (compiler.disableTypeInference) return _dynamicType;
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

  Iterable<Element> getCallersOf(MemberElement element) {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return inferrer.getCallersOf(element);
  }

  @deprecated
  bool isLocalFunctionCalledOnce(LocalFunctionElement element) {
    if (compiler.disableTypeInference) return false;
    MemberTypeInformation info =
        inferrer.types.getInferredTypeOfLocalFunction(element);
    return info.isCalledOnce();
  }

  bool isMemberCalledOnce(MemberElement element) {
    if (compiler.disableTypeInference) return false;
    MemberTypeInformation info =
        inferrer.types.getInferredTypeOfMember(element);
    return info.isCalledOnce();
  }

  bool isParameterCalledOnce(ParameterElement element) {
    if (compiler.disableTypeInference) return false;
    MemberTypeInformation info =
        inferrer.types.getInferredTypeOfParameter(element);
    return info.isCalledOnce();
  }

  void clear() {
    inferrer.clear();
  }
}
