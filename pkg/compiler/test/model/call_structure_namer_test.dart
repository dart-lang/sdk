// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/js_backend/namer.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:expect/expect.dart';

main() {
  asyncTest(() async {
    test(List<String> expectedSuffixes,
        {int positionalParameters: 0,
        int typeParameters: 0,
        List<String> namedParameters: const <String>[]}) {
      CallStructure callStructure = new CallStructure(
          positionalParameters + namedParameters.length,
          namedParameters,
          typeParameters);
      List<String> actualSuffixes = Namer.callSuffixForStructure(callStructure);
      Expect.listEquals(
          expectedSuffixes,
          actualSuffixes,
          "Unexpected suffixes for $callStructure. "
          "Expected: $expectedSuffixes, actual: $actualSuffixes.");
    }

    test(['0']);
    test(['1'], positionalParameters: 1);
    test(['2'], positionalParameters: 2);
    test(['1', 'a'], namedParameters: ['a']);
    test(['2', 'a', 'b'], namedParameters: ['a', 'b']);
    test(['2', 'b', 'c'], namedParameters: ['c', 'b']);
    test(['2', 'a'], positionalParameters: 1, namedParameters: ['a']);

    test(['1', '0'], typeParameters: 1);
    test(['1', '1'], positionalParameters: 1, typeParameters: 1);
    test(['1', '2'], positionalParameters: 2, typeParameters: 1);
    test(['1', '1', 'a'], namedParameters: ['a'], typeParameters: 1);
    test(['1', '2', 'a', 'b'], namedParameters: ['a', 'b'], typeParameters: 1);
    test(['1', '2', 'b', 'c'], namedParameters: ['c', 'b'], typeParameters: 1);
    test(['1', '2', 'a'],
        positionalParameters: 1, namedParameters: ['a'], typeParameters: 1);

    test(['2', '0'], typeParameters: 2);
    test(['2', '1'], positionalParameters: 1, typeParameters: 2);
    test(['2', '2'], positionalParameters: 2, typeParameters: 2);
    test(['2', '1', 'a'], namedParameters: ['a'], typeParameters: 2);
    test(['2', '2', 'a', 'b'], namedParameters: ['a', 'b'], typeParameters: 2);
    test(['2', '2', 'b', 'c'], namedParameters: ['c', 'b'], typeParameters: 2);
    test(['2', '2', 'a'],
        positionalParameters: 1, namedParameters: ['a'], typeParameters: 2);
  });
}
