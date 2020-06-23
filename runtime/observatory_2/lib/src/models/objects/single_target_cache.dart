// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class SingleTargetCacheRef extends ObjectRef {
  Code get target;
}

abstract class SingleTargetCache extends Object
    implements SingleTargetCacheRef {
  int get lowerLimit;
  int get upperLimit;
}
