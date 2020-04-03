// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The test for recursive typedef declaration involving multiple typedefs.

typedef Foo<T> = void Function(Bar<T>);
typedef Bar<T> = void Function(Baz<T>);
typedef Baz<T> = void Function(Foo<T>);

main() {}
