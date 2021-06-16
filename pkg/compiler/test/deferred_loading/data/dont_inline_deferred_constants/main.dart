// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 a_pre_fragments=[
  p1: {units: [1{lib1}], usedBy: [], needs: []},
  p2: {units: [3{lib2}], usedBy: [], needs: []},
  p3: {units: [2{lib1, lib2}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [1{lib1}],
  f2: [3{lib2}],
  f3: [2{lib1, lib2}]],
 c_steps=[
  lib1=(f3, f1),
  lib2=(f3, f2)]
*/

/*two-frag|three-frag.library: 
 a_pre_fragments=[
  p1: {units: [1{lib1}], usedBy: [p2], needs: []},
  p2: {units: [2{lib1, lib2}, 3{lib2}], usedBy: [], needs: [p1]}],
 b_finalized_fragments=[
  f1: [1{lib1}],
  f2: [2{lib1, lib2}, 3{lib2}]],
 c_steps=[
  lib1=(f2, f1),
  lib2=(f2)]
*/

// @dart = 2.7

// TODO(sigmund): remove this indirection and move the main code here. This is
// needed because of the id-equivalence frameworks overrides the entrypoint URI.
export 'exported_main.dart';
