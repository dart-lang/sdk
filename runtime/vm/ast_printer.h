// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_AST_PRINTER_H_
#define VM_AST_PRINTER_H_

#include "vm/ast.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declaration.
class ParsedFunction;

class AstPrinter : public AstNodeVisitor {
 public:
  static void PrintNode(AstNode* node);
  static void PrintFunctionScope(const ParsedFunction& parsed_function);
  static void PrintFunctionNodes(const ParsedFunction& parsed_function);

#define DECLARE_VISITOR_FUNCTION(BaseName)                                     \
  virtual void Visit##BaseName##Node(BaseName##Node* node);

  FOR_EACH_NODE(DECLARE_VISITOR_FUNCTION)
#undef DECLARE_VISITOR_FUNCTION

 private:
  AstPrinter();
  ~AstPrinter();

  static const int kScopeIndent = 2;

  static void PrintLocalScopeVariable(const LocalScope* scope,
                                      LocalVariable* var,
                                      int indent = 0);
  static void PrintLocalScope(const LocalScope* scope,
                              int variable_index,
                              int indent = 0);

  void VisitGenericAstNode(AstNode* node);
  void VisitGenericLocalNode(AstNode* node, const LocalVariable& local);
  void VisitGenericFieldNode(AstNode* node, const Field& field);

  DISALLOW_COPY_AND_ASSIGN(AstPrinter);
};

}  // namespace dart

#endif  // VM_AST_PRINTER_H_
