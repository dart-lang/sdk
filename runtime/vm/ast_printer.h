// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_AST_PRINTER_H_
#define RUNTIME_VM_AST_PRINTER_H_

#include "vm/ast.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declaration.
class ParsedFunction;
class Log;

class AstPrinter : public AstNodeVisitor {
 public:
  explicit AstPrinter(bool log = true);
  ~AstPrinter();

  void PrintNode(AstNode* node);
  void PrintFunctionScope(const ParsedFunction& parsed_function);
  void PrintFunctionNodes(const ParsedFunction& parsed_function);

#define DECLARE_VISITOR_FUNCTION(BaseName)                                     \
  virtual void Visit##BaseName##Node(BaseName##Node* node);

  FOR_EACH_NODE(DECLARE_VISITOR_FUNCTION)
#undef DECLARE_VISITOR_FUNCTION

 private:
  static const int kScopeIndent = 2;

  void IndentN(int count);
  void PrintLocalScopeVariable(const LocalScope* scope,
                               LocalVariable* var,
                               int indent = 0);
  void PrintLocalScope(const LocalScope* scope,
                       int variable_index,
                       int indent = 0);

  void VisitGenericAstNode(AstNode* node);
  void VisitGenericLocalNode(AstNode* node, const LocalVariable& local);
  void VisitGenericFieldNode(AstNode* node, const Field& field);

  void PrintLocalVariable(const LocalVariable* variable);
  void PrintNewlineAndIndent();

  intptr_t indent_;
  Log* logger_;

  DISALLOW_COPY_AND_ASSIGN(AstPrinter);
};

}  // namespace dart

#endif  // RUNTIME_VM_AST_PRINTER_H_
