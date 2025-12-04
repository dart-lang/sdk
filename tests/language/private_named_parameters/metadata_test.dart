// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Can call constructors with private names as metadata annotations.

// SharedOptions=--enable-experiment=private-named-parameters

import 'package:expect/expect.dart';

class C {
  final String _foo;
  final String _bar;

  const C({required this._foo, required this._bar})
      : assert(_foo == 'foo'),
        assert(_bar == 'bar');
}

@C(foo: 'foo', bar: 'bar')
void main() {}
