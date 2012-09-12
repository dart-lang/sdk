// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that dart2js gvns dynamic getters that don't have side
// effects.

#import('compiler_helper.dart');
#import('parser_helper.dart');
#import('dart:uri');

const String TEST = @"""
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
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  String generated = compiler.assembledCode;
  RegExp regexp = const RegExp(@"get\$foo");
  Iterator matches = regexp.allMatches(generated).iterator();
  checkNumberOfMatches(matches, 1);
  var cls = findElement(compiler, 'A');
  Expect.isNotNull(cls);
  var element = cls.lookupLocalMember(buildSourceString('foo'));
  Expect.isNotNull(element);
  Expect.isFalse(compiler.world.userDefinedGetters.contains(element));
}
