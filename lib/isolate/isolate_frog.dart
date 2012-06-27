// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Dart isolate's API and implementation for frog. Since dartdocs are generated
// using frog, we include here some additional library level comments.

/**
 * The `dart:isolate` library defines APIs to spawn and communicate with
 * isolates.
 *
 * All code in dart runs in the context of an isolate. Each isolate has its own
 * heap, which means that all values in memory, including globals, are available
 * only to that isolate. The only mechanism available to communicate between
 * isolates is to pass messages. Messages are sent through ports. This library
 * defines [ReceivePort] to represent the receiver's end of a communication
 * channel, and [SendPort] to represent the sender's end.
 *
 * All isolates start with an initial receive port, which is set in the
 * top-level property [port]. This port is used to establish the first
 * communication between isolates.
 *
 * Two APIs are available to spawn a new isolate: [spawnFunction] and
 * [spawnUri]. [spawnFunction] creates a new isolate that is using the same
 * source code as the current isolate, [spawnUri] allows spawning an isolate
 * that was written independently.
 *
 * There is currently no way to indicate in the API whether the isolates should
 * run on the same or different threads. The underlying system will schedule the
 * isolate were appropriate. In the near future we will add an API to create DOM
 * isolates. These are isolates that share access to the DOM. All DOM isolates
 * will run on the UI thread.
 *
 * This library is still evolving. New APIs are being added, and some will be
 * deprecated and removed. In particular, the class [Isolate] will be
 * deprecated as soon the dartvm has an implementation working for
 * [spawnFunction] and [spawnUri], and we have an API to spawn DOM isolates.
 */
#library("dart:isolate");

#import("../uri/uri.dart");
#source("isolate_api.dart");
#source("frog/compiler_hooks.dart");
#source("frog/isolateimpl.dart");
#source("frog/ports.dart");
#source("frog/messages.dart");
#source("timer.dart");
#source("timer_hook.dart");
#native("frog/natives.js");
