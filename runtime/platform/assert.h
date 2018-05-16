// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_ASSERT_H_
#define RUNTIME_PLATFORM_ASSERT_H_

// TODO(5411406): include sstream for now, once we have a Utils::toString()
// implemented for all the primitive types we can replace the usage of
// sstream by Utils::toString()
#if defined(TESTING)
#include <sstream>
#include <string>
#endif

#include "platform/globals.h"
#include "platform/memory_sanitizer.h"

#if !defined(DEBUG) && !defined(NDEBUG)
#error neither DEBUG nor NDEBUG defined
#elif defined(DEBUG) && defined(NDEBUG)
#error both DEBUG and NDEBUG defined
#endif

namespace dart {

class DynamicAssertionHelper {
 public:
  DynamicAssertionHelper(const char* file, int line)
      : file_(file), line_(line) {}

 protected:
  void Print(const char* format, va_list arguments);

  const char* const file_;
  const int line_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(DynamicAssertionHelper);
};

class Assert : public DynamicAssertionHelper {
 public:
  Assert(const char* file, int line) : DynamicAssertionHelper(file, line) {}

  DART_NORETURN void Fail(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  template <typename T>
  T NotNull(const T p);
};

class Expect : public DynamicAssertionHelper {
 public:
  Expect(const char* file, int line) : DynamicAssertionHelper(file, line) {}

  void Fail(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

#if defined(TESTING)
  template <typename E, typename A>
  void Equals(const E& expected, const A& actual);

  template <typename E, typename A>
  void NotEquals(const E& not_expected, const A& actual);

  template <typename E, typename A, typename T>
  void FloatEquals(const E& expected, const A& actual, const T& tol);

  template <typename E, typename A>
  void StringEquals(const E& expected, const A& actual);

  template <typename E, typename A>
  void IsSubstring(const E& needle, const A& haystack);

  template <typename E, typename A>
  void IsNotSubstring(const E& needle, const A& haystack);

  template <typename E, typename A>
  void LessThan(const E& left, const A& right);

  template <typename E, typename A>
  void LessEqual(const E& left, const A& right);

  template <typename E, typename A>
  void GreaterThan(const E& left, const A& right);

  template <typename E, typename A>
  void GreaterEqual(const E& left, const A& right);

  template <typename T>
  T NotNull(const T p);
#endif

  static bool failed() { return failed_; }

 private:
  static bool failed_;
};

template <typename T>
T Assert::NotNull(const T p) {
  if (p != NULL) return p;
  Fail("expected: not NULL, found NULL");
  return NULL;
}

#if defined(TESTING)
// Only allow the expensive (with respect to code size) assertions
// in testing code.
template <typename E, typename A>
void Expect::Equals(const E& expected, const A& actual) {
  if (actual == expected) return;
  std::ostringstream ess, ass;
  ess << expected;
  ass << actual;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: <%s> but was: <%s>", es.c_str(), as.c_str());
}

template <typename E, typename A>
void Expect::NotEquals(const E& not_expected, const A& actual) {
  if (actual != not_expected) return;
  std::ostringstream ness;
  ness << not_expected;
  std::string nes = ness.str();
  Fail("did not expect: <%s>", nes.c_str());
}

template <typename E, typename A, typename T>
void Expect::FloatEquals(const E& expected, const A& actual, const T& tol) {
  if (((expected - tol) <= actual) && (actual <= (expected + tol))) {
    return;
  }
  std::ostringstream ess, ass, tolss;
  ess << expected;
  ass << actual;
  tolss << tol;
  std::string es = ess.str(), as = ass.str(), tols = tolss.str();
  Fail("expected: <%s> but was: <%s> (tolerance: <%s>)", es.c_str(), as.c_str(),
       tols.c_str());
}

template <typename E, typename A>
NO_SANITIZE_MEMORY void Expect::StringEquals(const E& expected,
                                             const A& actual) {
  std::ostringstream ess, ass;
  ess << expected;
  ass << actual;
  std::string es = ess.str(), as = ass.str();
  if (as == es) return;
  Fail("expected:\n<\"%s\">\nbut was:\n<\"%s\">", es.c_str(), as.c_str());
}

template <typename E, typename A>
NO_SANITIZE_MEMORY void Expect::IsSubstring(const E& needle,
                                            const A& haystack) {
  std::ostringstream ess, ass;
  ess << needle;
  ass << haystack;
  std::string es = ess.str(), as = ass.str();
  if (as.find(es) != std::string::npos) return;
  Fail("expected <\"%s\"> to be a substring of <\"%s\">", es.c_str(),
       as.c_str());
}

template <typename E, typename A>
NO_SANITIZE_MEMORY void Expect::IsNotSubstring(const E& needle,
                                               const A& haystack) {
  std::ostringstream ess, ass;
  ess << needle;
  ass << haystack;
  std::string es = ess.str(), as = ass.str();
  if (as.find(es) == std::string::npos) return;
  Fail("expected <\"%s\"> to not be a substring of <\"%s\">", es.c_str(),
       as.c_str());
}

template <typename E, typename A>
void Expect::LessThan(const E& left, const A& right) {
  if (left < right) return;
  std::ostringstream ess, ass;
  ess << left;
  ass << right;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: %s < %s", es.c_str(), as.c_str());
}

template <typename E, typename A>
void Expect::LessEqual(const E& left, const A& right) {
  if (left <= right) return;
  std::ostringstream ess, ass;
  ess << left;
  ass << right;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: %s <= %s", es.c_str(), as.c_str());
}

template <typename E, typename A>
void Expect::GreaterThan(const E& left, const A& right) {
  if (left > right) return;
  std::ostringstream ess, ass;
  ess << left;
  ass << right;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: %s > %s", es.c_str(), as.c_str());
}

template <typename E, typename A>
void Expect::GreaterEqual(const E& left, const A& right) {
  if (left >= right) return;
  std::ostringstream ess, ass;
  ess << left;
  ass << right;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: %s >= %s", es.c_str(), as.c_str());
}

template <typename T>
T Expect::NotNull(const T p) {
  if (p != NULL) return p;
  Fail("expected: not NULL, found NULL");
  return NULL;
}
#endif

}  // namespace dart

#define FATAL(error) dart::Assert(__FILE__, __LINE__).Fail("%s", error)

#define FATAL1(format, p1) dart::Assert(__FILE__, __LINE__).Fail(format, (p1))

#define FATAL2(format, p1, p2)                                                 \
  dart::Assert(__FILE__, __LINE__).Fail(format, (p1), (p2))

#define FATAL3(format, p1, p2, p3)                                             \
  dart::Assert(__FILE__, __LINE__).Fail(format, (p1), (p2), (p3))

#define UNIMPLEMENTED() FATAL("unimplemented code")

#define UNREACHABLE() FATAL("unreachable code")

#define OUT_OF_MEMORY() FATAL("Out of memory.")

#if defined(DEBUG)
// DEBUG binaries use assertions in the code.
// Note: We wrap the if statement in a do-while so that we get a compile
//       error if there is no semicolon after ASSERT(condition). This
//       ensures that we get the same behavior on DEBUG and RELEASE builds.

#define ASSERT(cond)                                                           \
  do {                                                                         \
    if (!(cond)) dart::Assert(__FILE__, __LINE__).Fail("expected: %s", #cond); \
  } while (false)

// DEBUG_ASSERT allows identifiers in condition to be undeclared in release
// mode.
#define DEBUG_ASSERT(cond) ASSERT(cond)

// Returns 'ptr'; useful for initializer lists:
//   class Foo { Foo(int* ptr) : ptr_(ASSERT_NOTNULL(ptr)) ...
#define ASSERT_NOTNULL(ptr) dart::Assert(__FILE__, __LINE__).NotNull((ptr))

#else  // if defined(DEBUG)

// In order to avoid variable unused warnings for code that only uses
// a variable in an ASSERT or EXPECT, we make sure to use the macro
// argument.
#define ASSERT(condition)                                                      \
  do {                                                                         \
  } while (false && (condition))

#define DEBUG_ASSERT(cond)

#define ASSERT_NOTNULL(ptr) (ptr)

#endif  // if defined(DEBUG)

#define RELEASE_ASSERT(cond)                                                   \
  do {                                                                         \
    if (!(cond)) dart::Assert(__FILE__, __LINE__).Fail("expected: %s", #cond); \
  } while (false)

// The COMPILE_ASSERT macro can be used to verify that a compile time
// expression is true. For example, you could use it to verify the
// size of a static array:
//
//   COMPILE_ASSERT(ARRAYSIZE(content_type_names) == CONTENT_NUM_TYPES);
//
// or to make sure a struct is smaller than a certain size:
//
//   COMPILE_ASSERT(sizeof(foo) < 128);
//

template <bool>
struct CompileAssert {};
// Macro to concatenate two tokens. The helper is need to proper expansion
// in case an argument is a macro itself.
#if !defined(COMPILE_ASSERT)
#define COMPILE_ASSERT_JOIN(a, b) COMPILE_ASSERT_JOIN_HELPER(a, b)
#define COMPILE_ASSERT_JOIN_HELPER(a, b) a##b
#define COMPILE_ASSERT(expr)                                                   \
  DART_UNUSED typedef CompileAssert<(static_cast<bool>(expr))>                 \
      COMPILE_ASSERT_JOIN(CompileAssertTypeDef,                                \
                          __LINE__)[static_cast<bool>(expr) ? 1 : -1]
#endif  // !defined(COMPILE_ASSERT)

#if defined(TESTING)

// EXPECT and FAIL are equivalent to ASSERT and FATAL except that they do not
// cause early termination of the unit test. This allows testing to proceed
// further to be able to report other failures before reporting the overall
// unit tests as failing.

#define EXPECT(condition)                                                      \
  if (!(condition)) {                                                          \
    dart::Expect(__FILE__, __LINE__).Fail("expected: %s", #condition);         \
  }

#define EXPECT_EQ(expected, actual)                                            \
  dart::Expect(__FILE__, __LINE__).Equals((expected), (actual))

#define EXPECT_NE(not_expected, actual)                                        \
  dart::Expect(__FILE__, __LINE__).NotEquals((not_expected), (actual))

#define EXPECT_FLOAT_EQ(expected, actual, tol)                                 \
  dart::Expect(__FILE__, __LINE__).FloatEquals((expected), (actual), (tol))

#define EXPECT_STREQ(expected, actual)                                         \
  dart::Expect(__FILE__, __LINE__).StringEquals((expected), (actual))

#define EXPECT_SUBSTRING(needle, haystack)                                     \
  dart::Expect(__FILE__, __LINE__).IsSubstring((needle), (haystack))

#define EXPECT_NOTSUBSTRING(needle, haystack)                                  \
  dart::Expect(__FILE__, __LINE__).IsNotSubstring((needle), (haystack))

#define EXPECT_LT(left, right)                                                 \
  dart::Expect(__FILE__, __LINE__).LessThan((left), (right))

#define EXPECT_LE(left, right)                                                 \
  dart::Expect(__FILE__, __LINE__).LessEqual((left), (right))

#define EXPECT_GT(left, right)                                                 \
  dart::Expect(__FILE__, __LINE__).GreaterThan((left), (right))

#define EXPECT_GE(left, right)                                                 \
  dart::Expect(__FILE__, __LINE__).GreaterEqual((left), (right))

#define EXPECT_NOTNULL(ptr) dart::Expect(__FILE__, __LINE__).NotNull((ptr))

#define FAIL(error) dart::Expect(__FILE__, __LINE__).Fail("%s", error)

#define FAIL1(format, p1) dart::Expect(__FILE__, __LINE__).Fail(format, (p1))

#define FAIL2(format, p1, p2)                                                  \
  dart::Expect(__FILE__, __LINE__).Fail(format, (p1), (p2))

#endif  // defined(TESTING)

#endif  // RUNTIME_PLATFORM_ASSERT_H_
