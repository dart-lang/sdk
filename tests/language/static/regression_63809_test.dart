// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 63809: dart2wasm compiler replaced constructor
// invocations, static methods, constructor bodies, and closures of cyclic types
// with unreachable, discarding throwing initializers and breaking static calls or
// constructor closures.

import "package:expect/expect.dart";

// Case 1: Throwing Constructor Initializer
abstract class Api {
  Future<String> act(String id);
}

abstract class Client {
  factory Client() => throw UnsupportedError('Client not supported');
  Future<String> get(String url);
}

class CycleClient implements Client {
  final Client _inner;
  CycleClient({Client? inner}) : _inner = inner ?? Client();

  @override
  @pragma('wasm:entry-point')
  Future<String> get(String url) => _inner.get(url);
}

class ConcreteApi implements Api {
  final Client _client;
  ConcreteApi(this._client);

  @override
  @pragma('wasm:entry-point')
  Future<String> act(String id) async {
    final response = await _client.get('https://example.com/$id');
    return response;
  }
}

// Case 2: Static method on cyclic class
class CyclicWithStatic {
  final CyclicWithStatic next;
  CyclicWithStatic(this.next);

  @pragma('wasm:entry-point')
  CyclicWithStatic getNext() => next;

  static String foo() => 'foo';
}

class CyclicWithClosures {
  final CyclicWithClosures next;
  final int value;

  CyclicWithClosures._dummy(this.next, this.value);
  CyclicWithClosures(int val)
    : value = val,
      next = (() {
        if (val >= 3) {
          throw StateError('Max cycle depth reached');
        }
        var closureInInit = () => val + 1;
        return CyclicWithClosures(closureInInit());
      })() {
    var closureInBody = () => value * 2;
    Expect.equals(val * 2, closureInBody());
  }
}

@pragma('wasm:never-inline')
int evalClosure(int Function() f) => f();

// Owl Finding 1: Closures in constructor initializer lists of cyclic classes
class CyclicWithInitClosure implements Client {
  final Client _inner;
  final int value;

  CyclicWithInitClosure(int v)
    : value = evalClosure(() {
        if (v < 0) throw ArgumentError('negative');
        return v * 2;
      }),
      _inner = Client();

  @override
  @pragma('wasm:entry-point')
  Future<String> get(String url) => _inner.get(url);
}

// Owl Finding 2: Uninitialized locals of ExtensionType / TypeParameter wrapping cyclic classes
class CyclicBaseClass {
  final CyclicBaseClass next;
  CyclicBaseClass(this.next);
}

extension type ExtCyclic(CyclicBaseClass c) {}

@pragma('wasm:never-inline')
void testExtCyclicLocal(bool cond, ExtCyclic? val) {
  ExtCyclic x;
  if (cond) {
    x = val!;
    Expect.isNotNull(x);
  }
}

@pragma('wasm:never-inline')
void testTypeParamCyclicLocal<T extends CyclicBaseClass>(bool cond, T? val) {
  T t;
  if (cond) {
    t = val!;
    Expect.isNotNull(t);
  }
}

// Owl Finding 3: Super initializer chaining on cyclic subclasses
class NonCyclicSuper {
  final String label;
  NonCyclicSuper(int x)
    : label = (() {
        if (x < 0) throw RangeError('negative super arg');
        return 'val: $x';
      })();
}

class CyclicSub extends NonCyclicSuper {
  final CyclicSub next;
  CyclicSub._dummy(this.next, int x) : super(x);
  CyclicSub(int x)
    : next = (() {
        if (x < 0) throw RangeError('negative cyclic sub arg');
        return CyclicSub(x + 1);
      })(),
      super(x);
}

int get dynamicNegativeOne => int.parse('-1');
int get dynamicOne => int.parse('1');

void testConstructorThrow() {
  Expect.throws(() {
    ConcreteApi(CycleClient());
  }, (e) => e is UnsupportedError);
}

void testStaticMethods() {
  Expect.equals('foo', CyclicWithStatic.foo());
}

void testConstructorClosures() {
  // We use dynamic inputs instead of constants to prevent TFA from completely replacing with unreachable
  Expect.throws(() {
    CyclicWithClosures(dynamicOne);
  }, (e) => e is StateError);
}

void testRealInitializerClosure() {
  Expect.throws(() {
    CyclicWithInitClosure(dynamicNegativeOne);
  }, (e) => e is ArgumentError);
}

void testCyclicSubSuperInit() {
  Expect.throws(() => CyclicSub(dynamicNegativeOne), (e) => e is RangeError);
}

void main() {
  testConstructorThrow();
  testStaticMethods();
  testConstructorClosures();
  testRealInitializerClosure();
  testExtCyclicLocal(false, null);
  testTypeParamCyclicLocal(false, null);
  testCyclicSubSuperInit();
}
