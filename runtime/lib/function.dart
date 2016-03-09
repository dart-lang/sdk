// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Closure implements Function {

  bool operator ==(other) native "Closure_equals";

  int get hashCode native "Closure_hashCode";

  _Closure get call => this;

  _Closure _clone() native "Closure_clone";

  // The type_arguments_, function_, and context_ fields are not declared here.
}
