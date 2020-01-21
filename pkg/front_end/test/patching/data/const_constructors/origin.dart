// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

/*class: PatchedClass:
 kernel-members=[
   PatchedClass.,
   _field
 ]
*/
class PatchedClass {
  external const PatchedClass({int field});
}
