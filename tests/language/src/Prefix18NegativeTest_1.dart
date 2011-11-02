// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// prefix: strings should only contain valid identifiers

#library("Prefix18NegativeTest.dart");
#import("library1.dart", prefix:"lib1.invalid");

main() {
}
