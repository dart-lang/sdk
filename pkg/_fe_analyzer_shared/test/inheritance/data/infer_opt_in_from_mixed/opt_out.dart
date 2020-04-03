// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart = 2.5

/*class: Legacy:Legacy,Object*/
abstract class Legacy {
  /*member: Legacy.mandatory:void Function(int*)**/
  void mandatory(int param);
  /*member: Legacy.optional:void Function(int*)**/
  void optional(int param);
}
