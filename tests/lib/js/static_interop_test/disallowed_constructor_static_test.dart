// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library disallowed_constructor_static_test;

import 'package:js/js.dart';

@JS()
@staticInterop
class JSClass {
  external JSClass();
  //       ^
  // [web] `@staticInterop` classes should not contain any generative constructors.
  external JSClass.namedConstructor();
  //       ^
  // [web] `@staticInterop` classes should not contain any generative constructors.
}

@JS()
@staticInterop
class SyntheticConstructor {}

@JS()
@staticInterop
@anonymous
class Anonymous {
  external factory Anonymous({String? a});
  external factory Anonymous.named({String? a});
}

void main() {
  SyntheticConstructor();
//^
// [web] Synthetic constructors on `@staticInterop` classes can not be used.

  SyntheticConstructor.new;
//^
// [web] Synthetic constructors on `@staticInterop` classes can not be used.

  // Make sure that we report an error for every usage of the constant and that
  // we check nested constants.
  const [SyntheticConstructor.new];
//^
// [web] Synthetic constructors on `@staticInterop` classes can not be used.

  Anonymous.new;
//^
// [web] Factories of `@anonymous` `@staticInterop` classes can not be torn off.
  Anonymous.named;
//^
// [web] Factories of `@anonymous` `@staticInterop` classes can not be torn off.

  const [Anonymous.new, Anonymous.named];
//^
// [web] Factories of `@anonymous` `@staticInterop` classes can not be torn off.
}
