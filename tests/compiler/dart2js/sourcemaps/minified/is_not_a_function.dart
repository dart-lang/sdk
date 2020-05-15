// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// TODO(sigmund): should this be handled as "other"? (the identifier appears
// direclty in the line producing the error).
//
// Error pattern: \.([^\.]*) is not a function
// Kind of minified name: instance
// Expected deobfuscated name: m1

main() {
  dynamic x = confuse(new B());
  x.m1();
}

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
confuse(x) => x;

class B {
  m2() {}
}
