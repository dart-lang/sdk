// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_FILTER_H_
#define BIN_FILTER_H_

#include "bin/builtin.h"
#include "bin/utils.h"

#include "../third_party/zlib/zlib.h"

class Filter {
 protected:
  Filter() : initialized(false) {}

 public:
  virtual ~Filter() {}

 public:
  virtual bool Init() = 0;
  /**
   * On a succesfull call to Process, Process will take ownership of data. On
   * successive calls to either Processed or ~Filter, data will be freed with
   * a delete[] call.
   */
  virtual bool Process(uint8_t* data, intptr_t length) = 0;
  virtual intptr_t Processed(uint8_t* buffer, intptr_t length, bool finish) = 0;


 public:
  static Dart_Handle SetFilterPointerNativeField(Dart_Handle filter,
                                                 Filter* filter_pointer);
  static Dart_Handle GetFilterPointerNativeField(Dart_Handle filter,
                                                 Filter** filter_pointer);

 protected:
  bool initialized;
};

class ZLibDeflateFilter : public Filter {
 public:
  ZLibDeflateFilter(bool gZip = false, int level = 6)
    : gZip(gZip), level(level), current_buffer(NULL) {}
  virtual ~ZLibDeflateFilter();

 public:
  virtual bool Init();
  virtual bool Process(uint8_t* data, intptr_t length);
  virtual intptr_t Processed(uint8_t* buffer, intptr_t length, bool finish);

 private:
  const bool gZip;
  const int level;
  uint8_t* current_buffer;
  z_stream stream;
};

class ZLibInflateFilter : public Filter {
 public:
  ZLibInflateFilter() : current_buffer(NULL) {}
  virtual ~ZLibInflateFilter();

 public:
  virtual bool Init();
  virtual bool Process(uint8_t* data, intptr_t length);
  virtual intptr_t Processed(uint8_t* buffer, intptr_t length, bool finish);

 private:
  uint8_t* current_buffer;
  z_stream stream;
};

#endif  // BIN_FILTER_H_

