// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for asynchronous programming,
 * with classes such as Future and Stream.
 *
 * Understanding [Future]s and [Stream]s is a prerequisite for
 * writing just about any Dart program.
 *
 * To use this library in your code:
 *
 *     import 'dart:async';
 *
 * ## Future
 *
 * A Future object represents a computation whose return value
 * might not yet be available.
 * The Future returns the value of the computation
 * when it completes at some time in the future.
 * Futures are often used for potentially lengthy computations
 * such as I/O and interaction with users.
 *
 * Many methods in the Dart libraries return Futures when
 * performing tasks. For example, when binding an HttpServer
 * to a host and port, the `bind()` method returns a Future.
 *
 *      HttpServer.bind('127.0.0.1', 4444)
 *          .then((server) => print('${server.isBroadcast}'))
 *          .catchError(print);
 *
 * [Future.then] registers a callback function that runs
 * when the Future's operation, in this case the `bind()` method,
 * completes successfully.
 * The value returned by the operation
 * is passed into the callback function.
 * In this example, the `bind()` method returns the HttpServer
 * object. The callback function prints one of its properties.
 * [Future.catchError] registers a callback function that
 * runs if an error occurs within the Future.
 *
 * ## Stream
 *
 * A Stream provides an asynchronous sequence of data.
 * Examples of data sequences include individual events, like mouse clicks,
 * or sequential chunks of larger data, like multiple byte lists with the
 * contents of a file
 * such as mouse clicks, and a stream of byte lists read from a file.
 * The following example opens a file for reading.
 * [Stream.listen] registers a callback function that runs
 * each time more data is available.
 *
 *     Stream<List<int>> stream = new File('quotes.txt').openRead();
 *     stream.transform(UTF8.decoder).listen(print);
 *
 * The stream emits a sequence of a list of bytes.
 * The program must interpret the bytes or handle the raw byte data.
 * Here, the code uses a UTF8 decoder (provided in the `dart:convert` library)
 * to convert the sequence of bytes into a sequence
 * of Dart strings.
 *
 * Another common use of streams is for user-generated events
 * in a web app: The following code listens for mouse clicks on a button.
 *
 *     querySelector('#myButton').onClick.listen((_) => print('Click.'));
 *
 * ## Other resources
 *
 * * The [dart:async section of the library tour][asynchronous-programming]:
 *   A brief overview of asynchronous programming.
 *
 * * [Use Future-Based APIs][futures-tutorial]: A closer look at Futures and
 *   how to use them to write asynchronous Dart code.
 *
 * * [Futures and Error Handling][futures-error-handling]: Everything you
 *   wanted to know about handling errors and exceptions when working with
 *   Futures (but were afraid to ask).
 *
 * * [The Event Loop and Dart](https://www.dartlang.org/articles/event-loop/):
 *   Learn how Dart handles the event queue and microtask queue, so you can
 *   write better asynchronous code with fewer surprises.
 *
 * * [test package: Asynchronous Tests][test-readme]: How to test asynchronous
 *   code.
 *
 * [asynchronous-programming]: https://www.dartlang.org/docs/dart-up-and-running/ch03.html#dartasync---asynchronous-programming
 * [futures-tutorial]: https://www.dartlang.org/docs/tutorials/futures/
 * [futures-error-handling]: https://www.dartlang.org/articles/futures-and-error-handling/
 * [test-readme]: https://pub.dartlang.org/packages/test
 */
library dart.async;

import "dart:collection" show HashMap, IterableBase;
import "dart:_internal" show printToZone, printToConsole, IterableElementError;

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
