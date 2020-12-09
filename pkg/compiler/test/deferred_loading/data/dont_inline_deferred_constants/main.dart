// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec|three-frag.library: 
 output_units=[
  f1: {units: [2{lib1, lib2}], usedBy: [2, 3], needs: []},
  f2: {units: [1{lib1}], usedBy: [], needs: [1]},
  f3: {units: [3{lib2}], usedBy: [], needs: [1]}],
 steps=[
  lib1=(f1, f2),
  lib2=(f1, f3)]
*/

/*two-frag.library: 
 output_units=[
  f1: {units: [2{lib1, lib2}, 3{lib2}], usedBy: [2], needs: []},
  f2: {units: [1{lib1}], usedBy: [], needs: [1]}],
 steps=[
  lib1=(f1, f2),
  lib2=(f1)]
*/

// @dart = 2.7

// TODO(sigmund): remove this indirection and move the main code here. This is
// needed because of the id-equivalence frameworks overrides the entrypoint URI.
export 'exported_main.dart';
