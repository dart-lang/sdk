// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_in_isolate_lib;

class DeferredObj {
  DeferredObj(this._val);
  toString() => "$_val";
    
  var _val;
}
