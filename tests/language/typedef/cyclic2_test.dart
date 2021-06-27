// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type alias cyclicity with new syntax and generic function types.

// A body dependency, cycle length 1.
typedef F1<X> = F1<X> Function();
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F1' has a reference to itself.

// A body dependency (in a bound), cycle length 1.
typedef F2<X> = Function<Y extends F2<X>>(Y);
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F2' has a reference to itself.

// A bound dependency, cycle length 1.
typedef F3<X extends F3<X>> = Function(X);
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F3' has a reference to itself.

// A body dependency, cycle length 2.
typedef F4a<X> = F4b<X> Function();
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F4a' has a reference to itself.

typedef F4b<X> = F4a<X> Function();
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F4b' has a reference to itself.

// A body dependency (in a bound), cycle length 2.
typedef F5a<X> = Function<Y extends F5b<X>>(Y);
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F5a' has a reference to itself.

typedef F5b<X> = Function<Y extends F5a<X>>(Y);
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F5b' has a reference to itself.

// A bound dependency, cycle length 2.
typedef F6a<X extends F6b<X>> = Function(X);
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F6a' has a reference to itself.

typedef F6b<X extends F6a<X>> = Function(X);
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F6b' has a reference to itself.

void main() {}
