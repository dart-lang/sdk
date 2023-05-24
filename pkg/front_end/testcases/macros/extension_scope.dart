// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'extension_scope_lib.dart';

test(Class c) {
  c._namedExtensionPrivateMethod(); // Error
  c.unnamedExtensionMethod(); // Error
  c._unnamedExtensionPrivateMethod(); // Error

  c._namedInjectedExtensionPrivateMethod1(); // Error
  c.unnamedInjectedExtensionMethod1(); // Error
  c._unnamedInjectedExtensionPrivateMethod1(); // Error

  c._namedInjectedExtensionPrivateMethod2(); // Error
  c.unnamedInjectedExtensionMethod2(); // Error
  c._unnamedInjectedExtensionPrivateMethod2(); // Error
}

method(Class c) {
  c.namedExtensionMethod(); // Ok
  c.namedInjectedExtensionMethod1(); // Ok
  c.namedInjectedExtensionMethod2(); // Ok
}

main() {
  method(new Class());
}
