// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';
import 'package:compiler/src/types/types.dart';

bool isContainer(TypeMask mask) {
  return mask is ContainerTypeMask;
}

const String TEST = '''

foo1() {
  final methods = [];
  var res, sum;
  for (int i = 0; i != 3; i++) {
    methods.add((int x) { res = x; sum = x + i; });
  }
  methods[0](499);
  probe1res(res);
  probe1sum(sum);
  probe1methods(methods);
}
probe1res(x) => x;
probe1sum(x) => x;
probe1methods(x) => x;

nonContainer(choice) {
  var m = choice == 0 ? [] : "<String>";
  if (m is !List) throw 123;
  // The union then filter leaves us with a non-container type.
  return m;
}

foo2(int choice) {
  final methods = nonContainer(choice);
  var res, sum;
  for (int i = 0; i != 3; i++) {
    methods.add((int x) { res = x; sum = x + i; });
  }
  methods[0](499);
  probe2res(res);
  probe2methods(methods);
}
probe2res(x) => x;
probe2methods(x) => x;

main() {
  foo1();
  foo2(0);
  foo2(1);
}
''';

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;
        var commonMasks = closedWorld.commonMasks;

        typeOf(String name) {
          return typesInferrer
              .getReturnTypeOfMember(findElement(compiler, name));
        }

        checkType(String name, type) {
          var mask = typeOf(name);
          Expect.equals(type.nullable(), simplify(mask, closedWorld), name);
        }

        checkContainer(String name, bool value) {
          var mask = typeOf(name);
          Expect.equals(
              value, isContainer(mask), '$name is container (mask: $mask)');
        }

        checkContainer('probe1methods', true);
        checkType('probe1res', commonMasks.uint31Type);
        checkType('probe1sum', commonMasks.positiveIntType);

        checkContainer('probe2methods', false);
        checkType('probe2res', commonMasks.dynamicType);
      }));
}
