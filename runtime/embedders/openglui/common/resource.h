// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_RESOURCE_H_
#define EMBEDDERS_OPENGLUI_COMMON_RESOURCE_H_

#include <stdlib.h>
#include <string.h>

class Resource {
  public:
    explicit Resource(const char* path)
        :  descriptor_(-1),
           start_(0),
           length_(-1) {
      path_ = strdup(path);
    }

    const char* path() {
      return path_;
    }

    virtual int32_t descriptor() {
      return descriptor_;
    }

    virtual off_t start() {
      return start_;
    }

    virtual off_t length() {
      return length_;
    }

    virtual int32_t Open() {
      return -1;
    }

    virtual void Close() {
    }

    virtual int32_t Read(void* buffer, size_t count) {
      return -1;
    }

    virtual ~Resource() {
      free(path_);
    }

  protected:
    char* path_;
    int32_t descriptor_;
    off_t start_;
    off_t length_;
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_RESOURCE_H_

