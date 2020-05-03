// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_is_even_rather_than_modulo`

bool isEven = 1 % 2 == 0; //LINT
bool isOdd = 13 % 2 == 1; //LINT
int number = 3;
bool c = number % 2 == 0; //LINT

// Not equality operator is okay
bool a = 1 % 2 >= 0;
bool d = number % 2 != 0;

// Modulo by any other number than 2 is okay
d = number % 3 == 1;

// Not modulo operation is okay.
d = number + 2 == 0;

// Compare to not an IntegerLiteral is okay.
bool b = 1 % 2 == 3-3;
// Unknown operand type is okay.
Class tmp;
a = tmp % 2 == 0;

a = 1.isEven;
a = 2.isOdd;
