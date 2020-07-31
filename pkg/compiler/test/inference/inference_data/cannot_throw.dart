// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  noThrows();
  noInline();
  throws();
}

// We trust the annotation.
/*member: noThrows:no-throw*/
@pragma('dart2js:noThrows')
@pragma(
    'dart2js:noInline') // Required for the @pragma('dart2js:noThrows') annotation.
noThrows() => throw '';

// Check that the @pragma('dart2js:noInline') annotation has no impact on its own.
/*member: noInline:*/
@pragma('dart2js:noInline')
noInline() {}

// TODO(johnniwinther): Should we infer this?
/*member: throws:*/
throws() => 0;
