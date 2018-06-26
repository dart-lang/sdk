// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_js_helper';

main() {
  noThrows();
  noInline();
  throws();
}

// We trust the annotation.
/*element: noThrows:no-throw*/
@NoThrows()
@NoInline() // Required for the @NoThrows() annotation.
noThrows() => throw '';

// Check that the @NoInline() annotation has no impact on its own.
/*element: noInline:*/
@NoInline()
noInline() {}

// TODO(johnniwinther): Should we infer this?
/*element: throws:*/
throws() => 0;
