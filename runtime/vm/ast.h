// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_AST_H_
#define RUNTIME_VM_AST_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/scopes.h"
#include "vm/token.h"
#include "vm/token_position.h"

namespace dart {

#define FOR_EACH_NODE(V)                                                       \
  V(Sequence)                                                                  \

#define FORWARD_DECLARATION(BaseName) class BaseName##Node;
FOR_EACH_NODE(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION

#define DECLARE_COMMON_NODE_FUNCTIONS(type)                                    \
  virtual type* As##type() { return this; }

class AstNode : public ZoneAllocated {
 public:
  explicit AstNode(TokenPosition token_pos) : token_pos_(token_pos) {
    ASSERT(!token_pos_.IsClassifying() ||
           (token_pos_ == TokenPosition::kMethodExtractor));
  }
  virtual ~AstNode() {}

  TokenPosition token_pos() const { return token_pos_; }

#define AST_TYPE_CHECK(BaseName)                                               \
  bool Is##BaseName##Node() { return As##BaseName##Node() != NULL; }           \
  virtual BaseName##Node* As##BaseName##Node() { return NULL; }

  FOR_EACH_NODE(AST_TYPE_CHECK)
#undef AST_TYPE_CHECK

 protected:
  friend class ParsedFunction;

 private:
  const TokenPosition token_pos_;
  DISALLOW_COPY_AND_ASSIGN(AstNode);
};

class SequenceNode : public AstNode {
 public:
  SequenceNode(TokenPosition token_pos, LocalScope* scope)
      : AstNode(token_pos), scope_(scope), nodes_(4), label_(NULL) {}

  LocalScope* scope() const { return scope_; }

  SourceLabel* label() const { return label_; }
  void set_label(SourceLabel* value) { label_ = value; }

  DECLARE_COMMON_NODE_FUNCTIONS(SequenceNode);

 private:
  LocalScope* scope_;
  GrowableArray<AstNode*> nodes_;
  SourceLabel* label_;

  DISALLOW_COPY_AND_ASSIGN(SequenceNode);
};

}  // namespace dart

#undef DECLARE_COMMON_NODE_FUNCTIONS

#endif  // RUNTIME_VM_AST_H_
