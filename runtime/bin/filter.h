// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_FILTER_H_
#define BIN_FILTER_H_

#include "bin/builtin.h"
#include "bin/utils.h"

#include "../third_party/zlib/zlib.h"

class Filter {
 public:
  virtual ~Filter() {}

  virtual bool Init() = 0;

  /**
   * On a succesfull call to Process, Process will take ownership of data. On
   * successive calls to either Processed or ~Filter, data will be freed with
   * a delete[] call.
   */
  virtual bool Process(uint8_t* data, intptr_t length) = 0;
  virtual intptr_t Processed(uint8_t* buffer, intptr_t length, bool finish) = 0;

  static Dart_Handle SetFilterPointerNativeField(Dart_Handle filter,
                                                 Filter* filter_pointer);
  static Dart_Handle GetFilterPointerNativeField(Dart_Handle filter,
                                                 Filter** filter_pointer);

  bool initialized() const { return initialized_; }
  void set_initialized(bool value) { initialized_ = value; }
  uint8_t* processed_buffer() { return processed_buffer_; }
  intptr_t processed_buffer_size() const { return kFilterBufferSize; }

 protected:
  Filter() : initialized_(false) {}

 private:
  static const intptr_t kFilterBufferSize = 64 * KB;
  uint8_t processed_buffer_[kFilterBufferSize];
  bool initialized_;

  DISALLOW_COPY_AND_ASSIGN(Filter);
};

class ZLibDeflateFilter : public Filter {
 public:
  ZLibDeflateFilter(bool gzip = false, int level = 6)
    : gzip_(gzip), level_(level), current_buffer_(NULL) {}
  virtual ~ZLibDeflateFilter();

  virtual bool Init();
  virtual bool Process(uint8_t* data, intptr_t length);
  virtual intptr_t Processed(uint8_t* buffer, intptr_t length, bool finish);

 private:
  const bool gzip_;
  const int level_;
  uint8_t* current_buffer_;
  z_stream stream_;

  DISALLOW_COPY_AND_ASSIGN(ZLibDeflateFilter);
};

class ZLibInflateFilter : public Filter {
 public:
  ZLibInflateFilter() : current_buffer_(NULL) {}
  virtual ~ZLibInflateFilter();

  virtual bool Init();
  virtual bool Process(uint8_t* data, intptr_t length);
  virtual intptr_t Processed(uint8_t* buffer, intptr_t length, bool finish);

 private:
  uint8_t* current_buffer_;
  z_stream stream_;

  DISALLOW_COPY_AND_ASSIGN(ZLibInflateFilter);
};

#endif  // BIN_FILTER_H_

