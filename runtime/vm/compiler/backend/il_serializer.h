// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_

#include "platform/text_buffer.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

class Precompiler;

// Flow graph serialization.
class FlowGraphSerializer : ValueObject {
 public:
  static void SerializeToBuffer(const FlowGraph* flow_graph,
                                TextBuffer* buffer);

  TextBuffer* buffer() const { return buffer_; }

 private:
  FlowGraphSerializer(const FlowGraph* flow_graph, TextBuffer* buffer)
      : flow_graph_(flow_graph),
        buffer_(buffer),
        zone_(flow_graph->zone()),
        tmp_type_(AbstractType::Handle(zone_)),
        tmp_class_(Class::Handle(zone_)),
        tmp_function_(Function::Handle(zone_)),
        tmp_library_(Library::Handle(zone_)),
        tmp_object_(Object::Handle(zone_)),
        tmp_string_(String::Handle(zone_)) {}

  void SerializeFunction();
  void SerializeConstantPool();
  void SerializeBlocks();

  void SerializeBlockId(intptr_t block_id);
  void SerializeBlockEntry(const char* entry_name, BlockEntryInstr* entry);
  void SerializeCanonicalName(const Object& obj);
  void SerializeQuotedString(const char* str);
  void SerializeUse(const Definition* definition);

  template <typename T>
  void OptionallySerializeExtraInfo(const T* obj);

  // Methods for serializing Dart values.
  void SerializeAbstractType(const AbstractType& typ);
  void SerializeClass(const Class& cls);
  void SerializeCode(const Code& c);
  void SerializeField(const Field& f);
  void SerializeSlot(const Slot& s);
  void SerializeTypeArguments(const TypeArguments& ta);
  void SerializeDartValue(const Object& obj);

  void set_buffer(TextBuffer* buffer) { buffer_ = buffer; }

  const FlowGraph* flow_graph() const { return flow_graph_; }

  const FlowGraph* flow_graph_;
  TextBuffer* buffer_;
  Zone* zone_;

  // Handles for temporary use.
  AbstractType& tmp_type_;
  Class& tmp_class_;
  Function& tmp_function_;
  Library& tmp_library_;
  Object& tmp_object_;
  String& tmp_string_;

  friend AllocateObjectInstr;
  friend BlockEntryInstr;
  friend BranchInstr;
  friend CompileType;
  friend ConstantInstr;
  friend Definition;
  friend GotoInstr;
  friend InstanceCallInstr;
  friend Instruction;
  friend LoadFieldInstr;
  friend PolymorphicInstanceCallInstr;
  friend StoreInstanceFieldInstr;
  friend TailCallInstr;
  friend Value;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
