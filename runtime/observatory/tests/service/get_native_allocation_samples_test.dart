// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/cpu_profile.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

void verifyHelper(var root, bool exclusive) {
  if (root.children.length == 0) {
    return;
  }

/*  if (!(root is FunctionCallTreeNode)) {
    print('${root.profileCode.code.name}');
  } else {
    print('${root.profileFunction.function.name}');
  }
*/
  int inclusiveAllocations = 0;
  int exclusiveAllocations = 0;

  for (int i = 0; i < root.children.length; i++) {
    inclusiveAllocations += root.children[i].inclusiveNativeAllocations;
    exclusiveAllocations += root.children[i].exclusiveNativeAllocations;
  }

  int rootMemory;
  if (exclusive) {
    rootMemory = root.inclusiveNativeAllocations + exclusiveAllocations;
  } else {
    rootMemory =
        root.inclusiveNativeAllocations - root.exclusiveNativeAllocations;
  }

  expect(inclusiveAllocations == rootMemory, isTrue);
  for (int i = 0; i < root.children.length; i++) {
    verifyHelper(root.children[i], exclusive);
  }
}

void verify(var tree, bool exclusive) {
  var node = tree.root;
  expect(node, isNotNull);
  expect(node.children.length >= 0, isTrue);

  for (int i = 0; i < node.children.length; i++) {
    verifyHelper(node.children[i], exclusive);
  }
}

var tests = [
  // Verify inclusive tries.
  (VM vm) async {
    var response =
        await vm.invokeRpc('_getNativeAllocationSamples', {'tags': 'None'});
    CpuProfile cpuProfile = new CpuProfile();
    await cpuProfile.load(vm, response);
    var codeTree = cpuProfile.loadCodeTree(M.ProfileTreeDirection.inclusive);
    var functionTree =
        cpuProfile.loadFunctionTree(M.ProfileTreeDirection.inclusive);
    verify(codeTree, false);
    verify(functionTree, false);
  },
  // Verify exclusive tries.
  (VM vm) async {
    var response =
        await vm.invokeRpc('_getNativeAllocationSamples', {'tags': 'None'});
    CpuProfile cpuProfile = new CpuProfile();
    await cpuProfile.load(vm, response);
    var codeTreeExclusive =
        cpuProfile.loadCodeTree(M.ProfileTreeDirection.exclusive);
    var functionTreeExclusive =
        cpuProfile.loadFunctionTree(M.ProfileTreeDirection.exclusive);
    verify(codeTreeExclusive, true);
    verify(functionTreeExclusive, true);
  }
];

main(args) async => runVMTests(args, tests);
