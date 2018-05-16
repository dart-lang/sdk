// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import '../common.dart' show failedAt;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/entities.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../universe/selector.dart' show Selector;
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
abstract class GlobalTypeInferenceElementResult<T> {
  /// Whether the method element associated with this result always throws.
  bool get throwsAlways;

  /// The inferred type when this result belongs to a parameter or field
  /// element, null otherwise.
  TypeMask get type;

  /// The inferred return type when this result belongs to a function element.
  TypeMask get returnType;

  /// Returns the type of a list new expression [node].
  TypeMask typeOfNewList(T node);

  /// Returns the type of a list literal [node].
  TypeMask typeOfListLiteral(T node);

  /// Returns the type of a send [node].
  // TODO(johnniwinther): Rename this.
  TypeMask typeOfSend(T node);

  /// Returns the type of the getter in a complex send-set [node], for example,
  /// the type of the `a.f` getter in `a.f += b`.
  TypeMask typeOfGetter(T node);

  /// Returns the type of the iterator in a [loop].
  TypeMask typeOfIterator(T node);

  /// Returns the type of the `moveNext` call of an iterator in a [loop].
  TypeMask typeOfIteratorMoveNext(T node);

  /// Returns the type of the `current` getter of an iterator in a [loop].
  TypeMask typeOfIteratorCurrent(T node);
}

abstract class GlobalTypeInferenceMemberResult<T>
    extends GlobalTypeInferenceElementResult<T> {
  /// Whether the member associated with this result is only called once in one
  /// location in the entire program.
  bool get isCalledOnce;
}

abstract class GlobalTypeInferenceParameterResult<T>
    extends GlobalTypeInferenceElementResult<T> {}

abstract class GlobalTypeInferenceElementResultImpl<T>
    implements GlobalTypeInferenceElementResult<T> {
  // TODO(sigmund): split - stop using _data after inference is done.
  final GlobalTypeInferenceElementData<T> _data;

  // TODO(sigmund): store relevant data & drop reference to inference engine.
  final TypesInferrer<T> _inferrer;
  final bool _isJsInterop;
  final TypeMask _dynamic;

  GlobalTypeInferenceElementResultImpl(
      this._data, this._inferrer, this._isJsInterop, this._dynamic);

  bool get throwsAlways {
    TypeMask mask = this.returnType;
    // Always throws if the return type was inferred to be non-null empty.
    return mask != null && mask.isEmpty;
  }

  TypeMask typeOfNewList(T node) => _inferrer.getTypeForNewList(node);

  TypeMask typeOfListLiteral(T node) => _inferrer.getTypeForNewList(node);

  TypeMask typeOfSend(T node) => _data?.typeOfSend(node);
  TypeMask typeOfGetter(T node) => _data?.typeOfGetter(node);
  TypeMask typeOfIterator(T node) => _data?.typeOfIterator(node);
  TypeMask typeOfIteratorMoveNext(T node) =>
      _data?.typeOfIteratorMoveNext(node);
  TypeMask typeOfIteratorCurrent(T node) => _data?.typeOfIteratorCurrent(node);
}

class GlobalTypeInferenceMemberResultImpl<T>
    extends GlobalTypeInferenceElementResultImpl<T>
    implements GlobalTypeInferenceMemberResult<T> {
  // TODO(sigmund): delete, store data directly here.
  final MemberEntity _owner;

  GlobalTypeInferenceMemberResultImpl(
      this._owner,
      GlobalTypeInferenceElementData data,
      TypesInferrer inferrer,
      bool isJsInterop,
      TypeMask _dynamic)
      : super(data, inferrer, isJsInterop, _dynamic);

  bool get isCalledOnce => _inferrer.isMemberCalledOnce(_owner);

  TypeMask get returnType =>
      _isJsInterop ? _dynamic : _inferrer.getReturnTypeOfMember(_owner);

  TypeMask get type =>
      _isJsInterop ? _dynamic : _inferrer.getTypeOfMember(_owner);
}

class GlobalTypeInferenceParameterResultImpl<T>
    extends GlobalTypeInferenceElementResultImpl<T>
    implements GlobalTypeInferenceParameterResult<T> {
  // TODO(sigmund): delete, store data directly here.
  final Local _owner;

  GlobalTypeInferenceParameterResultImpl(
      this._owner, TypesInferrer inferrer, TypeMask _dynamic)
      : super(null, inferrer, false, _dynamic);

  TypeMask get returnType =>
      _isJsInterop ? _dynamic : _inferrer.getReturnTypeOfParameter(_owner);

  TypeMask get type =>
      _isJsInterop ? _dynamic : _inferrer.getTypeOfParameter(_owner);
}

/// Internal data used during type-inference to store intermediate results about
/// a single element.
abstract class GlobalTypeInferenceElementData<T> {
  // TODO(johnniwinther): Remove this. Maybe split by access/invoke.
  TypeMask typeOfSend(T node);
  TypeMask typeOfGetter(T node);

  void setTypeMask(T node, TypeMask mask);

  TypeMask typeOfIterator(T node);

  TypeMask typeOfIteratorMoveNext(T node);

  TypeMask typeOfIteratorCurrent(T node);

  void setIteratorTypeMask(T node, TypeMask mask);

  void setMoveNextTypeMask(T node, TypeMask mask);

  void setCurrentTypeMask(T node, TypeMask mask);
}

/// API to interact with the global type-inference engine.
abstract class TypesInferrer<T> {
  void analyzeMain(FunctionEntity element);
  TypeMask getReturnTypeOfMember(MemberEntity element);
  TypeMask getReturnTypeOfParameter(Local element);
  TypeMask getTypeOfMember(MemberEntity element);
  TypeMask getTypeOfParameter(Local element);
  TypeMask getTypeForNewList(T node);
  TypeMask getTypeOfSelector(Selector selector, TypeMask mask);
  void clear();
  bool isMemberCalledOnce(MemberEntity element);
  bool isFixedArrayCheckedForGrowable(T node);
  GlobalTypeInferenceResults createResults();
}

/// Results produced by the global type-inference algorithm.
///
/// All queries in this class may contain results that assume whole-program
/// closed-world semantics. Any [TypeMask] for an element or node that we return
/// was inferred to be a "guaranteed type", that means, it is a type that we
/// can prove to be correct for all executions of the program.
abstract class GlobalTypeInferenceResults<T> {
  // TODO(sigmund): store relevant data & drop reference to inference engine.
  final TypeGraphInferrer<T> _inferrer;
  final ClosedWorld closedWorld;
  final Map<MemberEntity, GlobalTypeInferenceMemberResult<T>> _memberResults =
      <MemberEntity, GlobalTypeInferenceMemberResult<T>>{};
  final Map<Local, GlobalTypeInferenceParameterResult<T>> _parameterResults =
      <Local, GlobalTypeInferenceParameterResult<T>>{};

  GlobalTypeInferenceResults(this._inferrer, this.closedWorld);

  /// Create the [GlobalTypeInferenceMemberResult] object for [member].
  GlobalTypeInferenceMemberResult<T> createMemberResult(
      TypeGraphInferrer<T> inferrer, MemberEntity member,
      {bool isJsInterop: false});

  /// Create the [GlobalTypeInferenceParameterResult] object for [parameter].
  GlobalTypeInferenceParameterResult<T> createParameterResult(
      TypeGraphInferrer<T> inferrer, Local parameter);

  // TODO(sigmund,johnniwinther): compute result objects eagerly and make it an
  // error to query for results that don't exist.
  GlobalTypeInferenceMemberResult<T> resultOfMember(MemberEntity member) {
    assert(
        member is! ConstructorBodyEntity,
        failedAt(
            member,
            "unexpected input: ConstructorBodyElements are created"
            " after global type inference, no data is avaiable for them."));

    bool isJsInterop = closedWorld.nativeData.isJsInteropMember(member);
    return _memberResults.putIfAbsent(member,
        () => createMemberResult(_inferrer, member, isJsInterop: isJsInterop));
  }

  // TODO(sigmund,johnniwinther): compute result objects eagerly and make it an
  // error to query for results that don't exist.
  GlobalTypeInferenceElementResult<T> resultOfParameter(Local parameter) {
    return _parameterResults.putIfAbsent(
        parameter, () => createParameterResult(_inferrer, parameter));
  }

  TypeMask get dynamicType => closedWorld.abstractValueDomain.dynamicType;

  /// Returns the type of a [selector] when applied to a receiver with the given
  /// type [mask].
  TypeMask typeOfSelector(Selector selector, TypeMask mask) =>
      _inferrer.getTypeOfSelector(selector, mask);

  /// Returns whether a fixed-length constructor call goes through a growable
  /// check.
  // TODO(sigmund): move into the result of the element containing such
  // constructor call.
  bool isFixedArrayCheckedForGrowable(T ctorCall) =>
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
      typesInferrerInternal ??= compiler.backendStrategy.createTypesInferrer(
          closedWorldRefiner,
          disableTypeInference: compiler.disableTypeInference);
      typesInferrerInternal.analyzeMain(mainElement);
      typesInferrerInternal.clear();
      results = typesInferrerInternal.createResults();
      closedWorld.noSuchMethodData.categorizeComplexImplementations(results);
    });
  }
}
