// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

T identity<T>(T t) => t;
T identityObject<T extends Object>(T t) => t;
T identityList<T extends List<T>>(T t) => t;

// Test that error messages involving generic function types
// print the type variable bounds correctly.
String x = identity; // No bound
String y = identityObject; // Object bound
String z = identityList; // List<T> bound

main() {}
