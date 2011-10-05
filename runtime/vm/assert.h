// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSERT_H_
#define VM_ASSERT_H_

// TODO(5411406): include sstream for now, once we have a Utils::toString()
// implemented for all the primitive types we can replace the usage of
// sstream by Utils::toString()
#if defined(TESTING)
#include <sstream>
#include <string>
#endif

#include "vm/globals.h"

#if !defined(DEBUG) && !defined(NDEBUG)
#error neither DEBUG nor NDEBUG defined
#elif defined(DEBUG) && defined(NDEBUG)
#error both DEBUG and NDEBUG defined
#endif

namespace dart {

class DynamicAssertionHelper {
 public:
  enum Kind {
    ASSERT,
    EXPECT
  };

  DynamicAssertionHelper(const char* file, int line, Kind kind)
      : file_(file), line_(line), kind_(kind) { }

  void Fail(const char* format, ...);

#if defined(TESTING)
  template<typename E, typename A>
  void Equals(const E& expected, const A& actual);

  template<typename E, typename A, typename T>
  void FloatEquals(const E& expected, const A& actual, const T& tol);

  template<typename E, typename A>
  void StringEquals(const E& expected, const A& actual);

  template<typename E, typename A>
  void LessThan(const E& left, const A& right);

  template<typename E, typename A>
  void LessEqual(const E& left, const A& right);

  template<typename E, typename A>
  void GreaterThan(const E& left, const A& right);

  template<typename E, typename A>
  void GreaterEqual(const E& left, const A& right);
#endif

 private:
  const char* const file_;
  const int line_;
  const Kind kind_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(DynamicAssertionHelper);
};


class Assert: public DynamicAssertionHelper {
 public:
  Assert(const char* file, int line)
      : DynamicAssertionHelper(file, line, ASSERT) { }
};


class Expect: public DynamicAssertionHelper {
 public:
  Expect(const char* file, int line)
      : DynamicAssertionHelper(file, line, EXPECT) { }
};


#if defined(TESTING)
// Only allow the expensive (with respect to code size) assertions
// in testing code.
template<typename E, typename A>
void DynamicAssertionHelper::Equals(const E& expected, const A& actual) {
  if (actual == expected) return;
  std::stringstream ess, ass;
  ess << expected;
  ass << actual;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: <%s> but was: <%s>", es.c_str(), as.c_str());
}


template<typename E, typename A, typename T>
void DynamicAssertionHelper::FloatEquals(const E& expected,
                                         const A& actual,
                                         const T& tol) {
  if (((expected - tol) <= actual) && (actual <= (expected + tol))) {
    return;
  }
  std::stringstream ess, ass, tolss;
  ess << expected;
  ass << actual;
  tolss << tol;
  std::string es = ess.str(), as = ass.str(), tols = tolss.str();
  Fail("expected: <%s> but was: <%s> (tolerance: <%s>)",
       es.c_str(),
       as.c_str(),
       tols.c_str());
}


template<typename E, typename A>
void DynamicAssertionHelper::StringEquals(const E& expected, const A& actual) {
  std::stringstream ess, ass;
  ess << expected;
  ass << actual;
  std::string es = ess.str(), as = ass.str();
  if (as == es) return;
  Fail("expected: <\"%s\"> but was: <\"%s\">", es.c_str(), as.c_str());
}


template<typename E, typename A>
void DynamicAssertionHelper::LessThan(const E& left, const A& right) {
  if (left < right) return;
  std::stringstream ess, ass;
  ess << left;
  ass << right;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: %s < %s", es.c_str(), as.c_str());
}


template<typename E, typename A>
void DynamicAssertionHelper::LessEqual(const E& left, const A& right) {
  if (left <= right) return;
  std::stringstream ess, ass;
  ess << left;
  ass << right;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: %s <= %s", es.c_str(), as.c_str());
}


template<typename E, typename A>
void DynamicAssertionHelper::GreaterThan(const E& left, const A& right) {
  if (left > right) return;
  std::stringstream ess, ass;
  ess << left;
  ass << right;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: %s > %s", es.c_str(), as.c_str());
}


template<typename E, typename A>
void DynamicAssertionHelper::GreaterEqual(const E& left, const A& right) {
  if (left >= right) return;
  std::stringstream ess, ass;
  ess << left;
  ass << right;
  std::string es = ess.str(), as = ass.str();
  Fail("expected: %s >= %s", es.c_str(), as.c_str());
}
#endif

}  // namespace dart


#define FATAL(error)                                                           \
  dart::Assert(__FILE__, __LINE__).Fail("%s", error)

#define FATAL1(format, p1)                                                     \
  dart::Assert(__FILE__, __LINE__).Fail(format, (p1))

#define FATAL2(format, p1, p2)                                                 \
  dart::Assert(__FILE__, __LINE__).Fail(format, (p1), (p2))

#define UNIMPLEMENTED()                                                        \
  FATAL("unimplemented code")

#define UNREACHABLE()                                                          \
  FATAL("unreachable code")


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
#define DEBUG_ASSERT(cond)                                                     \
  if (!(cond)) dart::Assert(__FILE__, __LINE__).Fail("expected: %s", #cond);

#else  // if defined(DEBUG)

// In order to avoid variable unused warnings for code that only uses
// a variable in an ASSERT or EXPECT, we make sure to use the macro
// argument.
#define ASSERT(condition) do {} while (false && (condition))

#define DEBUG_ASSERT(cond)

#endif  // if defined(DEBUG)


#if defined(TESTING)
#define EXPECT(condition)                                                      \
  if (!(condition)) {                                                          \
    dart::Expect(__FILE__, __LINE__).Fail("expected: %s", #condition);         \
  }

#define EXPECT_EQ(expected, actual)                                            \
  dart::Expect(__FILE__, __LINE__).Equals((expected), (actual))

#define EXPECT_FLOAT_EQ(expected, actual, tol)                                 \
  dart::Expect(__FILE__, __LINE__).FloatEquals((expected), (actual), (tol))

#define EXPECT_STREQ(expected, actual)                                         \
  dart::Expect(__FILE__, __LINE__).StringEquals((expected), (actual))

#define EXPECT_LT(left, right)                                                 \
  dart::Expect(__FILE__, __LINE__).LessThan((left), (right))

#define EXPECT_LE(left, right)                                                 \
  dart::Expect(__FILE__, __LINE__).LessEqual((left), (right))

#define EXPECT_GT(left, right)                                                 \
  dart::Expect(__FILE__, __LINE__).GreaterThan((left), (right))

#define EXPECT_GE(left, right)                                                 \
  dart::Expect(__FILE__, __LINE__).GreaterEqual((left), (right))
#endif

// TODO(iposva): provide a better way to get extra info on an EXPECT
// fail - you suggested EXPECT_EQ(expected, actual, msg_format,
// parameters_for_msg...), I quite like the google3 method
// EXPECT_EQ(a, b) << "more stuff here...". (benl).

#define WARN(error)                                                           \
  dart::Expect(__FILE__, __LINE__).Fail("%s", error)

#define WARN1(format, p1)                                                     \
  dart::Expect(__FILE__, __LINE__).Fail(format, (p1))

#define WARN2(format, p1, p2)                                                 \
  dart::Expect(__FILE__, __LINE__).Fail(format, (p1), (p2))

#endif  // VM_ASSERT_H_
