// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_CALL_SPECIALIZER_H_
#define RUNTIME_VM_COMPILER_CALL_SPECIALIZER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <array>

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

// Call specialization pass is responsible for replacing instance calls by
// faster alternatives based on type feedback (JIT), type speculations (AOT),
// locally propagated type information or global type information.
//
// This pass for example can
//
//    * Replace a call to a binary arithmetic operator with corresponding IL
//      instructions and necessary checks;
//    * Replace a dynamic call with a static call, if receiver is known
//      to have a certain class id;
//    * Replace type check with a range check
//
// CallSpecializer is a base class that contains logic shared between
// JIT and AOT compilation pipelines, see JitCallSpecializer for JIT specific
// optimizations and AotCallSpecializer for AOT specific optimizations.
class CallSpecializer : public FlowGraphVisitor {
 public:
  CallSpecializer(FlowGraph* flow_graph, bool should_clone_fields)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        should_clone_fields_(should_clone_fields),
        flow_graph_(flow_graph) {}

  virtual ~CallSpecializer() {}

  FlowGraph* flow_graph() const { return flow_graph_; }

  void set_flow_graph(FlowGraph* flow_graph) {
    flow_graph_ = flow_graph;
    set_block_order(flow_graph->reverse_postorder());
  }

  // Use ICData to optimize, replace or eliminate instructions.
  void ApplyICData();

  // Use propagated class ids to optimize, replace or eliminate instructions.
  void ApplyClassIds();

  virtual void ReplaceInstanceCallsWithDispatchTableCalls();

  void InsertBefore(Instruction* next,
                    Instruction* instr,
                    Environment* env,
                    FlowGraph::UseKind use_kind) {
    flow_graph_->InsertBefore(next, instr, env, use_kind);
  }
  void InsertSpeculativeBefore(Instruction* next,
                               Instruction* instr,
                               Environment* env,
                               FlowGraph::UseKind use_kind) {
    flow_graph_->InsertSpeculativeBefore(next, instr, env, use_kind);
  }

  virtual void VisitStaticCall(StaticCallInstr* instr);

  // TODO(dartbug.com/30633) these methods have nothing to do with
  // specialization of calls. They are here for historical reasons.
  // Find a better place for them.
  virtual void VisitLoadCodeUnits(LoadCodeUnitsInstr* instr);

  struct ExactnessInfo {
    const bool is_exact;
    bool emit_exactness_guard;
  };

 protected:
  Thread* thread() const { return flow_graph_->thread(); }
  IsolateGroup* isolate_group() const { return flow_graph_->isolate_group(); }
  Zone* zone() const { return flow_graph_->zone(); }
  const Function& function() const { return flow_graph_->function(); }

  bool TryReplaceWithBinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithUnaryOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryReplaceWithEqualityOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithRelationalOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryInlineInstanceGetter(InstanceCallInstr* call);
  bool TryInlineInstanceSetter(InstanceCallInstr* call);

  bool TryInlineInstanceMethod(InstanceCallInstr* call);
  void ReplaceWithInstanceOf(InstanceCallInstr* instr);

  // Replaces a call where the replacement code does not end in a
  // value-returning instruction, so we must specify what definition should be
  // used instead to replace uses of the call return value.
  void ReplaceCallWithResult(Definition* call,
                             Instruction* replacement,
                             Definition* result);
  void ReplaceCall(Definition* call, Definition* replacement);

  // Add a class check for the call's first argument (receiver).
  void AddReceiverCheck(InstanceCallInstr* call) {
    AddCheckClass(call->Receiver()->definition(), call->Targets(),
                  call->deopt_id(), call->env(), call);
  }

  // Insert a null check if needed.
  void AddCheckNull(Value* to_check,
                    const String& function_name,
                    intptr_t deopt_id,
                    Environment* deopt_environment,
                    Instruction* insert_before);

  // Attempt to build ICData for call using propagated class-ids.
  virtual bool TryCreateICData(InstanceCallInstr* call);

  virtual bool TryReplaceInstanceOfWithRangeCheck(InstanceCallInstr* call,
                                                  const AbstractType& type);

  virtual bool TryOptimizeStaticCallUsingStaticTypes(StaticCallInstr* call) = 0;

 protected:
  void InlineImplicitInstanceGetter(Definition* call, const Field& field);

  // Insert a check of 'to_check' determined by 'unary_checks'.  If the
  // check fails it will deoptimize to 'deopt_id' using the deoptimization
  // environment 'deopt_environment'.  The check is inserted immediately
  // before 'insert_before'.
  void AddCheckClass(Definition* to_check,
                     const Cids& cids,
                     intptr_t deopt_id,
                     Environment* deopt_environment,
                     Instruction* insert_before);

  const bool should_clone_fields_;

 private:
  bool TypeCheckAsClassEquality(const AbstractType& type, intptr_t* type_cid);

  // Insert a Smi check if needed.
  void AddCheckSmi(Definition* to_check,
                   intptr_t deopt_id,
                   Environment* deopt_environment,
                   Instruction* insert_before);

  // Add a class check for a call's nth argument immediately before the
  // call, using the call's IC data to determine the check, and the call's
  // deopt ID and deoptimization environment if the check fails.
  void AddChecksForArgNr(InstanceCallInstr* call,
                         Definition* argument,
                         int argument_number);

  bool InlineSimdBinaryOp(InstanceCallInstr* call,
                          intptr_t cid,
                          Token::Kind op_kind);

  bool TryInlineImplicitInstanceGetter(InstanceCallInstr* call);

  BoolPtr InstanceOfAsBool(const ICData& ic_data,
                           const AbstractType& type,
                           ZoneGrowableArray<intptr_t>* results) const;

  bool TryOptimizeInstanceOfUsingStaticTypes(InstanceCallInstr* call,
                                             const AbstractType& type);

  bool TryStringLengthOneEquality(InstanceCallInstr* call, Token::Kind op_kind);

  void SpecializePolymorphicInstanceCall(PolymorphicInstanceCallInstr* call);

  // Tries to add cid tests to 'results' so that no deoptimization is
  // necessary for common number-related type tests.  Unconditionally adds an
  // entry for the Smi type to the start of the array.
  static bool SpecializeTestCidsForNumericTypes(
      ZoneGrowableArray<intptr_t>* results,
      const AbstractType& type);

  static bool TryReplaceInstanceCallWithInline(
      FlowGraph* flow_graph,
      ForwardInstructionIterator* iterator,
      InstanceCallInstr* call);

  static bool TryReplaceStaticCallWithInline(
      FlowGraph* flow_graph,
      ForwardInstructionIterator* iterator,
      StaticCallInstr* call);

  static bool TryInlineRecognizedMethod(FlowGraph* flow_graph,
                                        intptr_t receiver_cid,
                                        const Function& target,
                                        Definition* call,
                                        Definition* receiver,
                                        const InstructionSource& source,
                                        const ICData* ic_data,
                                        GraphEntryInstr* graph_entry,
                                        FunctionEntryInstr** entry,
                                        Instruction** last,
                                        Definition** result,
                                        ExactnessInfo* exactness = nullptr);

  FlowGraph* flow_graph_;
};

#define PUBLIC_TYPED_DATA_CLASS_LIST(V)                                        \
  V(Int8List, int_type_, kTypedDataInt8ArrayCid)                               \
  V(Uint8List, int_type_, kTypedDataUint8ArrayCid)                             \
  V(Uint8ClampedList, int_type_, kTypedDataUint8ClampedArrayCid)               \
  V(Int16List, int_type_, kTypedDataInt16ArrayCid)                             \
  V(Uint16List, int_type_, kTypedDataUint16ArrayCid)                           \
  V(Int32List, int_type_, kTypedDataInt32ArrayCid)                             \
  V(Uint32List, int_type_, kTypedDataUint32ArrayCid)                           \
  V(Int64List, int_type_, kTypedDataInt64ArrayCid)                             \
  V(Uint64List, int_type_, kTypedDataUint64ArrayCid)                           \
  V(Float32List, double_type_, kTypedDataFloat32ArrayCid)                      \
  V(Float64List, double_type_, kTypedDataFloat64ArrayCid)                      \
  V(Float32x4List, float32x4_type_, kTypedDataFloat32x4ArrayCid)               \
  V(Int32x4List, int32x4_type_, kTypedDataInt32x4ArrayCid)                     \
  V(Float64x2List, float64x2_type_, kTypedDataFloat64x2ArrayCid)

// Specializes instance/static calls with receiver type being a typed data
// interface (if that interface is only implemented by internal/external/view
// typed data classes).
//
// For example:
//
//    foo(Uint8List bytes) => bytes[0];
//
// Would be translated to something like this:
//
//    v0 <- Constant(0)
//
//    // Ensures the list is non-null.
//    v1 <- ParameterInstr(0)
//    v2 <- CheckNull(v1)
//
//    // Load the length & perform bounds checks
//    v3 <- LoadField(v2, "TypedDataBase.length");
//    v4 <- GenericCheckBounds(v3, v0);
//
//    // Directly access the byte, independent of whether `bytes` is
//    // _Uint8List, _Uint8ArrayView or _ExternalUint8Array.
//    v5 <- LoadField(Slot::PointerBase_data(), v1);
//    v5 <- LoadIndexed(v5, v4)
//
class TypedDataSpecializer : public FlowGraphVisitor {
 public:
  static void Optimize(FlowGraph* flow_graph);

  virtual void VisitInstanceCall(InstanceCallInstr* instr);
  virtual void VisitStaticCall(StaticCallInstr* instr);

 private:
  // clang-format off
  explicit TypedDataSpecializer(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        thread_(Thread::Current()),
        zone_(thread_->zone()),
        flow_graph_(flow_graph),
        int_type_(AbstractType::Handle()),
        double_type_(AbstractType::Handle()),
        float32x4_type_(AbstractType::Handle()),
        int32x4_type_(AbstractType::Handle()),
        float64x2_type_(AbstractType::Handle()),
        implementor_(Class::Handle()) {
  }
  // clang-format on

  void EnsureIsInitialized();
  void TryInlineCall(TemplateDartCall<0>* call);
  void ReplaceWithLengthGetter(TemplateDartCall<0>* call);
  void ReplaceWithIndexGet(TemplateDartCall<0>* call, classid_t cid);
  void ReplaceWithIndexSet(TemplateDartCall<0>* call, classid_t cid);
  void AppendNullCheck(TemplateDartCall<0>* call, Definition** array);
  void AppendMutableCheck(TemplateDartCall<0>* call, Definition** array);
  void AppendBoundsCheck(TemplateDartCall<0>* call,
                         Definition* array,
                         Definition** index);
  Definition* AppendLoadLength(TemplateDartCall<0>* call, Definition* array);
  Definition* AppendLoadIndexed(TemplateDartCall<0>* call,
                                Definition* array,
                                Definition* index,
                                classid_t cid);
  void AppendStoreIndexed(TemplateDartCall<0>* call,
                          Definition* array,
                          Definition* index,
                          Definition* value,
                          classid_t cid);

  Zone* zone() const { return zone_; }

  Thread* thread_;
  Zone* zone_;
  FlowGraph* flow_graph_;
  bool initialized_ = false;

  struct TypedDataVariant {
    AbstractType& array_type = AbstractType::Handle();
    intptr_t array_cid = kIllegalCid;
    AbstractType& element_type = AbstractType::Handle();
  };

  enum {
#define DEFINE_INDEX(iface, type, cid) k##iface##Index,
    PUBLIC_TYPED_DATA_CLASS_LIST(DEFINE_INDEX)
#undef DEFINE_INDEX
        kNumTypedDataVariants
  };

  std::array<TypedDataVariant, kNumTypedDataVariants> typed_data_variants_;

  AbstractType& int_type_;
  AbstractType& double_type_;
  AbstractType& float32x4_type_;
  AbstractType& int32x4_type_;
  AbstractType& float64x2_type_;
  Class& implementor_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_CALL_SPECIALIZER_H_
