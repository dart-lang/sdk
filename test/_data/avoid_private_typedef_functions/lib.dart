// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_private_typedef_functions`

part 'part.dart';

typedef void _FL1(); // LINT
typedef void _FL2(); // OK

_FP1 fp1l() => null;
_FP2 fp2l() => null;
_FL2 fl2l() => null;