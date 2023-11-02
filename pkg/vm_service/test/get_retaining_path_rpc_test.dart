// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

class _TestClass {
  _TestClass();
  // Make sure these fields are not removed by the tree shaker.
  @pragma("vm:entry-point") // Prevent obfuscation
  dynamic x;
  @pragma("vm:entry-point") // Prevent obfuscation
  dynamic y;
}

_TestClass? target1 = _TestClass();
_TestClass? target2 = _TestClass();
_TestClass? target3 = _TestClass();
_TestClass? target4 = _TestClass();
_TestClass? target5 = _TestClass();
_TestClass? target6 = _TestClass();
_TestClass? target7 = _TestClass();
_TestClass? target8 = _TestClass();

@pragma("vm:entry-point") // Prevent obfuscation
Expando<_TestClass> expando = Expando<_TestClass>();
@pragma("vm:entry-point") // Prevent obfuscation
_TestClass globalObject = _TestClass();
@pragma("vm:entry-point") // Prevent obfuscation
dynamic globalList = List<dynamic>.filled(100, null);
@pragma("vm:entry-point") // Prevent obfuscation
dynamic globalMap1 = Map();
@pragma("vm:entry-point") // Prevent obfuscation
dynamic globalMap2 = Map();
@pragma("vm:entry-point") // Prevent obfuscation
_TestClass weakReachable = _TestClass();
@pragma("vm:entry-point") // Prevent obfuscation
_TestClass weakUnreachable = _TestClass();

void warmup() {
  globalObject.x = target1;
  globalObject.y = target2;
  globalList[12] = target3;
  globalMap1['key'] = target4;
  globalMap2[target5] = 'value';

  // The weak reference will be traced first in DFS, but the retaining path
  // include the strong reference.
  weakReachable.x = WeakReference<_TestClass>(target7!);
  weakReachable.y = target7;

  weakUnreachable.x = WeakReference<_TestClass>(target8!);
  weakUnreachable.y = null;
}

@pragma("vm:entry-point") // Prevent obfuscation
getGlobalObject() => globalObject;

@pragma("vm:entry-point") // Prevent obfuscation
_TestClass? takeTarget1() {
  var tmp = target1;
  target1 = null;
  return tmp;
}

@pragma("vm:entry-point") // Prevent obfuscation
_TestClass? takeTarget2() {
  var tmp = target2;
  target2 = null;
  return tmp;
}

@pragma("vm:entry-point") // Prevent obfuscation
_TestClass? takeTarget3() {
  var tmp = target3;
  target3 = null;
  return tmp;
}

@pragma("vm:entry-point") // Prevent obfuscation
_TestClass? takeTarget4() {
  var tmp = target4;
  target4 = null;
  return tmp;
}

@pragma("vm:entry-point") // Prevent obfuscation
_TestClass? takeTarget5() {
  var tmp = target5;
  target5 = null;
  return tmp;
}

@pragma("vm:entry-point") // Prevent obfuscation
_TestClass? takeExpandoTarget() {
  var tmp = target6;
  target6 = null;
  var tmp2 = _TestClass();
  expando[tmp!] = tmp2;
  return tmp2;
}

@pragma("vm:entry-point") // Prevent obfuscation
_TestClass? takeWeakReachableTarget() {
  var tmp = target7;
  target7 = null;
  return tmp;
}

@pragma("vm:entry-point") // Prevent obfuscation
_TestClass? takeWeakUnreachableTarget() {
  var tmp = target8;
  target8 = null;
  return tmp;
}

@pragma("vm:entry-point") // Prevent obfuscation
bool getTrue() => true;

Future<InstanceRef> invoke(String selector) async {
  return await rootService.invoke(
    isolateId,
    isolate.rootLib!.id!,
    selector,
    [],
  ) as InstanceRef;
}

late final VmService rootService;
late final Isolate isolate;
late final String isolateId;

final tests = <IsolateTest>[
  // Initialization
  (VmService service, IsolateRef isolateRef) async {
    isolateId = isolateRef.id!;
    rootService = service;
    isolate = await service.getIsolate(isolateId);
  },
  // simple path
  (VmService service, IsolateRef isolateRef) async {
    final obj = await invoke('getGlobalObject');
    final result = await service.getRetainingPath(isolateId, obj.id!, 100);
    expect(result.gcRootType, 'user global');
    expect(result.elements!.length, 2);
    expect((result.elements![1].value! as FieldRef).name, 'globalObject');
  },

  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('takeTarget1');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    expect(result.gcRootType, 'user global');
    final elements = result.elements!;
    expect(elements.length, 3);
    expect(elements[1].parentField, 'x');
    expect((elements[2].value as FieldRef).name, 'globalObject');
  },

  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('takeTarget2');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    expect(result.gcRootType, 'user global');
    final elements = result.elements!;
    expect(elements.length, 3);
    expect(elements[1].parentField, 'y');
    expect((elements[2].value as FieldRef).name, 'globalObject');
  },

  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('takeTarget3');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    expect(result.gcRootType, 'user global');
    final elements = result.elements!;
    expect(elements.length, 3);
    expect(elements[1].parentListIndex, 12);
    expect((elements[2].value as FieldRef).name, 'globalList');
  },

  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('takeTarget4');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    expect(result.gcRootType, 'user global');
    final elements = result.elements!;
    expect(elements.length, 3);
    expect((elements[1].parentMapKey as InstanceRef).valueAsString, 'key');
    expect((elements[2].value as FieldRef).name, 'globalMap1');
  },

  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('takeTarget5');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    expect(result.gcRootType, 'user global');
    final elements = result.elements!;
    expect(elements.length, 3);
    expect(
      (elements[1].parentMapKey as InstanceRef).classRef!.name,
      '_TestClass',
    );
    expect((elements[2].value as FieldRef).name, 'globalMap2');
  },

  (VmService service, IsolateRef isolateRef) async {
    // Regression test for https://github.com/dart-lang/sdk/issues/44016
    final target = await invoke('takeExpandoTarget');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    final elements = result.elements!;
    expect(elements.length, 5);
    expect(
      (elements[1].parentMapKey as InstanceRef).classRef!.name,
      '_TestClass',
    );
    expect(elements[2].parentListIndex, isNotNull);
    expect((elements[4].value as FieldRef).name, 'expando');
  },

  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('takeWeakReachableTarget');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    expect(result.gcRootType, 'user global');
    final elements = result.elements!;
    expect(elements.length, 3);
    expect(elements[1].parentField, 'y');
    expect((elements[2].value as FieldRef).name, 'weakReachable');
  },

  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('takeWeakUnreachableTarget');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    final elements = result.elements!;
    expect(elements.length, 0);
  },

  // object store
  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('getTrue');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    expect(
      result.gcRootType == 'isolate_object store' ||
          result.gcRootType == 'class table',
      true,
    );
    final elements = result.elements!;
    expect(elements.length, 0);
  },
];

void main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'get_retaining_path_rpc_test.dart',
      testeeBefore: warmup,
    );
