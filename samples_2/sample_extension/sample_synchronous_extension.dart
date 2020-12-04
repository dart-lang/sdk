// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

library sample_synchronous_extension;

import 'dart-ext:sample_extension';

// The simplest way to call native code: top-level functions.
int systemRand() native "SystemRand";
int noScopeSystemRand() native "NoScopeSystemRand";
bool systemSrand(int seed) native "SystemSrand";
