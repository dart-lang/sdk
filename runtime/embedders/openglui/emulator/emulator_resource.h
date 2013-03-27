// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_EMULATOR_EMULATOR_RESOURCE_H_
#define EMBEDDERS_OPENGLUI_EMULATOR_EMULATOR_RESOURCE_H_

#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "embedders/openglui/common/log.h"
#include "embedders/openglui/common/resource.h"

class EmulatorResource : public Resource {
  public:
    explicit EmulatorResource(const char* path)
      : Resource(path),
        fd_(-1) {
    }

    int32_t descriptor() {
      if (fd_ < 0) {
        Open();
      }
      return fd_;
    }

    off_t length() {
      if (length_ < 0) {
        length_ = lseek(fd_, 0, SEEK_END);
        lseek(fd_, 0, SEEK_SET);
      }
      return length_;
    }

    int32_t Open() {
      fd_ = open(path_, 0);
      if (fd_ >= 0) {
        return 0;
      }
      LOGE("Could not open asset %s", path_);
      return -1;
    }

    void Close() {
      if (fd_ >= 0) {
        close(fd_);
        fd_ = -1;
      }
    }

    int32_t Read(void* buffer, size_t count) {
      size_t actual = read(fd_, buffer, count);
      return (actual == count) ? 0 : -1;
    }

  private:
    int fd_;
};

#endif  // EMBEDDERS_OPENGLUI_EMULATOR_EMULATOR_RESOURCE_H_

