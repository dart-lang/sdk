// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

const String TEST = '''
int closure(int x) {
  return x;
}

class A {
  static const DEFAULT = const {'fun' : closure};

  final map;

  A([maparg]) : map = maparg == null ? DEFAULT : maparg;
}

main() {
  var a = new A();
  a.map['fun'](3.3);
  print(closure(22));
}
''';

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri, expectedErrors: 0, expectedWarnings: 0);
  compiler.stopAfterTypeInference = true;
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;
        var commonMasks = closedWorld.commonMasks;
        MemberElement element = findElement(compiler, 'closure');
        var mask = typesInferrer.getReturnTypeOfMember(element);
        Expect.equals(commonMasks.numType, simplify(mask, closedWorld));
      }));
}
