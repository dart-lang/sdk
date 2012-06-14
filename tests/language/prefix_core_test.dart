// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that Object can be resolved when importing dart:core with a prefix.

#import('dart:core', prefix:'core');

class Object {
}

main() => core.print(new Object());
