// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  ParameterTest().buildAll();
}

class ParameterTest extends PartialCodeTest {
  buildAll() {
    buildTests('required', [
      TestDescriptor(
        'functionType_noIdentifier',
        'f(Function(void)) {}',
        [diag.expectedToken],
        'f(Function(void) _s_) {}',
        failing: ['eof'],
      ),
      TestDescriptor(
        'typeArgument_noGt',
        '''
          class C<E> {}
          f(C<int Function(int, int) c) {}
          ''',
        [diag.expectedToken],
        '''
          class C<E> {}
          f(C<int Function(int, int)> c) {}
          ''',
        failing: ['eof'],
      ),
    ], []);
  }
}
