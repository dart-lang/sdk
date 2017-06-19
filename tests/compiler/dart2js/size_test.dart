// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import "compiler_helper.dart";

const String TEST = "main() => [];";

const Map<String, String> DEFAULT_CORELIB_WITH_LIST = const <String, String>{
  'Object': 'class Object { const Object(); }',
  'bool': 'class bool {}',
  'List': 'abstract class List<E> {}',
  'num': 'class num {}',
  'int': 'class int {}',
  'double': 'class double {}',
  'String': 'class String {}',
  'Function': 'class Function {}',
  'Null': 'class Null {}',
  'Type': 'class Type {}',
  'Map': 'class Map {}',
  'StackTrace': 'class StackTrace {}',
  'identical': 'identical(a, b) => true;',
  'proxy': 'const proxy = 0;',
};

main() {
  asyncTest(() =>
      compileAll(TEST, coreSource: DEFAULT_CORELIB_WITH_LIST).then((generated) {
        return MockCompiler.create((MockCompiler compiler) {
          // Make sure no class is emitted.
          Expect.isFalse(generated.contains('finishClasses'));
        });
      }));
}
