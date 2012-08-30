// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SCOPES_H_
#define VM_SCOPES_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/growable_array.h"
#include "vm/symbols.h"

namespace dart {

class BitVector;
class JoinEntryInstr;
class LocalScope;
class LocalVariable;
class SourceLabel;


class LocalVariable : public ZoneAllocated {
 public:
  LocalVariable(intptr_t token_pos,
                const String& name,
                const AbstractType& type)
    : token_pos_(token_pos),
      name_(name),
      owner_(NULL),
      type_(type),
      is_final_(false),
      is_captured_(false),
      is_invisible_(false),
      index_(LocalVariable::kUnitializedIndex) {
    ASSERT(type.IsZoneHandle());
    ASSERT(type.IsFinalized());
  }

  intptr_t token_pos() const { return token_pos_; }
  const String& name() const { return name_; }
  LocalScope* owner() const { return owner_; }
  void set_owner(LocalScope* owner) {
    ASSERT(owner_ == NULL);
    owner_ = owner;
  }

  const AbstractType& type() const { return type_; }

  bool is_final() const { return is_final_; }
  void set_is_final() { is_final_ = true; }

  bool is_captured() const { return is_captured_; }
  void set_is_captured() { is_captured_ = true; }

  bool HasIndex() const {
    return index_ != kUnitializedIndex;
  }
  int index() const {
    ASSERT(HasIndex());
    return index_;
  }

  // Assign an index to a local.
  void set_index(int index) {
    ASSERT(!HasIndex());
    ASSERT(index != kUnitializedIndex);
    index_ = index;
  }

  void set_invisible(bool value) {
    is_invisible_ = value;
  }

  bool Equals(const LocalVariable& other) const;

  // Map the frame index to a bit-vector index.  Assumes the variable is
  // allocated to the frame.
  // var_count is the total number of stack-allocated variables including
  // all parameters.
  int BitIndexIn(intptr_t var_count) const;

 private:
  static const int kUnitializedIndex = INT_MIN;

  const intptr_t token_pos_;
  const String& name_;
  LocalScope* owner_;  // Local scope declaring this variable.

  const AbstractType& type_;  // Declaration type of local variable.

  bool is_final_;  // If true, this variable is readonly.
  bool is_captured_;  // If true, this variable lives in the context, otherwise
                      // in the stack frame.
  bool is_invisible_;
  int index_;  // Allocation index in words relative to frame pointer (if not
               // captured), or relative to the context pointer (if captured).

  friend class LocalScope;
  DISALLOW_COPY_AND_ASSIGN(LocalVariable);
};


class SourceLabel : public ZoneAllocated {
 public:
  enum Kind {
    kFor,
    kWhile,
    kDoWhile,
    kSwitch,
    kCase,
    kTry,
    kCatch,
    kForward,
    kStatement  // Any statement other than the above
  };

  SourceLabel(intptr_t token_pos, const String& name, Kind kind)
    : token_pos_(token_pos),
      name_(name),
      owner_(NULL),
      kind_(kind),
      continue_label_(),
      break_label_(),
      join_for_break_(NULL),
      join_for_continue_(NULL),
      is_continue_target_(false) {
  }

  static SourceLabel* New(intptr_t token_pos, String* name, Kind kind) {
    if (name != NULL) {
      return new SourceLabel(token_pos, *name, kind);
    } else {
      return new SourceLabel(token_pos,
                             String::ZoneHandle(Symbols::DefaultLabel()),
                             kind);
    }
  }

  intptr_t token_pos() const { return token_pos_; }
  const String& name() const { return name_; }
  LocalScope* owner() const { return owner_; }
  void set_owner(LocalScope* owner) {
    ASSERT(owner_ == NULL);
    owner_ = owner;
  }

  Kind kind() const { return kind_; }
  Label* break_label() { return &break_label_; }
  Label* continue_label() { return &continue_label_; }

  void set_join_for_continue(JoinEntryInstr* join) {
    ASSERT(join_for_continue_ == NULL);
    join_for_continue_ = join;
  }

  JoinEntryInstr* join_for_continue() const {
    return join_for_continue_;
  }

  bool is_continue_target() const { return is_continue_target_; }
  void set_is_continue_target(bool value) { is_continue_target_ = value; }

  void set_join_for_break(JoinEntryInstr* join) {
    ASSERT(join_for_break_ == NULL);
    join_for_break_ = join;
  }

  JoinEntryInstr* join_for_break() const {
    return join_for_break_;
  }

  // Returns the function level of the scope in which the label is defined.
  int FunctionLevel() const;

  void ResolveForwardReference() { kind_ = kCase; }

 private:
  const intptr_t token_pos_;
  const String& name_;
  LocalScope* owner_;  // Local scope declaring this label.

  Kind kind_;
  Label continue_label_;
  Label break_label_;
  JoinEntryInstr* join_for_break_;
  JoinEntryInstr* join_for_continue_;
  bool is_continue_target_;  // Needed for CaseNode.

  DISALLOW_COPY_AND_ASSIGN(SourceLabel);
};


class LocalScope : public ZoneAllocated {
 public:
  LocalScope(LocalScope* parent, int function_level, int loop_level);

  LocalScope* parent() const { return parent_; }
  LocalScope* child() const { return child_; }
  LocalScope* sibling() const { return sibling_; }
  int function_level() const { return function_level_; }
  int loop_level() const { return loop_level_; }

  // Check if this scope is nested within the passed in scope.
  bool IsNestedWithin(LocalScope* scope) const;

  // The context level is only set in a scope that is either the owner scope of
  // a captured variable or that is the owner scope of a context.
  bool HasContextLevel() const {
    return context_level_ != kUnitializedContextLevel;
  }
  int context_level() const {
    ASSERT(HasContextLevel());
    return context_level_;
  }
  void set_context_level(int context_level) {
    ASSERT(!HasContextLevel());
    ASSERT(context_level != kUnitializedContextLevel);
    context_level_ = context_level;
  }

  intptr_t begin_token_pos() const { return begin_token_pos_; }
  void set_begin_token_pos(intptr_t value) { begin_token_pos_ = value; }

  intptr_t end_token_pos() const { return end_token_pos_; }
  void set_end_token_pos(intptr_t value) { end_token_pos_ = value; }

  // The number of variables allocated in the context and belonging to this
  // scope and to its children at the same loop level.
  int num_context_variables() const { return num_context_variables_; }

  // Add a variable to the scope. Returns false if a variable with the
  // same name is already present.
  bool AddVariable(LocalVariable* variable);

  // Add a label to the scope. Returns false if a label with the same name
  // is already present.
  bool AddLabel(SourceLabel* label);

  // Lookup a variable in this scope only.
  LocalVariable* LocalLookupVariable(const String& name) const;

  // Lookup a label in this scope only.
  SourceLabel* LocalLookupLabel(const String& name) const;

  // Lookup a variable in this scope and its parents. If the variable
  // is found in a parent scope and 'test_only' is not true, we insert
  // aliases of the variable in the current and intermediate scopes up to
  // the declaration scope in order to detect "used before declared" errors.
  // We mark a variable as 'captured' when applicable.
  LocalVariable* LookupVariable(const String& name, bool test_only);

  // Lookup a label in this scope and its parents.
  SourceLabel* LookupLabel(const String& name);

  // Lookup the "innermost" label that labels a for, while, do, or switch
  // statement.
  SourceLabel* LookupInnermostLabel(Token::Kind jump_kind);

  // Lookup the label for the "innermost" catch block if one exists.
  SourceLabel* LookupInnermostCatchLabel();

  // Lookup scope of outer switch statement at same function level.
  // Returns NULL if this scope is not embedded in a switch.
  LocalScope* LookupSwitchScope();

  // Look for unresolved forward references to labels in this scope.
  // If there are any, propagate the forward reference to the next
  // outer scope of a switch statement. If there is no outer switch
  // statement, return the first unresolved label found.
  SourceLabel* CheckUnresolvedLabels();

  // Accessing the variables in the scope.
  intptr_t num_variables() const { return variables_.length(); }
  LocalVariable* VariableAt(intptr_t index) const {
    ASSERT((index >= 0) && (index < variables_.length()));
    return variables_[index];
  }

  // Count the captured variables belonging to outer scopes and referenced in
  // this local scope.
  int NumCapturedVariables() const;

  // Allocate both captured and non-captured variables declared in this scope
  // and in its children scopes of the same function level. Allocating means
  // assigning a frame slot index or a context slot index.
  // Parameters to be allocated in the frame must all appear in the top scope
  // and not in its children (we do not yet handle register parameters).
  // Locals must be listed after parameters in top scope and in its children.
  // Two locals in different sibling scopes may share the same frame slot.
  // Return the index of the next available frame slot.
  int AllocateVariables(int first_parameter_index,
                        int num_parameters,
                        int first_frame_index,
                        LocalScope* loop_owner,
                        LocalScope** context_owner);

  // Creates variable info for the scope and all its nested scopes.
  // Must be called after AllocateVariables() has been called.
  RawLocalVarDescriptors* GetVarDescriptors(const Function& func);

  // Create a ContextScope object describing all captured variables referenced
  // from this scope and belonging to outer scopes.
  RawContextScope* PreserveOuterScope(int current_context_level) const;

  // Creates a LocalScope representing the outer scope of a local function to be
  // compiled. This outer scope contains the variables captured by the function
  // as specified by the given ContextScope, which was created during the
  // compilation of the enclosing function.
  static LocalScope* RestoreOuterScope(const ContextScope& context_scope);

  // Create a ContextScope object which will capture "this" for an implicit
  // closure object.
  static RawContextScope* CreateImplicitClosureScope(const Function& func);

 private:
  struct VarDesc {
    const String* name;
    RawLocalVarDescriptors::VarInfo info;
  };

  // Allocate the variable in the current context, possibly updating the current
  // context owner scope, if the variable is the first one to be allocated at
  // this loop level.
  // The variable may belong to this scope or to any of its children, but at the
  // same loop level.
  void AllocateContextVariable(LocalVariable* variable,
                               LocalScope** context_owner);

  void CollectLocalVariables(GrowableArray<VarDesc>* vars, int16_t* scope_id);

  static const int kUnitializedContextLevel = INT_MIN;
  LocalScope* parent_;
  LocalScope* child_;
  LocalScope* sibling_;
  int function_level_;  // Reflects the nesting level of local functions.
  int loop_level_;      // Reflects the loop nesting level.
  int context_level_;   // Reflects the level of the runtime context.
  int num_context_variables_;   // Only set if this scope is a context owner.
  intptr_t begin_token_pos_;  // Token index of beginning of scope.
  intptr_t end_token_pos_;    // Token index of end of scope.
  GrowableArray<LocalVariable*> variables_;
  GrowableArray<SourceLabel*> labels_;

  DISALLOW_COPY_AND_ASSIGN(LocalScope);
};

}  // namespace dart

#endif  // VM_SCOPES_H_
