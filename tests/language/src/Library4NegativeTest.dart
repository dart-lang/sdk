// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test should fail to load because library1 defines a top-level
// variable named 'foo' which conflicts with the prefix 'foo' used to import
// library3.  This is an error even if 'foo' is never referred to.

#library("Library4NegativeTest.dart");
#import("library1.dart"); // Defines a top-level variable 'foo'
#import("library3.dart", prefix:"foo"); // Creates prefix 'foo'

main() {
}
