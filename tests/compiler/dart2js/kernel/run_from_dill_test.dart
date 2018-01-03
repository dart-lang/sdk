// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we can compile from dill and run the generated code with d8.
library dart2js.kernel.run_from_dill_test;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';

import 'compiler_helper.dart';
import '../serialization/helper.dart';

const SOURCE = const {
  'main.dart': r'''
import "package:expect/expect.dart";

class K {}

class A<T> {
  foo() {
    bar() => T;
    return bar();
  }
}

class B extends A<K> {}

class X<T> {}

// [globalMethod] and [format] are copied from
// `language/named_parameters_with_dollars_test`. This test failed because
// when inlining [globalMethod] the named arguments where processed unsorted,
// passing `[a, a$b, a$$b, b]` to [format] instead of `[a, b, a$b, a$$b]`.
globalMethod({a, b, a$b, a$$b}) => [a, b, a$b, a$$b];

format(thing) {
  if (thing == null) return '-';
  if (thing is List) {
    var fragments = ['['];
    var sep;
    for (final item in thing) {
      if (sep != null) fragments.add(sep);
      sep = ', ';
      fragments.add(format(item));
    }
    fragments.add(']');
    return fragments.join();
  }
  return thing.toString();
}

main() {
  for (int i = 0; i < 10; i++) {
    if (i == 5) continue;
    print('Hello World: $i!');
    if (i == 7) break;
  }
  Expect.equals(new A<int>().foo(), int);
  var v = new DateTime.now().millisecondsSinceEpoch != 42
      ? new X<B>()
      : new X<A<String>>();
  Expect.isFalse(v is X<A<String>>);
  Expect.equals('[1, 2, -, -]', format(globalMethod(a: 1, b: 2)));
}
'''
};

const OUTPUT = '''
Hello World: 0!
Hello World: 1!
Hello World: 2!
Hello World: 3!
Hello World: 4!
Hello World: 6!
Hello World: 7!
''';

main(List<String> args) {
  asyncTest(() async {
    await mainInternal(args);
  });
}

enum ResultKind { crashes, errors, warnings, success, failure }

Future<ResultKind> mainInternal(List<String> args,
    {bool skipWarnings: false, bool skipErrors: false}) async {
  Arguments arguments = new Arguments.from(args);
  Uri entryPoint;
  Map<String, String> memorySourceFiles;
  if (arguments.uri != null) {
    entryPoint = arguments.uri;
    memorySourceFiles = const <String, String>{};
  } else {
    entryPoint = Uri.parse('memory:main.dart');
    memorySourceFiles = SOURCE;
  }

  await runWithD8(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [Flags.useKernel, Flags.enableAssertMessage],
      expectedOutput: OUTPUT);

  return ResultKind.success;
}
