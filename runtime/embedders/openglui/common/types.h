// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_TYPES_H_
#define EMBEDDERS_OPENGLUI_COMMON_TYPES_H_

struct Location {
  Location() : pos_x_(0), pos_y_(0) {
  };
  void setPosition(float pos_x, float pos_y) {
    pos_x_ = pos_x;
    pos_y_ = pos_y;
  }
  void translate(float amount_x, float amount_y) {
    pos_x_ += amount_x;
    pos_y_ += amount_y;
  }

  float pos_x_, pos_y_;
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_TYPES_H_

