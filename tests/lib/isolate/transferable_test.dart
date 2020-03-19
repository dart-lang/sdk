// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import "dart:async";
import "dart:collection";
import "dart:isolate";
import "dart:typed_data";
import "package:expect/expect.dart";

const large = 2 * 1024 * 1024;

void child(replyPort) {
  print("Child start");

  print("Child ByteData");
  dynamic x = new ByteData(large);
  for (int i = 0; i < 4; i++) {
    x.setInt8(i, i);
  }
  replyPort.send(TransferableTypedData.fromList([x.buffer.asUint8List()]));

  print("Child Uint8List");
  x = new Uint8List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child Uint8List.view");
  x = new Uint8List.view(x.buffer, 1, 2);
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child Int8List");
  x = new Int8List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child Uint16List");
  x = new Uint16List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child Int16List");
  x = new Int16List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child Uint32List");
  x = new Uint32List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child Int32List");
  x = new Int32List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child Uint64List");
  x = new Uint64List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child Int64List");
  x = new Int64List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(TransferableTypedData.fromList([x]));

  print("Child two Uint8Lists");
  x = new Uint8List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send([
    TransferableTypedData.fromList([x]),
    TransferableTypedData.fromList([x])
  ]);

  print("Child same Uint8List twice - materialize first");
  x = new Uint8List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  var tr = TransferableTypedData.fromList([x]);
  replyPort.send([tr, tr]);

  print("Child same Uint8List twice - materialize second");
  x = new Uint8List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  tr = TransferableTypedData.fromList([x]);
  replyPort.send([tr, tr]);

  print("Child done");
}

Future<void> main(List<String> args) async {
  print("Parent start");

  ReceivePort port = new ReceivePort();
  Isolate.spawn(child, port.sendPort);
  StreamIterator<dynamic> incoming = new StreamIterator<dynamic>(port);

  print("Parent ByteData");
  Expect.isTrue(await incoming.moveNext());
  dynamic x = incoming.current.materialize().asByteData();
  Expect.isTrue(x is ByteData);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x.getUint8(i));
  }

  print("Parent Uint8List");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize();
  Expect.isTrue(x is ByteBuffer);
  x = x.asUint8List();
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Uint8List view");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize().asUint8List();
  Expect.equals(1, x[0]);
  Expect.equals(2, x[1]);

  print("Parent Int8");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize().asInt8List();
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Uint16");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize().asUint16List();
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Int16");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize().asInt16List();
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Uint32");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize().asUint32List();
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Int32");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize().asInt32List();
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Uint64");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize().asUint64List();
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Int64");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current.materialize().asInt64List();
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent two Uint8Lists");
  Expect.isTrue(await incoming.moveNext());
  final x1 = incoming.current[0].materialize().asUint8List();
  final x2 = incoming.current[1].materialize().asUint8List();
  Expect.equals(large, x1.length);
  Expect.equals(large, x2.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x1[i]);
    Expect.equals(i, x2[i]);
  }

  print("Parent same Uint8Lists twice, materialize first");
  Expect.isTrue(await incoming.moveNext());
  final tr0 = incoming.current[0].materialize().asUint8List();
  Expect.throwsArgumentError(() => incoming.current[1].materialize());
  Expect.equals(large, tr0.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, tr0[i]);
  }

  print("Parent same Uint8Lists twice, materialize second");
  Expect.isTrue(await incoming.moveNext());
  final tr1 = incoming.current[1].materialize().asUint8List();
  Expect.throwsArgumentError(() => incoming.current[0].materialize());
  Expect.equals(large, tr1.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, tr1[i]);
  }

  port.close();
  print("Parent done");

  testCreateMaterializeInSameIsolate();
  testIterableToList();
  testUserExtendedList();
}

testCreateMaterializeInSameIsolate() {
  // Test same-isolate operation of TransferableTypedData.
  final Uint8List bytes = new Uint8List(large);
  for (int i = 0; i < bytes.length; ++i) {
    bytes[i] = i % 256;
  }
  final tr = TransferableTypedData.fromList([bytes]);
  Expect.listEquals(bytes, tr.materialize().asUint8List());
}

testIterableToList() {
  // Test that iterable.toList() can be used as an argument.
  final list1 = Uint8List(10);
  for (int i = 0; i < list1.length; i++) {
    list1[i] = i;
  }
  final list2 = Uint8List(20);
  for (int i = 0; i < list2.length; i++) {
    list2[i] = i + list1.length;
  }
  final map = {list1: true, list2: true};
  Iterable<Uint8List> iterable = map.keys;
  final result = TransferableTypedData.fromList(iterable.toList())
      .materialize()
      .asUint8List();
  for (int i = 0; i < result.length; i++) {
    Expect.equals(i, result[i]);
  }
}

class MyList<E> extends ListBase<E> {
  List<E> _source;
  MyList(this._source);
  int get length => _source.length;
  void set length(int length) {
    _source.length = length;
  }

  E operator [](int index) => _source[index];
  void operator []=(int index, E value) {
    _source[index] = value;
  }
}

testUserExtendedList() {
  final list = MyList<TypedData>([Uint8List(10)]);
  TransferableTypedData.fromList(list);
}
