// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `external` instance variables cannot be introduced by a declaring parameter.

// SharedOptions=--enable-experiment=primary-constructors

class C(external int x);
//      ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'external' here.
