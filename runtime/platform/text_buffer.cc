// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/text_buffer.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/unicode.h"
#include "platform/utils.h"

namespace dart {

intptr_t BaseTextBuffer::Printf(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t len = VPrintf(format, args);
  va_end(args);
  return len;
}

intptr_t BaseTextBuffer::VPrintf(const char* format, va_list args) {
  va_list args1;
  va_copy(args1, args);
  intptr_t remaining = capacity_ - length_;
  ASSERT(remaining >= 0);
  intptr_t len = Utils::VSNPrint(buffer_ + length_, remaining, format, args1);
  va_end(args1);
  if (len >= remaining) {
    if (!EnsureCapacity(len)) {
      length_ = capacity_ - 1;
      buffer_[length_] = '\0';
      return remaining - 1;
    }
    remaining = capacity_ - length_;
    ASSERT(remaining > len);
    va_list args2;
    va_copy(args2, args);
    intptr_t len2 =
        Utils::VSNPrint(buffer_ + length_, remaining, format, args2);
    va_end(args2);
    ASSERT(len == len2);
  }
  length_ += len;
  buffer_[length_] = '\0';
  return len;
}

void BaseTextBuffer::AddChar(char ch) {
  if (!EnsureCapacity(sizeof(ch))) return;
  buffer_[length_] = ch;
  length_++;
  buffer_[length_] = '\0';
}

void BaseTextBuffer::AddRaw(const uint8_t* buffer, intptr_t buffer_length) {
  ASSERT(buffer != nullptr);
  if (!EnsureCapacity(buffer_length)) {
    buffer_length = capacity_ - length_ - 1;  // Copy what fits.
  }
  memmove(&buffer_[length_], buffer, buffer_length);
  length_ += buffer_length;
  buffer_[length_] = '\0';
}

void BaseTextBuffer::AddEscapedUTF8(const char* const s, intptr_t len) {
  const uint8_t* cursor = reinterpret_cast<const uint8_t*>(s);
  const uint8_t* end = cursor + len;

  intptr_t needed = 0;
  while (cursor < end) {
    uint8_t codeunit = *cursor++;
    if (codeunit >= 0x80) {
      needed += 1;
    } else {
      needed += EscapedCodeUnitLength(codeunit);
    }
  }

  if (!EnsureCapacity(needed)) return;

  cursor = reinterpret_cast<const uint8_t*>(s);
  while (cursor < end) {
    uint8_t codeunit = *cursor++;
    if (codeunit >= 0x80) {
      buffer_[length_++] = codeunit;
    } else {
      EscapeAndAddCodeUnit(codeunit);
    }
  }
  buffer_[length_] = '\0';
}

void BaseTextBuffer::AddEscapedLatin1(const uint8_t* const s, intptr_t len) {
  const uint8_t* cursor = s;
  const uint8_t* end = cursor + len;

  intptr_t needed = 0;
  while (cursor < end) {
    needed += EscapedCodeUnitLength(*cursor++);
  }

  if (!EnsureCapacity(needed)) return;

  cursor = s;
  while (cursor < end) {
    EscapeAndAddCodeUnit(*cursor++);
  }
  buffer_[length_] = '\0';
}

void BaseTextBuffer::AddEscapedUTF16(const uint16_t* s, intptr_t len) {
  for (const uint16_t* end = s + len; s < end; s++) {
    if (!EnsureCapacity(6)) return;

    uint16_t code_unit = *s;
    if (Utf16::IsTrailSurrogate(code_unit)) {
      EscapeAndAddUTF16CodeUnit(code_unit);
    } else if (Utf16::IsLeadSurrogate(code_unit)) {
      if (s + 1 == end) {
        EscapeAndAddUTF16CodeUnit(code_unit);
      } else {
        uint16_t next_code_unit = *(s + 1);
        if (Utf16::IsTrailSurrogate(next_code_unit)) {
          uint32_t decoded = Utf16::Decode(code_unit, next_code_unit);
          EscapeAndAddCodeUnit(decoded);
          s++;
        } else {
          EscapeAndAddUTF16CodeUnit(code_unit);
        }
      }
    } else {
      EscapeAndAddCodeUnit(code_unit);
    }
  }
  buffer_[length_] = '\0';
}

DART_FORCE_INLINE
intptr_t BaseTextBuffer::EscapedCodeUnitLength(uint32_t codeunit) {
  switch (codeunit) {
    case '"':
    case '\\':
    case '/':
    case '\b':
    case '\f':
    case '\n':
    case '\r':
    case '\t':
      return 2;
    default:
      if (codeunit < 0x20) {
        return 6;
      } else if (codeunit <= Utf8::kMaxOneByteChar) {
        return 1;
      } else if (codeunit <= Utf8::kMaxTwoByteChar) {
        return 2;
      } else if (codeunit <= Utf8::kMaxThreeByteChar) {
        return 3;
      } else {
        ASSERT(codeunit <= Utf8::kMaxFourByteChar);
        return 4;
      }
  }
}

static uint8_t Hex(uint8_t value) {
  return value < 10 ? '0' + value : 'A' + value - 10;
}

// Write a UTF-32 code unit so it can be read by a JSON parser in a string
// literal. Use official encoding from JSON specification. http://json.org/
DART_FORCE_INLINE
void BaseTextBuffer::EscapeAndAddCodeUnit(uint32_t codeunit) {
  intptr_t remaining = capacity_ - length_;
  switch (codeunit) {
    case '"':
      ASSERT(remaining > 2);
      buffer_[length_++] = '\\';
      buffer_[length_++] = '\"';
      break;
    case '\\':
      ASSERT(remaining > 2);
      buffer_[length_++] = '\\';
      buffer_[length_++] = '\\';
      break;
    case '/':
      ASSERT(remaining > 2);
      buffer_[length_++] = '\\';
      buffer_[length_++] = '/';
      break;
    case '\b':
      ASSERT(remaining > 2);
      buffer_[length_++] = '\\';
      buffer_[length_++] = 'b';
      break;
    case '\f':
      ASSERT(remaining > 2);
      buffer_[length_++] = '\\';
      buffer_[length_++] = 'f';
      break;
    case '\n':
      ASSERT(remaining > 2);
      buffer_[length_++] = '\\';
      buffer_[length_++] = 'n';
      break;
    case '\r':
      ASSERT(remaining > 2);
      buffer_[length_++] = '\\';
      buffer_[length_++] = 'r';
      break;
    case '\t':
      ASSERT(remaining > 2);
      buffer_[length_++] = '\\';
      buffer_[length_++] = 't';
      break;
    default:
      constexpr int kMask = ~(1 << 6);
      if (codeunit < 0x20) {
        ASSERT(remaining > 6);
        buffer_[length_++] = '\\';
        buffer_[length_++] = 'u';
        buffer_[length_++] = Hex((codeunit >> 12) & 0xF);
        buffer_[length_++] = Hex((codeunit >> 8) & 0xF);
        buffer_[length_++] = Hex((codeunit >> 4) & 0xF);
        buffer_[length_++] = Hex((codeunit >> 0) & 0xF);
      } else if (codeunit <= Utf8::kMaxOneByteChar) {
        ASSERT(remaining > 1);
        buffer_[length_++] = codeunit;
      } else if (codeunit <= Utf8::kMaxTwoByteChar) {
        ASSERT(remaining > 2);
        buffer_[length_++] = 0xC0 | (codeunit >> 6);
        buffer_[length_++] = 0x80 | (codeunit & kMask);
      } else if (codeunit <= Utf8::kMaxThreeByteChar) {
        ASSERT(remaining > 3);
        buffer_[length_++] = 0xE0 | (codeunit >> 12);
        buffer_[length_++] = 0x80 | ((codeunit >> 6) & kMask);
        buffer_[length_++] = 0x80 | (codeunit & kMask);
      } else {
        ASSERT(codeunit <= Utf8::kMaxFourByteChar);
        ASSERT(remaining > 4);
        buffer_[length_++] = 0xF0 | (codeunit >> 18);
        buffer_[length_++] = 0x80 | ((codeunit >> 12) & kMask);
        buffer_[length_++] = 0x80 | ((codeunit >> 6) & kMask);
        buffer_[length_++] = 0x80 | (codeunit & kMask);
      }
  }
}

// Write an incomplete UTF-16 code unit so it can be read by a JSON parser in a
// string literal.
void BaseTextBuffer::EscapeAndAddUTF16CodeUnit(uint16_t codeunit) {
  intptr_t remaining = capacity_ - length_;
  ASSERT(remaining > 6);
  buffer_[length_++] = '\\';
  buffer_[length_++] = 'u';
  buffer_[length_++] = Hex((codeunit >> 12) & 0xF);
  buffer_[length_++] = Hex((codeunit >> 8) & 0xF);
  buffer_[length_++] = Hex((codeunit >> 4) & 0xF);
  buffer_[length_++] = Hex((codeunit >> 0) & 0xF);
}

void BaseTextBuffer::AddString(const char* s) {
  AddRaw(reinterpret_cast<const uint8_t*>(s), strlen(s));
}

void BaseTextBuffer::AddEscapedString(const char* s) {
  AddEscapedUTF8(s, strlen(s));
}

TextBuffer::TextBuffer(intptr_t buf_size) {
  ASSERT(buf_size > 0);
  buffer_ = reinterpret_cast<char*>(malloc(buf_size));
  capacity_ = buf_size;
  Clear();
}

TextBuffer::~TextBuffer() {
  free(buffer_);
  buffer_ = nullptr;
}

char* TextBuffer::Steal() {
  char* r = buffer_;
  buffer_ = nullptr;
  capacity_ = 0;
  length_ = 0;
  return r;
}

bool TextBuffer::EnsureCapacity(intptr_t len) {
  intptr_t remaining = capacity_ - length_;
  if (remaining <= len) {
    intptr_t new_size = capacity_ + Utils::Maximum(capacity_, len + 1);
    new_size = Utils::Maximum(new_size, static_cast<intptr_t>(256));
    char* new_buf = reinterpret_cast<char*>(realloc(buffer_, new_size));
    buffer_ = new_buf;
    capacity_ = new_size;
  }
  return true;
}

}  // namespace dart
