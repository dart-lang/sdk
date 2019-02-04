// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PARSER_H_
#define RUNTIME_VM_PARSER_H_

#include "include/dart_api.h"

#include "lib/invocation_mirror.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/ast.h"
#include "vm/class_finalizer.h"
#include "vm/hash_table.h"
#include "vm/kernel.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/scopes.h"
#include "vm/token.h"

namespace dart {

// Forward declarations.

namespace kernel {

class ScopeBuildingResult;

}  // namespace kernel

class ArgumentsDescriptor;
class Isolate;
class LocalScope;
class LocalVariable;
struct RegExpCompileData;
class SourceLabel;
template <typename T>
class GrowableArray;
class Parser;

struct CatchParamDesc;
class ClassDesc;
struct MemberDesc;
struct ParamList;
struct QualIdent;
class TopLevel;
class RecursionChecker;

// The class ParsedFunction holds the result of parsing a function.
class ParsedFunction : public ZoneAllocated {
 public:
  ParsedFunction(Thread* thread, const Function& function);

  const Function& function() const { return function_; }
  const Code& code() const { return code_; }

  SequenceNode* node_sequence() const { return node_sequence_; }
  void SetNodeSequence(SequenceNode* node_sequence);

  RegExpCompileData* regexp_compile_data() const {
    return regexp_compile_data_;
  }
  void SetRegExpCompileData(RegExpCompileData* regexp_compile_data);

  LocalVariable* instantiator() const { return instantiator_; }
  void set_instantiator(LocalVariable* instantiator) {
    ASSERT(instantiator != NULL);
    instantiator_ = instantiator;
  }

  LocalVariable* function_type_arguments() const {
    return function_type_arguments_;
  }
  void set_function_type_arguments(LocalVariable* function_type_arguments) {
    ASSERT(function_type_arguments != NULL);
    function_type_arguments_ = function_type_arguments;
  }
  LocalVariable* parent_type_arguments() const {
    return parent_type_arguments_;
  }
  void set_parent_type_arguments(LocalVariable* parent_type_arguments) {
    ASSERT(parent_type_arguments != NULL);
    parent_type_arguments_ = parent_type_arguments;
  }

  void set_default_parameter_values(ZoneGrowableArray<const Instance*>* list) {
    default_parameter_values_ = list;
#if defined(DEBUG)
    if (list == NULL) return;
    for (intptr_t i = 0; i < list->length(); i++) {
      ASSERT(list->At(i)->IsZoneHandle() || list->At(i)->InVMHeap());
    }
#endif
  }

  const Instance& DefaultParameterValueAt(intptr_t i) const {
    ASSERT(default_parameter_values_ != NULL);
    return *default_parameter_values_->At(i);
  }

  ZoneGrowableArray<const Instance*>* default_parameter_values() const {
    return default_parameter_values_;
  }

  LocalVariable* current_context_var() const { return current_context_var_; }

  bool has_arg_desc_var() const { return arg_desc_var_ != NULL; }
  LocalVariable* arg_desc_var() const { return arg_desc_var_; }

  LocalVariable* expression_temp_var() const {
    ASSERT(has_expression_temp_var());
    return expression_temp_var_;
  }
  void set_expression_temp_var(LocalVariable* value) {
    ASSERT(!has_expression_temp_var());
    expression_temp_var_ = value;
  }
  bool has_expression_temp_var() const { return expression_temp_var_ != NULL; }

  LocalVariable* entry_points_temp_var() const {
    ASSERT(has_entry_points_temp_var());
    return entry_points_temp_var_;
  }
  void set_entry_points_temp_var(LocalVariable* value) {
    ASSERT(!has_entry_points_temp_var());
    entry_points_temp_var_ = value;
  }
  bool has_entry_points_temp_var() const {
    return entry_points_temp_var_ != NULL;
  }

  LocalVariable* finally_return_temp_var() const {
    ASSERT(has_finally_return_temp_var());
    return finally_return_temp_var_;
  }
  void set_finally_return_temp_var(LocalVariable* value) {
    ASSERT(!has_finally_return_temp_var());
    finally_return_temp_var_ = value;
  }
  bool has_finally_return_temp_var() const {
    return finally_return_temp_var_ != NULL;
  }
  void EnsureFinallyReturnTemp(bool is_async);

  LocalVariable* EnsureExpressionTemp();
  LocalVariable* EnsureEntryPointsTemp();

  bool HasDeferredPrefixes() const { return deferred_prefixes_->length() != 0; }
  ZoneGrowableArray<const LibraryPrefix*>* deferred_prefixes() const {
    return deferred_prefixes_;
  }
  void AddDeferredPrefix(const LibraryPrefix& prefix);

  ZoneGrowableArray<const Field*>* guarded_fields() const {
    return guarded_fields_;
  }

  VariableIndex first_parameter_index() const { return first_parameter_index_; }
  int num_stack_locals() const { return num_stack_locals_; }

  void AllocateVariables();
  void AllocateIrregexpVariables(intptr_t num_stack_locals);
  void AllocateBytecodeVariables(intptr_t num_stack_locals);

  void record_await() { have_seen_await_expr_ = true; }
  bool have_seen_await() const { return have_seen_await_expr_; }
  bool is_forwarding_stub() const {
    return forwarding_stub_super_target_ != -1;
  }
  kernel::NameIndex forwarding_stub_super_target() const {
    return forwarding_stub_super_target_;
  }
  void MarkForwardingStub(kernel::NameIndex target) {
    forwarding_stub_super_target_ = target;
  }

  Thread* thread() const { return thread_; }
  Isolate* isolate() const { return thread_->isolate(); }
  Zone* zone() const { return thread_->zone(); }

  // Adds only relevant fields: field must be unique and its guarded_cid()
  // relevant.
  void AddToGuardedFields(const Field* field) const;

  void Bailout(const char* origin, const char* reason) const;

  kernel::ScopeBuildingResult* EnsureKernelScopes();

  LocalVariable* RawTypeArgumentsVariable() const {
    return raw_type_arguments_var_;
  }

  void SetRawTypeArgumentsVariable(LocalVariable* raw_type_arguments_var) {
    raw_type_arguments_var_ = raw_type_arguments_var;
  }

  void SetRawParameters(ZoneGrowableArray<LocalVariable*>* raw_parameters) {
    raw_parameters_ = raw_parameters;
  }

  LocalVariable* RawParameterVariable(intptr_t i) const {
    return raw_parameters_->At(i);
  }

 private:
  Thread* thread_;
  const Function& function_;
  Code& code_;
  SequenceNode* node_sequence_;
  RegExpCompileData* regexp_compile_data_;
  LocalVariable* instantiator_;
  LocalVariable* function_type_arguments_;
  LocalVariable* parent_type_arguments_;
  LocalVariable* current_context_var_;
  LocalVariable* arg_desc_var_;
  LocalVariable* expression_temp_var_;
  LocalVariable* entry_points_temp_var_;
  LocalVariable* finally_return_temp_var_;
  ZoneGrowableArray<const LibraryPrefix*>* deferred_prefixes_;
  ZoneGrowableArray<const Field*>* guarded_fields_;
  ZoneGrowableArray<const Instance*>* default_parameter_values_;

  LocalVariable* raw_type_arguments_var_;
  ZoneGrowableArray<LocalVariable*>* raw_parameters_ = nullptr;

  VariableIndex first_parameter_index_;
  int num_stack_locals_;
  bool have_seen_await_expr_;

  kernel::NameIndex forwarding_stub_super_target_;
  kernel::ScopeBuildingResult* kernel_scopes_;

  friend class Parser;
  DISALLOW_COPY_AND_ASSIGN(ParsedFunction);
};

class Parser : public ValueObject {
 public:
  // Parse a function to retrieve parameter information that is not retained in
  // the Function object. Returns either an error if the parse fails (which
  // could be the case for local functions), or a flat array of entries for each
  // parameter. Each parameter entry contains: * a Dart bool indicating whether
  // the parameter was declared final * its default value (or null if none was
  // declared) * an array of metadata (or null if no metadata was declared).
  enum {
    kParameterIsFinalOffset,
    kParameterDefaultValueOffset,
    kParameterMetadataOffset,
    kParameterEntrySize,
  };

 private:
  DISALLOW_COPY_AND_ASSIGN(Parser);
};

}  // namespace dart

#endif  // RUNTIME_VM_PARSER_H_
