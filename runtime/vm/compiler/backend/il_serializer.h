// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "platform/assert.h"
#include "platform/text_buffer.h"

#include "vm/allocation.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/sexpression.h"
#include "vm/hash_table.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

// Flow graph serialization.
class FlowGraphSerializer : ValueObject {
 public:
#define FOR_EACH_BLOCK_ENTRY_KIND(M)                                           \
  M(Target)                                                                    \
  M(Join)                                                                      \
  M(Graph)                                                                     \
  M(Normal)                                                                    \
  M(Unchecked)                                                                 \
  M(OSR)                                                                       \
  M(Catch)                                                                     \
  M(Indirect)

  enum BlockEntryKind {
#define KIND_DECL(name) k##name,
    FOR_EACH_BLOCK_ENTRY_KIND(KIND_DECL)
#undef KIND_DECL
    // clang-format off
    kNumEntryKinds,
    kInvalid = -1,
    // clang-format on
  };

  // Special case: returns kTarget for a nullptr input.
  static BlockEntryKind BlockEntryTagToKind(SExpSymbol* tag);
  SExpSymbol* BlockEntryKindToTag(BlockEntryKind k);
  static bool BlockEntryKindHasInitialDefs(BlockEntryKind kind);

  static void SerializeToBuffer(Zone* zone,
                                const FlowGraph* flow_graph,
                                BaseTextBuffer* buffer);
  static SExpression* SerializeToSExp(Zone* zone, const FlowGraph* flow_graph);

  const FlowGraph* flow_graph() const { return flow_graph_; }
  Zone* zone() const { return zone_; }

  SExpression* FlowGraphToSExp();

  SExpSymbol* BlockEntryTag(const BlockEntryInstr* entry);
  SExpression* BlockIdToSExp(intptr_t block_id);
  SExpression* CanonicalNameToSExp(const Object& obj);
  SExpression* UseToSExp(const Definition* definition);

  // Helper method for creating canonical names.
  void SerializeCanonicalName(BaseTextBuffer* b, const Object& obj);

  // Methods for serializing Dart values. If the argument
  // value is the null object, the null pointer is returned.
  SExpression* AbstractTypeToSExp(const AbstractType& typ);
  SExpression* ArrayToSExp(const Array& arr);
  SExpression* ClassToSExp(const Class& cls);
  SExpression* ClosureToSExp(const Closure& c);
  SExpression* ContextToSExp(const Context& c);
  SExpression* CodeToSExp(const Code& c);
  SExpression* FieldToSExp(const Field& f);
  SExpression* FunctionToSExp(const Function& f);
  SExpression* InstanceToSExp(const Instance& obj);
  SExpression* TypeArgumentsToSExp(const TypeArguments& ta);

  // A method for serializing a Dart value of arbitrary type. Unlike the
  // type-specific methods, this returns the symbol "null" for the null object.
  SExpression* ObjectToSExp(const Object& obj);

  // A wrapper method for ObjectToSExp that first checks and sees if
  // the provided value is in the constant pool. If it is, then it
  // returns a reference to the constant definition via UseToSExp.
  SExpression* DartValueToSExp(const Object& obj);

  // A wrapper method for TypeArgumentsToSExp that also returns nullptr if the
  // type arguments are empty and checks against the constant pool.
  SExpression* NonEmptyTypeArgumentsToSExp(const TypeArguments& ta);

  // Methods for serializing IL-specific values.
  SExpression* LocalVariableToSExp(const LocalVariable& v);
  SExpression* SlotToSExp(const Slot& s);
  SExpression* ICDataToSExp(const ICData* ic_data);

  // Helper methods for adding Definition-specific extra info.
  bool HasDefinitionExtraInfo(const Definition* def);
  void AddDefinitionExtraInfoToSExp(const Definition* def, SExpList* sexp);

  // Helper methods for adding atoms to S-expression lists
  void AddBool(SExpList* sexp, bool b);
  void AddInteger(SExpList* sexp, intptr_t i);
  void AddString(SExpList* sexp, const char* cstr);
  void AddSymbol(SExpList* sexp, const char* cstr);
  void AddExtraBool(SExpList* sexp, const char* label, bool b);
  void AddExtraInteger(SExpList* sexp, const char* label, intptr_t i);
  void AddExtraString(SExpList* sexp, const char* label, const char* cstr);
  void AddExtraSymbol(SExpList* sexp, const char* label, const char* cstr);

 private:
  friend class Precompiler;  // For LLVMConstantsMap.

  FlowGraphSerializer(Zone* zone, const FlowGraph* flow_graph);
  ~FlowGraphSerializer();

  static const char* const initial_indent;

  // Helper methods for the function level that are not used by any
  // instruction serialization methods.
  SExpression* FunctionEntryToSExp(const BlockEntryInstr* entry);
  SExpression* EntriesToSExp(const GraphEntryInstr* start);
  SExpression* ConstantPoolToSExp(const GraphEntryInstr* start);

  const FlowGraph* const flow_graph_;
  Zone* const zone_;
  ObjectStore* const object_store_;

  // A map of currently open (being serialized) recursive types. We use this
  // to determine whether to serialize the referred types in TypeRefs.
  IntMap<const Type*> open_recursive_types_;

  // Used for --populate-llvm-constant-pool in ConstantPoolToSExp.
  class LLVMPoolMapKeyEqualsTraits : public AllStatic {
   public:
    static const char* Name() { return "LLVMPoolMapKeyEqualsTraits"; }
    static bool ReportStats() { return false; }

    static bool IsMatch(const Object& a, const Object& b) {
      return a.raw() == b.raw();
    }
    static uword Hash(const Object& obj) {
      if (obj.IsSmi()) return static_cast<uword>(obj.raw());
      if (obj.IsInstance()) return Instance::Cast(obj).CanonicalizeHash();
      return obj.GetClassId();
    }
  };
  typedef UnorderedHashMap<LLVMPoolMapKeyEqualsTraits> LLVMPoolMap;

  GrowableObjectArray& llvm_constants_;
  GrowableObjectArray& llvm_functions_;
  LLVMPoolMap llvm_constant_map_;
  Smi& llvm_index_;

  // Handles used across functions, where the contained value is used
  // immediately and does not need to live across calls to other serializer
  // functions.
  String& tmp_string_;

  // Handles for use within a single function in the following cases:
  //
  // * The function is guaranteed to not be re-entered during execution.
  // * The contained value is not live across any possible re-entry.
  //
  // Generally, the most likely source of possible re-entry is calling
  // DartValueToSExp with a sub-element of type Object, but any call to a
  // FlowGraphSerializer method that may eventually enter one of the methods
  // listed below should be examined with care.
  TypeArguments& array_type_args_;     // ArrayToSExp
  Context& closure_context_;           // ClosureToSExp
  Function& closure_function_;         // ClosureToSExp
  TypeArguments& closure_type_args_;   // ClosureToSExp
  Object& code_owner_;                 // CodeToSExp
  Context& context_parent_;            // ContextToSExp
  Object& context_elem_;               // ContextToSExp
  TypeArguments& function_type_args_;  // FunctionToSExp
  Function& ic_data_target_;           // ICDataToSExp
  AbstractType& ic_data_type_;         // ICDataToSExp
  Field& instance_field_;              // InstanceToSExp
  TypeArguments& instance_type_args_;  // InstanceToSExp
  Library& serialize_library_;         // SerializeCanonicalName
  Class& serialize_owner_;             // SerializeCanonicalName
  Function& serialize_parent_;         // SerializeCanonicalName
  AbstractType& type_arguments_elem_;  // TypeArgumentsToSExp
  Class& type_class_;                  // AbstractTypeToSExp
  Function& type_function_;            // AbstractTypeToSExp
  AbstractType& type_ref_type_;        // AbstractTypeToSExp
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
