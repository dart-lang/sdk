// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/inferrer/powersets/powersets.dart';
import 'package:compiler/src/inferrer/powersets/powerset_bits.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/element_lookup.dart';
import 'package:compiler/src/util/memory_compiler.dart';

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
    Compiler compiler = result.compiler!;
    var results = compiler.globalInference.resultsForTesting!;
    JClosedWorld closedWorld = results.closedWorld;
    final powersetDomain = closedWorld.abstractValueDomain as PowersetDomain;
    PowersetBitsDomain powersetBitsDomain = powersetDomain.powersetBitsDomain;

    checkBits(String name, bits) {
      var element = findMember(closedWorld, name);
      final mask = results.resultOfMember(element).type as PowersetValue;
      Expect.equals(bits, mask.powersetBits);
    }

    checkBits('a', powersetBitsDomain.trueValue);
    checkBits('b', powersetBitsDomain.boolValue);
    checkBits('c', powersetBitsDomain.boolValue);
    checkBits('d', powersetBitsDomain.boolValue);
    checkBits('e', powersetBitsDomain.falseValue);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
