// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// This list must be kept in sync with the list in runtime/bin/io_service.h
const int _FILE_EXISTS = 0;
const int _FILE_CREATE = 1;
const int _FILE_DELETE = 2;
const int _FILE_RENAME = 3;
const int _FILE_COPY = 4;
const int _FILE_OPEN = 5;
const int _FILE_RESOLVE_SYMBOLIC_LINKS = 6;
const int _FILE_CLOSE = 7;
const int _FILE_POSITION = 8;
const int _FILE_SET_POSITION = 9;
const int _FILE_TRUNCATE = 10;
const int _FILE_LENGTH = 11;
const int _FILE_LENGTH_FROM_PATH = 12;
const int _FILE_LAST_MODIFIED = 13;
const int _FILE_FLUSH = 14;
const int _FILE_READ_BYTE = 15;
const int _FILE_WRITE_BYTE = 16;
const int _FILE_READ = 17;
const int _FILE_READ_INTO = 18;
const int _FILE_WRITE_FROM = 19;
const int _FILE_CREATE_LINK = 20;
const int _FILE_DELETE_LINK = 21;
const int _FILE_RENAME_LINK = 22;
const int _FILE_LINK_TARGET = 23;
const int _FILE_TYPE = 24;
const int _FILE_IDENTICAL = 25;
const int _FILE_STAT = 26;
const int _SOCKET_LOOKUP = 27;
const int _SOCKET_LIST_INTERFACES = 28;
const int _SOCKET_REVERSE_LOOKUP = 29;
const int _DIRECTORY_CREATE = 30;
const int _DIRECTORY_DELETE = 31;
const int _DIRECTORY_EXISTS = 32;
const int _DIRECTORY_CREATE_TEMP = 33;
const int _DIRECTORY_LIST_START = 34;
const int _DIRECTORY_LIST_NEXT = 35;
const int _DIRECTORY_LIST_STOP = 36;
const int _DIRECTORY_RENAME = 37;
const int _SSL_PROCESS_FILTER = 38;

class _IOService {
  external static Future dispatch(int request, List data);
}
