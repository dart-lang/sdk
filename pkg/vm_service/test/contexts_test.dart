// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

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

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final fieldRef =
        rootLib.variables!.singleWhere((v) => v.name == 'cleanBlock');
    final field = await service.getObject(isolateId, fieldRef.id!) as Field;
    final block =
        await service.getObject(isolateId, field.staticValue.id!) as Instance;

    expect(block.closureFunction, isNotNull);
    expect(block.closureContext, isNull);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final fieldRef =
        rootLib.variables!.singleWhere((v) => v.name == 'copyingBlock');
    final field = await service.getObject(isolateId, fieldRef.id!) as Field;
    final block =
        await service.getObject(isolateId, field.staticValue.id!) as Instance;
    expect(block.closureFunction, isNotNull);
    expect(block.closureContext, isNotNull);

    final closureContext = block.closureContext!;
    expect(closureContext.length, 1);

    final ctxt =
        await service.getObject(isolateId, closureContext.id!) as Context;
    final value = ctxt.variables!.single.value as InstanceRef;
    expect(value.kind, InstanceKind.kString);
    expect(value.valueAsString, 'I could be copied into the block');
    expect(ctxt.parent, isNull);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final fieldRef =
        rootLib.variables!.singleWhere((v) => v.name == 'fullBlock');
    final field = await service.getObject(isolateId, fieldRef.id!) as Field;
    final block =
        await service.getObject(isolateId, field.staticValue.id!) as Instance;

    expect(block.closureFunction, isNotNull);
    expect(block.closureContext, isNotNull);

    final closureContext = block.closureContext!;
    expect(block.closureContext!.length, 1);

    final ctxt =
        await service.getObject(isolateId, closureContext.id!) as Context;
    final value = ctxt.variables!.single.value as InstanceRef;
    expect(value.kind, InstanceKind.kInt);
    expect(value.valueAsString, '43');
    expect(ctxt.parent, isNull);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final fieldRef =
        rootLib.variables!.singleWhere((v) => v.name == 'fullBlockWithChain');
    final field = await service.getObject(isolateId, fieldRef.id!) as Field;
    final block =
        await service.getObject(isolateId, field.staticValue.id!) as Instance;

    expect(block.closureFunction, isNotNull);
    expect(block.closureContext, isNotNull);

    final closureContext = block.closureContext!;
    expect(block.closureContext!.length, 1);

    final ctxt =
        await service.getObject(isolateId, closureContext.id!) as Context;
    final value = ctxt.variables!.single.value as InstanceRef;
    expect(value.kind, InstanceKind.kInt);
    expect(value.valueAsString, '4201');

    final parent = ctxt.parent!;
    expect(parent.length, 1);

    final outerCtxt = await service.getObject(isolateId, parent.id!) as Context;

    final outerValue = outerCtxt.variables!.single.value as InstanceRef;
    expect(outerValue.kind, InstanceKind.kInt);
    expect(outerValue.valueAsString, '421');
    expect(outerCtxt.parent, isNull);
  },
];

void main(List<String> args) => runIsolateTests(
      args,
      tests,
      'contexts_test.dart',
      testeeBefore: script,
    );
