// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages without spawning
// isolates.

// ---------------------------------------------------------------------------
// Serialization test.
// ---------------------------------------------------------------------------
#library('SerializationTest');
#import("dart:coreimpl");

main() {
  testAllTypes(copy);
  testAllTypes(serialize);
}

copy(x) {
  return new Copier().traverse(x);
}

serialize(x) {
  Serializer serializer = new Serializer();
  Deserializer deserializer = new Deserializer();
  return deserializer.deserialize(serializer.traverse(x));
}

void testAllTypes(Function f) {
  copyAndVerify(0, f);
  copyAndVerify(499, f);
  copyAndVerify(true, f);
  copyAndVerify(false, f);
  copyAndVerify("", f);
  copyAndVerify("foo", f);
  copyAndVerify([], f);
  copyAndVerify([1, 2], f);
  copyAndVerify([[]], f);
  copyAndVerify([1, []], f);
  copyAndVerify({}, f);
  copyAndVerify({ 'a': 3 }, f);
  copyAndVerify({ 'a': 3, 'b': 5, 'c': 8 }, f);
  copyAndVerify({ 'a': [1, 2] }, f);
  copyAndVerify({ 'b': { 'c' : 99 } }, f);
  copyAndVerify([ { 'a': 499 }, { 'b': 42 } ], f);

  var port = new ReceivePort();
  var transformed = f(port);
  Expect.equals(port.toSendPort(), transformed);
  port.close();

  port = new ReceivePort.singleShot();
  transformed = f(port);
  Expect.equals(port.toSendPort(), transformed);
  port.close();

  var a = [ 1, 3, 5 ];
  var b = { 'b': 49 };
  var c = [ a, b, a, b, a ];
  var copied = f(c);
  verify(c, copied);
  Expect.isFalse(c === copied);
  Expect.isTrue(copied[0] === copied[2]);
  Expect.isTrue(copied[0] === copied[4]);
  Expect.isTrue(copied[1] === copied[3]);
}

void copyAndVerify(o, Function f) {
  var copy = f(o);
  verify(o, copy);
}

void verify(o, copy) {
  if ((o is bool) || (o is num) || (o is String)) {
    Expect.equals(o, copy);
  } else if (o is List) {
    Expect.isTrue(copy is List);
    Expect.equals(o.length, copy.length);
    for (int i = 0; i < o.length; i++) {
      verify(o[i], copy[i]);
    }
  } else if (o is Map) {
    Expect.isTrue(copy is Map);
    Expect.equals(o.length, copy.length);
    o.forEach((key, value) {
      Expect.isTrue(copy.containsKey(key));
      verify(value, copy[key]);
    });
  } else {
    Expect.fail("Unexpected object encountered");
  }
}
