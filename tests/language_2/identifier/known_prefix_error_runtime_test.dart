// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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




























main() {


























}
