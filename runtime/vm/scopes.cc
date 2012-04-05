// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scopes.h"

#include "vm/ast.h"
#include "vm/object.h"

namespace dart {

const char* SourceLabel::kDefaultLabelName = ":L";


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
      end_token_index_(0),
      variables_(),
      labels_() {
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
                                  LocalScope** context_owner) {
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
    ASSERT(parameter->owner() == this);
    if (parameter->is_captured()) {
      // A captured parameter has a slot allocated in the frame and one in the
      // context, where it gets copied to. The parameter index reflects the
      // context allocation index.
      frame_index--;
      loop_owner->AllocateContextVariable(parameter, context_owner);
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
                                                     &child_context_owner);
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


RawLocalVarDescriptors* LocalScope::GetVarDescriptors() {
  GrowableArray<LocalVariable*> vars(8);
  // Variables of each scope are guaranteed to be consecutive elements
  // in array vars. See CollectLocalVariables() below. The outermost
  // scope (containing the function parameters) has id 0.
  CollectLocalVariables(&vars);
  const LocalVarDescriptors& var_desc =
      LocalVarDescriptors::Handle(LocalVarDescriptors::New(vars.length()));
  intptr_t scope_id = -1;
  LocalScope* current_scope = NULL;
  for (int i = 0;  i < vars.length(); i++) {
    LocalVariable* var = vars[i];
    if (current_scope != var->owner()) {
      current_scope = var->owner();
      scope_id += 1;
    }
    var_desc.SetVar(i, var->name(), var->index(),
        scope_id, var->token_index(), var->owner()->end_token_index());
  }
  return var_desc.raw();
}


// Add variables that are declared in this scope to vars, then collect
// variables of children, followed by siblings.
void LocalScope::CollectLocalVariables(GrowableArray<LocalVariable*>* vars) {
  for (int i = 0; i < this->variables_.length(); i++) {
    LocalVariable* var = variables_[i];
    // TODO(hausner): Remove the is_captured() condition once the debugger
    // can handle getting values of captured variables.
    if (!var->is_captured() && (var->owner() == this) &&
        Scanner::IsIdent(var->name())) {
      vars->Add(this->variables_[i]);
    }
  }
  if (child() != NULL) {
    child()->CollectLocalVariables(vars);
  }
  if (sibling() != NULL) {
    sibling()->CollectLocalVariables(vars);
  }
}


SourceLabel* LocalScope::LocalLookupLabel(const String& name) const {
  for (intptr_t i = 0; i < labels_.length(); i++) {
    SourceLabel* label = labels_[i];
    if (label->name().Equals(name)) {
      return label;
    }
  }
  return NULL;
}


LocalVariable* LocalScope::LocalLookupVariable(const String& name) const {
  for (intptr_t i = 0; i < variables_.length(); i++) {
    LocalVariable* var = variables_[i];
    if (var->name().Equals(name) && !var->is_invisible_) {
      return var;
    }
  }
  return NULL;
}


LocalVariable* LocalScope::LookupVariable(const String& name, bool test_only) {
  LocalScope* current_scope = this;
  while (current_scope != NULL) {
    LocalVariable* var = current_scope->LocalLookupVariable(name);
    if (var != NULL) {
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


SourceLabel* LocalScope::LookupInnermostCatchLabel() {
  LocalScope* current_scope = this;
  while (current_scope != NULL) {
    for (intptr_t i = 0; i < current_scope->labels_.length(); i++) {
      SourceLabel* label = current_scope->labels_[i];
      if (label->kind() == SourceLabel::kCatch) {
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
      context_scope.SetTokenIndexAt(captured_idx, variable->token_index());
      context_scope.SetNameAt(captured_idx, variable->name());
      context_scope.SetIsFinalAt(captured_idx, variable->is_final());
      context_scope.SetTypeAt(captured_idx, variable->type());
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
  LocalScope* outer_scope = new LocalScope(NULL, 0, 0);
  // Add all variables as aliases to the outer scope.
  for (int i = 0; i < context_scope.num_variables(); i++) {
    LocalVariable* variable =
        new LocalVariable(context_scope.TokenIndexAt(i),
                          String::ZoneHandle(context_scope.NameAt(i)),
                          AbstractType::ZoneHandle(context_scope.TypeAt(i)));
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


RawContextScope* LocalScope::CreateImplicitClosureScope(const Function& func) {
  static const intptr_t kNumCapturedVars = 1;

  // Create a ContextScope with space for kNumCapturedVars descriptors.
  const ContextScope& context_scope =
      ContextScope::Handle(ContextScope::New(kNumCapturedVars));

  // Create a descriptor for 'this' variable.
  const String& name = String::Handle(String::NewSymbol("this"));
  context_scope.SetTokenIndexAt(0, func.token_index());
  context_scope.SetNameAt(0, name);
  context_scope.SetIsFinalAt(0, true);
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

}  // namespace dart
