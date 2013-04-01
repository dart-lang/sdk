// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/image_cache.h"

#include <ctype.h>
#include <string.h>
#include "core/SkStream.h"
#include "embedders/openglui/common/canvas_context.h"

ImageCache* ImageCache::instance_ = NULL;

extern CanvasContext* Context2D(int handle);

ImageCache::ImageCache(const char* resource_path)
    : images(), resource_path_(resource_path) {
}

const SkBitmap* ImageCache::GetImage_(const char* src_url) {
  if (strncmp(src_url, "context2d://", 12) == 0) {
    int handle = atoi(src_url + 12);
    CanvasContext* otherContext = Context2D(handle);
    return otherContext->GetBitmap();
  } else if (images.find(src_url) == images.end()) {
    SkBitmap* bm = Load(src_url);
    if (bm != NULL) {
      images[src_url] = bm;
    }
    return bm;
  } else {
    return images[src_url];
  }
}

int ImageCache::GetWidth_(const char* src_url) {
  const SkBitmap* image = GetImage(src_url);
  if (image == NULL) return 0;
  return image->width();
}

int ImageCache::GetHeight_(const char* src_url) {
  const SkBitmap* image = GetImage(src_url);
  if (image == NULL) return 0;
  return image->height();
}

SkBitmap* ImageCache::Load(const char* src_url) {
  SkBitmap *bm = NULL;
  const char* filepath;
  if (strncmp(src_url, "file://", 7) == 0) {
    filepath = src_url + 7;
  } else {
    // TODO(gram): We need a way to remap URLs to local file names.
    // For now I am just using the characters after the last '/'.
    // Note also that if we want to support URLs and network fetches,
    // then we introduce more complexity; this can't just be an URL.
    int pos = strlen(src_url);
    while (--pos >= 0 && src_url[pos] != '/');
    filepath = src_url + pos + 1;
  }
  char* path;
  if (filepath[0] == '/') {
    path = const_cast<char*>(filepath);
  } else {
    size_t len1 = strlen(resource_path_);
    size_t len2 = strlen(filepath);
    path = new char[len1 + 1 + len2 + 1];
    strncpy(path, resource_path_, len1+1);
    strncat(path, "/", 1);
    strncat(path, filepath, len2);
  }

  SkFILEStream stream(path);
  if (stream.isValid()) {
    // We could use DecodeFile and pass the path, but by creating the
    // SkStream here we can produce better error log messages.
    bm = new SkBitmap();
    if (!SkImageDecoder::DecodeStream(&stream, bm)) {
      LOGI("Image decode of %s failed", path);
      return NULL;
    } else {
      LOGI("Decode image %s: width=%d,height=%d",
          path, bm->width(), bm->height());
    }
  } else {
    LOGI("Path %s is invalid", path);
  }

  if (path != filepath) {
    delete[] path;
  }
  return bm;
}

