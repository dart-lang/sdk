// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_

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
  static void SerializeToBuffer(const FlowGraph* flow_graph,
                                TextBuffer* buffer);
  static void SerializeToBuffer(Zone* zone,
                                const FlowGraph* flow_graph,
                                TextBuffer* buffer);

  const FlowGraph* flow_graph() const { return flow_graph_; }
  Zone* zone() const { return zone_; }

  SExpression* FunctionToSExp();

  SExpression* BlockIdToSExp(intptr_t block_id);
  SExpression* BlockEntryToSExp(const char* entry_name, BlockEntryInstr* entry);
  SExpression* CanonicalNameToSExp(const Object& obj);
  SExpression* UseToSExp(const Definition* definition);

  void SerializeCanonicalName(TextBuffer* b, const Object& obj);

  // Methods for serializing Dart values.
  SExpression* AbstractTypeToSExp(const AbstractType& typ);
  SExpression* ClassToSExp(const Class& cls);
  SExpression* CodeToSExp(const Code& c);
  SExpression* FieldToSExp(const Field& f);
  SExpression* SlotToSExp(const Slot& s);
  SExpression* TypeArgumentsToSExp(const TypeArguments& ta);
  SExpression* DartValueToSExp(const Object& obj);

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
      : flow_graph_(flow_graph),
        zone_(zone),
        tmp_type_(AbstractType::Handle(zone_)),
        tmp_class_(Class::Handle(zone_)),
        tmp_function_(Function::Handle(zone_)),
        tmp_library_(Library::Handle(zone_)),
        tmp_object_(Object::Handle(zone_)),
        tmp_string_(String::Handle(zone_)) {}

  static const char* const initial_indent;

  void AddConstantPool(SExpList* sexp);
  void AddBlocks(SExpList* sexp);

  const FlowGraph* flow_graph_;
  Zone* zone_;

  // Handles for temporary use.
  AbstractType& tmp_type_;
  Class& tmp_class_;
  Function& tmp_function_;
  Library& tmp_library_;
  Object& tmp_object_;
  String& tmp_string_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
