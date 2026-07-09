// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From co19/Language/Types/Type_Aliases/scope_t02

class A {}

class C<T> {}

typedef AAlias = A;
typedef CAlias<T> = C<T>;

typedef AAlias = A; //  error
typedef AAlias = C<String>; // error
typedef CAlias<T> = C<T>; //  error
typedef CAlias = C<String>; //  error
typedef CAlias<T1, T2> = C<T1>; //  error

main() {}
