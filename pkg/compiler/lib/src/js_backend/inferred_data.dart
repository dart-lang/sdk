// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show Queue;

import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js_model/js_world.dart';
import '../serialization/serialization.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import 'annotations.dart';

abstract class InferredData {
  /// Deserializes a [InferredData] object from [source].
  factory InferredData.readFromDataSource(
      DataSourceReader source, JClosedWorld closedWorld) {
    bool isTrivial = source.readBool();
    if (isTrivial) {
      return TrivialInferredData();
    } else {
      return InferredDataImpl.readFromDataSource(source, closedWorld);
    }
  }

  /// Serializes this [InferredData] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  /// Returns the side effects of executing [element].
  SideEffects getSideEffectsOfElement(FunctionEntity element);

  /// Returns the side effects of calling [selector] on the [receiver]. A `null`
  /// [receiver] indicates the type of the receiver is unknown and therefore
  /// all matches of the selector are returned.
  SideEffects getSideEffectsOfSelector(
      Selector selector, AbstractValue? receiver);

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

  final Set<FunctionEntity> _elementsThatCannotThrow;

  final Set<FunctionEntity> _functionsThatMightBePassedToApply;

  InferredDataImpl(
      this._closedWorld,
      this._functionsCalledInLoop,
      this._sideEffects,
      this._elementsThatCannotThrow,
      this._functionsThatMightBePassedToApply);

  factory InferredDataImpl.readFromDataSource(
      DataSourceReader source, JClosedWorld closedWorld) {
    source.begin(tag);
    Set<MemberEntity> functionsCalledInLoop = source.readMembers().toSet();
    Map<FunctionEntity, SideEffects> sideEffects = source.readMemberMap(
        (MemberEntity member) => SideEffects.readFromDataSource(source));
    Set<FunctionEntity> elementsThatCannotThrow =
        source.readMembers<FunctionEntity>().toSet();
    Set<FunctionEntity> functionsThatMightBePassedToApply =
        source.readMembers<FunctionEntity>().toSet();
    source.end(tag);
    return InferredDataImpl(closedWorld, functionsCalledInLoop, sideEffects,
        elementsThatCannotThrow, functionsThatMightBePassedToApply);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeBool(false); // Is _not_ trivial.
    sink.begin(tag);
    sink.writeMembers(_functionsCalledInLoop);
    sink.writeMemberMap(
        _sideEffects,
        (MemberEntity member, SideEffects sideEffects) =>
            sideEffects.writeToDataSink(sink));
    sink.writeMembers(_elementsThatCannotThrow);
    sink.writeMembers(_functionsThatMightBePassedToApply);
    sink.end(tag);
  }

  @override
  SideEffects getSideEffectsOfSelector(
      Selector selector, AbstractValue? receiver) {
    // We're not tracking side effects of closures.
    if (selector.isClosureCall ||
        _closedWorld.includesClosureCall(selector, receiver)) {
      return SideEffects();
    }
    SideEffects sideEffects = SideEffects.empty();
    for (MemberEntity e in _closedWorld.locateMembers(selector, receiver)) {
      if (e is FieldEntity) {
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
        sideEffects.add(getSideEffectsOfElement(e as FunctionEntity));
      }
    }
    return sideEffects;
  }

  @override
  SideEffects getSideEffectsOfElement(FunctionEntity element) {
    // TODO(johnniwinther): Check that [_makeSideEffects] is only called if
    // type inference has been disabled (explicitly or because of compile time
    // errors).
    return _sideEffects.putIfAbsent(element, _makeSideEffects);
  }

  static SideEffects _makeSideEffects() => SideEffects();

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
  final Set<MemberEntity> _functionsCalledInLoop = {};
  Map<MemberEntity, SideEffectsBuilder>? _sideEffectsBuilders = {};
  final Set<FunctionEntity> prematureSideEffectAccesses = {};

  final Set<FunctionEntity> _elementsThatCannotThrow = {};

  final Set<FunctionEntity> _functionsThatMightBePassedToApply = {};

  AnnotationsData? _annotationsData;

  InferredDataBuilderImpl(AnnotationsData this._annotationsData);

  @override
  SideEffectsBuilder getSideEffectsBuilder(MemberEntity member) {
    return _sideEffectsBuilders![member] ??= _createSideEffectsBuilder(member);
  }

  SideEffectsBuilder _createSideEffectsBuilder(MemberEntity member) {
    if (_annotationsData!.hasNoSideEffects(member)) {
      return SideEffectsBuilder.free(member);
    }
    return SideEffectsBuilder(member);
  }

  /// Compute [SideEffects] for all registered [SideEffectBuilder]s.
  @override
  InferredData close(JClosedWorld closedWorld) {
    assert(_sideEffectsBuilders != null,
        "Inferred data has already been computed.");
    Map<FunctionEntity, SideEffects> _sideEffects = {};
    Iterable<SideEffectsBuilder> sideEffectsBuilders =
        _sideEffectsBuilders!.values;
    emptyWorkList(sideEffectsBuilders);
    for (SideEffectsBuilder builder in sideEffectsBuilders) {
      final function = builder.member as FunctionEntity;
      _sideEffects[function] = builder.sideEffects;

      // TODO(sra): We should also infer whether the function cannot throw. This
      // might be conveniently computed with the closure of the side effects
      // over the call graph. For now we just use the annotations.
      if (_annotationsData!.hasNoThrows(function)) {
        _elementsThatCannotThrow.add(function);
      }
    }
    _sideEffectsBuilders = null;
    _annotationsData = null;

    return InferredDataImpl(closedWorld, _functionsCalledInLoop, _sideEffects,
        _elementsThatCannotThrow, _functionsThatMightBePassedToApply);
  }

  static void emptyWorkList(Iterable<SideEffectsBuilder> sideEffectsBuilders) {
    // TODO(johnniwinther): Optimize this algorithm.
    Queue<SideEffectsBuilder> queue = Queue();
    Set<SideEffectsBuilder> inQueue = {};

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
  void registerMightBePassedToApply(FunctionEntity element) {
    _functionsThatMightBePassedToApply.add(element);
  }

  @override
  bool getCurrentlyKnownMightBePassedToApply(FunctionEntity element) {
    return _functionsThatMightBePassedToApply.contains(element);
  }
}

class TrivialInferredData implements InferredData {
  final SideEffects _allSideEffects = SideEffects();

  @override
  void writeToDataSink(DataSinkWriter sink) {
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
      Selector selector, AbstractValue? receiver) {
    return _allSideEffects;
  }
}
