// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library input_stream;

import 'archive.dart' as archive;
import 'entry.dart';
import 'read_request.dart';
import 'utils.dart';

/**
 * A stream of [ArchiveEntry]s being read from an archive.
 *
 * This is accessible via [ArchiveReader].
 */
class ArchiveInputStream {
  /**
   * The id of the underlying archive.
   *
   * This will be set to null once the input stream has finished reading from
   * the archive.
   */
  final Reference<int> _id;

  /** A [Completer] that will fire once the [_onEntry] callback is set. */
  final Completer<Function> _onEntryCompleter;

  /** The callback to call when the input stream is closed. */
  Function _onClosed;

  /** The callback to call when an error occurs. */
  Function _onError;

  /** The entry that is currently eligible to read data from the archive. */
  ArchiveEntry _currentEntry;

  ArchiveInputStream(int id)
    : _id = new Reference<int>(id),
      _onEntryCompleter = new Completer<Function>() {
    var future = _consumeHeaders();
    future.handleException((e) {
      if (_onError != null) {
        _onError(e, future.stackTrace);
        return true;
      } else {
        throw e;
      }
    });

    future.then((_) {
      close();
      if (_onClosed != null) _onClosed();
    });

    attachFinalizer(this, (id) {
      if (id.value != null) call(FREE, id.value).then(() {});
    }, _id);
  }

  /** Whether this stream has finished reading entries. */
  bool get closed => _id.value == null;

  /**
   * Reads the entire contents of the archive at once.
   *
   * Note that this is mutually exclusive with reading individual entries using
   * [onEntry].
   */
  Future<List<CompleteArchiveEntry>> readAll() {
    var completer = new Completer<List<Future<CompleteArchiveEntry>>>();
    var result = <Future<CompleteArchiveEntry>>[];

    this.onEntry = (entry) => result.add(entry.readAll());
    this.onError = (e, stack) => completer.completeException(e, stack);
    this.onClosed = () => completer.complete(result);

    return completer.future.chain(Futures.wait);
  }

  /**
   * Sets a callback to call when a new entry is read from the archive.
   *
   * The [ArchiveEntry] that's read from an archive initially only contains
   * header information such as the filename and permissions. To get the actual
   * data contained in the entry, use [ArchiveEntry.openInputStream].
   *
   * Since the entries are read in sequence from the archive, the data stream
   * for one entry must be opened before the next entry is read from the
   * archive. The next entry will not be read until the return value of
   * [callback] has completed.
   *
   * If [callback] calls [ArchiveEntry.openInputStream] before it returns, or if
   * it doesn't want to read the contents of [entry], it can return null.
   */
  void set onEntry(Future callback(ArchiveEntry entry)) {
    _onEntryCompleter.complete(callback);
  }

  /**
   * Sets a callback to call when the input stream is done emitting entries.
   */
  void set onClosed(void callback()) {
    _onClosed = callback;
  }

  /**
   * Sets a callback to call if an error occurs while extracting the archive.
   *
   * [e] is the error that occured and [stack] is the stack trace of the error.
   */
  void set onError(void callback(e, stack)) {
    _onError = callback;
  }

  /**
   * Closes the input stream. No more entries will be emitted.
   */
  void close() {
    if (closed) return;
    call(FREE, _id.value).then((_) {});
    _id.value = null;
    if (_currentEntry != null) _currentEntry.close();
    if (!_onEntryCompleter.future.isComplete) _onEntryCompleter.complete(null);
  }

  /**
   * Consumes and emits all [ArchiveEntries] in this archive.
   */
  Future _consumeHeaders() {
    if (closed) return new Future.immediate(null);
    var data;
    return call(NEXT_HEADER, _id.value).chain((_data) {
      data = _data;
      if (data == null) return new Future.immediate(null);
      return _emit(new archive.ArchiveEntry.internal(data, _id.value)).
        chain((_) => _consumeHeaders());
    });
  }

  /**
   * Emits [entry] to the [onEntry] callback. Returns a [Future] that will
   * complete once the callback's return value completes and the entry's data
   * has been fully consumed.
   */
  Future _emit(ArchiveEntry entry) {
    _currentEntry = entry;
    var future = _onEntryCompleter.future.chain((onEntry) {
      if (closed) return new Future.immediate(null);
      var result = onEntry(entry);
      if (result is Future) return result;
      return new Future.immediate(null);
    }).chain((_) {
      if (entry.isInputOpen) return entry.inputComplete;
      return new Future.immediate(null);
    });
    future.onComplete((_) {
      _currentEntry = null;
      entry.close();
    });
    return future;
  }
}
