// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type const ET(int? i) {}

const dynamic a = ET(null);
const dynamic b = ET(0);
const List<int?> c = [a, b];