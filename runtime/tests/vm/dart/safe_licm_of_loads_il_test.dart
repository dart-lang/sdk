// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that loop-invariant loads which are safe to hoist (because the
// compile type of the receiver guarantees that the loaded field exists) are
// actually hoisted out of loops by LICM.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

//
// Dart fields.
//

abstract interface class Single {
  int get x;
}

final class SingleImpl implements Single {
  @override
  final int x;
  SingleImpl(this.x);
}

// Single has a single concrete implementation.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int singleImplementation(Single obj, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += obj.x;
  }
  return sum;
}

abstract interface class Common {
  int get x;
  double get d;
}

abstract class CommonBase implements Common {
  @override
  final int x;
  @override
  final double d;
  CommonBase(this.x, this.d);
}

class CommonA extends CommonBase {
  CommonA(super.x, super.d);
}

class CommonB extends CommonBase {
  CommonB(super.x, super.d);
}

// Common has multiple concrete implementations which inherit fields from
// the common base class.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
double commonBase(Common obj, int n) {
  var sum = 0.0;
  for (var i = 0; i < n; i++) {
    sum += obj.x + obj.d;
  }
  return sum;
}

abstract interface class Deep {
  int get x;
}

abstract class DeepBase {
  final int x;
  DeepBase(this.x);
}

abstract class DeepMidA extends DeepBase {
  DeepMidA(super.x);
}

abstract class DeepMidB extends DeepBase {
  DeepMidB(super.x);
}

class DeepA extends DeepMidA implements Deep {
  DeepA(super.x);
}

class DeepB extends DeepMidB implements Deep {
  DeepB(super.x);
}

// Concrete implementations of Deep have different superclass chains which
// only share DeepBase (which itself does not implement Deep).
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int deepCommonBase(Deep obj, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += obj.x;
  }
  return sum;
}

sealed class Sealed {
  final int x;
  Sealed(this.x);
}

final class SealedA extends Sealed {
  SealedA(super.x);
}

final class SealedB extends Sealed {
  SealedB(super.x);
}

// The field is declared in the static type of the receiver.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int sealedBase(Sealed obj, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += obj.x;
  }
  return sum;
}

abstract class MutableBase {
  int y;
  MutableBase(this.y);
}

class MutableA extends MutableBase {
  MutableA(super.y);
}

class MutableB extends MutableBase {
  MutableB(super.y);
}

// Mutable field which is not modified inside the loop.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int mutableField(MutableBase obj, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += obj.y;
  }
  return sum;
}

abstract interface class BoxIface<T> {
  bool accepts(Object? o);
}

class Box<T> implements BoxIface<T> {
  @override
  @pragma('vm:prefer-inline')
  bool accepts(Object? o) => o is T;
}

class SubBox<T> extends Box<T> {}

// Type arguments of all implementations of BoxIface are stored in the same
// field.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int typeArguments(BoxIface box, List<Object?> objects, int n) {
  var count = 0;
  for (var i = 0; i < n; i++) {
    if (box.accepts(objects[i])) count++;
  }
  return count;
}

//
// Native fields.
//

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int fixedLengthList(List<int> list, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += list[i];
  }
  return sum;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int growableList(List<int> list, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += list[i];
  }
  return sum;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int string(String str, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += str.codeUnitAt(i);
  }
  return sum;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int typedData(Uint8List list, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += list[i];
  }
  return sum;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int typedDataView(Uint8List list, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += list[i];
  }
  return sum;
}

// Only _ByteDataView instances reach this function.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int byteDataExact(ByteData bd, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += bd.getUint8(i);
  }
  return sum;
}

// Both _ByteDataView and _UnmodifiableByteDataView instances reach this
// function.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int byteDataPolymorphic(ByteData bd, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += bd.getUint8(i);
  }
  return sum;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int mapLength(Map<int, int> map, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += map.length;
  }
  return sum;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int record((int, int) r, int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += r.$1 + r.$2;
  }
  return sum;
}

void main() {
  Expect.equals(30, singleImplementation(SingleImpl(3), 10));
  Expect.equals(20, singleImplementation(SingleImpl(4), 5));

  Expect.equals(5.0, commonBase(CommonA(1, 1.5), 2));
  Expect.equals(10.0, commonBase(CommonB(2, 0.5), 4));

  Expect.equals(4, deepCommonBase(DeepA(1), 4));
  Expect.equals(8, deepCommonBase(DeepB(2), 4));

  Expect.equals(4, sealedBase(SealedA(1), 4));
  Expect.equals(8, sealedBase(SealedB(2), 4));

  Expect.equals(4, mutableField(MutableA(1), 4));
  Expect.equals(8, mutableField(MutableB(2), 4));

  final objects = <Object?>[1, 'a', 2, null];
  Expect.equals(2, typeArguments(Box<int>(), objects, objects.length));
  Expect.equals(1, typeArguments(SubBox<String>(), objects, objects.length));

  final fixed = List<int>.filled(4, 1);
  Expect.equals(4, fixedLengthList(fixed, fixed.length));
  final fixed2 = List<int>.filled(2, 2);
  Expect.equals(4, fixedLengthList(fixed2, fixed2.length));

  final growable = <int>[1, 2, 3, 4];
  Expect.equals(10, growableList(growable, growable.length));

  Expect.equals(0x61 * 4, string('aaaa', 4));
  Expect.equals(0x430 * 4, string('\u0430' * 4, 4));

  final u8 = Uint8List(4)..fillRange(0, 4, 1);
  Expect.equals(4, typedData(u8, u8.length));
  final u8view = Uint8List.sublistView(u8, 1);
  Expect.equals(3, typedDataView(u8view, u8view.length));

  final bd = ByteData(16);
  for (var i = 0; i < bd.lengthInBytes; i++) {
    bd.setUint8(i, i);
  }
  Expect.equals(120, byteDataExact(bd, bd.lengthInBytes));
  Expect.equals(120, byteDataPolymorphic(bd, bd.lengthInBytes));
  Expect.equals(
    120,
    byteDataPolymorphic(bd.asUnmodifiableView(), bd.lengthInBytes),
  );

  Expect.equals(8, mapLength({1: 1, 2: 2}, 4));

  Expect.equals(12, record((1, 2), 4));
  Expect.equals(14, record((3, 4), 2));
}

// Checks that every load from one of the given [slots] is located in the
// function entry block (which serves as the loop pre-header in all functions
// tested above) and that there is at least one such load for every slot.
void expectHoisted(FlowGraph graph, Set<String> slots) {
  final functionEntry = graph.blocks().firstWhere(
    (b) => b['o'] == 'FunctionEntry',
  );

  slots = slots.map(graph.rename).toSet();

  final hoisted = <String>{};
  final notHoisted = <String>[];
  for (final block in graph.blocks()) {
    for (final instr in [...?block['d'], ...?block['is']]) {
      if (instr['o'] != 'LoadField') continue;
      final slot = graph.attributesFor(instr)!['slot'] as String;
      if (!slots.contains(slot)) continue;
      if (identical(block, functionEntry)) {
        hoisted.add(slot);
      } else {
        notHoisted.add('$slot in B${block['b']}');
      }
    }
  }

  if (notHoisted.isNotEmpty || !hoisted.containsAll(slots)) {
    graph.dump();
  }
  Expect.isTrue(notHoisted.isEmpty, 'loads not hoisted: $notHoisted');
  Expect.setEquals(slots, hoisted);
}

void matchIL$singleImplementation(FlowGraph graph) {
  expectHoisted(graph, {'x'});
}

void matchIL$commonBase(FlowGraph graph) {
  expectHoisted(graph, {'x', 'd'});
}

void matchIL$deepCommonBase(FlowGraph graph) {
  expectHoisted(graph, {'x'});
}

void matchIL$sealedBase(FlowGraph graph) {
  expectHoisted(graph, {'x'});
}

void matchIL$mutableField(FlowGraph graph) {
  expectHoisted(graph, {'y'});
}

void matchIL$typeArguments(FlowGraph graph) {
  expectHoisted(graph, {':type_arguments'});
}

void matchIL$fixedLengthList(FlowGraph graph) {
  expectHoisted(graph, {'Array.length'});
}

void matchIL$growableList(FlowGraph graph) {
  expectHoisted(graph, {
    'GrowableObjectArray.length',
    'GrowableObjectArray.data',
  });
}

void matchIL$string(FlowGraph graph) {
  expectHoisted(graph, {'String.length'});
}

void matchIL$typedData(FlowGraph graph) {
  expectHoisted(graph, {'TypedDataBase.length'});
}

void matchIL$typedDataView(FlowGraph graph) {
  expectHoisted(graph, {'TypedDataBase.length'});
}

const byteDataSlots = {
  'TypedDataBase.length',
  'TypedDataView.offset_in_bytes',
  'TypedDataView.typed_data',
};

void matchIL$byteDataExact(FlowGraph graph) {
  expectHoisted(graph, byteDataSlots);
}

void matchIL$byteDataPolymorphic(FlowGraph graph) {
  expectHoisted(graph, byteDataSlots);
}

void matchIL$mapLength(FlowGraph graph) {
  expectHoisted(graph, {
    'LinkedHashBase.used_data',
    'LinkedHashBase.deleted_keys',
  });
}

void matchIL$record(FlowGraph graph) {
  expectHoisted(graph, {':record_field'});
}
