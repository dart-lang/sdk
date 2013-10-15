// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for asynchronous programming,
 * with classes such as Future and Stream.
 *
 * For an introduction to using dart:async, see the
 * [dart:async section of the language tour]
 * (https://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html#ch03-asynchronous-programming).
 * Also see
 * [articles](https://www.dartlang.org/articles/)
 * such as
 * [Using Future Based APIs]
 * (https://www.dartlang.org/articles/using-future-based-apis/).
 */
library dart.async;

import "dart:collection";
import "dart:_collection-dev" show deprecated, printToZone, printToConsole;

part 'async_error.dart';
part 'broadcast_stream_controller.dart';
part 'deferred_load.dart';
part 'future.dart';
part 'future_impl.dart';
part 'schedule_microtask.dart';
part 'stream.dart';
part 'stream_controller.dart';
part 'stream_impl.dart';
part 'stream_pipe.dart';
part 'stream_transformers.dart';
part 'timer.dart';
part 'zone.dart';
