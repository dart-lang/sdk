// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The identifiers listed below are mentioned in the grammar, but none of
// them is a reserved word or a built-in identifier. Such an identifier can
// be used as library prefix. Here are said 'known' identifiers:
//
//   `async`, `await`, `hide`, `of`, `on`, `show`, `sync`, `yield`.

import "package:expect/expect.dart";
import 'built_in_identifier_prefix_library_async.dart' as async;
import 'built_in_identifier_prefix_library_await.dart' as await;
import 'built_in_identifier_prefix_library_hide.dart' as hide;
import 'built_in_identifier_prefix_library_of.dart' as of;
import 'built_in_identifier_prefix_library_on.dart' as on;
import 'built_in_identifier_prefix_library_show.dart' as show;
import 'built_in_identifier_prefix_library_sync.dart' as sync;
import 'built_in_identifier_prefix_library_yield.dart' as yield;

async.A _async = new async.A();
await.A _await = new await.A();
hide.A _hide = new hide.A();
of.A _of = new of.A();
on.A _on = new on.A();
show.A _show = new show.A();
sync.A _sync = new sync.A();
yield.A _yield = new yield.A();

async.B<dynamic> dynamic_B_async = new async.B();
await.B<dynamic> dynamic_B_await = new await.B();
hide.B<dynamic> dynamic_B_hide = new hide.B();
of.B<dynamic> dynamic_B_of = new of.B();
on.B<dynamic> dynamic_B_on = new on.B();
show.B<dynamic> dynamic_B_show = new show.B();
sync.B<dynamic> dynamic_B_sync = new sync.B();
yield.B<dynamic> dynamic_B_yield = new yield.B();

class UseA {
  async.A _async = new async.A();
  await.A _await = new await.A();
  hide.A _hide = new hide.A();
  of.A _of = new of.A();
  on.A _on = new on.A();
  show.A _show = new show.A();
  sync.A _sync = new sync.A();
  yield.A _yield = new yield.A();
}

main() {
  Expect.isTrue(_async is async.A);
  Expect.isTrue(_await is await.A);
  Expect.isTrue(_hide is hide.A);
  Expect.isTrue(_of is of.A);
  Expect.isTrue(_on is on.A);
  Expect.isTrue(_show is show.A);
  Expect.isTrue(_sync is sync.A);
  Expect.isTrue(_yield is yield.A);

  Expect.isTrue(dynamic_B_async is async.B);
  Expect.isTrue(dynamic_B_await is await.B);
  Expect.isTrue(dynamic_B_hide is hide.B);
  Expect.isTrue(dynamic_B_of is of.B);
  Expect.isTrue(dynamic_B_on is on.B);
  Expect.isTrue(dynamic_B_show is show.B);
  Expect.isTrue(dynamic_B_sync is sync.B);
  Expect.isTrue(dynamic_B_yield is yield.B);

  var x = new UseA();
  Expect.isTrue(x._async is async.A);
  Expect.isTrue(x._await is await.A);
  Expect.isTrue(x._hide is hide.A);
  Expect.isTrue(x._of is of.A);
  Expect.isTrue(x._on is on.A);
  Expect.isTrue(x._show is show.A);
  Expect.isTrue(x._sync is sync.A);
  Expect.isTrue(x._yield is yield.A);
}
