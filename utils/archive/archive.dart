// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The primary library file for the archive library. This is the only file that
 * should be imported by clients.
 */
library archive;

import 'entry.dart' as entry;
import 'reader.dart' as reader;

// TODO(nweiz): Remove this when 3071 is fixed.
/** An error raised by the archive library. */
abstract class ArchiveException {
  /** A description of the error that occurred. */
  final String message;

  /** The error code for the error, or null. */
  final int errno;
}

// TODO(nweiz): Remove this when 3071 is fixed.
/** See [reader.ArchiveReader]. */
class ArchiveReader extends reader.ArchiveReader {}

// TODO(nweiz): Remove this when 3071 is fixed.
/** See [entry.ArchiveEntry]. */
class ArchiveEntry extends entry.ArchiveEntry {
  ArchiveEntry.internal(List properties, int archiveId)
    : super.internal(properties, archiveId);

  /** Create a new [ArchiveEntry] with default values for all of its fields. */
  static Future<ArchiveEntry> create() => entry.ArchiveEntry.create();
}
