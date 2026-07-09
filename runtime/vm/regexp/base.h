// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REGEXP_BASE_H_
#define RUNTIME_VM_REGEXP_BASE_H_

#include <cstring>
#include <limits>
#include <type_traits>

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/unicode.h"

#define DCHECK(x) DEBUG_ASSERT(x)
#define DCHECK_NULL(x) DEBUG_ASSERT((x) == nullptr)
#define DCHECK_NOT_NULL(x) DEBUG_ASSERT((x) != nullptr)
#define DCHECK_EQ(a, b) DEBUG_ASSERT((a) == (b))
#define DCHECK_NE(a, b) DEBUG_ASSERT((a) != (b))
#define DCHECK_LT(a, b) DEBUG_ASSERT((a) < (b))
#define DCHECK_GT(a, b) DEBUG_ASSERT((a) > (b))
#define DCHECK_LE(a, b) DEBUG_ASSERT((a) <= (b))
#define DCHECK_GE(a, b) DEBUG_ASSERT((a) >= (b))
#define DCHECK_IMPLIES(a, b) DEBUG_ASSERT(!(a) || (b))

#define CHECK(x) RELEASE_ASSERT(x)
#define CHECK_EQ(a, b) RELEASE_ASSERT((a) == (b))
#define CHECK_NE(a, b) RELEASE_ASSERT((a) != (b))
#define CHECK_LT(a, b) RELEASE_ASSERT((a) < (b))
#define CHECK_GT(a, b) RELEASE_ASSERT((a) > (b))
#define CHECK_LE(a, b) RELEASE_ASSERT((a) <= (b))
#define CHECK_GE(a, b) RELEASE_ASSERT((a) >= (b))
#define CHECK_IMPLIES(a, b) RELEASE_ASSERT(!(a) || (b))

#define SBXCHECK(x) RELEASE_ASSERT(x)
#define SBXCHECK_LT(a, b) RELEASE_ASSERT((a) < (b))
#define SBXCHECK_GT(a, b) RELEASE_ASSERT((a) > (b))
#define SBXCHECK_LE(a, b) RELEASE_ASSERT((a) <= (b))
#define SBXCHECK_GE(a, b) RELEASE_ASSERT((a) >= (b))

#define V8_INLINE DART_FORCE_INLINE
#define V8_NOINLINE DART_NOINLINE
#define V8_NOEXCEPT
#define V8_PRESERVE_MOST
#define V8_LIKELY LIKELY
#define V8_UNLIKELY UNLIKELY
#define V8_ASSUME(x)
#define V8_NODISCARD [[nodiscard]]
#define V8_INTL_SUPPORT 1
#define V8_ALLOW_UNUSED DART_UNUSED
#define V8_WARN_UNUSED_RESULT DART_WARN_UNUSED_RESULT
#define COMPILING_IRREGEXP_FOR_EXTERNAL_EMBEDDER 1

#ifdef DART_HAS_COMPUTED_GOTO
#define V8_HAS_COMPUTED_GOTO 1
#define V8_ENABLE_REGEXP_INTERPRETER_THREADED_DISPATCH 1
#endif

#define CONCAT_(a, ...) a##__VA_ARGS__
#define CONCAT(a, ...) CONCAT_(a, __VA_ARGS__)

// COUNT_MACRO_ARGS(...) returns the number of arguments passed. Currently, up
// to 8 arguments are supported.
#define COUNT_MACRO_ARGS(...)                                                  \
  EXPAND(COUNT_MACRO_ARGS_IMPL(__VA_ARGS__, 8, 7, 6, 5, 4, 3, 2, 1, 0))
#define COUNT_MACRO_ARGS_IMPL(_8, _7, _6, _5, _4, _3, _2, _1, N, ...) N
// GET_NTH_ARG(N, ...) returns the Nth argument in the list of arguments
// following. Currently, up to N=8 is supported.
#define GET_NTH_ARG(N, ...) CONCAT(GET_NTH_ARG_IMPL_, N)(__VA_ARGS__)
#define GET_NTH_ARG_IMPL_0(_0, ...) _0
#define GET_NTH_ARG_IMPL_1(_0, _1, ...) _1
#define GET_NTH_ARG_IMPL_2(_0, _1, _2, ...) _2
#define GET_NTH_ARG_IMPL_3(_0, _1, _2, _3, ...) _3
#define GET_NTH_ARG_IMPL_4(_0, _1, _2, _3, _4, ...) _4
#define GET_NTH_ARG_IMPL_5(_0, _1, _2, _3, _4, _5, ...) _5
#define GET_NTH_ARG_IMPL_6(_0, _1, _2, _3, _4, _5, _6, ...) _6
#define GET_NTH_ARG_IMPL_7(_0, _1, _2, _3, _4, _5, _6, _7, ...) _7

// Expands to true if __VA_ARGS__ is empty, false otherwise.
#define IS_VA_EMPTY(...) GET_NTH_ARG(0, __VA_OPT__(false, ) true)

// UNPAREN(x) removes a layer of nested parentheses on x, if any. This means
// that both UNPAREN(x) and UNPAREN((x)) expand to x. This is helpful for macros
// that want to support multi argument templates with commas, e.g.
//
//   #define FOO(Type, Name) UNPAREN(Type) Name;
//
// will work with both
//
//   FOO(int, x);
//   FOO((Foo<int, double, float>), x);
#define UNPAREN(X) CONCAT(DROP_, UNPAREN_ X)
#define UNPAREN_(...) UNPAREN_ __VA_ARGS__
#define DROP_UNPAREN_

// clang-format off
#define INT_0_TO_127_LIST(V)                                          \
V(0)   V(1)   V(2)   V(3)   V(4)   V(5)   V(6)   V(7)   V(8)   V(9)   \
V(10)  V(11)  V(12)  V(13)  V(14)  V(15)  V(16)  V(17)  V(18)  V(19)  \
V(20)  V(21)  V(22)  V(23)  V(24)  V(25)  V(26)  V(27)  V(28)  V(29)  \
V(30)  V(31)  V(32)  V(33)  V(34)  V(35)  V(36)  V(37)  V(38)  V(39)  \
V(40)  V(41)  V(42)  V(43)  V(44)  V(45)  V(46)  V(47)  V(48)  V(49)  \
V(50)  V(51)  V(52)  V(53)  V(54)  V(55)  V(56)  V(57)  V(58)  V(59)  \
V(60)  V(61)  V(62)  V(63)  V(64)  V(65)  V(66)  V(67)  V(68)  V(69)  \
V(70)  V(71)  V(72)  V(73)  V(74)  V(75)  V(76)  V(77)  V(78)  V(79)  \
V(80)  V(81)  V(82)  V(83)  V(84)  V(85)  V(86)  V(87)  V(88)  V(89)  \
V(90)  V(91)  V(92)  V(93)  V(94)  V(95)  V(96)  V(97)  V(98)  V(99)  \
V(100) V(101) V(102) V(103) V(104) V(105) V(106) V(107) V(108) V(109) \
V(110) V(111) V(112) V(113) V(114) V(115) V(116) V(117) V(118) V(119) \
V(120) V(121) V(122) V(123) V(124) V(125) V(126) V(127)
// clang-format on

namespace base {

using uc16 = uint16_t;
using uc32 = uint32_t;
constexpr int kUC16Size = sizeof(uc16);

// Returns the value (0 .. 15) of a hexadecimal character c.
// If c is not a legal hexadecimal character, returns a value < 0.
inline int HexValue(uc32 c) {
  c -= '0';
  if (static_cast<unsigned>(c) <= 9) return c;
  c = (c | 0x20) - ('a' - '0');  // detect 0x11..0x16 and 0x31..0x36.
  if (static_cast<unsigned>(c) <= 5) return c + 10;
  return -1;
}

template <typename D, typename S>
D saturated_cast(S in) {
  if (in < std::numeric_limits<D>::min()) {
    return std::numeric_limits<D>::min();
  }
  if (in > std::numeric_limits<D>::max()) {
    return std::numeric_limits<D>::max();
  }
  return static_cast<D>(in);
}

// Checks if value is in range [lower_limit, higher_limit] using a single
// branch.
template <typename T, typename U>
  requires((std::is_integral_v<T> || std::is_enum_v<T>) &&
           (std::is_integral_v<U> || std::is_enum_v<U>)) &&
          (sizeof(U) <= sizeof(T))
inline constexpr bool IsInRange(T value, U lower_limit, U higher_limit) {
  ASSERT(lower_limit <= higher_limit);
  using unsigned_T = std::make_unsigned_t<T>;
  // Use static_cast to support enum classes.
  return static_cast<unsigned_T>(static_cast<unsigned_T>(value) -
                                 static_cast<unsigned_T>(lower_limit)) <=
         static_cast<unsigned_T>(static_cast<unsigned_T>(higher_limit) -
                                 static_cast<unsigned_T>(lower_limit));
}

};  // namespace base

namespace dart {

using Address = uintptr_t;

constexpr bool FLAG_correctness_fuzzer_suppressions = false;
constexpr bool FLAG_regexp_possessive_quantifier = false;
constexpr bool FLAG_js_regexp_modifiers = true;
constexpr bool FLAG_js_regexp_duplicate_named_groups = true;
constexpr bool FLAG_trace_regexp_parser = false;
constexpr bool FLAG_regexp_unroll = false;
constexpr bool FLAG_regexp_optimization = false;
constexpr bool FLAG_regexp_quick_check = true;
constexpr bool FLAG_regexp_tier_up = false;
constexpr bool FLAG_regexp_peephole_optimization = false;

class JSRegExp {
 public:
  static constexpr uint32_t kNoBacktrackLimit = 0;
  static constexpr int RegistersForCaptureCount(int count) {
    return (count + 1) * 2;
  }
};

class DisallowGarbageCollection {};

// Compare 8bit/16bit chars to 8bit/16bit chars.
template <typename lchar, typename rchar>
inline bool CompareCharsEqualUnsigned(const lchar* lhs,
                                      const rchar* rhs,
                                      size_t chars) {
  static_assert(std::is_unsigned_v<lchar>);
  static_assert(std::is_unsigned_v<rchar>);
  if constexpr (sizeof(*lhs) == sizeof(*rhs)) {
    // memcmp compares byte-by-byte, but for equality it doesn't matter whether
    // two-byte char comparison is little- or big-endian.
    return memcmp(lhs, rhs, chars * sizeof(*lhs)) == 0;
  }
  for (const lchar* limit = lhs + chars; lhs < limit; ++lhs, ++rhs) {
    if (*lhs != *rhs) return false;
  }
  return true;
}

template <typename lchar, typename rchar>
inline bool CompareCharsEqual(const lchar* lhs,
                              const rchar* rhs,
                              size_t chars) {
  using ulchar = std::make_unsigned_t<lchar>;
  using urchar = std::make_unsigned_t<rchar>;
  return CompareCharsEqualUnsigned(reinterpret_cast<const ulchar*>(lhs),
                                   reinterpret_cast<const urchar*>(rhs), chars);
}

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_BASE_H_
