// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Value classes are always leaves in the tree of types

const String valueClass = "valueClass";

@valueClass
class Animal {}

class Cat implements Animal {}
//                   ^^^^^^
// [cfe] unspecified
