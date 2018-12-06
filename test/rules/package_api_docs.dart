// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N package_api_docs`

abstract class Foo //__LINT => TODO: fix API Model to treat tests specially
{
  /// Start a bar.
  bar(); //OK

  foo() => new _Bar().baz(); //__LINT
}

class _Bar //OK
{
  baz() => 42; //OK
}
