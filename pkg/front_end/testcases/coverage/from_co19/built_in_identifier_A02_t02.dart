// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on
// tests/co19/src/Language/Expressions/Identifier_Reference/built_in_identifier_A02_t02.dart

class C<as> // Error
{}

mixin M<as> // Error
{}

enum E<as> // Error
{
  e1;
}

void foo<as>() // Error
{}

extension Ext<as> on List // Error
{}

typedef int F1<as>(); // Error

typedef F2<as extends Comparable<as>> // Error
    = int Function();

const void Function<as>()? // Error
    c = null;
