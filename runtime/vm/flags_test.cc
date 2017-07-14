// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flags.h"
#include "platform/assert.h"
#include "vm/heap.h"
#include "vm/unit_test.h"

namespace dart {

DEFINE_FLAG(bool, basic_flag, true, "Testing of a basic boolean flag.");

DECLARE_FLAG(bool, print_flags);

VM_UNIT_TEST_CASE(BasicFlags) {
  EXPECT_EQ(true, FLAG_basic_flag);
  EXPECT_EQ(false, FLAG_verbose_gc);
  EXPECT_EQ(false, FLAG_print_flags);
}

DEFINE_FLAG(bool, parse_flag_bool_test, true, "Flags::Parse (bool) testing");
DEFINE_FLAG(charp, string_opt_test, NULL, "Testing: string option.");
DEFINE_FLAG(charp, entrypoint_test, "main", "Testing: entrypoint");
DEFINE_FLAG(int, counter, 100, "Testing: int flag");

VM_UNIT_TEST_CASE(ParseFlags) {
  EXPECT_EQ(true, FLAG_parse_flag_bool_test);
  Flags::Parse("no_parse_flag_bool_test");
  EXPECT_EQ(false, FLAG_parse_flag_bool_test);
  Flags::Parse("parse_flag_bool_test");
  EXPECT_EQ(true, FLAG_parse_flag_bool_test);
  Flags::Parse("parse_flag_bool_test=false");
  EXPECT_EQ(false, FLAG_parse_flag_bool_test);
  Flags::Parse("parse_flag_bool_test=true");
  EXPECT_EQ(true, FLAG_parse_flag_bool_test);

  EXPECT_EQ(true, FLAG_string_opt_test == NULL);
  Flags::Parse("string_opt_test=doobidoo");
  EXPECT_EQ(true, FLAG_string_opt_test != NULL);
  EXPECT_EQ(0, strcmp(FLAG_string_opt_test, "doobidoo"));

  EXPECT_EQ(true, FLAG_entrypoint_test != NULL);
  EXPECT_EQ(0, strcmp(FLAG_entrypoint_test, "main"));

  EXPECT_EQ(100, FLAG_counter);
  Flags::Parse("counter=-300");
  EXPECT_EQ(-300, FLAG_counter);
  Flags::Parse("counter=$300");
  EXPECT_EQ(-300, FLAG_counter);
}

}  // namespace dart
