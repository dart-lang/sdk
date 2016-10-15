// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <map>
#include <set>
#include <string>

#include "vm/kernel_to_il.h"

#include "vm/compiler.h"
#include "vm/intermediate_language.h"
#include "vm/kernel_reader.h"
#include "vm/longjump.h"
#include "vm/method_recognizer.h"
#include "vm/object_store.h"
#include "vm/report.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"

namespace dart {

DECLARE_FLAG(bool, support_externalizable_strings);

namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()


void ScopeBuilder::EnterScope(TreeNode* node) {
  scope_ = new (Z) LocalScope(scope_, depth_.function_, depth_.loop_);
  result_->scopes.Insert(node, scope_);
}


void ScopeBuilder::ExitScope() { scope_ = scope_->parent(); }


LocalVariable* ScopeBuilder::MakeVariable(const dart::String& name) {
  return new (Z)
      LocalVariable(TokenPosition::kNoSource, name, Object::dynamic_type());
}


LocalVariable* ScopeBuilder::MakeVariable(const dart::String& name,
                                          const Type& type) {
  return new (Z) LocalVariable(TokenPosition::kNoSource, name, type);
}


void ScopeBuilder::AddParameters(FunctionNode* function, intptr_t pos) {
  List<VariableDeclaration>& positional = function->positional_parameters();
  for (intptr_t i = 0; i < positional.length(); ++i) {
    AddParameter(positional[i], pos++);
  }
  List<VariableDeclaration>& named = function->named_parameters();
  for (intptr_t i = 0; i < named.length(); ++i) {
    AddParameter(named[i], pos++);
  }
}


void ScopeBuilder::AddParameter(VariableDeclaration* declaration,
                                intptr_t pos) {
  // TODO(27590): Handle final.
  LocalVariable* variable = MakeVariable(H.DartSymbol(declaration->name()));
  scope_->InsertParameterAt(pos, variable);
  result_->locals.Insert(declaration, variable);

  // The default value may contain 'let' bindings for which the constant
  // evaluator needs scope bindings.
  Expression* defaultValue = declaration->initializer();
  if (defaultValue != NULL) {
    defaultValue->AcceptExpressionVisitor(this);
  }
}


void ScopeBuilder::AddExceptionVariable(
    GrowableArray<LocalVariable*>* variables, const char* prefix,
    intptr_t nesting_depth) {
  LocalVariable* v = NULL;

  // If we are inside a function with yield points then Kernel transformer
  // could have lifted some of the auxiliary exception variables into the
  // context to preserve them across yield points because they might
  // be needed for rethrow.
  // Check if it did and capture such variables instead of introducing
  // new local ones.
  // Note: function that wrap kSyncYielding function does not contain
  // its own try/catches.
  if (current_function_node_->async_marker() == FunctionNode::kSyncYielding) {
    ASSERT(current_function_scope_->parent() != NULL);
    v = current_function_scope_->parent()->LocalLookupVariable(
        GenerateName(prefix, nesting_depth - 1));
    if (v != NULL) {
      scope_->CaptureVariable(v);
    }
  }

  // No need to create variables for try/catch-statements inside
  // nested functions.
  if (depth_.function_ > 0) return;
  if (variables->length() >= nesting_depth) return;

  // If variable was not lifted by the transformer introduce a new
  // one into the current function scope.
  if (v == NULL) {
    v = MakeVariable(GenerateName(prefix, nesting_depth - 1));

    // If transformer did not lift the variable then there is no need
    // to lift it into the context when we encouter a YieldStatement.
    v->set_is_forced_stack();
    current_function_scope_->AddVariable(v);
  }

  variables->Add(v);
}


void ScopeBuilder::AddTryVariables() {
  AddExceptionVariable(&result_->catch_context_variables,
                       ":saved_try_context_var", depth_.try_);
}


void ScopeBuilder::AddCatchVariables() {
  AddExceptionVariable(&result_->exception_variables, ":exception",
                       depth_.catch_);
  AddExceptionVariable(&result_->stack_trace_variables, ":stack_trace",
                       depth_.catch_);
}


void ScopeBuilder::AddIteratorVariable() {
  if (depth_.function_ > 0) return;
  if (result_->iterator_variables.length() >= depth_.for_in_) return;

  ASSERT(result_->iterator_variables.length() == depth_.for_in_ - 1);
  LocalVariable* iterator =
      MakeVariable(GenerateName(":iterator", depth_.for_in_ - 1));
  current_function_scope_->AddVariable(iterator);
  result_->iterator_variables.Add(iterator);
}


void ScopeBuilder::LookupVariable(VariableDeclaration* declaration) {
  LocalVariable* variable = result_->locals.Lookup(declaration);
  if (variable == NULL) {
    // We have not seen a declaration of the variable, so it must be the
    // case that we are compiling a nested function and the variable is
    // declared in an outer scope.  In that case, look it up in the scope by
    // name and add it to the variable map to simplify later lookup.
    ASSERT(current_function_scope_->parent() != NULL);
    const dart::String& name = H.DartSymbol(declaration->name());
    variable = current_function_scope_->parent()->LookupVariable(name, true);
    ASSERT(variable != NULL);
    result_->locals.Insert(declaration, variable);
  }
  if (variable->owner()->function_level() < scope_->function_level()) {
    // We call `LocalScope->CaptureVariable(variable)` in two scenarios for two
    // different reasons:
    //   Scenario 1:
    //       We need to know which variables defined in this function
    //       are closed over by nested closures in order to ensure we will
    //       create a [Context] object of appropriate size and store captured
    //       variables there instead of the stack.
    //   Scenario 2:
    //       We need to find out which variables defined in enclosing functions
    //       are closed over by this function/closure or nested closures. This
    //       is necessary in order to build a fat flattened [ContextScope]
    //       object.
    scope_->CaptureVariable(variable);
  } else {
    ASSERT(variable->owner()->function_level() == scope_->function_level());
  }
}


void ScopeBuilder::LookupCapturedVariableByName(LocalVariable** variable,
                                                const dart::String& name) {
  if (*variable == NULL) {
    *variable = scope_->LookupVariable(name, true);
    ASSERT(*variable != NULL);
    scope_->CaptureVariable(*variable);
  }
}


const dart::String& ScopeBuilder::GenerateName(const char* prefix,
                                               intptr_t suffix) {
  char name[64];
  OS::SNPrint(name, 64, "%s%" Pd "", prefix, suffix);
  return H.DartSymbol(name);
}


void ScopeBuilder::AddVariable(VariableDeclaration* declaration) {
  // TODO(27590): Handle final and const, including function declarations.
  const dart::String& name = declaration->name()->is_empty()
                                 ? GenerateName(":var", name_index_++)
                                 : H.DartSymbol(declaration->name());
  LocalVariable* variable = MakeVariable(name);
  scope_->AddVariable(variable);
  result_->locals.Insert(declaration, variable);
}


static bool IsStaticInitializer(const Function& function, Zone* zone) {
  return (function.kind() == RawFunction::kImplicitStaticFinalGetter) &&
         dart::String::Handle(zone, function.name())
             .StartsWith(Symbols::InitPrefix());
}


ScopeBuildingResult* ScopeBuilder::BuildScopes() {
  if (result_ != NULL) return result_;

  ASSERT(scope_ == NULL && depth_.loop_ == 0 && depth_.function_ == 0);
  result_ = new (Z) ScopeBuildingResult();

  ParsedFunction* parsed_function = parsed_function_;
  const dart::Function& function = parsed_function->function();

  LocalScope* enclosing_scope = NULL;
  if (function.IsLocalFunction()) {
    enclosing_scope = LocalScope::RestoreOuterScope(
        ContextScope::Handle(Z, function.context_scope()));
  }
  current_function_scope_ = scope_ = new (Z) LocalScope(enclosing_scope, 0, 0);
  scope_->AddVariable(parsed_function->EnsureExpressionTemp());
  scope_->AddVariable(parsed_function->current_context_var());
  parsed_function->SetNodeSequence(
      new SequenceNode(TokenPosition::kNoSource, scope_));

  switch (function.kind()) {
    case RawFunction::kClosureFunction:
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction:
    case RawFunction::kConstructor: {
      FunctionNode* node;
      if (node_->IsProcedure()) {
        node = Procedure::Cast(node_)->function();
      } else if (node_->IsConstructor()) {
        node = Constructor::Cast(node_)->function();
      } else {
        node = FunctionNode::Cast(node_);
      }
      current_function_node_ = node;

      intptr_t pos = 0;
      if (function.IsClosureFunction()) {
        LocalVariable* variable = MakeVariable(Symbols::ClosureParameter());
        scope_->InsertParameterAt(pos++, variable);
      } else if (!function.is_static()) {
        // We use [is_static] instead of [IsStaticFunction] because the latter
        // returns `false` for constructors.
        dart::Class& klass = dart::Class::Handle(Z, function.Owner());
        Type& klass_type = H.GetCanonicalType(klass);
        LocalVariable* variable = MakeVariable(Symbols::This(), klass_type);
        scope_->InsertParameterAt(pos++, variable);
        result_->this_variable = variable;

        // We visit instance field initializers because they might contain
        // [Let] expressions and we need to have a mapping.
        if (node_->IsConstructor()) {
          Class* klass = Class::Cast(Constructor::Cast(node_)->parent());

          for (intptr_t i = 0; i < klass->fields().length(); i++) {
            Field* field = klass->fields()[i];
            if (!field->IsStatic() && (field->initializer() != NULL)) {
              EnterScope(field);
              field->initializer()->AcceptExpressionVisitor(this);
              ExitScope();
            }
          }
        }
      } else if (function.IsFactory()) {
        LocalVariable* variable = MakeVariable(
            Symbols::TypeArgumentsParameter(), AbstractType::dynamic_type());
        scope_->InsertParameterAt(pos++, variable);
        result_->type_arguments_variable = variable;
      }
      AddParameters(node, pos);

      // We generate a syntethic body for implicit closure functions - which
      // will forward the call to the real function.
      //     -> see BuildGraphOfImplicitClosureFunction
      if (!function.IsImplicitClosureFunction()) {
        node_->AcceptVisitor(this);
      }
      break;
    }
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitStaticFinalGetter:
    case RawFunction::kImplicitSetter: {
      ASSERT(node_->IsField());
      if (IsStaticInitializer(function, Z)) {
        node_->AcceptVisitor(this);
        break;
      }
      bool is_setter = function.IsImplicitSetterFunction();
      bool is_method = !function.IsStaticFunction();
      intptr_t pos = 0;
      if (is_method) {
        dart::Class& klass = dart::Class::Handle(Z, function.Owner());
        Type& klass_type = H.GetCanonicalType(klass);
        LocalVariable* variable = MakeVariable(Symbols::This(), klass_type);
        scope_->InsertParameterAt(pos++, variable);
        result_->this_variable = variable;
      }
      if (is_setter) {
        result_->setter_value = MakeVariable(Symbols::Value());
        scope_->InsertParameterAt(pos++, result_->setter_value);
      }
      break;
    }
    case RawFunction::kMethodExtractor: {
      // Add a receiver parameter.  Though it is captured, we emit code to
      // explicitly copy it to a fixed offset in a freshly-allocated context
      // instead of using the generic code for regular functions.
      // Therefore, it isn't necessary to mark it as captured here.
      dart::Class& klass = dart::Class::Handle(Z, function.Owner());
      Type& klass_type = H.GetCanonicalType(klass);
      LocalVariable* variable = MakeVariable(Symbols::This(), klass_type);
      scope_->InsertParameterAt(0, variable);
      result_->this_variable = variable;
      break;
    }
    case RawFunction::kNoSuchMethodDispatcher:
    case RawFunction::kInvokeFieldDispatcher:
      for (intptr_t i = 0; i < function.NumParameters(); ++i) {
        LocalVariable* variable = MakeVariable(
            dart::String::ZoneHandle(Z, function.ParameterNameAt(i)));
        scope_->InsertParameterAt(i, variable);
      }
      break;
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
      UNREACHABLE();
  }

  parsed_function->AllocateVariables();

  return result_;
}


void ScopeBuilder::VisitThisExpression(ThisExpression* node) {
  HandleSpecialLoad(&result_->this_variable, Symbols::This());
}


void ScopeBuilder::VisitTypeParameterType(TypeParameterType* node) {
  Function& function = Function::Handle(Z, parsed_function_->function().raw());
  while (function.IsClosureFunction()) {
    function = function.parent_function();
  }

  if (function.IsFactory()) {
    // The type argument vector is passed as the very first argument to the
    // factory constructor function.
    HandleSpecialLoad(&result_->type_arguments_variable,
                      Symbols::TypeArgumentsParameter());
  } else {
    // The type argument vector is stored on the instance object. We therefore
    // need to capture `this`.
    HandleSpecialLoad(&result_->this_variable, Symbols::This());
  }
}


void ScopeBuilder::VisitVariableGet(VariableGet* node) {
  LookupVariable(node->variable());
}


void ScopeBuilder::VisitVariableSet(VariableSet* node) {
  LookupVariable(node->variable());
  node->VisitChildren(this);
}


void ScopeBuilder::HandleLocalFunction(TreeNode* parent,
                                       FunctionNode* function) {
  LocalScope* saved_function_scope = current_function_scope_;
  FunctionNode* saved_function_node = current_function_node_;
  ScopeBuilder::DepthState saved_depth_state = depth_;
  depth_ = DepthState(depth_.function_ + 1);
  EnterScope(parent);
  current_function_scope_ = scope_;
  current_function_node_ = function;
  if (depth_.function_ == 1) {
    FunctionScope function_scope = {function, scope_};
    result_->function_scopes.Add(function_scope);
  }
  AddParameters(function);
  VisitFunctionNode(function);
  ExitScope();
  depth_ = saved_depth_state;
  current_function_scope_ = saved_function_scope;
  current_function_node_ = saved_function_node;
}


void ScopeBuilder::HandleSpecialLoad(LocalVariable** variable,
                                     const dart::String& symbol) {
  if (current_function_scope_->parent() != NULL) {
    // We are building the scope tree of a closure function and saw [node]. We
    // lazily populate the variable using the parent function scope.
    if (*variable == NULL) {
      *variable =
          current_function_scope_->parent()->LookupVariable(symbol, true);
      ASSERT(*variable != NULL);
    }
  }

  if ((current_function_scope_->parent() != NULL) ||
      (scope_->function_level() > 0)) {
    // Every scope we use the [variable] from needs to be notified of the usage
    // in order to ensure that preserving the context scope on that particular
    // use-site also includes the [variable].
    scope_->CaptureVariable(*variable);
  }
}


void ScopeBuilder::VisitFunctionExpression(FunctionExpression* node) {
  HandleLocalFunction(node, node->function());
}


void ScopeBuilder::VisitLet(Let* node) {
  EnterScope(node);
  node->VisitChildren(this);
  ExitScope();
}


void ScopeBuilder::VisitBlock(Block* node) {
  EnterScope(node);
  node->VisitChildren(this);
  ExitScope();
}


void ScopeBuilder::VisitVariableDeclaration(VariableDeclaration* node) {
  AddVariable(node);
  node->VisitChildren(this);
}


void ScopeBuilder::VisitFunctionDeclaration(FunctionDeclaration* node) {
  VisitVariableDeclaration(node->variable());
  HandleLocalFunction(node, node->function());
}


void ScopeBuilder::VisitWhileStatement(WhileStatement* node) {
  ++depth_.loop_;
  node->VisitChildren(this);
  --depth_.loop_;
}


void ScopeBuilder::VisitDoStatement(DoStatement* node) {
  ++depth_.loop_;
  node->VisitChildren(this);
  --depth_.loop_;
}


void ScopeBuilder::VisitForStatement(ForStatement* node) {
  EnterScope(node);
  List<VariableDeclaration>& variables = node->variables();
  for (intptr_t i = 0; i < variables.length(); ++i) {
    VisitVariableDeclaration(variables[i]);
  }
  ++depth_.loop_;
  if (node->condition() != NULL) {
    node->condition()->AcceptExpressionVisitor(this);
  }
  node->body()->AcceptStatementVisitor(this);
  List<Expression>& updates = node->updates();
  for (intptr_t i = 0; i < updates.length(); ++i) {
    updates[i]->AcceptExpressionVisitor(this);
  }
  --depth_.loop_;
  ExitScope();
}


void ScopeBuilder::VisitForInStatement(ForInStatement* node) {
  node->iterable()->AcceptExpressionVisitor(this);
  ++depth_.for_in_;
  AddIteratorVariable();
  ++depth_.loop_;
  EnterScope(node);
  VisitVariableDeclaration(node->variable());
  node->body()->AcceptStatementVisitor(this);
  ExitScope();
  --depth_.loop_;
  --depth_.for_in_;
}


void ScopeBuilder::AddSwitchVariable() {
  if ((depth_.function_ == 0) && (result_->switch_variable == NULL)) {
    LocalVariable* variable = MakeVariable(Symbols::SwitchExpr());
    current_function_scope_->AddVariable(variable);
    result_->switch_variable = variable;
  }
}


void ScopeBuilder::VisitSwitchStatement(SwitchStatement* node) {
  AddSwitchVariable();
  node->VisitChildren(this);
}


void ScopeBuilder::VisitReturnStatement(ReturnStatement* node) {
  if ((depth_.function_ == 0) && (depth_.finally_ > 0) &&
      (result_->finally_return_variable == NULL)) {
    const dart::String& name = H.DartSymbol(":try_finally_return_value");
    LocalVariable* variable = MakeVariable(name);
    current_function_scope_->AddVariable(variable);
    result_->finally_return_variable = variable;
  }
  node->VisitChildren(this);
}


void ScopeBuilder::VisitTryCatch(TryCatch* node) {
  ++depth_.try_;
  AddTryVariables();
  node->body()->AcceptStatementVisitor(this);
  --depth_.try_;

  ++depth_.catch_;
  AddCatchVariables();
  List<Catch>& catches = node->catches();
  for (intptr_t i = 0; i < catches.length(); ++i) {
    Catch* ketch = catches[i];
    EnterScope(ketch);
    if (ketch->exception() != NULL) {
      VisitVariableDeclaration(ketch->exception());
    }
    if (ketch->stack_trace() != NULL) {
      VisitVariableDeclaration(ketch->stack_trace());
    }
    ketch->body()->AcceptStatementVisitor(this);
    ExitScope();
  }
  --depth_.catch_;
}


void ScopeBuilder::VisitTryFinally(TryFinally* node) {
  ++depth_.try_;
  ++depth_.finally_;
  AddTryVariables();
  node->body()->AcceptStatementVisitor(this);
  --depth_.finally_;
  --depth_.try_;

  ++depth_.catch_;
  AddCatchVariables();
  node->finalizer()->AcceptStatementVisitor(this);
  --depth_.catch_;
}


void ScopeBuilder::VisitFunctionNode(FunctionNode* node) {
  List<TypeParameter>& type_parameters = node->type_parameters();
  for (intptr_t i = 0; i < type_parameters.length(); ++i) {
    VisitTypeParameter(type_parameters[i]);
  }
  // Do not visit the positional and named parameters, because they've
  // already been added to the scope.
  if (node->body() != NULL) {
    node->body()->AcceptStatementVisitor(this);
  }

  // Ensure that :await_jump_var and :await_ctx_var are captured.
  if (node->async_marker() == FunctionNode::kSyncYielding) {
    {
      LocalVariable* temp = NULL;
      LookupCapturedVariableByName(
          (depth_.function_ == 0) ? &result_->yield_jump_variable : &temp,
          Symbols::AwaitJumpVar());
    }
    {
      LocalVariable* temp = NULL;
      LookupCapturedVariableByName(
          (depth_.function_ == 0) ? &result_->yield_context_variable : &temp,
          Symbols::AwaitContextVar());
    }
  }
}


void ScopeBuilder::VisitYieldStatement(YieldStatement* node) {
  ASSERT(node->is_native());
  if (depth_.function_ == 0) {
    AddSwitchVariable();
    // Promote all currently visible local variables into the context.
    // TODO(27590) CaptureLocalVariables promotes to many variables into
    // the scope. Mark those variables as stack_local.
    // TODO(27590) we don't need to promote those variables that are
    // not used across yields.
    scope_->CaptureLocalVariables(current_function_scope_);
  }
}


void ScopeBuilder::VisitAssertStatement(AssertStatement* node) {
  if (I->asserts()) {
    RecursiveVisitor::VisitAssertStatement(node);
  }
}


void ScopeBuilder::VisitConstructor(Constructor* node) {
  // Field initializers that come from non-static field declarations are
  // compiled as if they appear in the constructor initializer list.  This is
  // important for closure-valued field initializers because the VM expects the
  // corresponding closure functions to appear as if they were nested inside the
  // constructor.
  List<Field>& fields = Class::Cast(node->parent())->fields();
  for (intptr_t i = 0; i < fields.length(); ++i) {
    Field* field = fields[i];
    Expression* initializer = field->initializer();
    if (!field->IsStatic() && (initializer != NULL)) {
      initializer->AcceptExpressionVisitor(this);
    }
  }
  node->VisitChildren(this);
}


class BreakableBlock {
 public:
  BreakableBlock(FlowGraphBuilder* builder, LabeledStatement* statement)
      : builder_(builder),
        labeled_statement_(statement),
        outer_(builder->breakable_block_),
        destination_(NULL),
        outer_finally_(builder->try_finally_block_),
        context_depth_(builder->context_depth_) {
    builder_->breakable_block_ = this;
  }
  ~BreakableBlock() { builder_->breakable_block_ = outer_; }

  bool HadJumper() { return destination_ != NULL; }

  JoinEntryInstr* destination() { return destination_; }

  JoinEntryInstr* BreakDestination(LabeledStatement* label,
                                   TryFinallyBlock** outer_finally,
                                   intptr_t* context_depth) {
    BreakableBlock* block = builder_->breakable_block_;
    while (block->labeled_statement_ != label) {
      block = block->outer_;
    }
    ASSERT(block != NULL);
    *outer_finally = block->outer_finally_;
    *context_depth = block->context_depth_;
    return block->EnsureDestination();
  }

 private:
  JoinEntryInstr* EnsureDestination() {
    if (destination_ == NULL) {
      destination_ = builder_->BuildJoinEntry();
    }
    return destination_;
  }

  FlowGraphBuilder* builder_;
  LabeledStatement* labeled_statement_;
  BreakableBlock* outer_;
  JoinEntryInstr* destination_;
  TryFinallyBlock* outer_finally_;
  intptr_t context_depth_;
};


class SwitchBlock {
 public:
  SwitchBlock(FlowGraphBuilder* builder, SwitchStatement* switch_stmt)
      : builder_(builder),
        outer_(builder->switch_block_),
        outer_finally_(builder->try_finally_block_),
        switch_statement_(switch_stmt),
        context_depth_(builder->context_depth_) {
    builder_->switch_block_ = this;
  }
  ~SwitchBlock() { builder_->switch_block_ = outer_; }

  bool HadJumper(SwitchCase* switch_case) {
    return destinations_.Lookup(switch_case) != NULL;
  }

  JoinEntryInstr* Destination(SwitchCase* label,
                              TryFinallyBlock** outer_finally = NULL,
                              intptr_t* context_depth = NULL) {
    // Find corresponding [SwitchStatement].
    SwitchBlock* block = this;
    while (true) {
      block->EnsureSwitchCaseMapping();
      if (block->Contains(label)) break;
      block = block->outer_;
    }

    // Set the outer finally block.
    if (outer_finally != NULL) {
      *outer_finally = block->outer_finally_;
      *context_depth = block->context_depth_;
    }

    // Ensure there's [JoinEntryInstr] for that [SwitchCase].
    return block->EnsureDestination(label);
  }

 private:
  typedef std::set<SwitchCase*> DestinationSwitches;

  JoinEntryInstr* EnsureDestination(SwitchCase* switch_case) {
    JoinEntryInstr* cached_inst = destinations_.Lookup(switch_case);
    if (cached_inst == NULL) {
      JoinEntryInstr* inst = builder_->BuildJoinEntry();
      destinations_.Insert(switch_case, inst);
      return inst;
    }
    return cached_inst;
  }

  void EnsureSwitchCaseMapping() {
    if (destination_switches_.begin() == destination_switches_.end()) {
      List<SwitchCase>& cases = switch_statement_->cases();
      for (intptr_t i = 0; i < cases.length(); i++) {
        destination_switches_.insert(cases[i]);
      }
    }
  }

  bool Contains(SwitchCase* sc) {
    return destination_switches_.find(sc) != destination_switches_.end();
  }

  FlowGraphBuilder* builder_;
  SwitchBlock* outer_;

  Map<SwitchCase, JoinEntryInstr*> destinations_;
  DestinationSwitches destination_switches_;

  TryFinallyBlock* outer_finally_;
  SwitchStatement* switch_statement_;
  intptr_t context_depth_;
};


class TryFinallyBlock {
 public:
  TryFinallyBlock(FlowGraphBuilder* builder, Statement* finalizer)
      : builder_(builder),
        outer_(builder->try_finally_block_),
        finalizer_(finalizer),
        context_depth_(builder->context_depth_),
        // Finalizers are executed outside of the try block hence
        // try depth of finalizers are one less than current try
        // depth.
        try_depth_(builder->try_depth_ - 1) {
    builder_->try_finally_block_ = this;
  }
  ~TryFinallyBlock() { builder_->try_finally_block_ = outer_; }

  Statement* finalizer() const { return finalizer_; }
  intptr_t context_depth() const { return context_depth_; }
  intptr_t try_depth() const { return try_depth_; }
  TryFinallyBlock* outer() const { return outer_; }

 private:
  FlowGraphBuilder* const builder_;
  TryFinallyBlock* const outer_;
  Statement* const finalizer_;
  const intptr_t context_depth_;
  const intptr_t try_depth_;
};


class TryCatchBlock {
 public:
  explicit TryCatchBlock(FlowGraphBuilder* builder,
                         intptr_t try_handler_index = -1)
      : builder_(builder),
        outer_(builder->try_catch_block_),
        try_index_(try_handler_index) {
    if (try_index_ == -1) try_index_ = builder->AllocateTryIndex();
    builder->try_catch_block_ = this;
  }
  ~TryCatchBlock() { builder_->try_catch_block_ = outer_; }

  intptr_t TryIndex() { return try_index_; }

 private:
  FlowGraphBuilder* builder_;
  TryCatchBlock* outer_;
  intptr_t try_index_;
};


class CatchBlock {
 public:
  CatchBlock(FlowGraphBuilder* builder, LocalVariable* exception_var,
             LocalVariable* stack_trace_var, intptr_t catch_try_index)
      : builder_(builder),
        outer_(builder->catch_block_),
        exception_var_(exception_var),
        stack_trace_var_(stack_trace_var),
        catch_try_index_(catch_try_index) {
    builder_->catch_block_ = this;
  }
  ~CatchBlock() { builder_->catch_block_ = outer_; }

  LocalVariable* exception_var() { return exception_var_; }
  LocalVariable* stack_trace_var() { return stack_trace_var_; }
  intptr_t catch_try_index() { return catch_try_index_; }

 private:
  FlowGraphBuilder* builder_;
  CatchBlock* outer_;
  LocalVariable* exception_var_;
  LocalVariable* stack_trace_var_;
  intptr_t catch_try_index_;
};


Fragment& Fragment::operator+=(const Fragment& other) {
  if (entry == NULL) {
    entry = other.entry;
    current = other.current;
  } else if (current != NULL && other.entry != NULL) {
    current->LinkTo(other.entry);
    current = other.current;
  }
  return *this;
}


Fragment& Fragment::operator<<=(Instruction* next) {
  if (entry == NULL) {
    entry = current = next;
  } else if (current != NULL) {
    current->LinkTo(next);
    current = next;
  }
  return *this;
}


Fragment Fragment::closed() {
  ASSERT(entry != NULL);
  return Fragment(entry, NULL);
}


Fragment operator+(const Fragment& first, const Fragment& second) {
  Fragment result = first;
  result += second;
  return result;
}


Fragment operator<<(const Fragment& fragment, Instruction* next) {
  Fragment result = fragment;
  result <<= next;
  return result;
}


RawInstance* TranslationHelper::Canonicalize(const Instance& instance) {
  if (instance.IsNull()) return instance.raw();

  const char* error_str = NULL;
  RawInstance* result = instance.CheckAndCanonicalize(thread(), &error_str);
  if (result == Object::null()) {
    ReportError("Invalid const object %s", error_str);
  }
  return result;
}


const dart::String& TranslationHelper::DartString(const char* content,
                                                  Heap::Space space) {
  return dart::String::ZoneHandle(Z, dart::String::New(content, space));
}


dart::String& TranslationHelper::DartString(String* content,
                                            Heap::Space space) {
  return dart::String::ZoneHandle(
      Z, dart::String::FromUTF8(content->buffer(), content->size(), space));
}


const dart::String& TranslationHelper::DartSymbol(const char* content) const {
  return dart::String::ZoneHandle(Z, Symbols::New(thread_, content));
}


dart::String& TranslationHelper::DartSymbol(String* content) const {
  return dart::String::ZoneHandle(
      Z, dart::Symbols::FromUTF8(thread_, content->buffer(), content->size()));
}


const dart::String& TranslationHelper::DartClassName(
    kernel::Class* kernel_klass) {
  if (kernel_klass->name() != NULL) {
    ASSERT(kernel_klass->IsNormalClass());
    dart::String& name = DartString(kernel_klass->name());
    return ManglePrivateName(kernel_klass->parent(), &name);
  } else {
    // Mixin class names are not mangled.
    ASSERT(kernel_klass->IsMixinClass());

    // We construct the string from right to left:
    //     "Base&Mixin1&Mixin2&...&MixinN"
    dart::String& partial = dart::String::Handle(Z, dart::String::New(""));
    dart::String& amp = dart::String::Handle(Z, dart::String::New("&"));
    dart::String& tmp = dart::String::Handle(Z);
    while (kernel_klass->name() == NULL) {
      ASSERT(kernel_klass->IsMixinClass());

      MixinClass* kernel_mixin_class = MixinClass::Cast(kernel_klass);
      InterfaceType* base_type = kernel_mixin_class->first();
      InterfaceType* mixin_type = kernel_mixin_class->second();

      String* mixin_name = NormalClass::Cast(mixin_type->klass())->name();

      tmp = dart::String::FromUTF8(mixin_name->buffer(), mixin_name->size());

      partial = dart::String::Concat(amp, partial);
      partial = dart::String::Concat(tmp, partial);

      kernel_klass = base_type->klass();
    }

    tmp = dart::String::FromUTF8(kernel_klass->name()->buffer(),
                                 kernel_klass->name()->size());

    partial = dart::String::Concat(amp, partial);
    partial = dart::String::Concat(tmp, partial);

    partial = dart::Symbols::New(thread_, partial);
    return partial;
  }
}


const dart::String& TranslationHelper::DartConstructorName(Constructor* node) {
  Class* klass = Class::Cast(node->parent());
  return DartFactoryName(klass, node->name());
}


const dart::String& TranslationHelper::DartProcedureName(Procedure* procedure) {
  if (procedure->kind() == Procedure::kSetter) {
    return DartSetterName(procedure->name());
  } else if (procedure->kind() == Procedure::kGetter) {
    return DartGetterName(procedure->name());
  } else if (procedure->kind() == Procedure::kFactory) {
    return DartFactoryName(Class::Cast(procedure->parent()), procedure->name());
  } else {
    return DartMethodName(procedure->name());
  }
}


const dart::String& TranslationHelper::DartSetterName(Name* kernel_name) {
  // The names flowing into [content] are coming from the Kernel file:
  //   * user-defined setters: `fieldname=`
  //   * property-set expressions:  `fieldname`
  //
  // The VM uses `get:fieldname` and `set:fieldname`.
  //
  // => In order to be consistent, we remove the `=` always and adopt the VM
  //    conventions.
  String* content = kernel_name->string();
  ASSERT(content->size() > 0);
  intptr_t skip = 0;
  if (content->buffer()[content->size() - 1] == '=') {
    skip = 1;
  }
  dart::String& name = dart::String::ZoneHandle(
      Z, dart::String::FromUTF8(content->buffer(), content->size() - skip));
  ManglePrivateName(kernel_name->library(), &name, false);
  name = dart::Field::SetterSymbol(name);
  return name;
}


const dart::String& TranslationHelper::DartGetterName(Name* kernel_name) {
  dart::String& name = DartString(kernel_name->string());
  ManglePrivateName(kernel_name->library(), &name, false);
  name = dart::Field::GetterSymbol(name);
  return name;
}


const dart::String& TranslationHelper::DartFieldName(Name* kernel_name) {
  dart::String& name = DartString(kernel_name->string());
  return ManglePrivateName(kernel_name->library(), &name);
}


const dart::String& TranslationHelper::DartInitializerName(Name* kernel_name) {
  // The [DartFieldName] will take care of mangling the name.
  dart::String& name =
      dart::String::Handle(Z, DartFieldName(kernel_name).raw());
  name = Symbols::FromConcat(thread_, Symbols::InitPrefix(), name);
  return name;
}


const dart::String& TranslationHelper::DartMethodName(Name* kernel_name) {
  dart::String& name = DartString(kernel_name->string());
  return ManglePrivateName(kernel_name->library(), &name);
}


const dart::String& TranslationHelper::DartFactoryName(Class* klass,
                                                       Name* method_name) {
  // [DartMethodName] will mangle the name.
  dart::String& name =
      dart::String::Handle(Z, DartMethodName(method_name).raw());

  // We build a String which looks like <classname>.<constructor-name>.
  // [DartClassName] will mangle the name.
  dart::String& temp = dart::String::Handle(Z, DartClassName(klass).raw());
  temp = dart::String::Concat(temp, Symbols::Dot());
  temp = dart::String::Concat(temp, name);
  return dart::String::ZoneHandle(Z, dart::Symbols::New(thread_, temp));
}


dart::RawLibrary* TranslationHelper::LookupLibraryByKernelLibrary(
    Library* kernel_library) {
  const dart::String& library_name = DartSymbol(kernel_library->import_uri());
  ASSERT(!library_name.IsNull());
  dart::RawLibrary* library =
      dart::Library::LookupLibrary(thread_, library_name);
  ASSERT(library != Object::null());
  return library;
}


dart::RawClass* TranslationHelper::LookupClassByKernelClass(
    Class* kernel_klass) {
  dart::RawClass* klass = NULL;

  const dart::String& class_name = DartClassName(kernel_klass);
  Library* kernel_library = Library::Cast(kernel_klass->parent());
  dart::Library& library =
      dart::Library::Handle(Z, LookupLibraryByKernelLibrary(kernel_library));
  klass = library.LookupClassAllowPrivate(class_name);

  ASSERT(klass != Object::null());
  return klass;
}


dart::RawField* TranslationHelper::LookupFieldByKernelField(
    Field* kernel_field) {
  TreeNode* node = kernel_field->parent();

  dart::Class& klass = dart::Class::Handle(Z);
  if (node->IsClass()) {
    klass = LookupClassByKernelClass(Class::Cast(node));
  } else {
    ASSERT(node->IsLibrary());
    dart::Library& library = dart::Library::Handle(
        Z, LookupLibraryByKernelLibrary(Library::Cast(node)));
    klass = library.toplevel_class();
  }
  dart::RawField* field =
      klass.LookupFieldAllowPrivate(DartSymbol(kernel_field->name()->string()));
  ASSERT(field != Object::null());
  return field;
}


dart::RawFunction* TranslationHelper::LookupStaticMethodByKernelProcedure(
    Procedure* procedure) {
  ASSERT(procedure->IsStatic());
  const dart::String& procedure_name = DartProcedureName(procedure);

  // The parent is either a library or a class (in which case the procedure is a
  // static method).
  TreeNode* parent = procedure->parent();
  if (parent->IsClass()) {
    dart::Class& klass =
        dart::Class::Handle(Z, LookupClassByKernelClass(Class::Cast(parent)));
    dart::RawFunction* raw_function =
        klass.LookupFunctionAllowPrivate(procedure_name);
    ASSERT(raw_function != Object::null());

    // TODO(27590): We can probably get rid of this after no longer using
    // core libraries from the source.
    dart::Function& function = dart::Function::ZoneHandle(Z, raw_function);
    if (function.IsRedirectingFactory()) {
      ClassFinalizer::ResolveRedirectingFactory(klass, function);
      function = function.RedirectionTarget();
    }
    return function.raw();
  } else {
    ASSERT(parent->IsLibrary());
    dart::Library& library = dart::Library::Handle(
        Z, LookupLibraryByKernelLibrary(Library::Cast(parent)));
    dart::RawFunction* function =
        library.LookupFunctionAllowPrivate(procedure_name);
    ASSERT(function != Object::null());
    return function;
  }
}


dart::RawFunction* TranslationHelper::LookupConstructorByKernelConstructor(
    Constructor* constructor) {
  Class* kernel_klass = Class::Cast(constructor->parent());
  dart::Class& klass =
      dart::Class::Handle(Z, LookupClassByKernelClass(kernel_klass));
  return LookupConstructorByKernelConstructor(klass, constructor);
}


dart::RawFunction* TranslationHelper::LookupConstructorByKernelConstructor(
    const dart::Class& owner, Constructor* constructor) {
  dart::RawFunction* function =
      owner.LookupConstructorAllowPrivate(DartConstructorName(constructor));
  ASSERT(function != Object::null());
  return function;
}


dart::Type& TranslationHelper::GetCanonicalType(const dart::Class& klass) {
  ASSERT(!klass.IsNull());
  // Note that if cls is _Closure, the returned type will be _Closure,
  // and not the signature type.
  Type& type = Type::ZoneHandle(Z, klass.CanonicalType());
  if (!type.IsNull()) {
    return type;
  }
  type = Type::New(klass, TypeArguments::Handle(Z, klass.type_parameters()),
                   klass.token_pos());
  if (klass.is_type_finalized()) {
    type ^= ClassFinalizer::FinalizeType(
        klass, type, ClassFinalizer::kCanonicalizeWellFormed);
    // Note that the receiver type may now be a malbounded type.
    klass.SetCanonicalType(type);
  }
  return type;
}


void TranslationHelper::ReportError(const char* format, ...) {
  const Script& null_script = Script::Handle(Z);

  va_list args;
  va_start(args, format);
  Report::MessageV(Report::kError, null_script, TokenPosition::kNoSource,
                   Report::AtLocation, format, args);
  va_end(args);
  UNREACHABLE();
}


void TranslationHelper::ReportError(const Error& prev_error, const char* format,
                                    ...) {
  const Script& null_script = Script::Handle(Z);

  va_list args;
  va_start(args, format);
  Report::LongJumpV(prev_error, null_script, TokenPosition::kNoSource, format,
                    args);
  va_end(args);
  UNREACHABLE();
}


dart::String& TranslationHelper::ManglePrivateName(Library* kernel_library,
                                                   dart::String* name_to_modify,
                                                   bool symbolize) {
  if (name_to_modify->Length() >= 1 && name_to_modify->CharAt(0) == '_') {
    const dart::Library& library =
        dart::Library::Handle(Z, LookupLibraryByKernelLibrary(kernel_library));
    *name_to_modify = library.PrivateName(*name_to_modify);
  } else if (symbolize) {
    *name_to_modify = Symbols::New(thread_, *name_to_modify);
  }
  return *name_to_modify;
}


const Array& TranslationHelper::ArgumentNames(List<NamedExpression>* named) {
  if (named->length() == 0) return Array::ZoneHandle(Z);

  const Array& names = Array::ZoneHandle(Z, Array::New(named->length()));
  for (intptr_t i = 0; i < named->length(); ++i) {
    names.SetAt(i, DartSymbol((*named)[i]->name()));
  }
  return names;
}


Instance& ConstantEvaluator::EvaluateExpression(Expression* expression) {
  expression->AcceptExpressionVisitor(this);
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return dart::Instance::ZoneHandle(Z, result_.raw());
}


Object& ConstantEvaluator::EvaluateExpressionSafe(Expression* expression) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    return EvaluateExpression(expression);
  } else {
    Thread* thread = Thread::Current();
    Error& error = Error::Handle(Z);
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error;
  }
}


Instance& ConstantEvaluator::EvaluateConstructorInvocation(
    ConstructorInvocation* node) {
  VisitConstructorInvocation(node);
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return dart::Instance::ZoneHandle(Z, result_.raw());
}


Instance& ConstantEvaluator::EvaluateListLiteral(ListLiteral* node) {
  VisitListLiteral(node);
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return dart::Instance::ZoneHandle(Z, result_.raw());
}


Instance& ConstantEvaluator::EvaluateMapLiteral(MapLiteral* node) {
  VisitMapLiteral(node);
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return dart::Instance::ZoneHandle(Z, result_.raw());
}


void ConstantEvaluator::VisitBigintLiteral(BigintLiteral* node) {
  const dart::String& value = H.DartString(node->value());
  result_ = Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitBoolLiteral(BoolLiteral* node) {
  result_ = dart::Bool::Get(node->value()).raw();
}


void ConstantEvaluator::VisitDoubleLiteral(DoubleLiteral* node) {
  result_ = dart::Double::New(H.DartString(node->value()), Heap::kOld);
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitIntLiteral(IntLiteral* node) {
  result_ = dart::Integer::New(node->value(), Heap::kOld);
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitNullLiteral(NullLiteral* node) {
  result_ = dart::Instance::null();
}


void ConstantEvaluator::VisitStringLiteral(StringLiteral* node) {
  result_ = H.DartSymbol(node->value()).raw();
}


void ConstantEvaluator::VisitTypeLiteral(TypeLiteral* node) {
  const AbstractType& type = T.TranslateType(node->type());
  if (type.IsMalformed()) {
    H.ReportError("Malformed type literal in constant expression.");
  }
  result_ = type.raw();
}


RawObject* ConstantEvaluator::EvaluateConstConstructorCall(
    const dart::Class& type_class, const TypeArguments& type_arguments,
    const Function& constructor, const Object& argument) {
  // Factories have one extra argument: the type arguments.
  // Constructors have 1 extra arguments: receiver.
  const int kNumArgs = 1;
  const int kNumExtraArgs = 1;
  const int num_arguments = kNumArgs + kNumExtraArgs;
  const Array& arg_values =
      Array::Handle(Z, Array::New(num_arguments, Heap::kOld));
  Instance& instance = Instance::Handle(Z);
  if (!constructor.IsFactory()) {
    instance = Instance::New(type_class, Heap::kOld);
    if (!type_arguments.IsNull()) {
      ASSERT(type_arguments.IsInstantiated());
      instance.SetTypeArguments(
          TypeArguments::Handle(Z, type_arguments.Canonicalize()));
    }
    arg_values.SetAt(0, instance);
  } else {
    // Prepend type_arguments to list of arguments to factory.
    ASSERT(type_arguments.IsZoneHandle());
    arg_values.SetAt(0, type_arguments);
  }
  arg_values.SetAt((0 + kNumExtraArgs), argument);
  const Array& args_descriptor = Array::Handle(
      Z, ArgumentsDescriptor::New(num_arguments, Object::empty_array()));
  const Object& result = Object::Handle(
      Z, DartEntry::InvokeFunction(constructor, arg_values, args_descriptor));
  ASSERT(!result.IsError());
  if (constructor.IsFactory()) {
    // The factory method returns the allocated object.
    instance ^= result.raw();
  }
  return H.Canonicalize(instance);
}


void ConstantEvaluator::VisitSymbolLiteral(SymbolLiteral* node) {
  const dart::String& symbol_value = H.DartSymbol(node->value());

  const dart::Class& symbol_class =
      dart::Class::ZoneHandle(Z, I->object_store()->symbol_class());
  ASSERT(!symbol_class.IsNull());
  const dart::Function& symbol_constructor = Function::ZoneHandle(
      Z, symbol_class.LookupConstructor(Symbols::SymbolCtor()));
  ASSERT(!symbol_constructor.IsNull());
  result_ ^= EvaluateConstConstructorCall(
      symbol_class, TypeArguments::Handle(Z), symbol_constructor, symbol_value);
}


void ConstantEvaluator::VisitListLiteral(ListLiteral* node) {
  DartType* types[] = {node->type()};
  const TypeArguments& type_arguments = T.TranslateTypeArguments(types, 1);

  intptr_t length = node->expressions().length();
  const Array& const_list =
      Array::ZoneHandle(Z, Array::New(length, Heap::kOld));
  const_list.SetTypeArguments(type_arguments);
  for (intptr_t i = 0; i < length; i++) {
    const Instance& expression = EvaluateExpression(node->expressions()[i]);
    const_list.SetAt(i, expression);
  }
  const_list.MakeImmutable();
  result_ = H.Canonicalize(const_list);
}


void ConstantEvaluator::VisitMapLiteral(MapLiteral* node) {
  DartType* types[] = {node->key_type(), node->value_type()};
  const TypeArguments& type_arguments = T.TranslateTypeArguments(types, 2);

  intptr_t length = node->entries().length();

  Array& const_kv_array =
      Array::ZoneHandle(Z, Array::New(2 * length, Heap::kOld));
  for (intptr_t i = 0; i < length; i++) {
    const_kv_array.SetAt(2 * i + 0,
                         EvaluateExpression(node->entries()[i]->key()));
    const_kv_array.SetAt(2 * i + 1,
                         EvaluateExpression(node->entries()[i]->value()));
  }

  const_kv_array.MakeImmutable();
  const_kv_array ^= H.Canonicalize(const_kv_array);

  const dart::Class& map_class = dart::Class::Handle(
      Z, dart::Library::LookupCoreClass(Symbols::ImmutableMap()));
  ASSERT(!map_class.IsNull());
  ASSERT(map_class.NumTypeArguments() == 2);

  const dart::Field& field = dart::Field::Handle(
      Z, map_class.LookupInstanceFieldAllowPrivate(H.DartSymbol("_kvPairs")));
  ASSERT(!field.IsNull());

  // NOTE: This needs to be kept in sync with `runtime/lib/immutable_map.dart`!
  result_ = Instance::New(map_class, Heap::kOld);
  ASSERT(!result_.IsNull());
  result_.SetTypeArguments(type_arguments);
  result_.SetField(field, const_kv_array);
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitConstructorInvocation(
    ConstructorInvocation* node) {
  Arguments* kernel_arguments = node->arguments();

  const Function& constructor = Function::Handle(
      Z, H.LookupConstructorByKernelConstructor(node->target()));
  dart::Class& klass = dart::Class::Handle(Z, constructor.Owner());

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(constructor, &klass, kernel_arguments);

  // Prepare either the instance or the type argument vector for the constructor
  // call.
  Instance* receiver = NULL;
  const TypeArguments* type_arguments_argument = NULL;
  if (!constructor.IsFactory()) {
    receiver = &Instance::ZoneHandle(Z, Instance::New(klass, Heap::kOld));
    if (type_arguments != NULL) {
      receiver->SetTypeArguments(*type_arguments);
    }
  } else {
    type_arguments_argument = type_arguments;
  }

  const Object& result = RunFunction(constructor, kernel_arguments, receiver,
                                     type_arguments_argument);
  if (constructor.IsFactory()) {
    // Factories return the new object.
    result_ ^= result.raw();
    result_ = H.Canonicalize(result_);
  } else {
    ASSERT(!receiver->IsNull());
    result_ = H.Canonicalize(*receiver);
  }
}


void ConstantEvaluator::VisitMethodInvocation(MethodInvocation* node) {
  Arguments* kernel_arguments = node->arguments();

  // Dart does not support generic methods yet.
  ASSERT(kernel_arguments->types().length() == 0);

  const dart::Instance& receiver = EvaluateExpression(node->receiver());
  dart::Class& klass = dart::Class::Handle(
      Z, isolate_->class_table()->At(receiver.GetClassId()));
  ASSERT(!klass.IsNull());

  // Search the superclass chain for the selector.
  // TODO(27590): Can we assume this will never be a no-such-method error?
  dart::Function& function = dart::Function::Handle(Z);
  const dart::String& method_name = H.DartMethodName(node->name());
  while (!klass.IsNull()) {
    function = klass.LookupDynamicFunctionAllowPrivate(method_name);
    if (!function.IsNull()) break;
    klass = klass.SuperClass();
  }
  ASSERT(!function.IsNull());

  // Run the method and canonicalize the result.
  const Object& result = RunFunction(function, kernel_arguments, &receiver);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitStaticGet(StaticGet* node) {
  Member* member = node->target();
  if (member->IsField()) {
    Field* kernel_field = Field::Cast(member);
    const dart::Field& field =
        dart::Field::Handle(Z, H.LookupFieldByKernelField(kernel_field));
    if (field.StaticValue() == Object::sentinel().raw() ||
        field.StaticValue() == Object::transition_sentinel().raw()) {
      field.EvaluateInitializer();
      result_ = field.StaticValue();
      result_ = H.Canonicalize(result_);
      field.SetStaticValue(result_, true);
    } else {
      result_ = field.StaticValue();
    }
  } else if (member->IsProcedure()) {
    Procedure* procedure = Procedure::Cast(member);
    const Function& target = Function::ZoneHandle(
        Z, H.LookupStaticMethodByKernelProcedure(procedure));

    if (procedure->kind() == Procedure::kMethod) {
      ASSERT(procedure->IsStatic());
      Function& closure_function =
          Function::ZoneHandle(Z, target.ImplicitClosureFunction());
      closure_function.set_kernel_function(target.kernel_function());
      result_ = closure_function.ImplicitStaticClosure();
      result_ = H.Canonicalize(result_);
    } else if (procedure->kind() == Procedure::kGetter) {
      UNIMPLEMENTED();
    } else {
      UNIMPLEMENTED();
    }
  }
}


void ConstantEvaluator::VisitVariableGet(VariableGet* node) {
  // When we see a [VariableGet] the corresponding [VariableDeclaration] must've
  // been executed already. It therefore must have a constant object associated
  // with it.
  LocalVariable* variable = builder_->LookupVariable(node->variable());
  ASSERT(variable->IsConst());
  result_ = variable->ConstValue()->raw();
}


void ConstantEvaluator::VisitLet(Let* node) {
  VariableDeclaration* variable = node->variable();
  LocalVariable* local = builder_->LookupVariable(variable);
  local->SetConstValue(EvaluateExpression(variable->initializer()));
  node->body()->AcceptExpressionVisitor(this);
}


void ConstantEvaluator::VisitStaticInvocation(StaticInvocation* node) {
  const Function& function = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(node->procedure()));
  dart::Class& klass = dart::Class::Handle(Z, function.Owner());

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(function, &klass, node->arguments());

  const Object& result =
      RunFunction(function, node->arguments(), NULL, type_arguments);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitStringConcatenation(StringConcatenation* node) {
  intptr_t length = node->expressions().length();

  bool all_string = true;
  const Array& strings = Array::Handle(Z, Array::New(length));
  for (intptr_t i = 0; i < length; i++) {
    EvaluateExpression(node->expressions()[i]);
    strings.SetAt(i, result_);
    all_string = all_string && result_.IsString();
  }
  if (all_string) {
    result_ = dart::String::ConcatAll(strings, Heap::kOld);
    result_ = H.Canonicalize(result_);
  } else {
    // Get string interpolation function.
    const dart::Class& cls = dart::Class::Handle(
        Z, dart::Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    const Function& func = Function::Handle(
        Z, cls.LookupStaticFunction(
               dart::Library::PrivateCoreLibName(Symbols::Interpolate())));
    ASSERT(!func.IsNull());

    // Build argument array to pass to the interpolation function.
    const Array& interpolate_arg = Array::Handle(Z, Array::New(1, Heap::kOld));
    interpolate_arg.SetAt(0, strings);

    // Run and canonicalize.
    const Object& result =
        RunFunction(func, interpolate_arg, Array::null_array());
    result_ = H.Canonicalize(dart::String::Cast(result));
  }
}


void ConstantEvaluator::VisitConditionalExpression(
    ConditionalExpression* node) {
  EvaluateExpression(node->condition());
  if (Bool::Cast(result_).value()) {
    EvaluateExpression(node->then());
  } else {
    EvaluateExpression(node->otherwise());
  }
}


void ConstantEvaluator::VisitLogicalExpression(LogicalExpression* node) {
  if (node->op() == LogicalExpression::kAnd) {
    EvaluateExpression(node->left());
    if (Bool::Cast(result_).value()) {
      EvaluateExpression(node->right());
    }
  } else {
    ASSERT(node->op() == LogicalExpression::kOr);
    EvaluateExpression(node->left());
    if (!Bool::Cast(result_).value()) {
      EvaluateExpression(node->right());
    }
  }
}


void ConstantEvaluator::VisitNot(Not* node) {
  EvaluateExpression(node->expression());
  ASSERT(result_.IsBool());
  result_ =
      Bool::Cast(result_).value() ? Bool::False().raw() : Bool::True().raw();
}


const TypeArguments* ConstantEvaluator::TranslateTypeArguments(
    const Function& target, dart::Class* target_klass,
    Arguments* kernel_arguments) {
  List<DartType>& kernel_type_arguments = kernel_arguments->types();

  const TypeArguments* type_arguments = NULL;
  if (kernel_type_arguments.length() > 0) {
    type_arguments = &T.TranslateInstantiatedTypeArguments(
        *target_klass, kernel_type_arguments.raw_array(),
        kernel_type_arguments.length());

    if (!(type_arguments->IsNull() || type_arguments->IsInstantiated())) {
      H.ReportError("Type must be constant in const constructor.");
    }
  } else if (target.IsFactory() && type_arguments == NULL) {
    // All factories take a type arguments vector as first argument (independent
    // of whether the class is generic or not).
    type_arguments = &TypeArguments::ZoneHandle(Z, TypeArguments::null());
  }
  return type_arguments;
}


const Object& ConstantEvaluator::RunFunction(const Function& function,
                                             Arguments* kernel_arguments,
                                             const Instance* receiver,
                                             const TypeArguments* type_args) {
  // We do not support generic methods yet.
  ASSERT((receiver == NULL) || (type_args == NULL));
  intptr_t extra_arguments =
      (receiver != NULL ? 1 : 0) + (type_args != NULL ? 1 : 0);

  // Build up arguments.
  const Array& arguments = Array::ZoneHandle(
      Z, Array::New(extra_arguments + kernel_arguments->count()));
  const Array& names =
      Array::ZoneHandle(Z, Array::New(kernel_arguments->named().length()));
  intptr_t pos = 0;
  if (receiver != NULL) {
    arguments.SetAt(pos++, *receiver);
  }
  if (type_args != NULL) {
    arguments.SetAt(pos++, *type_args);
  }
  for (intptr_t i = 0; i < kernel_arguments->positional().length(); i++) {
    EvaluateExpression(kernel_arguments->positional()[i]);
    arguments.SetAt(pos++, result_);
  }
  for (intptr_t i = 0; i < kernel_arguments->named().length(); i++) {
    NamedExpression* named_expression = kernel_arguments->named()[i];
    EvaluateExpression(named_expression->expression());
    arguments.SetAt(pos++, result_);
    names.SetAt(i, H.DartSymbol(named_expression->name()));
  }
  return RunFunction(function, arguments, names);
}


const Object& ConstantEvaluator::RunFunction(const Function& function,
                                             const Array& arguments,
                                             const Array& names) {
  const Array& args_descriptor =
      Array::Handle(Z, ArgumentsDescriptor::New(arguments.Length(), names));
  const Object& result = Object::Handle(
      Z, DartEntry::InvokeFunction(function, arguments, args_descriptor));
  if (result.IsError()) {
    H.ReportError(Error::Cast(result), "error evaluating constant constructor");
  }
  return result;
}


FlowGraphBuilder::FlowGraphBuilder(
    TreeNode* node, ParsedFunction* parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    InlineExitCollector* exit_collector, intptr_t osr_id,
    intptr_t first_block_id)
    : zone_(Thread::Current()->zone()),
      translation_helper_(Thread::Current(), zone_,
                          Thread::Current()->isolate()),
      node_(node),
      parsed_function_(parsed_function),
      osr_id_(osr_id),
      ic_data_array_(ic_data_array),
      exit_collector_(exit_collector),
      next_block_id_(first_block_id),
      next_function_id_(0),
      context_depth_(0),
      loop_depth_(0),
      try_depth_(0),
      catch_depth_(0),
      for_in_depth_(0),
      stack_(NULL),
      pending_argument_count_(0),
      graph_entry_(NULL),
      scopes_(NULL),
      breakable_block_(NULL),
      switch_block_(NULL),
      try_finally_block_(NULL),
      try_catch_block_(NULL),
      next_used_try_index_(0),
      catch_block_(NULL),
      type_translator_(&translation_helper_, &active_class_),
      constant_evaluator_(this, zone_, &translation_helper_,
                          &type_translator_) {}


FlowGraphBuilder::~FlowGraphBuilder() {}


Fragment FlowGraphBuilder::TranslateFinallyFinalizers(
    TryFinallyBlock* outer_finally, intptr_t target_context_depth) {
  TryFinallyBlock* const saved_block = try_finally_block_;
  const intptr_t saved_depth = context_depth_;
  const intptr_t saved_try_depth = try_depth_;

  Fragment instructions;

  // While translating the body of a finalizer we need to set the try-finally
  // block which is active when translating the body.
  while (try_finally_block_ != outer_finally) {
    // Set correct try depth (in case there are nested try statements).
    try_depth_ = try_finally_block_->try_depth();

    // Potentially restore the context to what is expected for the finally
    // block.
    instructions += AdjustContextTo(try_finally_block_->context_depth());

    Statement* finalizer = try_finally_block_->finalizer();
    try_finally_block_ = try_finally_block_->outer();

    // This will potentially have exceptional cases as described in
    // [VisitTryFinally] and will handle them.
    instructions += TranslateStatement(finalizer);

    // We only need to make sure that if the finalizer ended normally, we
    // continue towards the next outer try-finally.
    if (!instructions.is_open()) break;
  }

  if (instructions.is_open() && target_context_depth != -1) {
    // A target context depth of -1 indicates that we the code after this
    // will not care about the context chain so we can leave it any way we
    // want after the last finalizer.  That is used when returning.
    instructions += AdjustContextTo(target_context_depth);
  }

  try_finally_block_ = saved_block;
  context_depth_ = saved_depth;
  try_depth_ = saved_try_depth;

  return instructions;
}


Fragment FlowGraphBuilder::EnterScope(TreeNode* node, bool* new_context) {
  Fragment instructions;
  const intptr_t context_size =
      scopes_->scopes.Lookup(node)->num_context_variables();
  if (context_size > 0) {
    instructions += PushContext(context_size);
    instructions += Drop();
    if (new_context != NULL) {
      *new_context = true;
    }
  }
  return instructions;
}


Fragment FlowGraphBuilder::ExitScope(TreeNode* node) {
  Fragment instructions;
  const intptr_t context_size =
      scopes_->scopes.Lookup(node)->num_context_variables();
  if (context_size > 0) {
    instructions += PopContext();
  }
  return instructions;
}


Fragment FlowGraphBuilder::LoadContextAt(int depth) {
  intptr_t delta = context_depth_ - depth;
  ASSERT(delta >= 0);
  Fragment instructions = LoadLocal(parsed_function_->current_context_var());
  while (delta-- > 0) {
    instructions += LoadField(Context::parent_offset());
  }
  return instructions;
}


Fragment FlowGraphBuilder::AdjustContextTo(int depth) {
  ASSERT(depth <= context_depth_ && depth >= 0);
  Fragment instructions;
  if (depth < context_depth_) {
    instructions += LoadContextAt(depth);
    instructions += StoreLocal(parsed_function_->current_context_var());
    instructions += Drop();
    context_depth_ = depth;
  }
  return instructions;
}


Fragment FlowGraphBuilder::PushContext(int size) {
  ASSERT(size > 0);
  Fragment instructions = AllocateContext(size);
  LocalVariable* context = MakeTemporary();
  instructions += LoadLocal(context);
  instructions += LoadLocal(parsed_function_->current_context_var());
  instructions += StoreInstanceField(Context::parent_offset());
  instructions += StoreLocal(parsed_function_->current_context_var());
  ++context_depth_;
  return instructions;
}


Fragment FlowGraphBuilder::PopContext() {
  return AdjustContextTo(context_depth_ - 1);
}


Fragment FlowGraphBuilder::LoadInstantiatorTypeArguments() {
  // TODO(27590): We could use `active_class_->IsGeneric()`.
  Fragment instructions;
  if (scopes_->type_arguments_variable != NULL) {
#ifdef DEBUG
    Function& function =
        Function::Handle(Z, parsed_function_->function().raw());
    while (function.IsClosureFunction()) {
      function = function.parent_function();
    }
    ASSERT(function.IsFactory());
#endif
    instructions += LoadLocal(scopes_->type_arguments_variable);
  } else if (scopes_->this_variable != NULL &&
             active_class_.kernel_class != NULL &&
             active_class_.kernel_class->type_parameters().length() > 0) {
    ASSERT(!parsed_function_->function().IsFactory());
    intptr_t type_arguments_field_offset =
        active_class_.klass->type_arguments_field_offset();
    ASSERT(type_arguments_field_offset != dart::Class::kNoTypeArguments);

    instructions += LoadLocal(scopes_->this_variable);
    instructions += LoadField(type_arguments_field_offset);
  } else {
    instructions += NullConstant();
  }
  return instructions;
}


Fragment FlowGraphBuilder::InstantiateTypeArguments(
    const TypeArguments& type_arguments) {
  InstantiateTypeArgumentsInstr* instr = new (Z) InstantiateTypeArgumentsInstr(
      TokenPosition::kNoSource, type_arguments, *active_class_.klass, Pop());
  Push(instr);
  return Fragment(instr);
}


Fragment FlowGraphBuilder::TranslateInstantiatedTypeArguments(
    const TypeArguments& type_arguments) {
  Fragment instructions;

  if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
    // There are no type references to type parameters so we can just take it.
    instructions += Constant(type_arguments);
  } else {
    // The [type_arguments] vector contains a type reference to a type
    // parameter we need to resolve it.
    const bool use_instantiator =
        type_arguments.IsUninstantiatedIdentity() ||
        type_arguments.CanShareInstantiatorTypeArguments(*active_class_.klass);
    if (use_instantiator) {
      // If the instantiator type arguments are just passed on, we don't need to
      // resolve the type parameters.
      //
      // This is for example the case here:
      //     class Foo<T> {
      //       newList() => new List<T>();
      //     }
      // We just use the type argument vector from the [Foo] object and pass it
      // directly to the `new List<T>()` factory constructor.
      instructions += LoadInstantiatorTypeArguments();
    } else {
      // Otherwise we need to resolve [TypeParameterType]s in the type
      // expression based on the current instantiator type argument vector.
      instructions += LoadInstantiatorTypeArguments();
      instructions += InstantiateTypeArguments(type_arguments);
    }
  }
  return instructions;
}


Fragment FlowGraphBuilder::AllocateContext(int size) {
  AllocateContextInstr* allocate =
      new (Z) AllocateContextInstr(TokenPosition::kNoSource, size);
  Push(allocate);
  return Fragment(allocate);
}


Fragment FlowGraphBuilder::AllocateObject(const dart::Class& klass,
                                          intptr_t argument_count) {
  ArgumentArray arguments = GetArguments(argument_count);
  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(TokenPosition::kNoSource, klass, arguments);
  Push(allocate);
  return Fragment(allocate);
}


Fragment FlowGraphBuilder::AllocateObject(const dart::Class& klass,
                                          const Function& closure_function) {
  ArgumentArray arguments = new (Z) ZoneGrowableArray<PushArgumentInstr*>(Z, 0);
  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(TokenPosition::kNoSource, klass, arguments);
  allocate->set_closure_function(closure_function);
  Push(allocate);
  return Fragment(allocate);
}


Fragment FlowGraphBuilder::BooleanNegate() {
  BooleanNegateInstr* negate = new (Z) BooleanNegateInstr(Pop());
  Push(negate);
  return Fragment(negate);
}


Fragment FlowGraphBuilder::StrictCompare(Token::Kind kind,
                                         bool number_check /* = false */) {
  Value* right = Pop();
  Value* left = Pop();
  StrictCompareInstr* compare = new (Z) StrictCompareInstr(
      TokenPosition::kNoSource, kind, left, right, number_check);
  Push(compare);
  return Fragment(compare);
}


Fragment FlowGraphBuilder::BranchIfTrue(TargetEntryInstr** then_entry,
                                        TargetEntryInstr** otherwise_entry,
                                        bool negate) {
  Fragment instructions = Constant(Bool::True());
  return instructions + BranchIfEqual(then_entry, otherwise_entry, negate);
}


Fragment FlowGraphBuilder::BranchIfNull(TargetEntryInstr** then_entry,
                                        TargetEntryInstr** otherwise_entry,
                                        bool negate) {
  Fragment instructions = NullConstant();
  return instructions + BranchIfEqual(then_entry, otherwise_entry, negate);
}

Fragment FlowGraphBuilder::BranchIfEqual(TargetEntryInstr** then_entry,
                                         TargetEntryInstr** otherwise_entry,
                                         bool negate) {
  Value* right_value = Pop();
  Value* left_value = Pop();
  StrictCompareInstr* compare = new (Z) StrictCompareInstr(
      TokenPosition::kNoSource, negate ? Token::kNE_STRICT : Token::kEQ_STRICT,
      left_value, right_value, false);
  BranchInstr* branch = new (Z) BranchInstr(compare);
  *then_entry = *branch->true_successor_address() = BuildTargetEntry();
  *otherwise_entry = *branch->false_successor_address() = BuildTargetEntry();
  return Fragment(branch).closed();
}


Fragment FlowGraphBuilder::BranchIfStrictEqual(
    TargetEntryInstr** then_entry, TargetEntryInstr** otherwise_entry) {
  Value* rhs = Pop();
  Value* lhs = Pop();
  StrictCompareInstr* compare = new (Z) StrictCompareInstr(
      TokenPosition::kNoSource, Token::kEQ_STRICT, lhs, rhs, false);
  BranchInstr* branch = new (Z) BranchInstr(compare);
  *then_entry = *branch->true_successor_address() = BuildTargetEntry();
  *otherwise_entry = *branch->false_successor_address() = BuildTargetEntry();
  return Fragment(branch).closed();
}


Fragment FlowGraphBuilder::CatchBlockEntry(const Array& handler_types,
                                           intptr_t handler_index) {
  ASSERT(CurrentException()->is_captured() ==
             CurrentStackTrace()->is_captured());
  const bool should_restore_closure_context =
      CurrentException()->is_captured() ||
      CurrentCatchContext()->is_captured();
  CatchBlockEntryInstr* entry = new (Z) CatchBlockEntryInstr(
      AllocateBlockId(), CurrentTryIndex(), graph_entry_, handler_types,
      handler_index, *CurrentException(), *CurrentStackTrace(),
      /* needs_stacktrace = */ true, Thread::Current()->GetNextDeoptId(),
      should_restore_closure_context);
  graph_entry_->AddCatchEntry(entry);
  Fragment instructions(entry);

  // :saved_try_context_var can be captured in the context of
  // of the closure, in this case CatchBlockEntryInstr restores
  // :current_context_var to point to closure context in the
  // same way as normal function prologue does.
  // Update current context depth to reflect that.
  const intptr_t saved_context_depth = context_depth_;
  ASSERT(!CurrentCatchContext()->is_captured() ||
         CurrentCatchContext()->owner()->context_level() == 0);
  context_depth_ = 0;
  instructions += LoadLocal(CurrentCatchContext());
  instructions += StoreLocal(parsed_function_->current_context_var());
  instructions += Drop();
  context_depth_ = saved_context_depth;

  return instructions;
}


Fragment FlowGraphBuilder::TryCatch(int try_handler_index) {
  // The body of the try needs to have it's own block in order to get a new try
  // index.
  //
  // => We therefore create a block for the body (fresh try index) and another
  //    join block (with current try index).
  Fragment body;
  JoinEntryInstr* entry =
      new (Z) JoinEntryInstr(AllocateBlockId(), try_handler_index);
  body += LoadLocal(parsed_function_->current_context_var());
  body += StoreLocal(CurrentCatchContext());
  body += Drop();
  body += Goto(entry);
  return Fragment(body.entry, entry);
}


Fragment FlowGraphBuilder::CheckStackOverflowInPrologue() {
  if (IsInlining()) {
    // If we are inlining don't actually attach the stack check.  We must still
    // create the stack check in order to allocate a deopt id.
    CheckStackOverflow();
    return Fragment();
  }
  return CheckStackOverflow();
}


Fragment FlowGraphBuilder::CheckStackOverflow() {
  return Fragment(
      new (Z) CheckStackOverflowInstr(TokenPosition::kNoSource, loop_depth_));
}


Fragment FlowGraphBuilder::CloneContext() {
  LocalVariable* context_variable = parsed_function_->current_context_var();

  Fragment instructions = LoadLocal(context_variable);

  CloneContextInstr* clone_instruction =
      new (Z) CloneContextInstr(TokenPosition::kNoSource, Pop());
  instructions <<= clone_instruction;
  Push(clone_instruction);

  instructions += StoreLocal(context_variable);
  instructions += Drop();
  return instructions;
}


Fragment FlowGraphBuilder::Constant(const Object& value) {
  ASSERT(value.IsNotTemporaryScopedHandle());
  ConstantInstr* constant = new (Z) ConstantInstr(value);
  Push(constant);
  return Fragment(constant);
}


Fragment FlowGraphBuilder::CreateArray() {
  Value* element_count = Pop();
  CreateArrayInstr* array = new (Z) CreateArrayInstr(TokenPosition::kNoSource,
                                                     Pop(),  // Element type.
                                                     element_count);
  Push(array);
  return Fragment(array);
}


Fragment FlowGraphBuilder::Goto(JoinEntryInstr* destination) {
  return Fragment(new (Z) GotoInstr(destination)).closed();
}


Fragment FlowGraphBuilder::IntConstant(int64_t value) {
  return Fragment(
      Constant(Integer::ZoneHandle(Z, Integer::New(value, Heap::kOld))));
}


Fragment FlowGraphBuilder::InstanceCall(const dart::String& name,
                                        Token::Kind kind,
                                        intptr_t argument_count,
                                        intptr_t num_args_checked) {
  return InstanceCall(name, kind, argument_count, Array::null_array(),
                      num_args_checked);
}


Fragment FlowGraphBuilder::InstanceCall(const dart::String& name,
                                        Token::Kind kind,
                                        intptr_t argument_count,
                                        const Array& argument_names,
                                        intptr_t num_args_checked) {
  ArgumentArray arguments = GetArguments(argument_count);
  InstanceCallInstr* call = new (Z)
      InstanceCallInstr(TokenPosition::kNoSource, name, kind, arguments,
                        argument_names, num_args_checked, ic_data_array_);
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::ClosureCall(int argument_count,
                                       const Array& argument_names) {
  Value* function = Pop();
  ArgumentArray arguments = GetArguments(argument_count);
  ClosureCallInstr* call = new (Z) ClosureCallInstr(
      function, arguments, argument_names, TokenPosition::kNoSource);
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::ThrowException() {
  Fragment instructions;
  instructions += Drop();
  instructions +=
      Fragment(new (Z) ThrowInstr(TokenPosition::kNoSource)).closed();
  // Use it's side effect of leaving a constant on the stack (does not change
  // the graph).
  NullConstant();

  pending_argument_count_ -= 1;

  return instructions;
}


Fragment FlowGraphBuilder::RethrowException(int catch_try_index) {
  Fragment instructions;
  instructions += Drop();
  instructions += Drop();
  instructions +=
      Fragment(new (Z) ReThrowInstr(TokenPosition::kNoSource, catch_try_index))
          .closed();
  // Use it's side effect of leaving a constant on the stack (does not change
  // the graph).
  NullConstant();

  pending_argument_count_ -= 2;

  return instructions;
}


Fragment FlowGraphBuilder::LoadClassId() {
  LoadClassIdInstr* load = new (Z) LoadClassIdInstr(Pop());
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::LoadField(const dart::Field& field) {
  LoadFieldInstr* load = new (Z)
      LoadFieldInstr(Pop(), &field, AbstractType::ZoneHandle(Z, field.type()),
                     TokenPosition::kNoSource);
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::LoadField(intptr_t offset, intptr_t class_id) {
  LoadFieldInstr* load = new (Z) LoadFieldInstr(
      Pop(), offset, AbstractType::ZoneHandle(Z), TokenPosition::kNoSource);
  load->set_result_cid(class_id);
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::LoadNativeField(MethodRecognizer::Kind kind,
                                           intptr_t offset, const Type& type,
                                           intptr_t class_id,
                                           bool is_immutable) {
  LoadFieldInstr* load =
      new (Z) LoadFieldInstr(Pop(), offset, type, TokenPosition::kNoSource);
  load->set_recognized_kind(kind);
  load->set_result_cid(class_id);
  load->set_is_immutable(is_immutable);
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  Fragment instructions;
  if (variable->is_captured()) {
    instructions += LoadContextAt(variable->owner()->context_level());
    instructions += LoadField(Context::variable_offset(variable->index()));
  } else {
    LoadLocalInstr* load =
        new (Z) LoadLocalInstr(*variable, TokenPosition::kNoSource);
    instructions <<= load;
    Push(load);
  }
  return instructions;
}


Fragment FlowGraphBuilder::InitStaticField(const dart::Field& field) {
  InitStaticFieldInstr* init = new (Z) InitStaticFieldInstr(Pop(), field);
  return Fragment(init);
}


Fragment FlowGraphBuilder::LoadStaticField() {
  LoadStaticFieldInstr* load =
      new (Z) LoadStaticFieldInstr(Pop(), TokenPosition::kNoSource);
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::NullConstant() {
  return Constant(Instance::ZoneHandle(Z, Instance::null()));
}


Fragment FlowGraphBuilder::NativeCall(const dart::String* name,
                                      const Function* function) {
  InlineBailout("kernel::FlowGraphBuilder::NativeCall");
  NativeCallInstr* call = new (Z) NativeCallInstr(
      name, function, FLAG_link_natives_lazily, TokenPosition::kNoSource);
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::PushArgument() {
  PushArgumentInstr* argument = new (Z) PushArgumentInstr(Pop());
  Push(argument);

  argument->set_temp_index(argument->temp_index() - 1);
  ++pending_argument_count_;

  return Fragment(argument);
}


Fragment FlowGraphBuilder::Return() {
  Value* value = Pop();
  ASSERT(stack_ == NULL);
  ReturnInstr* return_instr =
      new (Z) ReturnInstr(TokenPosition::kNoSource, value);
  if (exit_collector_ != NULL) exit_collector_->AddExit(return_instr);
  return Fragment(return_instr).closed();
}


Fragment FlowGraphBuilder::StaticCall(const Function& target,
                                      intptr_t argument_count) {
  return StaticCall(target, argument_count, Array::null_array());
}


static intptr_t GetResultCidOfListFactory(Zone* zone,
                                          const Function& function,
                                          intptr_t argument_count) {
  if (!function.IsFactory()) {
    return kDynamicCid;
  }

  const dart::Class& owner = dart::Class::Handle(zone, function.Owner());
  if ((owner.library() != dart::Library::CoreLibrary()) &&
      (owner.library() != dart::Library::TypedDataLibrary())) {
    return kDynamicCid;
  }

  if ((owner.Name() == Symbols::List().raw()) &&
      (function.name() == Symbols::ListFactory().raw())) {
    ASSERT(argument_count == 1 || argument_count == 2);
    return (argument_count == 1) ? kGrowableObjectArrayCid : kArrayCid;
  }
  return FactoryRecognizer::ResultCid(function);
}


Fragment FlowGraphBuilder::StaticCall(const Function& target,
                                      intptr_t argument_count,
                                      const Array& argument_names) {
  ArgumentArray arguments = GetArguments(argument_count);
  StaticCallInstr* call =
      new (Z) StaticCallInstr(TokenPosition::kNoSource, target, argument_names,
                              arguments, ic_data_array_);
  const intptr_t list_cid =
      GetResultCidOfListFactory(Z, target, argument_count);
  if (list_cid != kDynamicCid) {
    call->set_result_cid(list_cid);
    call->set_is_known_list_constructor(true);
  } else if (target.recognized_kind() != MethodRecognizer::kUnknown) {
    call->set_result_cid(MethodRecognizer::ResultCid(target));
  }
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::StoreIndexed(intptr_t class_id) {
  Value* value = Pop();
  Value* index = Pop();
  // TODO(27590): Omit store barrier when possible (e.g., storing
  // some constants).
  StoreIndexedInstr* store = new (Z) StoreIndexedInstr(
      Pop(),  // Array.
      index, value, kEmitStoreBarrier, Instance::ElementSizeFor(class_id),
      class_id, Thread::kNoDeoptId, TokenPosition::kNoSource);
  Push(store);
  return Fragment(store);
}


Fragment FlowGraphBuilder::StoreInstanceField(const dart::Field& field) {
  Value* value = Pop();
  // TODO(27590): Omit store barrier when possible (e.g., storing
  // some constants).
  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      field, Pop(), value, kEmitStoreBarrier, TokenPosition::kNoSource);
  return Fragment(store);
}


Fragment FlowGraphBuilder::StoreInstanceField(intptr_t offset) {
  Value* value = Pop();
  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      offset, Pop(), value, kEmitStoreBarrier, TokenPosition::kNoSource);
  return Fragment(store);
}


Fragment FlowGraphBuilder::StoreLocal(LocalVariable* variable) {
  Fragment instructions;
  if (variable->is_captured()) {
    LocalVariable* value = MakeTemporary();
    instructions += LoadContextAt(variable->owner()->context_level());
    instructions += LoadLocal(value);
    instructions +=
        StoreInstanceField(Context::variable_offset(variable->index()));
  } else {
    StoreLocalInstr* store =
        new (Z) StoreLocalInstr(*variable, Pop(), TokenPosition::kNoSource);
    instructions <<= store;
    Push(store);
  }
  return instructions;
}


Fragment FlowGraphBuilder::StoreStaticField(const dart::Field& field) {
  return Fragment(
      new (Z) StoreStaticFieldInstr(field, Pop(), TokenPosition::kNoSource));
}


Fragment FlowGraphBuilder::StringInterpolate() {
  Value* array = Pop();
  StringInterpolateInstr* interpolate =
      new (Z) StringInterpolateInstr(array, TokenPosition::kNoSource);
  Push(interpolate);
  return Fragment(interpolate);
}


Fragment FlowGraphBuilder::ThrowTypeError() {
  const dart::Class& klass = dart::Class::ZoneHandle(
      Z, dart::Library::LookupCoreClass(Symbols::TypeError()));
  ASSERT(!klass.IsNull());
  const dart::Function& constructor = dart::Function::ZoneHandle(
      Z,
      klass.LookupConstructorAllowPrivate(H.DartSymbol("_TypeError._create")));
  ASSERT(!constructor.IsNull());

  const dart::String& url = H.DartString(
      parsed_function_->function().ToLibNamePrefixedQualifiedCString(),
      Heap::kOld);

  Fragment instructions;

  // Create instance of _FallThroughError
  instructions += AllocateObject(klass, 0);
  LocalVariable* instance = MakeTemporary();

  // Call _AssertionError._create constructor.
  instructions += LoadLocal(instance);
  instructions += PushArgument();  // this

  instructions += Constant(url);
  instructions += PushArgument();  // url

  instructions += NullConstant();
  instructions += PushArgument();  // line

  instructions += IntConstant(0);
  instructions += PushArgument();  // column

  instructions += Constant(H.DartSymbol("Malformed type."));
  instructions += PushArgument();  // message

  instructions += StaticCall(constructor, 5);
  instructions += Drop();

  // Throw the exception
  instructions += PushArgument();
  instructions += ThrowException();

  return instructions;
}


Fragment FlowGraphBuilder::ThrowNoSuchMethodError() {
  const dart::Class& klass = dart::Class::ZoneHandle(
      Z, dart::Library::LookupCoreClass(Symbols::NoSuchMethodError()));
  ASSERT(!klass.IsNull());
  const dart::Function& throw_function = dart::Function::ZoneHandle(
      Z, klass.LookupStaticFunctionAllowPrivate(Symbols::ThrowNew()));
  ASSERT(!throw_function.IsNull());

  Fragment instructions;

  // Call NoSuchMethodError._throwNew static function.
  instructions += NullConstant();
  instructions += PushArgument();  // receiver

  instructions += Constant(H.DartString("<unknown>", Heap::kOld));
  instructions += PushArgument();  // memberName

  instructions += IntConstant(-1);
  instructions += PushArgument();  // invocation_type

  instructions += NullConstant();
  instructions += PushArgument();  // arguments

  instructions += NullConstant();
  instructions += PushArgument();  // argumentNames

  instructions += NullConstant();
  instructions += PushArgument();  // existingArgumentNames

  instructions += StaticCall(throw_function, 6);
  // Leave "result" on the stack since callers expect it to be there (even
  // though the function will result in an exception).

  return instructions;
}


dart::RawFunction* FlowGraphBuilder::LookupMethodByMember(
    Member* target, const dart::String& method_name) {
  Class* kernel_klass = Class::Cast(target->parent());
  dart::Class& klass =
      dart::Class::Handle(Z, H.LookupClassByKernelClass(kernel_klass));

  dart::RawFunction* function = klass.LookupFunctionAllowPrivate(method_name);
  ASSERT(function != Object::null());
  return function;
}


LocalVariable* FlowGraphBuilder::MakeTemporary() {
  char name[64];
  intptr_t index = stack_->definition()->temp_index();
  OS::SNPrint(name, 64, ":temp%" Pd, index);
  LocalVariable* variable = new (Z) LocalVariable(
      TokenPosition::kNoSource, H.DartSymbol(name), Object::dynamic_type());
  // Set the index relative to the base of the expression stack including
  // outgoing arguments.
  variable->set_index(parsed_function_->first_stack_local_index() -
                      parsed_function_->num_stack_locals() -
                      pending_argument_count_ - index);

  // The value has uses as if it were a local variable.  Mark the definition
  // as used so that its temp index will not be cleared (causing it to never
  // be materialized in the expression stack).
  stack_->definition()->set_ssa_temp_index(0);

  return variable;
}


intptr_t FlowGraphBuilder::CurrentTryIndex() {
  if (try_catch_block_ == NULL) {
    return CatchClauseNode::kInvalidTryIndex;
  } else {
    return try_catch_block_->TryIndex();
  }
}


dart::LocalVariable* FlowGraphBuilder::LookupVariable(
    VariableDeclaration* var) {
  LocalVariable* local = scopes_->locals.Lookup(var);
  ASSERT(local != NULL);
  return local;
}


void FlowGraphBuilder::SetTempIndex(Definition* definition) {
  definition->set_temp_index(
      stack_ == NULL ? 0 : stack_->definition()->temp_index() + 1);
}


void FlowGraphBuilder::Push(Definition* definition) {
  SetTempIndex(definition);
  Value::AddToList(new (Z) Value(definition), &stack_);
}


Value* FlowGraphBuilder::Pop() {
  ASSERT(stack_ != NULL);
  Value* value = stack_;
  stack_ = value->next_use();
  if (stack_ != NULL) stack_->set_previous_use(NULL);

  value->set_next_use(NULL);
  value->set_previous_use(NULL);
  value->definition()->ClearSSATempIndex();
  return value;
}


Fragment FlowGraphBuilder::Drop() {
  ASSERT(stack_ != NULL);
  Fragment instructions;
  Definition* definition = stack_->definition();
  // The SSA renaming implementation doesn't like [LoadLocal]s without a
  // tempindex.
  if (definition->HasSSATemp() || definition->IsLoadLocal()) {
    instructions <<= new (Z) DropTempsInstr(1, NULL);
  } else {
    definition->ClearTempIndex();
  }

  Pop();
  return instructions;
}


// TODO(27590): This method should be shared with
// runtime/vm/object.cc:RecognizeArithmeticOp.
Token::Kind FlowGraphBuilder::MethodKind(const dart::String& name) {
  ASSERT(name.IsSymbol());
  if (name.raw() == Symbols::Plus().raw()) {
    return Token::kADD;
  } else if (name.raw() == Symbols::Minus().raw()) {
    return Token::kSUB;
  } else if (name.raw() == Symbols::Star().raw()) {
    return Token::kMUL;
  } else if (name.raw() == Symbols::Slash().raw()) {
    return Token::kDIV;
  } else if (name.raw() == Symbols::TruncDivOperator().raw()) {
    return Token::kTRUNCDIV;
  } else if (name.raw() == Symbols::Percent().raw()) {
    return Token::kMOD;
  } else if (name.raw() == Symbols::BitOr().raw()) {
    return Token::kBIT_OR;
  } else if (name.raw() == Symbols::Ampersand().raw()) {
    return Token::kBIT_AND;
  } else if (name.raw() == Symbols::Caret().raw()) {
    return Token::kBIT_XOR;
  } else if (name.raw() == Symbols::LeftShiftOperator().raw()) {
    return Token::kSHL;
  } else if (name.raw() == Symbols::RightShiftOperator().raw()) {
    return Token::kSHR;
  } else if (name.raw() == Symbols::Tilde().raw()) {
    return Token::kBIT_NOT;
  } else if (name.raw() == Symbols::UnaryMinus().raw()) {
    return Token::kNEGATE;
  } else if (name.raw() == Symbols::EqualOperator().raw()) {
    return Token::kEQ;
  } else if (name.raw() == Symbols::Token(Token::kNE).raw()) {
    return Token::kNE;
  } else if (name.raw() == Symbols::LAngleBracket().raw()) {
    return Token::kLT;
  } else if (name.raw() == Symbols::RAngleBracket().raw()) {
    return Token::kGT;
  } else if (name.raw() == Symbols::LessEqualOperator().raw()) {
    return Token::kLTE;
  } else if (name.raw() == Symbols::GreaterEqualOperator().raw()) {
    return Token::kGTE;
  } else if (dart::Field::IsGetterName(name)) {
    return Token::kGET;
  } else if (dart::Field::IsSetterName(name)) {
    return Token::kSET;
  }
  return Token::kILLEGAL;
}


void FlowGraphBuilder::InlineBailout(const char* reason) {
  bool is_inlining = exit_collector_ != NULL;
  if (is_inlining) {
    parsed_function_->function().set_is_inlinable(false);
    parsed_function_->Bailout("kernel::FlowGraphBuilder", reason);
  }
}


FlowGraph* FlowGraphBuilder::BuildGraph() {
  const dart::Function& function = parsed_function_->function();

  if (function.IsConstructorClosureFunction()) return NULL;

  dart::Class& klass =
      dart::Class::Handle(zone_, parsed_function_->function().Owner());

  // Find out if there is an enclosing kernel class (which will be used to
  // resolve type parameters).
  Class* kernel_klass = NULL;
  dart::Function& topmost = dart::Function::Handle(Z, function.raw());
  while (topmost.parent_function() != Object::null()) {
    topmost = topmost.parent_function();
  }
  TreeNode* topmost_node = static_cast<TreeNode*>(topmost.kernel_function());
  if (topmost_node != NULL) {
    // Going up the closure->parent chain needs to result in a Procedure or
    // Constructor.
    TreeNode* parent = NULL;
    if (topmost_node->IsProcedure()) {
      parent = Procedure::Cast(topmost_node)->parent();
    } else if (topmost_node->IsConstructor()) {
      parent = Constructor::Cast(topmost_node)->parent();
    } else if (topmost_node->IsField()) {
      parent = Field::Cast(topmost_node)->parent();
    }
    if (parent != NULL && parent->IsClass()) kernel_klass = Class::Cast(parent);
  }

  // Mark that we are using [klass]/[kernell_klass] as active class.  Resolving
  // of type parameters will get resolved via [kernell_klass] unless we are
  // nested inside a static factory in which case we will use [member].
  ActiveClassScope active_class_scope(&active_class_, kernel_klass, &klass);
  Member* member = topmost_node != NULL && topmost_node->IsMember()
                       ? Member::Cast(topmost_node)
                       : NULL;
  ActiveMemberScope active_member(&active_class_, member);

  // The IR builder will create its own local variables and scopes, and it
  // will not need an AST.  The code generator will assume that there is a
  // local variable stack slot allocated for the current context and (I
  // think) that the runtime will expect it to be at a fixed offset which
  // requires allocating an unused expression temporary variable.
  scopes_ = parsed_function_->EnsureKernelScopes();

  switch (function.kind()) {
    case RawFunction::kClosureFunction:
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction: {
      FunctionNode* kernel_function = node_->IsProcedure()
                                          ? Procedure::Cast(node_)->function()
                                          : FunctionNode::Cast(node_);
      ActiveFunctionScope active_function_scope(&active_class_,
                                                kernel_function);
      return function.IsImplicitClosureFunction()
                 ? BuildGraphOfImplicitClosureFunction(kernel_function,
                                                       function)
                 : BuildGraphOfFunction(kernel_function);
    }
    case RawFunction::kConstructor: {
      bool is_factory = function.IsFactory();
      if (is_factory) {
        Procedure* procedure = Procedure::Cast(node_);
        FunctionNode* function = procedure->function();
        ActiveFunctionScope active_function_scope(&active_class_, function);
        return BuildGraphOfFunction(function, NULL);
      } else {
        Constructor* constructor = Constructor::Cast(node_);
        FunctionNode* function = constructor->function();
        ActiveFunctionScope active_function_scope(&active_class_, function);
        return BuildGraphOfFunction(function, constructor);
      }
    }
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitStaticFinalGetter:
    case RawFunction::kImplicitSetter: {
      Field* field = Field::Cast(node_);
      return IsStaticInitializer(function, Z)
                 ? BuildGraphOfStaticFieldInitializer(field)
                 : BuildGraphOfFieldAccessor(field, scopes_->setter_value);
    }
    case RawFunction::kMethodExtractor:
      return BuildGraphOfMethodExtractor(function);
    case RawFunction::kNoSuchMethodDispatcher:
      return BuildGraphOfNoSuchMethodDispatcher(function);
    case RawFunction::kInvokeFieldDispatcher:
      return BuildGraphOfInvokeFieldDispatcher(function);
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
      break;
  }
  UNREACHABLE();
  return NULL;
}


FlowGraph* FlowGraphBuilder::BuildGraphOfFunction(FunctionNode* function,
                                                  Constructor* constructor) {
  const Function& dart_function = parsed_function_->function();
  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  SetupDefaultParameterValues(function);

  Fragment body;
  if (!dart_function.is_native()) body += CheckStackOverflowInPrologue();
  intptr_t context_size =
      parsed_function_->node_sequence()->scope()->num_context_variables();
  if (context_size > 0) {
    body += PushContext(context_size);
    LocalVariable* context = MakeTemporary();

    // Copy captured parameters from the stack into the context.
    LocalScope* scope = parsed_function_->node_sequence()->scope();
    intptr_t parameter_count = dart_function.NumParameters();
    intptr_t parameter_index = parsed_function_->first_parameter_index();
    for (intptr_t i = 0; i < parameter_count; ++i, --parameter_index) {
      LocalVariable* variable = scope->VariableAt(i);
      if (variable->is_captured()) {
        // There is no LocalVariable describing the on-stack parameter so
        // create one directly.
        LocalVariable* parameter =
            new (Z) LocalVariable(TokenPosition::kNoSource,
                                  Symbols::TempParam(), Object::dynamic_type());
        parameter->set_index(parameter_index);
        // Mark the stack variable so it will be ignored by the code for
        // try/catch.
        parameter->set_is_captured_parameter(true);

        // Copy the parameter from the stack to the context.  Overwrite it
        // with a null constant on the stack so the original value is
        // eligible for garbage collection.
        body += LoadLocal(context);
        body += LoadLocal(parameter);
        body += StoreInstanceField(Context::variable_offset(variable->index()));
        body += NullConstant();
        body += StoreLocal(parameter);
        body += Drop();
      }
    }
    body += Drop();  // The context.
  }
  if (constructor != NULL) {
    // TODO(27590): Currently the [VariableDeclaration]s from the
    // initializers will be visible inside the entire body of the constructor.
    // We should make a separate scope for them.
    Class* kernel_klass = Class::Cast(constructor->parent());
    body += TranslateInitializers(kernel_klass, &constructor->initializers());
  }

  // The specification defines the result of `a == b` to be:
  //
  //   a) if either side is `null` then the result is `identical(a, b)`.
  //   b) else the result is `a.operator==(b)`
  //
  // For user-defined implementations of `operator==` we need therefore
  // implement the handling of a).
  //
  // The default `operator==` implementation in `Object` is implemented in terms
  // of identical (which we assume here!) which means that case a) is actually
  // included in b).  So we just use the normal implementation in the body.
  if ((dart_function.NumParameters() == 2) &&
      (dart_function.name() == Symbols::EqualOperator().raw()) &&
      (dart_function.Owner() != I->object_store()->object_class())) {
    LocalVariable* parameter =
        LookupVariable(function->positional_parameters()[0]);

    TargetEntryInstr* null_entry;
    TargetEntryInstr* non_null_entry;

    body += LoadLocal(parameter);
    body += BranchIfNull(&null_entry, &non_null_entry);

    // The argument was `null` and the receiver is not the null class (we only
    // go into this branch for user-defined == operators) so we can return
    // false.
    Fragment null_fragment(null_entry);
    null_fragment += Constant(Bool::False());
    null_fragment += Return();

    body = Fragment(body.entry, non_null_entry);
  }

  if (dart_function.is_native()) {
    body += NativeFunctionBody(function, dart_function);
  } else if (function->body() != NULL) {
    body += TranslateStatement(function->body());
  }
  if (body.is_open()) {
    body += NullConstant();
    body += Return();
  }

  // If functions body contains any yield points build switch statement that
  // selects a continuation point based on the value of :await_jump_var.
  if (!yield_continuations_.is_empty()) {
    // The code we are building will be executed right after we enter
    // the function and before any nested contexts are allocated.
    // Reset current context_depth_ to match this.
    intptr_t current_context_depth = context_depth_;
    context_depth_ = scopes_->yield_jump_variable->owner()->context_level();

    // Prepend an entry corresponding to normal entry to the function.
    yield_continuations_.InsertAt(
        0, YieldContinuation(new (Z) DropTempsInstr(0, NULL),
                             CatchClauseNode::kInvalidTryIndex));
    yield_continuations_[0].entry->LinkTo(body.entry);

    // Build a switch statement.
    Fragment dispatch;

    // Load :await_jump_var into a temporary.
    dispatch += LoadLocal(scopes_->yield_jump_variable);
    dispatch += StoreLocal(scopes_->switch_variable);
    dispatch += Drop();

    BlockEntryInstr* block = NULL;
    for (intptr_t i = 0; i < yield_continuations_.length(); i++) {
      if (i == 1) {
        // This is not a normal entry but a resumption.  Restore
        // :current_context_var from :await_ctx_var.
        // Note: after this point context_depth_ does not match current context
        // depth so we should not access any local variables anymore.
        dispatch += LoadLocal(scopes_->yield_context_variable);
        dispatch += StoreLocal(parsed_function_->current_context_var());
        dispatch += Drop();
      }
      if (i == (yield_continuations_.length() - 1)) {
        // We reached the last possility, no need to build more ifs.
        // Coninue to the last continuation.
        // Note: continuations start with nop DropTemps instruction
        // which acts like an anchor, so we need to skip it.
        block->set_try_index(yield_continuations_[i].try_index);
        dispatch <<= yield_continuations_[i].entry->next();
        break;
      }

      // Build comparison:
      //
      //   if (:await_ctx_var == i) {
      //     -> yield_continuations_[i]
      //   } else ...
      //
      TargetEntryInstr* then;
      TargetEntryInstr* otherwise;
      dispatch += LoadLocal(scopes_->switch_variable);
      dispatch += IntConstant(i);
      dispatch += BranchIfStrictEqual(&then, &otherwise);

      // True branch is linked to appropriate continuation point.
      // Note: continuations start with nop DropTemps instruction
      // which acts like an anchor, so we need to skip it.
      then->LinkTo(yield_continuations_[i].entry->next());
      then->set_try_index(yield_continuations_[i].try_index);

      // False branch will contain the next comparison.
      dispatch = Fragment(dispatch.entry, otherwise);
      block = otherwise;
    }
    body = dispatch;

    context_depth_ = current_context_depth;
  }
  normal_entry->LinkTo(body.entry);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


Fragment FlowGraphBuilder::NativeFunctionBody(FunctionNode* kernel_function,
                                              const Function& function) {
  ASSERT(function.is_native());
  // We explicitly build the graph for native functions in the same way that the
  // from-source backend does.  We should find a way to have a single component
  // to build these graphs so that this code is not duplicated.

  Fragment body;
  MethodRecognizer::Kind kind = MethodRecognizer::RecognizeKind(function);
  switch (kind) {
    case MethodRecognizer::kObjectEquals:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
      body += StrictCompare(Token::kEQ_STRICT);
      break;
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty:
      // Depending on FLAG_support_externalizable_strings, treat string length
      // loads as mutable so that the class check that precedes them will not be
      // hoisted.  This is unsafe because string externalization can change the
      // class.
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(MethodRecognizer::kStringBaseLength,
                              dart::String::length_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid,
                              !FLAG_support_externalizable_strings);
      if (kind == MethodRecognizer::kStringBaseIsEmpty) {
        body += IntConstant(0);
        body += StrictCompare(Token::kEQ_STRICT);
      }
      break;
    case MethodRecognizer::kGrowableArrayLength:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, GrowableObjectArray::length_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
      body += LoadLocal(scopes_->this_variable);
      body +=
          LoadNativeField(kind, Array::length_offset(),
                          Type::ZoneHandle(Z, Type::SmiType()), kSmiCid, true);
      break;
    case MethodRecognizer::kTypedDataLength:
      body += LoadLocal(scopes_->this_variable);
      body +=
          LoadNativeField(kind, TypedData::length_offset(),
                          Type::ZoneHandle(Z, Type::SmiType()), kSmiCid, true);
      break;
    case MethodRecognizer::kClassIDgetID:
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
      body += LoadClassId();
      break;
    case MethodRecognizer::kGrowableArrayCapacity:
      body += LoadLocal(scopes_->this_variable);
      body += LoadField(Array::data_offset(), kArrayCid);
      body += LoadNativeField(MethodRecognizer::kObjectArrayLength,
                              Array::length_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kObjectArrayAllocate:
      body += LoadLocal(scopes_->type_arguments_variable);
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
      body += CreateArray();
      break;
    case MethodRecognizer::kBigint_getDigits:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, Bigint::digits_offset(),
                              Object::dynamic_type(), kTypedDataUint32ArrayCid);
      break;
    case MethodRecognizer::kBigint_getUsed:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, Bigint::used_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kLinkedHashMap_getIndex:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::index_offset(),
                              Object::dynamic_type(), kDynamicCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setIndex:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
      body += StoreInstanceField(LinkedHashMap::index_offset());
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getData:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::data_offset(),
                              Object::dynamic_type(), kArrayCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setData:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
      body += StoreInstanceField(LinkedHashMap::data_offset());
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getHashMask:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::hash_mask_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setHashMask:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
      // TODO(27590): This store does not need a store barrier.
      body += StoreInstanceField(LinkedHashMap::hash_mask_offset());
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getUsedData:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::used_data_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setUsedData:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
      // TODO(27590): This store does not need a store barrier.
      body += StoreInstanceField(LinkedHashMap::used_data_offset());
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getDeletedKeys:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::deleted_keys_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setDeletedKeys:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
      // TODO(27590): This store does not need a store barrier.
      body += StoreInstanceField(LinkedHashMap::deleted_keys_offset());
      body += NullConstant();
      break;
    case MethodRecognizer::kBigint_getNeg:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, Bigint::neg_offset(),
                              Type::ZoneHandle(Z, Type::BoolType()), kBoolCid);
      break;
    default: {
      dart::String& name = dart::String::ZoneHandle(Z, function.native_name());
      body += NativeCall(&name, &function);
      break;
    }
  }
  return body + Return();
}


FlowGraph* FlowGraphBuilder::BuildGraphOfFieldAccessor(
    Field* kernel_field, LocalVariable* setter_value) {
  const dart::Function& function = parsed_function_->function();

  bool is_setter = function.IsImplicitSetterFunction();
  bool is_method = !function.IsStaticFunction();
  dart::Field& field =
      dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(kernel_field));

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  // TODO(27590): Add support for FLAG_use_field_guards.
  Fragment body(normal_entry);
  if (is_setter) {
    if (is_method) {
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(setter_value);
      body += StoreInstanceField(field);
    } else {
      body += LoadLocal(setter_value);
      body += StoreStaticField(field);
    }
    body += NullConstant();
  } else if (is_method) {
    body += LoadLocal(scopes_->this_variable);
    body += LoadField(field);
  } else if (field.is_const()) {
    // If the parser needs to know the value of an uninitialized constant field
    // it will set the value to the transition sentinel (used to detect circular
    // initialization) and then call the implicit getter.  Thus, the getter
    // cannot contain the InitStaticField instruction that normal static getters
    // contain because it would detect spurious circular initialization when it
    // checks for the transition sentinel.
    Expression* initializer = kernel_field->initializer();
    ASSERT(initializer != NULL);
    body += Constant(constant_evaluator_.EvaluateExpression(initializer));
  } else {
    // The field always has an initializer because static fields without
    // initializers are initialized eagerly and do not have implicit getters.
    ASSERT(field.has_initializer());
    body += Constant(field);
    body += InitStaticField(field);
    body += Constant(field);
    body += LoadStaticField();
  }
  body += Return();

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


FlowGraph* FlowGraphBuilder::BuildGraphOfStaticFieldInitializer(
    Field* kernel_field) {
  ASSERT(kernel_field->IsStatic());

  Expression* initializer = kernel_field->initializer();

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();
  if (kernel_field->IsConst()) {
    body += Constant(constant_evaluator_.EvaluateExpression(initializer));
  } else {
    body += TranslateExpression(initializer);
  }
  body += Return();

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


Fragment FlowGraphBuilder::BuildImplicitClosureCreation(
    const Function& target) {
  Fragment fragment;
  const dart::Class& closure_class =
      dart::Class::ZoneHandle(Z, I->object_store()->closure_class());
  fragment += AllocateObject(closure_class, target);
  LocalVariable* closure = MakeTemporary();

  // Allocate a context that closes over `this`.
  fragment += AllocateContext(1);
  LocalVariable* context = MakeTemporary();

  // Store the function and the context in the closure.
  fragment += LoadLocal(closure);
  fragment += Constant(target);
  fragment += StoreInstanceField(Closure::function_offset());

  fragment += LoadLocal(closure);
  fragment += LoadLocal(context);
  fragment += StoreInstanceField(Closure::context_offset());

  // The context is on top of the operand stack.  Store `this`.  The context
  // doesn't need a parent pointer because it doesn't close over anything
  // else.
  fragment += LoadLocal(scopes_->this_variable);
  fragment += StoreInstanceField(Context::variable_offset(0));

  return fragment;
}


FlowGraph* FlowGraphBuilder::BuildGraphOfMethodExtractor(
    const Function& method) {
  // A method extractor is the implicit getter for a method.
  const Function& function =
      Function::ZoneHandle(Z, method.extracted_method_closure());

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);
  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();
  body += BuildImplicitClosureCreation(function);
  body += Return();

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


FlowGraph* FlowGraphBuilder::BuildGraphOfImplicitClosureFunction(
    FunctionNode* kernel_function, const Function& function) {
  const Function& target = Function::ZoneHandle(Z, function.parent_function());

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);
  SetupDefaultParameterValues(kernel_function);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();

  // Load all the arguments.
  if (!target.is_static()) {
    // The context has a fixed shape: a single variable which is the
    // closed-over receiver.
    body += LoadLocal(parsed_function_->current_context_var());
    body += LoadField(Context::variable_offset(0));
    body += PushArgument();
  }
  intptr_t positional_argument_count =
      kernel_function->positional_parameters().length();
  for (intptr_t i = 0; i < positional_argument_count; i++) {
    body +=
        LoadLocal(LookupVariable(kernel_function->positional_parameters()[i]));
    body += PushArgument();
  }
  intptr_t named_argument_count = kernel_function->named_parameters().length();
  Array& argument_names = Array::ZoneHandle(Z);
  if (named_argument_count > 0) {
    argument_names = Array::New(named_argument_count);
    for (intptr_t i = 0; i < named_argument_count; i++) {
      VariableDeclaration* variable = kernel_function->named_parameters()[i];
      body += LoadLocal(LookupVariable(variable));
      body += PushArgument();
      argument_names.SetAt(i, H.DartSymbol(variable->name()));
    }
  }
  // Forward them to the target.
  intptr_t argument_count = positional_argument_count + named_argument_count;
  if (!target.is_static()) ++argument_count;
  body += StaticCall(target, argument_count, argument_names);

  // Return the result.
  body += Return();

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


FlowGraph* FlowGraphBuilder::BuildGraphOfNoSuchMethodDispatcher(
    const Function& function) {
  // This function is specialized for a receiver class, a method name, and
  // the arguments descriptor at a call site.

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  // The backend will expect an array of default values for all the named
  // parameters, even if they are all known to be passed at the call site
  // because the call site matches the arguments descriptor.  Use null for
  // the default values.
  const Array& descriptor_array =
      Array::ZoneHandle(Z, function.saved_args_desc());
  ArgumentsDescriptor descriptor(descriptor_array);
  ZoneGrowableArray<const Instance*>* default_values =
      new ZoneGrowableArray<const Instance*>(Z, descriptor.NamedCount());
  for (intptr_t i = 0; i < descriptor.NamedCount(); ++i) {
    default_values->Add(&Object::null_instance());
  }
  parsed_function_->set_default_parameter_values(default_values);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();

  // The receiver is the first argument to noSuchMethod, and it is the first
  // argument passed to the dispatcher function.
  LocalScope* scope = parsed_function_->node_sequence()->scope();
  body += LoadLocal(scope->VariableAt(0));
  body += PushArgument();

  // The second argument to noSuchMethod is an invocation mirror.  Push the
  // arguments for allocating the invocation mirror.  First, the name.
  body += Constant(dart::String::ZoneHandle(Z, function.name()));
  body += PushArgument();

  // Second, the arguments descriptor.
  body += Constant(descriptor_array);
  body += PushArgument();

  // Third, an array containing the original arguments.  Create it and fill
  // it in.
  body += Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
  body += IntConstant(descriptor.Count());
  body += CreateArray();
  LocalVariable* array = MakeTemporary();
  for (intptr_t i = 0; i < descriptor.PositionalCount(); ++i) {
    body += LoadLocal(array);
    body += IntConstant(i);
    body += LoadLocal(scope->VariableAt(i));
    body += StoreIndexed(kArrayCid);
    body += Drop();
  }
  dart::String& name = dart::String::Handle(Z);
  for (intptr_t i = 0; i < descriptor.NamedCount(); ++i) {
    intptr_t parameter_index = descriptor.PositionalCount() + i;
    name = descriptor.NameAt(i);
    name = dart::Symbols::New(H.thread(), name);
    body += LoadLocal(array);
    body += IntConstant(descriptor.PositionAt(i));
    body += LoadLocal(scope->VariableAt(parameter_index));
    body += StoreIndexed(kArrayCid);
    body += Drop();
  }
  body += PushArgument();

  // Fourth, false indicating this is not a super NoSuchMethod.
  body += Constant(Bool::False());
  body += PushArgument();

  const dart::Class& mirror_class = dart::Class::Handle(
      Z, dart::Library::LookupCoreClass(Symbols::InvocationMirror()));
  ASSERT(!mirror_class.IsNull());
  const Function& allocation_function = Function::ZoneHandle(
      Z, mirror_class.LookupStaticFunction(dart::Library::PrivateCoreLibName(
             Symbols::AllocateInvocationMirror())));
  ASSERT(!allocation_function.IsNull());
  body += StaticCall(allocation_function, 4);
  body += PushArgument();  // For the call to noSuchMethod.

  ArgumentsDescriptor two_arguments(
      Array::Handle(Z, ArgumentsDescriptor::New(2)));
  Function& no_such_method =
      Function::ZoneHandle(Z, Resolver::ResolveDynamicForReceiverClass(
                                  dart::Class::Handle(Z, function.Owner()),
                                  Symbols::NoSuchMethod(), two_arguments));
  if (no_such_method.IsNull()) {
    // If noSuchMethod is not found on the receiver class, call
    // Object.noSuchMethod.
    no_such_method = Resolver::ResolveDynamicForReceiverClass(
        dart::Class::Handle(Z, I->object_store()->object_class()),
        Symbols::NoSuchMethod(), two_arguments);
  }
  body += StaticCall(no_such_method, 2);
  body += Return();

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


FlowGraph* FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher(
    const Function& function) {
  // Find the name of the field we should dispatch to.
  const dart::Class& owner = dart::Class::Handle(Z, function.Owner());
  ASSERT(!owner.IsNull());
  const dart::String& field_name = dart::String::Handle(Z, function.name());
  const dart::String& getter_name = dart::String::ZoneHandle(
      Z,
      Symbols::New(H.thread(), dart::String::Handle(
                                   Z, dart::Field::GetterSymbol(field_name))));

  // Determine if this is `class Closure { get call => this; }`
  const dart::Class& closure_class =
      dart::Class::Handle(Z, I->object_store()->closure_class());
  const bool is_closure_call = (owner.raw() == closure_class.raw()) &&
                               field_name.Equals(Symbols::Call());

  // Set default parameters & construct argument names array.
  //
  // The backend will expect an array of default values for all the named
  // parameters, even if they are all known to be passed at the call site
  // because the call site matches the arguments descriptor.  Use null for
  // the default values.
  const Array& descriptor_array =
      Array::ZoneHandle(Z, function.saved_args_desc());
  ArgumentsDescriptor descriptor(descriptor_array);
  const Array& argument_names =
      Array::ZoneHandle(Z, Array::New(descriptor.NamedCount(), Heap::kOld));
  ZoneGrowableArray<const Instance*>* default_values =
      new ZoneGrowableArray<const Instance*>(Z, descriptor.NamedCount());
  dart::String& string_handle = dart::String::Handle(Z);
  for (intptr_t i = 0; i < descriptor.NamedCount(); ++i) {
    default_values->Add(&Object::null_instance());
    string_handle = descriptor.NameAt(i);
    argument_names.SetAt(i, string_handle);
  }
  parsed_function_->set_default_parameter_values(default_values);

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();

  LocalScope* scope = parsed_function_->node_sequence()->scope();

  LocalVariable* closure = NULL;
  if (is_closure_call) {
    closure = scope->VariableAt(0);

    // The closure itself is the first argument.
    body += LoadLocal(closure);
  } else {
    // Invoke the getter to get the field value.
    body += LoadLocal(scope->VariableAt(0));
    body += PushArgument();
    body += InstanceCall(getter_name, Token::kGET, 1);
  }

  body += PushArgument();

  // Push all arguments onto the stack.
  intptr_t pos = 1;
  for (; pos < descriptor.Count(); pos++) {
    body += LoadLocal(scope->VariableAt(pos));
    body += PushArgument();
  }

  if (is_closure_call) {
    // Lookup the function in the closure.
    body += LoadLocal(closure);
    body += LoadField(Closure::function_offset());

    body += ClosureCall(descriptor.Count(), argument_names);
  } else {
    body += InstanceCall(Symbols::Call(), Token::kILLEGAL, descriptor.Count(),
                         argument_names);
  }

  body += Return();

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


void FlowGraphBuilder::SetupDefaultParameterValues(FunctionNode* function) {
  intptr_t num_optional_parameters =
      parsed_function_->function().NumOptionalParameters();
  if (num_optional_parameters > 0) {
    ZoneGrowableArray<const Instance*>* default_values =
        new ZoneGrowableArray<const Instance*>(Z, num_optional_parameters);

    if (parsed_function_->function().HasOptionalNamedParameters()) {
      ASSERT(!parsed_function_->function().HasOptionalPositionalParameters());
      for (intptr_t i = 0; i < num_optional_parameters; i++) {
        VariableDeclaration* variable = function->named_parameters()[i];
        Instance* default_value;
        if (variable->initializer() != NULL) {
          default_value =
              &constant_evaluator_.EvaluateExpression(variable->initializer());
        } else {
          default_value = &Instance::ZoneHandle(Z, Instance::null());
        }
        default_values->Add(default_value);
      }
    } else {
      ASSERT(parsed_function_->function().HasOptionalPositionalParameters());
      intptr_t required = function->required_parameter_count();
      for (intptr_t i = 0; i < num_optional_parameters; i++) {
        VariableDeclaration* variable =
            function->positional_parameters()[required + i];
        Instance* default_value;
        if (variable->initializer() != NULL) {
          default_value =
              &constant_evaluator_.EvaluateExpression(variable->initializer());
        } else {
          default_value = &Instance::ZoneHandle(Z, Instance::null());
        }
        default_values->Add(default_value);
      }
    }
    parsed_function_->set_default_parameter_values(default_values);
  }
}


TargetEntryInstr* FlowGraphBuilder::BuildTargetEntry() {
  return new (Z) TargetEntryInstr(AllocateBlockId(), CurrentTryIndex());
}


JoinEntryInstr* FlowGraphBuilder::BuildJoinEntry() {
  return new (Z) JoinEntryInstr(AllocateBlockId(), CurrentTryIndex());
}


Fragment FlowGraphBuilder::TranslateInitializers(
    Class* kernel_klass, List<Initializer>* initializers) {
  Fragment instructions;

  // These come from:
  //   class A {
  //     var x = (expr);
  //   }
  for (intptr_t i = 0; i < kernel_klass->fields().length(); i++) {
    Field* kernel_field = kernel_klass->fields()[i];
    Expression* init = kernel_field->initializer();
    if (!kernel_field->IsStatic() && init != NULL) {
      dart::Field& field =
          dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(kernel_field));

      EnterScope(kernel_field);
      // TODO(27590): Support FLAG_use_field_guards.
      instructions += LoadLocal(scopes_->this_variable);
      instructions += TranslateExpression(init);
      instructions += StoreInstanceField(field);
      ExitScope(kernel_field);
    }
  }

  // These to come from:
  //   class A {
  //     var x;
  //     var y;
  //     A(this.x) : super(expr), y = (expr);
  //   }
  for (intptr_t i = 0; i < initializers->length(); i++) {
    Initializer* initializer = (*initializers)[i];
    if (initializer->IsFieldInitializer()) {
      FieldInitializer* init = FieldInitializer::Cast(initializer);
      dart::Field& field =
          dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(init->field()));

      // TODO(27590): Support FLAG_use_field_guards.
      instructions += LoadLocal(scopes_->this_variable);
      instructions += TranslateExpression(init->value());
      instructions += StoreInstanceField(field);
    } else if (initializer->IsSuperInitializer()) {
      SuperInitializer* init = SuperInitializer::Cast(initializer);

      instructions += LoadLocal(scopes_->this_variable);
      instructions += PushArgument();

      ASSERT(init->arguments()->types().length() == 0);
      Array& argument_names = Array::ZoneHandle(Z);
      instructions += TranslateArguments(init->arguments(), &argument_names);

      const Function& target = Function::ZoneHandle(
          Z, H.LookupConstructorByKernelConstructor(init->target()));
      intptr_t argument_count = init->arguments()->count() + 1;
      instructions += StaticCall(target, argument_count, argument_names);
      instructions += Drop();
    } else if (initializer->IsRedirectingInitializer()) {
      RedirectingInitializer* init = RedirectingInitializer::Cast(initializer);

      instructions += LoadLocal(scopes_->this_variable);
      instructions += PushArgument();

      ASSERT(init->arguments()->types().length() == 0);
      Array& argument_names = Array::ZoneHandle(Z);
      instructions += TranslateArguments(init->arguments(), &argument_names);

      const Function& target = Function::ZoneHandle(
          Z, H.LookupConstructorByKernelConstructor(init->target()));
      intptr_t argument_count = init->arguments()->count() + 1;
      instructions += StaticCall(target, argument_count, argument_names);
      instructions += Drop();
    } else if (initializer->IsLocalInitializer()) {
      // The other initializers following this one might read the variable. This
      // is used e.g. for evaluating the arguments to a super call first, run
      // normal field initializers next and then make the actual super call:
      //
      //   The frontend converts
      //
      //      class A {
      //        var x;
      //        A(a, b) : super(a + b), x = 2*b {}
      //      }
      //
      //   to
      //
      //      class A {
      //        var x;
      //        A(a, b) : tmp = a + b, x = 2*b, super(tmp) {}
      //      }
      //
      // (This is strictly speaking not what one should do in terms of the
      //  specification but that is how it is currently implemented.)
      LocalInitializer* init = LocalInitializer::Cast(initializer);

      VariableDeclaration* declaration = init->variable();
      LocalVariable* variable = LookupVariable(declaration);
      Expression* initializer = init->variable()->initializer();
      ASSERT(initializer != NULL);
      ASSERT(!declaration->IsConst());

      instructions += TranslateExpression(initializer);
      instructions += StoreLocal(variable);
      instructions += Drop();

      fragment_ = instructions;
    } else {
      UNIMPLEMENTED();
    }
  }
  return instructions;
}


Fragment FlowGraphBuilder::TranslateStatement(Statement* statement) {
#ifdef DEBUG
  intptr_t original_context_depth = context_depth_;
#endif
  statement->AcceptStatementVisitor(this);
  DEBUG_ASSERT(context_depth_ == original_context_depth);
  return fragment_;
}


Fragment FlowGraphBuilder::TranslateCondition(Expression* expression,
                                              bool* negate) {
  *negate = expression->IsNot();
  if (*negate) {
    return TranslateExpression(Not::Cast(expression)->expression());
  }
  return TranslateExpression(expression);
}


Fragment FlowGraphBuilder::TranslateExpression(Expression* expression) {
  expression->AcceptExpressionVisitor(this);
  return fragment_;
}


ArgumentArray FlowGraphBuilder::GetArguments(int count) {
  ArgumentArray arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(Z, count);
  arguments->SetLength(count);
  for (intptr_t i = count - 1; i >= 0; --i) {
    ASSERT(stack_->definition()->IsPushArgument());
    ASSERT(!stack_->definition()->HasSSATemp());
    arguments->data()[i] = stack_->definition()->AsPushArgument();
    Drop();
  }
  pending_argument_count_ -= count;
  ASSERT(pending_argument_count_ >= 0);
  return arguments;
}


void FlowGraphBuilder::VisitInvalidExpression(InvalidExpression* node) {
  // TODO(27590): Once we have better error information we might need to
  // make some invalid expressions not NSM errors but type/compile-time/...
  // errors.
  fragment_ = ThrowNoSuchMethodError();
}


void FlowGraphBuilder::VisitNullLiteral(NullLiteral* node) {
  fragment_ = Constant(Instance::ZoneHandle(Z, Instance::null()));
}


void FlowGraphBuilder::VisitBoolLiteral(BoolLiteral* node) {
  fragment_ = Constant(Bool::Get(node->value()));
}


void FlowGraphBuilder::VisitIntLiteral(IntLiteral* node) {
  fragment_ = IntConstant(node->value());
}


void FlowGraphBuilder::VisitBigintLiteral(BigintLiteral* node) {
  const dart::String& value = H.DartString(node->value());
  fragment_ = Constant(Integer::ZoneHandle(Z, Integer::New(value, Heap::kOld)));
}


void FlowGraphBuilder::VisitDoubleLiteral(DoubleLiteral* node) {
  fragment_ = Constant(constant_evaluator_.EvaluateExpression(node));
}


void FlowGraphBuilder::VisitStringLiteral(StringLiteral* node) {
  fragment_ = Constant(H.DartSymbol(node->value()));
}


void FlowGraphBuilder::VisitSymbolLiteral(SymbolLiteral* node) {
  fragment_ = Constant(constant_evaluator_.EvaluateExpression(node));
}


AbstractType& DartTypeTranslator::TranslateType(DartType* node) {
  node->AcceptDartTypeVisitor(this);

  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return dart::AbstractType::ZoneHandle(Z, result_.raw());
}


AbstractType& DartTypeTranslator::TranslateTypeWithoutFinalization(
    DartType* node) {
  bool saved_finalize = finalize_;
  finalize_ = false;
  H.SetFinalize(false);
  AbstractType& result = TranslateType(node);
  finalize_ = saved_finalize;
  H.SetFinalize(saved_finalize);
  return result;
}


void DartTypeTranslator::VisitInvalidType(InvalidType* node) {
  result_ = ClassFinalizer::NewFinalizedMalformedType(
      Error::Handle(Z),  // No previous error.
      dart::Script::Handle(Z, dart::Script::null()), TokenPosition::kNoSource,
      "[InvalidType] in Kernel IR.");
}


void DartTypeTranslator::VisitFunctionType(FunctionType* node) {
  // TODO(27590): Fix function types which are composed of malformed types.
  // We might need to convert them to dynamic types instead of making the
  // function type malformed.
  const Function& signature_function = Function::ZoneHandle(
      Z, Function::NewSignatureFunction(*active_class_->klass,
                                        TokenPosition::kNoSource));

  node->return_type()->AcceptDartTypeVisitor(this);
  if (result_.IsMalformed()) return;
  signature_function.set_result_type(result_);

  const intptr_t positional_count = node->positional_parameters().length();
  const intptr_t named_count = node->named_parameters().length();
  const intptr_t all_count = positional_count + named_count;
  const intptr_t required_count = node->required_parameter_count();

  // The additional first parameter is the receiver type (set to dynamic).
  signature_function.set_num_fixed_parameters(1 + required_count);
  signature_function.SetNumOptionalParameters(
      all_count - required_count, positional_count > required_count);

  const Array& parameter_types =
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld));
  signature_function.set_parameter_types(parameter_types);
  const Array& parameter_names =
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld));
  signature_function.set_parameter_names(parameter_names);

  intptr_t pos = 0;
  parameter_types.SetAt(pos, AbstractType::dynamic_type());
  parameter_names.SetAt(pos, H.DartSymbol("_receiver_"));
  pos++;
  for (intptr_t i = 0; i < positional_count; i++, pos++) {
    node->positional_parameters()[i]->AcceptDartTypeVisitor(this);
    if (result_.IsMalformed()) return;
    parameter_types.SetAt(pos, result_);
    parameter_names.SetAt(pos, H.DartSymbol("noname"));
  }
  for (intptr_t i = 0; i < named_count; i++, pos++) {
    Tuple<String, DartType>* tuple = node->named_parameters()[i];
    tuple->second()->AcceptDartTypeVisitor(this);
    if (result_.IsMalformed()) return;
    parameter_types.SetAt(pos, result_);
    parameter_names.SetAt(pos, H.DartSymbol(tuple->first()));
  }

  Type& signature_type =
      Type::ZoneHandle(Z, signature_function.SignatureType());

  if (finalize_) {
    signature_type ^= ClassFinalizer::FinalizeType(
        *active_class_->klass, signature_type, ClassFinalizer::kCanonicalize);
  }
  signature_function.SetSignatureType(signature_type);

  result_ = signature_type.raw();
}


void DartTypeTranslator::VisitTypeParameterType(TypeParameterType* node) {
  ASSERT(active_class_->kernel_class != NULL);

  List<TypeParameter>* parameters =
      &active_class_->kernel_class->type_parameters();
  if ((active_class_->member != NULL) && active_class_->member->IsProcedure()) {
    Procedure* procedure = Procedure::Cast(active_class_->member);
    if ((procedure->function() != NULL) &&
        (procedure->function()->type_parameters().length() > 0)) {
      //
      // WARNING: This is a little hackish:
      //
      // We have a static factory constructor. The kernel IR gives the factory
      // constructor function it's own type parameters (which are equal in name
      // and number to the ones of the enclosing class).
      // I.e.,
      //
      //   class A<T> {
      //     factory A.x() { return new B<T>(); }
      //   }
      //
      //  is basically translated to this:
      //
      //   class A<T> {
      //     static A.x<T'>() { return new B<T'>(); }
      //   }
      //
      parameters = &procedure->function()->type_parameters();
    }
  }

  for (intptr_t i = 0; i < parameters->length(); i++) {
    TypeParameter* type_parameter = (*parameters)[i];
    if (node->parameter() == type_parameter) {
      // The index of the type parameter in [parameters] is
      // the same index into the `klass->type_parameters()` array.
      result_ ^= dart::TypeArguments::Handle(
                     Z, active_class_->klass->type_parameters())
                     .TypeAt(i);
      return;
    }
  }

  UNREACHABLE();
}


void DartTypeTranslator::VisitInterfaceType(InterfaceType* node) {
  // NOTE: That an interface type like `T<A, B>` is considered to be
  // malformed iff `T` is malformed.
  //   => We therefore ignore errors in `A` or `B`.
  const TypeArguments& type_arguments = TranslateTypeArguments(
      node->type_arguments().raw_array(), node->type_arguments().length());

  const dart::Class& klass =
      dart::Class::Handle(Z, H.LookupClassByKernelClass(node->klass()));

  result_ = Type::New(klass, type_arguments, TokenPosition::kNoSource);
  result_.SetIsResolved();
  if (finalize_) {
    result_ = ClassFinalizer::FinalizeType(klass, result_,
                                           ClassFinalizer::kCanonicalize);
  }
}


void DartTypeTranslator::VisitDynamicType(DynamicType* node) {
  result_ = Object::dynamic_type().raw();
}


void DartTypeTranslator::VisitVoidType(VoidType* node) {
  result_ = Object::void_type().raw();
}


const TypeArguments& DartTypeTranslator::TranslateTypeArguments(
    DartType** dart_types, intptr_t length) {
  bool only_dynamic = true;
  for (intptr_t i = 0; i < length; i++) {
    if (!dart_types[i]->IsDynamicType()) {
      only_dynamic = false;
      break;
    }
  }
  TypeArguments& type_arguments = TypeArguments::ZoneHandle(Z);
  if (!only_dynamic) {
    type_arguments = TypeArguments::New(length);
    for (intptr_t i = 0; i < length; i++) {
      dart_types[i]->AcceptDartTypeVisitor(this);
      if (result_.IsMalformed()) {
        type_arguments = TypeArguments::null();
        return type_arguments;
      }
      type_arguments.SetTypeAt(i, result_);
    }
    if (finalize_) {
      type_arguments = type_arguments.Canonicalize();
    }
  }
  return type_arguments;
}


const TypeArguments& DartTypeTranslator::TranslateInstantiatedTypeArguments(
    const dart::Class& receiver_class, DartType** receiver_type_arguments,
    intptr_t length) {
  const TypeArguments& type_arguments =
      TranslateTypeArguments(receiver_type_arguments, length);
  if (type_arguments.IsNull()) return type_arguments;

  // We make a temporary [Type] object and use `ClassFinalizer::FinalizeType` to
  // finalize the argument types.
  // (This can for example make the [type_arguments] vector larger)
  Type& type = Type::Handle(
      Z, Type::New(receiver_class, type_arguments, TokenPosition::kNoSource));
  if (finalize_) {
    type ^= ClassFinalizer::FinalizeType(
        *active_class_->klass, type, ClassFinalizer::kCanonicalizeWellFormed);
  }

  const TypeArguments& instantiated_type_arguments =
      TypeArguments::ZoneHandle(Z, type.arguments());
  return instantiated_type_arguments;
}


const Type& DartTypeTranslator::ReceiverType(const dart::Class& klass) {
  ASSERT(!klass.IsNull());
  ASSERT(!klass.IsTypedefClass());
  // Note that if klass is _Closure, the returned type will be _Closure,
  // and not the signature type.
  Type& type = Type::ZoneHandle(Z, klass.CanonicalType());
  if (!type.IsNull()) {
    return type;
  }
  type = Type::New(klass, TypeArguments::Handle(Z, klass.type_parameters()),
                   klass.token_pos());
  return type;
}


void FlowGraphBuilder::VisitTypeLiteral(TypeLiteral* node) {
  const AbstractType& type = T.TranslateType(node->type());
  if (type.IsMalformed()) H.ReportError("Malformed type literal");

  fragment_ = Constant(type);
}


void FlowGraphBuilder::VisitVariableGet(VariableGet* node) {
  fragment_ = LoadLocal(LookupVariable(node->variable()));
}


void FlowGraphBuilder::VisitVariableSet(VariableSet* node) {
  Fragment instructions = TranslateExpression(node->expression());
  // The IR should not include assignments to final or const variables.
  // This is https://github.com/dart-lang/rasta/issues/83.
  //
  // TODO(27590): simply ASSERT that the variable is not const or final
  // when that issue is fixed.
  fragment_ = instructions +
              ((node->variable()->IsFinal() || node->variable()->IsConst())
                   ? Drop() + ThrowNoSuchMethodError()
                   : StoreLocal(LookupVariable(node->variable())));
}


void FlowGraphBuilder::VisitStaticGet(StaticGet* node) {
  Member* target = node->target();
  if (target->IsField()) {
    Field* kernel_field = Field::Cast(target);
    const dart::Field& field =
        dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(kernel_field));
    if (kernel_field->IsConst()) {
      fragment_ = Constant(constant_evaluator_.EvaluateExpression(node));
    } else {
      const dart::Class& owner = dart::Class::Handle(Z, field.Owner());
      const dart::String& getter_name = H.DartGetterName(kernel_field->name());
      const Function& getter =
          Function::ZoneHandle(Z, owner.LookupStaticFunction(getter_name));
      if (getter.IsNull() || !field.has_initializer()) {
        Fragment instructions = Constant(field);
        fragment_ = instructions + LoadStaticField();
      } else {
        // TODO(27590): figure out how to trigger this case and add tests.
        fragment_ = StaticCall(getter, 0);
      }
    }
  } else {
    Procedure* procedure = Procedure::Cast(target);
    const Function& target = Function::ZoneHandle(
        Z, H.LookupStaticMethodByKernelProcedure(procedure));

    if (procedure->kind() == Procedure::kGetter) {
      fragment_ = StaticCall(target, 0);
    } else if (procedure->kind() == Procedure::kMethod) {
      ASSERT(procedure->IsStatic());
      Function& closure_function =
          Function::ZoneHandle(Z, target.ImplicitClosureFunction());
      closure_function.set_kernel_function(target.kernel_function());
      const Instance& closure =
          Instance::ZoneHandle(Z, closure_function.ImplicitStaticClosure());
      fragment_ = Constant(closure);
    } else {
      UNIMPLEMENTED();
    }
  }
}


void FlowGraphBuilder::VisitStaticSet(StaticSet* node) {
  Member* target = node->target();
  if (target->IsField()) {
    Field* kernel_field = Field::Cast(target);
    const dart::Field& field =
        dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(kernel_field));
    Fragment instructions = TranslateExpression(node->expression());
    LocalVariable* variable = MakeTemporary();
    instructions += LoadLocal(variable);
    fragment_ = instructions + StoreStaticField(field);
  } else {
    ASSERT(target->IsProcedure());

    // Evaluate the expression on the right hand side.
    Fragment instructions = TranslateExpression(node->expression());
    LocalVariable* variable = MakeTemporary();

    // Prepare argument.
    instructions += LoadLocal(variable);
    instructions += PushArgument();

    // Invoke the setter function.
    Procedure* procedure = Procedure::Cast(target);
    const Function& target = Function::ZoneHandle(
        Z, H.LookupStaticMethodByKernelProcedure(procedure));
    instructions += StaticCall(target, 1);

    // Drop the unused result & leave the stored value on the stack.
    fragment_ = instructions + Drop();
  }
}


void FlowGraphBuilder::VisitPropertyGet(PropertyGet* node) {
  Fragment instructions = TranslateExpression(node->receiver());
  instructions += PushArgument();
  const dart::String& getter_name = H.DartGetterName(node->name());
  fragment_ = instructions + InstanceCall(getter_name, Token::kGET, 1);
}


void FlowGraphBuilder::VisitPropertySet(PropertySet* node) {
  Fragment instructions(NullConstant());
  LocalVariable* variable = MakeTemporary();
  instructions += TranslateExpression(node->receiver());
  instructions += PushArgument();
  instructions += TranslateExpression(node->value());
  instructions += StoreLocal(variable);
  instructions += PushArgument();

  const dart::String& setter_name = H.DartSetterName(node->name());
  instructions += InstanceCall(setter_name, Token::kSET, 2);
  fragment_ = instructions + Drop();
}


void FlowGraphBuilder::VisitDirectPropertyGet(DirectPropertyGet* node) {
  Function& target = Function::ZoneHandle(Z);
  if (node->target()->IsProcedure()) {
    Procedure* kernel_procedure = Procedure::Cast(node->target());
    Name* kernel_name = kernel_procedure->name();
    if (kernel_procedure->kind() == Procedure::kGetter) {
      target =
          LookupMethodByMember(kernel_procedure, H.DartGetterName(kernel_name));
    } else {
      target =
          LookupMethodByMember(kernel_procedure, H.DartMethodName(kernel_name));
      target = target.ImplicitClosureFunction();
      ASSERT(!target.IsNull());
      fragment_ = BuildImplicitClosureCreation(target);
      return;
    }
  } else {
    ASSERT(node->target()->IsField());
    const dart::String& getter_name = H.DartGetterName(node->target()->name());
    target = LookupMethodByMember(node->target(), getter_name);
    ASSERT(target.IsGetterFunction() || target.IsImplicitGetterFunction());
  }

  Fragment instructions = TranslateExpression(node->receiver());
  instructions += PushArgument();
  fragment_ = instructions + StaticCall(target, 1);
}


void FlowGraphBuilder::VisitDirectPropertySet(DirectPropertySet* node) {
  const dart::String& method_name = H.DartSetterName(node->target()->name());
  const Function& target = Function::ZoneHandle(
      Z, LookupMethodByMember(node->target(), method_name));
  ASSERT(target.IsSetterFunction() || target.IsImplicitSetterFunction());

  Fragment instructions(NullConstant());
  LocalVariable* value = MakeTemporary();
  instructions += TranslateExpression(node->receiver());
  instructions += PushArgument();
  instructions += TranslateExpression(node->value());
  instructions += StoreLocal(value);
  instructions += PushArgument();
  instructions += StaticCall(target, 2);

  fragment_ = instructions + Drop();
}


void FlowGraphBuilder::VisitStaticInvocation(StaticInvocation* node) {
  const Function& target = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(node->procedure()));
  const dart::Class& klass = dart::Class::ZoneHandle(Z, target.Owner());
  intptr_t argument_count = node->arguments()->count();
  if (target.IsGenerativeConstructor() || target.IsFactory()) {
    // The VM requires a TypeArguments object as first parameter for
    // every factory constructor.
    ++argument_count;
  }
  List<NamedExpression>& named = node->arguments()->named();
  const Array& argument_names = H.ArgumentNames(&named);

  Fragment instructions;
  if (!target.AreValidArguments(argument_count, argument_names, NULL)) {
    // An argument mismatch for a static invocation really should not occur
    // in the IR.  This is issue https://github.com/dart-lang/rasta/issues/76.
    //
    // TODO(27590): Change this to an ASSERT when that issue is fixed.
    List<Expression>& positional = node->arguments()->positional();
    for (intptr_t i = 0; i < positional.length(); ++i) {
      instructions += TranslateExpression(positional[i]);
      instructions += Drop();
    }

    for (intptr_t i = 0; i < named.length(); ++i) {
      instructions += TranslateExpression(named[i]->expression());
      instructions += Drop();
    }

    fragment_ = instructions + ThrowNoSuchMethodError();
    return;
  }

  LocalVariable* instance_variable = NULL;

  // If we cross the Kernel -> VM core library boundary, a [StaticInvocation]
  // can appear, but the thing we're calling is not a static method, but a
  // factory constructor.
  // The `H.LookupStaticmethodByKernelProcedure` will potentially resolve to the
  // forwarded constructor.
  // In that case we'll make an instance and pass it as first argument.
  //
  // TODO(27590): Get rid of this after we're using core libraries compiled
  // into Kernel.
  if (target.IsGenerativeConstructor()) {
    if (klass.NumTypeArguments() > 0) {
      List<DartType>& kernel_type_arguments = node->arguments()->types();
      const TypeArguments& type_arguments =
          T.TranslateInstantiatedTypeArguments(
              klass, kernel_type_arguments.raw_array(),
              kernel_type_arguments.length());
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
      instructions += AllocateObject(klass, 1);
    } else {
      instructions += AllocateObject(klass, 0);
    }

    instance_variable = MakeTemporary();

    instructions += LoadLocal(instance_variable);
    instructions += PushArgument();
  } else if (target.IsFactory()) {
    // The VM requires currently a TypeArguments object as first parameter for
    // every factory constructor :-/ !
    //
    // TODO(27590): Get rid of this after we're using core libraries compiled
    // into Kernel.
    List<DartType>& kernel_type_arguments = node->arguments()->types();

    const TypeArguments& type_arguments = T.TranslateInstantiatedTypeArguments(
        klass, kernel_type_arguments.raw_array(),
        kernel_type_arguments.length());

    instructions += TranslateInstantiatedTypeArguments(type_arguments);
    instructions += PushArgument();
  } else {
    ASSERT(node->arguments()->types().length() == 0);
  }

  // Special case identical(x, y) call.
  // TODO(27590) consider moving this into the inliner and force inline it
  // there.
  if (klass.IsTopLevel() && (klass.library() == dart::Library::CoreLibrary()) &&
      (target.name() == Symbols::Identical().raw())) {
    ASSERT(argument_count == 2);

    List<Expression>& positional = node->arguments()->positional();
    for (intptr_t i = 0; i < positional.length(); ++i) {
      instructions += TranslateExpression(positional[i]);
    }
    instructions += StrictCompare(Token::kEQ_STRICT, /*number_check=*/true);
  } else {
    instructions += TranslateArguments(node->arguments(), NULL);
    instructions += StaticCall(target, argument_count, argument_names);

    if (target.IsGenerativeConstructor()) {
      // Drop the result of the constructor call and leave [instance_variable]
      // on top-of-stack.
      instructions += Drop();
    }
  }

  fragment_ = instructions;
}


static bool IsNumberLiteral(Node* node) {
  return node->IsIntLiteral() || node->IsDoubleLiteral();
}


void FlowGraphBuilder::VisitMethodInvocation(MethodInvocation* node) {
  const dart::String& name = H.DartMethodName(node->name());
  const intptr_t argument_count = node->arguments()->count() + 1;
  const Token::Kind token_kind = MethodKind(name);
  if (IsNumberLiteral(node->receiver())) {
    if ((argument_count == 1) && (token_kind == Token::kNEGATE)) {
      const Object& result = constant_evaluator_.EvaluateExpressionSafe(node);
      if (!result.IsError()) {
        fragment_ = Constant(result);
        return;
      }
    } else if ((argument_count == 2) &&
               Token::IsBinaryArithmeticOperator(token_kind) &&
               IsNumberLiteral(node->arguments()->positional()[0])) {
      const Object& result = constant_evaluator_.EvaluateExpressionSafe(node);
      if (!result.IsError()) {
        fragment_ = Constant(result);
        return;
      }
    }
  }

  Fragment instructions = TranslateExpression(node->receiver());
  instructions += PushArgument();

  // Dart does not support generic methods yet.
  ASSERT(node->arguments()->types().length() == 0);

  Array& argument_names = Array::ZoneHandle(Z);
  instructions += TranslateArguments(node->arguments(), &argument_names);

  intptr_t num_args_checked = 1;
  // If we have a special operation (e.g. +/-/==) we mark both arguments as
  // to be checked.
  if (token_kind != Token::kILLEGAL) {
    ASSERT(argument_count <= 2);
    num_args_checked = argument_count;
  }

  fragment_ = instructions + InstanceCall(name, token_kind, argument_count,
                                          argument_names, num_args_checked);
}


void FlowGraphBuilder::VisitDirectMethodInvocation(
    DirectMethodInvocation* node) {
  const dart::String& method_name = H.DartMethodName(node->target()->name());
  const Function& target = Function::ZoneHandle(
      Z, LookupMethodByMember(node->target(), method_name));

  intptr_t argument_count = node->arguments()->count() + 1;
  Array& argument_names = Array::ZoneHandle(Z);

  ASSERT(node->arguments()->types().length() == 0);
  Fragment instructions = TranslateExpression(node->receiver());
  instructions += PushArgument();
  instructions += TranslateArguments(node->arguments(), &argument_names);
  fragment_ = instructions + StaticCall(target, argument_count, argument_names);
}


void FlowGraphBuilder::VisitConstructorInvocation(ConstructorInvocation* node) {
  if (node->is_const()) {
    fragment_ =
        Constant(constant_evaluator_.EvaluateConstructorInvocation(node));
    return;
  }

  Class* kernel_class = Class::Cast(node->target()->parent());

  dart::Class& klass =
      dart::Class::ZoneHandle(Z, H.LookupClassByKernelClass(kernel_class));

  Fragment instructions;
  if (klass.NumTypeArguments() > 0) {
    List<DartType>& kernel_type_arguments = node->arguments()->types();
    const TypeArguments& type_arguments = T.TranslateInstantiatedTypeArguments(
        klass, kernel_type_arguments.raw_array(),
        kernel_type_arguments.length());

    if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    } else {
      if (!klass.IsGeneric()) {
        Type& type = Type::ZoneHandle(Z, T.ReceiverType(klass).raw());

        // TODO(27590): Can we move this code into [ReceiverType]?
        type ^= ClassFinalizer::FinalizeType(*active_class_.klass, type,
                                             ClassFinalizer::kFinalize);
        ASSERT(!type.IsMalformedOrMalbounded());

        TypeArguments& canonicalized_type_arguments =
            TypeArguments::ZoneHandle(Z, type.arguments());
        canonicalized_type_arguments =
            canonicalized_type_arguments.Canonicalize();
        instructions += Constant(canonicalized_type_arguments);
      } else {
        instructions += TranslateInstantiatedTypeArguments(type_arguments);
      }
    }

    instructions += PushArgument();
    instructions += AllocateObject(klass, 1);
  } else {
    instructions += AllocateObject(klass, 0);
  }
  LocalVariable* variable = MakeTemporary();

  instructions += LoadLocal(variable);
  instructions += PushArgument();

  Array& argument_names = Array::ZoneHandle(Z);
  instructions += TranslateArguments(node->arguments(), &argument_names);

  const Function& target = Function::ZoneHandle(
      Z, H.LookupConstructorByKernelConstructor(klass, node->target()));
  intptr_t argument_count = node->arguments()->count() + 1;
  instructions += StaticCall(target, argument_count, argument_names);
  fragment_ = instructions + Drop();
}


void FlowGraphBuilder::VisitIsExpression(IsExpression* node) {
  Fragment instructions = TranslateExpression(node->operand());

  // The VM does not like an instanceOf call with a dynamic type. We need to
  // special case this situation.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());
  const AbstractType& type = T.TranslateType(node->type());
  if (type.IsMalformed()) {
    instructions += Drop();
    instructions += ThrowTypeError();
    fragment_ = instructions;
    return;
  }

  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, NULL, NULL, Heap::kOld)) {
    // Evaluate the expression on the left but ignore it's result.
    instructions += Drop();

    // Let condition be always true.
    instructions += Constant(Bool::True());
  } else {
    instructions += PushArgument();

    if (!type.IsInstantiated()) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Type arguments.

    instructions += Constant(type);
    instructions += PushArgument();  // Type.

    instructions += Constant(Bool::False());
    instructions += PushArgument();  // Negate?.

    instructions +=
        InstanceCall(dart::Library::PrivateCoreLibName(Symbols::_instanceOf()),
                     Token::kIS, 4);
  }

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitAsExpression(AsExpression* node) {
  Fragment instructions = TranslateExpression(node->operand());

  // The VM does not like an Object_as call with a dynamic type. We need to
  // special case this situation.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());
  const AbstractType& type = T.TranslateType(node->type());
  if (type.IsMalformed()) {
    instructions += Drop();
    instructions += ThrowTypeError();
    fragment_ = instructions;
    return;
  }

  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, NULL, NULL, Heap::kOld)) {
    // We already evaluated the operand on the left and just leave it there as
    // the result of the `obj as dynamic` expression.
  } else {
    instructions += PushArgument();

    if (!type.IsInstantiated()) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Type arguments.

    instructions += Constant(type);
    instructions += PushArgument();  // Type.

    instructions += InstanceCall(
        dart::Library::PrivateCoreLibName(Symbols::_as()), Token::kAS, 3);
  }

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitConditionalExpression(ConditionalExpression* node) {
  bool negate;
  Fragment instructions = TranslateCondition(node->condition(), &negate);

  TargetEntryInstr* then_entry;
  TargetEntryInstr* otherwise_entry;
  instructions += BranchIfTrue(&then_entry, &otherwise_entry, negate);

  Value* top = stack_;
  Fragment then_fragment(then_entry);
  then_fragment += TranslateExpression(node->then());
  then_fragment += StoreLocal(parsed_function_->expression_temp_var());
  then_fragment += Drop();

  ASSERT(stack_ == top);
  Fragment otherwise_fragment(otherwise_entry);
  otherwise_fragment += TranslateExpression(node->otherwise());
  otherwise_fragment += StoreLocal(parsed_function_->expression_temp_var());
  otherwise_fragment += Drop();

  JoinEntryInstr* join = BuildJoinEntry();
  then_fragment += Goto(join);
  otherwise_fragment += Goto(join);

  fragment_ = Fragment(instructions.entry, join) +
              LoadLocal(parsed_function_->expression_temp_var());
}


void FlowGraphBuilder::VisitLogicalExpression(LogicalExpression* node) {
  bool negate;
  Fragment instructions = TranslateCondition(node->left(), &negate);
  TargetEntryInstr* right_entry;
  TargetEntryInstr* constant_entry;

  if (node->op() == LogicalExpression::kAnd) {
    instructions += BranchIfTrue(&right_entry, &constant_entry, negate);
  } else {
    instructions += BranchIfTrue(&constant_entry, &right_entry, negate);
  }

  Value* top = stack_;
  Fragment right_fragment(right_entry);
  right_fragment += TranslateCondition(node->right(), &negate);
  right_fragment += Constant(Bool::True());
  right_fragment +=
      StrictCompare(negate ? Token::kNE_STRICT : Token::kEQ_STRICT);
  right_fragment += StoreLocal(parsed_function_->expression_temp_var());
  right_fragment += Drop();

  ASSERT(top == stack_);
  Fragment constant_fragment(constant_entry);
  constant_fragment +=
      Constant(Bool::Get(node->op() == LogicalExpression::kOr));
  constant_fragment += StoreLocal(parsed_function_->expression_temp_var());
  constant_fragment += Drop();

  JoinEntryInstr* join = BuildJoinEntry();
  right_fragment += Goto(join);
  constant_fragment += Goto(join);

  fragment_ = Fragment(instructions.entry, join) +
              LoadLocal(parsed_function_->expression_temp_var());
}


void FlowGraphBuilder::VisitNot(Not* node) {
  Fragment instructions = TranslateExpression(node->expression());
  fragment_ = instructions + BooleanNegate();
}


void FlowGraphBuilder::VisitThisExpression(ThisExpression* node) {
  fragment_ = LoadLocal(scopes_->this_variable);
}


void FlowGraphBuilder::VisitStringConcatenation(StringConcatenation* node) {
  List<Expression>& expressions = node->expressions();

  Fragment instructions;

  // The type arguments for CreateArray.
  instructions += Constant(TypeArguments::ZoneHandle(Z));
  instructions += IntConstant(expressions.length());
  instructions += CreateArray();
  LocalVariable* array = MakeTemporary();

  for (intptr_t i = 0; i < node->expressions().length(); i++) {
    instructions += LoadLocal(array);
    instructions += IntConstant(i);
    instructions += TranslateExpression(node->expressions()[i]);
    instructions += StoreIndexed(kArrayCid);
    instructions += Drop();
  }

  instructions += StringInterpolate();

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitListLiteral(ListLiteral* node) {
  if (node->is_const()) {
    fragment_ = Constant(constant_evaluator_.EvaluateListLiteral(node));
    return;
  }

  DartType* types[] = {node->type()};
  const TypeArguments& type_arguments = T.TranslateTypeArguments(types, 1);

  // The type argument for the factory call.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);
  instructions += PushArgument();
  List<Expression>& expressions = node->expressions();
  if (expressions.length() == 0) {
    instructions += Constant(Object::empty_array());
  } else {
    // The type arguments for CreateArray.
    instructions += Constant(TypeArguments::ZoneHandle(Z));
    instructions += IntConstant(expressions.length());
    instructions += CreateArray();

    LocalVariable* array = MakeTemporary();
    for (intptr_t i = 0; i < expressions.length(); ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += TranslateExpression(expressions[i]);
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();
    }
  }
  instructions += PushArgument();  // The array.

  const dart::Class& factory_class =
      dart::Class::Handle(Z, dart::Library::LookupCoreClass(Symbols::List()));
  const Function& factory_method = Function::ZoneHandle(
      Z, factory_class.LookupFactory(
             dart::Library::PrivateCoreLibName(Symbols::ListLiteralFactory())));
  fragment_ = instructions + StaticCall(factory_method, 2);
}


void FlowGraphBuilder::VisitMapLiteral(MapLiteral* node) {
  if (node->is_const()) {
    fragment_ = Constant(constant_evaluator_.EvaluateMapLiteral(node));
    return;
  }

  const dart::Class& map_class =
      dart::Class::Handle(Z, dart::Library::LookupCoreClass(Symbols::Map()));
  const Function& factory_method = Function::ZoneHandle(
      Z, map_class.LookupFactory(
             dart::Library::PrivateCoreLibName(Symbols::MapLiteralFactory())));

  DartType* types[] = {node->key_type(), node->value_type()};
  const TypeArguments& type_arguments = T.TranslateTypeArguments(types, 2);

  // The type argument for the factory call `new Map<K, V>._fromLiteral(List)`.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);
  instructions += PushArgument();

  List<MapEntry>& entries = node->entries();
  if (entries.length() == 0) {
    instructions += Constant(Object::empty_array());
  } else {
    // The type arguments for `new List<X>(int len)`.
    instructions += Constant(TypeArguments::ZoneHandle(Z));

    // We generate a list of tuples, i.e. [key1, value1, ..., keyN, valueN].
    instructions += IntConstant(2 * entries.length());
    instructions += CreateArray();

    LocalVariable* array = MakeTemporary();
    for (intptr_t i = 0; i < entries.length(); ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(2 * i);
      instructions += TranslateExpression(entries[i]->key());
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();

      instructions += LoadLocal(array);
      instructions += IntConstant(2 * i + 1);
      instructions += TranslateExpression(entries[i]->value());
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();
    }
  }
  instructions += PushArgument();  // The array.

  fragment_ = instructions + StaticCall(factory_method, 2);
}


void FlowGraphBuilder::VisitFunctionExpression(FunctionExpression* node) {
  fragment_ = TranslateFunctionNode(node->function(), node);
}


void FlowGraphBuilder::VisitLet(Let* node) {
  Fragment instructions = TranslateStatement(node->variable());
  instructions += TranslateExpression(node->body());
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitThrow(Throw* node) {
  Fragment instructions;

  instructions += TranslateExpression(node->expression());
  instructions += PushArgument();
  instructions += ThrowException();
  ASSERT(instructions.is_closed());

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitRethrow(Rethrow* node) {
  Fragment instructions;

  instructions += LoadLocal(catch_block_->exception_var());
  instructions += PushArgument();
  instructions += LoadLocal(catch_block_->stack_trace_var());
  instructions += PushArgument();
  instructions += RethrowException(catch_block_->catch_try_index());

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitBlockExpression(BlockExpression* node) {
  Fragment instructions = TranslateStatement(node->body());
  instructions += TranslateExpression(node->value());
  fragment_ = instructions;
}


Fragment FlowGraphBuilder::TranslateArguments(Arguments* node,
                                              Array* argument_names) {
  Fragment instructions;

  List<Expression>& positional = node->positional();
  for (intptr_t i = 0; i < positional.length(); ++i) {
    instructions += TranslateExpression(positional[i]);
    instructions += PushArgument();
  }

  List<NamedExpression>& named = node->named();
  if (argument_names != NULL) {
    *argument_names = H.ArgumentNames(&named).raw();
  }
  for (intptr_t i = 0; i < named.length(); ++i) {
    NamedExpression* named_expression = named[i];
    instructions += TranslateExpression(named_expression->expression());
    instructions += PushArgument();
  }
  return instructions;
}


void FlowGraphBuilder::VisitInvalidStatement(InvalidStatement* node) {
  H.ReportError("Invalid statements not implemented yet!");
}


void FlowGraphBuilder::VisitEmptyStatement(EmptyStatement* node) {
  fragment_ = Fragment();
}


void FlowGraphBuilder::VisitBlock(Block* node) {
  Fragment instructions;

  instructions += EnterScope(node);
  List<Statement>& statements = node->statements();
  for (intptr_t i = 0; i < statements.length(); ++i) {
    instructions += TranslateStatement(statements[i]);
  }
  instructions += ExitScope(node);

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitReturnStatement(ReturnStatement* node) {
  bool inside_try_finally = try_finally_block_ != NULL;

  Fragment instructions = node->expression() == NULL
                              ? NullConstant()
                              : TranslateExpression(node->expression());
  if (inside_try_finally) {
    ASSERT(scopes_->finally_return_variable != NULL);
    instructions += StoreLocal(scopes_->finally_return_variable);
    instructions += Drop();
    instructions += TranslateFinallyFinalizers(NULL, -1);
    if (instructions.is_open()) {
      instructions += LoadLocal(scopes_->finally_return_variable);
      instructions += Return();
    }
  } else {
    instructions += Return();
  }
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitExpressionStatement(ExpressionStatement* node) {
  Fragment instructions = TranslateExpression(node->expression());
  instructions += Drop();
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitVariableDeclaration(VariableDeclaration* node) {
  LocalVariable* variable = LookupVariable(node);
  Expression* initializer = node->initializer();

  Fragment instructions;
  if (initializer == NULL) {
    instructions += NullConstant();
  } else {
    if (node->IsConst()) {
      const Instance& constant_value =
          constant_evaluator_.EvaluateExpression(initializer);
      variable->SetConstValue(constant_value);
      instructions += Constant(constant_value);
    } else {
      instructions += TranslateExpression(initializer);
    }
  }
  instructions += StoreLocal(variable);
  instructions += Drop();
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitFunctionDeclaration(FunctionDeclaration* node) {
  Fragment instructions = TranslateFunctionNode(node->function(), node);
  instructions += StoreLocal(LookupVariable(node->variable()));
  instructions += Drop();
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitIfStatement(IfStatement* node) {
  bool negate;
  Fragment instructions = TranslateCondition(node->condition(), &negate);
  TargetEntryInstr* then_entry;
  TargetEntryInstr* otherwise_entry;
  instructions += BranchIfTrue(&then_entry, &otherwise_entry, negate);

  Fragment then_fragment(then_entry);
  then_fragment += TranslateStatement(node->then());

  Fragment otherwise_fragment(otherwise_entry);
  otherwise_fragment += TranslateStatement(node->otherwise());

  if (then_fragment.is_open()) {
    if (otherwise_fragment.is_open()) {
      JoinEntryInstr* join = BuildJoinEntry();
      then_fragment += Goto(join);
      otherwise_fragment += Goto(join);
      fragment_ = Fragment(instructions.entry, join);
    } else {
      fragment_ = Fragment(instructions.entry, then_fragment.current);
    }
  } else if (otherwise_fragment.is_open()) {
    fragment_ = Fragment(instructions.entry, otherwise_fragment.current);
  } else {
    fragment_ = instructions.closed();
  }
}


void FlowGraphBuilder::VisitWhileStatement(WhileStatement* node) {
  ++loop_depth_;
  bool negate;
  Fragment condition = TranslateCondition(node->condition(), &negate);
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit, negate);

  Fragment body(body_entry);
  body += TranslateStatement(node->body());

  Instruction* entry;
  if (body.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
    entry = new (Z) GotoInstr(join);
  } else {
    entry = condition.entry;
  }


  fragment_ = Fragment(entry, loop_exit);
  --loop_depth_;
}


void FlowGraphBuilder::VisitDoStatement(DoStatement* node) {
  ++loop_depth_;
  Fragment body = TranslateStatement(node->body());

  if (body.is_closed()) {
    fragment_ = body;
    --loop_depth_;
    return;
  }

  bool negate;
  JoinEntryInstr* join = BuildJoinEntry();
  Fragment loop(join);
  loop += CheckStackOverflow();
  loop += body;
  loop += TranslateCondition(node->condition(), &negate);
  TargetEntryInstr* loop_repeat;
  TargetEntryInstr* loop_exit;
  loop += BranchIfTrue(&loop_repeat, &loop_exit, negate);

  Fragment repeat(loop_repeat);
  repeat += Goto(join);

  fragment_ = Fragment(new (Z) GotoInstr(join), loop_exit);
  --loop_depth_;
}


void FlowGraphBuilder::VisitForStatement(ForStatement* node) {
  Fragment declarations;

  bool new_context = false;
  declarations += EnterScope(node, &new_context);

  List<VariableDeclaration>& variables = node->variables();
  for (intptr_t i = 0; i < variables.length(); ++i) {
    declarations += TranslateStatement(variables[i]);
  }

  ++loop_depth_;
  bool negate = false;
  Fragment condition = node->condition() == NULL
                           ? Constant(Bool::True())
                           : TranslateCondition(node->condition(), &negate);
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit, negate);

  Fragment body(body_entry);
  body += TranslateStatement(node->body());

  if (body.is_open()) {
    // We allocated a fresh context before the loop which contains captured
    // [ForStatement] variables.  Before jumping back to the loop entry we clone
    // the context object (at same depth) which ensures the next iteration of
    // the body gets a fresh set of [ForStatement] variables (with the old
    // (possibly updated) values).
    if (new_context) body += CloneContext();

    List<Expression>& updates = node->updates();
    for (intptr_t i = 0; i < updates.length(); ++i) {
      body += TranslateExpression(updates[i]);
      body += Drop();
    }
    JoinEntryInstr* join = BuildJoinEntry();
    declarations += Goto(join);
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
  } else {
    declarations += condition;
  }

  Fragment loop(declarations.entry, loop_exit);
  --loop_depth_;

  loop += ExitScope(node);

  fragment_ = loop;
}


void FlowGraphBuilder::VisitForInStatement(ForInStatement* node) {
  Fragment instructions = TranslateExpression(node->iterable());
  instructions += PushArgument();

  const dart::String& iterator_getter = dart::String::ZoneHandle(
      Z, dart::Field::GetterSymbol(Symbols::Iterator()));
  instructions += InstanceCall(iterator_getter, Token::kGET, 1);
  LocalVariable* iterator = scopes_->iterator_variables[for_in_depth_];
  instructions += StoreLocal(iterator);
  instructions += Drop();

  ++for_in_depth_;
  ++loop_depth_;
  Fragment condition = LoadLocal(iterator);
  condition += PushArgument();
  condition += InstanceCall(Symbols::MoveNext(), Token::kILLEGAL, 1);
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit);

  Fragment body(body_entry);
  body += EnterScope(node);
  body += LoadLocal(iterator);
  body += PushArgument();
  const dart::String& current_getter = dart::String::ZoneHandle(
      Z, dart::Field::GetterSymbol(Symbols::Current()));
  body += InstanceCall(current_getter, Token::kGET, 1);
  body += StoreLocal(LookupVariable(node->variable()));
  body += Drop();
  body += TranslateStatement(node->body());
  body += ExitScope(node);

  if (body.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    instructions += Goto(join);
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
  } else {
    instructions += condition;
  }

  fragment_ = Fragment(instructions.entry, loop_exit);
  --loop_depth_;
  --for_in_depth_;
}


void FlowGraphBuilder::VisitLabeledStatement(LabeledStatement* node) {
  // There can be serveral cases:
  //
  //   * the body contains a break
  //   * the body doesn't contain a break
  //
  //   * translating the body results in a closed fragment
  //   * translating the body results in a open fragment
  //
  // => We will only know which case we are in after the body has been
  //    traversed.

  BreakableBlock block(this, node);
  Fragment instructions = TranslateStatement(node->body());
  if (block.HadJumper()) {
    if (instructions.is_open()) {
      instructions += Goto(block.destination());
    }
    fragment_ = Fragment(instructions.entry, block.destination());
  } else {
    fragment_ = instructions;
  }
}


void FlowGraphBuilder::VisitBreakStatement(BreakStatement* node) {
  TryFinallyBlock* outer_finally = NULL;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* destination = breakable_block_->BreakDestination(
      node->target(), &outer_finally, &target_context_depth);

  Fragment instructions;
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    instructions += Goto(destination);
  }
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitSwitchStatement(SwitchStatement* node) {
  SwitchBlock block(this, node);

  // Instead of using a variable we should reuse the expression on the stack,
  // since it won't be assigned again, we don't need phi nodes.
  Fragment head_instructions = TranslateExpression(node->condition());
  head_instructions += StoreLocal(scopes_->switch_variable);
  head_instructions += Drop();

  // Phase 1: Generate bodies and try to find out whether a body will be target
  // of a jump due to:
  //   * `continue case_label`
  //   * `case e1: case e2: body`
  Fragment* body_fragments = new Fragment[node->cases().length()];

  intptr_t num_cases = node->cases().length();
  for (intptr_t i = 0; i < num_cases; i++) {
    SwitchCase* switch_case = node->cases()[i];
    Fragment& body_fragment = body_fragments[i] =
        TranslateStatement(switch_case->body());

    if (body_fragment.entry == NULL) {
      // Make a NOP in order to ensure linking works properly.
      body_fragment = NullConstant();
      body_fragment += Drop();
    }

    // The Dart language specification mandates fall-throughs in [SwitchCase]es
    // to be runtime errors.
    if (!switch_case->is_default() && body_fragment.is_open() &&
        (i < (node->cases().length() - 1))) {
      const dart::Class& klass = dart::Class::ZoneHandle(
          Z, dart::Library::LookupCoreClass(Symbols::FallThroughError()));
      ASSERT(!klass.IsNull());
      const dart::Function& constructor = dart::Function::ZoneHandle(
          Z, klass.LookupConstructorAllowPrivate(
                 H.DartSymbol("FallThroughError._create")));
      ASSERT(!constructor.IsNull());
      const dart::String& url = H.DartString(
          parsed_function_->function().ToLibNamePrefixedQualifiedCString(),
          Heap::kOld);

      // Create instance of _FallThroughError
      body_fragment += AllocateObject(klass, 0);
      LocalVariable* instance = MakeTemporary();

      // Call _AssertionError._create constructor.
      body_fragment += LoadLocal(instance);
      body_fragment += PushArgument();  // this

      body_fragment += Constant(url);
      body_fragment += PushArgument();  // url

      body_fragment += NullConstant();
      body_fragment += PushArgument();  // line

      body_fragment += StaticCall(constructor, 3);
      body_fragment += Drop();

      // Throw the exception
      body_fragment += PushArgument();
      body_fragment += ThrowException();
      body_fragment += Drop();
    }

    // If there is an implicit fall-through we have one [SwitchCase] and
    // multiple expressions, e.g.
    //
    //    switch(expr) {
    //      case a:
    //      case b:
    //        <stmt-body>
    //    }
    //
    // This means that the <stmt-body> will have more than 1 incoming edge (one
    // from `a == expr` and one from `a != expr && b == expr`). The
    // `block.Destination()` records the additional jump.
    if (switch_case->expressions().length() > 1) {
      block.Destination(switch_case);
    }
  }

  // Phase 2: Generate everything except the real bodies:
  //   * jump directly to a body (if there is no jumper)
  //   * jump to a wrapper block which jumps to the body (if there is a jumper)
  Fragment current_instructions = head_instructions;
  for (intptr_t i = 0; i < num_cases; i++) {
    SwitchCase* switch_case = node->cases()[i];

    if (switch_case->is_default()) {
      ASSERT(i == (node->cases().length() - 1));

      // Evaluate the conditions for the default [SwitchCase] just for the
      // purpose of potentially triggering a compile-time error.
      for (intptr_t k = 0; k < switch_case->expressions().length(); k++) {
        constant_evaluator_.EvaluateExpression(switch_case->expressions()[k]);
      }

      if (block.HadJumper(switch_case)) {
        // There are several branches to the body, so we will make a goto to
        // the join block (and prepend a join instruction to the real body).
        JoinEntryInstr* join = block.Destination(switch_case);
        current_instructions += Goto(join);

        current_instructions = Fragment(current_instructions.entry, join);
        current_instructions += body_fragments[i];
      } else {
        current_instructions += body_fragments[i];
      }
    } else {
      JoinEntryInstr* body_join = NULL;
      if (block.HadJumper(switch_case)) {
        body_join = block.Destination(switch_case);
        body_fragments[i] = Fragment(body_join) + body_fragments[i];
      }

      for (intptr_t j = 0; j < switch_case->expressions().length(); j++) {
        TargetEntryInstr* then;
        TargetEntryInstr* otherwise;

        current_instructions += Constant(constant_evaluator_.EvaluateExpression(
            switch_case->expressions()[j]));
        current_instructions += PushArgument();
        current_instructions += LoadLocal(scopes_->switch_variable);
        current_instructions += PushArgument();
        current_instructions +=
            InstanceCall(Symbols::EqualOperator(), Token::kEQ,
                         /*argument_count=*/2,
                         /*num_args_checked=*/2);
        current_instructions += BranchIfTrue(&then, &otherwise);

        Fragment then_fragment(then);

        if (body_join != NULL) {
          // There are several branches to the body, so we will make a goto to
          // the join block (the real body has already been prepended with a
          // join instruction).
          then_fragment += Goto(body_join);
        } else {
          // There is only a signle branch to the body, so we will just append
          // the body fragment.
          then_fragment += body_fragments[i];
        }

        current_instructions = Fragment(otherwise);
      }
    }
  }

  bool has_no_default =
      num_cases > 0 && !node->cases()[num_cases - 1]->is_default();
  if (has_no_default) {
    // There is no default, which means we have an open [current_instructions]
    // (which is a [TargetEntryInstruction] for the last "otherwise" branch).
    //
    // Furthermore the last [SwitchCase] can be open as well.  If so, we need
    // to join these two.
    Fragment& last_body = body_fragments[node->cases().length() - 1];
    if (last_body.is_open()) {
      ASSERT(current_instructions.is_open());
      ASSERT(current_instructions.current->IsTargetEntry());

      // Join the last "otherwise" branch and the last [SwitchCase] fragment.
      JoinEntryInstr* join = BuildJoinEntry();
      current_instructions += Goto(join);
      last_body += Goto(join);

      current_instructions = Fragment(join);
    }
  } else {
    // All non-default cases will be closed (i.e. break/continue/throw/return)
    // So it is fine to just let more statements after the switch append to the
    // default case.
  }

  delete[] body_fragments;

  fragment_ = Fragment(head_instructions.entry, current_instructions.current);
}


void FlowGraphBuilder::VisitContinueSwitchStatement(
    ContinueSwitchStatement* node) {
  TryFinallyBlock* outer_finally = NULL;
  intptr_t target_context_depth = -1;
  JoinEntryInstr* entry = switch_block_->Destination(
      node->target(), &outer_finally, &target_context_depth);

  Fragment instructions;
  instructions +=
      TranslateFinallyFinalizers(outer_finally, target_context_depth);
  if (instructions.is_open()) {
    instructions += Goto(entry);
  }
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitAssertStatement(AssertStatement* node) {
  if (!I->asserts()) {
    fragment_ = Fragment();
    return;
  }

  TargetEntryInstr* then;
  TargetEntryInstr* otherwise;

  bool negate;
  Fragment instructions;
  instructions += TranslateCondition(node->condition(), &negate);
  instructions += BranchIfTrue(&then, &otherwise, negate);

  const dart::Class& klass = dart::Class::ZoneHandle(
      Z, dart::Library::LookupCoreClass(Symbols::AssertionError()));
  ASSERT(!klass.IsNull());
  const dart::Function& constructor = dart::Function::ZoneHandle(
      Z, klass.LookupConstructorAllowPrivate(
             H.DartSymbol("_AssertionError._create")));
  ASSERT(!constructor.IsNull());

  const dart::String& url = H.DartString(
      parsed_function_->function().ToLibNamePrefixedQualifiedCString(),
      Heap::kOld);

  // Create instance of _AssertionError
  Fragment otherwise_fragment(otherwise);
  otherwise_fragment += AllocateObject(klass, 0);
  LocalVariable* instance = MakeTemporary();

  // Call _AssertionError._create constructor.
  otherwise_fragment += LoadLocal(instance);
  otherwise_fragment += PushArgument();  // this

  otherwise_fragment +=
      node->message() != NULL
          ? TranslateExpression(node->message())
          : Constant(H.DartString("<no message>", Heap::kOld));
  otherwise_fragment += PushArgument();  // message

  otherwise_fragment += Constant(url);
  otherwise_fragment += PushArgument();  // url

  otherwise_fragment += IntConstant(0);
  otherwise_fragment += PushArgument();  // line

  otherwise_fragment += IntConstant(0);
  otherwise_fragment += PushArgument();  // column

  otherwise_fragment += StaticCall(constructor, 5);
  otherwise_fragment += Drop();

  // Throw _AssertionError exception.
  otherwise_fragment += PushArgument();
  otherwise_fragment += ThrowException();
  otherwise_fragment += Drop();

  fragment_ = Fragment(instructions.entry, then);
}


void FlowGraphBuilder::VisitTryFinally(TryFinally* node) {
  InlineBailout("kernel::FlowgraphBuilder::VisitTryFinally");

  // There are 5 different cases where we need to execute the finally block:
  //
  //  a) 1/2/3th case: Special control flow going out of `node->body()`:
  //
  //   * [BreakStatement] transfers control to a [LabledStatement]
  //   * [ContinueSwitchStatement] transfers control to a [SwitchCase]
  //   * [ReturnStatement] returns a value
  //
  //   => All three cases will automatically append all finally blocks
  //      between the branching point and the destination (so we don't need to
  //      do anything here).
  //
  //  b) 4th case: Translating the body resulted in an open fragment (i.e. body
  //               executes without any control flow out of it)
  //
  //   => We are responsible for jumping out of the body to a new block (with
  //      different try index) and execute the finalizer.
  //
  //  c) 5th case: An exception occured inside the body.
  //
  //   => We are responsible for catching it, executing the finally block and
  //      rethrowing the exception.
  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  // Fill in the body of the try.
  ++try_depth_;
  {
    TryCatchBlock tcb(this, try_handler_index);
    TryFinallyBlock tfb(this, node->finalizer());
    try_body += TranslateStatement(node->body());
  }
  --try_depth_;

  if (try_body.is_open()) {
    // Please note: The try index will be on level out of this block,
    // thereby ensuring if there's an exception in the finally block we
    // won't run it twice.
    JoinEntryInstr* finally_entry = BuildJoinEntry();

    try_body += Goto(finally_entry);

    Fragment finally_body(finally_entry);
    finally_body += TranslateStatement(node->finalizer());
    finally_body += Goto(after_try);
  }

  // Fill in the body of the catch.
  ++catch_depth_;
  const Array& handler_types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
  handler_types.SetAt(0, Object::dynamic_type());
  Fragment finally_body = CatchBlockEntry(handler_types, try_handler_index);
  finally_body += TranslateStatement(node->finalizer());
  if (finally_body.is_open()) {
    finally_body += LoadLocal(CurrentException());
    finally_body += PushArgument();
    finally_body += LoadLocal(CurrentStackTrace());
    finally_body += PushArgument();
    finally_body += RethrowException(try_handler_index);
    Drop();
  }
  --catch_depth_;

  fragment_ = Fragment(try_body.entry, after_try);
}


void FlowGraphBuilder::VisitTryCatch(class TryCatch* node) {
  InlineBailout("kernel::FlowgraphBuilder::VisitTryCatch");

  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  // Fill in the body of the try.
  ++try_depth_;
  {
    TryCatchBlock block(this, try_handler_index);
    try_body += TranslateStatement(node->body());
    try_body += Goto(after_try);
  }
  --try_depth_;

  ++catch_depth_;
  const Array& handler_types =
      Array::ZoneHandle(Z, Array::New(node->catches().length(), Heap::kOld));
  Fragment catch_body = CatchBlockEntry(handler_types, try_handler_index);
  // Fill in the body of the catch.
  for (intptr_t i = 0; i < node->catches().length(); i++) {
    Catch* catch_clause = node->catches()[i];

    Fragment catch_handler_body;

    catch_handler_body += EnterScope(catch_clause);

    if (catch_clause->exception() != NULL) {
      catch_handler_body += LoadLocal(CurrentException());
      catch_handler_body +=
          StoreLocal(LookupVariable(catch_clause->exception()));
      catch_handler_body += Drop();
    }
    if (catch_clause->stack_trace() != NULL) {
      catch_handler_body += LoadLocal(CurrentStackTrace());
      catch_handler_body +=
          StoreLocal(LookupVariable(catch_clause->stack_trace()));
      catch_handler_body += Drop();
    }
    AbstractType* type_guard = NULL;
    if (catch_clause->guard() != NULL &&
        !catch_clause->guard()->IsDynamicType()) {
      type_guard = &T.TranslateType(catch_clause->guard());
      handler_types.SetAt(i, *type_guard);
    } else {
      handler_types.SetAt(i, Object::dynamic_type());
    }

    {
      CatchBlock block(this, CurrentException(), CurrentStackTrace(),
                       try_handler_index);

      catch_handler_body += TranslateStatement(catch_clause->body());

      // Note: ExitScope adjusts context_depth_ so even if catch_handler_body
      // is closed we still need to execute ExitScope for its side effect.
      catch_handler_body += ExitScope(catch_clause);
      if (catch_handler_body.is_open()) {
        catch_handler_body += Goto(after_try);
      }
    }

    if (type_guard != NULL) {
      if (type_guard->IsMalformed()) {
        catch_body += ThrowTypeError();
        catch_body += Drop();
      } else {
        catch_body += LoadLocal(CurrentException());
        catch_body += PushArgument();  // exception
        catch_body += NullConstant();
        catch_body += PushArgument();  // type arguments
        catch_body += Constant(*type_guard);
        catch_body += PushArgument();  // guard type
        catch_body += Constant(Object::bool_false());
        catch_body += PushArgument();  // negate
        catch_body += InstanceCall(
            dart::Library::PrivateCoreLibName(Symbols::_instanceOf()),
            Token::kIS, 4);

        TargetEntryInstr* catch_entry;
        TargetEntryInstr* next_catch_entry;
        catch_body += BranchIfTrue(&catch_entry, &next_catch_entry);

        Fragment(catch_entry) + catch_handler_body;
        catch_body = Fragment(next_catch_entry);
      }
    } else {
      catch_body += catch_handler_body;
    }
  }

  // In case the last catch body was not handling the exception and branching to
  // after the try block, we will rethrow the exception (i.e. no default catch
  // handler).
  if (catch_body.is_open()) {
    catch_body += LoadLocal(CurrentException());
    catch_body += PushArgument();
    catch_body += LoadLocal(CurrentStackTrace());
    catch_body += PushArgument();
    catch_body += RethrowException(try_handler_index);
    Drop();
  }
  --catch_depth_;

  fragment_ = Fragment(try_body.entry, after_try);
}


void FlowGraphBuilder::VisitYieldStatement(YieldStatement* node) {
  ASSERT(node->is_native());  // Must have been desugared.
  // Setup yield/continue point:
  //
  //   ...
  //   :await_jump_var = index;
  //   :await_ctx_var = :current_context_var
  //   return <expr>
  //
  // Continuation<index>:
  //   Drop(1)
  //   ...
  //
  // BuildGraphOfFunction will create a dispatch that jumps to
  // Continuation<:await_jump_var> upon entry to the function.
  //
  Fragment instructions = IntConstant(yield_continuations_.length() + 1);
  instructions += StoreLocal(scopes_->yield_jump_variable);
  instructions += Drop();
  instructions += LoadLocal(parsed_function_->current_context_var());
  instructions += StoreLocal(scopes_->yield_context_variable);
  instructions += Drop();
  instructions += TranslateExpression(node->expression());
  instructions += Return();

  // Note: DropTempsInstr serves as an anchor instruction. It will not
  // be linked into the resulting graph.
  DropTempsInstr* anchor = new (Z) DropTempsInstr(0, NULL);
  yield_continuations_.Add(YieldContinuation(anchor, CurrentTryIndex()));

  Fragment continuation(instructions.entry, anchor);

  // TODO(27590): we need a better way to detect if we need to check for an
  // exception after yield or not.
  if (parsed_function_->function().NumOptionalPositionalParameters() == 3) {
    // If function takes three parameters then the second and the third
    // are exception and stack_trace. Check if exception is non-null
    // and rethrow it.
    //
    //   :async_op([:result, :exception, :stack_trace]) {
    //     ...
    //     Continuation<index>:
    //       if (:exception != null) rethrow(:exception, :stack_trace);
    //     ...
    //   }
    //
    LocalScope* scope = parsed_function_->node_sequence()->scope();
    LocalVariable* exception_var = scope->VariableAt(2);
    LocalVariable* stack_trace_var = scope->VariableAt(3);
    ASSERT(exception_var->name().raw() == Symbols::ExceptionParameter().raw());
    ASSERT(stack_trace_var->name().raw() ==
           Symbols::StackTraceParameter().raw());

    TargetEntryInstr* no_error;
    TargetEntryInstr* error;

    continuation += LoadLocal(exception_var);
    continuation += BranchIfNull(&no_error, &error);

    Fragment rethrow(error);
    rethrow += LoadLocal(exception_var);
    rethrow += PushArgument();
    rethrow += LoadLocal(stack_trace_var);
    rethrow += PushArgument();
    rethrow += RethrowException(CatchClauseNode::kInvalidTryIndex);
    Drop();


    continuation = Fragment(continuation.entry, no_error);
  }

  fragment_ = continuation;
}


Fragment FlowGraphBuilder::TranslateFunctionNode(FunctionNode* node,
                                                 TreeNode* parent) {
  // The VM has a per-isolate table of functions indexed by the enclosing
  // function and token position.  We don't have token positions, so we've
  // simply numbered the immediately-nested functions with respect to the
  // parent.
  Function& function = Function::ZoneHandle(Z);
  for (intptr_t i = 0; i < scopes_->function_scopes.length(); ++i) {
    if (scopes_->function_scopes[i].function != node) continue;

    function = I->LookupClosureFunction(parsed_function_->function(),
                                        TokenPosition(i));
    if (function.IsNull()) {
      const dart::String* name;
      if (parent->IsFunctionExpression()) {
        name = &Symbols::AnonymousClosure();
      } else {
        ASSERT(parent->IsFunctionDeclaration());
        name = &H.DartSymbol(
            FunctionDeclaration::Cast(parent)->variable()->name());
      }
      function = Function::NewClosureFunction(
          *name, parsed_function_->function(), TokenPosition(i));
      function.set_is_debuggable(false);
      LocalScope* scope = scopes_->function_scopes[i].scope;
      const ContextScope& context_scope =
          ContextScope::Handle(Z, scope->PreserveOuterScope(context_depth_));
      function.set_context_scope(context_scope);
      function.set_kernel_function(node);
      KernelReader::SetupFunctionParameters(H, T, dart::Class::Handle(Z),
                                            function, node,
                                            false,  // is_method
                                            true);  // is_closure
      // Finalize function type.
      Type& signature_type = Type::Handle(Z, function.SignatureType());
      signature_type ^= ClassFinalizer::FinalizeType(
          *active_class_.klass, signature_type, ClassFinalizer::kCanonicalize);
      function.SetSignatureType(signature_type);

      I->AddClosureFunction(function);
    }
    break;
  }

  const dart::Class& closure_class =
      dart::Class::ZoneHandle(Z, I->object_store()->closure_class());
  ASSERT(!closure_class.IsNull());
  Fragment instructions = AllocateObject(closure_class, function);
  LocalVariable* closure = MakeTemporary();

  // TODO(27590): Generic closures need type arguments.

  // Store the function and the context in the closure.
  instructions += LoadLocal(closure);
  instructions += Constant(function);
  instructions += StoreInstanceField(Closure::function_offset());

  instructions += LoadLocal(closure);
  instructions += LoadLocal(parsed_function_->current_context_var());
  instructions += StoreInstanceField(Closure::context_offset());

  return instructions;
}


}  // namespace kernel
}  // namespace dart
