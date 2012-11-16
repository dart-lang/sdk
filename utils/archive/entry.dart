// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entry;

import 'dart:io';
import 'archive.dart' as archive;
import 'entry_request.dart';
import 'read_request.dart' as read;
import 'utils.dart';

/**
 * A single file in an archive.
 *
 * This is accessible via [ArchiveInputStream.onEntry].
 */
class ArchiveEntry {
  /**
   * The various properties of this archive entry, as sent over from the C
   * extension.
   */
  final List _properties;

  /**
   * The id of the archive to which this entry belongs. Used to read the entry
   * data. This will be set to null once there's no longer data available to be
   * read for this entry.
   */
  int _archiveId;

  /**
   * The input stream being used to read data from this entry. This is null
   * until [openInputStream] is called.
   */
  InputStream _input;

  // TODO(nweiz): Get rid of this once issue 4202 is fixed.
  /**
   * A future that only exists once [openInputStream] is called, and completes
   * once the input stream is closed.
   *
   * For internal use only.
   */
  Future inputComplete;

  ArchiveEntry.internal(this._properties, this._archiveId) {
    attachFinalizer(this, (id) => call(FREE, id), _id);
  }

  /** Create a new [ArchiveEntry] with default values for all of its fields. */
  static Future<ArchiveEntry> create() {
    return call(NEW).transform((properties) {
      return new archive.ArchiveEntry.internal(properties, null);
    });
  }

  /** The id of the underlying archive entry. */
  int get _id => _properties[0];

  /** If this entry is a hardlink, this is the destination. Otherwise, null. */
  String get hardlink => _properties[1];
  set hardlink(String value) => _set(SET_HARDLINK, 1, value);

  /** The path to this entry in the archive. */
  String get pathname => _properties[2];
  set pathname(String value) => _set(SET_PATHNAME, 2, value);

  /** The path to this entry on disk, */
  String get sourcepath => _properties[3];

  /** If this entry is a symlink, this is the destination. Otherwise, null. */
  String get symlink => _properties[4];
  set symlink(String value) => _set(SET_SYMLINK, 4, value);

  /** The group identifier for this entry. */
  int get gid => _properties[5];
  set gid(int value) => _set(SET_GID, 5, value);

  /** The user identifier for this entry. */
  int get uid => _properties[6];
  set uid(int value) => _set(SET_UID, 6, value);

  /** The permissions bitmask for this entry. */
  int get perm_mask => _properties[7];
  set perm_mask(int value) => _set(SET_PERM, 7, value);

  /**
   * The String representation of the permissions for this entry.
   *
   * Note that if you set [perm_mask], this value will not change.
   */
  String get strmode => _properties[8];

  /** The name of the group this entry belongs to. */
  String get gname => _properties[9];
  set gname(String value) => _set(SET_GNAME, 9, value);

  /** The name of the user this entry belongs to. */
  String get uname => _properties[10];
  set uname(String value) => _set(SET_UNAME, 10, value);

  /**
   * The file flag bits that should be set for this entry.
   *
   * Note that if you set [fflags_text], this value will not change, and vice
   * versa.
   */
  int get fflags_set => _properties[11];
  set fflags_set(int value) => _set(SET_FFLAGS_SET, 11, value);

  /**
   * The file flag bits that should be cleared for this entry.
   *
   * Note that if you set [fflags_text], this value will not change, and vice
   * versa.
   */
  int get fflags_clear => _properties[12];
  set fflags_clear(int value) => _set(SET_FFLAGS_CLEAR, 12, value);

  /**
   * The textual representation of the file flags for this entry.
   *
   * Note that if you set [fflags_set] or [fflags_clear], this value will not
   * change, and vice versa.
   */
  String get fflags_text => _properties[13];

  /** The filetype bitmask for this entry. */
  int get filetype_mask => _properties[14];
  set filetype_mask(int value) => _set(SET_FILETYPE, 14, value);

  /** The filetype and permissions bitmask for this entry. */
  int get mode_mask => _properties[15];
  set mode_mask(int value) => _set(SET_MODE, 15, value);

  /** The size of this entry in bytes, or null if it's unset. */
  int get size => _properties[16];
  set size(int value) => _set(SET_SIZE, 16, value);

  /** The ID of the device containing this entry, or null if it's unset. */
  int get dev => _properties[17];
  set dev(int value) => _set(SET_DEV, 17, value);

  /** The major number of the ID of the device containing this entry. */
  int get devmajor => _properties[18];
  set devmajor(int value) => _set(SET_DEVMAJOR, 18, value);

  /** The minor number of the ID of the device containing this entry. */
  int get devminor => _properties[19];
  set devminor(int value) => _set(SET_DEVMINOR, 19, value);

  /** The inode number of this entry, or null if it's unset. */
  int get ino => _properties[20];
  set ino(int value) => _set(SET_INO, 20, value);

  /** The number of references to this entry. */
  int get nlink => _properties[21];
  set nlink(int value) => _set(SET_NLINK, 21, value);

  /** The device ID of this entry. */
  int get rdev => _properties[22];
  set rdev(int value) => _set(SET_RDEV, 22, value);

  /** The major number of the device ID of this entry. */
  int get rdevmajor => _properties[23];
  set rdevmajor(int value) => _set(SET_RDEVMAJOR, 23, value);

  /** The minor number of the device ID of this entry. */
  int get rdevminor => _properties[24];
  set rdevminor(int value) => _set(SET_RDEVMINOR, 24, value);

  /** The last time this entry was accessed, or null if it's unset. */
  Date get atime => _fromMs(_properties[25]);
  set atime(Date value) => _set(SET_ATIME, 25, _toMs(value));

  /** The time this entry was created, or null if it's unset. */
  Date get birthtime => _fromMs(_properties[26]);
  set birthtime(Date value) => _set(SET_BIRTHTIME, 26, _toMs(value));

  /**
   * The last time an inode property of this entry was changed, or null if it's
   * unset.
   */
  Date get ctime => _fromMs(_properties[27]);
  set ctime(Date value) => _set(SET_CTIME, 27, _toMs(value));

  /** The last time this entry was modified, or null if it's unset. */
  Date get mtime => _fromMs(_properties[28]);
  set mtime(Date value) => _set(SET_MTIME, 28, _toMs(value));

  /** Whether [openInputStream] has been called. */
  bool get isInputOpen => _input != null;

  /** Create a deep copy of this [ArchiveEntry]. */
  Future<ArchiveEntry> clone() {
    return call(CLONE, _id).
      transform((array) => new archive.ArchiveEntry.internal(array, null));
  }

  /**
   * Consumes the entire contents of this entry at once and returns it wrapped
   * in a [CompleteArchiveEntry]. All metadata fields in the returned entry are
   * copies of the fields in this entry.
   *
   * This may not be called if [openInputStream] is called, and vice versa.
   */
  Future<CompleteArchiveEntry> readAll() {
    var stream = openInputStream();
    var buffer = <int>[];
    var completer = new Completer<List<int>>();

    stream.onData = () => buffer.addAll(stream.read());
    stream.onError = completer.completeException;
    stream.onClosed = () => completer.complete(buffer);

    return Futures.wait([call(CLONE, _id), completer.future])
      .transform((list) => new CompleteArchiveEntry._(list[0], list[1]));
  }

  /**
   * Set a property value with index [value] on the local representation of the
   * archive entry and on the native representation.
   */
  void _set(int requestType, int index, value) {
    _properties[index] = value;
    // Since the native code processes messages in order, the SET_* messages
    // will be received and processed before any further messages.
    call(requestType, _id, [value]).then((_) {});
  }

  /**
   * Converts [ms], the (possibly null) number of milliseconds since the epoch
   * into a Date object (which may also be null).
   */
  Date _fromMs(int ms) {
    if (ms == null) return null;
    return new Date.fromMillisecondsSinceEpoch(ms);
  }

  /**
   * Converts [date], which may be null, into the number of milliseconds since
   * the epoch (which may also be null).
   */
  int _toMs(Date date) {
    if (date == null) return null;
    return date.millisecondsSinceEpoch;
  }

  /**
   * Creates a new input stream for reading the contents of this entry.
   *
   * The contents of an entry must be consumed before the next entry is read
   * from the parent [ArchiveInputStream]. This means that [openInputStream]
   * must be called from the [ArchiveInputStream.onEntry] callback, or before
   * the future returned by that callback completes. Once the next entry has
   * been read, calling [openInputStream] will throw an [ArchiveException].
   *
   * Only one input stream may be opened per entry.
   */
  InputStream openInputStream() {
    if (_archiveId == null) {
      throw new UnsupportedError("Cannot open input stream for "
          "archive entry $pathname.");
    } else if (_input != null) {
      throw new UnsupportedError("An input stream has already been"
          "opened for archive entry $pathname.");
    }

    var inputCompleter = new Completer();
    inputComplete = inputCompleter.future;

    _input = new ListInputStream();
    // TODO(nweiz): Report errors once issue 3657 is fixed
    var future = _consumeInput().chain((_) {
      if (!_input.closed) _input.markEndOfStream();
      // Asynchronously complete to give the InputStream callbacks a chance to
      // fire.
      return async();
    }).transform((_) => inputCompleter.complete(null));

    future.handleException((e) {
      print(e);
      print(future.stackTrace);
    });
    return _input;
  }

  /**
   * Close this entry so that its input stream no longer produces data.
   *
   * In addition to closing the associated input stream, this will prevent new
   * input streams from being opened.
   */
  void close() {
    _archiveId = null;
    if (_input != null) _input.close();
  }

  /**
   * Read all data from the archive and write it to [_input]. Returns a future
   * that completes once this is done.
   *
   * This assumes that both [_input] and [_archiveId] are non-null and that
   * [_input] is open, although if that changes before this completes it will
   * handle it gracefully.
   */
  Future _consumeInput() {
    var data;
    return call(read.DATA_BLOCK, _archiveId).chain((_data) {
      data = _data;
      // TODO(nweiz): This async() call is only necessary because of issue 4222.
      return async();
    }).chain((_) {
      if (_input.closed || _archiveId == null || data == null) {
        return new Future.immediate(null);
      }
      _input.write(data);
      return _consumeInput();
    });
  }
}

/**
 * An [ArchiveEntry] that contains the complete decompressed contents of the
 * file.
 */
class CompleteArchiveEntry extends ArchiveEntry {
  /** The contents of the entry as bytes. */
  final List<int> contentBytes;

  /** The contents of the entry as a string. */
  String get contents => new String.fromCharCodes(contentBytes);

  CompleteArchiveEntry._(List properties, this.contentBytes)
    : super.internal(properties, null);
}
