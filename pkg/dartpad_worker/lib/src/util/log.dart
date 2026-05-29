// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'log_js.dart' if (dart.library.io) 'log_io.dart';

/// Log [message] to `console.error` / stderr, prefixed with 'worker.dart:'
void logError(String message) => logErrorImpl(message);
