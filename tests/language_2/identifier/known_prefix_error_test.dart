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
import 'built_in_prefix_library_async.dart' as async;
import 'built_in_prefix_library_await.dart' as await;
import 'built_in_prefix_library_hide.dart' as hide;
import 'built_in_prefix_library_of.dart' as of;
import 'built_in_prefix_library_on.dart' as on;
import 'built_in_prefix_library_show.dart' as show;
import 'built_in_prefix_library_sync.dart' as sync;
import 'built_in_prefix_library_yield.dart' as yield;

async<dynamic> _async = new async.A();
// [error line 24, column 1, length 5]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'async' isn't a type.
// [error line 24, column 1]
// [cfe] Expected 0 type arguments.
await<dynamic> _await = new await.A();
// [error line 30, column 1, length 5]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'await' isn't a type.
// [error line 30, column 1]
// [cfe] Expected 0 type arguments.
hide<dynamic> _hide = new hide.A();
// [error line 36, column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'hide' isn't a type.
// [error line 36, column 1]
// [cfe] Expected 0 type arguments.
of<dynamic> _of = new of.A();
// [error line 42, column 1, length 2]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'of' isn't a type.
// [error line 42, column 1]
// [cfe] Expected 0 type arguments.
on<dynamic> _on = new on.A();
// [error line 48, column 1, length 2]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'on' isn't a type.
// [error line 48, column 1]
// [cfe] Expected 0 type arguments.
show<dynamic> _show = new show.A();
// [error line 54, column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'show' isn't a type.
// [error line 54, column 1]
// [cfe] Expected 0 type arguments.
sync<dynamic> _sync = new sync.A();
// [error line 60, column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'sync' isn't a type.
// [error line 60, column 1]
// [cfe] Expected 0 type arguments.
yield<dynamic> _yield = new yield.A();
// [error line 66, column 1, length 5]
// [analyzer] COMPILE_TIME_ERROR.NOT_A_TYPE
// [cfe] 'yield' isn't a type.
// [error line 66, column 1]
// [cfe] Expected 0 type arguments.

async.B<async> _B_async = new async.B();
//      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'async' isn't a type.
await.B<await> _B_await = new await.B();
//      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'await' isn't a type.
hide.B<hide> _B_hide = new hide.B();
//     ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'hide' isn't a type.
of.B<of> _B_of = new of.B();
//   ^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'of' isn't a type.
on.B<on> _B_on = new on.B();
//   ^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'on' isn't a type.
show.B<show> _B_show = new show.B();
//     ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'show' isn't a type.
sync.B<sync> _B_sync = new sync.B();
//     ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'sync' isn't a type.
yield.B<yield> _B_yield = new yield.B();
//      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'yield' isn't a type.

async.B<async<dynamic>> _B2_async = new async.B();
//      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'async' isn't a type.
//      ^
// [cfe] Expected 0 type arguments.
await.B<await<dynamic>> _B2_await = new await.B();
//      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'await' isn't a type.
//      ^
// [cfe] Expected 0 type arguments.
hide.B<hide<dynamic>> _B2_hide = new hide.B();
//     ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'hide' isn't a type.
//     ^
// [cfe] Expected 0 type arguments.
of.B<of<dynamic>> _B2_of = new of.B();
//   ^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'of' isn't a type.
//   ^
// [cfe] Expected 0 type arguments.
on.B<on<dynamic>> _B2_on = new on.B();
//   ^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'on' isn't a type.
//   ^
// [cfe] Expected 0 type arguments.
show.B<show<dynamic>> _B2_show = new show.B();
//     ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'show' isn't a type.
//     ^
// [cfe] Expected 0 type arguments.
sync.B<sync<dynamic>> _B2_sync = new sync.B();
//     ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'sync' isn't a type.
//     ^
// [cfe] Expected 0 type arguments.
yield.B<yield<dynamic>> _B2_yield = new yield.B();
//      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'yield' isn't a type.
//      ^
// [cfe] Expected 0 type arguments.

main() {
  Expect.isTrue(_async is async.A);
  Expect.isTrue(_await is await.A);
  Expect.isTrue(_hide is hide.A);
  Expect.isTrue(_of is of.A);
  Expect.isTrue(_on is on.A);
  Expect.isTrue(_show is show.A);
  Expect.isTrue(_sync is sync.A);
  Expect.isTrue(_yield is yield.A);

  Expect.isTrue(_B_async is async.B);
  Expect.isTrue(_B_await is await.B);
  Expect.isTrue(_B_hide is hide.B);
  Expect.isTrue(_B_of is of.B);
  Expect.isTrue(_B_on is on.B);
  Expect.isTrue(_B_show is show.B);
  Expect.isTrue(_B_sync is sync.B);
  Expect.isTrue(_B_yield is yield.B);

  Expect.isTrue(_B2_async is async.B);
  Expect.isTrue(_B2_await is await.B);
  Expect.isTrue(_B2_hide is hide.B);
  Expect.isTrue(_B2_of is of.B);
  Expect.isTrue(_B2_on is on.B);
  Expect.isTrue(_B2_show is show.B);
  Expect.isTrue(_B2_sync is sync.B);
  Expect.isTrue(_B2_yield is yield.B);
}
