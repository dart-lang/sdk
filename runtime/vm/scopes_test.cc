// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scopes.h"
#include "platform/assert.h"
#include "vm/ast.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(LocalScope) {
  // Allocate a couple of local variables first.
  const Type& dynamic_type = Type::ZoneHandle(Type::DynamicType());
  const String& a = String::ZoneHandle(Symbols::New(thread, "a"));
  LocalVariable* var_a = new LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, a, dynamic_type);
  LocalVariable* inner_var_a = new LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, a, dynamic_type);
  const String& b = String::ZoneHandle(Symbols::New(thread, "b"));
  LocalVariable* var_b = new LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, b, dynamic_type);
  const String& c = String::ZoneHandle(Symbols::New(thread, "c"));
  LocalVariable* var_c = new LocalVariable(
      TokenPosition::kNoSource, TokenPosition::kNoSource, c, dynamic_type);
  const String& L = String::ZoneHandle(Symbols::New(thread, "L"));
  SourceLabel* label_L =
      new SourceLabel(TokenPosition::kNoSource, L, SourceLabel::kFor);

  LocalScope* outer_scope = new LocalScope(NULL, 0, 0);
  LocalScope* inner_scope1 = new LocalScope(outer_scope, 0, 0);
  LocalScope* inner_scope2 = new LocalScope(outer_scope, 0, 0);

  EXPECT(outer_scope->parent() == NULL);
  EXPECT_EQ(outer_scope, inner_scope1->parent());
  EXPECT_EQ(outer_scope, inner_scope2->parent());
  EXPECT_EQ(inner_scope2, outer_scope->child());
  EXPECT_EQ(inner_scope1, inner_scope2->sibling());
  EXPECT(inner_scope1->child() == NULL);
  EXPECT(inner_scope2->child() == NULL);

  // Populate the local scopes as follows:
  // {  // outer_scope
  //   var a;
  //   {  // inner_scope1
  //     var b;
  //   }
  //   L: {  // inner_scope2
  //     var c;
  //   }
  // }
  EXPECT(outer_scope->AddVariable(var_a));
  EXPECT(inner_scope1->AddVariable(var_b));
  EXPECT(inner_scope2->AddVariable(var_c));
  EXPECT(inner_scope2->AddLabel(label_L));
  EXPECT(!outer_scope->AddVariable(var_a));

  // Check the simple layout above.
  EXPECT_EQ(var_a, outer_scope->LocalLookupVariable(a));
  EXPECT_EQ(var_a, inner_scope1->LookupVariable(a, true));
  EXPECT_EQ(label_L, inner_scope2->LookupLabel(L));
  EXPECT(outer_scope->LocalLookupVariable(b) == NULL);
  EXPECT(inner_scope1->LocalLookupVariable(c) == NULL);

  // Modify the local scopes to contain shadowing:
  // {  // outer_scope
  //   var a;
  //   {  // inner_scope1
  //     var b;
  //     var a;  // inner_var_a
  //   }
  //   {  // inner_scope2
  //     var c;
  //     L: ...
  //   }
  // }
  EXPECT(inner_scope1->AddVariable(inner_var_a));
  EXPECT_EQ(inner_var_a, inner_scope1->LookupVariable(a, true));
  EXPECT(inner_scope1->LookupVariable(a, true) != var_a);

  // Modify the local scopes with access of an outer scope variable:
  // {  // outer_scope
  //   var a;
  //   {  // inner_scope1
  //     var b;
  //     var a;  // inner_var_a
  //   }
  //   {  // inner_scope2
  //     var c = a;
  //     L: ...
  //   }
  // }
  EXPECT(inner_scope2->LocalLookupVariable(a) == NULL);
  EXPECT(inner_scope2->AddVariable(var_a));
  EXPECT_EQ(var_a, inner_scope2->LocalLookupVariable(a));

  EXPECT_EQ(1, outer_scope->num_variables());
  EXPECT_EQ(2, inner_scope1->num_variables());
  EXPECT_EQ(2, inner_scope2->num_variables());

  // Cannot depend on the order, but we should find the variables.
  EXPECT(outer_scope->VariableAt(0) == var_a);
  EXPECT((inner_scope1->VariableAt(0) == inner_var_a) ||
         (inner_scope1->VariableAt(1) == inner_var_a));
  EXPECT((inner_scope1->VariableAt(0) == var_b) ||
         (inner_scope1->VariableAt(1) == var_b));
  EXPECT((inner_scope2->VariableAt(0) == var_a) ||
         (inner_scope2->VariableAt(1) == var_a) ||
         (inner_scope2->VariableAt(2) == var_a));
  EXPECT((inner_scope2->VariableAt(0) == var_c) ||
         (inner_scope2->VariableAt(1) == var_c) ||
         (inner_scope2->VariableAt(2) == var_c));
}

}  // namespace dart
