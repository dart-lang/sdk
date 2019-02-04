// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import 'package:kernel/ast.dart' as ir;
import '../common.dart' show failedAt, retainDataForTesting;
import '../common/names.dart';
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/entities.dart';
import '../js_backend/inferred_data.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../serialization/serialization.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show JClosedWorld;
import 'abstract_value_domain.dart';
import '../inferrer/inferrer_engine.dart';

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
abstract class GlobalTypeInferenceMemberResult {
  /// Deserializes a [GlobalTypeInferenceMemberResult] object from [source].
  factory GlobalTypeInferenceMemberResult.readFromDataSource(
          DataSource source, AbstractValueDomain abstractValueDomain) =
      GlobalTypeInferenceMemberResultImpl.readFromDataSource;

  /// Serializes this [GlobalTypeInferenceMemberResult] to [sink].
  void writeToDataSink(DataSink sink, AbstractValueDomain abstractValueDomain);

  /// The inferred type when this result belongs to a field, null otherwise.
  AbstractValue get type;

  /// Whether the member associated with this result is only called once in one
  /// location in the entire program.
  bool get isCalledOnce;

  /// Whether the method element associated with this result always throws.
  bool get throwsAlways;

  /// The inferred return type when this result belongs to a function element.
  AbstractValue get returnType;

  /// Returns the type of a send [node].
  // TODO(johnniwinther): Rename this.
  AbstractValue typeOfSend(ir.TreeNode node);

  /// Returns the type of the getter in a complex send-set [node], for example,
  /// the type of the `a.f` getter in `a.f += b`.
  AbstractValue typeOfGetter(ir.TreeNode node);

  /// Returns the type of the iterator in a [loop].
  AbstractValue typeOfIterator(ir.TreeNode node);

  /// Returns the type of the `moveNext` call of an iterator in a [loop].
  AbstractValue typeOfIteratorMoveNext(ir.TreeNode node);

  /// Returns the type of the `current` getter of an iterator in a [loop].
  AbstractValue typeOfIteratorCurrent(ir.TreeNode node);
}

/// Internal data used during type-inference to store intermediate results about
/// a single element.
abstract class GlobalTypeInferenceElementData {
  /// Deserializes a [GlobalTypeInferenceElementData] object from [source].
  factory GlobalTypeInferenceElementData.readFromDataSource(
          DataSource source, AbstractValueDomain abstractValueDomain) =
      KernelGlobalTypeInferenceElementData.readFromDataSource;

  /// Serializes this [GlobalTypeInferenceElementData] to [sink].
  void writeToDataSink(DataSink sink, AbstractValueDomain abstractValueDomain);

  /// Compresses the inner representation by removing [AbstractValue] mappings
  /// to `null`. Returns the data object itself or `null` if the data object
  /// was empty after compression.
  GlobalTypeInferenceElementData compress();

  // TODO(johnniwinther): Remove this. Maybe split by access/invoke.
  AbstractValue typeOfSend(ir.TreeNode node);
  AbstractValue typeOfGetter(ir.TreeNode node);

  AbstractValue typeOfIterator(ir.TreeNode node);

  AbstractValue typeOfIteratorMoveNext(ir.TreeNode node);

  AbstractValue typeOfIteratorCurrent(ir.TreeNode node);
}

/// API to interact with the global type-inference engine.
abstract class TypesInferrer {
  GlobalTypeInferenceResults analyzeMain(FunctionEntity element);
}

/// Results produced by the global type-inference algorithm.
///
/// All queries in this class may contain results that assume whole-program
/// closed-world semantics. Any [AbstractValue] for an element or node that we
/// return was inferred to be a "guaranteed type", that means, it is a type that
/// we can prove to be correct for all executions of the program.
abstract class GlobalTypeInferenceResults {
  /// Deserializes a [GlobalTypeInferenceResults] object from [source].
  factory GlobalTypeInferenceResults.readFromDataSource(
      DataSource source, JClosedWorld closedWorld, InferredData inferredData) {
    bool isTrivial = source.readBool();
    if (isTrivial) {
      return new TrivialGlobalTypeInferenceResults(closedWorld);
    }
    return new GlobalTypeInferenceResultsImpl.readFromDataSource(
        source, closedWorld, inferredData);
  }

  /// Serializes this [GlobalTypeInferenceResults] to [sink].
  void writeToDataSink(DataSink sink);

  JClosedWorld get closedWorld;

  InferredData get inferredData;

  GlobalTypeInferenceMemberResult resultOfMember(MemberEntity member);

  AbstractValue resultOfParameter(Local parameter);

  /// Returns the type of a [selector] when applied to a receiver with the given
  /// type [mask].
  AbstractValue typeOfSelector(Selector selector, AbstractValue mask);

  /// Returns whether a fixed-length constructor call goes through a growable
  /// check.
  bool isFixedArrayCheckedForGrowable(ir.TreeNode node);

  /// Returns the type of a list new expression [node].
  AbstractValue typeOfNewList(ir.TreeNode node);

  /// Returns the type of a list literal [node].
  AbstractValue typeOfListLiteral(ir.TreeNode node);
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

  GlobalTypeInferenceTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer);

  /// Runs the global type-inference algorithm once.
  GlobalTypeInferenceResults runGlobalTypeInference(FunctionEntity mainElement,
      JClosedWorld closedWorld, InferredDataBuilder inferredDataBuilder) {
    return measure(() {
      GlobalTypeInferenceResults results;
      if (compiler.disableTypeInference) {
        results = new TrivialGlobalTypeInferenceResults(closedWorld);
      } else {
        typesInferrerInternal ??= compiler.backendStrategy
            .createTypesInferrer(closedWorld, inferredDataBuilder);
        results = typesInferrerInternal.analyzeMain(mainElement);
      }
      closedWorld.noSuchMethodData.categorizeComplexImplementations(results);
      if (retainDataForTesting) {
        resultsForTesting = results;
      }
      return results;
    });
  }
}

class GlobalTypeInferenceResultsImpl implements GlobalTypeInferenceResults {
  /// Tag used for identifying serialized [GlobalTypeInferenceResults] objects
  /// in a debugging data stream.
  static const String tag = 'global-type-inference-results';

  final JClosedWorld closedWorld;
  final InferredData inferredData;
  final GlobalTypeInferenceMemberResult _deadFieldResult;
  final GlobalTypeInferenceMemberResult _deadMethodResult;
  final AbstractValue _trivialParameterResult;

  final Map<MemberEntity, GlobalTypeInferenceMemberResult> memberResults;
  final Map<Local, AbstractValue> parameterResults;
  final Set<ir.TreeNode> checkedForGrowableLists;
  final Set<Selector> returnsListElementTypeSet;
  final Map<ir.TreeNode, AbstractValue> _allocatedLists;

  GlobalTypeInferenceResultsImpl(
      this.closedWorld,
      this.inferredData,
      this.memberResults,
      this.parameterResults,
      this.checkedForGrowableLists,
      this.returnsListElementTypeSet,
      this._allocatedLists)
      : _deadFieldResult = new DeadFieldGlobalTypeInferenceResult(
            closedWorld.abstractValueDomain),
        _deadMethodResult = new DeadMethodGlobalTypeInferenceResult(
            closedWorld.abstractValueDomain),
        _trivialParameterResult = closedWorld.abstractValueDomain.dynamicType;

  factory GlobalTypeInferenceResultsImpl.readFromDataSource(
      DataSource source, JClosedWorld closedWorld, InferredData inferredData) {
    source.begin(tag);
    Map<MemberEntity, GlobalTypeInferenceMemberResult> memberResults =
        source.readMemberMap(() =>
            new GlobalTypeInferenceMemberResult.readFromDataSource(
                source, closedWorld.abstractValueDomain));
    Map<Local, AbstractValue> parameterResults = source.readLocalMap(() =>
        closedWorld.abstractValueDomain
            .readAbstractValueFromDataSource(source));
    Set<ir.TreeNode> checkedForGrowableLists = source.readTreeNodes().toSet();
    Set<Selector> returnsListElementTypeSet =
        source.readList(() => new Selector.readFromDataSource(source)).toSet();
    Map<ir.TreeNode, AbstractValue> allocatedLists = source.readTreeNodeMap(
        () => closedWorld.abstractValueDomain
            .readAbstractValueFromDataSource(source));
    source.end(tag);
    return new GlobalTypeInferenceResultsImpl(
        closedWorld,
        inferredData,
        memberResults,
        parameterResults,
        checkedForGrowableLists,
        returnsListElementTypeSet,
        allocatedLists);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeBool(false); // Is _not_ trivial.
    sink.begin(tag);
    sink.writeMemberMap(
        memberResults,
        (GlobalTypeInferenceMemberResult result) =>
            result.writeToDataSink(sink, closedWorld.abstractValueDomain));
    sink.writeLocalMap(
        parameterResults,
        (AbstractValue value) => closedWorld.abstractValueDomain
            .writeAbstractValueToDataSink(sink, value));
    sink.writeTreeNodes(checkedForGrowableLists);
    sink.writeList(returnsListElementTypeSet,
        (Selector selector) => selector.writeToDataSink(sink));
    sink.writeTreeNodeMap(
        _allocatedLists,
        (AbstractValue value) => closedWorld.abstractValueDomain
            .writeAbstractValueToDataSink(sink, value));
    sink.end(tag);
  }

  @override
  GlobalTypeInferenceMemberResult resultOfMember(MemberEntity member) {
    assert(
        member is! ConstructorBodyEntity,
        failedAt(
            member,
            "unexpected input: ConstructorBodyElements are created"
            " after global type inference, no data is avaiable for them."));
    // TODO(sigmund,johnniwinther): Make it an error to query for results that
    // don't exist..
    /*assert(memberResults.containsKey(member) || member is JSignatureMethod,
        "No inference result for member $member");*/
    return memberResults[member] ??
        (member is FunctionEntity ? _deadMethodResult : _deadFieldResult);
  }

  @override
  AbstractValue resultOfParameter(Local parameter) {
    // TODO(sigmund,johnniwinther): Make it an error to query for results that
    // don't exist.
    /*assert(parameterResults.containsKey(parameter),
        "No inference result for parameter $parameter");*/
    return parameterResults[parameter] ?? _trivialParameterResult;
  }

  /// Returns the type of a [selector] when applied to a receiver with the given
  /// [receiver] type.
  @override
  AbstractValue typeOfSelector(Selector selector, AbstractValue receiver) {
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall)
      return closedWorld.abstractValueDomain.dynamicType;
    if (selector.isSetter || selector.isIndexSet) {
      return closedWorld.abstractValueDomain.dynamicType;
    }
    if (returnsListElementType(selector, receiver)) {
      return closedWorld.abstractValueDomain.getContainerElementType(receiver);
    }
    if (returnsMapValueType(selector, receiver)) {
      return closedWorld.abstractValueDomain.getMapValueType(receiver);
    }

    if (closedWorld.includesClosureCall(selector, receiver)) {
      return closedWorld.abstractValueDomain.dynamicType;
    } else {
      Iterable<MemberEntity> elements =
          closedWorld.locateMembers(selector, receiver);
      List<AbstractValue> types = <AbstractValue>[];
      for (MemberEntity element in elements) {
        AbstractValue type = typeOfMemberWithSelector(element, selector);
        types.add(type);
      }
      return closedWorld.abstractValueDomain.unionOfMany(types);
    }
  }

  bool returnsListElementType(Selector selector, AbstractValue mask) {
    return mask != null &&
        closedWorld.abstractValueDomain.isContainer(mask) &&
        returnsListElementTypeSet.contains(selector);
  }

  bool returnsMapValueType(Selector selector, AbstractValue mask) {
    return mask != null &&
        closedWorld.abstractValueDomain.isMap(mask) &&
        selector.isIndex;
  }

  AbstractValue typeOfMemberWithSelector(
      MemberEntity element, Selector selector) {
    if (element.name == Identifiers.noSuchMethod_ &&
        selector.name != element.name) {
      // An invocation can resolve to a [noSuchMethod], in which case
      // we get the return type of [noSuchMethod].
      return resultOfMember(element).returnType;
    } else if (selector.isGetter) {
      if (element.isFunction) {
        // [functionType] is null if the inferrer did not run.
        return closedWorld.abstractValueDomain.functionType;
      } else if (element.isField) {
        return resultOfMember(element).type;
      } else if (element.isGetter) {
        return resultOfMember(element).returnType;
      } else {
        assert(false, failedAt(element, "Unexpected member $element"));
        return closedWorld.abstractValueDomain.dynamicType;
      }
    } else if (element.isGetter || element.isField) {
      assert(selector.isCall || selector.isSetter);
      return closedWorld.abstractValueDomain.dynamicType;
    } else {
      return resultOfMember(element).returnType;
    }
  }

  /// Returns whether a fixed-length constructor call goes through a growable
  /// check.
  // TODO(sigmund): move into the result of the element containing such
  // constructor call.
  @override
  bool isFixedArrayCheckedForGrowable(ir.Node ctorCall) =>
      checkedForGrowableLists.contains(ctorCall);

  AbstractValue typeOfNewList(ir.Node node) => _allocatedLists[node];

  AbstractValue typeOfListLiteral(ir.Node node) => _allocatedLists[node];
}

class GlobalTypeInferenceMemberResultImpl
    implements GlobalTypeInferenceMemberResult {
  /// Tag used for identifying serialized [GlobalTypeInferenceMemberResult]
  /// objects in a debugging data stream.
  static const String tag = 'global-type-inference-member-result';

  final GlobalTypeInferenceElementData _data;
  final AbstractValue returnType;
  final AbstractValue type;
  final bool throwsAlways;
  final bool isCalledOnce;

  GlobalTypeInferenceMemberResultImpl(this._data, this.returnType, this.type,
      {this.throwsAlways, this.isCalledOnce});

  factory GlobalTypeInferenceMemberResultImpl.readFromDataSource(
      DataSource source, AbstractValueDomain abstractValueDomain) {
    source.begin(tag);
    GlobalTypeInferenceElementData data = source.readValueOrNull(() {
      return new GlobalTypeInferenceElementData.readFromDataSource(
          source, abstractValueDomain);
    });
    AbstractValue returnType =
        abstractValueDomain.readAbstractValueFromDataSource(source);
    AbstractValue type =
        abstractValueDomain.readAbstractValueFromDataSource(source);
    bool throwsAlways = source.readBool();
    bool isCalledOnce = source.readBool();
    source.end(tag);
    return new GlobalTypeInferenceMemberResultImpl(data, returnType, type,
        throwsAlways: throwsAlways, isCalledOnce: isCalledOnce);
  }

  void writeToDataSink(DataSink sink, AbstractValueDomain abstractValueDomain) {
    sink.begin(tag);
    sink.writeValueOrNull(_data, (GlobalTypeInferenceElementData data) {
      data.writeToDataSink(sink, abstractValueDomain);
    });
    abstractValueDomain.writeAbstractValueToDataSink(sink, returnType);
    abstractValueDomain.writeAbstractValueToDataSink(sink, type);
    sink.writeBool(throwsAlways);
    sink.writeBool(isCalledOnce);
    sink.end(tag);
  }

  AbstractValue typeOfSend(ir.Node node) => _data?.typeOfSend(node);
  AbstractValue typeOfGetter(ir.Node node) => _data?.typeOfGetter(node);
  AbstractValue typeOfIterator(ir.Node node) => _data?.typeOfIterator(node);
  AbstractValue typeOfIteratorMoveNext(ir.Node node) =>
      _data?.typeOfIteratorMoveNext(node);
  AbstractValue typeOfIteratorCurrent(ir.Node node) =>
      _data?.typeOfIteratorCurrent(node);
}

class TrivialGlobalTypeInferenceResults implements GlobalTypeInferenceResults {
  final JClosedWorld closedWorld;
  final TrivialGlobalTypeInferenceMemberResult _trivialMemberResult;
  final AbstractValue _trivialParameterResult;
  final InferredData inferredData = new TrivialInferredData();

  TrivialGlobalTypeInferenceResults(this.closedWorld)
      : _trivialMemberResult = new TrivialGlobalTypeInferenceMemberResult(
            closedWorld.abstractValueDomain.dynamicType),
        _trivialParameterResult = closedWorld.abstractValueDomain.dynamicType;

  void writeToDataSink(DataSink sink) {
    sink.writeBool(true); // Is trivial.
  }

  @override
  bool isFixedArrayCheckedForGrowable(ir.Node node) => false;

  @override
  AbstractValue typeOfSelector(Selector selector, AbstractValue mask) {
    return closedWorld.abstractValueDomain.dynamicType;
  }

  @override
  AbstractValue resultOfParameter(Local parameter) {
    return _trivialParameterResult;
  }

  @override
  GlobalTypeInferenceMemberResult resultOfMember(MemberEntity member) {
    return _trivialMemberResult;
  }

  @override
  AbstractValue typeOfListLiteral(ir.TreeNode node) => null;

  @override
  AbstractValue typeOfNewList(ir.TreeNode node) => null;
}

class TrivialGlobalTypeInferenceMemberResult
    implements GlobalTypeInferenceMemberResult {
  final AbstractValue dynamicType;

  TrivialGlobalTypeInferenceMemberResult(this.dynamicType);

  @override
  AbstractValue get type => dynamicType;

  @override
  AbstractValue get returnType => dynamicType;

  @override
  bool get throwsAlways => false;

  @override
  AbstractValue typeOfIteratorCurrent(ir.Node node) => null;

  @override
  AbstractValue typeOfIteratorMoveNext(ir.Node node) => null;

  @override
  AbstractValue typeOfIterator(ir.Node node) => null;

  @override
  AbstractValue typeOfGetter(ir.Node node) => null;

  @override
  AbstractValue typeOfSend(ir.Node node) => null;

  @override
  bool get isCalledOnce => false;

  void writeToDataSink(DataSink sink, AbstractValueDomain abstractValueDomain) {
    throw new UnsupportedError(
        "TrivialGlobalTypeInferenceMemberResult.writeToDataSink");
  }
}

class DeadFieldGlobalTypeInferenceResult
    implements GlobalTypeInferenceMemberResult {
  final AbstractValue dynamicType;
  final AbstractValue emptyType;

  DeadFieldGlobalTypeInferenceResult(AbstractValueDomain domain)
      : this.dynamicType = domain.dynamicType,
        this.emptyType = domain.emptyType;

  @override
  AbstractValue get type => emptyType;

  @override
  AbstractValue get returnType => dynamicType;

  @override
  bool get throwsAlways => false;

  @override
  AbstractValue typeOfIteratorCurrent(ir.Node node) => null;

  @override
  AbstractValue typeOfIteratorMoveNext(ir.Node node) => null;

  @override
  AbstractValue typeOfIterator(ir.Node node) => null;

  @override
  AbstractValue typeOfGetter(ir.Node node) => null;

  @override
  AbstractValue typeOfSend(ir.Node node) => null;

  @override
  bool get isCalledOnce => false;

  void writeToDataSink(DataSink sink, AbstractValueDomain abstractValueDomain) {
    throw new UnsupportedError(
        "DeadFieldGlobalTypeInferenceResult.writeToDataSink");
  }
}

class DeadMethodGlobalTypeInferenceResult
    implements GlobalTypeInferenceMemberResult {
  final AbstractValue emptyType;
  final AbstractValue functionType;

  DeadMethodGlobalTypeInferenceResult(AbstractValueDomain domain)
      : this.functionType = domain.functionType,
        this.emptyType = domain.emptyType;

  @override
  AbstractValue get type => functionType;

  @override
  AbstractValue get returnType => emptyType;

  @override
  bool get throwsAlways => false;

  @override
  AbstractValue typeOfIteratorCurrent(ir.Node node) => null;

  @override
  AbstractValue typeOfIteratorMoveNext(ir.Node node) => null;

  @override
  AbstractValue typeOfIterator(ir.Node node) => null;

  @override
  AbstractValue typeOfGetter(ir.Node node) => null;

  @override
  AbstractValue typeOfSend(ir.Node node) => null;

  @override
  bool get isCalledOnce => false;

  void writeToDataSink(DataSink sink, AbstractValueDomain abstractValueDomain) {
    throw new UnsupportedError(
        "DeadFieldGlobalTypeInferenceResult.writeToDataSink");
  }
}
