// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Static field used in tests below.
var field;

/// Read a static field. This adds dependency of static properties to the
/// side effects of the method.
/*member: readStaticField:SideEffects(reads static; writes nothing)*/
readStaticField() => field;

/// Read a static field. If not for the `@pragma('dart2js:noSideEffects')`
/// annotation this would add dependency of static properties to the side
/// effects of the method.
/*member: readStaticFieldAnnotated:SideEffects(reads nothing; writes nothing)*/
@pragma('dart2js:noInline')
@pragma('dart2js:noSideEffects')
readStaticFieldAnnotated() => field;

/*member: main:SideEffects(reads static; writes nothing)*/
main() {
  readStaticField();
  readStaticFieldAnnotated();
}
