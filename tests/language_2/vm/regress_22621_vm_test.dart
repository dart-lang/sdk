// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that BoxAllocationSlowPath for Mint emits stackmap in unoptimized code.
// VMOptions=--gc_at_instance_allocation=_Mint --inline_alloc=false

main() {
  var re = new RegExp(r"IsolateStubs (.*)");
  return re.firstMatch("oooo");
}
