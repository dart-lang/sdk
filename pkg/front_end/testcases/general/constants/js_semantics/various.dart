// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const bool y = false;
const bool z = !(y);

const maybeInt = z ? 42 : true;
const bool isItInt = maybeInt is int ? true : false;
const bool isItDouble = maybeInt is double ? true : false;

const int actualInt = 42;
const bool isItInt2 = actualInt is int ? true : false;
const bool isItDouble2 = actualInt is double ? true : false;

const maybeDouble = z ? 42.0 : true;
const bool isItInt3 = maybeDouble is int ? true : false;
const bool isItDouble3 = maybeDouble is double ? true : false;

const double actualDouble = 42.0;
const bool isItInt4 = actualDouble is int ? true : false;
const bool isItDouble4 = actualDouble is double ? true : false;

const maybeDouble2 = z ? 42.42 : true;
const bool isItInt5 = maybeDouble2 is int ? true : false;
const bool isItDouble5 = maybeDouble2 is double ? true : false;

const double actualDouble2 = 42.42;
const bool isItInt6 = actualDouble2 is int ? true : false;
const bool isItDouble7 = actualDouble2 is double ? true : false;

const zeroPointZeroIdentical = identical(0.0, 0.0);
const zeroPointZeroIdenticalToZero = identical(0.0, 0);
const zeroIdenticalToZeroPointZero = identical(0, 0.0);
const nanIdentical = identical(0 / 0, 0 / 0);
const stringIdentical = identical("hello", "hello");
const string2Identical = identical("hello", "world");

const zeroPointZeroEqual = 0.0 == 0.0;
const zeroPointZeroEqualToZero = 0.0 == 0;
const zeroEqualToZeroPointZero = 0 == 0.0;
const nanEqual = 0 / 0 == 0 / 0;
const stringEqual = "hello" == "hello";
const string2Equal = "hello" == "world";

const int intFortyTwo = 42;
const String intStringConcat = "hello" "${intFortyTwo * intFortyTwo}";
