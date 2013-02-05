// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_ISIZED_H_
#define EMBEDDERS_OPENGLUI_COMMON_ISIZED_H_

#include <stdint.h>

// An interface for objects that have a size. VMGlue needs the window
// size when calling setup() (and eventually resize()) but it does not
// need to know anything else about the window, so we use this interface.
class ISized {
  public:
    virtual const int32_t& height() = 0;
    virtual const int32_t& width() = 0;
    virtual ~ISized() {}
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_ISIZED_H_

