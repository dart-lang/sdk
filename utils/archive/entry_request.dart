// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The request ids for entry-related messages to send to the C extension. */
library entry_request;

import 'read_request.dart' as read;

final int _first = read.LAST;

final int CLONE = _first + 1;
final int FREE = _first + 2;
final int NEW = _first + 3;
final int SET_HARDLINK = _first + 4;
final int SET_PATHNAME = _first + 5;
final int SET_SYMLINK = _first + 6;
final int SET_GID = _first + 7;
final int SET_UID = _first + 8;
final int SET_PERM_MASK = _first + 9;
final int SET_GNAME = _first + 10;
final int SET_UNAME = _first + 11;
final int SET_FFLAGS_SET = _first + 12;
final int SET_FFLAGS_CLEAR = _first + 13;
final int SET_FILETYPE_MASK = _first + 14;
final int SET_MODE_MASK = _first + 15;
final int SET_SIZE = _first + 16;
final int SET_DEV = _first + 17;
final int SET_DEVMAJOR = _first + 18;
final int SET_DEVMINOR = _first + 19;
final int SET_INO = _first + 20;
final int SET_NLINK = _first + 21;
final int SET_RDEV = _first + 22;
final int SET_RDEVMAJOR = _first + 23;
final int SET_RDEVMINOR = _first + 24;
final int SET_ATIME = _first + 25;
final int SET_BIRTHTIME = _first + 26;
final int SET_CTIME = _first + 27;
final int SET_MTIME = _first + 28;

final int LAST = SET_MTIME;
