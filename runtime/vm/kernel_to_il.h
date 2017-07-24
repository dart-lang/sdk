// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_TO_IL_H_
#define RUNTIME_VM_KERNEL_TO_IL_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/growable_array.h"
#include "vm/hash_map.h"

#include "vm/flow_graph.h"
#include "vm/flow_graph_builder.h"
#include "vm/intermediate_language.h"

namespace dart {
namespace kernel {

class StreamingFlowGraphBuilder;

class KernelConstMapKeyEqualsTraits {
 public:
  static const char* Name() { return "KernelConstMapKeyEqualsTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    const Smi& key1 = Smi::Cast(a);
    const Smi& key2 = Smi::Cast(b);
    return (key1.Value() == key2.Value());
  }
  static bool IsMatch(const intptr_t key1, const Object& b) {
    return KeyAsSmi(key1) == Smi::Cast(b).raw();
  }
  static uword Hash(const Object& obj) {
    const Smi& key = Smi::Cast(obj);
    return HashValue(key.Value());
  }
  static uword Hash(const intptr_t key) {
    return HashValue(Smi::Value(KeyAsSmi(key)));
  }
  static RawObject* NewKey(const intptr_t key) { return KeyAsSmi(key); }

 private:
  static uword HashValue(intptr_t pos) { return pos % (Smi::kMaxValue - 13); }

  static RawSmi* KeyAsSmi(const intptr_t key) {
    ASSERT(key >= 0);
    return Smi::New(key);
  }
};
typedef UnorderedHashMap<KernelConstMapKeyEqualsTraits> KernelConstantsMap;

template <typename K, typename V>
class Map : public DirectChainedHashMap<RawPointerKeyValueTrait<K, V> > {
 public:
  typedef typename RawPointerKeyValueTrait<K, V>::Key Key;
  typedef typename RawPointerKeyValueTrait<K, V>::Value Value;
  typedef typename RawPointerKeyValueTrait<K, V>::Pair Pair;

  inline void Insert(const Key& key, const Value& value) {
    Pair pair(key, value);
    DirectChainedHashMap<RawPointerKeyValueTrait<K, V> >::Insert(pair);
  }

  inline V Lookup(const Key& key) {
    Pair* pair =
        DirectChainedHashMap<RawPointerKeyValueTrait<K, V> >::Lookup(key);
    if (pair == NULL) {
      return V();
    } else {
      return pair->value;
    }
  }

  inline Pair* LookupPair(const Key& key) {
    return DirectChainedHashMap<RawPointerKeyValueTrait<K, V> >::Lookup(key);
  }
};

template <typename V>
class IntKeyRawPointerValueTrait {
 public:
  typedef intptr_t Key;
  typedef V Value;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(NULL), value() {}
    Pair(const Key key, const Value& value) : key(key), value(value) {}
    Pair(const Pair& other) : key(other.key), value(other.value) {}
  };

  static Key KeyOf(Pair kv) { return kv.key; }
  static Value ValueOf(Pair kv) { return kv.value; }
  static intptr_t Hashcode(Key key) { return key; }
  static bool IsKeyEqual(Pair kv, Key key) { return kv.key == key; }
};

template <typename V>
class IntMap : public DirectChainedHashMap<IntKeyRawPointerValueTrait<V> > {
 public:
  typedef typename IntKeyRawPointerValueTrait<V>::Key Key;
  typedef typename IntKeyRawPointerValueTrait<V>::Value Value;
  typedef typename IntKeyRawPointerValueTrait<V>::Pair Pair;

  inline void Insert(const Key& key, const Value& value) {
    Pair pair(key, value);
    DirectChainedHashMap<IntKeyRawPointerValueTrait<V> >::Insert(pair);
  }

  inline V Lookup(const Key& key) {
    Pair* pair =
        DirectChainedHashMap<IntKeyRawPointerValueTrait<V> >::Lookup(key);
    if (pair == NULL) {
      return V();
    } else {
      return pair->value;
    }
  }

  inline Pair* LookupPair(const Key& key) {
    return DirectChainedHashMap<IntKeyRawPointerValueTrait<V> >::Lookup(key);
  }
};

template <typename K, typename V>
class MallocMap
    : public MallocDirectChainedHashMap<RawPointerKeyValueTrait<K, V> > {
 public:
  typedef typename RawPointerKeyValueTrait<K, V>::Key Key;
  typedef typename RawPointerKeyValueTrait<K, V>::Value Value;
  typedef typename RawPointerKeyValueTrait<K, V>::Pair Pair;

  inline void Insert(const Key& key, const Value& value) {
    Pair pair(key, value);
    MallocDirectChainedHashMap<RawPointerKeyValueTrait<K, V> >::Insert(pair);
  }

  inline V Lookup(const Key& key) {
    Pair* pair =
        MallocDirectChainedHashMap<RawPointerKeyValueTrait<K, V> >::Lookup(key);
    if (pair == NULL) {
      return V();
    } else {
      return pair->value;
    }
  }

  inline Pair* LookupPair(const Key& key) {
    return MallocDirectChainedHashMap<RawPointerKeyValueTrait<K, V> >::Lookup(
        key);
  }
};

class BreakableBlock;
class CatchBlock;
class FlowGraphBuilder;
class SwitchBlock;
class TryCatchBlock;
class TryFinallyBlock;

class Fragment {
 public:
  Instruction* entry;
  Instruction* current;

  Fragment() : entry(NULL), current(NULL) {}

  explicit Fragment(Instruction* instruction)
      : entry(instruction), current(instruction) {}

  Fragment(Instruction* entry, Instruction* current)
      : entry(entry), current(current) {}

  bool is_open() { return entry == NULL || current != NULL; }
  bool is_closed() { return !is_open(); }

  Fragment& operator+=(const Fragment& other);
  Fragment& operator<<=(Instruction* next);

  Fragment closed();
};

Fragment operator+(const Fragment& first, const Fragment& second);
Fragment operator<<(const Fragment& fragment, Instruction* next);

typedef ZoneGrowableArray<PushArgumentInstr*>* ArgumentArray;

class ActiveClass {
 public:
  ActiveClass()
      : kernel_class(NULL),
        class_type_parameters(0),
        class_type_parameters_offset_start(-1),
        klass(NULL),
        member_is_procedure(false),
        member_is_factory_procedure(false),
        member_type_parameters(0),
        member_type_parameters_offset_start(-1) {}

  // The current enclosing kernel class (if available, otherwise NULL).
  Class* kernel_class;
  intptr_t class_type_parameters;
  intptr_t class_type_parameters_offset_start;

  // The current enclosing class (or the library top-level class).  When this is
  // a library's top-level class, the kernel_class will be NULL.
  const dart::Class* klass;

  bool member_is_procedure;
  bool member_is_factory_procedure;
  intptr_t member_type_parameters;
  intptr_t member_type_parameters_offset_start;
};

class ActiveClassScope {
 public:
  ActiveClassScope(ActiveClass* active_class,
                   intptr_t class_type_parameters,
                   intptr_t class_type_parameters_offset_start,
                   const dart::Class* klass)
      : active_class_(active_class), saved_(*active_class) {
    active_class_->kernel_class = NULL;
    active_class_->class_type_parameters = class_type_parameters;
    active_class_->class_type_parameters_offset_start =
        class_type_parameters_offset_start;
    active_class_->klass = klass;
  }

  ~ActiveClassScope() { *active_class_ = saved_; }

 private:
  ActiveClass* active_class_;
  ActiveClass saved_;
};

class ActiveMemberScope {
 public:
  ActiveMemberScope(ActiveClass* active_class,
                    bool member_is_procedure,
                    bool member_is_factory_procedure,
                    intptr_t member_type_parameters,
                    intptr_t member_type_parameters_offset_start)
      : active_class_(active_class), saved_(*active_class) {
    // The class and kernel_class is inherited.
    active_class_->member_is_procedure = member_is_procedure;
    active_class_->member_is_factory_procedure = member_is_factory_procedure;
    active_class_->member_type_parameters = member_type_parameters;
    active_class_->member_type_parameters_offset_start =
        member_type_parameters_offset_start;
  }

  ~ActiveMemberScope() { *active_class_ = saved_; }

 private:
  ActiveClass* active_class_;
  ActiveClass saved_;
};

class TranslationHelper {
 public:
  explicit TranslationHelper(dart::Thread* thread);

  TranslationHelper(dart::Thread* thread,
                    dart::RawTypedData* string_offsets,
                    dart::RawTypedData* string_data,
                    dart::RawTypedData* canonical_names);

  virtual ~TranslationHelper() {}

  Thread* thread() { return thread_; }

  Zone* zone() { return zone_; }

  Isolate* isolate() { return isolate_; }

  Heap::Space allocation_space() { return allocation_space_; }

  // Access to strings.
  const TypedData& string_offsets() { return string_offsets_; }
  void SetStringOffsets(const TypedData& string_offsets);

  const TypedData& string_data() { return string_data_; }
  void SetStringData(const TypedData& string_data);

  const TypedData& canonical_names() { return canonical_names_; }
  void SetCanonicalNames(const TypedData& canonical_names);

  intptr_t StringOffset(StringIndex index) const;
  intptr_t StringSize(StringIndex index) const;
  uint8_t CharacterAt(StringIndex string_index, intptr_t index);
  bool StringEquals(StringIndex string_index, const char* other);

  // Accessors and predicates for canonical names.
  NameIndex CanonicalNameParent(NameIndex name);
  StringIndex CanonicalNameString(NameIndex name);
  bool IsAdministrative(NameIndex name);
  bool IsPrivate(NameIndex name);
  bool IsRoot(NameIndex name);
  bool IsLibrary(NameIndex name);
  bool IsClass(NameIndex name);
  bool IsMember(NameIndex name);
  bool IsField(NameIndex name);
  bool IsConstructor(NameIndex name);
  bool IsProcedure(NameIndex name);
  bool IsMethod(NameIndex name);
  bool IsGetter(NameIndex name);
  bool IsSetter(NameIndex name);
  bool IsFactory(NameIndex name);

  // For a member (field, constructor, or procedure) return the canonical name
  // of the enclosing class or library.
  NameIndex EnclosingName(NameIndex name);

  RawInstance* Canonicalize(const Instance& instance);

  const dart::String& DartString(const char* content) {
    return DartString(content, allocation_space_);
  }
  const dart::String& DartString(const char* content, Heap::Space space);

  dart::String& DartString(StringIndex index) {
    return DartString(index, allocation_space_);
  }
  dart::String& DartString(StringIndex string_index, Heap::Space space);

  dart::String& DartString(const uint8_t* utf8_array, intptr_t len) {
    return DartString(utf8_array, len, allocation_space_);
  }
  dart::String& DartString(const uint8_t* utf8_array,
                           intptr_t len,
                           Heap::Space space);

  const dart::String& DartSymbol(const char* content) const;
  dart::String& DartSymbol(StringIndex string_index) const;
  dart::String& DartSymbol(const uint8_t* utf8_array, intptr_t len) const;

  const dart::String& DartClassName(NameIndex kernel_class);

  const dart::String& DartConstructorName(NameIndex constructor);

  const dart::String& DartProcedureName(NameIndex procedure);

  const dart::String& DartSetterName(NameIndex setter);
  const dart::String& DartSetterName(NameIndex parent, StringIndex setter);

  const dart::String& DartGetterName(NameIndex getter);
  const dart::String& DartGetterName(NameIndex parent, StringIndex getter);

  const dart::String& DartFieldName(NameIndex parent, StringIndex field);

  const dart::String& DartMethodName(NameIndex method);
  const dart::String& DartMethodName(NameIndex parent, StringIndex method);

  const dart::String& DartFactoryName(NameIndex factory);

  // A subclass overrides these when reading in the Kernel program in order to
  // support recursive type expressions (e.g. for "implements X" ...
  // annotations).
  virtual RawLibrary* LookupLibraryByKernelLibrary(NameIndex library);
  virtual RawClass* LookupClassByKernelClass(NameIndex klass);

  RawField* LookupFieldByKernelField(NameIndex field);
  RawFunction* LookupStaticMethodByKernelProcedure(NameIndex procedure);
  RawFunction* LookupConstructorByKernelConstructor(NameIndex constructor);
  dart::RawFunction* LookupConstructorByKernelConstructor(
      const dart::Class& owner,
      NameIndex constructor);

  dart::Type& GetCanonicalType(const dart::Class& klass);

  void ReportError(const char* format, ...);
  void ReportError(const Error& prev_error, const char* format, ...);

 private:
  // This will mangle [name_to_modify] if necessary and make the result a symbol
  // if asked.  The result will be available in [name_to_modify] and it is also
  // returned.  If the name is private, the canonical name [parent] will be used
  // to get the import URI of the library where the name is visible.
  dart::String& ManglePrivateName(NameIndex parent,
                                  dart::String* name_to_modify,
                                  bool symbolize = true);

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;
  Heap::Space allocation_space_;

  TypedData& string_offsets_;
  TypedData& string_data_;
  TypedData& canonical_names_;
};

struct FunctionScope {
  intptr_t kernel_offset;
  LocalScope* scope;
};

class ScopeBuildingResult : public ZoneAllocated {
 public:
  ScopeBuildingResult()
      : this_variable(NULL),
        type_arguments_variable(NULL),
        switch_variable(NULL),
        finally_return_variable(NULL),
        setter_value(NULL),
        yield_jump_variable(NULL),
        yield_context_variable(NULL) {}

  IntMap<LocalVariable*> locals;
  IntMap<LocalScope*> scopes;
  GrowableArray<FunctionScope> function_scopes;

  // Only non-NULL for instance functions.
  LocalVariable* this_variable;

  // Only non-NULL for factory constructor functions.
  LocalVariable* type_arguments_variable;

  // Non-NULL when the function contains a switch statement.
  LocalVariable* switch_variable;

  // Non-NULL when the function contains a return inside a finally block.
  LocalVariable* finally_return_variable;

  // Non-NULL when the function is a setter.
  LocalVariable* setter_value;

  // Non-NULL if the function contains yield statement.
  // TODO(27590) actual variable is called :await_jump_var, we should rename
  // it to reflect the fact that it is used for both await and yield.
  LocalVariable* yield_jump_variable;

  // Non-NULL if the function contains yield statement.
  // TODO(27590) actual variable is called :await_ctx_var, we should rename
  // it to reflect the fact that it is used for both await and yield.
  LocalVariable* yield_context_variable;

  // Variables used in exception handlers, one per exception handler nesting
  // level.
  GrowableArray<LocalVariable*> exception_variables;
  GrowableArray<LocalVariable*> stack_trace_variables;
  GrowableArray<LocalVariable*> catch_context_variables;

  // For-in iterators, one per for-in nesting level.
  GrowableArray<LocalVariable*> iterator_variables;
};

struct YieldContinuation {
  Instruction* entry;
  intptr_t try_index;

  YieldContinuation(Instruction* entry, intptr_t try_index)
      : entry(entry), try_index(try_index) {}

  YieldContinuation()
      : entry(NULL), try_index(CatchClauseNode::kInvalidTryIndex) {}
};

class FlowGraphBuilder {
 public:
  FlowGraphBuilder(intptr_t kernel_offset,
                   ParsedFunction* parsed_function,
                   const ZoneGrowableArray<const ICData*>& ic_data_array,
                   ZoneGrowableArray<intptr_t>* context_level_array,
                   InlineExitCollector* exit_collector,
                   intptr_t osr_id,
                   intptr_t first_block_id = 1);
  virtual ~FlowGraphBuilder();

  FlowGraph* BuildGraph();

 private:
  FlowGraph* BuildGraphOfMethodExtractor(const Function& method);
  FlowGraph* BuildGraphOfNoSuchMethodDispatcher(const Function& function);
  FlowGraph* BuildGraphOfInvokeFieldDispatcher(const Function& function);

  Fragment NativeFunctionBody(intptr_t first_positional_offset,
                              const Function& function);

  TargetEntryInstr* BuildTargetEntry();
  JoinEntryInstr* BuildJoinEntry();
  JoinEntryInstr* BuildJoinEntry(intptr_t try_index);

  ArgumentArray GetArguments(int count);

  Fragment TranslateFinallyFinalizers(TryFinallyBlock* outer_finally,
                                      intptr_t target_context_depth);

  Fragment EnterScope(intptr_t kernel_offset, bool* new_context = NULL);
  Fragment ExitScope(intptr_t kernel_offset);

  Fragment LoadContextAt(int depth);
  Fragment AdjustContextTo(int depth);

  Fragment PushContext(int size);
  Fragment PopContext();

  Fragment LoadInstantiatorTypeArguments();
  Fragment LoadFunctionTypeArguments();
  Fragment InstantiateType(const AbstractType& type);
  Fragment InstantiateTypeArguments(const TypeArguments& type_arguments);
  Fragment TranslateInstantiatedTypeArguments(
      const TypeArguments& type_arguments);

  Fragment AllocateContext(intptr_t size);
  Fragment AllocateObject(TokenPosition position,
                          const dart::Class& klass,
                          intptr_t argument_count);
  Fragment AllocateObject(const dart::Class& klass,
                          const Function& closure_function);
  Fragment BooleanNegate();
  Fragment StrictCompare(Token::Kind kind, bool number_check = false);
  Fragment BranchIfTrue(TargetEntryInstr** then_entry,
                        TargetEntryInstr** otherwise_entry,
                        bool negate = false);
  Fragment BranchIfNull(TargetEntryInstr** then_entry,
                        TargetEntryInstr** otherwise_entry,
                        bool negate = false);
  Fragment BranchIfEqual(TargetEntryInstr** then_entry,
                         TargetEntryInstr** otherwise_entry,
                         bool negate = false);
  Fragment BranchIfStrictEqual(TargetEntryInstr** then_entry,
                               TargetEntryInstr** otherwise_entry);
  Fragment CatchBlockEntry(const Array& handler_types,
                           intptr_t handler_index,
                           bool needs_stacktrace);
  Fragment TryCatch(int try_handler_index);
  Fragment CheckStackOverflowInPrologue();
  Fragment CheckStackOverflow();
  Fragment CloneContext();
  Fragment Constant(const Object& value);
  Fragment CreateArray();
  Fragment Goto(JoinEntryInstr* destination);
  Fragment IntConstant(int64_t value);
  Fragment InstanceCall(TokenPosition position,
                        const dart::String& name,
                        Token::Kind kind,
                        intptr_t argument_count,
                        intptr_t checked_argument_count = 1);
  Fragment InstanceCall(TokenPosition position,
                        const dart::String& name,
                        Token::Kind kind,
                        intptr_t type_args_len,
                        intptr_t argument_count,
                        const Array& argument_names,
                        intptr_t checked_argument_count = 1);
  Fragment ClosureCall(intptr_t type_args_len,
                       intptr_t argument_count,
                       const Array& argument_names);
  Fragment ThrowException(TokenPosition position);
  Fragment RethrowException(TokenPosition position, int catch_try_index);
  Fragment LoadClassId();
  Fragment LoadField(const dart::Field& field);
  Fragment LoadField(intptr_t offset, intptr_t class_id = kDynamicCid);
  Fragment LoadNativeField(MethodRecognizer::Kind kind,
                           intptr_t offset,
                           const Type& type,
                           intptr_t class_id,
                           bool is_immutable = false);
  Fragment LoadLocal(LocalVariable* variable);
  Fragment InitStaticField(const dart::Field& field);
  Fragment LoadStaticField();
  Fragment NullConstant();
  Fragment NativeCall(const dart::String* name, const Function* function);
  Fragment PushArgument();
  Fragment Return(TokenPosition position);
  Fragment StaticCall(TokenPosition position,
                      const Function& target,
                      intptr_t argument_count);
  Fragment StaticCall(TokenPosition position,
                      const Function& target,
                      intptr_t argument_count,
                      const Array& argument_names);
  Fragment StoreIndexed(intptr_t class_id);
  Fragment StoreInstanceFieldGuarded(const dart::Field& field,
                                     bool is_initialization_store);
  Fragment StoreInstanceField(
      const dart::Field& field,
      bool is_initialization_store,
      StoreBarrierType emit_store_barrier = kEmitStoreBarrier);
  Fragment StoreInstanceField(
      TokenPosition position,
      intptr_t offset,
      StoreBarrierType emit_store_barrier = kEmitStoreBarrier);
  Fragment StoreLocal(TokenPosition position, LocalVariable* variable);
  Fragment StoreStaticField(TokenPosition position, const dart::Field& field);
  Fragment StringInterpolate(TokenPosition position);
  Fragment StringInterpolateSingle(TokenPosition position);
  Fragment ThrowTypeError();
  Fragment ThrowNoSuchMethodError();
  Fragment BuildImplicitClosureCreation(const Function& target);
  Fragment GuardFieldLength(const dart::Field& field, intptr_t deopt_id);
  Fragment GuardFieldClass(const dart::Field& field, intptr_t deopt_id);

  Fragment EvaluateAssertion();
  Fragment CheckReturnTypeInCheckedMode();
  Fragment CheckVariableTypeInCheckedMode(const AbstractType& dst_type,
                                          const dart::String& name_symbol);
  Fragment CheckBooleanInCheckedMode();
  Fragment CheckAssignableInCheckedMode(const dart::AbstractType& dst_type,
                                        const dart::String& dst_name);

  Fragment AssertBool();
  Fragment AssertAssignable(const dart::AbstractType& dst_type,
                            const dart::String& dst_name);

  bool NeedsDebugStepCheck(const Function& function, TokenPosition position);
  bool NeedsDebugStepCheck(Value* value, TokenPosition position);
  Fragment DebugStepCheck(TokenPosition position);

  dart::RawFunction* LookupMethodByMember(NameIndex target,
                                          const dart::String& method_name);

  LocalVariable* MakeTemporary();
  LocalVariable* MakeNonTemporary(const dart::String& symbol);

  intptr_t CurrentTryIndex();
  intptr_t AllocateTryIndex() { return next_used_try_index_++; }

  dart::LocalVariable* LookupVariable(VariableDeclaration* var);
  dart::LocalVariable* LookupVariable(intptr_t kernel_offset);

  void SetTempIndex(Definition* definition);

  void Push(Definition* definition);
  Value* Pop();
  Fragment Drop();

  bool IsInlining() { return exit_collector_ != NULL; }

  Token::Kind MethodKind(const dart::String& name);

  void InlineBailout(const char* reason);

  TranslationHelper translation_helper_;
  Thread* thread_;
  Zone* zone_;

  intptr_t kernel_offset_;

  ParsedFunction* parsed_function_;
  intptr_t osr_id_;
  const ZoneGrowableArray<const ICData*>& ic_data_array_;
  // Contains (deopt_id, context_level) pairs.
  ZoneGrowableArray<intptr_t>* context_level_array_;
  InlineExitCollector* exit_collector_;

  intptr_t next_block_id_;
  intptr_t AllocateBlockId() { return next_block_id_++; }

  intptr_t GetNextDeoptId() {
    intptr_t deopt_id = thread_->GetNextDeoptId();
    if (context_level_array_ != NULL) {
      intptr_t level = context_depth_;
      context_level_array_->Add(deopt_id);
      context_level_array_->Add(level);
    }
    return deopt_id;
  }

  intptr_t next_function_id_;
  intptr_t AllocateFunctionId() { return next_function_id_++; }

  intptr_t context_depth_;
  intptr_t loop_depth_;
  intptr_t try_depth_;
  intptr_t catch_depth_;
  intptr_t for_in_depth_;
  Value* stack_;
  intptr_t pending_argument_count_;

  GraphEntryInstr* graph_entry_;

  ScopeBuildingResult* scopes_;

  GrowableArray<YieldContinuation> yield_continuations_;

  LocalVariable* CurrentException() {
    return scopes_->exception_variables[catch_depth_ - 1];
  }
  LocalVariable* CurrentStackTrace() {
    return scopes_->stack_trace_variables[catch_depth_ - 1];
  }
  LocalVariable* CurrentCatchContext() {
    return scopes_->catch_context_variables[try_depth_];
  }

  // A chained list of breakable blocks. Chaining and lookup is done by the
  // [BreakableBlock] class.
  BreakableBlock* breakable_block_;

  // A chained list of switch blocks. Chaining and lookup is done by the
  // [SwitchBlock] class.
  SwitchBlock* switch_block_;

  // A chained list of try-finally blocks. Chaining and lookup is done by the
  // [TryFinallyBlock] class.
  TryFinallyBlock* try_finally_block_;

  // A chained list of try-catch blocks. Chaining and lookup is done by the
  // [TryCatchBlock] class.
  TryCatchBlock* try_catch_block_;
  intptr_t next_used_try_index_;

  // A chained list of catch blocks. Chaining and lookup is done by the
  // [CatchBlock] class.
  CatchBlock* catch_block_;

  ActiveClass active_class_;

  StreamingFlowGraphBuilder* streaming_flow_graph_builder_;

  friend class BreakableBlock;
  friend class CatchBlock;
  friend class ConstantEvaluator;
  friend class StreamingFlowGraphBuilder;
  friend class ScopeBuilder;
  friend class SwitchBlock;
  friend class TryCatchBlock;
  friend class TryFinallyBlock;
};

class SwitchBlock {
 public:
  SwitchBlock(FlowGraphBuilder* builder, intptr_t case_count)
      : builder_(builder),
        outer_(builder->switch_block_),
        outer_finally_(builder->try_finally_block_),
        case_count_(case_count),
        context_depth_(builder->context_depth_),
        try_index_(builder->CurrentTryIndex()) {
    builder_->switch_block_ = this;
    if (outer_ != NULL) {
      depth_ = outer_->depth_ + outer_->case_count_;
    } else {
      depth_ = 0;
    }
  }
  ~SwitchBlock() { builder_->switch_block_ = outer_; }

  bool HadJumper(intptr_t case_num) {
    return destinations_.Lookup(case_num) != NULL;
  }

  // Get destination via absolute target number (i.e. the correct destination
  // is not not necessarily in this block.
  JoinEntryInstr* Destination(intptr_t target_index,
                              TryFinallyBlock** outer_finally = NULL,
                              intptr_t* context_depth = NULL) {
    // Find corresponding [SwitchStatement].
    SwitchBlock* block = this;
    while (block->depth_ > target_index) {
      block = block->outer_;
    }

    // Set the outer finally block.
    if (outer_finally != NULL) {
      *outer_finally = block->outer_finally_;
      *context_depth = block->context_depth_;
    }

    // Ensure there's [JoinEntryInstr] for that [SwitchCase].
    return block->EnsureDestination(target_index - block->depth_);
  }

  // Get destination via relative target number (i.e. relative to this block,
  // 0 is first case in this block etc).
  JoinEntryInstr* DestinationDirect(intptr_t case_num,
                                    TryFinallyBlock** outer_finally = NULL,
                                    intptr_t* context_depth = NULL) {
    // Set the outer finally block.
    if (outer_finally != NULL) {
      *outer_finally = outer_finally_;
      *context_depth = context_depth_;
    }

    // Ensure there's [JoinEntryInstr] for that [SwitchCase].
    return EnsureDestination(case_num);
  }

 private:
  JoinEntryInstr* EnsureDestination(intptr_t case_num) {
    JoinEntryInstr* cached_inst = destinations_.Lookup(case_num);
    if (cached_inst == NULL) {
      JoinEntryInstr* inst = builder_->BuildJoinEntry(try_index_);
      destinations_.Insert(case_num, inst);
      return inst;
    }
    return cached_inst;
  }

  FlowGraphBuilder* builder_;
  SwitchBlock* outer_;

  IntMap<JoinEntryInstr*> destinations_;

  TryFinallyBlock* outer_finally_;
  intptr_t case_count_;
  intptr_t depth_;
  intptr_t context_depth_;
  intptr_t try_index_;
};

class TryCatchBlock {
 public:
  explicit TryCatchBlock(FlowGraphBuilder* builder,
                         intptr_t try_handler_index = -1)
      : builder_(builder),
        outer_(builder->try_catch_block_),
        try_index_(try_handler_index) {
    if (try_index_ == -1) try_index_ = builder->AllocateTryIndex();
    builder->try_catch_block_ = this;
  }
  ~TryCatchBlock() { builder_->try_catch_block_ = outer_; }

  intptr_t try_index() { return try_index_; }
  TryCatchBlock* outer() const { return outer_; }

 private:
  FlowGraphBuilder* builder_;
  TryCatchBlock* outer_;
  intptr_t try_index_;
};

class TryFinallyBlock {
 public:
  TryFinallyBlock(FlowGraphBuilder* builder, intptr_t finalizer_kernel_offset)
      : builder_(builder),
        outer_(builder->try_finally_block_),
        finalizer_kernel_offset_(finalizer_kernel_offset),
        context_depth_(builder->context_depth_),
        // Finalizers are executed outside of the try block hence
        // try depth of finalizers are one less than current try
        // depth.
        try_depth_(builder->try_depth_ - 1),
        try_index_(builder_->CurrentTryIndex()) {
    builder_->try_finally_block_ = this;
  }
  ~TryFinallyBlock() { builder_->try_finally_block_ = outer_; }

  intptr_t finalizer_kernel_offset() const { return finalizer_kernel_offset_; }
  intptr_t context_depth() const { return context_depth_; }
  intptr_t try_depth() const { return try_depth_; }
  intptr_t try_index() const { return try_index_; }
  TryFinallyBlock* outer() const { return outer_; }

 private:
  FlowGraphBuilder* const builder_;
  TryFinallyBlock* const outer_;
  intptr_t finalizer_kernel_offset_;
  const intptr_t context_depth_;
  const intptr_t try_depth_;
  const intptr_t try_index_;
};

class BreakableBlock {
 public:
  explicit BreakableBlock(FlowGraphBuilder* builder)
      : builder_(builder),
        outer_(builder->breakable_block_),
        destination_(NULL),
        outer_finally_(builder->try_finally_block_),
        context_depth_(builder->context_depth_),
        try_index_(builder->CurrentTryIndex()) {
    if (builder_->breakable_block_ == NULL) {
      index_ = 0;
    } else {
      index_ = builder_->breakable_block_->index_ + 1;
    }
    builder_->breakable_block_ = this;
  }
  ~BreakableBlock() { builder_->breakable_block_ = outer_; }

  bool HadJumper() { return destination_ != NULL; }

  JoinEntryInstr* destination() { return destination_; }

  JoinEntryInstr* BreakDestination(intptr_t label_index,
                                   TryFinallyBlock** outer_finally,
                                   intptr_t* context_depth) {
    BreakableBlock* block = builder_->breakable_block_;
    while (block->index_ != label_index) {
      block = block->outer_;
    }
    ASSERT(block != NULL);
    *outer_finally = block->outer_finally_;
    *context_depth = block->context_depth_;
    return block->EnsureDestination();
  }

 private:
  JoinEntryInstr* EnsureDestination() {
    if (destination_ == NULL) {
      destination_ = builder_->BuildJoinEntry(try_index_);
    }
    return destination_;
  }

  FlowGraphBuilder* builder_;
  intptr_t index_;
  BreakableBlock* outer_;
  JoinEntryInstr* destination_;
  TryFinallyBlock* outer_finally_;
  intptr_t context_depth_;
  intptr_t try_index_;
};

class CatchBlock {
 public:
  CatchBlock(FlowGraphBuilder* builder,
             LocalVariable* exception_var,
             LocalVariable* stack_trace_var,
             intptr_t catch_try_index)
      : builder_(builder),
        outer_(builder->catch_block_),
        exception_var_(exception_var),
        stack_trace_var_(stack_trace_var),
        catch_try_index_(catch_try_index) {
    builder_->catch_block_ = this;
  }
  ~CatchBlock() { builder_->catch_block_ = outer_; }

  LocalVariable* exception_var() { return exception_var_; }
  LocalVariable* stack_trace_var() { return stack_trace_var_; }
  intptr_t catch_try_index() { return catch_try_index_; }

 private:
  FlowGraphBuilder* builder_;
  CatchBlock* outer_;
  LocalVariable* exception_var_;
  LocalVariable* stack_trace_var_;
  intptr_t catch_try_index_;
};

RawObject* EvaluateMetadata(const dart::Field& metadata_field);
RawObject* BuildParameterDescriptor(const Function& function);
void CollectTokenPositionsFor(const Script& script);
String& GetSourceFor(const Script& script);
Array& GetLineStartsFor(const Script& script);

}  // namespace kernel
}  // namespace dart

#else  // !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/kernel.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

RawObject* EvaluateMetadata(const dart::Field& metadata_field);
RawObject* BuildParameterDescriptor(const Function& function);

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_TO_IL_H_
