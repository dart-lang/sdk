// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import '../common.dart' show failedAt;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../tree/tree.dart';
import '../universe/selector.dart' show Selector;
import '../util/util.dart' show Maplet;
import '../world.dart' show ClosedWorld, ClosedWorldRefiner;

import 'masks.dart';
export 'masks.dart';

/// Results about a single element (e.g. a method, parameter, or field)
/// produced by the global type-inference algorithm.
///
/// All queries in this class may contain results that assume whole-program
/// closed-world semantics. Any [TypeMask] for an element or node that we return
/// was inferred to be a "guaranteed type", that means, it is a type that we
/// can prove to be correct for all executions of the program.  A trivial
/// implementation would return false on all boolean properties (giving no
/// guarantees) and the `subclass of Object or null` type mask for the type
/// based queries (the runtime value could be anything).
abstract class GlobalTypeInferenceElementResult {
  /// Whether the method element associated with this result always throws.
  bool get throwsAlways;

  /// The inferred type when this result belongs to a parameter or field
  /// element, null otherwise.
  TypeMask get type;

  /// The inferred return type when this result belongs to a function element.
  TypeMask get returnType;

  /// Returns the type of a list new expression [node].
  TypeMask typeOfNewList(Send node);

  /// Returns the type of a list literal [node].
  TypeMask typeOfListLiteral(LiteralList node);

  /// Returns the type of a send [node].
  TypeMask typeOfSend(Send node);

  /// Returns the type of the operator of a complex send-set [node], for
  /// example, the type of `+` in `a += b`.
  TypeMask typeOfGetter(SendSet node);

  /// Returns the type of the getter in a complex send-set [node], for example,
  /// the type of the `a.f` getter in `a.f += b`.
  TypeMask typeOfOperator(SendSet node);

  /// Returns the type of the iterator in a [loop].
  TypeMask typeOfIterator(ForIn node);

  /// Returns the type of the `moveNext` call of an iterator in a [loop].
  TypeMask typeOfIteratorMoveNext(ForIn node);

  /// Returns the type of the `current` getter of an iterator in a [loop].
  TypeMask typeOfIteratorCurrent(ForIn node);
}

abstract class GlobalTypeInferenceMemberResult
    extends GlobalTypeInferenceElementResult {
  /// Whether the member associated with this result is only called once in one
  /// location in the entire program.
  bool get isCalledOnce;
}

abstract class GlobalTypeInferenceElementResultImpl
    implements GlobalTypeInferenceElementResult {
  // TODO(sigmund): delete, store data directly here.
  final Element _owner;

  // TODO(sigmund): split - stop using _data after inference is done.
  final GlobalTypeInferenceElementData _data;

  // TODO(sigmund): store relevant data & drop reference to inference engine.
  final TypesInferrer _inferrer;
  final bool _isJsInterop;
  final TypeMask _dynamic;

  GlobalTypeInferenceElementResultImpl.internal(this._owner, this._data,
      this._inferrer, this._isJsInterop, this._dynamic);

  bool get throwsAlways {
    TypeMask mask = this.returnType;
    // Always throws if the return type was inferred to be non-null empty.
    return mask != null && mask.isEmpty;
  }

  TypeMask typeOfNewList(Send node) => _inferrer.getTypeForNewList(node);

  TypeMask typeOfListLiteral(LiteralList node) =>
      _inferrer.getTypeForNewList(node);

  TypeMask typeOfSend(Send node) => _data?.typeOfSend(node);
  TypeMask typeOfGetter(SendSet node) => _data?.typeOfGetter(node);
  TypeMask typeOfOperator(SendSet node) => _data?.typeOfOperator(node);
  TypeMask typeOfIterator(ForIn node) => _data?.typeOfIterator(node);
  TypeMask typeOfIteratorMoveNext(ForIn node) =>
      _data?.typeOfIteratorMoveNext(node);
  TypeMask typeOfIteratorCurrent(ForIn node) =>
      _data?.typeOfIteratorCurrent(node);
}

class GlobalTypeInferenceMemberResultImpl
    extends GlobalTypeInferenceElementResultImpl
    implements GlobalTypeInferenceMemberResult {
  GlobalTypeInferenceMemberResultImpl(
      MemberElement owner,
      GlobalTypeInferenceElementData data,
      TypesInferrer inferrer,
      bool isJsInterop,
      TypeMask _dynamic)
      : super.internal(owner, data, inferrer, isJsInterop, _dynamic);

  bool get isCalledOnce => _inferrer.isMemberCalledOnce(_owner);

  TypeMask get returnType =>
      _isJsInterop ? _dynamic : _inferrer.getReturnTypeOfMember(_owner);

  TypeMask get type =>
      _isJsInterop ? _dynamic : _inferrer.getTypeOfMember(_owner);
}

class GlobalTypeInferenceParameterResult
    extends GlobalTypeInferenceElementResultImpl {
  GlobalTypeInferenceParameterResult(
      ParameterElement owner, TypesInferrer inferrer, TypeMask _dynamic)
      : super.internal(owner, null, inferrer, false, _dynamic);

  TypeMask get returnType =>
      _isJsInterop ? _dynamic : _inferrer.getReturnTypeOfParameter(_owner);

  TypeMask get type =>
      _isJsInterop ? _dynamic : _inferrer.getTypeOfParameter(_owner);
}

/// Internal data used during type-inference to store intermediate results about
/// a single element.
class GlobalTypeInferenceElementData {
  Map<Object, TypeMask> _typeMasks;

  TypeMask _get(Object node) => _typeMasks != null ? _typeMasks[node] : null;
  void _set(Object node, TypeMask mask) {
    _typeMasks ??= new Maplet<Object, TypeMask>();
    _typeMasks[node] = mask;
  }

  TypeMask typeOfSend(Send node) => _get(node);
  TypeMask typeOfGetter(SendSet node) => _get(node.selector);
  TypeMask typeOfOperator(SendSet node) => _get(node.assignmentOperator);

  void setTypeMask(Send node, TypeMask mask) {
    _set(node, mask);
  }

  void setGetterTypeMaskInComplexSendSet(SendSet node, TypeMask mask) {
    _set(node.selector, mask);
  }

  void setOperatorTypeMaskInComplexSendSet(SendSet node, TypeMask mask) {
    _set(node.assignmentOperator, mask);
  }

  // TODO(sigmund): clean up. We store data about 3 selectors for "for in"
  // nodes: the iterator, move-next, and current element. Because our map keys
  // are nodes, we need to fabricate different keys to keep these selectors
  // separate. The current implementation does this by using
  // children of the for-in node (these children were picked arbitrarily).

  TypeMask typeOfIterator(ForIn node) => _get(node);

  TypeMask typeOfIteratorMoveNext(ForIn node) => _get(node.forToken);

  TypeMask typeOfIteratorCurrent(ForIn node) => _get(node.inToken);

  void setIteratorTypeMask(ForIn node, TypeMask mask) {
    _set(node, mask);
  }

  void setMoveNextTypeMask(ForIn node, TypeMask mask) {
    _set(node.forToken, mask);
  }

  void setCurrentTypeMask(ForIn node, TypeMask mask) {
    _set(node.inToken, mask);
  }
}

/// API to interact with the global type-inference engine.
abstract class TypesInferrer {
  void analyzeMain(FunctionEntity element);
  TypeMask getReturnTypeOfMember(MemberElement element);
  TypeMask getReturnTypeOfParameter(ParameterElement element);
  TypeMask getTypeOfMember(MemberElement element);
  TypeMask getTypeOfParameter(ParameterElement element);
  TypeMask getTypeForNewList(Node node);
  TypeMask getTypeOfSelector(Selector selector, TypeMask mask);
  void clear();
  bool isMemberCalledOnce(MemberElement element);
  bool isFixedArrayCheckedForGrowable(Node node);
}

/// Results produced by the global type-inference algorithm.
///
/// All queries in this class may contain results that assume whole-program
/// closed-world semantics. Any [TypeMask] for an element or node that we return
/// was inferred to be a "guaranteed type", that means, it is a type that we
/// can prove to be correct for all executions of the program.
class GlobalTypeInferenceResults {
  // TODO(sigmund): store relevant data & drop reference to inference engine.
  final TypeGraphInferrer _inferrer;
  final ClosedWorld closedWorld;
  final Map<MemberElement, GlobalTypeInferenceMemberResult> _memberResults =
      <MemberElement, GlobalTypeInferenceMemberResult>{};
  final Map<ParameterElement, GlobalTypeInferenceParameterResult>
      _parameterResults =
      <ParameterElement, GlobalTypeInferenceParameterResult>{};

  // TODO(sigmund,johnniwinther): compute result objects eagerly and make it an
  // error to query for results that don't exist.
  GlobalTypeInferenceMemberResult resultOfMember(MemberElement member) {
    assert(
        !member.isGenerativeConstructorBody,
        failedAt(
            member,
            "unexpected input: ConstructorBodyElements are created"
            " after global type inference, no data is avaiable for them."));

    bool isJsInterop = closedWorld.nativeData.isJsInteropMember(member);
    return _memberResults.putIfAbsent(
        member,
        () => new GlobalTypeInferenceMemberResultImpl(
            member,
            // We store data in the context of the enclosing method, even
            // for closure elements.
            _inferrer.inferrer.lookupDataOfMember(member.memberContext),
            _inferrer,
            isJsInterop,
            dynamicType));
  }

  // TODO(sigmund,johnniwinther): compute result objects eagerly and make it an
  // error to query for results that don't exist.
  GlobalTypeInferenceElementResult resultOfParameter(
      ParameterElement parameter) {
    return _parameterResults.putIfAbsent(
        parameter,
        () => new GlobalTypeInferenceParameterResult(
            parameter, _inferrer, dynamicType));
  }

  GlobalTypeInferenceResults(this._inferrer, this.closedWorld);

  TypeMask get dynamicType => closedWorld.commonMasks.dynamicType;

  /// Returns the type of a [selector] when applied to a receiver with the given
  /// type [mask].
  TypeMask typeOfSelector(Selector selector, TypeMask mask) =>
      _inferrer.getTypeOfSelector(selector, mask);

  /// Returns whether a fixed-length constructor call goes through a growable
  /// check.
  // TODO(sigmund): move into the result of the element containing such
  // constructor call.
  bool isFixedArrayCheckedForGrowable(Node ctorCall) =>
      _inferrer.isFixedArrayCheckedForGrowable(ctorCall);
}

/// Global analysis that infers concrete types.
class GlobalTypeInferenceTask extends CompilerTask {
  // TODO(sigmund): rename at the same time as our benchmarking tools.
  final String name = 'Type inference';

  final Compiler compiler;

  /// The [TypeGraphInferrer] used by the global type inference. This should by
  /// accessed from outside this class for testing only.
  TypeGraphInferrer typesInferrerInternal;

  GlobalTypeInferenceResults results;

  GlobalTypeInferenceTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer);

  /// Runs the global type-inference algorithm once.
  void runGlobalTypeInference(FunctionEntity mainElement,
      ClosedWorld closedWorld, ClosedWorldRefiner closedWorldRefiner) {
    measure(() {
      typesInferrerInternal ??=
          new TypeGraphInferrer(compiler, closedWorld, closedWorldRefiner);
      typesInferrerInternal.analyzeMain(mainElement);
      typesInferrerInternal.clear();
      results =
          new GlobalTypeInferenceResults(typesInferrerInternal, closedWorld);
    });
  }
}
