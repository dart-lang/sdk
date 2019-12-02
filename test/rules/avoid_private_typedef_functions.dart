// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_private_typedef_functions`

typedef void _F1(); // LINT
typedef void F1(); // OK

typedef _F2 = void Function(); // LINT
typedef F2 = void Function(); // OK

typedef void _F3(); // LINT
m3(_F3 f) => null;

typedef void _F4(); // OK
m4a(_F4 f) => null;
m4b(_F4 f) => null;

typedef void _F5(); // OK
_F5 v5a;
_F5 v5b;

typedef void _F6(); // OK
_F6 f6a() => null;
_F6 f6b() => null;

typedef _F7 = void Function(); // OK
m7(_F7 f) => null;
List<_F7> l7 = [];

typedef void _F8(); // OK
m8(_F8 f) => null;
List<_F8> l8 = [];
