// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_SCOPE_BUILDER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_SCOPE_BUILDER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/constant_reader.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/parser.h"  // For ParsedFunction.

namespace dart {
namespace kernel {

class ScopeBuildingResult;

class ScopeBuilder {
 public:
  explicit ScopeBuilder(ParsedFunction* parsed_function);

  virtual ~ScopeBuilder() = default;

  ScopeBuildingResult* BuildScopes();

 private:
  void VisitField();

  void VisitProcedure();

  void VisitConstructor();

  void VisitFunctionNode();
  void VisitNode();
  void VisitInitializer();
  void VisitExpression();
  void VisitStatement();
  void VisitListOfExpressions();
  void VisitListOfNamedExpressions();
  void VisitArguments();
  void VisitVariableDeclaration();
  void VisitVariableGet(intptr_t declaration_binary_offset);
  void VisitDartType();
  void VisitInterfaceType(bool simple);
  void VisitFunctionType(bool simple);
  void VisitRecordType();
  void VisitTypeParameterType();
  void VisitIntersectionType();
  void VisitExtensionType();
  void VisitFutureOrType();
  void HandleLocalFunction(intptr_t parent_kernel_offset);

  AbstractType& BuildAndVisitVariableType();

  void EnterScope(intptr_t kernel_offset);
  void ExitScope(TokenPosition start_position, TokenPosition end_position);

  virtual void ReportUnexpectedTag(const char* variant, Tag tag);

  // This enum controls which parameters would be marked as requiring type
  // check on the callee side.
  enum ParameterTypeCheckMode {
    // All parameters will be checked.
    kTypeCheckAllParameters,

    // Only parameters marked as covariant or generic-covariant-impl will be
    // checked.
    kTypeCheckForNonDynamicallyInvokedMethod,

    // Only parameters *not* marked as covariant or generic-covariant-impl will
    // be checked. The rest would be checked in the method itself.
    // Inverse of kTypeCheckForNonDynamicallyInvokedMethod.
    kTypeCheckEverythingNotCheckedInNonDynamicallyInvokedMethod,

    // No parameters will be checked.
    kTypeCheckForStaticFunction,

    // No non-covariant checks are performed, and any covariant checks are
    // performed by the target.
    kTypeCheckForImplicitClosureFunction,
  };

  // This assumes that the reader is at a FunctionNode,
  // about to read the positional parameters.
  void AddPositionalAndNamedParameters(
      intptr_t pos,
      ParameterTypeCheckMode type_check_mode,
      const ProcedureAttributesMetadata& attrs);

  // This assumes that the reader is at a FunctionNode,
  // about to read a parameter (i.e. VariableDeclaration).
  void AddVariableDeclarationParameter(
      intptr_t pos,
      ParameterTypeCheckMode type_check_mode,
      const ProcedureAttributesMetadata& attrs);

  LocalVariable* MakeVariable(
      TokenPosition declaration_pos,
      TokenPosition token_pos,
      const String& name,
      const AbstractType& type,
      intptr_t kernel_offset = LocalVariable::kNoKernelOffset,
      const InferredTypeMetadata* param_type_md = nullptr);

  void AddExceptionVariable(GrowableArray<LocalVariable*>* variables,
                            const char* prefix,
                            intptr_t nesting_depth);

  void FinalizeExceptionVariable(GrowableArray<LocalVariable*>* variables,
                                 GrowableArray<LocalVariable*>* raw_variables,
                                 const String& symbol,
                                 intptr_t nesting_depth);

  void AddTryVariables();
  void AddCatchVariables();
  void FinalizeCatchVariables();
  void AddSwitchVariable();

  // Record an assignment or reference to a variable.  If the occurrence is
  // in a nested function, ensure that the variable is handled properly as a
  // captured variable.
  LocalVariable* LookupVariable(intptr_t declaration_binary_offset);

  StringIndex GetNameFromVariableDeclaration(intptr_t kernel_offset,
                                             const Function& function);

  const String& GenerateName(const char* prefix, intptr_t suffix);

  void HandleLoadReceiver();
  void HandleSpecialLoad(LocalVariable** variable,
                         const String& symbol,
                         intptr_t kernel_offset);

  ScriptPtr Script() { return active_class_.ActiveScript(); }

  struct DepthState {
    explicit DepthState(intptr_t function)
        : loop_(0), function_(function), try_(0), catch_(0), finally_(0) {}

    intptr_t loop_;
    intptr_t function_;
    intptr_t try_;
    intptr_t catch_;
    intptr_t finally_;
  };

  ScopeBuildingResult* result_;
  ParsedFunction* parsed_function_;

  ActiveClass active_class_;

  TranslationHelper translation_helper_;
  Zone* zone_;

  LocalScope* current_function_scope_;
  LocalScope* scope_;
  DepthState depth_;

  intptr_t name_index_;

  bool needs_expr_temp_;
  TokenPosition first_body_token_position_ = TokenPosition::kNoSource;

  KernelReaderHelper helper_;
  ConstantReader constant_reader_;
  InferredTypeMetadataHelper inferred_type_metadata_helper_;
  InferredTypeMetadataHelper inferred_arg_type_metadata_helper_;
  ProcedureAttributesMetadataHelper procedure_attributes_metadata_helper_;
  TypeTranslator type_translator_;

  DISALLOW_COPY_AND_ASSIGN(ScopeBuilder);
};

struct FunctionScope {
  intptr_t kernel_offset;
  LocalScope* scope;
};

class ScopeBuildingResult : public ZoneAllocated {
 public:
  ScopeBuildingResult()
      : type_arguments_variable(nullptr),
        switch_variable(nullptr),
        finally_return_variable(nullptr),
        setter_value(nullptr),
        raw_variable_counter_(0) {}

  bool IsClosureWithEmptyContext(intptr_t function_node_offset) {
    for (intptr_t i = 0; i < closure_offsets_without_captures.length(); ++i) {
      if (closure_offsets_without_captures[i] == function_node_offset) {
        return true;
      }
    }
    return false;
  }

  IntMap<LocalVariable*> locals;
  IntMap<LocalScope*> scopes;
  GrowableArray<FunctionScope> function_scopes;

  // Only non-null for factory constructor functions.
  LocalVariable* type_arguments_variable;

  // Non-nullptr when the function contains a switch statement.
  LocalVariable* switch_variable;

  // Non-nullptr when the function contains a return inside a finally block.
  LocalVariable* finally_return_variable;

  // Non-nullptr when the function is a setter.
  LocalVariable* setter_value;

  // Variables used in exception handlers, one per exception handler nesting
  // level.
  GrowableArray<LocalVariable*> exception_variables;
  GrowableArray<LocalVariable*> stack_trace_variables;
  GrowableArray<LocalVariable*> catch_context_variables;

  // These are used to access the raw exception/stacktrace variables (and are
  // used to put them into the captured variables in the context).
  GrowableArray<LocalVariable*> raw_exception_variables;
  GrowableArray<LocalVariable*> raw_stack_trace_variables;
  intptr_t raw_variable_counter_;

  // Remembers closure function kernel offsets that do not capture any
  // variables.
  GrowableArray<intptr_t> closure_offsets_without_captures;

 private:
  DISALLOW_COPY_AND_ASSIGN(ScopeBuildingResult);
};

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_SCOPE_BUILDER_H_
