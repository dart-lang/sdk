// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that identifiers which are used explicitly in the grammar but are
// not built-in identifiers can be used as library prefixes.

// The identifiers listed below are mentioned in the grammar, but none of
// them is a reserved word or a built-in identifier. Such an identifier can
// be used as a library prefix; this test puts such prefixes in wrong
// locations to verify that this is being handled. Here are the 'known'
// identifiers: `async`, `await`, `hide`, `of`, `on`, `show`, `sync`, `yield`.

import "package:expect/expect.dart";
import 'built_in_identifier_prefix_library_async.dart' as async;
import 'built_in_identifier_prefix_library_await.dart' as await;
import 'built_in_identifier_prefix_library_hide.dart' as hide;
import 'built_in_identifier_prefix_library_of.dart' as of;
import 'built_in_identifier_prefix_library_on.dart' as on;
import 'built_in_identifier_prefix_library_show.dart' as show;
import 'built_in_identifier_prefix_library_sync.dart' as sync;
import 'built_in_identifier_prefix_library_yield.dart' as yield;

async<dynamic> _async = new async.A(); //# 01: compile-time error
await<dynamic> _await = new await.A(); //# 02: compile-time error
hide<dynamic> _hide = new hide.A(); //# 03: compile-time error
of<dynamic> _of = new of.A(); //# 04: compile-time error
on<dynamic> _on = new on.A(); //# 05: compile-time error
show<dynamic> _show = new show.A(); //# 06: compile-time error
sync<dynamic> _sync = new sync.A(); //# 07: compile-time error
yield<dynamic> _yield = new yield.A(); //# 08: compile-time error

async.B<async> _B_async = new async.B(); //# 09: compile-time error
await.B<await> _B_await = new await.B(); //# 10: compile-time error
hide.B<hide> _B_hide = new hide.B(); //# 11: compile-time error
of.B<of> _B_of = new of.B(); //# 12: compile-time error
on.B<on> _B_on = new on.B(); //# 13: compile-time error
show.B<show> _B_show = new show.B(); //# 14: compile-time error
sync.B<sync> _B_sync = new sync.B(); //# 15: compile-time error
yield.B<yield> _B_yield = new yield.B(); //# 16: compile-time error

async.B<async<dynamic>> _B2_async = new async.B(); //# 17: compile-time error
await.B<await<dynamic>> _B2_await = new await.B(); //# 18: compile-time error
hide.B<hide<dynamic>> _B2_hide = new hide.B(); //# 19: compile-time error
of.B<of<dynamic>> _B2_of = new of.B(); //# 20: compile-time error
on.B<on<dynamic>> _B2_on = new on.B(); //# 21: compile-time error
show.B<show<dynamic>> _B2_show = new show.B(); //# 22: compile-time error
sync.B<sync<dynamic>> _B2_sync = new sync.B(); //# 23: compile-time error
yield.B<yield<dynamic>> _B2_yield = new yield.B(); //# 24: compile-time error

main() {
  Expect.isTrue(_async is async.A); //# 01: continued
  Expect.isTrue(_await is await.A); //# 02: continued
  Expect.isTrue(_hide is hide.A); //# 03: continued
  Expect.isTrue(_of is of.A); //# 04: continued
  Expect.isTrue(_on is on.A); //# 05: continued
  Expect.isTrue(_show is show.A); //# 06: continued
  Expect.isTrue(_sync is sync.A); //# 07: continued
  Expect.isTrue(_yield is yield.A); //# 08: continued

  Expect.isTrue(_B_async is async.B); //# 09: continued
  Expect.isTrue(_B_await is await.B); //# 10: continued
  Expect.isTrue(_B_hide is hide.B); //# 11: continued
  Expect.isTrue(_B_of is of.B); //# 12: continued
  Expect.isTrue(_B_on is on.B); //# 13: continued
  Expect.isTrue(_B_show is show.B); //# 14: continued
  Expect.isTrue(_B_sync is sync.B); //# 15: continued
  Expect.isTrue(_B_yield is yield.B); //# 16: continued

  Expect.isTrue(_B2_async is async.B); //# 17: continued
  Expect.isTrue(_B2_await is await.B); //# 18: continued
  Expect.isTrue(_B2_hide is hide.B); //# 19: continued
  Expect.isTrue(_B2_of is of.B); //# 20: continued
  Expect.isTrue(_B2_on is on.B); //# 21: continued
  Expect.isTrue(_B2_show is show.B); //# 22: continued
  Expect.isTrue(_B2_sync is sync.B); //# 23: continued
  Expect.isTrue(_B2_yield is yield.B); //# 24: continued
}
