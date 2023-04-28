// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <utility>  // For std::move.

#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/compiler/backend/locations.h"

namespace dart {

class AliasIdentity;
class BlockEntryInstr;
class CallTargets;
class CatchBlockEntryInstr;
struct CidRangeValue;
class Cids;
class Code;
class ComparisonInstr;
class CompileType;
class Definition;
class Environment;
class FunctionEntryInstr;
class Instruction;
class FlowGraph;
class GraphEntryInstr;
class Heap;
class IndirectEntryInstr;
class JoinEntryInstr;
class LocalVariable;
class LocationSummary;
class MoveOperands;
class MoveSchedule;
class NonStreamingWriteStream;
class OsrEntryInstr;
class ParsedFunction;
class ParallelMoveInstr;
class PhiInstr;
class Range;
class ReadStream;
class RecordShape;
class TargetEntryInstr;
class TokenPosition;

namespace compiler {
struct TableSelector;

namespace ffi {
class CallbackMarshaller;
class CallMarshaller;
class NativeCallingConvention;
}  // namespace ffi
}  // namespace compiler

// The list of types which are handled by flow graph serializer/deserializer.
// For each type there is a corresponding Write<T>(T) and Read<T>() methods.
//
// This list includes all types of fields of IL instructions
// which are serialized via DECLARE_INSTRUCTION_SERIALIZABLE_FIELDS macro,
// except enum types which are unwrapped with serializable_type_t.
//
// The list is sorted alphabetically by type name.
#define IL_SERIALIZABLE_TYPE_LIST(V)                                           \
  V(AliasIdentity)                                                             \
  V(const AbstractType&)                                                       \
  V(const AbstractType*)                                                       \
  V(const Array&)                                                              \
  V(bool)                                                                      \
  V(const compiler::ffi::CallbackMarshaller&)                                  \
  V(const compiler::ffi::CallMarshaller&)                                      \
  V(const CallTargets&)                                                        \
  V(const char*)                                                               \
  V(CidRangeValue)                                                             \
  V(const Cids&)                                                               \
  V(const Class&)                                                              \
  V(const Code&)                                                               \
  V(ComparisonInstr*)                                                          \
  V(CompileType*)                                                              \
  V(ConstantInstr*)                                                            \
  V(Definition*)                                                               \
  V(double)                                                                    \
  V(Environment*)                                                              \
  V(const Field&)                                                              \
  V(const ICData*)                                                             \
  V(const Instance&)                                                           \
  V(int8_t)                                                                    \
  V(int16_t)                                                                   \
  V(int32_t)                                                                   \
  V(int64_t)                                                                   \
  V(const Function&)                                                           \
  V(const FunctionType&)                                                       \
  V(Instruction*)                                                              \
  V(const LocalVariable&)                                                      \
  V(LocationSummary*)                                                          \
  V(MoveOperands*)                                                             \
  V(const MoveSchedule*)                                                       \
  V(const compiler::ffi::NativeCallingConvention&)                             \
  V(const Object&)                                                             \
  V(ParallelMoveInstr*)                                                        \
  V(PhiInstr*)                                                                 \
  V(Range*)                                                                    \
  V(RecordShape)                                                               \
  V(Representation)                                                            \
  V(const Slot&)                                                               \
  V(const Slot*)                                                               \
  V(const String&)                                                             \
  V(const compiler::TableSelector*)                                            \
  V(TokenPosition)                                                             \
  V(const TypeArguments&)                                                      \
  V(const TypeParameters&)                                                     \
  V(uint8_t)                                                                   \
  V(uint16_t)                                                                  \
  V(uint32_t)                                                                  \
  V(uint64_t)                                                                  \
  V(Value*)

// List of types serializable as references.
#define IL_SERIALIZABLE_REF_TYPE_LIST(V)                                       \
  V(BlockEntryInstr*)                                                          \
  V(CatchBlockEntryInstr*)                                                     \
  V(Definition*)                                                               \
  V(FunctionEntryInstr*)                                                       \
  V(IndirectEntryInstr*)                                                       \
  V(JoinEntryInstr*)                                                           \
  V(OsrEntryInstr*)                                                            \
  V(TargetEntryInstr*)

// Serializes flow graph, including constants and references
// to objects of program structure.
//
// Each IL instruction is serialized in 2 step:
// - the main step (T::WriteTo / T::T()) serializes
//   instruction fields, basically everything required to
//   re-create instruction object.
// - the extra step (T::WriteExtra / T::ReadExtra) serializes
//   references to other instructions, including inputs,
//   environments, locations (may reference constants) and successors.
//
class FlowGraphSerializer : public ValueObject {
 public:
  explicit FlowGraphSerializer(NonStreamingWriteStream* stream);
  ~FlowGraphSerializer();

  // Writes [flow_graph] into the stream.
  // The graph should be compacted via CompactSSA().
  // [detached_defs] should contain all definitions which are
  // detached from the graph but can still be referenced from
  // environments.
  void WriteFlowGraph(const FlowGraph& flow_graph,
                      const ZoneGrowableArray<Definition*>& detached_defs);

  // Implementation of 'Write' method, specialized for a particular type.
  // This struct is used for the partial template instantiations below.
  //
  // Explicit (full) specializations of 'Write' method are not provided as
  // gcc doesn't support explicit template specializations of members of
  // a non-template class
  // (CWG 730 https://cplusplus.github.io/CWG/issues/730.html).
  // The 2nd template argument is used to make all template instantiations
  // partial as gcc doesn't support explicit (full) template specializations
  // in class scope (CWG 727 https://cplusplus.github.io/CWG/issues/727.html).
  template <typename T, class = void>
  struct WriteTrait {
    using ArgType = T;
  };

  template <typename T>
  struct WriteTrait<GrowableArray<T>> {
    using ArgType = const GrowableArray<T>&;
    static void Write(FlowGraphSerializer* s, ArgType x) {
      const intptr_t len = x.length();
      s->Write<intptr_t>(len);
      for (intptr_t i = 0; i < len; ++i) {
        s->Write<T>(x[i]);
      }
    }
  };

  template <typename T>
  struct WriteTrait<const GrowableArray<T>&> {
    using ArgType = const GrowableArray<T>&;
    static void Write(FlowGraphSerializer* s, ArgType x) {
      WriteTrait<GrowableArray<T>>::Write(s, x);
    }
  };

  template <typename T>
  struct WriteTrait<ZoneGrowableArray<T>*> {
    using ArgType = const ZoneGrowableArray<T>*;
    static void Write(FlowGraphSerializer* s, ArgType x) {
      if (x == nullptr) {
        s->Write<intptr_t>(-1);
        return;
      }
      const intptr_t len = x->length();
      s->Write<intptr_t>(len);
      for (intptr_t i = 0; i < len; ++i) {
        s->Write<T>((*x)[i]);
      }
    }
  };

  template <typename T>
  struct WriteTrait<const ZoneGrowableArray<T>&> {
    using ArgType = const ZoneGrowableArray<T>&;
    static void Write(FlowGraphSerializer* s, ArgType x) {
      WriteTrait<ZoneGrowableArray<T>*>::Write(s, &x);
    }
  };

  // Specialization in case intptr_t is not mapped to intN_t.
  template <typename T>
  struct WriteTrait<T,
                    std::enable_if_t<std::is_same_v<intptr_t, T> &&
                                     !std::is_same_v<intptr_t, int32_t> &&
                                     !std::is_same_v<intptr_t, int64_t>>> {
    using ArgType = intptr_t;
    static void Write(FlowGraphSerializer* s, intptr_t x) {
#ifdef ARCH_IS_64_BIT
      s->Write<int64_t>(x);
#else
      s->Write<int32_t>(x);
#endif
    }
  };

  // Specialization in case uintptr_t is not mapped to uintN_t.
  template <typename T>
  struct WriteTrait<T,
                    std::enable_if_t<std::is_same_v<uintptr_t, T> &&
                                     !std::is_same_v<uintptr_t, uint32_t> &&
                                     !std::is_same_v<uintptr_t, uint64_t>>> {
    using ArgType = uintptr_t;
    static void Write(FlowGraphSerializer* s, uintptr_t x) {
#ifdef ARCH_IS_64_BIT
      s->Write<uint64_t>(x);
#else
      s->Write<uint32_t>(x);
#endif
    }
  };

#define DECLARE_WRITE_TRAIT(type)                                              \
  template <typename T>                                                        \
  struct WriteTrait<T, std::enable_if_t<std::is_same_v<type, T>>> {            \
    using ArgType = type;                                                      \
    static void Write(FlowGraphSerializer* s, type x);                         \
  };
  IL_SERIALIZABLE_TYPE_LIST(DECLARE_WRITE_TRAIT)
#undef DECLARE_WRITE_TRAIT

  template <typename T>
  void Write(typename WriteTrait<T>::ArgType x) {
    WriteTrait<T>::Write(this, x);
  }

  // Implementation of 'WriteRef' method, specialized for a particular type.
  // This struct is used for the partial template instantiations below.
  //
  // Explicit (full) specializations of 'WriteRef' method are not provided as
  // gcc doesn't support explicit template specializations of members of
  // a non-template class
  // (CWG 730 https://cplusplus.github.io/CWG/issues/730.html).
  // The 2nd template argument is used to make all template instantiations
  // partial as gcc doesn't support explicit (full) template specializations
  // in class scope (CWG 727 https://cplusplus.github.io/CWG/issues/727.html).
  template <typename T, class = void>
  struct WriteRefTrait {};

#define DECLARE_WRITE_REF_TRAIT(type)                                          \
  template <typename T>                                                        \
  struct WriteRefTrait<T, std::enable_if_t<std::is_same_v<type, T>>> {         \
    static void WriteRef(FlowGraphSerializer* s, T x);                         \
  };
  IL_SERIALIZABLE_REF_TYPE_LIST(DECLARE_WRITE_REF_TRAIT)
#undef DECLARE_WRITE_REF_TRAIT

  template <typename T>
  void WriteRef(T x) {
    WriteRefTrait<T>::WriteRef(this, x);
  }

  template <typename T>
  void WriteGrowableArrayOfRefs(const GrowableArray<T>& array) {
    const intptr_t len = array.length();
    Write<intptr_t>(len);
    for (intptr_t i = 0; i < len; ++i) {
      WriteRef<T>(array[i]);
    }
  }

  BaseWriteStream* stream() const { return stream_; }
  Zone* zone() const { return zone_; }
  Thread* thread() const { return thread_; }
  IsolateGroup* isolate_group() const { return isolate_group_; }
  Heap* heap() const { return heap_; }
  bool can_write_refs() const { return can_write_refs_; }

 private:
  void WriteObjectImpl(const Object& x, intptr_t cid, intptr_t object_index);
  bool IsWritten(const Object& obj);
  bool HasEnclosingTypes(const Object& obj);
  bool WriteObjectWithEnclosingTypes(const Object& type);
  void WriteEnclosingTypes(const Object& type,
                           intptr_t num_free_fun_type_params);

  NonStreamingWriteStream* stream_;
  Zone* zone_;
  Thread* thread_;
  IsolateGroup* isolate_group_;
  Heap* heap_;
  intptr_t object_counter_ = 0;
  bool can_write_refs_ = false;
  intptr_t num_free_fun_type_params_ = kMaxInt;
};

// Deserializes flow graph.
// All constants and types are canonicalized during deserialization.
class FlowGraphDeserializer : public ValueObject {
 public:
  FlowGraphDeserializer(const ParsedFunction& parsed_function,
                        ReadStream* stream);

  const ParsedFunction& parsed_function() const { return parsed_function_; }

  Zone* zone() const { return zone_; }
  ReadStream* stream() const { return stream_; }
  Thread* thread() const { return thread_; }
  IsolateGroup* isolate_group() const { return isolate_group_; }

  GraphEntryInstr* graph_entry() const { return graph_entry_; }
  void set_graph_entry(GraphEntryInstr* entry) { graph_entry_ = entry; }

  BlockEntryInstr* current_block() const { return current_block_; }
  void set_current_block(BlockEntryInstr* block) { current_block_ = block; }

  BlockEntryInstr* block(intptr_t block_id) const {
    BlockEntryInstr* b = blocks_[block_id];
    ASSERT(b != nullptr);
    return b;
  }
  void set_block(intptr_t block_id, BlockEntryInstr* block) {
    ASSERT(blocks_[block_id] == nullptr);
    blocks_[block_id] = block;
  }

  Definition* definition(intptr_t ssa_temp_index) const {
    Definition* def = definitions_[ssa_temp_index];
    ASSERT(def != nullptr);
    return def;
  }
  void set_definition(intptr_t ssa_temp_index, Definition* def) {
    ASSERT(definitions_[ssa_temp_index] == nullptr);
    definitions_[ssa_temp_index] = def;
  }

  FlowGraph* ReadFlowGraph();

  // Implementation of 'Read' method, specialized for a particular type.
  // This struct is used for the partial template instantiations below.
  //
  // Explicit (full) specializations of 'Read' method are not provided as
  // gcc doesn't support explicit template specializations of members of
  // a non-template class
  // (CWG 730 https://cplusplus.github.io/CWG/issues/730.html).
  // The 2nd template argument is used to make all template instantiations
  // partial as gcc doesn't support explicit (full) template specializations
  // in class scope (CWG 727 https://cplusplus.github.io/CWG/issues/727.html).
  template <typename T, class = void>
  struct ReadTrait {};

  template <typename T>
  struct ReadTrait<GrowableArray<T>> {
    static GrowableArray<T> Read(FlowGraphDeserializer* d) {
      const intptr_t len = d->Read<intptr_t>();
      GrowableArray<T> array(len);
      for (int i = 0; i < len; ++i) {
        array.Add(d->Read<T>());
      }
      return array;
    }
  };

  template <typename T>
  struct ReadTrait<const GrowableArray<T>&> {
    static const GrowableArray<T>& Read(FlowGraphDeserializer* d) {
      return ReadTrait<GrowableArray<T>>::Read(d);
    }
  };

  template <typename T>
  struct ReadTrait<ZoneGrowableArray<T>*> {
    static ZoneGrowableArray<T>* Read(FlowGraphDeserializer* d) {
      const intptr_t len = d->Read<intptr_t>();
      if (len < 0) {
        return nullptr;
      }
      auto* array = new (d->zone()) ZoneGrowableArray<T>(d->zone(), len);
      for (int i = 0; i < len; ++i) {
        array->Add(d->Read<T>());
      }
      return array;
    }
  };

  template <typename T>
  struct ReadTrait<const ZoneGrowableArray<T>&> {
    static const ZoneGrowableArray<T>& Read(FlowGraphDeserializer* d) {
      return *ReadTrait<ZoneGrowableArray<T>*>::Read(d);
    }
  };

  // Specialization in case intptr_t is not mapped to intN_t.
  template <typename T>
  struct ReadTrait<T,
                   std::enable_if_t<std::is_same_v<intptr_t, T> &&
                                    !std::is_same_v<intptr_t, int32_t> &&
                                    !std::is_same_v<intptr_t, int64_t>>> {
    static intptr_t Read(FlowGraphDeserializer* d) {
#ifdef ARCH_IS_64_BIT
      return d->Read<int64_t>();
#else
      return d->Read<int32_t>();
#endif
    }
  };

  // Specialization in case uintptr_t is not mapped to uintN_t.
  template <typename T>
  struct ReadTrait<T,
                   std::enable_if_t<std::is_same_v<uintptr_t, T> &&
                                    !std::is_same_v<uintptr_t, uint32_t> &&
                                    !std::is_same_v<uintptr_t, uint64_t>>> {
    static uintptr_t Read(FlowGraphDeserializer* d) {
#ifdef ARCH_IS_64_BIT
      return d->Read<uint64_t>();
#else
      return d->Read<uint32_t>();
#endif
    }
  };

#define DECLARE_READ_TRAIT(type)                                               \
  template <typename T>                                                        \
  struct ReadTrait<T, std::enable_if_t<std::is_same_v<type, T>>> {             \
    static type Read(FlowGraphDeserializer* d);                                \
  };
  IL_SERIALIZABLE_TYPE_LIST(DECLARE_READ_TRAIT)
#undef DECLARE_READ_TRAIT

  template <typename T>
  T Read() {
    return ReadTrait<T>::Read(this);
  }

  // Implementation of 'ReadRef' method, specialized for a particular type.
  // This struct is used for the partial template instantiations below.
  //
  // Explicit (full) specializations of 'ReadRef' method are not provided as
  // gcc doesn't support explicit template specializations of members of
  // a non-template class
  // (CWG 730 https://cplusplus.github.io/CWG/issues/730.html).
  // The 2nd template argument is used to make all template instantiations
  // partial as gcc doesn't support explicit (full) template specializations
  // in class scope (CWG 727 https://cplusplus.github.io/CWG/issues/727.html).
  template <typename T, class = void>
  struct ReadRefTrait {};

#define DECLARE_READ_REF_TRAIT(type)                                           \
  template <typename T>                                                        \
  struct ReadRefTrait<T, std::enable_if_t<std::is_same_v<type, T>>> {          \
    static T ReadRef(FlowGraphDeserializer* d);                                \
  };
  IL_SERIALIZABLE_REF_TYPE_LIST(DECLARE_READ_REF_TRAIT)
#undef DECLARE_READ_REF_TRAIT

  template <typename T>
  T ReadRef() {
    return ReadRefTrait<T>::ReadRef(this);
  }

  template <typename T>
  GrowableArray<T> ReadGrowableArrayOfRefs() {
    const intptr_t len = Read<intptr_t>();
    GrowableArray<T> array(len);
    for (int i = 0; i < len; ++i) {
      array.Add(ReadRef<T>());
    }
    return array;
  }

 private:
  ClassPtr GetClassById(classid_t id) const;
  const Object& ReadObjectImpl(intptr_t cid, intptr_t object_index);
  void SetObjectAt(intptr_t object_index, const Object& object);
  const Object& ReadObjectWithEnclosingTypes();

  const ParsedFunction& parsed_function_;
  ReadStream* stream_;
  Zone* zone_;
  Thread* thread_;
  IsolateGroup* isolate_group_;

  // Deserialized objects.
  GraphEntryInstr* graph_entry_ = nullptr;
  BlockEntryInstr* current_block_ = nullptr;
  GrowableArray<BlockEntryInstr*> blocks_;
  GrowableArray<Definition*> definitions_;
  GrowableArray<const Object*> objects_;
  intptr_t object_counter_ = 0;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_SERIALIZER_H_
