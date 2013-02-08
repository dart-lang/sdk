// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef void _CollectionSinkCallback<T>(Collection<T> collection);
typedef void _CollectionSinkErrorCallback(AsyncError error);

/** StreamSink that stores incoming data in a collection. */
class CollectionSink<T> implements StreamSink<T> {
  final Collection<T> collection;
  final _CollectionSinkCallback<T> _callback;
  final _CollectionSinkErrorCallback _errorCallback;
  bool _isClosed = false;

  /**
   * Create a sink that stores incoming values in a collection.
   *
   * The [collection] is the collection to add the values to.
   *
   * If [callback] is provided, then it's called with the collection as arugment
   * when the sink's [close] method is called.
   */
  CollectionSink(this.collection,
                { void onClose(Collection<T> collection),
                  void onError(AsyncError error) })
      : this._callback = onClose,
        this._errorCallback = onError;

  add(T value) {
    if (_isClosed) throw new StateError("Adding to closed sink");
    collection.add(value);
  }

  void signalError(AsyncError error) {
    if (_isClosed) throw new StateError("Singalling error on closed sink");
    if (_errorCallback != null) _errorCallback(error);
  }

  void close() {
    if (_isClosed) throw new StateError("Closing closed sink");
    _isClosed = true;
    if (_callback != null) _callback(collection);
  }
}
