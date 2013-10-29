// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for asynchronous programming,
 * with classes such as Future and Stream.
 *
 * For an introduction to asynchronous programming in Dart, see the
 * [dart:async section of the language tour]
 * (https://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html#ch03-asynchronous-programming).
 *
 * ## Other resources
 *
 * * [Using Future Based APIs]
 * (https://www.dartlang.org/articles/using-future-based-apis/): A first look at
 * Futures and how to use them to write asynchronous Dart code.
 *
 * * [Futures and Error Handling]
 * (https://www.dartlang.org/articles/futures-and-error-handling/): Everything
 * you wanted to know about handling errors and exceptions when working with
 * Futures (but were afraid to ask).
 *
 * * [The Event Loop and Dart](https://www.dartlang.org/articles/event-loop/):
 * Learn how Dart handles the event queue and microtask queue, so you can write
 * better asynchronous code with fewer surprises.
 *
 * * [Asynchronous Unit Testing with Dart]
 * (https://www.dartlang.org/articles/dart-unit-tests/#asynchronous-tests): How
 * to test asynchronous code.
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
