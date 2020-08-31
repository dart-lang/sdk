// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/inferrer/powersets/powersets.dart';
import 'package:compiler/src/inferrer/powersets/powerset_bits.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/element_lookup.dart';
import '../helpers/memory_compiler.dart';

const String CODE = """
var a = true;
var b = true;
var c = true;
var d = true;
var e = func();
var sink;

bool func() {
  return false;
}

main() {
  b = func();
  c = b && a;
  d = a || b;
  e = false;
  sink = e;
  print(sink);
}
""";

main() {
  retainDataForTesting = true;

  runTests() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': CODE},
        options: ['--experimental-powersets']);
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    var results = compiler.globalInference.resultsForTesting;
    JClosedWorld closedWorld = results.closedWorld;
    PowersetDomain powersetDomain = closedWorld.abstractValueDomain;
    PowersetBitsDomain powersetBitsDomain = powersetDomain.powersetBitsDomain;

    checkBits(String name, bits) {
      var element = findMember(closedWorld, name);
      PowersetValue mask = results.resultOfMember(element).type;
      Expect.equals(bits, mask.powersetBits);
    }

    checkBits('a', powersetBitsDomain.trueValue);
    checkBits('b', powersetBitsDomain.boolValue);
    checkBits('c', powersetBitsDomain.boolValue);
    checkBits('d', powersetBitsDomain.boolValue);
    checkBits(
        'e', powersetBitsDomain.falseValue | powersetBitsDomain.nullValue);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
