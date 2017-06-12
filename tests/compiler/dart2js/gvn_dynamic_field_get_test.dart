// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that dart2js gvns dynamic getters that don't have side
// effects.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/universe/selector.dart' show Selector;

const String TEST = r"""
class A {
  var foo;
  bar(a) {
    return a.foo + a.foo;
  }
}

main() {
  new A().bar(new Object());
}
""";

main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        String generated = compiler.assembledCode;
        RegExp regexp = new RegExp(r"get\$foo");
        Iterator matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
        var cls = findElement(compiler, 'A');
        Expect.isNotNull(cls);
        String name = 'foo';
        var element = cls.lookupLocalMember(name);
        Expect.isNotNull(element);
        Selector selector = new Selector.getter(new PublicName(name));
        Expect.isFalse(compiler.resolutionWorldBuilder.closedWorldForTesting
            .hasAnyUserDefinedGetter(selector, null));
      }));
}
