// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_TYPED_DATA_UTILS_H_
#define RUNTIME_BIN_TYPED_DATA_UTILS_H_

#include "include/dart_api.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class TypedDataScope {
 public:
  explicit TypedDataScope(Dart_Handle data);
  ~TypedDataScope() { Release(); }

  void Release();

  const char* GetCString() const {
    return reinterpret_cast<const char*>(data_);
  }

  const char* GetScopedCString() const;

  void* data() const { return data_; }
  intptr_t length() const { return length_; }
  intptr_t size_in_bytes() const;
  Dart_TypedData_Type type() const { return type_; }

 private:
  Dart_Handle data_handle_;
  void* data_;
  intptr_t length_;
  Dart_TypedData_Type type_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(TypedDataScope);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_TYPED_DATA_UTILS_H_
