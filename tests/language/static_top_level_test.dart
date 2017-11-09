// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

static method() { } //                   //# 00: syntax error
static var field; //                     //# 01: syntax error
static const finalField = 42; //         //# 02: syntax error
static const constant = 123; //          //# 03: syntax error

static int typedMethod() => 87; //       //# 04: syntax error
static int typedField; //                //# 05: syntax error
static const int typedFinalField = 99; //# 06: syntax error
static const int typedConstant = 1; //   //# 07: syntax error

void main() {}
