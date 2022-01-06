// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../executor.dart';

/// The only public api exposed by this library, returns a [_FakeMacroExecutor].
Future<MacroExecutor> start() async => new _FakeMacroExecutor();

/// A [MacroExecutor] implementation which throws an [UnsupportedError] in all
/// methods.
class _FakeMacroExecutor implements MacroExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw new UnsupportedError(
        'Macro expansion is not supported on this platform.');
  }
}
