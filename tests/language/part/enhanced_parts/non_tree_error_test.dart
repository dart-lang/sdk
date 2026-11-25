// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// DIFFERENT URIS. Should count as different parts.
part './/non_tree_files/non_tree_part1.dart';
part './non_tree_files//non_tree_part1.dart';

void main() {}
