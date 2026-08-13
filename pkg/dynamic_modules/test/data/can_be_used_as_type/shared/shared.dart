// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class L1A {}

class L1B {}

class L1C {}

extension type L1D(int i) {}

class C1 implements L1A, L1B, L1C {}

class L1Ea {}

class L1Eb implements L1Ea {}

class L1Ec implements L1Eb {}

class L1Fa {}

class L1Fb implements L1Fa {}

class L1Fc extends L1Fb {}

class L1Ga {}

mixin class L1Gb implements L1Ga {}

class L1Gc with L1Gb {}
