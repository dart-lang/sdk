// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  noInline();
  tryInline();
  noInline2();
  tryInline2();
  noElision();
  noThrows();
  noSideEffects();
  assumeDynamic();
  disableInlining();
  several();
}

/*member: noInline:noInline*/
@pragma('dart2js:noInline')
noInline() {}

/*member: tryInline:tryInline*/
@pragma('dart2js:tryInline')
tryInline() {}

/*member: noInline2:noInline*/
@pragma('dart2js:never-inline')
noInline2() {}

/*member: tryInline2:tryInline*/
@pragma('dart2js:prefer-inline')
tryInline2() {}

/*member: noElision:noElision*/
@pragma('dart2js:noElision')
noElision() {}

/*member: noThrows:noInline,noThrows*/
@pragma('dart2js:noThrows')
@pragma('dart2js:noInline')
noThrows() {}

/*member: noSideEffects:noInline,noSideEffects*/
@pragma('dart2js:noSideEffects')
@pragma('dart2js:noInline')
noSideEffects() {}

/*member: assumeDynamic:assumeDynamic*/
@pragma('dart2js:assumeDynamic')
assumeDynamic() {}

/*member: disableInlining:disable-inlining*/
@pragma('dart2js:disable-inlining')
disableInlining() {}

/*member: several:assumeDynamic,disable-inlining,noInline,noSideEffects,noThrows*/
@pragma('dart2js:disable-inlining')
@pragma('dart2js:noThrows')
@pragma('dart2js:noSideEffects')
@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
several() {}
