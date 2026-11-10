// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=Cyclic
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=-O0

void main() async {
  CyclicClass.initGlobalBox();
  constructorBodyClosureBox!.closure();
  constructorInitializeClosure!();

  CyclicClass.fooStatic();
  print(CyclicClass.fooStatic);

  final c = cyclic;

  print(c.fooSync);
  print(c.fooSyncStar());
  print(c.fooAsync);
  print(c.fooAsyncStar);

  c.fooSync();
  for (final value in c.fooSyncStar()) {
    print(value);
  }

  await c.fooAsync();
  await for (final value in c.fooAsyncStar()) {
    print(value);
  }
}

final CyclicClass cyclic = CyclicClass.chain(cyclic);

class CyclicClass {
  final CyclicClass other;

  CyclicClass.chain(this.other) {
    print('CyclicClass.chain()');
    print(other);
  }

  CyclicClass.initGlobalBox()
    : other = (() {
        constructorInitializeClosure = (() {
          print('CyclicClass.initGlobalBox(): initializer lambda');
        });
        return cyclic;
      })() {
    print('CyclicClass.initGlobalBox()');
    print(other);
    constructorBodyClosureBox = Box(() {
      print('lambdaInConstructorBody');
    });
  }

  void fooSync() {
    print('fooSync');
  }

  Iterable<int> fooSyncStar() sync* {
    print('fooSyncStar');
    yield 1;
  }

  Future fooAsync() async {
    print('fooAsync');
  }

  Stream<int> fooAsyncStar() async* {
    print('fooAsyncStar');
    yield 1;
  }

  static void fooStatic() {
    print('fooStatic');
  }
}

void Function()? constructorInitializeClosure;
Box? constructorBodyClosureBox;

class Box {
  final void Function() closure;
  Box(this.closure);
}
