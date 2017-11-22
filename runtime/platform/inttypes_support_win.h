// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_INTTYPES_SUPPORT_WIN_H_
#define RUNTIME_PLATFORM_INTTYPES_SUPPORT_WIN_H_

typedef signed __int8 int8_t;
typedef signed __int16 int16_t;
typedef signed __int32 int32_t;
typedef signed __int64 int64_t;
typedef unsigned __int8 uint8_t;
typedef unsigned __int16 uint16_t;
typedef unsigned __int32 uint32_t;
typedef unsigned __int64 uint64_t;

// Printf format specifiers for intptr_t and uintptr_t.
#define PRIdPTR "Id"
#define PRIuPTR "Iu"
#define PRIxPTR "Ix"
#define PRIXPTR "IX"

// Printf format specifiers for int64_t and uint64_t.
#define PRId64 "I64d"
#define PRIu64 "I64u"
#define PRIx64 "I64x"
#define PRIX64 "I64X"

// Printf format specifiers for int32_t and uint32_t.
#define PRId32 "I32d"
#define PRIu32 "I32u"
#define PRIx32 "I32x"
#define PRIX32 "I32X"

// Printf format specifiers for int16_t and uint16_t.
#define PRId16 "I16d"
#define PRIu16 "I16u"
#define PRIx16 "I16x"
#define PRIX16 "I16X"

// Printf format specifiers for int8_t and uint8_t.
#define PRId8 "I8d"
#define PRIu8 "I8u"
#define PRIx8 "I8x"
#define PRIX8 "I8X"

#endif  // RUNTIME_PLATFORM_INTTYPES_SUPPORT_WIN_H_
