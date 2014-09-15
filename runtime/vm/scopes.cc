// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scopes.h"

#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

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
      context_level_(LocalScope::kUnitializedContextLevel),
      num_context_variables_(0),
      begin_token_pos_(0),
      end_token_pos_(0),
      variables_(),
      labels_(),
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


void LocalScope::AddReferencedName(intptr_t token_pos,
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


intptr_t LocalScope::PreviousReferencePos(const String& name) const {
  NameReference* ref = FindReference(name);
  if (ref != NULL) {
    return ref->token_pos();
  }
  return -1;
}


void LocalScope::AllocateContextVariable(LocalVariable* variable,
                                         LocalScope** context_owner) {
  ASSERT(variable->is_captured());
  ASSERT(variable->owner()->loop_level() == loop_level());
  if (num_context_variables_ == 0) {
    // This scope will allocate and chain a new context.
    int new_context_level = ((*context_owner) == NULL) ?
        1 : (*context_owner)->context_level() + 1;
    // This scope becomes the current context owner.
    *context_owner = this;
    set_context_level(new_context_level);
  }
  // The context level in the owner scope of a captured variable indicates at
  // code generation time how far to walk up the context chain in order to
  // access the variable from the current context level.
  if (!variable->owner()->HasContextLevel()) {
    ASSERT(variable->owner() != this);
    variable->owner()->set_context_level(context_level());
  } else {
    ASSERT(variable->owner()->context_level() == context_level());
  }
  variable->set_index(num_context_variables_++);
}


int LocalScope::AllocateVariables(int first_parameter_index,
                                  int num_parameters,
                                  int first_frame_index,
                                  LocalScope* loop_owner,
                                  LocalScope** context_owner,
                                  bool* found_captured_variables) {
  // We should not allocate variables of nested functions while compiling an
  // enclosing function.
  ASSERT(function_level() == 0);
  ASSERT(num_parameters >= 0);

  // Keep track of the current loop owner scope, that is of the highest parent
  // scope at the same loop level as this scope.
  if (loop_level() > loop_owner->loop_level()) {
    loop_owner = this;
  }
  // Parameters must be listed first and must all appear in the top scope.
  ASSERT(num_parameters <= num_variables());
  int pos = 0;  // Current variable position.
  int frame_index = first_parameter_index;  // Current free frame index.
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
      frame_index--;
      loop_owner->AllocateContextVariable(parameter, context_owner);
      *found_captured_variables = true;
    } else {
      parameter->set_index(frame_index--);
    }
  }
  // No overlapping of parameters and locals.
  ASSERT(frame_index >= first_frame_index);
  frame_index = first_frame_index;
  while (pos < num_variables()) {
    LocalVariable* variable = VariableAt(pos);
    pos++;
    if (variable->owner() == this) {
      if (variable->is_captured()) {
        loop_owner->AllocateContextVariable(variable, context_owner);
        *found_captured_variables = true;
      } else {
        variable->set_index(frame_index--);
      }
    }
  }
  // Allocate variables of all children.
  int min_frame_index = frame_index;
  LocalScope* child = this->child();
  while (child != NULL) {
    LocalScope* child_context_owner = *context_owner;
    int const dummy_parameter_index = 0;  // Ignored, since no parameters.
    int const num_parameters_in_child = 0;  // No parameters in children scopes.
    int child_frame_index = child->AllocateVariables(dummy_parameter_index,
                                                     num_parameters_in_child,
                                                     frame_index,
                                                     loop_owner,
                                                     &child_context_owner,
                                                     found_captured_variables);
    if (child_frame_index < min_frame_index) {
      min_frame_index = child_frame_index;
    }
    // A context allocated at a deeper loop level than the current loop level is
    // not shared between children.
    if ((child_context_owner != *context_owner) &&
        (child_context_owner->loop_level() <= loop_owner->loop_level())) {
      *context_owner = child_context_owner;  // Share context between siblings.
    }
    child = child->sibling();
  }
  return min_frame_index;
}


RawLocalVarDescriptors* LocalScope::GetVarDescriptors(const Function& func) {
  GrowableArray<VarDesc> vars(8);
  // First enter all variables from scopes of outer functions.
  const ContextScope& context_scope =
      ContextScope::Handle(func.context_scope());
  if (!context_scope.IsNull()) {
    ASSERT(func.IsLocalFunction());
    for (int i = 0; i < context_scope.num_variables(); i++) {
      VarDesc desc;
      desc.name = &String::Handle(context_scope.NameAt(i));
      desc.info.set_kind(RawLocalVarDescriptors::kContextVar);
      desc.info.scope_id = context_scope.ContextLevelAt(i);
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

  if (vars.length() == 0) {
    return Object::empty_var_descriptors().raw();
  }
  const LocalVarDescriptors& var_desc =
      LocalVarDescriptors::Handle(LocalVarDescriptors::New(vars.length()));
  for (int i = 0; i < vars.length(); i++) {
    var_desc.SetVar(i, *(vars[i].name), &vars[i].info);
  }
  return var_desc.raw();
}


// The parser creates internal variables that start with ":"
static bool IsInternalIdentifier(const String& str) {
  ASSERT(str.Length() > 0);
  return str.CharAt(0) == ':';
}


// Add visible variables that are declared in this scope to vars, then
// collect visible variables of children, followed by siblings.
void LocalScope::CollectLocalVariables(GrowableArray<VarDesc>* vars,
                                       int16_t* scope_id) {
  (*scope_id)++;
  if (HasContextLevel() &&
      ((parent() == NULL) ||
      (!parent()->HasContextLevel()) ||
      (parent()->context_level() != context_level()))) {
    // This is the outermost scope with a context level or this scope's
    // context level differs from its parent's level.
    VarDesc desc;
    desc.name = &Symbols::Empty();  // No name.
    desc.info.set_kind(RawLocalVarDescriptors::kContextLevel);
    desc.info.scope_id = *scope_id;
    desc.info.begin_pos = begin_token_pos();
    desc.info.end_pos = end_token_pos();
    desc.info.set_index(context_level());
    vars->Add(desc);
  }
  for (int i = 0; i < this->variables_.length(); i++) {
    LocalVariable* var = variables_[i];
    if ((var->owner() == this) && !var->is_invisible()) {
      if (!IsInternalIdentifier(var->name())) {
        // This is a regular Dart variable, either stack-based or captured.
        VarDesc desc;
        desc.name = &var->name();
        if (var->is_captured()) {
          desc.info.set_kind(RawLocalVarDescriptors::kContextVar);
          ASSERT(var->owner() != NULL);
          ASSERT(var->owner()->context_level() >= 0);
          desc.info.scope_id = var->owner()->context_level();
        } else {
          desc.info.set_kind(RawLocalVarDescriptors::kStackVar);
          desc.info.scope_id = *scope_id;
        }
        desc.info.begin_pos = var->token_pos();
        desc.info.end_pos = var->owner()->end_token_pos();
        desc.info.set_index(var->index());
        vars->Add(desc);
      } else if (var->name().raw() == Symbols::SavedEntryContextVar().raw()) {
        // This is the local variable in which the function saves the
        // caller's chain of closure contexts (caller's CTX register).
        VarDesc desc;
        desc.name = &var->name();
        desc.info.set_kind(RawLocalVarDescriptors::kSavedEntryContext);
        desc.info.scope_id = 0;
        desc.info.begin_pos = 0;
        desc.info.end_pos = 0;
        desc.info.set_index(var->index());
        vars->Add(desc);
      } else if (var->name().raw() == Symbols::SavedCurrentContextVar().raw()) {
        // This is the local variable in which the function saves its
        // own context before calling a closure function.
        VarDesc desc;
        desc.name = &var->name();
        desc.info.set_kind(RawLocalVarDescriptors::kSavedCurrentContext);
        desc.info.scope_id = 0;
        desc.info.begin_pos = 0;
        desc.info.end_pos = 0;
        desc.info.set_index(var->index());
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
    if ((var != NULL) && !var->is_invisible_) {
      if (!test_only) {
        if (var->owner()->function_level() != function_level()) {
          var->set_is_captured();
        }
        // Insert aliases of the variable in intermediate scopes.
        LocalScope* intermediate_scope = this;
        while (intermediate_scope != current_scope) {
          intermediate_scope->variables_.Add(var);
          ASSERT(var->owner() != intermediate_scope);  // Item is an alias.
          intermediate_scope = intermediate_scope->parent();
        }
      }
      return var;
    }
    current_scope = current_scope->parent();
  }
  return NULL;
}


bool LocalScope::CaptureVariable(const String& name) {
  ASSERT(name.IsSymbol());
  LocalScope* current_scope = this;
  while (current_scope != NULL) {
    LocalVariable* var = current_scope->LocalLookupVariable(name);
    if (var != NULL) {
      if (var->owner()->function_level() != function_level()) {
        var->set_is_captured();
      }
      // Insert aliases of the variable in intermediate scopes.
      LocalScope* intermediate_scope = this;
      while (intermediate_scope != current_scope) {
        intermediate_scope->variables_.Add(var);
        ASSERT(var->owner() != intermediate_scope);  // Item is an alias.
        intermediate_scope = intermediate_scope->parent();
      }
      return true;
    }
    current_scope = current_scope->parent();
  }
  return false;
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
        outer_switch->AddLabel(label);
      }
    }
  }
  return NULL;
}


int LocalScope::NumCapturedVariables() const {
  // It is not necessary to traverse parent scopes, since we are only interested
  // in the captured variables referenced in this scope. If this scope
  // references a captured variable declared in a parent scope, it will contain
  // an alias for that variable.

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


RawContextScope* LocalScope::PreserveOuterScope(int current_context_level)
    const {
  // Since code generation for nested functions is postponed until first
  // invocation, the function level of the closure scope can only be 1.
  ASSERT(function_level() == 1);

  // Count the number of referenced captured variables.
  intptr_t num_captured_vars = NumCapturedVariables();

  // Create a ContextScope with space for num_captured_vars descriptors.
  const ContextScope& context_scope =
      ContextScope::Handle(ContextScope::New(num_captured_vars));

  // Create a descriptor for each referenced captured variable of enclosing
  // functions to preserve its name and its context allocation information.
  int captured_idx = 0;
  for (int i = 0; i < num_variables(); i++) {
    LocalVariable* variable = VariableAt(i);
    // Preserve the aliases of captured variables belonging to outer scopes.
    if (variable->owner()->function_level() != 1) {
      context_scope.SetTokenIndexAt(captured_idx, variable->token_pos());
      context_scope.SetNameAt(captured_idx, variable->name());
      context_scope.SetIsFinalAt(captured_idx, variable->is_final());
      context_scope.SetIsConstAt(captured_idx, variable->IsConst());
      if (variable->IsConst()) {
        context_scope.SetConstValueAt(captured_idx, *variable->ConstValue());
      } else {
        context_scope.SetTypeAt(captured_idx, variable->type());
      }
      context_scope.SetContextIndexAt(captured_idx, variable->index());
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
      variable = new LocalVariable(context_scope.TokenIndexAt(i),
          String::ZoneHandle(context_scope.NameAt(i)),
          AbstractType::ZoneHandle(Type::DynamicType()));
      variable->SetConstValue(
          Instance::ZoneHandle(context_scope.ConstValueAt(i)));
    } else {
      variable = new LocalVariable(context_scope.TokenIndexAt(i),
          String::ZoneHandle(context_scope.NameAt(i)),
          AbstractType::ZoneHandle(context_scope.TypeAt(i)));
    }
    variable->set_is_captured();
    variable->set_index(context_scope.ContextIndexAt(i));
    if (context_scope.IsFinalAt(i)) {
      variable->set_is_final();
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


void LocalScope::RecursivelyCaptureAllVariables() {
  bool found = false;
  for (intptr_t i = 0; i < num_variables(); i++) {
    if ((VariableAt(i)->name().raw() == Symbols::StackTraceVar().raw()) ||
        (VariableAt(i)->name().raw() == Symbols::ExceptionVar().raw()) ||
        (VariableAt(i)->name().raw() == Symbols::SavedTryContextVar().raw())) {
      // Don't capture those variables because the VM expects them to be on the
      // stack.
      continue;
    }
    found = CaptureVariable(VariableAt(i)->name());
    // Also manually set the variable as captured as CaptureVariable() does not
    // handle capturing variables on the same scope level.
    VariableAt(i)->set_is_captured();
    ASSERT(found);
  }
  if (sibling() != NULL) { sibling()->RecursivelyCaptureAllVariables(); }
  if (child() != NULL) { child()->RecursivelyCaptureAllVariables(); }
}


RawContextScope* LocalScope::CreateImplicitClosureScope(const Function& func) {
  static const intptr_t kNumCapturedVars = 1;

  // Create a ContextScope with space for kNumCapturedVars descriptors.
  const ContextScope& context_scope =
      ContextScope::Handle(ContextScope::New(kNumCapturedVars));

  // Create a descriptor for 'this' variable.
  context_scope.SetTokenIndexAt(0, func.token_pos());
  context_scope.SetNameAt(0, Symbols::This());
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


int LocalVariable::BitIndexIn(intptr_t fixed_parameter_count) const {
  ASSERT(!is_captured());
  // Parameters have positive indexes with the lowest index being
  // kParamEndSlotFromFp + 1.  Locals and copied parameters have negative
  // indexes with the lowest (closest to 0) index being kFirstLocalSlotFromFp.
  if (index() > 0) {
    // Shift non-negative indexes so that the lowest one is 0.
    return fixed_parameter_count - (index() - kParamEndSlotFromFp);
  } else {
    // Shift negative indexes so that the lowest one is 0 (they are still
    // non-positive).
    return fixed_parameter_count - (index() - kFirstLocalSlotFromFp);
  }
}


}  // namespace dart
