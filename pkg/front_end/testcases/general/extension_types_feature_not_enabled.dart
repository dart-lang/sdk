// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Remove this file when 'extension-types' is enabled by default.

class A {}

extension type E on A {} // Error because of 'type'.

main() {}
