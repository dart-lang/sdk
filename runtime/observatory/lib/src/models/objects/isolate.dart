// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class IsolateRef {
  /// The id which is passed to the getIsolate RPC to reload this
  /// isolate.
  String get id;

  /// A numeric id for this isolate, represented as a string. Unique.
  int get number;

  /// A name identifying this isolate. Not guaranteed to be unique.
  String get name;
}

abstract class Isolate extends IsolateRef {
  /// The time that the VM started in milliseconds since the epoch.
  DateTime get startTime;

  /// Is the isolate in a runnable state?
  bool get runnable;

  /// The number of live ports for this isolate.
  //int get livePorts;

  /// Will this isolate pause when exiting?
  //bool get pauseOnExit;

  /// The last pause event delivered to the isolate. If the isolate is
  /// running, this will be a resume event.
  //Event get pauseEvent;

  /// [optional] The root library for this isolate.
  ///
  /// Guaranteed to be initialized when the IsolateRunnable event fires.
  //LibraryRef get rootLib;

  /// A list of all libraries for this isolate.
  ///
  /// Guaranteed to be initialized when the IsolateRunnable event fires.
  Iterable<LibraryRef> get libraries;

  /// A list of all breakpoints for this isolate.
  //Iterable<Breakpoint> get breakpoints;

  /// [optional] The error that is causing this isolate to exit, if applicable.
  Error get error;

  /// The current pause on exception mode for this isolate.
  //ExceptionPauseMode get exceptionPauseMode;

  /// [optional]The list of service extension RPCs that are registered for this
  /// isolate, if any.
  Iterable<String> get extensionRPCs;

  Map get counters;
  HeapSpace get newSpace;
  HeapSpace get oldSpace;
}
