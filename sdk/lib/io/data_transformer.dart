// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Private helper-class to handle native filters.
 */
abstract class _Filter {
  /**
   * Call to process a chunk of data. A call to [process] should only be made
   * when [processed] returns [null].
   */
  void process(List<int> data);

  /**
   * Get a chunk of processed data. When there are no more data available,
   * [processed] will return [null]. Set [flush] to [false] for non-final
   * calls to improve performance of some filters.
   */
  List<int> processed({bool flush: true});

  /**
   * Mark the filter as closed. Always call this method for any filter created
   * to avoid leaking resources. [end] can be called at any time, but any
   * successive calls to [process] or [processed] will fail.
   */
  void end();

  external static _Filter newZLibDeflateFilter(bool gzip, int level);
  external static _Filter newZLibInflateFilter();
}


class _FilterTransformer extends StreamEventTransformer<List<int>, List<int>> {
  final _Filter _filter;
  bool _closed = false;
  bool _empty = true;

  _FilterTransformer(_Filter this._filter);

  void handleData(List<int> data, EventSink<List<int>> sink) {
    if (_closed) return;
    try {
      _empty = false;
      _filter.process(data);
      var out;
      while ((out = _filter.processed(flush: false)) != null) {
        sink.add(out);
      }
    } catch (e, s) {
      _closed = true;
      // TODO(floitsch): we are losing the stack trace.
      sink.addError(e);
      sink.close();
    }
  }

  void handleDone(EventSink<List<int>> sink) {
    if (_closed) return;
    if (_empty) _filter.process(const []);
    try {
      var out;
      while ((out = _filter.processed()) != null) {
        sink.add(out);
      }
    } catch (e, s) {
      // TODO(floitsch): we are losing the stack trace.
      sink.addError(e);
      _closed = true;
    }
    if (!_closed) _filter.end();
    _closed = true;
    sink.close();
  }
}


/**
 * ZLibDeflater class used to deflate a stream of bytes, using zlib.
 */
class ZLibDeflater extends _FilterTransformer {
  ZLibDeflater({bool gzip: true, int level: 6})
      : super(_Filter.newZLibDeflateFilter(gzip, level));
}


/**
 * ZLibInflater class used to inflate a stream of bytes, using zlib.
 */
class ZLibInflater extends _FilterTransformer {
  ZLibInflater() : super(_Filter.newZLibInflateFilter());
}

