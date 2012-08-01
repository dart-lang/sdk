// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("entry");

#import("dart:io");
#import("read_request.dart");
#import("utils.dart");

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

  ArchiveEntry(this._archiveId, this._properties);

  /** If this entry is a hardlink, this is the destination. Otherwise, null. */
  String get hardlink() => _properties[0];

  /** The path to this entry in the archive. */
  String get pathname() => _properties[1];

  /** The path to this entry on disk, */
  String get sourcepath() => _properties[2];

  /** If this entry is a symlink, this is the destination. Otherwise, null. */
  String get symlink() => _properties[3];

  /** The group identifier for this entry. */
  int get gid() => _properties[4];

  /** The user identifier for this entry. */
  int get uid() => _properties[5];

  /** The permissions bitmask for this entry. */
  int get perm_mask() => _properties[6];

  /** The String representation of the permissions for this entry. */
  String get strmode() => _properties[7];

  /** The name of the group this entry belongs to. */
  String get gname() => _properties[8];

  /** The name of the user this entry belongs to. */
  String get uname() => _properties[9];

  /** The file flag bits that should be set for this entry. */
  int get fflags_set() => _properties[10];

  /** The file flag bits that should be cleared for this entry. */
  int get fflags_clear() => _properties[11];

  /** The textual representation of the file flags for this entry. */
  String get fflags_text() => _properties[12];

  /** The filetype bitmask for this entry. */
  int get filetype_mask() => _properties[13];

  /** The filetype and permissions bitmask for this entry. */
  int get mode_mask() => _properties[14];

  /** The size of this entry in bytes, or null if it's unset. */
  int get size() => _properties[15];

  /** The ID of the device containing this entry, or null if it's unset. */
  int get dev() => _properties[16];

  /** The major number of the ID of the device containing this entry. */
  int get devmajor() => _properties[17];

  /** The minor number of the ID of the device containing this entry. */
  int get devminor() => _properties[18];

  /** The inode number of this entry, or null if it's unset. */
  int get ino() => _properties[19];

  /** The number of references to this entry. */
  int get nlink() => _properties[20];

  /** The device ID of this entry. */
  int get rdev() => _properties[21];

  /** The major number of the device ID of this entry. */
  int get rdevmajor() => _properties[22];

  /** The minor number of the device ID of this entry. */
  int get rdevminor() => _properties[23];

  /** The last time this entry was accessed. */
  Date get atime() => new Date.fromMillisecondsSinceEpoch(_properties[24]);

  /** The nanoseconds at the last time this entry was accessed. */
  int get atime_nsec() => _properties[25];

  /** The time this entry was created. */
  Date get birthtime() => new Date.fromMillisecondsSinceEpoch(_properties[26]);

  /** The nanoseconds at the time this entry was created. */
  int get birthtime_nsec() => _properties[27];

  /** The last time an inode property of this entry was changed. */
  Date get ctime() => new Date.fromMillisecondsSinceEpoch(_properties[28]);

  /**
   * The nanoseconds at the last time an inode property of this entry was
   * changed.
   */
  int get ctime_nsec() => _properties[29];

  /** The last time this entry was modified. */
  Date get mtime() => new Date.fromMillisecondsSinceEpoch(_properties[30]);

  /** The nanoseconds at the last time this entry was modified. */
  int get mtime_nsec() => _properties[31];

  /** Whether [openInputStream] has been called. */
  bool get isInputOpen() => _input != null;

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
      throw new UnsupportedOperationException("Archive entry $pathname is no "
          "longer being read from the archive.");
    } else if (_input != null) {
      throw new UnsupportedOperationException("An input stream has already been"
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
    return call(DATA_BLOCK, _archiveId).chain((_data) {
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
