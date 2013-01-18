// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_SAMPLE_H_
#define EMBEDDERS_OPENGLUI_COMMON_SAMPLE_H_

#include "embedders/openglui/common/resource.h"

class Sample {
  public:
    explicit Sample(const char* path)
        : resource_(path),
          buffer_(NULL),
          length_(0) {
    }

    ~Sample() {
      Unload();
    }

    const char* path() {
      return resource_.path();
    }

    uint8_t* buffer() {
      return buffer_;
    }

    off_t length() {
      return length_;
    }

    int32_t Load() {
      int32_t rtn = -1;
      if (resource_.Open() == 0) {
        buffer_ = new uint8_t[length_ = resource_.length()];
        rtn = resource_.Read(buffer_, length_);
        resource_.Close();
      }
      return rtn;
    }

    void Unload() {
      if (buffer_ != NULL) {
        delete[] buffer_;
        buffer_ = NULL;
      }
      length_ = 0;
    }

  private:
    friend class SoundService;
    Resource resource_;
    uint8_t* buffer_;
    off_t length_;
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_SAMPLE_H_

