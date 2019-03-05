// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  noThrows();
  noInline();
  throws();
}

// We trust the annotation.
/*element: noThrows:no-throw*/
@pragma('dart2js:noThrows')
@pragma(
    'dart2js:noInline') // Required for the @pragma('dart2js:noThrows') annotation.
noThrows() => throw '';

// Check that the @pragma('dart2js:noInline') annotation has no impact on its own.
/*element: noInline:*/
@pragma('dart2js:noInline')
noInline() {}

// TODO(johnniwinther): Should we infer this?
/*element: throws:*/
throws() => 0;
