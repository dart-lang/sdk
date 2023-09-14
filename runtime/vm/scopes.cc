// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/scopes.h"

#include "vm/compiler/backend/slot.h"
#include "vm/kernel.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"


namespace dart {

DEFINE_FLAG(bool,
            share_enclosing_context,
            true,
            "Allocate captured variables in the existing context of an "
            "enclosing scope (up to innermost loop) and spare the allocation "
            "of a local context.");

LocalScope::LocalScope(LocalScope* parent, int function_level, int loop_level)
    : parent_(parent),
      child_(nullptr),
      sibling_(nullptr),
      function_level_(function_level),
      loop_level_(loop_level),
      context_level_(LocalScope::kUninitializedContextLevel),
      begin_token_pos_(TokenPosition::kNoSource),
      end_token_pos_(TokenPosition::kNoSource),
      variables_(),
      context_variables_(),
      context_slots_(new(Thread::Current()->zone())
                         ZoneGrowableArray<const Slot*>()) {
  // Hook this node into the children of the parent, unless the parent has a
  // different function_level, since the local scope of a nested function can
  // be discarded after it has been parsed.
  if ((parent != nullptr) && (parent->function_level() == function_level)) {
    sibling_ = parent->child_;
    parent->child_ = this;
  }
}

bool LocalScope::IsNestedWithin(LocalScope* scope) const {
  const LocalScope* current_scope = this;
  while (current_scope != nullptr) {
    if (current_scope == scope) {
      return true;
    }
    current_scope = current_scope->parent();
  }
  return false;
}

bool LocalScope::AddVariable(LocalVariable* variable) {
  ASSERT(variable != nullptr);
  if (LocalLookupVariable(variable->name(), variable->kernel_offset()) !=
      nullptr) {
    return false;
  }
  variables_.Add(variable);
  if (variable->owner() == nullptr) {
    // Variables must be added to their owner scope first. Subsequent calls
    // to 'add' treat the variable as an alias.
    variable->set_owner(this);
  }
  return true;
}

bool LocalScope::InsertParameterAt(intptr_t pos, LocalVariable* parameter) {
  ASSERT(parameter != nullptr);
  if (LocalLookupVariable(parameter->name(), parameter->kernel_offset()) !=
      nullptr) {
    return false;
  }
  variables_.InsertAt(pos, parameter);
  // InsertParameterAt is not used to add aliases of parameters.
  ASSERT(parameter->owner() == nullptr);
  parameter->set_owner(this);
  return true;
}

void LocalScope::AllocateContextVariable(LocalVariable* variable,
                                         LocalScope** context_owner) {
  ASSERT(variable->is_captured());
  ASSERT(variable->owner() == this);
  // The context level in the owner scope of a captured variable indicates at
  // code generation time how far to walk up the context chain in order to
  // access the variable from the current context level.
  if ((*context_owner) == nullptr) {
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

VariableIndex LocalScope::AllocateVariables(const Function& function,
                                            VariableIndex first_parameter_index,
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

  LocalVariable* suspend_state_var = nullptr;
  for (intptr_t i = 0; i < num_variables(); i++) {
    LocalVariable* variable = VariableAt(i);
    if (variable->owner() == this &&
        variable->name().Equals(Symbols::SuspendStateVar())) {
      ASSERT(!variable->is_captured());
      suspend_state_var = variable;
    }
  }

  if (suspend_state_var != nullptr) {
    suspend_state_var->set_index(
        VariableIndex(SuspendState::kSuspendStateVarIndex));
    ASSERT(next_index.value() == SuspendState::kSuspendStateVarIndex - 1);
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
  for (; pos < num_variables(); pos++) {
    LocalVariable* variable = VariableAt(pos);
    if (variable == suspend_state_var) {
      continue;
    }

    if (variable->owner() == this) {
      if (variable->is_captured()) {
        AllocateContextVariable(variable, &context_owner);
        *found_captured_variables = true;
      } else {
        variable->set_index(next_index);
        next_index = VariableIndex(next_index.value() - 1);
      }
    }
  }
  // Allocate variables of all children.
  VariableIndex min_index = next_index;
  LocalScope* child = this->child();
  while (child != nullptr) {
    // Ignored, since no parameters.
    const VariableIndex dummy_parameter_index(0);

    // No parameters in children scopes.
    const int num_parameters_in_child = 0;
    VariableIndex child_next_index = child->AllocateVariables(
        function, dummy_parameter_index, num_parameters_in_child, next_index,
        context_owner, found_captured_variables);
    if (child_next_index.value() < min_index.value()) {
      min_index = child_next_index;
    }
    child = child->sibling();
  }
  return min_index;
}

LocalVariable::LocalVariable(TokenPosition declaration_pos,
                             TokenPosition token_pos,
                             const String& name,
                             const AbstractType& static_type,
                             intptr_t kernel_offset)
    : LocalVariable(declaration_pos,
                    token_pos,
                    name,
                    static_type,
                    kernel_offset,
                    new CompileType(CompileType::FromAbstractType(
                        static_type,
                        CompileType::kCanBeNull,
                        CompileType::kCannotBeSentinel))) {}

// VM creates internal variables that start with ":"
bool LocalVariable::IsFilteredIdentifier(const String& name) {
  ASSERT(name.Length() > 0);
  if (name.ptr() == Symbols::FunctionTypeArgumentsVar().ptr()) {
    // Keep :function_type_arguments for accessing type variables in debugging.
    return false;
  }
  return name.CharAt(0) == ':';
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
    ASSERT(func.HasParent());
    for (int i = 0; i < context_scope.num_variables(); i++) {
      if (context_scope.IsInvisibleAt(i)) {
        continue;
      }
      String& name = String::Handle(context_scope.NameAt(i));
      ASSERT(!LocalVariable::IsFilteredIdentifier(name));

      LocalVarDescriptorsBuilder::VarDesc desc;
      desc.name = &name;
      desc.info.set_kind(UntaggedLocalVarDescriptors::kContextVar);
      desc.info.scope_id = context_scope.ContextLevelAt(i);
      desc.info.declaration_pos = context_scope.DeclarationTokenIndexAt(i);
      desc.info.begin_pos = begin_token_pos();
      desc.info.end_pos = end_token_pos();
      ASSERT((desc.info.begin_pos.IsReal() != desc.info.end_pos.IsReal()) ||
             (desc.info.begin_pos <= desc.info.end_pos));
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
    if (var->owner() == this) {
      if (var->name().ptr() == Symbols::CurrentContextVar().ptr()) {
        // This is the local variable in which the function saves its
        // own context before calling a closure function.
        LocalVarDescriptorsBuilder::VarDesc desc;
        desc.name = &var->name();
        desc.info.set_kind(UntaggedLocalVarDescriptors::kSavedCurrentContext);
        desc.info.scope_id = 0;
        desc.info.declaration_pos = TokenPosition::kMinSource;
        desc.info.begin_pos = TokenPosition::kMinSource;
        desc.info.end_pos = TokenPosition::kMinSource;
        desc.info.set_index(var->index().value());
        vars->Add(desc);
      } else if (!var->is_invisible()) {
        ASSERT(!LocalVariable::IsFilteredIdentifier(var->name()));
        // This is a regular Dart variable, either stack-based or captured.
        LocalVarDescriptorsBuilder::VarDesc desc;
        desc.name = &var->name();
        if (var->is_captured()) {
          desc.info.set_kind(UntaggedLocalVarDescriptors::kContextVar);
          ASSERT(var->owner() != nullptr);
          ASSERT(var->owner()->context_level() >= 0);
          desc.info.scope_id = var->owner()->context_level();
        } else {
          desc.info.set_kind(UntaggedLocalVarDescriptors::kStackVar);
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
  while (child != nullptr) {
    child->CollectLocalVariables(vars, scope_id);
    child = child->sibling();
  }
}

LocalVariable* LocalScope::LocalLookupVariable(const String& name,
                                               intptr_t kernel_offset) const {
  ASSERT(name.IsSymbol());
  for (intptr_t i = 0; i < variables_.length(); i++) {
    LocalVariable* var = variables_[i];
    ASSERT(var->name().IsSymbol());
    if ((var->name().ptr() == name.ptr()) &&
        (var->kernel_offset() == kernel_offset)) {
      return var;
    }
  }
  return nullptr;
}

LocalVariable* LocalScope::LookupVariable(const String& name,
                                          intptr_t kernel_offset,
                                          bool test_only) {
  LocalScope* current_scope = this;
  while (current_scope != nullptr) {
    LocalVariable* var =
        current_scope->LocalLookupVariable(name, kernel_offset);
    // If testing only, return the variable even if invisible.
    if ((var != nullptr) && (!var->is_invisible() || test_only)) {
      if (!test_only && (var->owner()->function_level() != function_level())) {
        CaptureVariable(var);
      }
      return var;
    }
    current_scope = current_scope->parent();
  }
  return nullptr;
}

LocalVariable* LocalScope::LookupVariableByName(const String& name) {
  ASSERT(name.IsSymbol());
  for (LocalScope* scope = this; scope != nullptr; scope = scope->parent()) {
    for (intptr_t i = 0, n = scope->variables_.length(); i < n; ++i) {
      LocalVariable* var = scope->variables_[i];
      ASSERT(var->name().IsSymbol());
      if (var->name().ptr() == name.ptr()) {
        return var;
      }
    }
  }
  return nullptr;
}

void LocalScope::CaptureVariable(LocalVariable* variable) {
  ASSERT(variable != nullptr);

  // The variable must exist in an enclosing scope, not necessarily in this one.
  variable->set_is_captured();
  const int variable_function_level = variable->owner()->function_level();
  LocalScope* scope = this;
  while (scope->function_level() != variable_function_level) {
    // Insert an alias of the variable in the top scope of each function
    // level so that the variable is found in the context.
    LocalScope* parent_scope = scope->parent();
    while ((parent_scope != nullptr) &&
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
    const Function& function,
    intptr_t current_context_level) const {
  Zone* zone = Thread::Current()->zone();
  auto& library = Library::Handle(
      zone, function.IsNull()
                ? Library::null()
                : Class::Handle(zone, function.Owner()).library());
  // Since code generation for nested functions is postponed until first
  // invocation, the function level of the closure scope can only be 1.
  ASSERT(function_level() == 1);

  // Count the number of referenced captured variables.
  intptr_t num_captured_vars = NumCapturedVariables();

  // Create a ContextScope with space for num_captured_vars descriptors.
  const ContextScope& context_scope =
      ContextScope::Handle(ContextScope::New(num_captured_vars, false));

  LocalVariable* awaiter_link = nullptr;

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
      CompileType* type = variable->inferred_type();
      context_scope.SetTypeAt(captured_idx, *type->ToAbstractType());
      context_scope.SetCidAt(captured_idx, type->ToNullableCid());
      context_scope.SetIsNullableAt(captured_idx, type->is_nullable());
      context_scope.SetIsInvisibleAt(captured_idx, variable->is_invisible());
      context_scope.SetContextIndexAt(captured_idx, variable->index().value());
      // Adjust the context level relative to the current context level,
      // since the context of the current scope will be at level 0 when
      // compiling the nested function.
      intptr_t adjusted_context_level =
          variable->owner()->context_level() - current_context_level;
      context_scope.SetContextLevelAt(captured_idx, adjusted_context_level);
      context_scope.SetKernelOffsetAt(captured_idx, variable->kernel_offset());

      // Handle async frame link.
      const bool is_awaiter_link = variable->ComputeIfIsAwaiterLink(library);
      context_scope.SetIsAwaiterLinkAt(captured_idx, is_awaiter_link);
      if (is_awaiter_link) {
        awaiter_link = variable;
      }
      captured_idx++;
    }
  }
  ASSERT(context_scope.num_variables() == captured_idx);  // Verify count.

  if (awaiter_link != nullptr) {
    const intptr_t depth =
        current_context_level - awaiter_link->owner()->context_level();
    const intptr_t index = awaiter_link->index().value();
    if (Utils::IsUint(8, depth) && Utils::IsUint(8, index)) {
      function.set_awaiter_link(
          {static_cast<uint8_t>(depth), static_cast<uint8_t>(index)});
    } else if (FLAG_precompiled_mode) {
      OS::PrintErr(
          "Warning: @pragma('vm:awaiter-link') marked variable %s is visible "
          "from the function %s but the link {%" Pd ", %" Pd
          "} can't be encoded\n",
          awaiter_link->name().ToCString(),
          function.IsNull() ? "<?>" : function.ToFullyQualifiedCString(), depth,
          index);
    }
  }

  return context_scope.ptr();
}

LocalScope* LocalScope::RestoreOuterScope(const ContextScope& context_scope) {
  // The function level of the outer scope is one less than the function level
  // of the current function, which is 0.
  LocalScope* outer_scope = new LocalScope(nullptr, -1, 0);
  // Add all variables as aliases to the outer scope.
  for (int i = 0; i < context_scope.num_variables(); i++) {
    const bool is_late = context_scope.IsLateAt(i);
    const auto& static_type = AbstractType::ZoneHandle(context_scope.TypeAt(i));
    CompileType* inferred_type =
        new CompileType(context_scope.IsNullableAt(i), is_late,
                        context_scope.CidAt(i), &static_type);
    LocalVariable* variable = new LocalVariable(
        context_scope.DeclarationTokenIndexAt(i), context_scope.TokenIndexAt(i),
        String::ZoneHandle(context_scope.NameAt(i)), static_type,
        context_scope.KernelOffsetAt(i), inferred_type);
    variable->set_is_awaiter_link(context_scope.IsAwaiterLinkAt(i));
    variable->set_is_captured();
    variable->set_index(VariableIndex(context_scope.ContextIndexAt(i)));
    if (context_scope.IsFinalAt(i)) {
      variable->set_is_final();
    }
    if (is_late) {
      variable->set_is_late();
      variable->set_late_init_offset(context_scope.LateInitOffsetAt(i));
    }
    if (context_scope.IsInvisibleAt(i)) {
      variable->set_invisible(true);
    }
    // Create a fake owner scope describing the index and context level of the
    // variable. Function level and loop level are unused (set to 0), since
    // context level has already been assigned.
    LocalScope* owner_scope = new LocalScope(nullptr, 0, 0);
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
          (variable->name().ptr() == Symbols::ExceptionVar().ptr()) ||
          (variable->name().ptr() == Symbols::SavedTryContextVar().ptr()) ||
          (variable->name().ptr() == Symbols::ArgDescVar().ptr()) ||
          (variable->name().ptr() ==
           Symbols::FunctionTypeArgumentsVar().ptr())) {
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
  const intptr_t kNumCapturedVars = 1;

  // Create a ContextScope with space for kNumCapturedVars descriptors.
  const ContextScope& context_scope =
      ContextScope::Handle(ContextScope::New(kNumCapturedVars, true));

  // Create a descriptor for 'this' variable.
  context_scope.SetTokenIndexAt(0, func.token_pos());
  context_scope.SetDeclarationTokenIndexAt(0, func.token_pos());
  context_scope.SetNameAt(0, Symbols::This());
  context_scope.ClearFlagsAt(0);
  context_scope.SetIsFinalAt(0, true);
  const AbstractType& type = AbstractType::Handle(func.ParameterTypeAt(0));
  context_scope.SetTypeAt(0, type);
  context_scope.SetCidAt(0, kIllegalCid);
  context_scope.SetContextIndexAt(0, 0);
  context_scope.SetContextLevelAt(0, 0);
  context_scope.SetKernelOffsetAt(0, LocalVariable::kNoKernelOffset);
  ASSERT(context_scope.num_variables() == kNumCapturedVars);  // Verify count.
  return context_scope.ptr();
}

bool LocalVariable::ComputeIfIsAwaiterLink(const Library& library) {
  if (is_awaiter_link_ == IsAwaiterLink::kUnknown) {
    RELEASE_ASSERT(annotations_offset_ != kNoKernelOffset);
    Thread* T = Thread::Current();
    Zone* Z = T->zone();
    const auto& metadata = Object::Handle(
        Z, kernel::EvaluateMetadata(library, annotations_offset_,
                                    /* is_annotations_offset = */ true));
    set_is_awaiter_link(
        FindPragmaInMetadata(T, metadata, Symbols::vm_awaiter_link()));
  }
  return is_awaiter_link_ == IsAwaiterLink::kLink;
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
    desc.info.set_kind(UntaggedLocalVarDescriptors::kContextLevel);
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
    return Object::empty_var_descriptors().ptr();
  }
  const LocalVarDescriptors& var_desc =
      LocalVarDescriptors::Handle(LocalVarDescriptors::New(vars_.length()));
  for (int i = 0; i < vars_.length(); i++) {
    var_desc.SetVar(i, *(vars_[i].name), &vars_[i].info);
  }
  return var_desc.ptr();
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
