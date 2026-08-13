// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

// Initializing formal.
extension type E07(int this.x) /* Error */ {}

// Super parameter.
extension type E08(int super.x) /* Error */ {}

// Old-style function parameter syntax.
extension type E11(int x()) /* Error */ {}
