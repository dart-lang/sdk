// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.19

// This library is purposely labeled to use an OLD sdk version prior to 3.0.
// The trim script based on dynamic interfaces will reject uses of `M3` in the
// extendable section, but allows it on the callable section.
class M3 {
  String method3() => '3';
}
