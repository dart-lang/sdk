// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--print_instructions_sizes-to=no/such/path
// VMOptions=--timeline_dir=no/such/path
// VMOptions=--trace_precompiler_to=no/such/path
// VMOptions=--write_code_comments_as_synthetic_source_to=no/such/path
// VMOptions=--write_retained_reasons_to=no/such/path
// VMOptions=--write_v8_snapshot_profile-to=no/such/path

// @dart = 2.9

main() {
  print("Just checking we don't crash.");
}
