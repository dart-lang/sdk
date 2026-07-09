// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';

import "package:expect/expect.dart";

double getDoubleWithHeapObjectTag() {
  final bd = ByteData(8);
  bd.setUint64(0, 0x8000000000000001, Endian.host);
  final double v = bd.getFloat64(0, Endian.host);
  return v;
}

class Foo {
  final String clazz = "foo";
  final double x = getDoubleWithHeapObjectTag();
}

// Here we ensure to have a GC pointer and a non-GC pointer field, and then a
// type argument vector, so the offset in number of words for the type arguments
// will be different between host and target when compiling from 64-bit to
// 32-bit architectures.
class Bar<T> extends Foo {
  final String clazz = "bar";
  final double y = getDoubleWithHeapObjectTag();
  final T value;
  Bar(T val) : value = val;
}

main() async {
  final receivePort = new ReceivePort();
  receivePort.sendPort.send(Foo());
  receivePort.sendPort.send(Bar<String>("StringBar"));
  receivePort.sendPort.send(Bar<double>(4.2));
  final it = StreamIterator(receivePort);

  Expect.isTrue(await it.moveNext());
  final foo = it.current as Foo;

  Expect.isTrue(await it.moveNext());
  final string_bar = it.current as Bar<String>;

  Expect.isTrue(await it.moveNext());
  final double_bar = it.current as Bar<double>;

  Expect.equals(string_bar.value, "StringBar");
  Expect.equals(string_bar.clazz, "bar");
  Expect.equals(string_bar.y, getDoubleWithHeapObjectTag());
  Expect.equals(string_bar.x, getDoubleWithHeapObjectTag());
  Expect.equals(double_bar.value, 4.2);
  Expect.equals(foo.clazz, "foo");
  Expect.equals(foo.x, getDoubleWithHeapObjectTag());

  await it.cancel();
}
