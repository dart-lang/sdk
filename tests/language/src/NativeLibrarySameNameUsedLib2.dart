// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Native implementation.

#library('lib2');
#import('NativeLibrarySameNameUsedLib1.dart');  // To get interface I.

// Native impl has same name as interface.
class Impl implements I native "*I" {
  Impl read() native;
  write(Impl x) native;
}
