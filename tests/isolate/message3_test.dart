// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

library MessageTest;
import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'dart:typed_data';

void echoMain(msg) {
  SendPort replyTo = msg[0];
  SendPort pong = msg[1];
  ReceivePort port = new ReceivePort();
  replyTo.send(port.sendPort);
  port.listen((msg) {
    if (msg == "halt") {
      port.close();
    } else {
      pong.send(msg);
    }
  });
}

class A {
  var field = 499;

  A();
  A.named(this.field);
}

class B extends A {
  final field2;
  B() : field2 = 99;
  B.named(this.field2, x) : super.named(x);
}

class C extends B {
  var field = 33;

  get superField => super.field;
  get superField2 => super.field2;
}

class M {
  get field2 => 11;
}

class D extends C with M {
  var gee = 123;
}

class E {
  Function fun;
  E(this.fun);

  static fooFun() => 499;
  instanceFun() => 1234;
}
barFun() => 42;

class F {
  final field = "field";
  const F();
}

class G {
  final field;
  const G(this.field);
}

class Value {
  final val;
  Value(this.val);

  operator==(other) {
    if (other is! Value) return false;
    return other.val == val;
  }

  get hashCode => val;
}

void runTests(SendPort ping, Queue checks) {
  ping.send("abc");
  checks.add((x) => Expect.equals("abc", x));

  ping.send([1, 2]);
  checks.add((x) {
    Expect.isTrue(x is List);
    Expect.listEquals([1, 2], x);
    // Make sure the list is mutable.
    x[0] = 0;
    Expect.equals(0, x[0]);
    // List must be extendable.
    x.add(3);
    Expect.equals(3, x[2]);
  });

  List fixed = new List(2);
  fixed[0] = 0;
  fixed[1] = 1;
  ping.send(fixed);
  checks.add((x) {
    Expect.isTrue(x is List);
    Expect.listEquals([0, 1], x);
    // List must be mutable.
    x[0] = 3;
    Expect.equals(3, x[0]);
    // List must be fixed length.
    Expect.throws(() { x.add(5); });
  });

  List cyclic = [];
  cyclic.add(cyclic);
  ping.send(cyclic);
  checks.add((x) {
    Expect.isTrue(x is List);
    Expect.equals(1, x.length);
    Expect.identical(x, x[0]);
    // List must be mutable.
    x[0] = 55;
    Expect.equals(55, x[0]);
    // List must be extendable.
    x.add(42);
    Expect.equals(42, x[1]);
  });

  List cyclic2 = new List(1);
  cyclic2[0] = cyclic2;
  ping.send(cyclic2);
  checks.add((x) {
    Expect.isTrue(x is List);
    Expect.equals(1, x.length);
    Expect.identical(x, x[0]);
    // List must be mutable.
    x[0] = 55;
    Expect.equals(55, x[0]);
    // List must be fixed.
    Expect.throws(() => x.add(42));
  });

  List constList = const [1, 2];
  ping.send(constList);
  checks.add((x) {
    Expect.isTrue(x is List);
    Expect.listEquals([1, 2], x);
    // Make sure the list is immutable.
    Expect.throws(() => x[0] = 0);  /// constList: ok
    // List must not be extendable.
    Expect.throws(() => x.add(3));
    Expect.identical(x, constList);  /// constList_identical: ok
  });

  Uint8List uint8 = new Uint8List(2);
  uint8[0] = 0;
  uint8[1] = 1;
  ping.send(uint8);
  checks.add((x) {
    Expect.isTrue(x is Uint8List);
    Expect.equals(2, x.length);
    Expect.equals(0, x[0]);
    Expect.equals(1, x[1]);
  });

  Uint16List uint16 = new Uint16List(2);
  uint16[0] = 0;
  uint16[1] = 1;
  ByteBuffer byteBuffer = uint16.buffer;
  ping.send(byteBuffer);  /// byteBuffer: ok
  checks.add(             /// byteBuffer: ok
  (x) {
    Expect.isTrue(x is ByteBuffer);
    Uint16List uint16View = new Uint16List.view(x);
    Expect.equals(2, uint16View.length);
    Expect.equals(0, uint16View[0]);
    Expect.equals(1, uint16View[1]);
  }
  )                      /// byteBuffer: ok
  ;

  Int32x4List list32x4 = new Int32x4List(2);
  list32x4[0] = new Int32x4(1, 2, 3, 4);
  list32x4[1] = new Int32x4(5, 6, 7, 8);
  ping.send(list32x4);   /// int32x4: ok
  checks.add(            /// int32x4: ok
  (x) {
    Expect.isTrue(x is Int32x4List);
    Expect.equals(2, x.length);
    Int32x4 entry1 = x[0];
    Int32x4 entry2 = x[1];
    Expect.equals(1, entry1.x);
    Expect.equals(2, entry1.y);
    Expect.equals(3, entry1.z);
    Expect.equals(4, entry1.w);
    Expect.equals(5, entry2.x);
    Expect.equals(6, entry2.y);
    Expect.equals(7, entry2.z);
    Expect.equals(8, entry2.w);
  }
  )                     /// int32x4: ok
  ;

  ping.send({"foo": 499, "bar": 32});
  checks.add((x) {
    Expect.isTrue(x is LinkedHashMap);
    Expect.listEquals(["foo", "bar"], x.keys.toList());
    Expect.listEquals([499, 32], x.values.toList());
    // Must be mutable.
    x["foo"] = 22;
    Expect.equals(22, x["foo"]);
    // Must be extendable.
    x["gee"] = 499;
    Expect.equals(499, x["gee"]);
  });

  ping.send({0: 499, 1: 32});
  checks.add((x) {
    Expect.isTrue(x is LinkedHashMap);
    Expect.listEquals([0, 1], x.keys.toList());
    Expect.listEquals([499, 32], x.values.toList());
    // Must be mutable.
    x[0] = 22;
    Expect.equals(22, x[0]);
    // Must be extendable.
    x["gee"] = 499;
    Expect.equals(499, x["gee"]);
  });

  Map cyclicMap = {};
  cyclicMap["cycle"] = cyclicMap;
  ping.send(cyclicMap);
  checks.add((x) {
    Expect.isTrue(x is LinkedHashMap);
    Expect.identical(x, x["cycle"]);
    // Must be mutable.
    x["cycle"] = 22;
    Expect.equals(22, x["cycle"]);
    // Must be extendable.
    x["gee"] = 499;
    Expect.equals(499, x["gee"]);
  });

  Map constMap = const {'foo': 499};
  ping.send(constMap);
  checks.add((x) {
    Expect.isTrue(x is Map);
    print(x.length);
    Expect.equals(1, x.length);
    Expect.equals(499, x['foo']);
    Expect.identical(constMap, x);  /// constMap: ok
    Expect.throws(() => constMap['bar'] = 42);
  });

  ping.send(new A());
  checks.add((x) {
    Expect.isTrue(x is A);
    Expect.equals(499, x.field);
  });

  ping.send(new A.named(42));
  checks.add((x) {
    Expect.isTrue(x is A);
    Expect.equals(42, x.field);
  });

  ping.send(new B());
  checks.add((x) {
    Expect.isTrue(x is A);
    Expect.isTrue(x is B);
    Expect.equals(499, x.field);
    Expect.equals(99, x.field2);
    Expect.throws(() => x.field2 = 22);
  });

  ping.send(new B.named(1, 2));
  checks.add((x) {
    Expect.isTrue(x is A);
    Expect.isTrue(x is B);
    Expect.equals(2, x.field);
    Expect.equals(1, x.field2);
    Expect.throws(() => x.field2 = 22);
  });

  ping.send(new C());
  checks.add((x) {
    Expect.isTrue(x is A);
    Expect.isTrue(x is B);
    Expect.isTrue(x is C);
    Expect.equals(33, x.field);
    Expect.equals(99, x.field2);
    Expect.equals(499, x.superField);
    Expect.throws(() => x.field2 = 22);
  });

  ping.send(new D());
  checks.add((x) {
    Expect.isTrue(x is A);
    Expect.isTrue(x is B);
    Expect.isTrue(x is C);
    Expect.isTrue(x is D);
    Expect.isTrue(x is M);
    Expect.equals(33, x.field);
    Expect.equals(11, x.field2);
    Expect.equals(499, x.superField);
    Expect.equals(99, x.superField2);
    Expect.throws(() => x.field2 = 22);
  });

  D cyclicD = new D();
  cyclicD.field = cyclicD;
  ping.send(cyclicD);
  checks.add((x) {
    Expect.isTrue(x is A);
    Expect.isTrue(x is B);
    Expect.isTrue(x is C);
    Expect.isTrue(x is D);
    Expect.isTrue(x is M);
    Expect.identical(x, x.field);
    Expect.equals(11, x.field2);
    Expect.equals(499, x.superField);
    Expect.equals(99, x.superField2);
    Expect.throws(() => x.field2 = 22);
  });

  ping.send(new E(E.fooFun));  /// fun: ok
  checks.add((x) {             /// fun: continued
    Expect.equals(E.fooFun, x.fun);  /// fun: continued
    Expect.equals(499, x.fun());     /// fun: continued
  });                                /// fun: continued

  ping.send(new E(barFun));  /// fun: continued
  checks.add((x) {           /// fun: continued
    Expect.equals(barFun, x.fun);  /// fun: continued
    Expect.equals(42, x.fun());    /// fun: continued
  });                              /// fun: continued

  Expect.throws(() => ping.send(new E(new E(null).instanceFun)));

  F nonConstF = new F();
  ping.send(nonConstF);
  checks.add((x) {
    Expect.equals("field", x.field);
    Expect.isFalse(identical(nonConstF, x));
  });

  const F constF = const F();
  ping.send(constF);
  checks.add((x) {
    Expect.equals("field", x.field);
    Expect.identical(constF, x);  /// constInstance: ok
  });

  G g1 = new G(nonConstF);
  G g2 = new G(constF);
  G g3 = const G(constF);
  ping.send(g1);
  ping.send(g2);
  ping.send(g3);

  checks.add((x) {  // g1.
    Expect.isTrue(x is G);
    Expect.isFalse(identical(g1, x));
    F f = x.field;
    Expect.equals("field", f.field);
    Expect.isFalse(identical(nonConstF, f));
  });
  checks.add((x) {  // g1.
    Expect.isTrue(x is G);
    Expect.isFalse(identical(g1, x));
    F f = x.field;
    Expect.equals("field", f.field);
    Expect.identical(constF, f);  /// constInstance: continued
  });
  checks.add((x) {  // g3.
    Expect.isTrue(x is G);
    Expect.identical(g1, x);  /// constInstance: continued
    F f = x.field;
    Expect.equals("field", f.field);
    Expect.identical(constF, f);  /// constInstance: continued
  });

  // Make sure objects in a map are serialized and deserialized in the correct
  // order.
  Map m = new Map();
  Value val1 = new Value(1);
  Value val2 = new Value(2);
  m[val1] = val2;
  m[val2] = val1;
  // Possible bug we want to catch:
  // serializer runs through keys first, and then the values:
  //    - id1 = val1, id2 = val2, ref[id2], ref[id1]
  // deserializer runs through the keys and values in order:
  //    - val1;  // id1.
  //    - ref[id2];  // boom. Wasn't deserialized yet.
  ping.send(m);
  checks.add((x) {
    Expect.isTrue(x is Map);
    Expect.equals(2, x.length);
    Expect.equals(val2, x[val1]);
    Expect.equals(val1, x[val2]);
    Expect.identical(x.keys.elementAt(0), x.values.elementAt(1));
    Expect.identical(x.keys.elementAt(1), x.values.elementAt(0));
  });
}

void main() {
  asyncStart();
  Queue checks = new Queue();
  ReceivePort testPort = new ReceivePort();
  Completer completer = new Completer();

  testPort.listen((msg) {
    Function check = checks.removeFirst();
    check(msg);
    if (checks.isEmpty) {
      completer.complete();
      testPort.close();
    }
  });

  ReceivePort initialReplyPort = new ReceivePort();
  Isolate
    .spawn(echoMain, [initialReplyPort.sendPort, testPort.sendPort])
    .then((_) => initialReplyPort.first)
    .then((SendPort ping) {
      runTests(ping, checks);
      Expect.isTrue(checks.length > 0);
      completer.future
        .then((_) => ping.send("halt"))
        .then((_) => asyncEnd());
    });
}
