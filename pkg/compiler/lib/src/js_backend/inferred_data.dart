// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show Queue;

import '../common.dart';
import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../serialization/serialization.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import '../world.dart';
import 'annotations.dart';

abstract class InferredData {
  /// Deserializes a [InferredData] object from [source].
  factory InferredData.readFromDataSource(
      DataSource source, JClosedWorld closedWorld) {
    bool isTrivial = source.readBool();
    if (isTrivial) {
      return new TrivialInferredData();
    } else {
      return new InferredDataImpl.readFromDataSource(source, closedWorld);
    }
  }

  /// Serializes this [InferredData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Returns the side effects of executing [element].
  SideEffects getSideEffectsOfElement(FunctionEntity element);

  /// Returns the side effects of calling [selector] on the [receiver].
  SideEffects getSideEffectsOfSelector(
      Selector selector, AbstractValue receiver);

  /// Returns `true` if [element] is guaranteed not to throw an exception.
  bool getCannotThrow(FunctionEntity element);

  /// Returns `true` if [element] is called in a loop.
  // TODO(johnniwinther): Is this 'potentially called' or 'known to be called'?
  // TODO(johnniwinther): Change [MemberEntity] to [FunctionEntity].
  bool isCalledInLoop(MemberEntity element);

  /// Returns `true` if [element] might be passed to `Function.apply`.
  // TODO(johnniwinther): Is this 'passed invocation target` or
  // `passed as argument`?
  bool getMightBePassedToApply(FunctionEntity element);
}

abstract class InferredDataBuilder {
  /// Registers the executing of [element] as without side effects.
  void registerSideEffectsFree(FunctionEntity element);

  /// Returns the [SideEffectBuilder] associated with [element].
  SideEffectsBuilder getSideEffectsBuilder(FunctionEntity member);

  /// Registers that [element] might be passed to `Function.apply`.
  // TODO(johnniwinther): Is this 'passed invocation target` or
  // `passed as argument`?
  void registerMightBePassedToApply(FunctionEntity element);

  /// Returns `true` if [element] might be passed to `Function.apply` given the
  /// currently inferred information.
  bool getCurrentlyKnownMightBePassedToApply(FunctionEntity element);

  /// Registers that [element] is called in a loop.
  // TODO(johnniwinther): Is this 'potentially called' or 'known to be called'?
  void addFunctionCalledInLoop(MemberEntity element);

  /// Registers that [element] is guaranteed not to throw an exception.
  void registerCannotThrow(FunctionEntity element);

  /// Create a [InferredData] object for the collected information.
  InferredData close(JClosedWorld closedWorld);
}

class InferredDataImpl implements InferredData {
  /// Tag used for identifying serialized [InferredData] objects in a
  /// debugging data stream.
  static const String tag = 'inferred-data';

  final JClosedWorld _closedWorld;
  final Set<MemberEntity> _functionsCalledInLoop;
  final Map<FunctionEntity, SideEffects> _sideEffects;

  final Set<FunctionEntity> _sideEffectsFreeElements;

  final Set<FunctionEntity> _elementsThatCannotThrow;

  final Set<FunctionEntity> _functionsThatMightBePassedToApply;

  InferredDataImpl(
      this._closedWorld,
      this._functionsCalledInLoop,
      this._sideEffects,
      this._sideEffectsFreeElements,
      this._elementsThatCannotThrow,
      this._functionsThatMightBePassedToApply);

  factory InferredDataImpl.readFromDataSource(
      DataSource source, JClosedWorld closedWorld) {
    source.begin(tag);
    Set<MemberEntity> functionsCalledInLoop = source.readMembers().toSet();
    Map<FunctionEntity, SideEffects> sideEffects = source.readMemberMap(
        (MemberEntity member) => new SideEffects.readFromDataSource(source));
    Set<FunctionEntity> sideEffectsFreeElements =
        source.readMembers<FunctionEntity>().toSet();
    Set<FunctionEntity> elementsThatCannotThrow =
        source.readMembers<FunctionEntity>().toSet();
    Set<FunctionEntity> functionsThatMightBePassedToApply =
        source.readMembers<FunctionEntity>().toSet();
    source.end(tag);
    return new InferredDataImpl(
        closedWorld,
        functionsCalledInLoop,
        sideEffects,
        sideEffectsFreeElements,
        elementsThatCannotThrow,
        functionsThatMightBePassedToApply);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeBool(false); // Is _not_ trivial.
    sink.begin(tag);
    sink.writeMembers(_functionsCalledInLoop);
    sink.writeMemberMap(
        _sideEffects,
        (MemberEntity member, SideEffects sideEffects) =>
            sideEffects.writeToDataSink(sink));
    sink.writeMembers(_sideEffectsFreeElements);
    sink.writeMembers(_elementsThatCannotThrow);
    sink.writeMembers(_functionsThatMightBePassedToApply);
    sink.end(tag);
  }

  @override
  SideEffects getSideEffectsOfSelector(
      Selector selector, AbstractValue receiver) {
    // We're not tracking side effects of closures.
    if (selector.isClosureCall ||
        _closedWorld.includesClosureCall(selector, receiver)) {
      return new SideEffects();
    }
    SideEffects sideEffects = new SideEffects.empty();
    for (MemberEntity e in _closedWorld.locateMembers(selector, receiver)) {
      if (e.isField) {
        if (selector.isGetter) {
          if (!_closedWorld.fieldNeverChanges(e)) {
            sideEffects.setDependsOnInstancePropertyStore();
          }
        } else if (selector.isSetter) {
          sideEffects.setChangesInstanceProperty();
        } else {
          assert(selector.isCall);
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      } else {
        sideEffects.add(getSideEffectsOfElement(e));
      }
    }
    return sideEffects;
  }

  @override
  SideEffects getSideEffectsOfElement(FunctionEntity element) {
    assert(_sideEffects != null,
        failedAt(element, "Side effects have not been computed yet."));
    // TODO(johnniwinther): Check that [_makeSideEffects] is only called if
    // type inference has been disabled (explicitly or because of compile time
    // errors).
    return _sideEffects.putIfAbsent(element, _makeSideEffects);
  }

  static SideEffects _makeSideEffects() => new SideEffects();

  @override
  bool isCalledInLoop(MemberEntity element) {
    return _functionsCalledInLoop.contains(element);
  }

  @override
  bool getCannotThrow(FunctionEntity element) {
    return _elementsThatCannotThrow.contains(element);
  }

  @override
  bool getMightBePassedToApply(FunctionEntity element) {
    // We assume all functions reach Function.apply if no functions are
    // registered so.  We get an empty set in two circumstances (1) a trivial
    // program and (2) when compiling without type inference
    // (i.e. --disable-type-inference). Returning `true` has consequences (extra
    // metadata for Function.apply) only when Function.apply is also part of the
    // program. It is an unusual trivial program that includes Function.apply
    // but does not call it on a function.
    //
    // TODO(sra): We should reverse the sense of this set and register functions
    // that we have proven do not reach Function.apply.
    if (_functionsThatMightBePassedToApply.isEmpty) return true;
    return _functionsThatMightBePassedToApply.contains(element);
  }
}

class InferredDataBuilderImpl implements InferredDataBuilder {
  final Set<MemberEntity> _functionsCalledInLoop = new Set<MemberEntity>();
  Map<MemberEntity, SideEffectsBuilder> _sideEffectsBuilders =
      <MemberEntity, SideEffectsBuilder>{};
  final Set<FunctionEntity> prematureSideEffectAccesses =
      new Set<FunctionEntity>();

  final Set<FunctionEntity> _sideEffectsFreeElements =
      new Set<FunctionEntity>();

  final Set<FunctionEntity> _elementsThatCannotThrow =
      new Set<FunctionEntity>();

  final Set<FunctionEntity> _functionsThatMightBePassedToApply =
      new Set<FunctionEntity>();

  InferredDataBuilderImpl(AnnotationsData annotationsData) {
    annotationsData.forEachNoThrows(registerCannotThrow);
    annotationsData.forEachNoSideEffects(registerSideEffectsFree);
  }

  @override
  SideEffectsBuilder getSideEffectsBuilder(MemberEntity member) {
    return _sideEffectsBuilders[member] ??= new SideEffectsBuilder(member);
  }

  @override
  void registerSideEffectsFree(FunctionEntity element) {
    _sideEffectsFreeElements.add(element);
    assert(!_sideEffectsBuilders.containsKey(element));
    _sideEffectsBuilders[element] = new SideEffectsBuilder.free(element);
  }

  /// Compute [SideEffects] for all registered [SideEffectBuilder]s.
  @override
  InferredData close(JClosedWorld closedWorld) {
    assert(_sideEffectsBuilders != null,
        "Inferred data has already been computed.");
    Map<FunctionEntity, SideEffects> _sideEffects =
        <FunctionEntity, SideEffects>{};
    Iterable<SideEffectsBuilder> sideEffectsBuilders =
        _sideEffectsBuilders.values;
    emptyWorkList(sideEffectsBuilders);
    for (SideEffectsBuilder sideEffectsBuilder in sideEffectsBuilders) {
      _sideEffects[sideEffectsBuilder.member] = sideEffectsBuilder.sideEffects;
    }
    _sideEffectsBuilders = null;

    return new InferredDataImpl(
        closedWorld,
        _functionsCalledInLoop,
        _sideEffects,
        _sideEffectsFreeElements,
        _elementsThatCannotThrow,
        _functionsThatMightBePassedToApply);
  }

  static void emptyWorkList(Iterable<SideEffectsBuilder> sideEffectsBuilders) {
    // TODO(johnniwinther): Optimize this algorithm.
    Queue<SideEffectsBuilder> queue = new Queue<SideEffectsBuilder>();
    Set<SideEffectsBuilder> inQueue = new Set<SideEffectsBuilder>();

    for (SideEffectsBuilder builder in sideEffectsBuilders) {
      queue.addLast(builder);
      inQueue.add(builder);
    }
    while (queue.isNotEmpty) {
      SideEffectsBuilder sideEffectsBuilder = queue.removeFirst();
      inQueue.remove(sideEffectsBuilder);
      for (SideEffectsBuilder dependent in sideEffectsBuilder.depending) {
        if (dependent.add(sideEffectsBuilder.sideEffects)) {
          if (inQueue.add(dependent)) {
            queue.addLast(dependent);
          }
        }
      }
    }
  }

  @override
  void addFunctionCalledInLoop(MemberEntity element) {
    _functionsCalledInLoop.add(element);
  }

  @override
  void registerCannotThrow(FunctionEntity element) {
    _elementsThatCannotThrow.add(element);
  }

  @override
  void registerMightBePassedToApply(FunctionEntity element) {
    _functionsThatMightBePassedToApply.add(element);
  }

  @override
  bool getCurrentlyKnownMightBePassedToApply(FunctionEntity element) {
    return _functionsThatMightBePassedToApply.contains(element);
  }
}

class TrivialInferredData implements InferredData {
  final SideEffects _allSideEffects = new SideEffects();

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeBool(true); // Is trivial.
  }

  @override
  SideEffects getSideEffectsOfElement(FunctionEntity element) {
    return _allSideEffects;
  }

  @override
  bool getMightBePassedToApply(FunctionEntity element) => true;

  @override
  bool isCalledInLoop(MemberEntity element) => true;

  @override
  bool getCannotThrow(FunctionEntity element) => false;

  @override
  SideEffects getSideEffectsOfSelector(
      Selector selector, AbstractValue receiver) {
    return _allSideEffects;
  }
}
