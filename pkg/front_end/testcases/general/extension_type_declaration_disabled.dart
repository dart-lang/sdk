// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

extension type ExtensionType1(int it) {}
extension type ExtensionType2<T>._(int it) implements int, ExtensionType1 {}
