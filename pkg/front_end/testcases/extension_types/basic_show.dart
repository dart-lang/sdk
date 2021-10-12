// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E1 on int show num {} // Ok.

extension E2 on int {} // Ok.

extension E3 on int show {} // Error.

extension E4 on int show num, Comparable {} // Ok.

extension E5 on int show num, {} // Error.

extension E6 on int show , num {} // Error.

main() {}
