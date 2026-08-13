// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_LINE_STARTS_READER_H_
#define RUNTIME_VM_LINE_STARTS_READER_H_

#if !defined(DART_PRECOMPILED_RUNTIME) || defined(DART_DYNAMIC_MODULES)

#include <memory>

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/token_position.h"

namespace dart {

class LineStartsReader : public ValueObject {
 public:
  explicit LineStartsReader(const TypedData& line_starts_data);

  uint32_t At(intptr_t index) const {
    if (element_type_ == kUint16ArrayElement) {
      return line_starts_data_.GetUint16(index << 1);
    } else {
      ASSERT(element_type_ == kUint32ArrayElement);
      return line_starts_data_.GetUint32(index << 2);
    }
  }

  uint32_t MaxPosition() const;

  // Returns whether the given offset corresponds to a valid source offset
  // If it does, then *line and *column (if column is not nullptr) are set
  // to the line and column the token starts at.
  DART_WARN_UNUSED_RESULT bool LocationForPosition(
      intptr_t position,
      intptr_t* line,
      intptr_t* col = nullptr) const;

  // Returns whether any tokens were found for the given line. When found,
  // *first_token_index and *last_token_index are set to the first and
  // last token on the line, respectively.
  DART_WARN_UNUSED_RESULT bool TokenRangeAtLine(
      intptr_t line_number,
      TokenPosition* first_token_index,
      TokenPosition* last_token_index) const;

 private:
  const TypedData& line_starts_data_;
  const TypedDataElementType element_type_;
};

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME) || defined(DART_DYNAMIC_MODULES)
#endif  // RUNTIME_VM_LINE_STARTS_READER_H_
