// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/types/types.dart' show ContainerTypeMask, TypeMask;

import 'compiler_helper.dart';

String generateTest(String key, String value, bool initial) {
  return """
double aDouble = 42.5;
List aList = [42];

consume(x) => x;

main() {
""" +
      (initial
          ? """
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, $key: $value};
"""
          : """
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap[$key] = $value;
""") +
      """
  for (var key in theMap.keys) {
    aDouble = theMap[key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume(aList);
}
""";
}

void main() {
  // Test using keys without the list floating in
  doTest();
  // Test using keys with the list floating in as key
  doTest(key: "aList", bail: true);
  // Test using keys with the list floating in as value
  doTest(value: "aList");
  // And the above where we add the list as part of the map literal.
  doTest(initial: true);
  doTest(key: "aList", bail: true, initial: true);
  doTest(value: "aList", initial: true);
}

void doTest(
    {String key: "'d'",
    String value: "5.5",
    bool bail: false,
    bool initial: false}) {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(generateTest(key, value, initial), uri,
      expectedErrors: 0, expectedWarnings: 0);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var commonMasks = typesInferrer.closedWorld.commonMasks;
        MemberElement aDouble = findElement(compiler, 'aDouble');
        var aDoubleType = typesInferrer.getTypeOfMember(aDouble);
        MemberElement aList = findElement(compiler, 'aList');
        var aListType = typesInferrer.getTypeOfMember(aList);

        Expect.equals(aDoubleType, commonMasks.doubleType);
        Expect.isTrue(aListType is ContainerTypeMask);
        ContainerTypeMask container = aListType;
        TypeMask elementType = container.elementType;
        if (bail) {
          Expect.equals(elementType, commonMasks.dynamicType);
        } else {
          Expect.equals(elementType, commonMasks.uint31Type);
        }
      }));
}
