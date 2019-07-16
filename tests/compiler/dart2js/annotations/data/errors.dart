// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  noThrowsWithoutNoInline();
  noSideEffectsWithoutNoInline();
}

@pragma('dart2js:noThrows')
/*error: @pragma('dart2js:noThrows') should always be combined with @pragma('dart2js:noInline').*/
noThrowsWithoutNoInline() {}

@pragma('dart2js:noSideEffects')
/*error: @pragma('dart2js:noSideEffects') should always be combined with @pragma('dart2js:noInline').*/
noSideEffectsWithoutNoInline() {}
