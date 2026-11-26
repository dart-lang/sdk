// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Program used by check_snapshot_symbols_test.dart. The functions are not
// inlined so that each has its own symbol in the snapshot, and their names
// start with characters that assemblers and linkers may treat specially.

@pragma('vm:never-inline')
int leadingLowercaseL(int i) => i + 1;

@pragma('vm:never-inline')
// ignore: non_constant_identifier_names
int LeadingUppercaseL(int i) => i + 2;

@pragma('vm:never-inline')
int _leadingUnderscore(int i) => i + 3;

void main(List<String> args) {
  print(leadingLowercaseL(args.length));
  print(LeadingUppercaseL(args.length));
  print(_leadingUnderscore(args.length));
}
