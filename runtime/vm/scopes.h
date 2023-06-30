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
//    a) [LocalVariable]s referring to a parameter: The indices for those
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
  static constexpr int kInvalidIndex = std::numeric_limits<int>::min();

  explicit VariableIndex(int value = kInvalidIndex) : value_(value) {}

  bool operator==(const VariableIndex& other) { return value_ == other.value_; }

  bool IsValid() const { return value_ != kInvalidIndex; }

  int value() const { return value_; }

 private:
  int value_;
};

class LocalVariable : public ZoneAllocated {
 public:
  static constexpr intptr_t kNoKernelOffset = -1;

  LocalVariable(TokenPosition declaration_pos,
                TokenPosition token_pos,
                const String& name,
                const AbstractType& type,
                intptr_t kernel_offset = kNoKernelOffset,
                CompileType* parameter_type = nullptr,
                const Object* parameter_value = nullptr)
      : declaration_pos_(declaration_pos),
        token_pos_(token_pos),
        name_(name),
        kernel_offset_(kernel_offset),
        annotations_offset_(kNoKernelOffset),
        owner_(nullptr),
        type_(type),
        parameter_type_(parameter_type),
        parameter_value_(parameter_value),
        const_value_(nullptr),
        is_final_(false),
        is_captured_(false),
        is_invisible_(false),
        is_captured_parameter_(false),
        is_forced_stack_(false),
        covariance_mode_(kNotCovariant),
        is_late_(false),
        late_init_offset_(0),
        type_check_mode_(kDoTypeCheck),
        index_(),
        is_awaiter_link_(IsAwaiterLink::kNotLink) {
    DEBUG_ASSERT(type.IsNotTemporaryScopedHandle());
    ASSERT(type.IsFinalized());
    ASSERT(name.IsSymbol());
    if (IsFilteredIdentifier(name)) {
      set_invisible(true);
    }
  }

  TokenPosition token_pos() const { return token_pos_; }
  TokenPosition declaration_token_pos() const { return declaration_pos_; }
  const String& name() const { return name_; }
  intptr_t kernel_offset() const { return kernel_offset_; }
  intptr_t annotations_offset() const { return annotations_offset_; }
  LocalScope* owner() const { return owner_; }
  void set_owner(LocalScope* owner) {
    ASSERT(owner_ == nullptr);
    owner_ = owner;
  }

  void set_annotations_offset(intptr_t offset) {
    annotations_offset_ = offset;
    is_awaiter_link_ = (offset == kNoKernelOffset) ? IsAwaiterLink::kNotLink
                                                   : IsAwaiterLink::kUnknown;
  }

  const AbstractType& type() const { return type_; }

  CompileType* parameter_type() const { return parameter_type_; }
  const Object* parameter_value() const { return parameter_value_; }

  bool is_final() const { return is_final_; }
  void set_is_final() { is_final_ = true; }

  bool is_captured() const { return is_captured_; }
  void set_is_captured() { is_captured_ = true; }

  bool ComputeIfIsAwaiterLink(const Library& library);
  void set_is_awaiter_link(bool value) {
    is_awaiter_link_ = value ? IsAwaiterLink::kLink : IsAwaiterLink::kNotLink;
  }

  // Variables marked as forced to stack are skipped and not captured by
  // CaptureLocalVariables - which iterates scope chain between two scopes
  // and indiscriminately marks all variables as captured.
  // TODO(27590) remove the hardcoded list of names from CaptureLocalVariables
  bool is_forced_stack() const { return is_forced_stack_; }
  void set_is_forced_stack() { is_forced_stack_ = true; }

  bool is_late() const { return is_late_; }
  void set_is_late() { is_late_ = true; }

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

  // Invisible variables are not included into LocalVarDescriptors
  // and not displayed in the debugger.
  void set_invisible(bool value) { is_invisible_ = value; }
  bool is_invisible() const { return is_invisible_; }

  bool is_captured_parameter() const { return is_captured_parameter_; }
  void set_is_captured_parameter(bool value) { is_captured_parameter_ = value; }

  bool IsConst() const { return const_value_ != nullptr; }

  void SetConstValue(const Instance& value) {
    DEBUG_ASSERT(value.IsNotTemporaryScopedHandle());
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

  static constexpr int kUninitializedIndex = INT_MIN;

  static bool IsFilteredIdentifier(const String& name);

  const TokenPosition declaration_pos_;
  const TokenPosition token_pos_;
  const String& name_;
  const intptr_t kernel_offset_;
  intptr_t annotations_offset_;
  LocalScope* owner_;  // Local scope declaring this variable.

  const AbstractType& type_;  // Declaration type of local variable.

  CompileType* const parameter_type_;  // nullptr or incoming parameter type.
  const Object* parameter_value_;      // nullptr or incoming parameter value.

  const Instance* const_value_;  // nullptr or compile-time const value.

  bool is_final_;     // If true, this variable is readonly.
  bool is_captured_;  // If true, this variable lives in the context, otherwise
                      // in the stack frame.
  bool is_invisible_;
  bool is_captured_parameter_;
  bool is_forced_stack_;
  CovarianceMode covariance_mode_;
  bool is_late_;
  intptr_t late_init_offset_;
  TypeCheckMode type_check_mode_;
  VariableIndex index_;

  enum class IsAwaiterLink {
    kUnknown,
    kNotLink,
    kLink,
  };
  IsAwaiterLink is_awaiter_link_;

  friend class LocalScope;
  DISALLOW_COPY_AND_ASSIGN(LocalVariable);
};

// Accumulates local variable descriptors while building
// LocalVarDescriptors object.
class LocalVarDescriptorsBuilder : public ValueObject {
 public:
  struct VarDesc {
    const String* name;
    UntaggedLocalVarDescriptors::VarInfo info;
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
  // same name and kernel offset is already present.
  bool AddVariable(LocalVariable* variable);

  // Add a variable to the scope as a context allocated variable and assigns
  // it an index within the context. Does not check if the scope already
  // contains this variable or a variable with the same name.
  void AddContextVariable(LocalVariable* var);

  // Insert a formal parameter variable to the scope at the given position,
  // possibly in front of aliases already added with AddVariable.
  // Returns false if a variable with the same name is already present.
  bool InsertParameterAt(intptr_t pos, LocalVariable* parameter);

  // Lookup a variable in this scope only.
  LocalVariable* LocalLookupVariable(const String& name,
                                     intptr_t kernel_offset) const;

  // Lookup a variable in this scope and its parents. If the variable
  // is found in a parent scope and 'test_only' is not true, we insert
  // aliases of the variable in the current and intermediate scopes up to
  // the declaration scope in order to detect "used before declared" errors.
  // We mark a variable as 'captured' when applicable.
  LocalVariable* LookupVariable(const String& name,
                                intptr_t kernel_offset,
                                bool test_only);

  // Lookup a variable in this scope and its parents by name.
  LocalVariable* LookupVariableByName(const String& name);

  // Mark this variable as captured by this scope.
  void CaptureVariable(LocalVariable* variable);

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
  //
  // Return the index of the next available frame slot.
  VariableIndex AllocateVariables(const Function& function,
                                  VariableIndex first_parameter_index,
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
  ContextScopePtr PreserveOuterScope(const Function& function,
                                     intptr_t current_context_level) const;

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

  static constexpr int kUninitializedContextLevel = INT_MIN;
  LocalScope* parent_;
  LocalScope* child_;
  LocalScope* sibling_;
  int function_level_;  // Reflects the nesting level of local functions.
  int loop_level_;      // Reflects the loop nesting level.
  int context_level_;   // Reflects the level of the runtime context.
  TokenPosition begin_token_pos_;  // Token index of beginning of scope.
  TokenPosition end_token_pos_;    // Token index of end of scope.
  GrowableArray<LocalVariable*> variables_;

  // List of variables allocated into the context which is owned by this scope,
  // and their corresponding Slots.
  GrowableArray<LocalVariable*> context_variables_;
  ZoneGrowableArray<const Slot*>* context_slots_;

  DISALLOW_COPY_AND_ASSIGN(LocalScope);
};

}  // namespace dart

#endif  // RUNTIME_VM_SCOPES_H_
