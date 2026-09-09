// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for Debug Adapter Protocol (DAP) adapters.
library;

export 'package:dap/dap.dart';

export 'src/adapters/dart.dart';
export 'src/adapters/dds_hosted_adapter.dart';
export 'src/adapters/mixins.dart';
export 'src/constants.dart';
export 'src/logging.dart';
export 'src/progress_reporter.dart';
export 'src/protocol_stream.dart';
export 'src/server.dart' show DapServer;
export 'src/stream_transformers.dart';
