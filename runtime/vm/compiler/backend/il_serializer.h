// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_

#include "platform/assert.h"
#include "platform/text_buffer.h"

#include "vm/allocation.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/sexpression.h"
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

  static void SerializeToBuffer(const FlowGraph* flow_graph,
                                TextBuffer* buffer);
  static void SerializeToBuffer(Zone* zone,
                                const FlowGraph* flow_graph,
                                TextBuffer* buffer);
  static SExpression* SerializeToSExp(const FlowGraph* flow_graph);
  static SExpression* SerializeToSExp(Zone* zone, const FlowGraph* flow_graph);

  const FlowGraph* flow_graph() const { return flow_graph_; }
  Zone* zone() const { return zone_; }

  SExpression* FlowGraphToSExp();

  SExpSymbol* BlockEntryTag(const BlockEntryInstr* entry);
  SExpression* BlockIdToSExp(intptr_t block_id);
  SExpression* CanonicalNameToSExp(const Object& obj);
  SExpression* UseToSExp(const Definition* definition);

  // Helper method for creating canonical names.
  void SerializeCanonicalName(TextBuffer* b, const Object& obj);

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
  FlowGraphSerializer(Zone* zone, const FlowGraph* flow_graph)
      : flow_graph_(ASSERT_NOTNULL(flow_graph)),
        zone_(zone),
        tmp_string_(String::Handle(zone_)),
        closure_context_(Context::Handle(zone_)),
        closure_function_(Function::Handle(zone_)),
        closure_type_args_(TypeArguments::Handle(zone_)),
        code_owner_(Object::Handle(zone_)),
        context_parent_(Context::Handle(zone_)),
        context_elem_(Object::Handle(zone_)),
        function_type_args_(TypeArguments::Handle(zone_)),
        instance_field_(Field::Handle(zone_)),
        instance_type_args_(TypeArguments::Handle(zone_)),
        serialize_library_(Library::Handle(zone_)),
        serialize_owner_(Class::Handle(zone_)),
        serialize_parent_(Function::Handle(zone_)),
        type_arguments_elem_(AbstractType::Handle(zone_)),
        type_class_(Class::Handle(zone_)),
        type_ref_type_(AbstractType::Handle(zone_)) {
    // Double-check that the zone in the flow graph is a parent of the
    // zone we'll be using for serialization.
    ASSERT(flow_graph->zone()->ContainsNestedZone(zone));
  }

  static const char* const initial_indent;

  // Helper methods for the function level that are not used by any
  // instruction serialization methods.
  SExpression* FunctionEntryToSExp(BlockEntryInstr* entry);
  SExpression* EntriesToSExp(GraphEntryInstr* start);
  SExpression* ConstantPoolToSExp(GraphEntryInstr* start);

  const FlowGraph* const flow_graph_;
  Zone* const zone_;

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
  Context& closure_context_;           // ClosureToSExp
  Function& closure_function_;         // ClosureToSExp
  TypeArguments& closure_type_args_;   // ClosureToSExp
  Object& code_owner_;                 // CodeToSExp
  Context& context_parent_;            // ContextToSExp
  Object& context_elem_;               // ContextToSExp
  TypeArguments& function_type_args_;  // FunctionToSExp
  Field& instance_field_;              // InstanceToSExp
  TypeArguments& instance_type_args_;  // InstanceToSExp
  Library& serialize_library_;         // SerializeCanonicalName
  Class& serialize_owner_;             // SerializeCanonicalName
  Function& serialize_parent_;         // SerializeCanonicalName
  AbstractType& type_arguments_elem_;  // TypeArgumentsToSExp
  Class& type_class_;                  // AbstractTypeToSExp
  AbstractType& type_ref_type_;        // AbstractTypeToSExp
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
