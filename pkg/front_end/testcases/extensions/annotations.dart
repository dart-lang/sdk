// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  @pragma('dart2js:noInline')
  instanceMethod() {}

  @pragma('dart2js:noInline')
  static staticMethod() {}
}

extension Extension on Class {
  @pragma('dart2js:noInline')
  extensionInstanceMethod() {}

  @pragma('dart2js:noInline')
  static extensionStaticMethod() {}
}

@pragma('dart2js:noInline')
topLevelMethod() {}

main() {}
