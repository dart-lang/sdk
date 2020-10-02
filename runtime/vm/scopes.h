// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SCOPES_H_
#define RUNTIME_VM_SCOPES_H_

#include <limits>

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/symbols.h"
#include "vm/token.h"

namespace dart {

class CompileType;
class LocalScope;
class Slot;

// Indices of [LocalVariable]s are abstract and have little todo with the
// actual frame layout!
//
// There are generally 4 different kinds of [LocalVariable]s:
//
//    a) [LocalVariable]s refering to a parameter: The indices for those
//       variables are assigned by the flow graph builder. Parameter n gets
//       assigned the index (function.num_parameters - n - 1). I.e. the last
//       parameter has index 1.
//
//    b) [LocalVariable]s referring to actual variables in the body of a
//       function (either from Dart code or specially injected ones. The
//       indices of those variables are assigned by the scope builder
//       from 0, -1, ... -(M-1) for M local variables.
//
//       -> These variables participate in full SSA renaming and can therefore
//          be used with [StoreLocalInstr]s (in addition to [LoadLocal]s).
//
//    c) [LocalVariable]s referring to values on the expression stack. Those are
//       assigned by the flow graph builder. The indices of those variables are
//       assigned by the flow graph builder (it simulates the expression stack
//       height), they go from -NumVariables - ExpressionHeight.
//
//       -> These variables participate only partially in SSA renaming and can
//          therefore only be used with [LoadLocalInstr]s and with
//          [StoreLocalInstr]s **where no phis are necessary**.
//
//    b) [LocalVariable]s referring to captured variables.  Those are never
//       loaded/stored directly. Their only purpose is to tell the flow graph
//       builder how many parent links to follow and into which context index to
//       store.  The indices of those variables are assigned by the scope
//       builder and they refer to indices into context objects.
class VariableIndex {
 public:
  static const int kInvalidIndex = std::numeric_limits<int>::min();

  explicit VariableIndex(int value = kInvalidIndex) : value_(value) {}

  bool operator==(const VariableIndex& other) { return value_ == other.value_; }

  bool IsValid() const { return value_ != kInvalidIndex; }

  int value() const { return value_; }

 private:
  int value_;
};

class LocalVariable : public ZoneAllocated {
 public:
  LocalVariable(TokenPosition declaration_pos,
                TokenPosition token_pos,
                const String& name,
                const AbstractType& type,
                CompileType* parameter_type = nullptr,
                const Object* parameter_value = nullptr)
      : declaration_pos_(declaration_pos),
        token_pos_(token_pos),
        name_(name),
        owner_(NULL),
        type_(type),
        parameter_type_(parameter_type),
        parameter_value_(parameter_value),
        const_value_(NULL),
        is_final_(false),
        is_captured_(false),
        is_invisible_(false),
        is_captured_parameter_(false),
        is_forced_stack_(false),
        covariance_mode_(kNotCovariant),
        is_late_(false),
        is_chained_future_(false),
        expected_context_index_(-1),
        late_init_offset_(0),
        type_check_mode_(kDoTypeCheck),
        index_() {
    ASSERT(type.IsZoneHandle() || type.IsReadOnlyHandle());
    ASSERT(type.IsFinalized());
    ASSERT(name.IsSymbol());
  }

  TokenPosition token_pos() const { return token_pos_; }
  TokenPosition declaration_token_pos() const { return declaration_pos_; }
  const String& name() const { return name_; }
  LocalScope* owner() const { return owner_; }
  void set_owner(LocalScope* owner) {
    ASSERT(owner_ == NULL);
    owner_ = owner;
  }

  const AbstractType& type() const { return type_; }

  CompileType* parameter_type() const { return parameter_type_; }
  const Object* parameter_value() const { return parameter_value_; }

  bool is_final() const { return is_final_; }
  void set_is_final() { is_final_ = true; }

  bool is_captured() const { return is_captured_; }
  void set_is_captured() { is_captured_ = true; }

  // Variables marked as forced to stack are skipped and not captured by
  // CaptureLocalVariables - which iterates scope chain between two scopes
  // and indiscriminately marks all variables as captured.
  // TODO(27590) remove the hardcoded list of names from CaptureLocalVariables
  bool is_forced_stack() const { return is_forced_stack_; }
  void set_is_forced_stack() { is_forced_stack_ = true; }

  bool is_late() const { return is_late_; }
  void set_is_late() { is_late_ = true; }

  bool is_chained_future() const { return is_chained_future_; }
  void set_is_chained_future() { is_chained_future_ = true; }

  intptr_t expected_context_index() const { return expected_context_index_; }
  void set_expected_context_index(int index) {
    expected_context_index_ = index;
  }

  intptr_t late_init_offset() const { return late_init_offset_; }
  void set_late_init_offset(intptr_t late_init_offset) {
    late_init_offset_ = late_init_offset;
  }

  bool is_explicit_covariant_parameter() const {
    return covariance_mode_ == kExplicit;
  }
  void set_is_explicit_covariant_parameter() { covariance_mode_ = kExplicit; }

  bool needs_covariant_check_in_method() const {
    return covariance_mode_ != kNotCovariant;
  }
  void set_needs_covariant_check_in_method() {
    if (covariance_mode_ == kNotCovariant) {
      covariance_mode_ = kImplicit;
    }
  }

  enum TypeCheckMode {
    kDoTypeCheck,
    kSkipTypeCheck,
    kTypeCheckedByCaller,
  };

  // Returns true if this local variable represents a parameter that needs type
  // check when we enter the function.
  bool needs_type_check() const { return (type_check_mode_ == kDoTypeCheck); }

  // Returns true if this local variable represents a parameter which type is
  // guaranteed by the caller.
  bool was_type_checked_by_caller() const {
    return type_check_mode_ == kTypeCheckedByCaller;
  }

  TypeCheckMode type_check_mode() const { return type_check_mode_; }
  void set_type_check_mode(TypeCheckMode mode) { type_check_mode_ = mode; }

  bool HasIndex() const { return index_.IsValid(); }
  VariableIndex index() const {
    ASSERT(HasIndex());
    return index_;
  }

  // Assign an index to a local.
  void set_index(VariableIndex index) {
    ASSERT(index.IsValid());
    index_ = index;
  }

  void set_invisible(bool value) { is_invisible_ = value; }
  bool is_invisible() const { return is_invisible_; }

  bool is_captured_parameter() const { return is_captured_parameter_; }
  void set_is_captured_parameter(bool value) { is_captured_parameter_ = value; }

  // By convention, internal variables start with a colon.
  bool IsInternal() const { return name_.CharAt(0) == ':'; }

  bool IsConst() const { return const_value_ != NULL; }

  void SetConstValue(const Instance& value) {
    ASSERT(value.IsZoneHandle() || value.IsReadOnlyHandle());
    const_value_ = &value;
  }

  const Instance* ConstValue() const {
    ASSERT(IsConst());
    return const_value_;
  }

  bool Equals(const LocalVariable& other) const;

 private:
  enum CovarianceMode {
    kNotCovariant,
    kImplicit,
    kExplicit,
  };

  static const int kUninitializedIndex = INT_MIN;

  const TokenPosition declaration_pos_;
  const TokenPosition token_pos_;
  const String& name_;
  LocalScope* owner_;  // Local scope declaring this variable.

  const AbstractType& type_;  // Declaration type of local variable.

  CompileType* const parameter_type_;  // NULL or incoming parameter type.
  const Object* parameter_value_;      // NULL or incoming parameter value.

  const Instance* const_value_;  // NULL or compile-time const value.

  bool is_final_;     // If true, this variable is readonly.
  bool is_captured_;  // If true, this variable lives in the context, otherwise
                      // in the stack frame.
  bool is_invisible_;
  bool is_captured_parameter_;
  bool is_forced_stack_;
  CovarianceMode covariance_mode_;
  bool is_late_;
  bool is_chained_future_;
  intptr_t expected_context_index_;
  intptr_t late_init_offset_;
  TypeCheckMode type_check_mode_;
  VariableIndex index_;

  friend class LocalScope;
  DISALLOW_COPY_AND_ASSIGN(LocalVariable);
};

// Accumulates local variable descriptors while building
// LocalVarDescriptors object.
class LocalVarDescriptorsBuilder : public ValueObject {
 public:
  struct VarDesc {
    const String* name;
    LocalVarDescriptorsLayout::VarInfo info;
  };

  LocalVarDescriptorsBuilder() : vars_(8) {}

  // Add variable descriptor.
  void Add(const VarDesc& var_desc) { vars_.Add(var_desc); }

  // Add all variable descriptors from given [LocalVarDescriptors] object.
  void AddAll(Zone* zone, const LocalVarDescriptors& var_descs);

  // Record deopt-id -> context-level mappings, using ranges of deopt-ids with
  // the same context-level. [context_level_array] contains (deopt_id,
  // context_level) tuples.
  void AddDeoptIdToContextLevelMappings(
      ZoneGrowableArray<intptr_t>* context_level_array);

  // Finish building LocalVarDescriptor object.
  LocalVarDescriptorsPtr Done();

 private:
  GrowableArray<VarDesc> vars_;
};

class NameReference : public ZoneAllocated {
 public:
  NameReference(TokenPosition token_pos, const String& name)
      : token_pos_(token_pos), name_(name) {
    ASSERT(name.IsSymbol());
  }
  const String& name() const { return name_; }
  TokenPosition token_pos() const { return token_pos_; }
  void set_token_pos(TokenPosition value) { token_pos_ = value; }

 private:
  TokenPosition token_pos_;
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

  SourceLabel(TokenPosition token_pos, const String& name, Kind kind)
      : token_pos_(token_pos), name_(name), owner_(NULL), kind_(kind) {
    ASSERT(name.IsSymbol());
  }

  static SourceLabel* New(TokenPosition token_pos, String* name, Kind kind) {
    if (name != NULL) {
      return new SourceLabel(token_pos, *name, kind);
    } else {
      return new SourceLabel(token_pos, Symbols::DefaultLabel(), kind);
    }
  }

  TokenPosition token_pos() const { return token_pos_; }
  const String& name() const { return name_; }
  LocalScope* owner() const { return owner_; }
  void set_owner(LocalScope* owner) { owner_ = owner; }

  Kind kind() const { return kind_; }

  // Returns the function level of the scope in which the label is defined.
  int FunctionLevel() const;

  bool IsUnresolved() { return kind_ == kForward; }
  void ResolveForwardReference() { kind_ = kCase; }

 private:
  const TokenPosition token_pos_;
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
    return context_level_ != kUninitializedContextLevel;
  }
  int context_level() const {
    ASSERT(HasContextLevel());
    return context_level_;
  }
  void set_context_level(int context_level) {
    ASSERT(!HasContextLevel());
    ASSERT(context_level != kUninitializedContextLevel);
    context_level_ = context_level;
  }

  TokenPosition begin_token_pos() const { return begin_token_pos_; }
  void set_begin_token_pos(TokenPosition value) { begin_token_pos_ = value; }

  TokenPosition end_token_pos() const { return end_token_pos_; }
  void set_end_token_pos(TokenPosition value) { end_token_pos_ = value; }

  // Return the list of variables allocated in the context and belonging to this
  // scope and to its children at the same loop level.
  const GrowableArray<LocalVariable*>& context_variables() const {
    return context_variables_;
  }

  const ZoneGrowableArray<const Slot*>& context_slots() const {
    return *context_slots_;
  }

  // The number of variables allocated in the context and belonging to this
  // scope and to its children at the same loop level.
  int num_context_variables() const { return context_variables().length(); }

  // Add a variable to the scope. Returns false if a variable with the
  // same name is already present.
  bool AddVariable(LocalVariable* variable);

  // Add a variable to the scope as a context allocated variable and assigns
  // it an index within the context. Does not check if the scope already
  // contains this variable or a variable with the same name.
  void AddContextVariable(LocalVariable* var);

  // Insert a formal parameter variable to the scope at the given position,
  // possibly in front of aliases already added with AddVariable.
  // Returns false if a variable with the same name is already present.
  bool InsertParameterAt(intptr_t pos, LocalVariable* parameter);

  // Add a label to the scope. Returns false if a label with the same name
  // is already present.
  bool AddLabel(SourceLabel* label);

  // Move an unresolved label of a switch case label to an outer switch.
  void MoveLabel(SourceLabel* label);

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

  // Mark this variable as captured by this scope.
  void CaptureVariable(LocalVariable* variable);

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
  void AddReferencedName(TokenPosition token_pos, const String& name);
  TokenPosition PreviousReferencePos(const String& name) const;

  // Allocate both captured and non-captured variables declared in this scope
  // and in its children scopes of the same function level. Allocating means
  // assigning a frame slot index or a context slot index.
  // Parameters to be allocated in the frame must all appear in the top scope
  // and not in its children (we do not yet handle register parameters).
  // Locals must be listed after parameters in top scope and in its children.
  // Two locals in different sibling scopes may share the same frame slot.
  //
  // Return the index of the next available frame slot.
  VariableIndex AllocateVariables(VariableIndex first_parameter_index,
                                  int num_parameters,
                                  VariableIndex first_local_index,
                                  LocalScope* context_owner,
                                  bool* found_captured_variables);

  // Creates variable info for the scope and all its nested scopes.
  // Must be called after AllocateVariables() has been called.
  LocalVarDescriptorsPtr GetVarDescriptors(
      const Function& func,
      ZoneGrowableArray<intptr_t>* context_level_array);

  // Create a ContextScope object describing all captured variables referenced
  // from this scope and belonging to outer scopes.
  ContextScopePtr PreserveOuterScope(int current_context_level) const;

  // Mark all local variables that are accessible from this scope up to
  // top_scope (included) as captured unless they are marked as forced to stack.
  void CaptureLocalVariables(LocalScope* top_scope);

  // Creates a LocalScope representing the outer scope of a local function to be
  // compiled. This outer scope contains the variables captured by the function
  // as specified by the given ContextScope, which was created during the
  // compilation of the enclosing function.
  static LocalScope* RestoreOuterScope(const ContextScope& context_scope);

  // Create a ContextScope object which will capture "this" for an implicit
  // closure object.
  static ContextScopePtr CreateImplicitClosureScope(const Function& func);

 private:
  // Allocate the variable in the current context, possibly updating the current
  // context owner scope, if the variable is the first one to be allocated at
  // this loop level.
  // The variable may belong to this scope or to any of its children, but at the
  // same loop level.
  void AllocateContextVariable(LocalVariable* variable,
                               LocalScope** context_owner);

  void CollectLocalVariables(LocalVarDescriptorsBuilder* vars,
                             int16_t* scope_id);

  NameReference* FindReference(const String& name) const;

  static const int kUninitializedContextLevel = INT_MIN;
  LocalScope* parent_;
  LocalScope* child_;
  LocalScope* sibling_;
  int function_level_;  // Reflects the nesting level of local functions.
  int loop_level_;      // Reflects the loop nesting level.
  int context_level_;   // Reflects the level of the runtime context.
  TokenPosition begin_token_pos_;  // Token index of beginning of scope.
  TokenPosition end_token_pos_;    // Token index of end of scope.
  GrowableArray<LocalVariable*> variables_;
  GrowableArray<SourceLabel*> labels_;

  // List of variables allocated into the context which is owned by this scope,
  // and their corresponding Slots.
  GrowableArray<LocalVariable*> context_variables_;
  ZoneGrowableArray<const Slot*>* context_slots_;

  // List of names referenced in this scope and its children that
  // are not resolved to local variables.
  GrowableArray<NameReference*> referenced_;

  DISALLOW_COPY_AND_ASSIGN(LocalScope);
};

}  // namespace dart

#endif  // RUNTIME_VM_SCOPES_H_
