// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Missing() {} // Error

extension type Multiple(bool instanceField1, int instanceField2) {}  // Error

extension type Duplicate(bool instanceField, int instanceField) {} // Error