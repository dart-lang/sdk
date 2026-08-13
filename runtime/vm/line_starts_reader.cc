// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME) || defined(DART_DYNAMIC_MODULES)

#include "vm/line_starts_reader.h"
#include "vm/object.h"
#include "vm/token_position.h"

namespace dart {

LineStartsReader::LineStartsReader(const dart::TypedData& line_starts_data)
    : line_starts_data_(line_starts_data),
      element_type_(line_starts_data.ElementType()) {
  RELEASE_ASSERT((element_type_ == kUint16ArrayElement) ||
                 (element_type_ == kUint32ArrayElement));
}

uint32_t LineStartsReader::MaxPosition() const {
  const intptr_t line_count = line_starts_data_.Length();
  if (line_count == 0) {
    return 0;
  }
  return At(line_count - 1);
}

bool LineStartsReader::LocationForPosition(intptr_t position,
                                           intptr_t* line,
                                           intptr_t* col) const {
  const intptr_t line_count = line_starts_data_.Length();
  if (position < 0 || static_cast<uint32_t>(position) > MaxPosition() ||
      line_count == 0) {
    return false;
  }

  intptr_t lo = 0;
  intptr_t hi = line_count;
  while (hi > lo + 1) {
    const intptr_t mid = lo + (hi - lo) / 2;
    const intptr_t mid_position = At(mid);
    if (mid_position > position) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  *line = lo + 1;
  if (col != nullptr) {
    *col = position - At(lo) + 1;
  }

  return true;
}

bool LineStartsReader::TokenRangeAtLine(intptr_t line_number,
                                        TokenPosition* first_token_index,
                                        TokenPosition* last_token_index) const {
  const intptr_t line_count = line_starts_data_.Length();
  if (line_number <= 0 || line_number > line_count) {
    return false;
  }
  *first_token_index = TokenPosition::Deserialize(At(line_number - 1));
  if (line_number == line_count) {
    *last_token_index = *first_token_index;
  } else {
    *last_token_index = TokenPosition::Deserialize(At(line_number) - 1);
  }
  return true;
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME) || defined(DART_DYNAMIC_MODULES)
