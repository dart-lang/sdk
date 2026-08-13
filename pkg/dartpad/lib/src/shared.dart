// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library that exports types shared between `package:dartpad` and
/// `package:dartpad_worker`.
library;

export 'exceptions.dart' hide rethrowAsDartPadException;

// TODO(jonasfj): Consider a final class wouldn't be a more future proof API?
typedef CompileResult = ({
  String? code,
  List<String> compiledLibraryUris,
  String log,
});
