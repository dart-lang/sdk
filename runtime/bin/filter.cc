// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "bin/filter.h"

#include "bin/dartutils.h"
#include "bin/io_buffer.h"

#include "include/dart_api.h"

namespace dart {
namespace bin {

const int kZLibFlagUseGZipHeader = 16;
const int kZLibFlagAcceptAnyHeader = 32;

static const int kFilterPointerNativeField = 0;

static Dart_Handle GetFilter(Dart_Handle filter_obj, Filter** filter) {
  ASSERT(filter != NULL);
  Filter* result;
  Dart_Handle err = Filter::GetFilterNativeField(filter_obj, &result);
  if (Dart_IsError(err)) {
    return err;
  }
  if (result == NULL) {
    return Dart_NewApiError("Filter was destroyed");
  }

  *filter = result;
  return Dart_Null();
}

static Dart_Handle CopyDictionary(Dart_Handle dictionary_obj,
                                  uint8_t** dictionary) {
  ASSERT(dictionary != NULL);
  uint8_t* src = NULL;
  intptr_t size;
  Dart_TypedData_Type type;

  Dart_Handle err = Dart_ListLength(dictionary_obj, &size);
  if (Dart_IsError(err)) {
    return err;
  }

  uint8_t* result = new uint8_t[size];
  if (result == NULL) {
    return Dart_NewApiError("Could not allocate new dictionary");
  }

  err = Dart_TypedDataAcquireData(dictionary_obj, &type,
                                  reinterpret_cast<void**>(&src), &size);
  if (!Dart_IsError(err)) {
    memmove(result, src, size);
    Dart_TypedDataReleaseData(dictionary_obj);
  } else {
    err = Dart_ListGetAsBytes(dictionary_obj, 0, result, size);
    if (Dart_IsError(err)) {
      delete[] result;
      return err;
    }
  }

  *dictionary = result;
  return Dart_Null();
}

void FUNCTION_NAME(Filter_CreateZLibInflate)(Dart_NativeArguments args) {
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Dart_Handle window_bits_obj = Dart_GetNativeArgument(args, 1);
  int64_t window_bits = DartUtils::GetIntegerValue(window_bits_obj);
  Dart_Handle dict_obj = Dart_GetNativeArgument(args, 2);
  Dart_Handle raw_obj = Dart_GetNativeArgument(args, 3);
  bool raw = DartUtils::GetBooleanValue(raw_obj);

  Dart_Handle err;
  uint8_t* dictionary = NULL;
  intptr_t dictionary_length = 0;
  if (!Dart_IsNull(dict_obj)) {
    err = CopyDictionary(dict_obj, &dictionary);
    if (Dart_IsError(err)) {
      Dart_PropagateError(err);
    }
    ASSERT(dictionary != NULL);
    dictionary_length = 0;
    err = Dart_ListLength(dict_obj, &dictionary_length);
    if (Dart_IsError(err)) {
      delete[] dictionary;
      Dart_PropagateError(err);
    }
  }

  ZLibInflateFilter* filter = new ZLibInflateFilter(
      static_cast<int32_t>(window_bits), dictionary, dictionary_length, raw);
  if (filter == NULL) {
    delete[] dictionary;
    Dart_PropagateError(
        Dart_NewApiError("Could not allocate ZLibInflateFilter"));
  }
  if (!filter->Init()) {
    delete filter;
    Dart_ThrowException(
        DartUtils::NewInternalError("Failed to create ZLibInflateFilter"));
  }
  err = Filter::SetFilterAndCreateFinalizer(
      filter_obj, filter, sizeof(*filter) + dictionary_length);
  if (Dart_IsError(err)) {
    delete filter;
    Dart_PropagateError(err);
  }
}

void FUNCTION_NAME(Filter_CreateZLibDeflate)(Dart_NativeArguments args) {
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Dart_Handle gzip_obj = Dart_GetNativeArgument(args, 1);
  bool gzip = DartUtils::GetBooleanValue(gzip_obj);
  Dart_Handle level_obj = Dart_GetNativeArgument(args, 2);
  int64_t level =
      DartUtils::GetInt64ValueCheckRange(level_obj, kMinInt32, kMaxInt32);
  Dart_Handle window_bits_obj = Dart_GetNativeArgument(args, 3);
  int64_t window_bits = DartUtils::GetIntegerValue(window_bits_obj);
  Dart_Handle mLevel_obj = Dart_GetNativeArgument(args, 4);
  int64_t mem_level = DartUtils::GetIntegerValue(mLevel_obj);
  Dart_Handle strategy_obj = Dart_GetNativeArgument(args, 5);
  int64_t strategy = DartUtils::GetIntegerValue(strategy_obj);
  Dart_Handle dict_obj = Dart_GetNativeArgument(args, 6);
  Dart_Handle raw_obj = Dart_GetNativeArgument(args, 7);
  bool raw = DartUtils::GetBooleanValue(raw_obj);

  Dart_Handle err;
  uint8_t* dictionary = NULL;
  intptr_t dictionary_length = 0;
  if (!Dart_IsNull(dict_obj)) {
    err = CopyDictionary(dict_obj, &dictionary);
    if (Dart_IsError(err)) {
      Dart_PropagateError(err);
    }
    ASSERT(dictionary != NULL);
    dictionary_length = 0;
    err = Dart_ListLength(dict_obj, &dictionary_length);
    if (Dart_IsError(err)) {
      delete[] dictionary;
      Dart_PropagateError(err);
    }
  }

  ZLibDeflateFilter* filter = new ZLibDeflateFilter(
      gzip, static_cast<int32_t>(level), static_cast<int32_t>(window_bits),
      static_cast<int32_t>(mem_level), static_cast<int32_t>(strategy),
      dictionary, dictionary_length, raw);
  if (filter == NULL) {
    delete[] dictionary;
    Dart_PropagateError(
        Dart_NewApiError("Could not allocate ZLibDeflateFilter"));
  }
  if (!filter->Init()) {
    delete filter;
    Dart_ThrowException(
        DartUtils::NewInternalError("Failed to create ZLibDeflateFilter"));
  }
  Dart_Handle result = Filter::SetFilterAndCreateFinalizer(
      filter_obj, filter, sizeof(*filter) + dictionary_length);
  if (Dart_IsError(result)) {
    delete filter;
    Dart_PropagateError(result);
  }
}

void FUNCTION_NAME(Filter_Process)(Dart_NativeArguments args) {
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Dart_Handle data_obj = Dart_GetNativeArgument(args, 1);
  intptr_t start = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t end = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  intptr_t chunk_length = end - start;
  intptr_t length;
  Dart_TypedData_Type type;
  uint8_t* buffer = NULL;

  Filter* filter = NULL;
  Dart_Handle err = GetFilter(filter_obj, &filter);
  if (Dart_IsError(err)) {
    Dart_PropagateError(err);
  }

  Dart_Handle result = Dart_TypedDataAcquireData(
      data_obj, &type, reinterpret_cast<void**>(&buffer), &length);
  if (!Dart_IsError(result)) {
    ASSERT(type == Dart_TypedData_kUint8 || type == Dart_TypedData_kInt8);
    if (type != Dart_TypedData_kUint8 && type != Dart_TypedData_kInt8) {
      Dart_TypedDataReleaseData(data_obj);
      Dart_ThrowException(DartUtils::NewInternalError(
          "Invalid argument passed to Filter_Process"));
    }
    uint8_t* zlib_buffer = new uint8_t[chunk_length];
    if (zlib_buffer == NULL) {
      Dart_TypedDataReleaseData(data_obj);
      Dart_PropagateError(Dart_NewApiError("Could not allocate zlib buffer"));
    }

    memmove(zlib_buffer, buffer + start, chunk_length);
    Dart_TypedDataReleaseData(data_obj);
    buffer = zlib_buffer;
  } else {
    err = Dart_ListLength(data_obj, &length);
    if (Dart_IsError(err)) {
      Dart_PropagateError(err);
    }
    buffer = new uint8_t[chunk_length];
    if (buffer == NULL) {
      Dart_PropagateError(Dart_NewApiError("Could not allocate buffer"));
    }
    err = Dart_ListGetAsBytes(data_obj, start, buffer, chunk_length);
    if (Dart_IsError(err)) {
      delete[] buffer;
      Dart_PropagateError(err);
    }
  }
  // Process will take ownership of buffer, if successful.
  if (!filter->Process(buffer, chunk_length)) {
    delete[] buffer;
    Dart_ThrowException(DartUtils::NewInternalError(
        "Call to Process while still processing data"));
  }
}

void FUNCTION_NAME(Filter_Processed)(Dart_NativeArguments args) {
  Dart_Handle filter_obj = Dart_GetNativeArgument(args, 0);
  Dart_Handle flush_obj = Dart_GetNativeArgument(args, 1);
  bool flush = DartUtils::GetBooleanValue(flush_obj);
  Dart_Handle end_obj = Dart_GetNativeArgument(args, 2);
  bool end = DartUtils::GetBooleanValue(end_obj);

  Filter* filter = NULL;
  Dart_Handle err = GetFilter(filter_obj, &filter);
  if (Dart_IsError(err)) {
    Dart_PropagateError(err);
  }

  intptr_t read = filter->Processed(
      filter->processed_buffer(), filter->processed_buffer_size(), flush, end);
  if (read < 0) {
    Dart_ThrowException(DartUtils::NewInternalError("Filter error, bad data"));
  } else if (read == 0) {
    Dart_SetReturnValue(args, Dart_Null());
  } else {
    uint8_t* io_buffer;
    Dart_Handle result = IOBuffer::Allocate(read, &io_buffer);
    memmove(io_buffer, filter->processed_buffer(), read);
    Dart_SetReturnValue(args, result);
  }
}

static void DeleteFilter(void* isolate_data,
                         Dart_WeakPersistentHandle handle,
                         void* filter_pointer) {
  Filter* filter = reinterpret_cast<Filter*>(filter_pointer);
  delete filter;
}

Dart_Handle Filter::SetFilterAndCreateFinalizer(Dart_Handle filter,
                                                Filter* filter_pointer,
                                                intptr_t size) {
  Dart_Handle err =
      Dart_SetNativeInstanceField(filter, kFilterPointerNativeField,
                                  reinterpret_cast<intptr_t>(filter_pointer));
  if (Dart_IsError(err)) {
    return err;
  }
  Dart_NewWeakPersistentHandle(filter, reinterpret_cast<void*>(filter_pointer),
                               size, DeleteFilter);
  return err;
}

Dart_Handle Filter::GetFilterNativeField(Dart_Handle filter,
                                         Filter** filter_pointer) {
  return Dart_GetNativeInstanceField(
      filter, kFilterPointerNativeField,
      reinterpret_cast<intptr_t*>(filter_pointer));
}

ZLibDeflateFilter::~ZLibDeflateFilter() {
  delete[] dictionary_;
  delete[] current_buffer_;
  if (initialized()) {
    deflateEnd(&stream_);
  }
}

bool ZLibDeflateFilter::Init() {
  int window_bits = window_bits_;
  if (raw_) {
    window_bits = -window_bits;
  } else if (gzip_) {
    window_bits += kZLibFlagUseGZipHeader;
  }
  stream_.next_in = Z_NULL;
  stream_.zalloc = Z_NULL;
  stream_.zfree = Z_NULL;
  stream_.opaque = Z_NULL;
  int result = deflateInit2(&stream_, level_, Z_DEFLATED, window_bits,
                            mem_level_, strategy_);
  if (result != Z_OK) {
    return false;
  }
  if ((dictionary_ != NULL) && !gzip_ && !raw_) {
    result = deflateSetDictionary(&stream_, dictionary_, dictionary_length_);
    delete[] dictionary_;
    dictionary_ = NULL;
    if (result != Z_OK) {
      return false;
    }
  }
  set_initialized(true);
  return true;
}

bool ZLibDeflateFilter::Process(uint8_t* data, intptr_t length) {
  if (current_buffer_ != NULL) {
    return false;
  }
  stream_.avail_in = length;
  stream_.next_in = current_buffer_ = data;
  return true;
}

intptr_t ZLibDeflateFilter::Processed(uint8_t* buffer,
                                      intptr_t length,
                                      bool flush,
                                      bool end) {
  stream_.avail_out = length;
  stream_.next_out = buffer;
  bool error = false;
  switch (
      deflate(&stream_, end ? Z_FINISH : flush ? Z_SYNC_FLUSH : Z_NO_FLUSH)) {
    case Z_STREAM_END:
    case Z_BUF_ERROR:
    case Z_OK: {
      intptr_t processed = length - stream_.avail_out;
      if (processed == 0) {
        break;
      }
      return processed;
    }

    default:
    case Z_STREAM_ERROR:
      error = true;
  }

  delete[] current_buffer_;
  current_buffer_ = NULL;
  // Either 0 Byte processed or error
  return error ? -1 : 0;
}

ZLibInflateFilter::~ZLibInflateFilter() {
  delete[] dictionary_;
  delete[] current_buffer_;
  if (initialized()) {
    inflateEnd(&stream_);
  }
}

bool ZLibInflateFilter::Init() {
  int window_bits =
      raw_ ? -window_bits_ : window_bits_ | kZLibFlagAcceptAnyHeader;

  stream_.next_in = Z_NULL;
  stream_.avail_in = 0;
  stream_.zalloc = Z_NULL;
  stream_.zfree = Z_NULL;
  stream_.opaque = Z_NULL;
  int result = inflateInit2(&stream_, window_bits);
  if (result != Z_OK) {
    return false;
  }
  set_initialized(true);
  return true;
}

bool ZLibInflateFilter::Process(uint8_t* data, intptr_t length) {
  if (current_buffer_ != NULL) {
    return false;
  }
  stream_.avail_in = length;
  stream_.next_in = current_buffer_ = data;
  return true;
}

intptr_t ZLibInflateFilter::Processed(uint8_t* buffer,
                                      intptr_t length,
                                      bool flush,
                                      bool end) {
  stream_.avail_out = length;
  stream_.next_out = buffer;
  bool error = false;
  int v;
  switch (v = inflate(&stream_,
                      end ? Z_FINISH : flush ? Z_SYNC_FLUSH : Z_NO_FLUSH)) {
    case Z_STREAM_END:
    case Z_BUF_ERROR:
    case Z_OK: {
      intptr_t processed = length - stream_.avail_out;
      if (processed == 0) {
        break;
      }
      return processed;
    }

    case Z_NEED_DICT:
      if (dictionary_ == NULL) {
        error = true;
      } else {
        int result =
            inflateSetDictionary(&stream_, dictionary_, dictionary_length_);
        delete[] dictionary_;
        dictionary_ = NULL;
        error = result != Z_OK;
      }
      if (error) {
        break;
      } else {
        return Processed(buffer, length, flush, end);
      }

    default:
    case Z_MEM_ERROR:
    case Z_DATA_ERROR:
    case Z_STREAM_ERROR:
      error = true;
  }

  delete[] current_buffer_;
  current_buffer_ = NULL;
  // Either 0 Byte processed or error
  return error ? -1 : 0;
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED)
