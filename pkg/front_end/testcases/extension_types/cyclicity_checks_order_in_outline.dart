// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the order of elements in the outline doesn't affect the
// outcome of cyclicity checks.

extension type E1(F1 it) {} // Ok.
typedef F1 = F1; // Error.

typedef F2 = F2; // Error.
extension type E2(F2 it) {} // Ok.
