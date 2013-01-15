// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;
/**
 * An interface for an object that can receive a sequence of values.
 */
abstract class Sink<T> {
  /** Write a value to the sink. */
  add(T value);
  /** Tell the sink that no further values will be written. */
  void close();
}

// ----------------------------------------------------------------------
// Collections/Sink interoperability
// ----------------------------------------------------------------------

typedef void _CollectionSinkCallback<T>(Collection<T> collection);

/** Sink that stores incoming data in a collection. */
class CollectionSink<T> implements Sink<T> {
  final Collection<T> collection;
  final _CollectionSinkCallback<T> callback;
  bool _isClosed = false;

  /**
   * Create a sink that stores incoming values in a collection.
   *
   * The [collection] is the collection to add the values to.
   *
   * If [callback] is provided, then it's called with the collection as arugment
   * when the sink's [close] method is called.
   */
  CollectionSink(this.collection, [void callback(Collection<T> collection)])
      : this.callback = callback;

  add(T value) {
    if (_isClosed) throw new StateError("Adding to closed sink");
    collection.add(value);
  }

  void close() {
    if (_isClosed) throw new StateError("Closing closed sink");
    _isClosed = true;
    if (callback != null) callback(collection);
  }
}
