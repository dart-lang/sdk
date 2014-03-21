// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A generic destination for data.
 *
 * Multiple data values can be put into a sink, and when no more data is
 * available, the sink should be closed.
 *
 * This is a generic interface that other data receivers can implement.
 */
abstract class Sink<T> {
  /**
   * Put the data into the sink.
   *
   * Must not be called after a call to [close].
   */
  void add(T data);

  /**
   * Tell the sink that no further data will be added.
   *
   * Calling this method more than once is allowed, but does nothing.
   *
   * The [add] method must not be called after this method.
   */
  void close();
}
