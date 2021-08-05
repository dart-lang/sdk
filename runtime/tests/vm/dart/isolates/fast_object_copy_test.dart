// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--enable-isolate-groups --no-enable-fast-object-copy
// VMOptions=--enable-isolate-groups --enable-fast-object-copy
// VMOptions=--enable-isolate-groups --no-enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation --verify-store-buffer
// VMOptions=--enable-isolate-groups --enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation --verify-store-buffer

// The tests in this file are particularly for an implementation that tries to
// allocate the entire graph in BFS order using a fast new space allocation
// running in non-GC safe mode and a fallback to a slower GC-safe mode that uses
// handles.
//
// The tests will sometimes trigger the fallback from fast to slow case by
// inserting an object that cannot be allocated in new space.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:nativewrappers';
import 'dart:typed_data';

import 'package:expect/expect.dart';

class ClassWithNativeFields extends NativeFieldWrapperClass1 {}

final Uint8List largeExternalTypedData =
    File(Platform.resolvedExecutable).readAsBytesSync()..[0] = 42;
final Uint8List largeInternalTypedData = Uint8List(20 * 1024 * 1024)..[0] = 42;

final Uint8List smallExternalTypedData =
    File(Platform.script.toFilePath()).readAsBytesSync()..[0] = 21;
final Uint8List smallExternalTypedDataView =
    Uint8List.view(smallExternalTypedData.buffer, 1, 1);

final Uint8List smallInternalTypedData = Uint8List.fromList([0, 1, 2]);
final Uint8List smallInternalTypedDataView =
    Uint8List.view(smallInternalTypedData.buffer, 1, 1);

final Uint8List notAllocatableInTLAB = largeInternalTypedData;
final Object invalidObject = ClassWithNativeFields();

final smallPrimitives = [
  1,
  0xffffffffffffffff,
  'foobar',
  UserObject(1, 1.2, ''),
  smallInternalTypedData,
  smallInternalTypedDataView,
];
final smallContainers = [
  [],
  {},
  [...smallPrimitives],
  {for (final p in smallPrimitives) p: p},
  UserObject(2, 2.3, smallPrimitives),
];

void expectGraphsMatch(dynamic a, dynamic b) {
  if (a is int) {
    Expect.equals(a, (b as int));
    return;
  }
  if (a is double) {
    Expect.equals(a, (b as double));
    return;
  }
  if (a is String) {
    Expect.equals(a, (b as String));
    return;
  }
  if (a is UserObject) {
    final cb = b as UserObject;
    Expect.equals(a.unboxedInt, cb.unboxedInt);
    Expect.equals(a.unboxedDouble, cb.unboxedDouble);
    expectGraphsMatch(a.slot, cb.slot);
    return;
  }
  if (a is Uint8List) {
    final cb = b as Uint8List;
    Expect.equals(a.length, cb.length);
    Expect.equals(a.offsetInBytes, cb.offsetInBytes);
    for (int i = 0; i < a.length; ++i) {
      Expect.equals(a[i], cb[i]);
    }
    if (a.offsetInBytes != 0) {
      expectGraphsMatch(a.buffer.asUint8List(), b.buffer.asUint8List());
    }
    return;
  }
  if (a is List) {
    final cb = b as List;
    Expect.equals(a.length, cb.length);
    for (int i = 0; i < a.length; ++i) {
      expectGraphsMatch(a[i], cb[i]);
    }
    return;
  }
  if (a is Map) {
    final cb = b as Map;
    Expect.equals(a.length, cb.length);
    final aKeys = a.keys.toList();
    final aValues = a.values.toList();
    final cbKeys = cb.keys.toList();
    final cbValues = cb.values.toList();
    for (int i = 0; i < a.length; ++i) {
      expectGraphsMatch(aKeys[i], cbKeys[i]);
    }
    for (int i = 0; i < a.length; ++i) {
      expectGraphsMatch(aValues[i], cbValues[i]);
    }
    return;
  }
  if (a is Set) {
    final cb = b as Set;
    Expect.equals(a.length, cb.length);
    final aKeys = a.toList();
    final cbKeys = cb.toList();
    for (int i = 0; i < a.length; ++i) {
      expectGraphsMatch(aKeys[i], cbKeys[i]);
    }
    return;
  }

  throw 'Unexpected object encountered when matching object graphs $a / $b';
}

void expectViewOf(Uint8List view, Uint8List backing) {
  final int offset = view.offsetInBytes;
  Expect.isTrue(offset > 0);
  final int old = backing[offset];
  view[0] = ~view[0];
  Expect.notEquals(old, backing[offset]);
  view[0] = ~view[0];
  Expect.equals(old, backing[offset]);
}

class HashIncrementer {
  static int counter = 1;

  const HashIncrementer();

  int get hashCode => counter++;
  bool operator ==(other) => identical(this, other);
}

class UserObject {
  final int unboxedInt;
  final double unboxedDouble;
  final dynamic slot;

  const UserObject(this.unboxedInt, this.unboxedDouble, this.slot);
}

abstract class SendReceiveTestBase {
  late final ReceivePort receivePort;
  late final SendPort sendPort;
  late final StreamIterator si;

  SendReceiveTestBase();

  Future run() async {
    receivePort = ReceivePort();
    sendPort = receivePort.sendPort;
    si = StreamIterator(receivePort);

    await runTests();

    si.cancel();
    receivePort.close();
    print('done');
  }

  Future runTests();

  Future<T> sendReceive<T>(T graph) async {
    sendPort.send(graph);
    Expect.isTrue(await si.moveNext());
    return si.current as T;
  }
}

class SendReceiveTest extends SendReceiveTestBase {
  Future runTests() async {
    await testTransferrable();
    await testTransferrable2();
    await testTransferrable3();
    await testTransferrable4();
    await testTransferrable5();

    await testExternalTypedData();
    await testExternalTypedData2();
    await testExternalTypedData3();
    await testExternalTypedData4();
    await testExternalTypedData5();
    await testExternalTypedData6();

    await testInternalTypedDataView();
    await testInternalTypedDataView2();
    await testInternalTypedDataView3();
    await testInternalTypedDataView4();

    await testExternalTypedDataView();
    await testExternalTypedDataView2();
    await testExternalTypedDataView3();
    await testExternalTypedDataView4();

    await testArray();

    await testMapRehash();
    await testMapRehash2();
    await testMapRehash3();

    await testSetRehash();
    await testSetRehash2();
    await testSetRehash3();

    await testFastOnly();
    await testSlowOnly();
  }

  Future testTransferrable() async {
    print('testTransferrable');
    final td = TransferableTypedData.fromList([Uint8List(10)..[0] = 42]);
    final graph = [
      td,
      invalidObject,
    ];
    Expect.throwsArgumentError(() => sendPort.send(graph));
    Expect.equals(42, td.materialize().asInt8List()[0]);
  }

  Future testTransferrable2() async {
    print('testTransferrable2');
    final td = TransferableTypedData.fromList([Uint8List(10)..[0] = 42]);
    final graph = [
      td,
      notAllocatableInTLAB,
      invalidObject,
    ];
    Expect.throwsArgumentError(() => sendPort.send(graph));
    Expect.equals(42, td.materialize().asInt8List()[0]);
  }

  Future testTransferrable3() async {
    print('testTransferrable3');
    final td = TransferableTypedData.fromList([Uint8List(10)..[0] = 42]);
    final graph = [
      td,
    ];
    final result = await sendReceive(graph);
    Expect.throwsArgumentError(() => td.materialize());
    final tdCopy = result[0];
    Expect.equals(42, tdCopy.materialize().asInt8List()[0]);
  }

  Future testTransferrable4() async {
    print('testTransferrable4');
    final td = TransferableTypedData.fromList([Uint8List(10)..[0] = 42]);
    final graph = [
      notAllocatableInTLAB,
      td,
    ];
    final result = await sendReceive(graph);
    Expect.throwsArgumentError(() => td.materialize());
    final tdCopy = result[1] as TransferableTypedData;
    Expect.equals(42, tdCopy.materialize().asInt8List()[0]);
  }

  Future testTransferrable5() async {
    print('testTransferrable5');
    final td = TransferableTypedData.fromList([Uint8List(10)..[0] = 42]);
    final tdCopy = await sendReceive(td);
    Expect.throwsArgumentError(() => td.materialize());
    Expect.equals(42, tdCopy.materialize().asInt8List()[0]);
  }

  Future testExternalTypedData() async {
    print('testExternalTypedData');
    final graph = [
      notAllocatableInTLAB,
      largeExternalTypedData,
    ];
    for (int i = 0; i < 10; ++i) {
      final result = await sendReceive(graph);
      final etd = result[1];
      Expect.equals(42, etd[0]);
    }
  }

  Future testExternalTypedData2() async {
    print('testExternalTypedData2');
    final graph = [
      largeExternalTypedData,
      notAllocatableInTLAB,
    ];
    for (int i = 0; i < 10; ++i) {
      final result = await sendReceive(graph);
      final etd = result[1];
      Expect.equals(42, etd[0]);
    }
  }

  Future testExternalTypedData3() async {
    print('testExternalTypedData3');
    final graph = [
      notAllocatableInTLAB,
      largeExternalTypedData,
      invalidObject,
    ];
    Expect.throwsArgumentError(() => sendPort.send(graph));
  }

  Future testExternalTypedData4() async {
    print('testExternalTypedData4');
    final graph = [
      largeExternalTypedData,
      invalidObject,
    ];
    Expect.throwsArgumentError(() => sendPort.send(graph));
  }

  Future testExternalTypedData5() async {
    print('testExternalTypedData5');
    for (int i = 0; i < 10; ++i) {
      final etd = await sendReceive(largeExternalTypedData);
      Expect.equals(42, etd[0]);
    }
  }

  Future testExternalTypedData6() async {
    print('testExternalTypedData6');
    final etd = await sendReceive([
      smallExternalTypedData,
      largeExternalTypedData,
    ]);
    Expect.equals(21, etd[0][0]);
    Expect.equals(42, etd[1][0]);
  }

  Future testInternalTypedDataView() async {
    print('testInternalTypedDataView');
    final graph = [
      smallInternalTypedDataView,
      smallInternalTypedData,
    ];
    final copiedGraph = await sendReceive(graph);
    Expect.notIdentical(graph[0], copiedGraph[0]);
    Expect.notIdentical(graph[1], copiedGraph[1]);
    expectViewOf(copiedGraph[0], copiedGraph[1]);
    expectGraphsMatch(graph, copiedGraph);
  }

  Future testInternalTypedDataView2() async {
    print('testInternalTypedDataView2');
    final graph = [
      smallInternalTypedData,
      smallInternalTypedDataView,
    ];
    final copiedGraph = await sendReceive(graph);
    Expect.notIdentical(graph[0], copiedGraph[0]);
    Expect.notIdentical(graph[1], copiedGraph[1]);
    expectViewOf(copiedGraph[1], copiedGraph[0]);
    expectGraphsMatch(graph, copiedGraph);
  }

  Future testInternalTypedDataView3() async {
    print('testInternalTypedDataView3');
    final graph = [
      smallInternalTypedDataView,
      notAllocatableInTLAB,
      smallInternalTypedData,
    ];
    final copiedGraph = await sendReceive(graph);
    Expect.notIdentical(graph[0], copiedGraph[0]);
    Expect.notIdentical(graph[2], copiedGraph[2]);
    expectViewOf(copiedGraph[0], copiedGraph[2]);
    expectGraphsMatch(graph, copiedGraph);
  }

  Future testInternalTypedDataView4() async {
    print('testInternalTypedDataView4');
    final graph = [
      smallInternalTypedData,
      notAllocatableInTLAB,
      smallInternalTypedDataView,
    ];
    final copiedGraph = await sendReceive(graph);
    Expect.notIdentical(graph[0], copiedGraph[0]);
    Expect.notIdentical(graph[1], copiedGraph[1]);
    expectViewOf(copiedGraph[2], copiedGraph[0]);
    expectGraphsMatch(graph, copiedGraph);
  }

  Future testExternalTypedDataView() async {
    print('testExternalTypedDataView');
    final graph = [
      smallExternalTypedDataView,
      smallExternalTypedData,
    ];
    final copiedGraph = await sendReceive(graph);
    Expect.notIdentical(graph[0], copiedGraph[0]);
    Expect.notIdentical(graph[1], copiedGraph[1]);
    expectViewOf(copiedGraph[0], copiedGraph[1]);
    expectGraphsMatch(graph, copiedGraph);
  }

  Future testExternalTypedDataView2() async {
    print('testExternalTypedDataView2');
    final graph = [
      smallExternalTypedData,
      smallExternalTypedDataView,
    ];
    final copiedGraph = await sendReceive(graph);
    Expect.notIdentical(graph[0], copiedGraph[0]);
    Expect.notIdentical(graph[1], copiedGraph[1]);
    expectViewOf(copiedGraph[1], copiedGraph[0]);
    expectGraphsMatch(graph, copiedGraph);
  }

  Future testExternalTypedDataView3() async {
    print('testExternalTypedDataView3');
    final graph = [
      smallExternalTypedDataView,
      notAllocatableInTLAB,
      smallExternalTypedData,
    ];
    final copiedGraph = await sendReceive(graph);
    Expect.notIdentical(graph[0], copiedGraph[0]);
    Expect.notIdentical(graph[1], copiedGraph[1]);
    expectViewOf(copiedGraph[0], copiedGraph[2]);
    expectGraphsMatch(graph, copiedGraph);
  }

  Future testExternalTypedDataView4() async {
    print('testExternalTypedDataView4');
    final graph = [
      smallExternalTypedData,
      notAllocatableInTLAB,
      smallExternalTypedDataView,
    ];
    final copiedGraph = await sendReceive(graph);
    Expect.notIdentical(graph[0], copiedGraph[0]);
    Expect.notIdentical(graph[1], copiedGraph[1]);
    expectViewOf(copiedGraph[2], copiedGraph[0]);
    expectGraphsMatch(graph, copiedGraph);
  }

  Future testArray() async {
    print('testArray');
    final oldSpace = List<dynamic>.filled(1024 * 1024, null);
    final newSpace = UserObject(1, 1.1, 'foobar');
    oldSpace[0] = newSpace;
    final oldSpaceCopy = await sendReceive(oldSpace);
    final newSpaceCopy = oldSpaceCopy[0] as UserObject;
    Expect.equals(newSpaceCopy.unboxedInt, 1);
    Expect.equals(newSpaceCopy.unboxedDouble, 1.1);
    Expect.equals(newSpaceCopy.slot, 'foobar');
  }

  Future testMapRehash() async {
    print('testMapRehash');
    final obj = Object();
    final graph = [
      {obj: 42},
      notAllocatableInTLAB,
    ];
    final result = await sendReceive(graph);
    final mapCopy = result[0] as Map;
    Expect.equals(42, mapCopy.values.single);
    Expect.notIdentical(obj, mapCopy.keys.single);
    Expect.notEquals(
        identityHashCode(obj), identityHashCode(mapCopy.keys.single));
    Expect.equals(null, mapCopy[obj]);
    Expect.equals(42, mapCopy[mapCopy.keys.single]);
  }

  Future testMapRehash2() async {
    print('testMapRehash2');
    final obj = Object();
    final graph = [
      notAllocatableInTLAB,
      {obj: 42},
    ];
    final result = await sendReceive(graph);
    final mapCopy = result[1] as Map;
    Expect.equals(42, mapCopy.values.single);
    Expect.notIdentical(obj, mapCopy.keys.single);
    Expect.notEquals(
        identityHashCode(obj), identityHashCode(mapCopy.keys.single));
    Expect.equals(null, mapCopy[obj]);
    Expect.equals(42, mapCopy[mapCopy.keys.single]);
  }

  Future testMapRehash3() async {
    print('testMapRehash3');
    final obj = const HashIncrementer();
    final graph = [
      {obj: 42},
      notAllocatableInTLAB,
    ];
    final int before = HashIncrementer.counter;
    await sendReceive(graph);
    final int after = HashIncrementer.counter;
    Expect.equals(before + 1, after);
  }

  Future testSetRehash() async {
    print('testSetRehash');
    final obj = Object();
    final graph = <dynamic>[
      <dynamic>{42, obj},
      notAllocatableInTLAB,
    ];
    final result = await sendReceive(graph);
    final setCopy = result[0] as Set<dynamic>;
    Expect.equals(2, setCopy.length);
    Expect.equals(42, setCopy.toList()[0]);
    Expect.equals(obj.runtimeType, setCopy.toList()[1].runtimeType);
    Expect.notIdentical(obj, setCopy.toList()[1]);
    Expect.notEquals(
        identityHashCode(obj), identityHashCode(setCopy.toList()[1]));
    Expect.isFalse(setCopy.contains(obj));
    Expect.isTrue(setCopy.contains(setCopy.toList()[1]));
  }

  Future testSetRehash2() async {
    print('testSetRehash2');
    final obj = Object();
    final graph = <dynamic>[
      notAllocatableInTLAB,
      <dynamic>{42, obj},
    ];
    final result = await sendReceive(graph);
    final setCopy = result[1] as Set<dynamic>;
    Expect.equals(2, setCopy.length);
    Expect.equals(42, setCopy.toList()[0]);
    Expect.equals(obj.runtimeType, setCopy.toList()[1].runtimeType);
    Expect.notIdentical(obj, setCopy.toList()[1]);
    Expect.notEquals(
        identityHashCode(obj), identityHashCode(setCopy.toList()[1]));
    Expect.isFalse(setCopy.contains(obj));
    Expect.isTrue(setCopy.contains(setCopy.toList()[1]));
  }

  Future testSetRehash3() async {
    print('testSetRehash3');
    final obj = const HashIncrementer();
    final graph = [
      {42, obj},
      notAllocatableInTLAB,
    ];
    final int before = HashIncrementer.counter;
    await sendReceive(graph);
    final int after = HashIncrementer.counter;
    Expect.equals(before + 1, after);
  }

  Future testFastOnly() async {
    print('testFastOnly');
    for (final smallPrimitive in smallPrimitives) {
      expectGraphsMatch(smallPrimitive, await sendReceive(smallPrimitive));
    }
    for (final smallContainer in smallContainers) {
      expectGraphsMatch(smallContainer, await sendReceive(smallContainer));
    }
  }

  Future testSlowOnly() async {
    print('testSlowOnly');
    for (final smallPrimitive in smallPrimitives) {
      expectGraphsMatch([notAllocatableInTLAB, smallPrimitive],
          await sendReceive([notAllocatableInTLAB, smallPrimitive]));
    }
    for (final smallContainer in smallContainers) {
      expectGraphsMatch([notAllocatableInTLAB, smallContainer],
          await sendReceive([notAllocatableInTLAB, smallContainer]));
    }
  }
}

main() async {
  await SendReceiveTest().run();
}
