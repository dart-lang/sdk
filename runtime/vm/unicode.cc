// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/unicode.h"

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

// A constant mask that can be 'and'ed with a word of data to determine if it
// is all ASCII (with no Latin1 characters).
#if defined(ARCH_IS_64_BIT)
static const uintptr_t kAsciiWordMask = DART_UINT64_C(0x8080808080808080);
#else
static const uintptr_t kAsciiWordMask = 0x80808080u;
#endif

intptr_t Utf8::Length(const String& str) {
  if (str.IsOneByteString() || str.IsExternalOneByteString()) {
    // For 1-byte strings, all code points < 0x80 have single-byte UTF-8
    // encodings and all >= 0x80 have two-byte encodings.  To get the length,
    // start with the number of code points and add the number of high bits in
    // the bytes.
    uintptr_t char_length = str.Length();
    uintptr_t length = char_length;
    const uintptr_t* data;
    NoSafepointScope no_safepoint;
    if (str.IsOneByteString()) {
      data = reinterpret_cast<const uintptr_t*>(OneByteString::DataStart(str));
    } else {
      data = reinterpret_cast<const uintptr_t*>(
          ExternalOneByteString::DataStart(str));
    }
    uintptr_t i;
    for (i = sizeof(uintptr_t); i <= char_length; i += sizeof(uintptr_t)) {
      uintptr_t chunk = *data++;
      chunk &= kAsciiWordMask;
      if (chunk != 0) {
// Shuffle the bits until we have a count of bits in the low nibble.
#if defined(ARCH_IS_64_BIT)
        chunk += chunk >> 32;
#endif
        chunk += chunk >> 16;
        chunk += chunk >> 8;
        length += (chunk >> 7) & 0xf;
      }
    }
    // Take care of the tail of the string, the last length % wordsize chars.
    i -= sizeof(uintptr_t);
    for (; i < char_length; i++) {
      if (str.CharAt(i) > kMaxOneByteChar) length++;
    }
    return length;
  }

  // Slow case for 2-byte strings that handles surrogate pairs and longer UTF-8
  // encodings.
  intptr_t length = 0;
  String::CodePointIterator it(str);
  while (it.Next()) {
    int32_t ch = it.Current();
    length += Utf8::Length(ch);
  }
  return length;
}

intptr_t Utf8::Encode(const String& src, char* dst, intptr_t len) {
  uintptr_t array_len = len;
  intptr_t pos = 0;
  ASSERT(static_cast<intptr_t>(array_len) >= Length(src));
  if (src.IsOneByteString() || src.IsExternalOneByteString()) {
    // For 1-byte strings, all code points < 0x80 have single-byte UTF-8
    // encodings and all >= 0x80 have two-byte encodings.
    const uintptr_t* data;
    NoSafepointScope scope;
    if (src.IsOneByteString()) {
      data = reinterpret_cast<const uintptr_t*>(OneByteString::DataStart(src));
    } else {
      data = reinterpret_cast<const uintptr_t*>(
          ExternalOneByteString::DataStart(src));
    }
    uintptr_t char_length = src.Length();
    uintptr_t pos = 0;
    ASSERT(kMaxOneByteChar + 1 == 0x80);
    for (uintptr_t i = 0; i < char_length; i += sizeof(uintptr_t)) {
      // Read the input one word at a time and just write it verbatim if it is
      // plain ASCII, as determined by the mask.
      if (i + sizeof(uintptr_t) <= char_length &&
          (*data & kAsciiWordMask) == 0 &&
          pos + sizeof(uintptr_t) <= array_len) {
        StoreUnaligned(reinterpret_cast<uintptr_t*>(dst + pos), *data);
        pos += sizeof(uintptr_t);
      } else {
        // Process up to one word of input that contains non-ASCII Latin1
        // characters.
        const uint8_t* p = reinterpret_cast<const uint8_t*>(data);
        const uint8_t* limit =
            Utils::Minimum(p + sizeof(uintptr_t), p + (char_length - i));
        for (; p < limit; p++) {
          uint8_t c = *p;
          // These calls to Length and Encode get inlined and the cases for 3
          // and 4 byte sequences are removed.
          intptr_t bytes = Length(c);
          if (pos + bytes > array_len) {
            return pos;
          }
          Encode(c, reinterpret_cast<char*>(dst) + pos);
          pos += bytes;
        }
      }
      data++;
    }
  } else {
    // For two-byte strings, which can contain 3 and 4-byte UTF-8 encodings,
    // which can result in surrogate pairs, use the more general code.
    String::CodePointIterator it(src);
    while (it.Next()) {
      int32_t ch = it.Current();
      ASSERT(!Utf::IsOutOfRange(ch));
      if (Utf16::IsSurrogate(ch)) {
        // Encode unpaired surrogates as replacement characters to ensure the
        // output is valid UTF-8. Encoded size is the same (3), so the computed
        // length is still valid.
        ch = Utf::kReplacementChar;
      }
      intptr_t num_bytes = Utf8::Length(ch);
      if (pos + num_bytes > len) {
        break;
      }
      Utf8::Encode(ch, &dst[pos]);
      pos += num_bytes;
    }
  }
  return pos;
}

}  // namespace dart
