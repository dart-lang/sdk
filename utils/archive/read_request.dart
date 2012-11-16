// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The request ids for read-related messages to send to the C extension. */
library read_request;

final int NEW = 0;
final int SUPPORT_FILTER_ALL = 1;
final int SUPPORT_FILTER_BZIP2 = 2;
final int SUPPORT_FILTER_COMPRESS = 3;
final int SUPPORT_FILTER_GZIP = 4;
final int SUPPORT_FILTER_LZMA = 5;
final int SUPPORT_FILTER_XZ = 6;
final int SUPPORT_FILTER_PROGRAM = 7;
final int SUPPORT_FILTER_PROGRAM_SIGNATURE = 8;
final int SUPPORT_FORMAT_ALL = 9;
final int SUPPORT_FORMAT_AR = 10;
final int SUPPORT_FORMAT_CPIO = 11;
final int SUPPORT_FORMAT_EMPTY = 12;
final int SUPPORT_FORMAT_ISO9660 = 13;
final int SUPPORT_FORMAT_MTREE = 14;
final int SUPPORT_FORMAT_RAW = 15;
final int SUPPORT_FORMAT_TAR = 16;
final int SUPPORT_FORMAT_ZIP = 17;
final int SET_FILTER_OPTION = 18;
final int SET_FORMAT_OPTION = 19;
final int SET_OPTION = 20;
final int OPEN_FILENAME = 21;
final int OPEN_MEMORY = 22;
final int NEXT_HEADER = 23;
final int DATA_BLOCK = 24;
final int DATA_SKIP = 25;
final int CLOSE = 26;
final int FREE = 27;

final int LAST = FREE;
