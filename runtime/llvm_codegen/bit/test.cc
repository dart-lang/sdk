// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include <utility>
#include <vector>

#include "llvm/ADT/StringRef.h"
#include "llvm/Support/LineIterator.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/Regex.h"
#include "llvm/Support/WithColor.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

#define LIT_BINARY_DIR "/path/to/bins"
#include "bit.h"

UNIT_TEST_CASE(BasicGetSubstitutions) {
  Config config;
  config.filename = "/foo/bar/baz.ll";
  config.out_dir = "/test/out/dir";

  StringMap<std::string> expected;
  expected["s"] = "/foo/bar/baz.ll";
  expected["p"] = "/foo/bar";
  expected["P"] = "/test/out/dir";
  expected["t"] = "/test/out/dir/baz.ll.tmp";
  expected["codegen"] = "/path/to/bins/codegen";
  expected["bit"] = "/path/to/bins/bit";

  StringMap<std::string> actual = GetSubstitutions(config);

  EXPECT_EQ(actual.size(), expected.size());
  for (const auto& p : actual)
    EXPECT_EQ(p.getValue(), expected[p.getKey()]);
}

UNIT_TEST_CASE(BasicPerformSubstitutions) {
  StringMap<std::string> subs;
  subs["foo"] = "/foo/path";
  subs["bar"] = "/bar/path";
  subs["baz"] = "/baz/path";
  std::vector<std::pair<std::string, std::string>> cases = {
      {"%foo", "/foo/path"},
      {"%bar", "/bar/path"},
      {"%baz", "/baz/path"},
      {"this has %foo, and %bar, and %baz2",
       "this has /foo/path, and /bar/path, and /baz/path2"},
      {"we don't want %this to expand", "we don't want %this to expand"},
      {"%", "%"}};
  for (const auto& test : cases) {
    auto out = PerformSubstitutions(subs, test.first);
    EXPECT_EQ(out, test.second);
  }
}

UNIT_TEST_CASE(BasicGetCommand) {
  EXPECT(!GetCommand("; this is some test"));
  EXPECT(!GetCommand("2 + 2"));
  EXPECT(!GetCommand("echo $VAR > %bit"));

  EXPECT(GetCommand(";RUN: blarg") == Optional<std::string>{"blarg"});
  EXPECT(GetCommand(";      RUN:        foo") == Optional<std::string>{"blarg"});
  EXPECT(
      GetCommand("; RUN: echo %bit %p/Input/$(%t2) > $(baz \"$BAR->%t\")") ==
      Optional<std::string>("echo %bit %p/Input/$(%t2) > $(baz \"$BAR->%t\")"));
}
