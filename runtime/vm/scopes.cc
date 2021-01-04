// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/scopes.h"

#include "vm/compiler/backend/slot.h"
#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"


namespace dart {

DEFINE_FLAG(bool,
            share_enclosing_context,
            true,
            "Allocate captured variables in the existing context of an "
            "enclosing scope (up to innermost loop) and spare the allocation "
            "of a local context.");

int SourceLabel::FunctionLevel() const {
  ASSERT(owner() != NULL);
  return owner()->function_level();
}

LocalScope::LocalScope(LocalScope* parent, int function_level, int loop_level)
    : parent_(parent),
      child_(NULL),
      sibling_(NULL),
      function_level_(function_level),
      loop_level_(loop_level),
      context_level_(LocalScope::kUninitializedContextLevel),
      begin_token_pos_(TokenPosition::kNoSource),
      end_token_pos_(TokenPosition::kNoSource),
      variables_(),
      labels_(),
      context_variables_(),
      context_slots_(new (Thread::Current()->zone())
                         ZoneGrowableArray<const Slot*>()),
      referenced_() {
  // Hook this node into the children of the parent, unless the parent has a
  // different function_level, since the local scope of a nested function can
  // be discarded after it has been parsed.
  if ((parent != NULL) && (parent->function_level() == function_level)) {
    sibling_ = parent->child_;
    parent->child_ = this;
  }
}

bool LocalScope::IsNestedWithin(LocalScope* scope) const {
  const LocalScope* current_scope = this;
  while (current_scope != NULL) {
    if (current_scope == scope) {
      return true;
    }
    current_scope = current_scope->parent();
  }
  return false;
}

bool LocalScope::AddVariable(LocalVariable* variable) {
  ASSERT(variable != NULL);
  if (LocalLookupVariable(variable->name()) != NULL) {
    return false;
  }
  variables_.Add(variable);
  if (variable->owner() == NULL) {
    // Variables must be added to their owner scope first. Subsequent calls
    // to 'add' treat the variable as an alias.
    variable->set_owner(this);
  }
  return true;
}

bool LocalScope::InsertParameterAt(intptr_t pos, LocalVariable* parameter) {
  ASSERT(parameter != NULL);
  if (LocalLookupVariable(parameter->name()) != NULL) {
    return false;
  }
  variables_.InsertAt(pos, parameter);
  // InsertParameterAt is not used to add aliases of parameters.
  ASSERT(parameter->owner() == NULL);
  parameter->set_owner(this);
  return true;
}

bool LocalScope::AddLabel(SourceLabel* label) {
  if (LocalLookupLabel(label->name()) != NULL) {
    return false;
  }
  labels_.Add(label);
  if (label->owner() == NULL) {
    // Labels must be added to their owner scope first. Subsequent calls
    // to 'add' treat the label as an alias.
    label->set_owner(this);
  }
  return true;
}

void LocalScope::MoveLabel(SourceLabel* label) {
  ASSERT(LocalLookupLabel(label->name()) == NULL);
  ASSERT(label->kind() == SourceLabel::kForward);
  labels_.Add(label);
  label->set_owner(this);
}

NameReference* LocalScope::FindReference(const String& name) const {
  ASSERT(name.IsSymbol());
  intptr_t num_references = referenced_.length();
  for (intptr_t i = 0; i < num_references; i++) {
    if (name.raw() == referenced_[i]->name().raw()) {
      return referenced_[i];
    }
  }
  return NULL;
}

void LocalScope::AddReferencedName(TokenPosition token_pos,
                                   const String& name) {
  if (LocalLookupVariable(name) != NULL) {
    return;
  }
  NameReference* ref = FindReference(name);
  if (ref != NULL) {
    ref->set_token_pos(token_pos);
    return;
  }
  ref = new NameReference(token_pos, name);
  referenced_.Add(ref);
  // Add name reference in innermost enclosing scopes that do not
  // define a local variable with this name.
  LocalScope* scope = this->parent();
  while (scope != NULL && (scope->LocalLookupVariable(name) == NULL)) {
    scope->referenced_.Add(ref);
    scope = scope->parent();
  }
}

TokenPosition LocalScope::PreviousReferencePos(const String& name) const {
  NameReference* ref = FindReference(name);
  if (ref != NULL) {
    return ref->token_pos();
  }
  return TokenPosition::kNoSource;
}

void LocalScope::AllocateContextVariable(LocalVariable* variable,
                                         LocalScope** context_owner) {
  ASSERT(variable->is_captured());
  ASSERT(variable->owner() == this);
  // The context level in the owner scope of a captured variable indicates at
  // code generation time how far to walk up the context chain in order to
  // access the variable from the current context level.
  if ((*context_owner) == NULL) {
    ASSERT(num_context_variables() == 0);
    // This scope becomes the current context owner.
    set_context_level(1);
    *context_owner = this;
  } else if (!FLAG_share_enclosing_context && ((*context_owner) != this)) {
    // The captured variable is in a child scope of the context owner and we do
    // not share contexts.
    // This scope will allocate and chain a new context.
    ASSERT(num_context_variables() == 0);
    // This scope becomes the current context owner.
    set_context_level((*context_owner)->context_level() + 1);
    *context_owner = this;
  } else if ((*context_owner)->loop_level() < loop_level()) {
    ASSERT(FLAG_share_enclosing_context);
    // The captured variable is at a deeper loop level than the current context.
    // This scope will allocate and chain a new context.
    ASSERT(num_context_variables() == 0);
    // This scope becomes the current context owner.
    set_context_level((*context_owner)->context_level() + 1);
    *context_owner = this;
  } else {
    // Allocate the captured variable in the current context.
    if (!HasContextLevel()) {
      ASSERT(variable->owner() != *context_owner);
      set_context_level((*context_owner)->context_level());
    } else {
      ASSERT(context_level() == (*context_owner)->context_level());
    }
  }

  (*context_owner)->AddContextVariable(variable);
}

void LocalScope::AddContextVariable(LocalVariable* variable) {
  variable->set_index(VariableIndex(context_variables_.length()));
  context_variables_.Add(variable);
  context_slots_->Add(
      &Slot::GetContextVariableSlotFor(Thread::Current(), *variable));
}

VariableIndex LocalScope::AllocateVariables(VariableIndex first_parameter_index,
                                            int num_parameters,
                                            VariableIndex first_local_index,
                                            LocalScope* context_owner,
                                            bool* found_captured_variables) {
  // We should not allocate variables of nested functions while compiling an
  // enclosing function.
  ASSERT(function_level() == 0);
  ASSERT(num_parameters >= 0);
  // Parameters must be listed first and must all appear in the top scope.
  ASSERT(num_parameters <= num_variables());
  int pos = 0;                              // Current variable position.
  VariableIndex next_index =
      first_parameter_index;  // Current free frame index.

  LocalVariable* await_jump_var = nullptr;
  LocalVariable* async_future = nullptr;
  LocalVariable* controller = nullptr;
  LocalVariable* chained_future = nullptr;
  LocalVariable* is_sync = nullptr;
  for (intptr_t i = 0; i < num_variables(); i++) {
    LocalVariable* variable = VariableAt(i);
    if (variable->owner() == this) {
      if (variable->is_captured()) {
        if (variable->name().Equals(Symbols::AwaitJumpVar())) {
          await_jump_var = variable;
        } else if (variable->name().Equals(Symbols::AsyncFuture())) {
          async_future = variable;
        } else if (variable->name().Equals(Symbols::Controller())) {
          controller = variable;
        } else if (variable->is_chained_future()) {
          chained_future = variable;
        } else if (variable->name().Equals(Symbols::is_sync())) {
          is_sync = variable;
        }
      }
    }
  }
  // If we are in an async/async* function, force :await_jump_var and
  // :async_future to be at fixed locations in the slot.
  if (await_jump_var != nullptr) {
    AllocateContextVariable(await_jump_var, &context_owner);
    *found_captured_variables = true;
    ASSERT(await_jump_var->index().value() == Context::kAwaitJumpVarIndex);
  }
  if (async_future != nullptr) {
    AllocateContextVariable(async_future, &context_owner);
    *found_captured_variables = true;
    ASSERT(async_future->index().value() == Context::kAsyncFutureIndex);
  }
  if (controller != nullptr) {
    AllocateContextVariable(controller, &context_owner);
    *found_captured_variables = true;
    ASSERT(controller->index().value() == Context::kControllerIndex);
  }
  if (chained_future != nullptr) {
    AllocateContextVariable(chained_future, &context_owner);
    *found_captured_variables = true;
    ASSERT(chained_future->index().value() ==
           chained_future->expected_context_index());
  }
  if (is_sync != nullptr) {
    AllocateContextVariable(is_sync, &context_owner);
    *found_captured_variables = true;
    ASSERT(is_sync->index().value() == Context::kIsSyncIndex);
  }

  while (pos < num_parameters) {
    LocalVariable* parameter = VariableAt(pos);
    pos++;
    // Parsing formal parameter default values may add local variable aliases
    // to the local scope before the formal parameters are added. However,
    // the parameters get inserted in front of the aliases, therefore, no
    // aliases can be encountered among the first num_parameters variables.
    ASSERT(parameter->owner() == this);
    if (parameter->is_captured()) {
      // A captured parameter has a slot allocated in the frame and one in the
      // context, where it gets copied to. The parameter index reflects the
      // context allocation index.
      next_index = VariableIndex(next_index.value() - 1);
      AllocateContextVariable(parameter, &context_owner);
      *found_captured_variables = true;
    } else {
      parameter->set_index(next_index);
      next_index = VariableIndex(next_index.value() - 1);
    }
  }
  // No overlapping of parameters and locals.
  ASSERT(next_index.value() >= first_local_index.value());
  next_index = first_local_index;
  while (pos < num_variables()) {
    LocalVariable* variable = VariableAt(pos);
    if (variable->owner() == this) {
      if (variable->is_captured()) {
        // Skip the variables already pre-allocated above.
        if (variable != await_jump_var && variable != async_future &&
            variable != controller && variable != chained_future &&
            variable != is_sync) {
          AllocateContextVariable(variable, &context_owner);
          *found_captured_variables = true;
        }
      } else {
        variable->set_index(next_index);
        next_index = VariableIndex(next_index.value() - 1);
      }
    }
    pos++;
  }
  // Allocate variables of all children.
  VariableIndex min_index = next_index;
  LocalScope* child = this->child();
  while (child != NULL) {
    // Ignored, since no parameters.
    const VariableIndex dummy_parameter_index(0);

    // No parameters in children scopes.
    const int num_parameters_in_child = 0;
    VariableIndex child_next_index = child->AllocateVariables(
        dummy_parameter_index, num_parameters_in_child, next_index,
        context_owner, found_captured_variables);
    if (child_next_index.value() < min_index.value()) {
      min_index = child_next_index;
    }
    child = child->sibling();
  }
  return min_index;
}

// The parser creates internal variables that start with ":"
static bool IsFilteredIdentifier(const String& str) {
  ASSERT(str.Length() > 0);
  if (str.raw() == Symbols::AsyncOperation().raw()) {
    // Keep :async_op for asynchronous debugging.
    return false;
  }
  if (str.raw() == Symbols::AsyncFuture().raw()) {
    // Keep :async_future for asynchronous debugging.
    return false;
  }
  if (str.raw() == Symbols::ControllerStream().raw()) {
    // Keep :controller_stream for asynchronous debugging.
    return false;
  }
  if (str.raw() == Symbols::AwaitJumpVar().raw()) {
    // Keep :await_jump_var for asynchronous debugging.
    return false;
  }
  if (str.raw() == Symbols::is_sync().raw()) {
    // Keep :is_sync for asynchronous debugging.
    return false;
  }
  if (str.raw() == Symbols::FunctionTypeArgumentsVar().raw()) {
    // Keep :function_type_arguments for accessing type variables in debugging.
    return false;
  }
  return str.CharAt(0) == ':';
}

LocalVarDescriptorsPtr LocalScope::GetVarDescriptors(
    const Function& func,
    ZoneGrowableArray<intptr_t>* context_level_array) {
  LocalVarDescriptorsBuilder vars;
  vars.AddDeoptIdToContextLevelMappings(context_level_array);

  // First enter all variables from scopes of outer functions.
  const ContextScope& context_scope =
      ContextScope::Handle(func.context_scope());
  if (!context_scope.IsNull()) {
    ASSERT(func.IsLocalFunction());
    for (int i = 0; i < context_scope.num_variables(); i++) {
      String& name = String::Handle(context_scope.NameAt(i));
      LocalVarDescriptorsLayout::VarInfoKind kind;
      if (!IsFilteredIdentifier(name)) {
        kind = LocalVarDescriptorsLayout::kContextVar;
      } else {
        continue;
      }

      LocalVarDescriptorsBuilder::VarDesc desc;
      desc.name = &name;
      desc.info.set_kind(kind);
      desc.info.scope_id = context_scope.ContextLevelAt(i);
      desc.info.declaration_pos = context_scope.DeclarationTokenIndexAt(i);
      desc.info.begin_pos = begin_token_pos();
      desc.info.end_pos = end_token_pos();
      ASSERT(desc.info.begin_pos <= desc.info.end_pos);
      desc.info.set_index(context_scope.ContextIndexAt(i));
      vars.Add(desc);
    }
  }
  // Now collect all variables from local scopes.
  int16_t scope_id = 0;
  CollectLocalVariables(&vars, &scope_id);

  return vars.Done();
}

// Add visible variables that are declared in this scope to vars, then
// collect visible variables of children, followed by siblings.
void LocalScope::CollectLocalVariables(LocalVarDescriptorsBuilder* vars,
                                       int16_t* scope_id) {
  (*scope_id)++;
  for (int i = 0; i < this->variables_.length(); i++) {
    LocalVariable* var = variables_[i];
    if ((var->owner() == this) && !var->is_invisible()) {
      if (var->name().raw() == Symbols::CurrentContextVar().raw()) {
        // This is the local variable in which the function saves its
        // own context before calling a closure function.
        LocalVarDescriptorsBuilder::VarDesc desc;
        desc.name = &var->name();
        desc.info.set_kind(LocalVarDescriptorsLayout::kSavedCurrentContext);
        desc.info.scope_id = 0;
        desc.info.declaration_pos = TokenPosition::kMinSource;
        desc.info.begin_pos = TokenPosition::kMinSource;
        desc.info.end_pos = TokenPosition::kMinSource;
        desc.info.set_index(var->index().value());
        vars->Add(desc);
      } else if (!IsFilteredIdentifier(var->name())) {
        // This is a regular Dart variable, either stack-based or captured.
        LocalVarDescriptorsBuilder::VarDesc desc;
        desc.name = &var->name();
        if (var->is_captured()) {
          desc.info.set_kind(LocalVarDescriptorsLayout::kContextVar);
          ASSERT(var->owner() != NULL);
          ASSERT(var->owner()->context_level() >= 0);
          desc.info.scope_id = var->owner()->context_level();
        } else {
          desc.info.set_kind(LocalVarDescriptorsLayout::kStackVar);
          desc.info.scope_id = *scope_id;
        }
        desc.info.set_index(var->index().value());
        desc.info.declaration_pos = var->declaration_token_pos();
        desc.info.begin_pos = var->token_pos();
        desc.info.end_pos = var->owner()->end_token_pos();
        vars->Add(desc);
      }
    }
  }
  LocalScope* child = this->child();
  while (child != NULL) {
    child->CollectLocalVariables(vars, scope_id);
    child = child->sibling();
  }
}

SourceLabel* LocalScope::LocalLookupLabel(const String& name) const {
  ASSERT(name.IsSymbol());
  for (intptr_t i = 0; i < labels_.length(); i++) {
    SourceLabel* label = labels_[i];
    if (label->name().raw() == name.raw()) {
      return label;
    }
  }
  return NULL;
}

LocalVariable* LocalScope::LocalLookupVariable(const String& name) const {
  ASSERT(name.IsSymbol());
  for (intptr_t i = 0; i < variables_.length(); i++) {
    LocalVariable* var = variables_[i];
    ASSERT(var->name().IsSymbol());
    if (var->name().raw() == name.raw()) {
      return var;
    }
  }
  return NULL;
}

LocalVariable* LocalScope::LookupVariable(const String& name, bool test_only) {
  LocalScope* current_scope = this;
  while (current_scope != NULL) {
    LocalVariable* var = current_scope->LocalLookupVariable(name);
    // If testing only, return the variable even if invisible.
    if ((var != NULL) && (!var->is_invisible_ || test_only)) {
      if (!test_only && (var->owner()->function_level() != function_level())) {
        CaptureVariable(var);
      }
      return var;
    }
    current_scope = current_scope->parent();
  }
  return NULL;
}

void LocalScope::CaptureVariable(LocalVariable* variable) {
  ASSERT(variable != NULL);

  // The variable must exist in an enclosing scope, not necessarily in this one.
  variable->set_is_captured();
  const int variable_function_level = variable->owner()->function_level();
  LocalScope* scope = this;
  while (scope->function_level() != variable_function_level) {
    // Insert an alias of the variable in the top scope of each function
    // level so that the variable is found in the context.
    LocalScope* parent_scope = scope->parent();
    while ((parent_scope != NULL) &&
           (parent_scope->function_level() == scope->function_level())) {
      scope = parent_scope;
      parent_scope = scope->parent();
    }
    // An alias may already have been added in this scope, and in that case,
    // in parent scopes as needed. If so, we are done.
    if (!scope->AddVariable(variable)) {
      return;
    }
    ASSERT(variable->owner() != scope);  // Item is an alias.
    scope = parent_scope;
  }
}

SourceLabel* LocalScope::LookupLabel(const String& name) {
  LocalScope* current_scope = this;
  while (current_scope != NULL) {
    SourceLabel* label = current_scope->LocalLookupLabel(name);
    if (label != NULL) {
      return label;
    }
    current_scope = current_scope->parent();
  }
  return NULL;
}

SourceLabel* LocalScope::LookupInnermostLabel(Token::Kind jump_kind) {
  ASSERT((jump_kind == Token::kCONTINUE) || (jump_kind == Token::kBREAK));
  LocalScope* current_scope = this;
  while (current_scope != NULL) {
    for (intptr_t i = 0; i < current_scope->labels_.length(); i++) {
      SourceLabel* label = current_scope->labels_[i];
      if ((label->kind() == SourceLabel::kWhile) ||
          (label->kind() == SourceLabel::kFor) ||
          (label->kind() == SourceLabel::kDoWhile) ||
          ((jump_kind == Token::kBREAK) &&
           (label->kind() == SourceLabel::kSwitch))) {
        return label;
      }
    }
    current_scope = current_scope->parent();
  }
  return NULL;
}

LocalScope* LocalScope::LookupSwitchScope() {
  LocalScope* current_scope = this->parent();
  int this_level = this->function_level();
  while (current_scope != NULL &&
         current_scope->function_level() == this_level) {
    for (int i = 0; i < current_scope->labels_.length(); i++) {
      SourceLabel* label = current_scope->labels_[i];
      if (label->kind() == SourceLabel::kSwitch) {
        // This scope contains a label that is bound to a switch statement,
        // so it is the scope of the a statement body.
        return current_scope;
      }
    }
    current_scope = current_scope->parent();
  }
  // We did not find a switch statement scope at the same function level.
  return NULL;
}

SourceLabel* LocalScope::CheckUnresolvedLabels() {
  for (int i = 0; i < this->labels_.length(); i++) {
    SourceLabel* label = this->labels_[i];
    if (label->kind() == SourceLabel::kForward) {
      LocalScope* outer_switch = LookupSwitchScope();
      if (outer_switch == NULL) {
        return label;
      } else {
        outer_switch->MoveLabel(label);
      }
    }
  }
  return NULL;
}

int LocalScope::NumCapturedVariables() const {
  // It is not necessary to traverse parent scopes, since we are only interested
  // in the captured variables referenced in this scope. If this scope is the
  // top scope at function level 1 and it (or its children scopes) references a
  // captured variable declared in a parent scope at function level 0, it will
  // contain an alias for that variable.

  // Since code generation for nested functions is postponed until first
  // invocation, the function level of the closure scope can only be 1.
  ASSERT(function_level() == 1);

  int num_captured = 0;
  for (int i = 0; i < num_variables(); i++) {
    LocalVariable* variable = VariableAt(i);
    // Count the aliases of captured variables belonging to outer scopes.
    if (variable->owner()->function_level() != 1) {
      ASSERT(variable->is_captured());
      ASSERT(variable->owner()->function_level() == 0);
      num_captured++;
    }
  }
  return num_captured;
}

ContextScopePtr LocalScope::PreserveOuterScope(
    int current_context_level) const {
  // Since code generation for nested functions is postponed until first
  // invocation, the function level of the closure scope can only be 1.
  ASSERT(function_level() == 1);

  // Count the number of referenced captured variables.
  intptr_t num_captured_vars = NumCapturedVariables();

  // Create a ContextScope with space for num_captured_vars descriptors.
  const ContextScope& context_scope =
      ContextScope::Handle(ContextScope::New(num_captured_vars, false));

  // Create a descriptor for each referenced captured variable of enclosing
  // functions to preserve its name and its context allocation information.
  int captured_idx = 0;
  for (int i = 0; i < num_variables(); i++) {
    LocalVariable* variable = VariableAt(i);
    // Preserve the aliases of captured variables belonging to outer scopes.
    if (variable->owner()->function_level() != 1) {
      context_scope.SetTokenIndexAt(captured_idx, variable->token_pos());
      context_scope.SetDeclarationTokenIndexAt(
          captured_idx, variable->declaration_token_pos());
      context_scope.SetNameAt(captured_idx, variable->name());
      context_scope.ClearFlagsAt(captured_idx);
      context_scope.SetIsFinalAt(captured_idx, variable->is_final());
      context_scope.SetIsLateAt(captured_idx, variable->is_late());
      if (variable->is_late()) {
        context_scope.SetLateInitOffsetAt(captured_idx,
                                          variable->late_init_offset());
      }
      context_scope.SetIsConstAt(captured_idx, variable->IsConst());
      if (variable->IsConst()) {
        context_scope.SetConstValueAt(captured_idx, *variable->ConstValue());
      } else {
        context_scope.SetTypeAt(captured_idx, variable->type());
      }
      context_scope.SetContextIndexAt(captured_idx, variable->index().value());
      // Adjust the context level relative to the current context level,
      // since the context of the current scope will be at level 0 when
      // compiling the nested function.
      int adjusted_context_level =
          variable->owner()->context_level() - current_context_level;
      context_scope.SetContextLevelAt(captured_idx, adjusted_context_level);
      captured_idx++;
    }
  }
  ASSERT(context_scope.num_variables() == captured_idx);  // Verify count.
  return context_scope.raw();
}

LocalScope* LocalScope::RestoreOuterScope(const ContextScope& context_scope) {
  // The function level of the outer scope is one less than the function level
  // of the current function, which is 0.
  LocalScope* outer_scope = new LocalScope(NULL, -1, 0);
  // Add all variables as aliases to the outer scope.
  for (int i = 0; i < context_scope.num_variables(); i++) {
    LocalVariable* variable;
    if (context_scope.IsConstAt(i)) {
      variable = new LocalVariable(context_scope.DeclarationTokenIndexAt(i),
                                   context_scope.TokenIndexAt(i),
                                   String::ZoneHandle(context_scope.NameAt(i)),
                                   Object::dynamic_type());
      variable->SetConstValue(
          Instance::ZoneHandle(context_scope.ConstValueAt(i)));
    } else {
      variable =
          new LocalVariable(context_scope.DeclarationTokenIndexAt(i),
                            context_scope.TokenIndexAt(i),
                            String::ZoneHandle(context_scope.NameAt(i)),
                            AbstractType::ZoneHandle(context_scope.TypeAt(i)));
    }
    variable->set_is_captured();
    variable->set_index(VariableIndex(context_scope.ContextIndexAt(i)));
    if (context_scope.IsFinalAt(i)) {
      variable->set_is_final();
    }
    if (context_scope.IsLateAt(i)) {
      variable->set_is_late();
      variable->set_late_init_offset(context_scope.LateInitOffsetAt(i));
    }
    // Create a fake owner scope describing the index and context level of the
    // variable. Function level and loop level are unused (set to 0), since
    // context level has already been assigned.
    LocalScope* owner_scope = new LocalScope(NULL, 0, 0);
    owner_scope->set_context_level(context_scope.ContextLevelAt(i));
    owner_scope->AddVariable(variable);
    outer_scope->AddVariable(variable);  // As alias.
    ASSERT(variable->owner() == owner_scope);
  }
  return outer_scope;
}

void LocalScope::CaptureLocalVariables(LocalScope* top_scope) {
  ASSERT(top_scope->function_level() == function_level());
  LocalScope* scope = this;
  while (scope != top_scope->parent()) {
    for (intptr_t i = 0; i < scope->num_variables(); i++) {
      LocalVariable* variable = scope->VariableAt(i);
      if (variable->is_forced_stack() ||
          (variable->name().raw() == Symbols::ExceptionVar().raw()) ||
          (variable->name().raw() == Symbols::SavedTryContextVar().raw()) ||
          (variable->name().raw() == Symbols::ArgDescVar().raw()) ||
          (variable->name().raw() ==
           Symbols::FunctionTypeArgumentsVar().raw())) {
        // Don't capture those variables because the VM expects them to be on
        // the stack.
        continue;
      }
      scope->CaptureVariable(variable);
    }
    scope = scope->parent();
  }
}

ContextScopePtr LocalScope::CreateImplicitClosureScope(const Function& func) {
  static const intptr_t kNumCapturedVars = 1;

  // Create a ContextScope with space for kNumCapturedVars descriptors.
  const ContextScope& context_scope =
      ContextScope::Handle(ContextScope::New(kNumCapturedVars, true));

  // Create a descriptor for 'this' variable.
  context_scope.SetTokenIndexAt(0, func.token_pos());
  context_scope.SetDeclarationTokenIndexAt(0, func.token_pos());
  context_scope.SetNameAt(0, Symbols::This());
  context_scope.ClearFlagsAt(0);
  context_scope.SetIsFinalAt(0, true);
  context_scope.SetIsConstAt(0, false);
  const AbstractType& type = AbstractType::Handle(func.ParameterTypeAt(0));
  context_scope.SetTypeAt(0, type);
  context_scope.SetContextIndexAt(0, 0);
  context_scope.SetContextLevelAt(0, 0);
  ASSERT(context_scope.num_variables() == kNumCapturedVars);  // Verify count.
  return context_scope.raw();
}

bool LocalVariable::Equals(const LocalVariable& other) const {
  if (HasIndex() && other.HasIndex() && (index() == other.index())) {
    if (is_captured() == other.is_captured()) {
      if (!is_captured()) {
        return true;
      }
      if (owner()->context_level() == other.owner()->context_level()) {
        return true;
      }
    }
  }
  return false;
}

void LocalVarDescriptorsBuilder::AddAll(Zone* zone,
                                        const LocalVarDescriptors& var_descs) {
  for (intptr_t i = 0, n = var_descs.Length(); i < n; ++i) {
    VarDesc desc;
    desc.name = &String::Handle(zone, var_descs.GetName(i));
    var_descs.GetInfo(i, &desc.info);
    Add(desc);
  }
}

void LocalVarDescriptorsBuilder::AddDeoptIdToContextLevelMappings(
    ZoneGrowableArray<intptr_t>* context_level_array) {
  // Record deopt-id -> context-level mappings, using ranges of deopt-ids with
  // the same context-level. [context_level_array] contains (deopt_id,
  // context_level) tuples.
  for (intptr_t start = 0; start < context_level_array->length();) {
    intptr_t start_deopt_id = (*context_level_array)[start];
    intptr_t start_context_level = (*context_level_array)[start + 1];
    intptr_t end = start;
    intptr_t end_deopt_id = start_deopt_id;
    for (intptr_t peek = start + 2; peek < context_level_array->length();
         peek += 2) {
      intptr_t peek_deopt_id = (*context_level_array)[peek];
      intptr_t peek_context_level = (*context_level_array)[peek + 1];
      // The range encoding assumes the tuples have ascending deopt_ids.
      ASSERT(peek_deopt_id > end_deopt_id);
      if (peek_context_level != start_context_level) break;
      end = peek;
      end_deopt_id = peek_deopt_id;
    }

    VarDesc desc;
    desc.name = &Symbols::Empty();  // No name.
    desc.info.set_kind(LocalVarDescriptorsLayout::kContextLevel);
    desc.info.scope_id = 0;
    // We repurpose the token position fields to store deopt IDs in this case.
    desc.info.begin_pos = TokenPosition::Deserialize(start_deopt_id);
    desc.info.end_pos = TokenPosition::Deserialize(end_deopt_id);
    desc.info.set_index(start_context_level);
    Add(desc);

    start = end + 2;
  }
}

LocalVarDescriptorsPtr LocalVarDescriptorsBuilder::Done() {
  if (vars_.is_empty()) {
    return Object::empty_var_descriptors().raw();
  }
  const LocalVarDescriptors& var_desc =
      LocalVarDescriptors::Handle(LocalVarDescriptors::New(vars_.length()));
  for (int i = 0; i < vars_.length(); i++) {
    var_desc.SetVar(i, *(vars_[i].name), &vars_[i].info);
  }
  return var_desc.raw();
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
