// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library inbound_references_test;

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

// Make sure these variables are not removed by the tree shaker.
@pragma("vm:entry-point")
var cleanBlock;
@pragma("vm:entry-point")
var copyingBlock;
@pragma("vm:entry-point")
var fullBlock;
@pragma("vm:entry-point")
var fullBlockWithChain;

Function genCleanBlock() {
  block(x) => x;
  return block;
}

Function genCopyingBlock() {
  final x = 'I could be copied into the block';
  block() => x;
  return block;
}

Function genFullBlock() {
  var x = 42; // I must captured in a context.
  block() => x;
  x++;
  return block;
}

Function genFullBlockWithChain() {
  var x = 420; // I must captured in a context.
  outerBlock() {
    var y = 4200;
    innerBlock() => x + y;
    y++;
    return innerBlock;
  }

  x++;
  return outerBlock();
}

void script() {
  cleanBlock = genCleanBlock();
  copyingBlock = genCopyingBlock();
  fullBlock = genFullBlock();
  fullBlockWithChain = genFullBlockWithChain();
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load() as Library;
    Field field = lib.variables.singleWhere((v) => v.name == 'cleanBlock');
    await field.load();
    Instance block = await field.staticValue!.load() as Instance;
    expect(block.isClosure, isTrue);
    expect(block.closureContext, isNull);
  },
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load() as Library;
    Field field = lib.variables.singleWhere((v) => v.name == 'copyingBlock');
    await field.load();
    Instance block = await field.staticValue!.load() as Instance;
    expect(block.isClosure, isTrue);
    expect(block.closureContext!.isContext, isTrue);
    expect(block.closureContext!.length, equals(1));
    Context ctxt = await block.closureContext!.load() as Context;
    expect(ctxt.variables!.single.value.asValue!.isString, isTrue);
    expect(ctxt.variables!.single.value.asValue!.valueAsString,
        equals('I could be copied into the block'));
    expect(ctxt.parentContext, isNull);
  },
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load() as Library;
    Field field = lib.variables.singleWhere((v) => v.name == 'fullBlock');
    await field.load();
    Instance block = await field.staticValue!.load() as Instance;
    expect(block.isClosure, isTrue);
    expect(block.closureContext!.isContext, isTrue);
    expect(block.closureContext!.length, equals(1));
    Context ctxt = await block.closureContext!.load() as Context;
    expect(ctxt.variables!.single.value.asValue!.isInt, isTrue);
    expect(ctxt.variables!.single.value.asValue!.valueAsString, equals('43'));
    expect(ctxt.parentContext, isNull);
  },
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load() as Library;
    Field field =
        lib.variables.singleWhere((v) => v.name == 'fullBlockWithChain');
    await field.load();
    Instance block = await field.staticValue!.load() as Instance;
    expect(block.isClosure, isTrue);
    expect(block.closureContext!.isContext, isTrue);
    expect(block.closureContext!.length, equals(1));
    Context ctxt = await block.closureContext!.load() as Context;
    expect(ctxt.variables!.single.value.asValue!.isInt, isTrue);
    expect(ctxt.variables!.single.value.asValue!.valueAsString, equals('4201'));
    expect(ctxt.parentContext!.isContext, isTrue);
    expect(ctxt.parentContext!.length, equals(1));
    Context outerCtxt = await ctxt.parentContext!.load() as Context;
    expect(outerCtxt.variables!.single.value.asValue!.isInt, isTrue);
    expect(outerCtxt.variables!.single.value.asValue!.valueAsString,
        equals('421'));
    expect(outerCtxt.parentContext, isNull);
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
