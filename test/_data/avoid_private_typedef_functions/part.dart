// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_private_typedef_functions`

part of 'lib.dart';

typedef void _FP1(); // LINT
typedef void _FP2(); // OK

_FL1 fl1p() => null;
_FL2 fl2p() => null;
_FP2 fp2p() => null;
