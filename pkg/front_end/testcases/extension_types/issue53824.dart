// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E1(Never foo) {} // Error.
extension type E2<X extends Never>(X foo) {} // Error.
extension type E3<X extends Y, Y extends Never>(X foo) {} // Error.
