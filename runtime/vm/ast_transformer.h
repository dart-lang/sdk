// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_AST_TRANSFORMER_H_
#define VM_AST_TRANSFORMER_H_

#include "platform/assert.h"
#include "vm/ast.h"

namespace dart {

class ParsedFunction;

// Translate an AstNode containing an expression (that itself contains one or
// more awaits) into a sequential representation where subexpressions are
// evaluated sequentially into intermediates. Those intermediates are stored
// within a context.
//
// This allows a function to be suspended and resumed from within evaluating an
// expression. The evaluation is split among a so-called preamble and the
// evaluation of the resulting expression (which is only a single load).
//
// Example (minimalistic):
//
//   var a = (await bar()) + foo();
//
// This translates to a premable similar to:
//
//   var t_1, t_2, t_3, t_4; // All stored in a context.
//   t_1 = bar();
//   :result_param = t_1;
//   <continuation logic>
//   t_2 = :result_param;
//   t_3 = foo();
//   t_4 = t_2.operator+(t_3);
//
// and a resulting expression of a load of t_4.
//
class AwaitTransformer : public AstNodeVisitor {
 public:
  AwaitTransformer(SequenceNode* preamble,
                   const Library& library,
                   ParsedFunction* const parsed_function)
    : preamble_(preamble),
      temp_cnt_(0),
      library_(library),
      parsed_function_(parsed_function),
      isolate_(Isolate::Current()) {}

#define DECLARE_VISIT(BaseName)                                                \
  virtual void Visit##BaseName##Node(BaseName##Node* node);

  FOR_EACH_NODE(DECLARE_VISIT)
#undef DECLARE_VISIT

  AstNode* Transform(AstNode* expr);

 private:
  LocalVariable* EnsureCurrentTempVar();
  LocalVariable* AddToPreambleNewTempVar(AstNode* node);
  ArgumentListNode* TransformArguments(ArgumentListNode* node);
  AstNode* LazyTransform(const Token::Kind kind,
                         AstNode* new_left,
                         AstNode* right);

  void NextTempVar() { temp_cnt_++; }

  Isolate* isolate() const { return isolate_; }

  SequenceNode* preamble_;
  int32_t temp_cnt_;
  AstNode* result_;
  const Library& library_;
  ParsedFunction* const parsed_function_;

  Isolate* isolate_;

  DISALLOW_COPY_AND_ASSIGN(AwaitTransformer);
};

}  // namespace dart

#endif  // VM_AST_TRANSFORMER_H_
