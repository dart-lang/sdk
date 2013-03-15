// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/filter.h"
#include "bin/io_buffer.h"

#include "include/dart_api.h"

const int kZlibFlagMemUsage = 8;
const int kZLibFlagWindowBits = 15;
const int kZLibFlagUseGZipHeader = 16;
const int kZLibFlagAcceptAnyHeader = 32;

static const int kFilterPointerNativeField = 0;

Filter* GetFilter(Dart_Handle filter_obj) {
  Filter* filter;
  Dart_Handle result = Filter::GetFilterPointerNativeField(filter_obj, &filter);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  if (filter == NULL) {
    Dart_ThrowException(DartUtils::NewInternalError("Filter destroyed"));
  }
  return filter;
}

void EndFilter(Dart_Handle filter_obj, Filter* filter) {
  Filter::SetFilterPointerNativeField(filter_obj, NULL);
  delete filter;
}

void FUNCTION_NAME(Filter_CreateZLibInflate)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Filter* filter = new ZLibInflateFilter();
  if (filter == NULL || !filter->Init()) {
    delete filter;
    Dart_ThrowException(DartUtils::NewInternalError(
        "Failed to create ZLibInflateFilter"));
  }
  Dart_Handle result = Filter::SetFilterPointerNativeField(filter_obj, filter);
  if (Dart_IsError(result)) {
    delete filter;
    Dart_PropagateError(result);
  }
  Dart_ExitScope();
}

void FUNCTION_NAME(Filter_CreateZLibDeflate)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Dart_Handle gzip_obj = Dart_GetNativeArgument(args, 1);
  Dart_Handle level_obj = Dart_GetNativeArgument(args, 2);
  bool gzip;
  if (Dart_IsError(Dart_BooleanValue(gzip_obj, &gzip))) {
    Dart_ThrowException(DartUtils::NewInternalError(
        "Failed to get 'gzip' parameter"));
  }
  int64_t level;
  if (Dart_IsError(Dart_IntegerToInt64(level_obj, &level))) {
    Dart_ThrowException(DartUtils::NewInternalError(
        "Failed to get 'level' parameter"));
  }
  Filter* filter = new ZLibDeflateFilter(gzip, level);
  if (filter == NULL || !filter->Init()) {
    delete filter;
    Dart_ThrowException(DartUtils::NewInternalError(
        "Failed to create ZLibDeflateFilter"));
  }
  Dart_Handle result = Filter::SetFilterPointerNativeField(filter_obj, filter);
  if (Dart_IsError(result)) {
    delete filter;
    Dart_PropagateError(result);
  }
  Dart_ExitScope();
}

void FUNCTION_NAME(Filter_Process)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Filter* filter = GetFilter(filter_obj);
  Dart_Handle data_obj = Dart_GetNativeArgument(args, 1);
  intptr_t length;
  Dart_TypedData_Type type;
  uint8_t* buffer = NULL;
  Dart_Handle result = Dart_TypedDataAcquireData(
      data_obj, &type, reinterpret_cast<void**>(&buffer), &length);
  if (!Dart_IsError(result)) {
    uint8_t* zlib_buffer = new uint8_t[length];
    if (zlib_buffer == NULL) {
      Dart_TypedDataReleaseData(data_obj);
      Dart_ThrowException(DartUtils::NewInternalError(
          "Failed to allocate buffer for zlib"));
    }
    memmove(zlib_buffer, buffer, length);
    Dart_TypedDataReleaseData(data_obj);
    buffer = zlib_buffer;
  } else {
    if (Dart_IsError(Dart_ListLength(data_obj, &length))) {
      Dart_ThrowException(DartUtils::NewInternalError(
          "Failed to get list length"));
    }
    buffer = new uint8_t[length];
    if (Dart_IsError(Dart_ListGetAsBytes(data_obj, 0, buffer, length))) {
      delete[] buffer;
      Dart_ThrowException(DartUtils::NewInternalError(
          "Failed to get list bytes"));
    }
  }
  // Process will take ownership of buffer, if successful.
  if (!filter->Process(buffer, length)) {
    delete[] buffer;
    EndFilter(filter_obj, filter);
    Dart_ThrowException(DartUtils::NewInternalError(
        "Call to Process while still processing data"));
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Filter_Processed)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Filter* filter = GetFilter(filter_obj);
  Dart_Handle flush_obj = Dart_GetNativeArgument(args, 1);
  bool flush;
  if (Dart_IsError(Dart_BooleanValue(flush_obj, &flush))) {
    Dart_ThrowException(DartUtils::NewInternalError(
        "Failed to get 'flush' parameter"));
  }
  intptr_t read = filter->Processed(filter->processed_buffer(),
                                    filter->processed_buffer_size(),
                                    flush);
  if (read < 0) {
    // Error, end filter.
    EndFilter(filter_obj, filter);
    Dart_ThrowException(DartUtils::NewInternalError(
        "Filter error, bad data"));
  } else if (read == 0) {
    Dart_SetReturnValue(args, Dart_Null());
  } else {
    uint8_t* io_buffer;
    Dart_Handle result = IOBuffer::Allocate(read, &io_buffer);
    memmove(io_buffer, filter->processed_buffer(), read);
    Dart_SetReturnValue(args, result);
  }
  Dart_ExitScope();
}


void FUNCTION_NAME(Filter_End)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Filter* filter = GetFilter(filter_obj);
  EndFilter(filter_obj, filter);
  Dart_ExitScope();
}


Dart_Handle Filter::SetFilterPointerNativeField(Dart_Handle filter,
                                                Filter* filter_pointer) {
  return Dart_SetNativeInstanceField(filter,
                                     kFilterPointerNativeField,
                                     (intptr_t)filter_pointer);
}


Dart_Handle Filter::GetFilterPointerNativeField(Dart_Handle filter,
                                                Filter** filter_pointer) {
  return Dart_GetNativeInstanceField(
      filter,
      kFilterPointerNativeField,
      reinterpret_cast<intptr_t*>(filter_pointer));
}


ZLibDeflateFilter::~ZLibDeflateFilter() {
  delete[] current_buffer_;
  if (initialized()) deflateEnd(&stream_);
}


bool ZLibDeflateFilter::Init() {
  stream_.zalloc = Z_NULL;
  stream_.zfree = Z_NULL;
  stream_.opaque = Z_NULL;
  int result = deflateInit2(
      &stream_,
      level_,
      Z_DEFLATED,
      kZLibFlagWindowBits | (gzip_ ? kZLibFlagUseGZipHeader : 0),
      kZlibFlagMemUsage,
      Z_DEFAULT_STRATEGY);
  if (result == Z_OK) {
    set_initialized(true);
    return true;
  }
  return false;
}


bool ZLibDeflateFilter::Process(uint8_t* data, intptr_t length) {
  if (current_buffer_ != NULL) return false;
  stream_.avail_in = length;
  stream_.next_in = current_buffer_ = data;
  return true;
}

intptr_t ZLibDeflateFilter::Processed(uint8_t* buffer,
                                      intptr_t length,
                                      bool flush) {
  stream_.avail_out = length;
  stream_.next_out = buffer;
  switch (deflate(&stream_, flush ? Z_SYNC_FLUSH : Z_NO_FLUSH)) {
    case Z_OK: {
      intptr_t processed = length - stream_.avail_out;
      if (processed == 0) {
        delete[] current_buffer_;
        current_buffer_ = NULL;
        return 0;
      } else {
        // We processed data, should be called again.
        return processed;
      }
    }

    case Z_STREAM_END:
    case Z_BUF_ERROR:
      // We processed all available input data.
      delete[] current_buffer_;
      current_buffer_ = NULL;
      return 0;

    default:
    case Z_STREAM_ERROR:
      // An error occoured.
      delete[] current_buffer_;
      current_buffer_ = NULL;
      return -1;
  }
}


ZLibInflateFilter::~ZLibInflateFilter() {
  delete[] current_buffer_;
  if (initialized()) inflateEnd(&stream_);
}


bool ZLibInflateFilter::Init() {
  stream_.zalloc = Z_NULL;
  stream_.zfree = Z_NULL;
  stream_.opaque = Z_NULL;
  int result = inflateInit2(&stream_,
                            kZLibFlagWindowBits | kZLibFlagAcceptAnyHeader);
  if (result == Z_OK) {
    set_initialized(true);
    return true;
  }
  return false;
}


bool ZLibInflateFilter::Process(uint8_t* data, intptr_t length) {
  if (current_buffer_ != NULL) return false;
  stream_.avail_in = length;
  stream_.next_in = current_buffer_ = data;
  return true;
}


intptr_t ZLibInflateFilter::Processed(uint8_t* buffer,
                                      intptr_t length,
                                      bool flush) {
  stream_.avail_out = length;
  stream_.next_out = buffer;
  switch (inflate(&stream_, flush ? Z_SYNC_FLUSH : Z_NO_FLUSH)) {
    case Z_OK: {
      intptr_t processed = length - stream_.avail_out;
      if (processed == 0) {
        delete[] current_buffer_;
        current_buffer_ = NULL;
        return 0;
      } else {
        // We processed data, should be called again.
        return processed;
      }
    }

    case Z_STREAM_END:
    case Z_BUF_ERROR:
      // We processed all available input data.
      delete[] current_buffer_;
      current_buffer_ = NULL;
      return 0;

    default:
    case Z_MEM_ERROR:
    case Z_NEED_DICT:
    case Z_DATA_ERROR:
    case Z_STREAM_ERROR:
      // An error occoured.
      delete[] current_buffer_;
      current_buffer_ = NULL;
      return -1;
  }
}

