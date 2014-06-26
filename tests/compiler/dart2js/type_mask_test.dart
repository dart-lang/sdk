// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'parser_helper.dart';
import "package:compiler/implementation/types/types.dart";

const String CODE = """
class A {}
class B extends A {}
class C implements A {}
main() {
  print([new A(), new B(), new C()]);
}
""";

main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(CODE, uri);

  asyncTest(() => compiler.runCompiler(uri).then((_) {
    var classA = findElement(compiler, 'A');
    var classB = findElement(compiler, 'B');
    var classC = findElement(compiler, 'C');

    var exactA = new TypeMask.exact(classA);
    var exactB = new TypeMask.exact(classB);
    var exactC = new TypeMask.exact(classC);

    var subclassA = new TypeMask.subclass(classA);
    var subtypeA = new TypeMask.subtype(classA);

    rule(a, b, c) => Expect.equals(c, a.isInMask(b, compiler));

    rule(exactA, exactA, true);
    rule(exactA, exactB, false);
    rule(exactA, exactC, false);
    rule(exactA, subclassA, true);
    rule(exactA, subtypeA, true);

    rule(exactB, exactA, false);
    rule(exactB, exactB, true);
    rule(exactB, exactC, false);
    rule(exactB, subclassA, true);
    rule(exactB, subtypeA, true);

    rule(exactC, exactA, false);
    rule(exactC, exactB, false);
    rule(exactC, exactC, true);
    rule(exactC, subclassA, false);
    rule(exactC, subtypeA, true);

    rule(subclassA, exactA, false);
    rule(subclassA, exactB, false);
    rule(subclassA, exactC, false);
    rule(subclassA, subclassA, true);
    rule(subclassA, subtypeA, true);

    rule(subtypeA, exactA, false);
    rule(subtypeA, exactB, false);
    rule(subtypeA, exactC, false);
    rule(subtypeA, subclassA, false);
    rule(subtypeA, subtypeA, true);
  }));
}
