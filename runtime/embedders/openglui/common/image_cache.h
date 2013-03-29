// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_IMAGE_CACHE_H_
#define EMBEDDERS_OPENGLUI_COMMON_IMAGE_CACHE_H_

#include <map>
#include <string>
#include "embedders/openglui/common/log.h"
#include "embedders/openglui/common/opengl.h"
#include "embedders/openglui/common/support.h"

class ImageCache {
 public:
  static void Init(const char *resource_path) {
    if (instance_ == NULL) {
      instance_ = new ImageCache(resource_path);
    }
  }

  inline static const SkBitmap* GetImage(const char* src_url) {
    if (instance_ == NULL) {
      fprintf(stderr, "GetImage called with no instance_\n");
      return NULL;
    }
    return instance_->GetImage_(src_url);
  }

  inline static int GetWidth(const char* src_url) {
    if (instance_ == NULL) {
      fprintf(stderr, "GetWidth called with no instance_\n");
      return NULL;
    }
    return instance_->GetWidth_(src_url);
  }

  inline static int GetHeight(const char* src_url) {
    if (instance_ == NULL) {
      fprintf(stderr, "GetHeight called with no instance_\n");
      return NULL;
    }
    return instance_->GetHeight_(src_url);
  }

 private:
  explicit ImageCache(const char* resource_path);
  SkBitmap* Load(const char* src_url);
  const SkBitmap* GetImage_(const char* src_url);
  int GetWidth_(const char* src_url);
  int GetHeight_(const char* src_url);

  std::map<std::string, SkBitmap*> images;
  const char* resource_path_;
  static ImageCache* instance_;
};

#endif  // EMBEDDERS_OPENGLUI_COMMON_IMAGE_CACHE_H_
