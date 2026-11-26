// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of my.lib;
//      ^^^^^^
// [analyzer] SYNTACTIC_ERROR.PART_OF_NAME
// [cfe] The 'part of' directive can't use a name with the enhanced-parts feature.

int x = 42;
