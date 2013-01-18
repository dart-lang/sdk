// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This unit test of dart2js checks that a SSA bailout target
// instruction gets removed from the graph when it's not used.

import 'compiler_helper.dart';

String TEST = r'''
main() {
  foo(1);
  foo([]);
}

foo(a) {
  // Make the method recursive to always enable bailouts
  // and force a list instantiation.
  foo([]);
  // Force bailout on [a].
  for (int i = 0; i < 100; i++) a[0] = 42;
  // Force bailout on [:a.length:].
  for (int i = 0; i < 200; i++) a[0] = -a.length;
}
''';

main() {
  String generated = compile(TEST, entry: 'foo');

  // Check that we only have one bailout call. The second bailout call
  // is dead code because we know [:a.length:] is an int.
  checkNumberOfMatches(new RegExp('bailout').allMatches(generated).iterator, 1);

  // Check that the foo method does not have any call to
  // 'getInterceptor'. The environment for the second bailout contains
  // the interceptor of [:a.length:], but since the bailout is
  // removed, the interceptor is removed too.
  Expect.isTrue(!generated.contains('getInterceptor'));

  generated = compileAll(TEST);
  
  // Check that the foo bailout method is generated.
  checkNumberOfMatches(
      new RegExp('foo\\\$bailout').allMatches(generated).iterator, 2);

  // Check that it's the only bailout method.
  checkNumberOfMatches(new RegExp('bailout').allMatches(generated).iterator, 2);

  // Check that the bailout method has a case 2 for the state, which
  // is the second bailout in foo.
  RegExp state = new RegExp('case 2:[ \n]+state0 = 0;');
  checkNumberOfMatches(state.allMatches(generated).iterator, 1);

  // Finally, make sure that the reason foo does not contain
  // 'getInterceptor' is not because the compiler renamed it.
  Expect.isTrue(generated.contains('getInterceptor'));
}
