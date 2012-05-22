// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DIRECTORY_H_
#define BIN_DIRECTORY_H_

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "platform/globals.h"
#include "platform/thread.h"

class DirectoryListing {
 public:
  enum Response {
    kListDirectory = 0,
    kListFile = 1,
    kListError = 2,
    kListDone = 3
  };

  explicit DirectoryListing(Dart_Port response_port)
      : response_port_(response_port) {}
  bool HandleDirectory(char* dir_name);
  bool HandleFile(char* file_name);
  bool HandleError(const char* dir_name);

 private:
  CObjectArray* NewResponse(Response response, char* arg);
  Dart_Port response_port_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(DirectoryListing);
};


class Directory {
 public:
  enum ExistsResult {
    UNKNOWN,
    EXISTS,
    DOES_NOT_EXIST
  };

  // This enum must be kept in sync with the request values in
  // directory_impl.dart.
  enum DirectoryRequest {
    kCreateRequest = 0,
    kDeleteRequest = 1,
    kExistsRequest = 2,
    kCreateTempRequest = 3,
    kListRequest = 4,
    kRenameRequest = 5
  };

  static bool List(const char* path,
                   bool recursive,
                   DirectoryListing* listing);
  static ExistsResult Exists(const char* path);
  static char* Current();
  static bool Create(const char* path);
  static char* CreateTemp(const char* const_template);
  static bool Delete(const char* path, bool recursive);
  static bool Rename(const char* path, const char* new_path);
  static Dart_Port GetServicePort();

 private:
  static dart::Mutex mutex_;
  static int service_ports_size_;
  static Dart_Port* service_ports_;
  static int service_ports_index_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Directory);
};


#endif  // BIN_DIRECTORY_H_
