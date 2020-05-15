// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@pragma('dart2js:noInline')
String confuse(String x) => x;

@pragma('dart2js:noInline')
sink(x) {}

main() {
  confuse('x');
  var m = confuse(null);
  // JSString.isEmpty gets inlined to 'm.length==0'
  sink(m. /*0:main*/ isEmpty);
}
