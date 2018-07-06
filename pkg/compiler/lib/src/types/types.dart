// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import 'package:kernel/ast.dart' as ir;
import '../common.dart' show failedAt;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/entities.dart';
import '../js_backend/inferred_data.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../universe/selector.dart' show Selector;
import '../world.dart' show JClosedWorld;
import 'abstract_value_domain.dart';

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
  AbstractValue get type;

  /// The inferred return type when this result belongs to a function element.
  AbstractValue get returnType;

  /// Returns the type of a list new expression [node].
  AbstractValue typeOfNewList(ir.Node node);

  /// Returns the type of a list literal [node].
  AbstractValue typeOfListLiteral(ir.Node node);

  /// Returns the type of a send [node].
  // TODO(johnniwinther): Rename this.
  AbstractValue typeOfSend(ir.Node node);

  /// Returns the type of the getter in a complex send-set [node], for example,
  /// the type of the `a.f` getter in `a.f += b`.
  AbstractValue typeOfGetter(ir.Node node);

  /// Returns the type of the iterator in a [loop].
  AbstractValue typeOfIterator(ir.Node node);

  /// Returns the type of the `moveNext` call of an iterator in a [loop].
  AbstractValue typeOfIteratorMoveNext(ir.Node node);

  /// Returns the type of the `current` getter of an iterator in a [loop].
  AbstractValue typeOfIteratorCurrent(ir.Node node);
}

abstract class GlobalTypeInferenceMemberResult
    extends GlobalTypeInferenceElementResult {
  /// Whether the member associated with this result is only called once in one
  /// location in the entire program.
  bool get isCalledOnce;
}

abstract class GlobalTypeInferenceParameterResult
    extends GlobalTypeInferenceElementResult {}

abstract class GlobalTypeInferenceElementResultImpl
    implements GlobalTypeInferenceElementResult {
  // TODO(sigmund): split - stop using _data after inference is done.
  final GlobalTypeInferenceElementData _data;

  // TODO(sigmund): store relevant data & drop reference to inference engine.
  final TypesInferrer _inferrer;
  final bool _isJsInterop;

  GlobalTypeInferenceElementResultImpl(
      this._data, this._inferrer, this._isJsInterop);

  bool get throwsAlways {
    AbstractValue mask = this.returnType;
    // Always throws if the return type was inferred to be non-null empty.
    return mask != null && _inferrer.abstractValueDomain.isEmpty(mask);
  }

  AbstractValue typeOfNewList(ir.Node node) =>
      _inferrer.getTypeForNewList(node);

  AbstractValue typeOfListLiteral(ir.Node node) =>
      _inferrer.getTypeForNewList(node);

  AbstractValue typeOfSend(ir.Node node) => _data?.typeOfSend(node);
  AbstractValue typeOfGetter(ir.Node node) => _data?.typeOfGetter(node);
  AbstractValue typeOfIterator(ir.Node node) => _data?.typeOfIterator(node);
  AbstractValue typeOfIteratorMoveNext(ir.Node node) =>
      _data?.typeOfIteratorMoveNext(node);
  AbstractValue typeOfIteratorCurrent(ir.Node node) =>
      _data?.typeOfIteratorCurrent(node);
}

class GlobalTypeInferenceMemberResultImpl
    extends GlobalTypeInferenceElementResultImpl
    implements GlobalTypeInferenceMemberResult {
  // TODO(sigmund): delete, store data directly here.
  final MemberEntity _owner;

  GlobalTypeInferenceMemberResultImpl(
      this._owner,
      GlobalTypeInferenceElementData data,
      TypesInferrer inferrer,
      bool isJsInterop)
      : super(data, inferrer, isJsInterop);

  bool get isCalledOnce => _inferrer.isMemberCalledOnce(_owner);

  AbstractValue get returnType => _isJsInterop
      ? _inferrer.abstractValueDomain.dynamicType
      : _inferrer.getReturnTypeOfMember(_owner);

  AbstractValue get type => _isJsInterop
      ? _inferrer.abstractValueDomain.dynamicType
      : _inferrer.getTypeOfMember(_owner);
}

class GlobalTypeInferenceParameterResultImpl
    extends GlobalTypeInferenceElementResultImpl
    implements GlobalTypeInferenceParameterResult {
  // TODO(sigmund): delete, store data directly here.
  final Local _owner;

  GlobalTypeInferenceParameterResultImpl(this._owner, TypesInferrer inferrer)
      : super(null, inferrer, false);

  AbstractValue get returnType => _isJsInterop
      ? _inferrer.abstractValueDomain.dynamicType
      : _inferrer.getReturnTypeOfParameter(_owner);

  AbstractValue get type => _isJsInterop
      ? _inferrer.abstractValueDomain.dynamicType
      : _inferrer.getTypeOfParameter(_owner);
}

/// Internal data used during type-inference to store intermediate results about
/// a single element.
abstract class GlobalTypeInferenceElementData {
  // TODO(johnniwinther): Remove this. Maybe split by access/invoke.
  AbstractValue typeOfSend(ir.Node node);
  AbstractValue typeOfGetter(ir.Node node);

  void setTypeMask(ir.Node node, AbstractValue mask);

  AbstractValue typeOfIterator(ir.Node node);

  AbstractValue typeOfIteratorMoveNext(ir.Node node);

  AbstractValue typeOfIteratorCurrent(ir.Node node);

  void setIteratorTypeMask(ir.Node node, AbstractValue mask);

  void setMoveNextTypeMask(ir.Node node, AbstractValue mask);

  void setCurrentTypeMask(ir.Node node, AbstractValue mask);
}

/// API to interact with the global type-inference engine.
abstract class TypesInferrer {
  AbstractValueDomain get abstractValueDomain;
  void analyzeMain(FunctionEntity element);
  AbstractValue getReturnTypeOfMember(MemberEntity element);
  AbstractValue getReturnTypeOfParameter(Local element);
  AbstractValue getTypeOfMember(MemberEntity element);
  AbstractValue getTypeOfParameter(Local element);
  AbstractValue getTypeForNewList(ir.Node node);
  AbstractValue getTypeOfSelector(Selector selector, AbstractValue receiver);
  void clear();
  bool isMemberCalledOnce(MemberEntity element);
  bool isFixedArrayCheckedForGrowable(ir.Node node);
  GlobalTypeInferenceResults createResults();
}

/// Results produced by the global type-inference algorithm.
///
/// All queries in this class may contain results that assume whole-program
/// closed-world semantics. Any [TypeMask] for an element or node that we return
/// was inferred to be a "guaranteed type", that means, it is a type that we
/// can prove to be correct for all executions of the program.
abstract class GlobalTypeInferenceResults {
  // TODO(sigmund): store relevant data & drop reference to inference engine.
  final TypeGraphInferrer _inferrer;
  final JClosedWorld closedWorld;
  final Map<MemberEntity, GlobalTypeInferenceMemberResult> _memberResults =
      <MemberEntity, GlobalTypeInferenceMemberResult>{};
  final Map<Local, GlobalTypeInferenceParameterResult> _parameterResults =
      <Local, GlobalTypeInferenceParameterResult>{};

  GlobalTypeInferenceResults(this._inferrer, this.closedWorld);

  /// Create the [GlobalTypeInferenceMemberResult] object for [member].
  GlobalTypeInferenceMemberResult createMemberResult(
      TypeGraphInferrer inferrer, MemberEntity member,
      {bool isJsInterop: false});

  /// Create the [GlobalTypeInferenceParameterResult] object for [parameter].
  GlobalTypeInferenceParameterResult createParameterResult(
      TypeGraphInferrer inferrer, Local parameter);

  // TODO(sigmund,johnniwinther): compute result objects eagerly and make it an
  // error to query for results that don't exist.
  GlobalTypeInferenceMemberResult resultOfMember(MemberEntity member) {
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
  GlobalTypeInferenceElementResult resultOfParameter(Local parameter) {
    return _parameterResults.putIfAbsent(
        parameter, () => createParameterResult(_inferrer, parameter));
  }

  /// Returns the type of a [selector] when applied to a receiver with the given
  /// type [mask].
  AbstractValue typeOfSelector(Selector selector, AbstractValue mask) =>
      _inferrer.getTypeOfSelector(selector, mask);

  /// Returns whether a fixed-length constructor call goes through a growable
  /// check.
  // TODO(sigmund): move into the result of the element containing such
  // constructor call.
  bool isFixedArrayCheckedForGrowable(ir.Node ctorCall) =>
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

  GlobalTypeInferenceResults resultsForTesting;

  InferredData inferredData;

  GlobalTypeInferenceTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer);

  /// Runs the global type-inference algorithm once.
  GlobalTypeInferenceResults runGlobalTypeInference(FunctionEntity mainElement,
      JClosedWorld closedWorld, InferredDataBuilder inferredDataBuilder) {
    return measure(() {
      typesInferrerInternal ??= compiler.backendStrategy.createTypesInferrer(
          closedWorld, inferredDataBuilder,
          disableTypeInference: compiler.disableTypeInference);
      typesInferrerInternal.analyzeMain(mainElement);
      typesInferrerInternal.clear();
      GlobalTypeInferenceResults results =
          typesInferrerInternal.createResults();
      closedWorld.noSuchMethodData.categorizeComplexImplementations(results);
      inferredData = inferredDataBuilder.close(closedWorld);
      resultsForTesting = results;
      return results;
    });
  }
}
