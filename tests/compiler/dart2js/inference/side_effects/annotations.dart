// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/// Static field used in tests below.
var field;

/// Read a static field. This adds dependency of static properties to the
/// side effects of the method.
/*element: readStaticField:Reads static; writes nothing.*/
readStaticField() => field;

/// Read a static field. If not for the `@NoSideEffects()` annotation this would
/// add dependency of static properties to the side effects of the method.
/*element: readStaticFieldAnnotated:Reads nothing; writes nothing.*/
@NoInline()
@NoSideEffects()
readStaticFieldAnnotated() => field;

/*element: main:Reads static; writes nothing.*/
main() {
  readStaticField();
  readStaticFieldAnnotated();
}
