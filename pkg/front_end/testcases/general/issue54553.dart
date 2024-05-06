// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type EINullable(int? _) implements int? {} // Error.

class A {}
class B implements A? {} // Error.
typedef F<T> = T;
extension type EIAliasNullable(A? _) implements F<A?> {} // Error.
