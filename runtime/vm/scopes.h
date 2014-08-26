// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SCOPES_H_
#define VM_SCOPES_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/symbols.h"
#include "vm/token.h"

namespace dart {

class LocalScope;


class LocalVariable : public ZoneAllocated {
 public:
  LocalVariable(intptr_t token_pos,
                const String& name,
                const AbstractType& type)
    : token_pos_(token_pos),
      name_(name),
      owner_(NULL),
      type_(type),
      const_value_(NULL),
      is_final_(false),
      is_captured_(false),
      is_invisible_(false),
      index_(LocalVariable::kUninitializedIndex) {
    ASSERT(type.IsZoneHandle());
    ASSERT(type.IsFinalized());
    ASSERT(name.IsSymbol());
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
    return index_ != kUninitializedIndex;
  }
  int index() const {
    ASSERT(HasIndex());
    return index_;
  }

  // Assign an index to a local.
  void set_index(int index) {
    ASSERT(index != kUninitializedIndex);
    index_ = index;
  }

  void set_invisible(bool value) {
    is_invisible_ = value;
  }
  bool is_invisible() const { return is_invisible_; }

  bool IsConst() const {
    return const_value_ != NULL;
  }

  void SetConstValue(const Instance& value) {
    ASSERT(value.IsZoneHandle() || value.IsReadOnlyHandle());
    const_value_ = &value;
  }

  const Instance* ConstValue() const {
    ASSERT(IsConst());
    return const_value_;
  }

  bool Equals(const LocalVariable& other) const;

  // Map the frame index to a bit-vector index.  Assumes the variable is
  // allocated to the frame.
  // var_count is the total number of stack-allocated variables including
  // all parameters.
  int BitIndexIn(intptr_t var_count) const;

 private:
  static const int kUninitializedIndex = INT_MIN;

  const intptr_t token_pos_;
  const String& name_;
  LocalScope* owner_;  // Local scope declaring this variable.

  const AbstractType& type_;  // Declaration type of local variable.

  const Instance* const_value_;   // NULL or compile-time const value.

  bool is_final_;  // If true, this variable is readonly.
  bool is_captured_;  // If true, this variable lives in the context, otherwise
                      // in the stack frame.
  bool is_invisible_;
  int index_;  // Allocation index in words relative to frame pointer (if not
               // captured), or relative to the context pointer (if captured).

  friend class LocalScope;
  DISALLOW_COPY_AND_ASSIGN(LocalVariable);
};


class NameReference : public ZoneAllocated {
 public:
  NameReference(intptr_t token_pos, const String& name)
    : token_pos_(token_pos),
      name_(name) {
    ASSERT(name.IsSymbol());
  }
  const String& name() const { return name_; }
  intptr_t token_pos() const { return token_pos_; }
  void set_token_pos(intptr_t value) { token_pos_ = value; }
 private:
  intptr_t token_pos_;
  const String& name_;
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
      kind_(kind) {
    ASSERT(name.IsSymbol());
  }

  static SourceLabel* New(intptr_t token_pos, String* name, Kind kind) {
    if (name != NULL) {
      return new SourceLabel(token_pos, *name, kind);
    } else {
      return new SourceLabel(token_pos,
                             Symbols::DefaultLabel(),
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

  // Returns the function level of the scope in which the label is defined.
  int FunctionLevel() const;

  void ResolveForwardReference() { kind_ = kCase; }

 private:
  const intptr_t token_pos_;
  const String& name_;
  LocalScope* owner_;  // Local scope declaring this label.

  Kind kind_;

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

  // Insert a formal parameter variable to the scope at the given position,
  // possibly in front of aliases already added with AddVariable.
  // Returns false if a variable with the same name is already present.
  bool InsertParameterAt(intptr_t pos, LocalVariable* parameter);

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

  // Lookup scope of outer switch statement at same function level.
  // Returns NULL if this scope is not embedded in a switch.
  LocalScope* LookupSwitchScope();

  // Looks up variable in this scope and mark as captured if applicable.
  // Finds the variable even if it is marked invisible. Returns true if
  // the variable was found, false if it was not found.
  bool CaptureVariable(const String& name);

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

  // Add a reference to the given name into this scope and the enclosing
  // scopes that do not have a local variable declaration for this name
  // already.
  void AddReferencedName(intptr_t token_pos, const String& name);
  intptr_t PreviousReferencePos(const String& name) const;

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
                        LocalScope** context_owner,
                        bool* found_captured_variables);

  // Creates variable info for the scope and all its nested scopes.
  // Must be called after AllocateVariables() has been called.
  RawLocalVarDescriptors* GetVarDescriptors(const Function& func);

  // Create a ContextScope object describing all captured variables referenced
  // from this scope and belonging to outer scopes.
  RawContextScope* PreserveOuterScope(int current_context_level) const;


  // Recursively traverses all siblings and children and marks all variables as
  // captured.
  void RecursivelyCaptureAllVariables();

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

  NameReference* FindReference(const String& name) const;

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

  // List of names referenced in this scope and its children that
  // are not resolved to local variables.
  GrowableArray<NameReference*> referenced_;

  DISALLOW_COPY_AND_ASSIGN(LocalScope);
};

}  // namespace dart

#endif  // VM_SCOPES_H_
