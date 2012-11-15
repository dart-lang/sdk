// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_FDUTILS_H_
#define BIN_FDUTILS_H_

#include "bin/builtin.h"
#include "platform/globals.h"

class FDUtils {
 public:
  static bool SetCloseOnExec(intptr_t fd);

  static bool SetNonBlocking(intptr_t fd);
  static bool SetBlocking(intptr_t fd);

  // Checks whether the file descriptor is blocking. If the function
  // returns true the value pointed to by is_blocking will be set to
  // the blocking state of the file descriptor. If the function
  // returns false the system call for checking the file descriptor
  // failed and the value pointed to by is_blocking is not modified.
  static bool IsBlocking(intptr_t fd, bool* is_blocking);

  static intptr_t AvailableBytes(intptr_t fd);

  // Reads the requested number of bytes from a file descriptor. This
  // function will only return on short reads if an error occours in
  // which case it returns -1 and errno is still valid. The file
  // descriptor must be in blocking mode.
  static ssize_t ReadFromBlocking(int fd, void* buffer, size_t count);

  // Writes the requested number of bytes to a file descriptor. This
  // function will only return on short writes if an error occours in
  // which case it returns -1 and errno is still valid. The file
  // descriptor must be in blocking mode.
  static ssize_t WriteToBlocking(int fd, const void* buffer, size_t count);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(FDUtils);
};

#endif  // BIN_FDUTILS_H_
