// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../native/behavior.dart';
import '../ssa/types.dart';
import '../universe/selector.dart';
import 'element_map.dart';
import 'js_world.dart';

class KernelToTypeInferenceMapImpl implements KernelToTypeInferenceMap {
  final GlobalTypeInferenceResults _globalInferenceResults;
  late final GlobalTypeInferenceMemberResult _targetResults;

  KernelToTypeInferenceMapImpl(
      MemberEntity target, this._globalInferenceResults) {
    _targetResults = _resultOf(target);
  }

  GlobalTypeInferenceMemberResult _resultOf(MemberEntity e) =>
      _globalInferenceResults
          .resultOfMember(e is ConstructorBodyEntity ? e.constructor : e);

  @override
  AbstractValue getReturnTypeOf(FunctionEntity function) {
    return AbstractValueFactory.inferredReturnTypeForElement(
        function, _globalInferenceResults);
  }

  @override
  AbstractValue? receiverTypeOfInvocation(
      ir.Expression node, AbstractValueDomain abstractValueDomain) {
    return _targetResults.typeOfReceiver(node);
  }

  @override
  AbstractValue? receiverTypeOfGet(ir.Expression node) {
    return _targetResults.typeOfReceiver(node);
  }

  @override
  AbstractValue? receiverTypeOfSet(
      ir.Expression node, AbstractValueDomain abstractValueDomain) {
    return _targetResults.typeOfReceiver(node);
  }

  @override
  AbstractValue typeOfListLiteral(
      ir.ListLiteral listLiteral, AbstractValueDomain abstractValueDomain) {
    return _globalInferenceResults.typeOfListLiteral(listLiteral) ??
        abstractValueDomain.dynamicType;
  }

  @override
  AbstractValue? typeOfIterator(ir.ForInStatement node) {
    return _targetResults.typeOfIterator(node);
  }

  @override
  AbstractValue? typeOfIteratorCurrent(ir.ForInStatement node) {
    return _targetResults.typeOfIteratorCurrent(node);
  }

  @override
  AbstractValue? typeOfIteratorMoveNext(ir.ForInStatement node) {
    return _targetResults.typeOfIteratorMoveNext(node);
  }

  @override
  bool isJsIndexableIterator(
      ir.ForInStatement node, AbstractValueDomain abstractValueDomain) {
    final mask = typeOfIterator(node);
    // TODO(sra): Investigate why mask is sometimes null.
    if (mask == null) return false;
    return abstractValueDomain.isJsIndexableAndIterable(mask).isDefinitelyTrue;
  }

  @override
  AbstractValue inferredIndexType(ir.ForInStatement node) {
    return AbstractValueFactory.inferredResultTypeForSelector(
        Selector.index(), typeOfIterator(node)!, _globalInferenceResults);
  }

  @override
  AbstractValue getInferredTypeOf(MemberEntity member) {
    return AbstractValueFactory.inferredTypeForMember(
        member, _globalInferenceResults);
  }

  @override
  AbstractValue getInferredTypeOfParameter(Local parameter) {
    return AbstractValueFactory.inferredTypeForParameter(
        parameter, _globalInferenceResults);
  }

  @override
  AbstractValue resultTypeOfSelector(Selector selector, AbstractValue mask) {
    return AbstractValueFactory.inferredResultTypeForSelector(
        selector, mask, _globalInferenceResults);
  }

  @override
  AbstractValue typeFromNativeBehavior(
      // TODO(48820): remove covariant once interface and implementation match.
      NativeBehavior nativeBehavior,
      covariant JClosedWorld closedWorld) {
    return AbstractValueFactory.fromNativeBehavior(nativeBehavior, closedWorld);
  }
}
