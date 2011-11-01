// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/ast.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/unit_test.h"

namespace dart {

static const intptr_t kPos = 1;  // Dummy token index in non-existing source.


TEST_CASE(Ast) {
  const intptr_t kPos = 1;  // Dummy token index in non-existing source.
  LocalVariable* v = new LocalVariable(kPos,
                                       String::ZoneHandle(String::New("v")),
                                       Type::ZoneHandle(Type::DynamicType()));
  AstNode* ll = new LoadLocalNode(kPos, *v);
  EXPECT(ll->IsLoadLocalNode());
  EXPECT(!ll->IsLiteralNode());
  LoadLocalNode* lln = ll->AsLoadLocalNode();
  EXPECT(NULL != lln);
  v->set_index(1);
  EXPECT_EQ(1, v->index());

  LocalVariable* p = new LocalVariable(kPos,
                                       String::ZoneHandle(String::New("p")),
                                       Type::ZoneHandle(Type::DynamicType()));
  EXPECT(!p->HasIndex());
  p->set_index(-1);
  EXPECT(p->HasIndex());
  EXPECT_EQ(-1, p->index());

  ReturnNode* r = new ReturnNode(kPos, lln);
  EXPECT_EQ(lln, r->value());

  LiteralNode* l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3)));
  EXPECT(l->literal().IsSmi());
  EXPECT_EQ(Smi::New(3), l->literal().raw());

  BinaryOpNode* b = new BinaryOpNode(kPos, Token::kADD, l, lln);
  EXPECT_EQ(Token::kADD, b->kind());
  EXPECT_EQ(l, b->left());
  EXPECT_EQ(lln, b->right());

  UnaryOpNode* u = new UnaryOpNode(kPos, Token::kSUB, b);
  EXPECT_EQ(Token::kSUB, u->kind());
  EXPECT_EQ(b, u->operand());

  SequenceNode* sequence_node = new SequenceNode(1, new LocalScope(NULL, 0, 0));
  LiteralNode* literal_node = new LiteralNode(2,  Smi::ZoneHandle(Smi::New(3)));
  ReturnNode* return_node = new ReturnNode(3, literal_node);
  sequence_node->Add(return_node);
  GrowableArray<AstNode*> nodes;
  sequence_node->CollectAllNodes(&nodes);
  EXPECT_EQ(3, nodes.length());
}

}  // namespace dart
