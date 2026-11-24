// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// Import contains invalid part/part-of relation.
import "package:enhanced_parts_cross_package_test_lib_helper/cross_package_lib_lib.dart";

// Import contains invalid part/part-of relation.
import "enhanced_parts_cross_package_test_lib_helper/tool/cross_package_tool_lib.dart";

void main() {}
