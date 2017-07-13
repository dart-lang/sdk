// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast_printer.h"
#include "platform/assert.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

TEST_CASE(AstPrinter) {
  const TokenPosition kPos = TokenPosition::kNoSource;
  LocalVariable* v = new LocalVariable(
      kPos, kPos, String::ZoneHandle(Symbols::New(thread, "wurscht")),
      Type::ZoneHandle(Type::DynamicType()));
  v->set_index(5);
  AstPrinter ast_printer;
  LoadLocalNode* ll = new LoadLocalNode(kPos, v);
  ReturnNode* r = new ReturnNode(kPos, ll);
  ast_printer.PrintNode(r);

  AstNode* l = new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3)));
  ReturnNode* rl = new ReturnNode(kPos, l);
  ast_printer.PrintNode(rl);

  ast_printer.PrintNode(new ReturnNode(kPos));

  ast_printer.PrintNode(new BinaryOpNode(
      kPos, Token::kADD, new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(3))),
      new LiteralNode(kPos, Smi::ZoneHandle(Smi::New(5)))));
  ast_printer.PrintNode(new UnaryOpNode(kPos, Token::kNEGATE, ll));
}

#endif  // !PRODUCT

}  // namespace dart
