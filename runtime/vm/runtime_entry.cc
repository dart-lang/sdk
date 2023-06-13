// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/runtime_entry.h"

#include "platform/memory_sanitizer.h"
#include "platform/thread_sanitizer.h"
#include "vm/code_descriptors.h"
#include "vm/code_patcher.h"
#include "vm/compiler/api/deopt_id.h"
#include "vm/compiler/api/type_check_mode.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/double_conversion.h"
#include "vm/exceptions.h"
#include "vm/ffi_callback_metadata.h"
#include "vm/flags.h"
#include "vm/heap/verifier.h"
#include "vm/instructions.h"
#include "vm/kernel_isolate.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/thread.h"
#include "vm/type_testing_stubs.h"
#include "vm/zone_text_buffer.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/deopt_instructions.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DEFINE_FLAG(
    int,
    max_subtype_cache_entries,
    1000,
    "Maximum number of subtype cache entries (number of checks cached).");
DEFINE_FLAG(
    int,
    regexp_optimization_counter_threshold,
    1000,
    "RegExp's usage-counter value before it is optimized, -1 means never");
DEFINE_FLAG(int,
            reoptimization_counter_threshold,
            4000,
            "Counter threshold before a function gets reoptimized.");
DEFINE_FLAG(bool,
            stress_write_barrier_elimination,
            false,
            "Stress test write barrier elimination.");
DEFINE_FLAG(bool, trace_deoptimization, false, "Trace deoptimization");
DEFINE_FLAG(bool,
            trace_deoptimization_verbose,
            false,
            "Trace deoptimization verbose");

DECLARE_FLAG(int, max_deoptimization_counter_threshold);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, trace_optimizing_compiler);
DECLARE_FLAG(int, max_polymorphic_checks);

DEFINE_FLAG(bool, trace_osr, false, "Trace attempts at on-stack replacement.");

DEFINE_FLAG(int, gc_every, 0, "Run major GC on every N stack overflow checks");
DEFINE_FLAG(int,
            stacktrace_every,
            0,
            "Compute debugger stacktrace on every N stack overflow checks");
DEFINE_FLAG(charp,
            stacktrace_filter,
            nullptr,
            "Compute stacktrace in named function on stack overflow checks");
DEFINE_FLAG(charp,
            deoptimize_filter,
            nullptr,
            "Deoptimize in named function on stack overflow checks");
DEFINE_FLAG(charp,
            deoptimize_on_runtime_call_name_filter,
            nullptr,
            "Runtime call name filter for --deoptimize-on-runtime-call-every.");

DEFINE_FLAG(bool,
            unopt_monomorphic_calls,
            true,
            "Enable specializing monomorphic calls from unoptimized code.");
DEFINE_FLAG(bool,
            unopt_megamorphic_calls,
            true,
            "Enable specializing megamorphic calls from unoptimized code.");
DEFINE_FLAG(bool,
            verbose_stack_overflow,
            false,
            "Print additional details about stack overflow.");

DECLARE_FLAG(int, reload_every);
DECLARE_FLAG(bool, reload_every_optimized);
DECLARE_FLAG(bool, reload_every_back_off);

#if defined(TESTING) || defined(DEBUG)
void VerifyOnTransition() {
  Thread* thread = Thread::Current();
  TransitionGeneratedToVM transition(thread);
  VerifyPointersVisitor::VerifyPointers("VerifyOnTransition");
  thread->isolate_group()->heap()->Verify("VerifyOnTransition");
}
#endif

DEFINE_RUNTIME_ENTRY(RangeError, 2) {
  const Instance& length = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& index = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  if (!length.IsInteger()) {
    // Throw: new ArgumentError.value(length, "length", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, length);
    args.SetAt(1, Symbols::Length());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  if (!index.IsInteger()) {
    // Throw: new ArgumentError.value(index, "index", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, index);
    args.SetAt(1, Symbols::Index());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  // Throw: new RangeError.range(index, 0, length - 1, "length");
  const Array& args = Array::Handle(zone, Array::New(4));
  args.SetAt(0, index);
  args.SetAt(1, Integer::Handle(zone, Integer::New(0)));
  args.SetAt(
      2, Integer::Handle(
             zone, Integer::Cast(length).ArithmeticOp(
                       Token::kSUB, Integer::Handle(zone, Integer::New(1)))));
  args.SetAt(3, Symbols::Length());
  Exceptions::ThrowByType(Exceptions::kRange, args);
}

DEFINE_RUNTIME_ENTRY(WriteError, 0) {
  Exceptions::ThrowUnsupportedError("Cannot modify an unmodifiable list");
}

static void NullErrorHelper(Zone* zone,
                            const String& selector,
                            bool is_param_name = false) {
  if (is_param_name) {
    const String& error = String::Handle(
        selector.IsNull()
            ? String::New("argument value is null")
            : String::NewFormatted("argument value for '%s' is null",
                                   selector.ToCString()));
    Exceptions::ThrowArgumentError(error);
    return;
  }

  // If the selector is null, this must be a null check that wasn't due to a
  // method invocation, so was due to the null check operator.
  if (selector.IsNull()) {
    const Array& args = Array::Handle(zone, Array::New(4));
    args.SetAt(
        3, String::Handle(
               zone, String::New("Null check operator used on a null value")));
    Exceptions::ThrowByType(Exceptions::kType, args);
    return;
  }

  InvocationMirror::Kind kind = InvocationMirror::kMethod;
  if (Field::IsGetterName(selector)) {
    kind = InvocationMirror::kGetter;
  } else if (Field::IsSetterName(selector)) {
    kind = InvocationMirror::kSetter;
  }

  const Smi& invocation_type = Smi::Handle(
      zone,
      Smi::New(InvocationMirror::EncodeType(InvocationMirror::kDynamic, kind)));

  const Array& args = Array::Handle(zone, Array::New(7));
  args.SetAt(0, /* instance */ Object::null_object());
  args.SetAt(1, selector);
  args.SetAt(2, invocation_type);
  args.SetAt(3, /* func_type_args_length */ Object::smi_zero());
  args.SetAt(4, /* func_type_args */ Object::null_object());
  args.SetAt(5, /* func_args */ Object::null_object());
  args.SetAt(6, /* func_arg_names */ Object::null_object());
  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, args);
}

static void DoThrowNullError(Isolate* isolate,
                             Thread* thread,
                             Zone* zone,
                             bool is_param) {
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  const StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  const Code& code = Code::Handle(zone, caller_frame->LookupDartCode());
  const uword pc_offset = caller_frame->pc() - code.PayloadStart();

  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }

  const CodeSourceMap& map =
      CodeSourceMap::Handle(zone, code.code_source_map());
  String& member_name = String::Handle(zone);
  if (!map.IsNull()) {
    CodeSourceMapReader reader(map, Array::null_array(),
                               Function::null_function());
    const intptr_t name_index = reader.GetNullCheckNameIndexAt(pc_offset);
    RELEASE_ASSERT(name_index >= 0);

    const ObjectPool& pool = ObjectPool::Handle(zone, code.GetObjectPool());
    member_name ^= pool.ObjectAt(name_index);
  } else {
    member_name = Symbols::OptimizedOut().ptr();
  }

  NullErrorHelper(zone, member_name, is_param);
}

DEFINE_RUNTIME_ENTRY(NullError, 0) {
  DoThrowNullError(isolate, thread, zone, /*is_param=*/false);
}

// Collects information about pointers within the top |kMaxSlotsCollected|
// slots on the stack.
// TODO(b/179632636) This code is added in attempt to better understand
// b/179632636 and should be removed in the future.
void ReportImpossibleNullError(intptr_t cid,
                               StackFrame* caller_frame,
                               Thread* thread) {
  TextBuffer buffer(512);
  buffer.Printf("hit null error with cid %" Pd ", caller context: ", cid);

  const intptr_t kMaxSlotsCollected = 5;
  const auto slots = reinterpret_cast<ObjectPtr*>(caller_frame->sp());
  const intptr_t num_slots_in_frame =
      reinterpret_cast<ObjectPtr*>(caller_frame->fp()) - slots;
  const auto num_slots_to_collect =
      Utils::Maximum(kMaxSlotsCollected, num_slots_in_frame);
  bool comma = false;
  for (intptr_t i = 0; i < num_slots_to_collect; i++) {
    const ObjectPtr ptr = slots[i];
    buffer.Printf("%s[sp+%" Pd "] %" Pp "", comma ? ", " : "", i,
                  static_cast<uword>(ptr));
    if (ptr->IsHeapObject() &&
        (Dart::vm_isolate_group()->heap()->Contains(
             UntaggedObject::ToAddr(ptr)) ||
         thread->heap()->Contains(UntaggedObject::ToAddr(ptr)))) {
      buffer.Printf("(%" Pp ")", static_cast<uword>(ptr->untag()->tags_));
    }
    comma = true;
  }

  const char* message = buffer.buffer();
  FATAL("%s", message);
}

DEFINE_RUNTIME_ENTRY(DispatchTableNullError, 1) {
  const Smi& cid = Smi::CheckedHandle(zone, arguments.ArgAt(0));
  if (cid.Value() != kNullCid) {
    // We hit null error, but receiver is not null itself. This most likely
    // is a memory corruption. Crash the VM but provide some additional
    // information about the arguments on the stack.
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    RELEASE_ASSERT(caller_frame->IsDartFrame());
    ReportImpossibleNullError(cid.Value(), caller_frame, thread);
  }
  DoThrowNullError(isolate, thread, zone, /*is_param=*/false);
}

DEFINE_RUNTIME_ENTRY(NullErrorWithSelector, 1) {
  const String& selector = String::CheckedHandle(zone, arguments.ArgAt(0));
  NullErrorHelper(zone, selector);
}

DEFINE_RUNTIME_ENTRY(NullCastError, 0) {
  NullErrorHelper(zone, String::null_string());
}

DEFINE_RUNTIME_ENTRY(ArgumentNullError, 0) {
  DoThrowNullError(isolate, thread, zone, /*is_param=*/true);
}

DEFINE_RUNTIME_ENTRY(ArgumentError, 1) {
  const Instance& value = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowArgumentError(value);
}

DEFINE_RUNTIME_ENTRY(ArgumentErrorUnboxedInt64, 0) {
  // Unboxed value is passed through a dedicated slot in Thread.
  int64_t unboxed_value = arguments.thread()->unboxed_int64_runtime_arg();
  const Integer& value = Integer::Handle(zone, Integer::New(unboxed_value));
  Exceptions::ThrowArgumentError(value);
}

DEFINE_RUNTIME_ENTRY(DoubleToInteger, 1) {
  // Unboxed value is passed through a dedicated slot in Thread.
  double val = arguments.thread()->unboxed_double_runtime_arg();
  const Smi& recognized_kind = Smi::CheckedHandle(zone, arguments.ArgAt(0));
  switch (recognized_kind.Value()) {
    case MethodRecognizer::kDoubleToInteger:
      break;
    case MethodRecognizer::kDoubleFloorToInt:
      val = floor(val);
      break;
    case MethodRecognizer::kDoubleCeilToInt:
      val = ceil(val);
      break;
    default:
      UNREACHABLE();
  }
  arguments.SetReturn(Integer::Handle(zone, DoubleToInteger(zone, val)));
}

DEFINE_RUNTIME_ENTRY(IntegerDivisionByZeroException, 0) {
  const Array& args = Array::Handle(zone, Array::New(0));
  Exceptions::ThrowByType(Exceptions::kIntegerDivisionByZeroException, args);
}

static Heap::Space SpaceForRuntimeAllocation() {
  return FLAG_stress_write_barrier_elimination ? Heap::kOld : Heap::kNew;
}

// Allocation of a fixed length array of given element type.
// This runtime entry is never called for allocating a List of a generic type,
// because a prior run time call instantiates the element type if necessary.
// Arg0: array length.
// Arg1: array type arguments, i.e. vector of 1 type, the element type.
// Return value: newly allocated array of length arg0.
DEFINE_RUNTIME_ENTRY(AllocateArray, 2) {
  const Instance& length = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  if (!length.IsInteger()) {
    // Throw: new ArgumentError.value(length, "length", "is not an integer");
    const Array& args = Array::Handle(zone, Array::New(3));
    args.SetAt(0, length);
    args.SetAt(1, Symbols::Length());
    args.SetAt(2, String::Handle(zone, String::New("is not an integer")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, args);
  }
  const int64_t len = Integer::Cast(length).AsInt64Value();
  if (len < 0) {
    // Throw: new RangeError.range(length, 0, Array::kMaxElements, "length");
    Exceptions::ThrowRangeError("length", Integer::Cast(length), 0,
                                Array::kMaxElements);
  }
  if (len > Array::kMaxElements) {
    Exceptions::ThrowOOM();
  }

  const Array& array = Array::Handle(
      zone,
      Array::New(static_cast<intptr_t>(len), SpaceForRuntimeAllocation()));
  arguments.SetReturn(array);
  TypeArguments& element_type =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  // An Array is raw or takes one type argument. However, its type argument
  // vector may be longer than 1 due to a type optimization reusing the type
  // argument vector of the instantiator.
  ASSERT(element_type.IsNull() ||
         (element_type.Length() >= 1 && element_type.IsInstantiated()));
  array.SetTypeArguments(element_type);  // May be null.
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateDouble, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(zone, Double::New(0.0)));
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(BoxDouble, 0) {
  const double val = thread->unboxed_double_runtime_arg();
  arguments.SetReturn(Object::Handle(zone, Double::New(val)));
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(BoxFloat32x4, 0) {
  const auto val = thread->unboxed_simd128_runtime_arg();
  arguments.SetReturn(Object::Handle(zone, Float32x4::New(val)));
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(BoxFloat64x2, 0) {
  const auto val = thread->unboxed_simd128_runtime_arg();
  arguments.SetReturn(Object::Handle(zone, Float64x2::New(val)));
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateMint, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(zone, Integer::New(kMaxInt64)));
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateFloat32x4, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(zone, Float32x4::New(0.0, 0.0, 0.0, 0.0)));
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateFloat64x2, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(zone, Float64x2::New(0.0, 0.0)));
}

DEFINE_RUNTIME_ENTRY_NO_LAZY_DEOPT(AllocateInt32x4, 0) {
  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  arguments.SetReturn(Object::Handle(zone, Int32x4::New(0, 0, 0, 0)));
}

// Allocate typed data array of given class id and length.
// Arg0: class id.
// Arg1: number of elements.
// Return value: newly allocated typed data array.
DEFINE_RUNTIME_ENTRY(AllocateTypedData, 2) {
  const intptr_t cid = Smi::CheckedHandle(zone, arguments.ArgAt(0)).Value();
  const auto& length = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  if (!length.IsInteger()) {
    const Array& args = Array::Handle(zone, Array::New(1));
    args.SetAt(0, length);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  const int64_t len = Integer::Cast(length).AsInt64Value();
  const intptr_t max = TypedData::MaxElements(cid);
  if (len < 0) {
    Exceptions::ThrowRangeError("length", Integer::Cast(length), 0, max);
  } else if (len > max) {
    Exceptions::ThrowOOM();
  }
  const auto& typed_data =
      TypedData::Handle(zone, TypedData::New(cid, static_cast<intptr_t>(len)));
  arguments.SetReturn(typed_data);
}

// Helper returning the token position of the Dart caller.
static TokenPosition GetCallerLocation() {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);
  return caller_frame->GetTokenPos();
}

// Result of an invoke may be an unhandled exception, in which case we
// rethrow it.
static void ThrowIfError(const Object& result) {
  if (!result.IsNull() && result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
}

// Allocate a new object.
// Arg0: class of the object that needs to be allocated.
// Arg1: type arguments of the object that needs to be allocated.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(AllocateObject, 2) {
  const Class& cls = Class::CheckedHandle(zone, arguments.ArgAt(0));
  ASSERT(cls.is_allocate_finalized());
  const Instance& instance = Instance::Handle(
      zone, Instance::NewAlreadyFinalized(cls, SpaceForRuntimeAllocation()));

  arguments.SetReturn(instance);
  if (cls.NumTypeArguments() == 0) {
    // No type arguments required for a non-parameterized type.
    ASSERT(Instance::CheckedHandle(zone, arguments.ArgAt(1)).IsNull());
  } else {
    const auto& type_arguments =
        TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
    // Unless null (for a raw type), the type argument vector may be longer than
    // necessary due to a type optimization reusing the type argument vector of
    // the instantiator.
    ASSERT(type_arguments.IsNull() ||
           (type_arguments.IsInstantiated() &&
            (type_arguments.Length() >= cls.NumTypeArguments())));
    instance.SetTypeArguments(type_arguments);
  }
}

DEFINE_LEAF_RUNTIME_ENTRY(uword /*ObjectPtr*/,
                          EnsureRememberedAndMarkingDeferred,
                          2,
                          uword /*ObjectPtr*/ object_in,
                          Thread* thread) {
  ObjectPtr object = static_cast<ObjectPtr>(object_in);
  // The allocation stubs will call this leaf method for newly allocated
  // old space objects.
  RELEASE_ASSERT(object->IsOldObject());

  // If we eliminate a generational write barriers on allocations of an object
  // we need to ensure it's either a new-space object or it has been added to
  // the remembered set.
  //
  // NOTE: We use reinterpret_cast<>() instead of ::RawCast() to avoid handle
  // allocations in debug mode. Handle allocations in leaf runtimes can cause
  // memory leaks because they will allocate into a handle scope from the next
  // outermost runtime code (to which the generated Dart code might not return
  // in a long time).
  bool add_to_remembered_set = true;
  if (object->untag()->IsRemembered()) {
    // Objects must not be added to the remembered set twice because the
    // scavenger's visitor is not idempotent.
    // Might already be remembered because of type argument store in
    // AllocateArray or any field in CloneContext.
    add_to_remembered_set = false;
  } else if (object->IsArray()) {
    const intptr_t length = Array::LengthOf(static_cast<ArrayPtr>(object));
    add_to_remembered_set =
        compiler::target::WillAllocateNewOrRememberedArray(length);
  } else if (object->IsContext()) {
    const intptr_t num_context_variables =
        Context::NumVariables(static_cast<ContextPtr>(object));
    add_to_remembered_set =
        compiler::target::WillAllocateNewOrRememberedContext(
            num_context_variables);
  }

  if (add_to_remembered_set) {
    object->untag()->EnsureInRememberedSet(thread);
  }

  // For incremental write barrier elimination, we need to ensure that the
  // allocation ends up in the new space or else the object needs to added
  // to deferred marking stack so it will be [re]scanned.
  if (thread->is_marking()) {
    thread->DeferredMarkingStackAddObject(object);
  }

  return static_cast<uword>(object);
}
END_LEAF_RUNTIME_ENTRY

// Instantiate type.
// Arg0: uninstantiated type.
// Arg1: instantiator type arguments.
// Arg2: function type arguments.
// Return value: instantiated type.
DEFINE_RUNTIME_ENTRY(InstantiateType, 3) {
  AbstractType& type = AbstractType::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  ASSERT(!type.IsNull());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsInstantiated());
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsInstantiated());
  type = type.InstantiateFrom(instantiator_type_arguments,
                              function_type_arguments, kAllFree, Heap::kOld);
  ASSERT(!type.IsNull() && type.IsInstantiated());
  arguments.SetReturn(type);
}

// Instantiate type arguments.
// Arg0: uninstantiated type arguments.
// Arg1: instantiator type arguments.
// Arg2: function type arguments.
// Return value: instantiated type arguments.
DEFINE_RUNTIME_ENTRY(InstantiateTypeArguments, 3) {
  TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  ASSERT(!type_arguments.IsNull() && !type_arguments.IsInstantiated());
  ASSERT(instantiator_type_arguments.IsNull() ||
         instantiator_type_arguments.IsInstantiated());
  ASSERT(function_type_arguments.IsNull() ||
         function_type_arguments.IsInstantiated());
  // Code inlined in the caller should have optimized the case where the
  // instantiator can be reused as type argument vector.
  ASSERT(!type_arguments.IsUninstantiatedIdentity());
  type_arguments = type_arguments.InstantiateAndCanonicalizeFrom(
      instantiator_type_arguments, function_type_arguments);
  ASSERT(type_arguments.IsNull() || type_arguments.IsInstantiated());
  arguments.SetReturn(type_arguments);
}

// Helper routine for tracing a subtype check.
static void PrintSubtypeCheck(const AbstractType& subtype,
                              const AbstractType& supertype,
                              const bool result) {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);

  LogBlock lb;
  THR_Print("SubtypeCheck: '%s' %d %s '%s' %d (pc: %#" Px ").\n",
            String::Handle(subtype.Name()).ToCString(), subtype.type_class_id(),
            result ? "is" : "is !",
            String::Handle(supertype.Name()).ToCString(),
            supertype.type_class_id(), caller_frame->pc());

  const Function& function =
      Function::Handle(caller_frame->LookupDartFunction());
  if (function.HasSavedArgumentsDescriptor()) {
    const auto& args_desc_array = Array::Handle(function.saved_args_desc());
    const ArgumentsDescriptor args_desc(args_desc_array);
    THR_Print(" -> Function %s [%s]\n", function.ToFullyQualifiedCString(),
              args_desc.ToCString());
  } else {
    THR_Print(" -> Function %s\n", function.ToFullyQualifiedCString());
  }
}

// Instantiate type.
// Arg0: instantiator type arguments
// Arg1: function type arguments
// Arg2: type to be a subtype of the other
// Arg3: type to be a supertype of the other
// Arg4: variable name of the subtype parameter
// No return value.
DEFINE_RUNTIME_ENTRY(SubtypeCheck, 5) {
  const TypeArguments& instantiator_type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(0));
  const TypeArguments& function_type_args =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(1));
  AbstractType& subtype = AbstractType::CheckedHandle(zone, arguments.ArgAt(2));
  AbstractType& supertype =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(3));
  const String& dst_name = String::CheckedHandle(zone, arguments.ArgAt(4));

  ASSERT(!supertype.IsNull());
  ASSERT(!subtype.IsNull());

  // Now that AssertSubtype may be checking types only available at runtime,
  // we can't guarantee the supertype isn't the top type.
  if (supertype.IsTopTypeForSubtyping()) return;

  // The supertype or subtype may not be instantiated.
  if (AbstractType::InstantiateAndTestSubtype(
          &subtype, &supertype, instantiator_type_args, function_type_args)) {
    if (FLAG_trace_type_checks) {
      // The supertype and subtype are now instantiated. Subtype check passed.
      PrintSubtypeCheck(subtype, supertype, true);
    }
    return;
  }
  if (FLAG_trace_type_checks) {
    // The supertype and subtype are now instantiated. Subtype check failed.
    PrintSubtypeCheck(subtype, supertype, false);
  }

  // Throw a dynamic type error.
  const TokenPosition location = GetCallerLocation();
  Exceptions::CreateAndThrowTypeError(location, subtype, supertype, dst_name);
  UNREACHABLE();
}

// Allocate a new closure and initializes its function and context fields with
// the arguments and all other fields to null.
// Arg0: function.
// Arg1: context.
// Return value: newly allocated closure.
DEFINE_RUNTIME_ENTRY(AllocateClosure, 2) {
  const auto& function = Function::CheckedHandle(zone, arguments.ArgAt(0));
  const auto& context = Context::CheckedHandle(zone, arguments.ArgAt(1));
  const Closure& closure = Closure::Handle(
      zone,
      Closure::New(Object::null_type_arguments(), Object::null_type_arguments(),
                   Object::null_type_arguments(), function, context,
                   SpaceForRuntimeAllocation()));
  arguments.SetReturn(closure);
}

// Allocate a new context large enough to hold the given number of variables.
// Arg0: number of variables.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(AllocateContext, 1) {
  const Smi& num_variables = Smi::CheckedHandle(zone, arguments.ArgAt(0));
  const Context& context = Context::Handle(
      zone, Context::New(num_variables.Value(), SpaceForRuntimeAllocation()));
  arguments.SetReturn(context);
}

// Make a copy of the given context, including the values of the captured
// variables.
// Arg0: the context to be cloned.
// Return value: newly allocated context.
DEFINE_RUNTIME_ENTRY(CloneContext, 1) {
  const Context& ctx = Context::CheckedHandle(zone, arguments.ArgAt(0));
  Context& cloned_ctx = Context::Handle(
      zone, Context::New(ctx.num_variables(), SpaceForRuntimeAllocation()));
  cloned_ctx.set_parent(Context::Handle(zone, ctx.parent()));
  Object& inst = Object::Handle(zone);
  for (int i = 0; i < ctx.num_variables(); i++) {
    inst = ctx.At(i);
    cloned_ctx.SetAt(i, inst);
  }
  arguments.SetReturn(cloned_ctx);
}

// Allocate a new record instance.
// Arg0: record shape id.
// Return value: newly allocated record.
DEFINE_RUNTIME_ENTRY(AllocateRecord, 1) {
  const RecordShape shape(Smi::RawCast(arguments.ArgAt(0)));
  const Record& record =
      Record::Handle(zone, Record::New(shape, SpaceForRuntimeAllocation()));
  arguments.SetReturn(record);
}

// Allocate a new small record instance and initialize its fields.
// Arg0: record shape id.
// Arg1-Arg3: field values.
// Return value: newly allocated record.
DEFINE_RUNTIME_ENTRY(AllocateSmallRecord, 4) {
  const RecordShape shape(Smi::RawCast(arguments.ArgAt(0)));
  const auto& value0 = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const auto& value1 = Instance::CheckedHandle(zone, arguments.ArgAt(2));
  const auto& value2 = Instance::CheckedHandle(zone, arguments.ArgAt(3));
  const Record& record =
      Record::Handle(zone, Record::New(shape, SpaceForRuntimeAllocation()));
  const intptr_t num_fields = shape.num_fields();
  ASSERT(num_fields == 2 || num_fields == 3);
  record.SetFieldAt(0, value0);
  record.SetFieldAt(1, value1);
  if (num_fields > 2) {
    record.SetFieldAt(2, value2);
  }
  arguments.SetReturn(record);
}

// Allocate a SuspendState object.
// Arg0: frame size.
// Arg1: existing SuspendState object or function data.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(AllocateSuspendState, 2) {
  const intptr_t frame_size =
      Smi::CheckedHandle(zone, arguments.ArgAt(0)).Value();
  const Object& previous_state = Object::Handle(zone, arguments.ArgAt(1));
  SuspendState& result = SuspendState::Handle(zone);
  if (previous_state.IsSuspendState()) {
    const auto& suspend_state = SuspendState::Cast(previous_state);
    const auto& function_data =
        Instance::Handle(zone, suspend_state.function_data());
    ObjectStore* object_store = thread->isolate_group()->object_store();
    if (function_data.GetClassId() ==
        Class::Handle(zone, object_store->async_star_stream_controller())
            .id()) {
      // Reset _AsyncStarStreamController.asyncStarBody to null in order
      // to create a new callback closure during next yield.
      // The new callback closure will capture the reallocated SuspendState.
      function_data.SetField(
          Field::Handle(
              zone,
              object_store->async_star_stream_controller_async_star_body()),
          Object::null_object());
    }
    result = SuspendState::New(frame_size, function_data,
                               SpaceForRuntimeAllocation());
    if (function_data.GetClassId() ==
        Class::Handle(zone, object_store->sync_star_iterator_class()).id()) {
      // Refresh _SyncStarIterator._state with the new SuspendState object.
      function_data.SetField(
          Field::Handle(zone, object_store->sync_star_iterator_state()),
          result);
    }
  } else {
    result = SuspendState::New(frame_size, Instance::Cast(previous_state),
                               SpaceForRuntimeAllocation());
  }
  arguments.SetReturn(result);
}

// Makes a copy of the given SuspendState object, including the payload frame.
// Arg0: the SuspendState object to be cloned.
// Return value: newly allocated object.
DEFINE_RUNTIME_ENTRY(CloneSuspendState, 1) {
  const SuspendState& src =
      SuspendState::CheckedHandle(zone, arguments.ArgAt(0));
  const SuspendState& dst = SuspendState::Handle(
      zone, SuspendState::Clone(thread, src, SpaceForRuntimeAllocation()));
  arguments.SetReturn(dst);
}

// Helper routine for tracing a type check.
static void PrintTypeCheck(const char* message,
                           const Instance& instance,
                           const AbstractType& type,
                           const TypeArguments& instantiator_type_arguments,
                           const TypeArguments& function_type_arguments,
                           const Bool& result) {
  DartFrameIterator iterator(Thread::Current(),
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);

  const AbstractType& instance_type =
      AbstractType::Handle(instance.GetType(Heap::kNew));
  ASSERT(instance_type.IsInstantiated() ||
         (instance.IsClosure() && instance_type.IsInstantiated(kCurrentClass)));
  LogBlock lb;
  if (type.IsInstantiated()) {
    THR_Print("%s: '%s' %d %s '%s' %d (pc: %#" Px ").\n", message,
              String::Handle(instance_type.Name()).ToCString(),
              instance_type.type_class_id(),
              (result.ptr() == Bool::True().ptr()) ? "is" : "is !",
              String::Handle(type.Name()).ToCString(), type.type_class_id(),
              caller_frame->pc());
  } else {
    // Instantiate type before printing.
    const AbstractType& instantiated_type = AbstractType::Handle(
        type.InstantiateFrom(instantiator_type_arguments,
                             function_type_arguments, kAllFree, Heap::kOld));
    THR_Print("%s: '%s' %s '%s' instantiated from '%s' (pc: %#" Px ").\n",
              message, String::Handle(instance_type.Name()).ToCString(),
              (result.ptr() == Bool::True().ptr()) ? "is" : "is !",
              String::Handle(instantiated_type.Name()).ToCString(),
              String::Handle(type.Name()).ToCString(), caller_frame->pc());
  }
  const Function& function =
      Function::Handle(caller_frame->LookupDartFunction());
  if (function.HasSavedArgumentsDescriptor()) {
    const auto& args_desc_array = Array::Handle(function.saved_args_desc());
    const ArgumentsDescriptor args_desc(args_desc_array);
    THR_Print(" -> Function %s [%s]\n", function.ToFullyQualifiedCString(),
              args_desc.ToCString());
  } else {
    THR_Print(" -> Function %s\n", function.ToFullyQualifiedCString());
  }
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
// A local flag used only in type_testing_stubs_test.cc that, when true, causes
// a failure when a STC entry for the given arguments already exists. Used to
// check that the SubtypeNTestCache stubs found the cache entry instead of
// calling the runtime.
bool TESTING_runtime_fail_on_existing_STC_entry = false;
#endif

// Checks for false negatives in the SubtypeNTestCache stubs and returns the
// result found if any, otherwise null.
static BoolPtr ResultForExistingTypeTestCacheEntry(
    Zone* zone,
    Thread* thread,
    const Instance& instance,
    const AbstractType& destination_type,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const SubtypeTestCache& cache) {
  ASSERT(destination_type.IsCanonical());
  ASSERT(instantiator_type_arguments.IsCanonical());
  ASSERT(function_type_arguments.IsCanonical());
  if (cache.IsNull()) return Bool::null();
  // Record instances are not added to the cache as they don't have a valid
  // key (type of a record depends on types of all its fields).
  if (instance.IsRecord()) return Bool::null();
  Class& instance_class = Class::Handle(zone);
  if (instance.IsSmi()) {
    instance_class = Smi::Class();
  } else {
    instance_class = instance.clazz();
  }
  // If the type is uninstantiated and refers to parent function type
  // parameters, the function_type_arguments have been canonicalized
  // when concatenated.
  auto& instance_class_id_or_signature = Object::Handle(zone);
  auto& instance_type_arguments = TypeArguments::Handle(zone);
  auto& instance_parent_function_type_arguments = TypeArguments::Handle(zone);
  auto& instance_delayed_type_arguments = TypeArguments::Handle(zone);
  if (instance_class.IsClosureClass()) {
    const auto& closure = Closure::Cast(instance);
    const auto& function = Function::Handle(zone, closure.function());
    instance_class_id_or_signature = function.signature();
    ASSERT(instance_class_id_or_signature.IsFunctionType());
    instance_type_arguments = closure.instantiator_type_arguments();
    instance_parent_function_type_arguments = closure.function_type_arguments();
    instance_delayed_type_arguments = closure.delayed_type_arguments();
    ASSERT(instance_class_id_or_signature.IsCanonical());
    ASSERT(instance_type_arguments.IsCanonical());
    ASSERT(instance_parent_function_type_arguments.IsCanonical());
    ASSERT(instance_delayed_type_arguments.IsCanonical());
  } else {
    instance_class_id_or_signature = Smi::New(instance_class.id());
    if (instance_class.NumTypeArguments() > 0) {
      instance_type_arguments = instance.GetTypeArguments();
      ASSERT(instance_type_arguments.IsCanonical());
    }
  }

  intptr_t index = -1;
  auto& result = Bool::Handle(zone);
  if (cache.HasCheck(instance_class_id_or_signature, destination_type,
                     instance_type_arguments, instantiator_type_arguments,
                     function_type_arguments,
                     instance_parent_function_type_arguments,
                     instance_delayed_type_arguments, &index, &result)) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    if (TESTING_runtime_fail_on_existing_STC_entry) {
      SafepointMutexLocker ml(
          thread->isolate_group()->subtype_test_cache_mutex());
      ZoneTextBuffer buffer(zone);
      buffer.Printf("For\n");
      buffer.Printf("  * instance cid or signature %s\n",
                    instance_class_id_or_signature.ToCString());
      buffer.Printf("  * destination type %s\n", destination_type.ToCString());
      buffer.Printf("  * instance type arguments: %s (hash: %" Pu ")\n",
                    instance_type_arguments.ToCString(),
                    instance_type_arguments.Hash());
      buffer.Printf("  * instantiator type arguments: %s (hash: %" Pu ")\n",
                    instantiator_type_arguments.ToCString(),
                    instantiator_type_arguments.Hash());
      buffer.Printf("  * function type arguments: %s (hash: %" Pu ")\n",
                    function_type_arguments.ToCString(),
                    function_type_arguments.Hash());
      buffer.Printf(
          "  * instance parent function type arguments: %s (hash: %" Pu ")\n",
          instance_parent_function_type_arguments.ToCString(),
          instance_parent_function_type_arguments.Hash());
      buffer.Printf("  * instance delayed type arguments: %s (hash: %" Pu ")\n",
                    instance_delayed_type_arguments.ToCString(),
                    instance_delayed_type_arguments.Hash());
      buffer.AddString("  * cache: ");
      cache.WriteToBuffer(zone, &buffer, "    ");
      buffer.AddString("\n");
      buffer.Printf("  * number of occupied entries in cache: %" Pd "\n",
                    cache.NumberOfChecks());
      buffer.Printf("  * number of available entries in cache: %" Pd "\n",
                    cache.NumEntries());
      buffer.Printf("expected to find entry with result %s at index %" Pd
                    " of cache in stub, but reached runtime",
                    result.value() ? "true" : "false", index);
      FATAL("%s", buffer.buffer());
    }
#endif
    return result.ptr();
  }

  return Bool::null();
}

// This updates the type test cache, an array containing 8 elements:
// - instance class (or function if the instance is a closure)
// - instance type arguments (null if the instance class is not generic)
// - instantiator type arguments (null if the type is instantiated)
// - function type arguments (null if the type is instantiated)
// - instance parent function type arguments (null if instance is not a closure)
// - instance delayed type arguments (null if instance is not a closure)
// - destination type (null if the type was known at compile time)
// - test result
// It can be applied to classes with type arguments in which case it contains
// just the result of the class subtype test, not including the evaluation of
// type arguments.
// This operation is currently very slow (lookup of code is not efficient yet).
static void UpdateTypeTestCache(
    Zone* zone,
    Thread* thread,
    const Instance& instance,
    const AbstractType& destination_type,
    const TypeArguments& instantiator_type_arguments,
    const TypeArguments& function_type_arguments,
    const Bool& result,
    const SubtypeTestCache& new_cache) {
  ASSERT(!new_cache.IsNull());
  ASSERT(destination_type.IsCanonical());
  ASSERT(instantiator_type_arguments.IsCanonical());
  ASSERT(function_type_arguments.IsCanonical());
  if (instance.IsRecord()) {
    // Do not add record instances to cache as they don't have a valid
    // key (type of a record depends on types of all its fields).
    if (FLAG_trace_type_checks) {
      THR_Print("Not updating subtype test cache for the record instance.\n");
    }
    return;
  }
  Class& instance_class = Class::Handle(zone);
  if (instance.IsSmi()) {
    instance_class = Smi::Class();
  } else {
    instance_class = instance.clazz();
  }
  // If the type is uninstantiated and refers to parent function type
  // parameters, the function_type_arguments have been canonicalized
  // when concatenated.
  auto& instance_class_id_or_signature = Object::Handle(zone);
  auto& instance_type_arguments = TypeArguments::Handle(zone);
  auto& instance_parent_function_type_arguments = TypeArguments::Handle(zone);
  auto& instance_delayed_type_arguments = TypeArguments::Handle(zone);
  if (instance_class.IsClosureClass()) {
    const auto& closure = Closure::Cast(instance);
    const auto& function = Function::Handle(zone, closure.function());
    instance_class_id_or_signature = function.signature();
    ASSERT(instance_class_id_or_signature.IsFunctionType());
    instance_type_arguments = closure.instantiator_type_arguments();
    instance_parent_function_type_arguments = closure.function_type_arguments();
    instance_delayed_type_arguments = closure.delayed_type_arguments();
    ASSERT(instance_class_id_or_signature.IsCanonical());
    ASSERT(instance_type_arguments.IsCanonical());
    ASSERT(instance_parent_function_type_arguments.IsCanonical());
    ASSERT(instance_delayed_type_arguments.IsCanonical());
  } else {
    instance_class_id_or_signature = Smi::New(instance_class.id());
    if (instance_class.NumTypeArguments() > 0) {
      instance_type_arguments = instance.GetTypeArguments();
      ASSERT(instance_type_arguments.IsCanonical());
    }
  }
  if (FLAG_trace_type_checks) {
    const auto& instance_class_name =
        String::Handle(zone, instance_class.Name());
    TextBuffer buffer(256);
    buffer.Printf("  Updating test cache %#" Px " with result %s for:\n",
                  static_cast<uword>(new_cache.ptr()), result.ToCString());
    if (instance.IsString()) {
      buffer.Printf("    instance: '%s'\n", instance.ToCString());
    } else {
      buffer.Printf("    instance: %s\n", instance.ToCString());
    }
    buffer.Printf("    class: %s (%" Pd ")\n", instance_class_name.ToCString(),
                  instance_class.id());
    buffer.Printf(
        "    raw entry: [ %#" Px ", %#" Px ", %#" Px ", %#" Px ", %#" Px
        ", %#" Px ", %#" Px ", %#" Px " ]\n",
        static_cast<uword>(instance_class_id_or_signature.ptr()),
        static_cast<uword>(destination_type.ptr()),
        static_cast<uword>(instance_type_arguments.ptr()),
        static_cast<uword>(instantiator_type_arguments.ptr()),
        static_cast<uword>(function_type_arguments.ptr()),
        static_cast<uword>(instance_parent_function_type_arguments.ptr()),
        static_cast<uword>(instance_delayed_type_arguments.ptr()),
        static_cast<uword>(result.ptr()));
    THR_Print("%s", buffer.buffer());
  }
  {
    SafepointMutexLocker ml(
        thread->isolate_group()->subtype_test_cache_mutex());
    const intptr_t len = new_cache.NumberOfChecks();
    if (len >= FLAG_max_subtype_cache_entries) {
      if (FLAG_trace_type_checks) {
        THR_Print("Not updating subtype test cache as its length reached %d\n",
                  FLAG_max_subtype_cache_entries);
      }
      return;
    }
    intptr_t colliding_index = -1;
    auto& old_result = Bool::Handle(zone);
    if (new_cache.HasCheck(
            instance_class_id_or_signature, destination_type,
            instance_type_arguments, instantiator_type_arguments,
            function_type_arguments, instance_parent_function_type_arguments,
            instance_delayed_type_arguments, &colliding_index, &old_result)) {
      if (FLAG_trace_type_checks) {
        TextBuffer buffer(256);
        buffer.Printf("  Collision for test cache %#" Px " at index %" Pd ":\n",
                      static_cast<uword>(new_cache.ptr()), colliding_index);
        buffer.Printf("    entry: ");
        new_cache.WriteEntryToBuffer(zone, &buffer, colliding_index, "      ");
        THR_Print("%s\n", buffer.buffer());
      }
      if (old_result.ptr() != result.ptr()) {
        FATAL("Existing subtype test cache entry has result %s, not %s",
              old_result.ToCString(), result.ToCString());
      }
      // Some other isolate might have updated the cache between entry was
      // found missing and now.
      return;
    }
    const intptr_t new_index = new_cache.AddCheck(
        instance_class_id_or_signature, destination_type,
        instance_type_arguments, instantiator_type_arguments,
        function_type_arguments, instance_parent_function_type_arguments,
        instance_delayed_type_arguments, result);
    if (FLAG_trace_type_checks) {
      TextBuffer buffer(256);
      buffer.Printf("  Added new entry to test cache %#" Px " at index %" Pd
                    ":\n",
                    static_cast<uword>(new_cache.ptr()), new_index);
      buffer.Printf("    new entry: ");
      new_cache.WriteEntryToBuffer(zone, &buffer, new_index, "      ");
      THR_Print("%s\n", buffer.buffer());
    }
  }
}

// Check that the given instance is an instance of the given type.
// Tested instance may be null, because a null test cannot always be inlined,
// e.g 'null is T' yields true if T = Null, but false if T = bool.
// Arg0: instance being checked.
// Arg1: type.
// Arg2: type arguments of the instantiator of the type.
// Arg3: type arguments of the function of the type.
// Arg4: SubtypeTestCache.
// Return value: true or false.
DEFINE_RUNTIME_ENTRY(Instanceof, 5) {
  const Instance& instance = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const AbstractType& type =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(3));
  const SubtypeTestCache& cache =
      SubtypeTestCache::CheckedHandle(zone, arguments.ArgAt(4));
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsDynamicType());  // No need to check assignment.
  ASSERT(!cache.IsNull());
  const Bool& result = Bool::Get(instance.IsInstanceOf(
      type, instantiator_type_arguments, function_type_arguments));
  if (FLAG_trace_type_checks) {
    PrintTypeCheck("InstanceOf", instance, type, instantiator_type_arguments,
                   function_type_arguments, result);
  }
  UpdateTypeTestCache(zone, thread, instance, type, instantiator_type_arguments,
                      function_type_arguments, result, cache);
  arguments.SetReturn(result);
}

// Check that the type of the given instance is a subtype of the given type and
// can therefore be assigned.
// Tested instance may not be null, because a null test is always inlined.
// Arg0: instance being assigned.
// Arg1: type being assigned to.
// Arg2: type arguments of the instantiator of the type being assigned to.
// Arg3: type arguments of the function of the type being assigned to.
// Arg4: name of variable being assigned to.
// Arg5: SubtypeTestCache.
// Arg6: invocation mode (see TypeCheckMode)
// Return value: instance if a subtype, otherwise throw a TypeError.
DEFINE_RUNTIME_ENTRY(TypeCheck, 7) {
  const Instance& src_instance =
      Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const AbstractType& dst_type =
      AbstractType::CheckedHandle(zone, arguments.ArgAt(1));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(2));
  const TypeArguments& function_type_arguments =
      TypeArguments::CheckedHandle(zone, arguments.ArgAt(3));
  String& dst_name = String::Handle(zone);
  dst_name ^= arguments.ArgAt(4);
  ASSERT(dst_name.IsNull() || dst_name.IsString());

  SubtypeTestCache& cache = SubtypeTestCache::Handle(zone);
  cache ^= arguments.ArgAt(5);
  ASSERT(cache.IsNull() || cache.IsSubtypeTestCache());

  const TypeCheckMode mode = static_cast<TypeCheckMode>(
      Smi::CheckedHandle(zone, arguments.ArgAt(6)).Value());

  // Handle cases where currently the SubtypeNTestCache stubs return a false
  // negative and the information is already in the cache.
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  bool check_false_negatives = TESTING_runtime_fail_on_existing_STC_entry;
#else
  bool check_false_negatives = false;
#endif
  // TODO(sstrickl): Remove the hash-based cache case when the stubs have been
  // updated to handle hash-based caches (the only non-testing use case).
  check_false_negatives |= cache.IsHash();
  if (check_false_negatives) {
    const auto& result = Bool::Handle(
        zone, ResultForExistingTypeTestCacheEntry(
                  zone, thread, src_instance, dst_type,
                  instantiator_type_arguments, function_type_arguments, cache));
    if (!result.IsNull() && result.value()) {
      // Early exit because a positive entry already exists in the cache.
      // (Negative entries should fall through to generating an exception.)
      arguments.SetReturn(src_instance);
      return;
    }
  }

#if defined(TARGET_ARCH_IA32)
  ASSERT(mode == kTypeCheckFromInline);
#endif

  // These are guaranteed on the calling side.
  ASSERT(!dst_type.IsDynamicType());
  ASSERT(!src_instance.IsNull() ||
         isolate->group()->use_strict_null_safety_checks());

  const bool is_instance_of = src_instance.IsAssignableTo(
      dst_type, instantiator_type_arguments, function_type_arguments);

  if (FLAG_trace_type_checks) {
    PrintTypeCheck("TypeCheck", src_instance, dst_type,
                   instantiator_type_arguments, function_type_arguments,
                   Bool::Get(is_instance_of));
  }
  if (!is_instance_of) {
    if (dst_name.IsNull()) {
#if !defined(TARGET_ARCH_IA32)
      // Can only come here from type testing stub.
      ASSERT(mode != kTypeCheckFromInline);

      // Grab the [dst_name] from the pool.  It's stored at one pool slot after
      // the subtype-test-cache.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      const Code& caller_code =
          Code::Handle(zone, caller_frame->LookupDartCode());
      const ObjectPool& pool =
          ObjectPool::Handle(zone, caller_code.GetObjectPool());
      TypeTestingStubCallPattern tts_pattern(caller_frame->pc());
      const intptr_t stc_pool_idx = tts_pattern.GetSubtypeTestCachePoolIndex();
      const intptr_t dst_name_idx = stc_pool_idx + 1;
      dst_name ^= pool.ObjectAt(dst_name_idx);
#else
      UNREACHABLE();
#endif
    }

    if (dst_name.ptr() ==
        Symbols::dynamic_assert_assignable_stc_check().ptr()) {
#if !defined(TARGET_ARCH_IA32)
      // Can only come here from type testing stub via dynamic AssertAssignable.
      ASSERT(mode != kTypeCheckFromInline);
#endif
      // This was a dynamic closure call where the destination name was not
      // known at compile-time. Thus, fetch the original arguments and arguments
      // descriptor and re-do the type check  in the runtime, which causes the
      // error with the proper destination name to be thrown.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      const auto& dispatcher =
          Function::Handle(zone, caller_frame->LookupDartFunction());
      ASSERT(dispatcher.IsInvokeFieldDispatcher());
      const auto& orig_arguments_desc =
          Array::Handle(zone, dispatcher.saved_args_desc());
      const ArgumentsDescriptor args_desc(orig_arguments_desc);
      const intptr_t arg_count = args_desc.CountWithTypeArgs();
      const auto& orig_arguments = Array::Handle(zone, Array::New(arg_count));
      auto& obj = Object::Handle(zone);
      for (intptr_t i = 0; i < arg_count; i++) {
        obj = *reinterpret_cast<ObjectPtr*>(
            ParamAddress(caller_frame->fp(), arg_count - i));
        orig_arguments.SetAt(i, obj);
      }
      const auto& receiver = Closure::CheckedHandle(
          zone, orig_arguments.At(args_desc.FirstArgIndex()));
      const auto& function = Function::Handle(zone, receiver.function());
      const auto& result = Object::Handle(
          zone, function.DoArgumentTypesMatch(orig_arguments, args_desc));
      if (result.IsError()) {
        Exceptions::PropagateError(Error::Cast(result));
      }
      // IsAssignableTo returned false, so we should have thrown a type
      // error in DoArgumentsTypesMatch.
      UNREACHABLE();
    }

    ASSERT(!dst_name.IsNull());
    // Throw a dynamic type error.
    const TokenPosition location = GetCallerLocation();
    const auto& src_type =
        AbstractType::Handle(zone, src_instance.GetType(Heap::kNew));
    auto& reported_type = AbstractType::Handle(zone, dst_type.ptr());
    if (!reported_type.IsInstantiated()) {
      // Instantiate dst_type before reporting the error.
      reported_type = reported_type.InstantiateFrom(instantiator_type_arguments,
                                                    function_type_arguments,
                                                    kAllFree, Heap::kNew);
    }
    Exceptions::CreateAndThrowTypeError(location, src_type, reported_type,
                                        dst_name);
    UNREACHABLE();
  }

  bool should_update_cache = true;
#if !defined(TARGET_ARCH_IA32)
  bool would_update_cache_if_not_lazy = false;
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Checks against type parameters are done by loading the corresponding type
  // argument at runtime and calling the type argument's TTS. Thus, we install
  // specialized TTSes on the type argument, not the parameter itself.
  auto& tts_type = AbstractType::Handle(zone, dst_type.ptr());
  if (tts_type.IsTypeParameter()) {
    const auto& param = TypeParameter::Cast(tts_type);
    tts_type = param.GetFromTypeArguments(instantiator_type_arguments,
                                          function_type_arguments);
  }
  ASSERT(!tts_type.IsTypeParameter());

  if (mode == kTypeCheckFromLazySpecializeStub) {
    if (FLAG_trace_type_checks) {
      THR_Print("  Specializing type testing stub for %s\n",
                tts_type.ToCString());
    }
    const Code& code = Code::Handle(
        zone, TypeTestingStubGenerator::SpecializeStubFor(thread, tts_type));
    tts_type.SetTypeTestingStub(code);

    // Only create the cache if we failed to create a specialized TTS and doing
    // the same check would cause an update to the cache.
    would_update_cache_if_not_lazy =
        (!src_instance.IsNull() &&
         tts_type.type_test_stub() ==
             StubCode::DefaultNullableTypeTest().ptr()) ||
        tts_type.type_test_stub() == StubCode::DefaultTypeTest().ptr();
    should_update_cache = would_update_cache_if_not_lazy && cache.IsNull();
  }

  // Since dst_type is not a top type or type parameter, then the only default
  // stubs it can use are DefaultTypeTest or DefaultNullableTypeTest.
  if ((mode == kTypeCheckFromSlowStub) &&
      (tts_type.type_test_stub() != StubCode::DefaultNullableTypeTest().ptr() &&
       tts_type.type_test_stub() != StubCode::DefaultTypeTest().ptr())) {
    // The specialized type testing stub returned a false negative. That means
    // the specialization may have been generated using outdated cid ranges and
    // new classes appeared since the stub was generated. Try respecializing.
    if (FLAG_trace_type_checks) {
      THR_Print("  Rebuilding type testing stub for %s\n",
                tts_type.ToCString());
    }
    const auto& old_code = Code::Handle(zone, tts_type.type_test_stub());
    const auto& new_code = Code::Handle(
        zone, TypeTestingStubGenerator::SpecializeStubFor(thread, tts_type));
    ASSERT(old_code.ptr() != new_code.ptr());
    // A specialized stub should always respecialize to a non-default stub.
    ASSERT(new_code.ptr() != StubCode::DefaultNullableTypeTest().ptr() &&
           new_code.ptr() != StubCode::DefaultTypeTest().ptr());
    const auto& old_instructions =
        Instructions::Handle(old_code.instructions());
    const auto& new_instructions =
        Instructions::Handle(new_code.instructions());
    // Check if specialization produced exactly the same sequence of
    // instructions. If it did, then we have a false negative, which can
    // happen in some cases involving uninstantiated types. In these cases,
    // update the cache, because the only case in which these false negatives
    // could possibly turn into true positives is with reloads, which clear
    // all the SubtypeTestCaches.
    should_update_cache = old_instructions.Equals(new_instructions);
    if (FLAG_trace_type_checks) {
      THR_Print("  %s rebuilt type testing stub for %s\n",
                should_update_cache ? "Discarding" : "Installing",
                tts_type.ToCString());
    }
    if (!should_update_cache) {
      tts_type.SetTypeTestingStub(new_code);
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // !defined(TARGET_ARCH_IA32)

  if (should_update_cache) {
    if (cache.IsNull()) {
#if !defined(TARGET_ARCH_IA32)
      ASSERT(mode == kTypeCheckFromSlowStub ||
             (mode == kTypeCheckFromLazySpecializeStub &&
              would_update_cache_if_not_lazy));
      // We lazily create [SubtypeTestCache] for those call sites which actually
      // need one and will patch the pool entry.
      DartFrameIterator iterator(thread,
                                 StackFrameIterator::kNoCrossThreadIteration);
      StackFrame* caller_frame = iterator.NextFrame();
      const Code& caller_code =
          Code::Handle(zone, caller_frame->LookupDartCode());
      const ObjectPool& pool =
          ObjectPool::Handle(zone, caller_code.GetObjectPool());
      TypeTestingStubCallPattern tts_pattern(caller_frame->pc());
      const intptr_t stc_pool_idx = tts_pattern.GetSubtypeTestCachePoolIndex();
      // Ensure we do have a STC (lazily create it if not) and all threads use
      // the same STC.
      {
        SafepointMutexLocker ml(isolate->group()->subtype_test_cache_mutex());
        cache ^= pool.ObjectAt<std::memory_order_acquire>(stc_pool_idx);
        if (cache.IsNull()) {
          cache = SubtypeTestCache::New();
          pool.SetObjectAt<std::memory_order_release>(stc_pool_idx, cache);
          if (FLAG_trace_type_checks) {
            THR_Print("  Installed new subtype test cache %#" Px
                      " at index %" Pd " of pool for %s\n",
                      static_cast<uword>(cache.ptr()), stc_pool_idx,
                      caller_code.ToCString());
          }
        }
      }
#else
      UNREACHABLE();
#endif
    }

    UpdateTypeTestCache(zone, thread, src_instance, dst_type,
                        instantiator_type_arguments, function_type_arguments,
                        Bool::True(), cache);
  }

  arguments.SetReturn(src_instance);
}

// Report that the type of the given object is not bool in conditional context.
// Throw assertion error if the object is null. (cf. Boolean Conversion
// in language Spec.)
// Arg0: bad object.
// Return value: none, throws TypeError or AssertionError.
DEFINE_RUNTIME_ENTRY(NonBoolTypeError, 1) {
  const TokenPosition location = GetCallerLocation();
  const Instance& src_instance =
      Instance::CheckedHandle(zone, arguments.ArgAt(0));

  if (src_instance.IsNull()) {
    const Array& args = Array::Handle(zone, Array::New(5));
    args.SetAt(
        0, String::Handle(
               zone,
               String::New(
                   "Failed assertion: boolean expression must not be null")));

    // No source code for this assertion, set url to null.
    args.SetAt(1, String::Handle(zone, String::null()));
    args.SetAt(2, Object::smi_zero());
    args.SetAt(3, Object::smi_zero());
    args.SetAt(4, String::Handle(zone, String::null()));

    Exceptions::ThrowByType(Exceptions::kAssertion, args);
    UNREACHABLE();
  }

  ASSERT(!src_instance.IsBool());
  const Type& bool_interface = Type::Handle(Type::BoolType());
  const AbstractType& src_type =
      AbstractType::Handle(zone, src_instance.GetType(Heap::kNew));
  Exceptions::CreateAndThrowTypeError(location, src_type, bool_interface,
                                      Symbols::BooleanExpression());
  UNREACHABLE();
}

DEFINE_RUNTIME_ENTRY(Throw, 1) {
  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::Throw(thread, exception);
}

DEFINE_RUNTIME_ENTRY(ReThrow, 2) {
  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& stacktrace =
      Instance::CheckedHandle(zone, arguments.ArgAt(1));
  Exceptions::ReThrow(thread, exception, stacktrace);
}

// Patches static call in optimized code with the target's entry point.
// Compiles target if necessary.
DEFINE_RUNTIME_ENTRY(PatchStaticCall, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      zone, caller_code.GetStaticCallTargetFunctionAt(caller_frame->pc()));
  const Code& target_code = Code::Handle(zone, target_function.EnsureHasCode());
  // Before patching verify that we are not repeatedly patching to the same
  // target.
  if (target_code.ptr() !=
      CodePatcher::GetStaticCallTargetAt(caller_frame->pc(), caller_code)) {
    GcSafepointOperationScope safepoint(thread);
    if (target_code.ptr() !=
        CodePatcher::GetStaticCallTargetAt(caller_frame->pc(), caller_code)) {
      CodePatcher::PatchStaticCallAt(caller_frame->pc(), caller_code,
                                     target_code);
      caller_code.SetStaticCallTargetCodeAt(caller_frame->pc(), target_code);
      if (FLAG_trace_patching) {
        THR_Print("PatchStaticCall: patching caller pc %#" Px
                  ""
                  " to '%s' new entry point %#" Px " (%s)\n",
                  caller_frame->pc(), target_function.ToFullyQualifiedCString(),
                  target_code.EntryPoint(),
                  target_code.is_optimized() ? "optimized" : "unoptimized");
      }
    }
  }
  arguments.SetReturn(target_code);
#else
  UNREACHABLE();
#endif
}

#if defined(PRODUCT) || defined(DART_PRECOMPILED_RUNTIME)
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  UNREACHABLE();
  return;
}
#else
// Gets called from debug stub when code reaches a breakpoint
// set on a runtime stub call.
DEFINE_RUNTIME_ENTRY(BreakpointRuntimeHandler, 0) {
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);
  Code& orig_stub = Code::Handle(zone);
  orig_stub =
      isolate->group()->debugger()->GetPatchedStubAddress(caller_frame->pc());
  const Error& error =
      Error::Handle(zone, isolate->debugger()->PauseBreakpoint());
  ThrowIfError(error);
  arguments.SetReturn(orig_stub);
}
#endif

DEFINE_RUNTIME_ENTRY(SingleStepHandler, 0) {
#if defined(PRODUCT) || defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  const Error& error =
      Error::Handle(zone, isolate->debugger()->PauseStepping());
  ThrowIfError(error);
#endif
}

// An instance call of the form o.f(...) could not be resolved.  Check if
// there is a getter with the same name.  If so, invoke it.  If the value is
// a closure, invoke it with the given arguments.  If the value is a
// non-closure, attempt to invoke "call" on it.
static bool ResolveCallThroughGetter(const Class& receiver_class,
                                     const String& target_name,
                                     const String& demangled,
                                     const Array& arguments_descriptor,
                                     Function* result) {
  const String& getter_name = String::Handle(Field::GetterName(demangled));
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;
  ArgumentsDescriptor args_desc(Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  const Function& getter =
      Function::Handle(Resolver::ResolveDynamicForReceiverClass(
          receiver_class, getter_name, args_desc));
  if (getter.IsNull() || getter.IsMethodExtractor()) {
    return false;
  }
  // We do this on the target_name, _not_ on the demangled name, so that
  // FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher can detect dynamic
  // calls from the dyn: tag on the name of the dispatcher.
  const Function& target_function =
      Function::Handle(receiver_class.GetInvocationDispatcher(
          target_name, arguments_descriptor,
          UntaggedFunction::kInvokeFieldDispatcher, FLAG_lazy_dispatchers));
  ASSERT(!target_function.IsNull() || !FLAG_lazy_dispatchers);
  if (FLAG_trace_ic) {
    OS::PrintErr(
        "InvokeField IC miss: adding <%s> id:%" Pd " -> <%s>\n",
        receiver_class.ToCString(), receiver_class.id(),
        target_function.IsNull() ? "null" : target_function.ToCString());
  }
  *result = target_function.ptr();
  return true;
}

// Handle other invocations (implicit closures, noSuchMethod).
FunctionPtr InlineCacheMissHelper(const Class& receiver_class,
                                  const Array& args_descriptor,
                                  const String& target_name) {
  // Create a demangled version of the target_name, if necessary, This is used
  // for the field getter in ResolveCallThroughGetter and as the target name
  // for the NoSuchMethod dispatcher (if needed).
  const String* demangled = &target_name;
  if (Function::IsDynamicInvocationForwarderName(target_name)) {
    demangled = &String::Handle(
        Function::DemangleDynamicInvocationForwarderName(target_name));
  }
  const bool is_getter = Field::IsGetterName(*demangled);
  Function& result = Function::Handle();
  if (is_getter ||
      !ResolveCallThroughGetter(receiver_class, target_name, *demangled,
                                args_descriptor, &result)) {
    ArgumentsDescriptor desc(args_descriptor);
    const Function& target_function =
        Function::Handle(receiver_class.GetInvocationDispatcher(
            *demangled, args_descriptor,
            UntaggedFunction::kNoSuchMethodDispatcher, FLAG_lazy_dispatchers));
    if (FLAG_trace_ic) {
      OS::PrintErr(
          "NoSuchMethod IC miss: adding <%s> id:%" Pd " -> <%s>\n",
          receiver_class.ToCString(), receiver_class.id(),
          target_function.IsNull() ? "null" : target_function.ToCString());
    }
    result = target_function.ptr();
  }
  // May be null if --no-lazy-dispatchers, in which case dispatch will be
  // handled by NoSuchMethodFromCallStub.
  ASSERT(!result.IsNull() || !FLAG_lazy_dispatchers);
  return result.ptr();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static void TrySwitchInstanceCall(Thread* thread,
                                  StackFrame* caller_frame,
                                  const Code& caller_code,
                                  const Function& caller_function,
                                  const ICData& ic_data,
                                  const Function& target_function) {
  auto zone = thread->zone();

  // Monomorphic/megamorphic calls only check the receiver CID.
  if (ic_data.NumArgsTested() != 1) return;

  ASSERT(ic_data.rebind_rule() == ICData::kInstance);

  // Monomorphic/megamorphic calls don't record exactness.
  if (ic_data.is_tracking_exactness()) return;

#if !defined(PRODUCT)
  // Monomorphic/megamorphic do not check the isolate's stepping flag.
  if (thread->isolate()->has_attempted_stepping()) return;
#endif

  // Monomorphic/megamorphic calls are only for unoptimized code.
  ASSERT(!caller_code.is_optimized());

  // Code is detached from its function. This will prevent us from resetting
  // the switchable call later because resets are function based and because
  // the ic_data_array belongs to the function instead of the code. This should
  // only happen because of reload, but it sometimes happens with KBC mixed mode
  // probably through a race between foreground and background compilation.
  if (caller_function.unoptimized_code() != caller_code.ptr()) {
    return;
  }
#if !defined(PRODUCT)
  // Skip functions that contain breakpoints or when debugger is in single
  // stepping mode.
  if (thread->isolate_group()->debugger()->IsDebugging(thread,
                                                       caller_function)) {
    return;
  }
#endif

  const intptr_t num_checks = ic_data.NumberOfChecks();

  // Monomorphic call.
  if (FLAG_unopt_monomorphic_calls && (num_checks == 1)) {
    // A call site in the monomorphic state does not load the arguments
    // descriptor, so do not allow transition to this state if the callee
    // needs it.
    if (target_function.PrologueNeedsArgumentsDescriptor()) {
      return;
    }

    const Array& data = Array::Handle(zone, ic_data.entries());
    const Code& target = Code::Handle(zone, target_function.EnsureHasCode());
    CodePatcher::PatchInstanceCallAt(caller_frame->pc(), caller_code, data,
                                     target);
    if (FLAG_trace_ic) {
      OS::PrintErr("Instance call at %" Px
                   " switching to monomorphic dispatch, %s\n",
                   caller_frame->pc(), ic_data.ToCString());
    }
    return;  // Success.
  }

  // Megamorphic call.
  if (FLAG_unopt_megamorphic_calls &&
      (num_checks > FLAG_max_polymorphic_checks)) {
    const String& name = String::Handle(zone, ic_data.target_name());
    const Array& descriptor =
        Array::Handle(zone, ic_data.arguments_descriptor());
    const MegamorphicCache& cache = MegamorphicCache::Handle(
        zone, MegamorphicCacheTable::Lookup(thread, name, descriptor));
    ic_data.set_is_megamorphic(true);
    CodePatcher::PatchInstanceCallAt(caller_frame->pc(), caller_code, cache,
                                     StubCode::MegamorphicCall());
    if (FLAG_trace_ic) {
      OS::PrintErr("Instance call at %" Px
                   " switching to megamorphic dispatch, %s\n",
                   caller_frame->pc(), ic_data.ToCString());
    }
    return;  // Success.
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// Perform the subtype and return constant function based on the result.
static FunctionPtr ComputeTypeCheckTarget(const Instance& receiver,
                                          const AbstractType& type,
                                          const ArgumentsDescriptor& desc) {
  const bool result = receiver.IsInstanceOf(type, Object::null_type_arguments(),
                                            Object::null_type_arguments());
  const ObjectStore* store = IsolateGroup::Current()->object_store();
  const Function& target =
      Function::Handle(result ? store->simple_instance_of_true_function()
                              : store->simple_instance_of_false_function());
  ASSERT(!target.IsNull());
  return target.ptr();
}

static FunctionPtr Resolve(
    Thread* thread,
    Zone* zone,
    const GrowableArray<const Instance*>& caller_arguments,
    const Class& receiver_class,
    const String& name,
    const Array& descriptor) {
  ASSERT(name.IsSymbol());
  auto& target_function = Function::Handle(zone);
  ArgumentsDescriptor args_desc(descriptor);

  if (receiver_class.EnsureIsFinalized(thread) == Error::null()) {
    target_function = Resolver::ResolveDynamicForReceiverClass(receiver_class,
                                                               name, args_desc);
  }
  if (caller_arguments.length() == 2 &&
      target_function.ptr() == thread->isolate_group()
                                   ->object_store()
                                   ->simple_instance_of_function()) {
    // Replace the target function with constant function.
    const AbstractType& type = AbstractType::Cast(*caller_arguments[1]);
    target_function =
        ComputeTypeCheckTarget(*caller_arguments[0], type, args_desc);
  }

  if (target_function.IsNull()) {
    target_function = InlineCacheMissHelper(receiver_class, descriptor, name);
  }
  if (target_function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
  }

  return target_function.ptr();
}

// Handles a static call in unoptimized code that has one argument type not
// seen before. Compile the target if necessary and update the ICData.
// Arg0: argument.
// Arg1: IC data object.
DEFINE_RUNTIME_ENTRY(StaticCallMissHandlerOneArg, 2) {
  const Instance& arg = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(1));
  // IC data for static call is prepopulated with the statically known target.
  ASSERT(ic_data.NumberOfChecksIs(1));
  const Function& target = Function::Handle(zone, ic_data.GetTargetAt(0));
  target.EnsureHasCode();
  ASSERT(!target.IsNull() && target.HasCode());
  ic_data.EnsureHasReceiverCheck(arg.GetClassId(), target, 1);
  if (FLAG_trace_ic) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != nullptr);
    OS::PrintErr("StaticCallMissHandler at %#" Px " target %s (%" Pd ")\n",
                 caller_frame->pc(), target.ToCString(), arg.GetClassId());
  }
  arguments.SetReturn(target);
}

// Handles a static call in unoptimized code that has two argument types not
// seen before. Compile the target if necessary and update the ICData.
// Arg0: argument 0.
// Arg1: argument 1.
// Arg2: IC data object.
DEFINE_RUNTIME_ENTRY(StaticCallMissHandlerTwoArgs, 3) {
  const Instance& arg0 = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& arg1 = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(2));
  // IC data for static call is prepopulated with the statically known target.
  ASSERT(!ic_data.NumberOfChecksIs(0));
  const Function& target = Function::Handle(zone, ic_data.GetTargetAt(0));
  target.EnsureHasCode();
  GrowableArray<intptr_t> cids(2);
  cids.Add(arg0.GetClassId());
  cids.Add(arg1.GetClassId());
  ic_data.EnsureHasCheck(cids, target);
  if (FLAG_trace_ic) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();
    ASSERT(caller_frame != nullptr);
    OS::PrintErr("StaticCallMissHandler at %#" Px " target %s (%" Pd ", %" Pd
                 ")\n",
                 caller_frame->pc(), target.ToCString(), cids[0], cids[1]);
  }
  arguments.SetReturn(target);
}

#if defined(DART_PRECOMPILED_RUNTIME)

static bool IsSingleTarget(IsolateGroup* isolate_group,
                           Zone* zone,
                           intptr_t lower_cid,
                           intptr_t upper_cid,
                           const Function& target,
                           const String& name) {
  Class& cls = Class::Handle(zone);
  ClassTable* table = isolate_group->class_table();
  Function& other_target = Function::Handle(zone);
  for (intptr_t cid = lower_cid; cid <= upper_cid; cid++) {
    if (!table->HasValidClassAt(cid)) continue;
    cls = table->At(cid);
    if (cls.is_abstract()) continue;
    if (!cls.is_allocated()) continue;
    other_target = Resolver::ResolveDynamicAnyArgs(zone, cls, name,
                                                   /*allow_add=*/false);
    if (other_target.ptr() != target.ptr()) {
      return false;
    }
  }
  return true;
}

class SavedUnlinkedCallMapKeyEqualsTraits : public AllStatic {
 public:
  static const char* Name() { return "SavedUnlinkedCallMapKeyEqualsTraits "; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& key1, const Object& key2) {
    if (!key1.IsInteger() || !key2.IsInteger()) return false;
    return Integer::Cast(key1).Equals(Integer::Cast(key2));
  }
  static uword Hash(const Object& key) {
    return Integer::Cast(key).CanonicalizeHash();
  }
};

using UnlinkedCallMap = UnorderedHashMap<SavedUnlinkedCallMapKeyEqualsTraits>;

static void SaveUnlinkedCall(Zone* zone,
                             Isolate* isolate,
                             uword frame_pc,
                             const UnlinkedCall& unlinked_call) {
  IsolateGroup* isolate_group = isolate->group();

  SafepointMutexLocker ml(isolate_group->unlinked_call_map_mutex());
  if (isolate_group->saved_unlinked_calls() == Array::null()) {
    const auto& initial_map =
        Array::Handle(zone, HashTables::New<UnlinkedCallMap>(16, Heap::kOld));
    isolate_group->set_saved_unlinked_calls(initial_map);
  }

  UnlinkedCallMap unlinked_call_map(zone,
                                    isolate_group->saved_unlinked_calls());
  const auto& pc = Integer::Handle(zone, Integer::NewFromUint64(frame_pc));
  // Some other isolate might have updated unlinked_call_map[pc] too, but
  // their update should be identical to ours.
  const auto& new_or_old_value = UnlinkedCall::Handle(
      zone, UnlinkedCall::RawCast(
                unlinked_call_map.InsertOrGetValue(pc, unlinked_call)));
  RELEASE_ASSERT(new_or_old_value.ptr() == unlinked_call.ptr());
  isolate_group->set_saved_unlinked_calls(unlinked_call_map.Release());
}

static UnlinkedCallPtr LoadUnlinkedCall(Zone* zone,
                                        Isolate* isolate,
                                        uword pc) {
  IsolateGroup* isolate_group = isolate->group();

  SafepointMutexLocker ml(isolate_group->unlinked_call_map_mutex());
  ASSERT(isolate_group->saved_unlinked_calls() != Array::null());
  UnlinkedCallMap unlinked_call_map(zone,
                                    isolate_group->saved_unlinked_calls());

  const auto& pc_integer = Integer::Handle(zone, Integer::NewFromUint64(pc));
  const auto& unlinked_call = UnlinkedCall::Cast(
      Object::Handle(zone, unlinked_call_map.GetOrDie(pc_integer)));
  isolate_group->set_saved_unlinked_calls(unlinked_call_map.Release());
  return unlinked_call.ptr();
}

// NOTE: Right now we never delete [UnlinkedCall] objects. They are needed while
// a call site is in Unlinked/Monomorphic/MonomorphicSmiable/SingleTarget
// states.
//
// Theoretically we could free the [UnlinkedCall] object once we transition the
// call site to use ICData/MegamorphicCache, but that would require careful
// coordination between the deleter and a possible concurrent reader.
//
// To simplify the code we decided not to do that atm (only a very small
// fraction of callsites in AOT use switchable calls, the name/args-descriptor
// objects are kept alive anyways -> there is little memory savings from
// freeing the [UnlinkedCall] objects).

#endif  // defined(DART_PRECOMPILED_RUNTIME)

enum class MissHandler {
  kInlineCacheMiss,
  kSwitchableCallMiss,
  kFixCallersTargetMonomorphic,
};

// Handles updating of type feedback and possible patching of instance calls.
//
// It works in 3 separate steps:
//   - resolve the actual target
//   - update type feedback & (optionally) perform call site transition
//   - return the right values
//
// Depending on the JIT/AOT mode we obtain current and patch new (target, data)
// differently:
//
//   - JIT calls must be patched with CodePatcher::PatchInstanceCallAt()
//   - AOT calls must be patched with CodePatcher::PatchSwitchableCallAt()
//
// Independent of which miss handler was used or how we will return, we look at
// current (target, data) and see if we need to transition the call site to a
// new (target, data). We do this while holding `IG->patchable_call_mutex()`.
//
// Depending on which miss handler got called we might need to return
// differently:
//
//   - SwitchableCallMiss will get get (stub, data) return value
//   - InlineCache*Miss will get get function as return value
//
class PatchableCallHandler {
 public:
  PatchableCallHandler(Thread* thread,
                       const GrowableArray<const Instance*>& caller_arguments,
                       MissHandler miss_handler,
                       NativeArguments arguments,
                       StackFrame* caller_frame,
                       const Code& caller_code,
                       const Function& caller_function)
      : isolate_(thread->isolate()),
        thread_(thread),
        zone_(thread->zone()),
        caller_arguments_(caller_arguments),
        miss_handler_(miss_handler),
        arguments_(arguments),
        caller_frame_(caller_frame),
        caller_code_(caller_code),
        caller_function_(caller_function),
        name_(String::Handle()),
        args_descriptor_(Array::Handle()) {
    // We only have two arg IC calls in JIT mode.
    ASSERT(caller_arguments_.length() == 1 || !FLAG_precompiled_mode);
  }

  void ResolveSwitchAndReturn(const Object& data);

 private:
  FunctionPtr ResolveTargetFunction(const Object& data);

#if defined(DART_PRECOMPILED_RUNTIME)
  void HandleMissAOT(const Object& old_data,
                     uword old_entry,
                     const Function& target_function);

  void DoUnlinkedCallAOT(const UnlinkedCall& unlinked,
                         const Function& target_function);
  void DoMonomorphicMissAOT(const Object& old_data,
                            const Function& target_function);
  void DoSingleTargetMissAOT(const SingleTargetCache& data,
                             const Function& target_function);
  void DoICDataMissAOT(const ICData& data, const Function& target_function);
  bool CanExtendSingleTargetRange(const String& name,
                                  const Function& old_target,
                                  const Function& target_function,
                                  intptr_t* lower,
                                  intptr_t* upper);
#else
  void HandleMissJIT(const Object& old_data,
                     const Code& old_target,
                     const Function& target_function);

  void DoMonomorphicMissJIT(const Object& old_data,
                            const Function& target_function);
  void DoICDataMissJIT(const ICData& data,
                       const Object& old_data,
                       const Function& target_function);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  void DoMegamorphicMiss(const MegamorphicCache& data,
                         const Function& target_function);

  void UpdateICDataWithTarget(const ICData& ic_data,
                              const Function& target_function);
  void TrySwitch(const ICData& ic_data, const Function& target_function);

  void ReturnAOT(const Code& stub, const Object& data);
  void ReturnJIT(const Code& stub, const Object& data, const Function& target);
  void ReturnJITorAOT(const Code& stub,
                      const Object& data,
                      const Function& target);

  const Instance& receiver() { return *caller_arguments_[0]; }

  bool should_consider_patching() {
    // In AOT we use switchable calls.
    if (FLAG_precompiled_mode) return true;

    // In JIT instance calls use a different calling sequence in unoptimized vs
    // optimized code (see [FlowGraphCompiler::EmitInstanceCallJIT] vs
    // [FlowGraphCompiler::EmitOptimizedInstanceCall]).
    //
    // The [CodePatcher::GetInstanceCallAt], [CodePatcher::PatchInstanceCallAt]
    // only recognize unoptimized call pattern.
    //
    // So we will not try to switch optimized instance calls.
    return !caller_code_.is_optimized();
  }

  ICDataPtr NewICData();
  ICDataPtr NewICDataWithTarget(intptr_t cid, const Function& target);

  Isolate* isolate_;
  Thread* thread_;
  Zone* zone_;
  const GrowableArray<const Instance*>& caller_arguments_;
  MissHandler miss_handler_;
  NativeArguments arguments_;
  StackFrame* caller_frame_;
  const Code& caller_code_;
  const Function& caller_function_;

  // Call-site information populated during resolution.
  String& name_;
  Array& args_descriptor_;
  bool is_monomorphic_hit_ = false;
};

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoUnlinkedCallAOT(const UnlinkedCall& unlinked,
                                             const Function& target_function) {
  const auto& ic_data = ICData::Handle(
      zone_,
      target_function.IsNull()
          ? NewICData()
          : NewICDataWithTarget(receiver().GetClassId(), target_function));

  Object& object = Object::Handle(zone_, ic_data.ptr());
  Code& code = Code::Handle(zone_, StubCode::ICCallThroughCode().ptr());
  // If the target function has optional parameters or is generic, it's
  // prologue requires ARGS_DESC_REG to be populated. Yet the switchable calls
  // do not populate that on the call site, which is why we don't transition
  // those call sites to monomorphic, but rather directly to call via stub
  // (which will populate the ARGS_DESC_REG from the ICData).
  //
  // Because of this we also don't generate monomorphic checks for those
  // functions.
  if (!target_function.IsNull() &&
      !target_function.PrologueNeedsArgumentsDescriptor()) {
    // Patch to monomorphic call.
    ASSERT(target_function.HasCode());
    const Code& target_code =
        Code::Handle(zone_, target_function.CurrentCode());
    const Smi& expected_cid =
        Smi::Handle(zone_, Smi::New(receiver().GetClassId()));

    if (unlinked.can_patch_to_monomorphic()) {
      object = expected_cid.ptr();
      code = target_code.ptr();
      ASSERT(code.HasMonomorphicEntry());
    } else {
      object = MonomorphicSmiableCall::New(expected_cid.Value(), target_code);
      code = StubCode::MonomorphicSmiableCheck().ptr();
    }
  }
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, object,
                                     code);

  // Return the ICData. The miss stub will jump to continue in the IC lookup
  // stub.
  ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
}

bool PatchableCallHandler::CanExtendSingleTargetRange(
    const String& name,
    const Function& old_target,
    const Function& target_function,
    intptr_t* lower,
    intptr_t* upper) {
  if (old_target.ptr() != target_function.ptr()) {
    return false;
  }
  intptr_t unchecked_lower, unchecked_upper;
  if (receiver().GetClassId() < *lower) {
    unchecked_lower = receiver().GetClassId();
    unchecked_upper = *lower - 1;
    *lower = receiver().GetClassId();
  } else {
    unchecked_upper = receiver().GetClassId();
    unchecked_lower = *upper + 1;
    *upper = receiver().GetClassId();
  }

  return IsSingleTarget(isolate_->group(), zone_, unchecked_lower,
                        unchecked_upper, target_function, name);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoMonomorphicMissAOT(
    const Object& old_data,
    const Function& target_function) {
  classid_t old_expected_cid;
  if (old_data.IsSmi()) {
    old_expected_cid = Smi::Cast(old_data).Value();
  } else {
    RELEASE_ASSERT(old_data.IsMonomorphicSmiableCall());
    old_expected_cid = MonomorphicSmiableCall::Cast(old_data).expected_cid();
  }
  const bool is_monomorphic_hit = old_expected_cid == receiver().GetClassId();
  const auto& old_receiver_class = Class::Handle(
      zone_, isolate_->group()->class_table()->At(old_expected_cid));
  const auto& old_target = Function::Handle(
      zone_, Resolve(thread_, zone_, caller_arguments_, old_receiver_class,
                     name_, args_descriptor_));

  const auto& ic_data = ICData::Handle(
      zone_, old_target.IsNull()
                 ? NewICData()
                 : NewICDataWithTarget(old_expected_cid, old_target));

  if (is_monomorphic_hit) {
    // The site just have been updated to monomorphic state with same
    // exact class id - do nothing in that case: stub will call through ic data.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  intptr_t lower = old_expected_cid;
  intptr_t upper = old_expected_cid;
  if (CanExtendSingleTargetRange(name_, old_target, target_function, &lower,
                                 &upper)) {
    const SingleTargetCache& cache =
        SingleTargetCache::Handle(zone_, SingleTargetCache::New());
    const Code& code = Code::Handle(zone_, target_function.CurrentCode());
    cache.set_target(code);
    cache.set_entry_point(code.EntryPoint());
    cache.set_lower_limit(lower);
    cache.set_upper_limit(upper);
    const Code& stub = StubCode::SingleTargetCall();
    CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, cache,
                                       stub);
    // Return the ICData. The miss stub will jump to continue in the IC call
    // stub.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  // Patch to call through stub.
  const Code& stub = StubCode::ICCallThroughCode();
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                     stub);

  // Return the ICData. The miss stub will jump to continue in the IC lookup
  // stub.
  ReturnAOT(stub, ic_data);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoMonomorphicMissJIT(
    const Object& old_data,
    const Function& target_function) {
  // Monomorphic calls use the ICData::entries() as their data.
  const auto& old_ic_data_entries = Array::Cast(old_data);
  // Any non-empty ICData::entries() has a backref to it's ICData.
  const auto& ic_data =
      ICData::Handle(zone_, ICData::ICDataOfEntriesArray(old_ic_data_entries));

  // The target didn't change, so we can stay inside monomorphic state.
  if (ic_data.NumberOfChecksIs(1) &&
      (ic_data.GetReceiverClassIdAt(0) == receiver().GetClassId())) {
    // No need to update ICData - it's already up-to-date.

    if (FLAG_trace_ic) {
      OS::PrintErr("Instance call at %" Px
                   " updating code (old code was disabled)\n",
                   caller_frame_->pc());
    }

    // We stay in monomorphic state, patch the code object and reload the icdata
    // entries array.
    const auto& code = Code::Handle(zone_, target_function.EnsureHasCode());
    const auto& data = Object::Handle(zone_, ic_data.entries());
    CodePatcher::PatchInstanceCallAt(caller_frame_->pc(), caller_code_, data,
                                     code);
    ReturnJIT(code, data, target_function);
    return;
  }

  ASSERT(ic_data.NumArgsTested() == 1);
  const Code& stub = ic_data.is_tracking_exactness()
                         ? StubCode::OneArgCheckInlineCacheWithExactnessCheck()
                         : StubCode::OneArgCheckInlineCache();
  if (FLAG_trace_ic) {
    OS::PrintErr("Instance call at %" Px
                 " switching monomorphic to polymorphic dispatch, %s\n",
                 caller_frame_->pc(), ic_data.ToCString());
  }
  CodePatcher::PatchInstanceCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                   stub);

  ASSERT(caller_arguments_.length() == 1);
  UpdateICDataWithTarget(ic_data, target_function);
  ASSERT(should_consider_patching());
  TrySwitchInstanceCall(thread_, caller_frame_, caller_code_, caller_function_,
                        ic_data, target_function);
  ReturnJIT(stub, ic_data, target_function);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoSingleTargetMissAOT(
    const SingleTargetCache& data,
    const Function& target_function) {
  const Code& old_target_code = Code::Handle(zone_, data.target());
  const Function& old_target =
      Function::Handle(zone_, Function::RawCast(old_target_code.owner()));

  // We lost the original ICData when we patched to the monomorphic case.
  const auto& ic_data = ICData::Handle(
      zone_,
      target_function.IsNull()
          ? NewICData()
          : NewICDataWithTarget(receiver().GetClassId(), target_function));

  intptr_t lower = data.lower_limit();
  intptr_t upper = data.upper_limit();
  if (CanExtendSingleTargetRange(name_, old_target, target_function, &lower,
                                 &upper)) {
    data.set_lower_limit(lower);
    data.set_upper_limit(upper);
    // Return the ICData. The single target stub will jump to continue in the
    // IC call stub.
    ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    return;
  }

  // Call site is not single target, switch to call using ICData.
  const Code& stub = StubCode::ICCallThroughCode();
  CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_, ic_data,
                                     stub);

  // Return the ICData. The single target stub will jump to continue in the
  // IC call stub.
  ReturnAOT(stub, ic_data);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoICDataMissAOT(const ICData& ic_data,
                                           const Function& target_function) {
  const String& name = String::Handle(zone_, ic_data.target_name());
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  ASSERT(!cls.IsNull());
  const Array& descriptor =
      Array::CheckedHandle(zone_, ic_data.arguments_descriptor());
  ArgumentsDescriptor args_desc(descriptor);
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("ICData miss, class=%s, function<%" Pd ">=%s\n",
                 cls.ToCString(), args_desc.TypeArgsLen(), name.ToCString());
  }

  if (target_function.IsNull()) {
    ReturnAOT(StubCode::NoSuchMethodDispatcher(), ic_data);
    return;
  }

  const intptr_t number_of_checks = ic_data.NumberOfChecks();

  if ((number_of_checks == 0) &&
      (!FLAG_precompiled_mode || ic_data.receiver_cannot_be_smi()) &&
      !target_function.PrologueNeedsArgumentsDescriptor()) {
    // This call site is unlinked: transition to a monomorphic direct call.
    // Note we cannot do this if the target has optional parameters because
    // the monomorphic direct call does not load the arguments descriptor.
    // We cannot do this if we are still in the middle of precompiling because
    // the monomorphic case hides a live instance selector from the
    // treeshaker.
    const Code& target_code =
        Code::Handle(zone_, target_function.EnsureHasCode());
    const Smi& expected_cid =
        Smi::Handle(zone_, Smi::New(receiver().GetClassId()));
    ASSERT(target_code.HasMonomorphicEntry());
    CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_,
                                       expected_cid, target_code);
    ReturnAOT(target_code, expected_cid);
  } else {
    ic_data.EnsureHasReceiverCheck(receiver().GetClassId(), target_function);
    if (number_of_checks > FLAG_max_polymorphic_checks) {
      // Switch to megamorphic call.
      const MegamorphicCache& cache = MegamorphicCache::Handle(
          zone_, MegamorphicCacheTable::Lookup(thread_, name, descriptor));
      const Code& stub = StubCode::MegamorphicCall();

      CodePatcher::PatchSwitchableCallAt(caller_frame_->pc(), caller_code_,
                                         cache, stub);
      ReturnAOT(stub, cache);
    } else {
      ReturnAOT(StubCode::ICCallThroughCode(), ic_data);
    }
  }
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
void PatchableCallHandler::DoICDataMissJIT(const ICData& ic_data,
                                           const Object& old_code,
                                           const Function& target_function) {
  ASSERT(ic_data.NumArgsTested() == caller_arguments_.length());

  if (ic_data.NumArgsTested() == 1) {
    ASSERT(old_code.ptr() == StubCode::OneArgCheckInlineCache().ptr() ||
           old_code.ptr() ==
               StubCode::OneArgCheckInlineCacheWithExactnessCheck().ptr() ||
           old_code.ptr() ==
               StubCode::OneArgOptimizedCheckInlineCache().ptr() ||
           old_code.ptr() ==
               StubCode::OneArgOptimizedCheckInlineCacheWithExactnessCheck()
                   .ptr() ||
           old_code.ptr() == StubCode::ICCallBreakpoint().ptr() ||
           (old_code.IsNull() && !should_consider_patching()));
    UpdateICDataWithTarget(ic_data, target_function);
    if (should_consider_patching()) {
      TrySwitchInstanceCall(thread_, caller_frame_, caller_code_,
                            caller_function_, ic_data, target_function);
    }
    const Code& stub = Code::Handle(
        zone_, ic_data.is_tracking_exactness()
                   ? StubCode::OneArgCheckInlineCacheWithExactnessCheck().ptr()
                   : StubCode::OneArgCheckInlineCache().ptr());
    ReturnJIT(stub, ic_data, target_function);
  } else {
    ASSERT(old_code.ptr() == StubCode::TwoArgsCheckInlineCache().ptr() ||
           old_code.ptr() == StubCode::SmiAddInlineCache().ptr() ||
           old_code.ptr() == StubCode::SmiLessInlineCache().ptr() ||
           old_code.ptr() == StubCode::SmiEqualInlineCache().ptr() ||
           old_code.ptr() ==
               StubCode::TwoArgsOptimizedCheckInlineCache().ptr() ||
           old_code.ptr() == StubCode::ICCallBreakpoint().ptr() ||
           (old_code.IsNull() && !should_consider_patching()));
    UpdateICDataWithTarget(ic_data, target_function);
    ReturnJIT(StubCode::TwoArgsCheckInlineCache(), ic_data, target_function);
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void PatchableCallHandler::DoMegamorphicMiss(const MegamorphicCache& data,
                                             const Function& target_function) {
  const String& name = String::Handle(zone_, data.target_name());
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  ASSERT(!cls.IsNull());
  const Array& descriptor =
      Array::CheckedHandle(zone_, data.arguments_descriptor());
  ArgumentsDescriptor args_desc(descriptor);
  if (FLAG_trace_ic || FLAG_trace_ic_miss_in_optimized) {
    OS::PrintErr("Megamorphic miss, class=%s, function<%" Pd ">=%s\n",
                 cls.ToCString(), args_desc.TypeArgsLen(), name.ToCString());
  }
  if (target_function.IsNull()) {
    ReturnJITorAOT(StubCode::NoSuchMethodDispatcher(), data, target_function);
    return;
  }

  // Insert function found into cache.
  const Smi& class_id = Smi::Handle(zone_, Smi::New(cls.id()));
  data.EnsureContains(class_id, target_function);
  ReturnJITorAOT(StubCode::MegamorphicCall(), data, target_function);
}

void PatchableCallHandler::UpdateICDataWithTarget(
    const ICData& ic_data,
    const Function& target_function) {
  if (target_function.IsNull()) return;

  // If, upon return of the runtime, we will invoke the target directly we have
  // to increment the call count here in the ICData.
  // If we instead only insert a new ICData entry and will return to the IC stub
  // which will call the target, the stub will take care of the increment.
  const bool call_target_directly =
      miss_handler_ == MissHandler::kInlineCacheMiss;
  const intptr_t invocation_count = call_target_directly ? 1 : 0;

  if (caller_arguments_.length() == 1) {
    auto exactness = StaticTypeExactnessState::NotTracking();
#if !defined(DART_PRECOMPILED_RUNTIME)
    if (ic_data.is_tracking_exactness()) {
      exactness = receiver().IsNull()
                      ? StaticTypeExactnessState::NotExact()
                      : StaticTypeExactnessState::Compute(
                            Type::Cast(AbstractType::Handle(
                                ic_data.receivers_static_type())),
                            receiver());
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
    ic_data.EnsureHasReceiverCheck(receiver().GetClassId(), target_function,
                                   invocation_count, exactness);
  } else {
    GrowableArray<intptr_t> class_ids(caller_arguments_.length());
    ASSERT(ic_data.NumArgsTested() == caller_arguments_.length());
    for (intptr_t i = 0; i < caller_arguments_.length(); i++) {
      class_ids.Add(caller_arguments_[i]->GetClassId());
    }
    ic_data.EnsureHasCheck(class_ids, target_function, invocation_count);
  }
}

void PatchableCallHandler::ReturnAOT(const Code& stub, const Object& data) {
  ASSERT(miss_handler_ == MissHandler::kSwitchableCallMiss);
  arguments_.SetArgAt(0, stub);  // Second return value.
  arguments_.SetReturn(data);
}

void PatchableCallHandler::ReturnJIT(const Code& stub,
                                     const Object& data,
                                     const Function& target) {
  // In JIT we can have two different miss handlers to which we return slightly
  // differently.
  switch (miss_handler_) {
    case MissHandler::kSwitchableCallMiss: {
      arguments_.SetArgAt(0, stub);  // Second return value.
      arguments_.SetReturn(data);
      break;
    }
    case MissHandler::kFixCallersTargetMonomorphic: {
      arguments_.SetArgAt(1, data);  // Second return value.
      arguments_.SetReturn(stub);
      break;
    }
    case MissHandler::kInlineCacheMiss: {
      arguments_.SetReturn(target);
      break;
    }
  }
}

void PatchableCallHandler::ReturnJITorAOT(const Code& stub,
                                          const Object& data,
                                          const Function& target) {
#if defined(DART_PRECOMPILED_MODE)
  ReturnAOT(stub, data);
#else
  ReturnJIT(stub, data, target);
#endif
}

ICDataPtr PatchableCallHandler::NewICData() {
  return ICData::New(caller_function_, name_, args_descriptor_, DeoptId::kNone,
                     /*num_args_tested=*/1, ICData::kInstance);
}

ICDataPtr PatchableCallHandler::NewICDataWithTarget(intptr_t cid,
                                                    const Function& target) {
  GrowableArray<intptr_t> cids(1);
  cids.Add(cid);
  return ICData::NewWithCheck(caller_function_, name_, args_descriptor_,
                              DeoptId::kNone, /*num_args_tested=*/1,
                              ICData::kInstance, &cids, target);
}

FunctionPtr PatchableCallHandler::ResolveTargetFunction(const Object& data) {
  switch (data.GetClassId()) {
    case kUnlinkedCallCid: {
      const auto& unlinked_call = UnlinkedCall::Cast(data);

#if defined(DART_PRECOMPILED_RUNTIME)
      // When transitioning out of UnlinkedCall to other states (e.g.
      // Monomorphic, MonomorphicSmiable, SingleTarget) we lose
      // name/arg-descriptor in AOT mode and cannot recover it.
      //
      // Even if we could recover an old target function (which was missed) -
      // which we cannot in AOT bare mode - we can still lose the name due to a
      // dyn:* call site potentially targeting non-dyn:* targets.
      //
      // => We will therefore retain the unlinked call here.
      //
      // In JIT mode we always use ICData from the call site, which has the
      // correct name/args-descriptor.
      SaveUnlinkedCall(zone_, isolate_, caller_frame_->pc(), unlinked_call);
#endif  // defined(DART_PRECOMPILED_RUNTIME)

      name_ = unlinked_call.target_name();
      args_descriptor_ = unlinked_call.arguments_descriptor();
      break;
    }
    case kMonomorphicSmiableCallCid:
      FALL_THROUGH;
#if defined(DART_PRECOMPILED_RUNTIME)
    case kSmiCid:
      FALL_THROUGH;
    case kSingleTargetCacheCid: {
      const auto& unlinked_call = UnlinkedCall::Handle(
          zone_, LoadUnlinkedCall(zone_, isolate_, caller_frame_->pc()));
      name_ = unlinked_call.target_name();
      args_descriptor_ = unlinked_call.arguments_descriptor();
      break;
    }
#else
    case kArrayCid: {
      // Monomorphic calls use the ICData::entries() as their data.
      const auto& ic_data_entries = Array::Cast(data);
      // Any non-empty ICData::entries() has a backref to it's ICData.
      const auto& ic_data =
          ICData::Handle(zone_, ICData::ICDataOfEntriesArray(ic_data_entries));
      args_descriptor_ = ic_data.arguments_descriptor();
      name_ = ic_data.target_name();
      break;
    }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
    case kICDataCid:
      FALL_THROUGH;
    case kMegamorphicCacheCid: {
      const CallSiteData& call_site_data = CallSiteData::Cast(data);
      name_ = call_site_data.target_name();
      args_descriptor_ = call_site_data.arguments_descriptor();
      break;
    }
    default:
      UNREACHABLE();
  }
  const Class& cls = Class::Handle(zone_, receiver().clazz());
  return Resolve(thread_, zone_, caller_arguments_, cls, name_,
                 args_descriptor_);
}

void PatchableCallHandler::ResolveSwitchAndReturn(const Object& old_data) {
  // Find out actual target (which can be time consuming) without holding any
  // locks.
  const auto& target_function =
      Function::Handle(zone_, ResolveTargetFunction(old_data));

  auto& data = Object::Handle(zone_);

  // We ensure any transition in a patchable calls are done in an atomic
  // manner, we ensure we always transition forward (e.g. Monomorphic ->
  // Polymorphic).
  //
  // Mutators are only stopped if we actually need to patch a patchable call.
  // We may not do that if we e.g. just add one more check to an ICData.
  SafepointMutexLocker ml(thread_->isolate_group()->patchable_call_mutex());

#if defined(DART_PRECOMPILED_RUNTIME)
  data =
      CodePatcher::GetSwitchableCallDataAt(caller_frame_->pc(), caller_code_);
  uword target_entry = 0;
  DEBUG_ONLY(target_entry = CodePatcher::GetSwitchableCallTargetEntryAt(
                 caller_frame_->pc(), caller_code_));
  HandleMissAOT(data, target_entry, target_function);
#else
  auto& code = Code::Handle(zone_);
  if (should_consider_patching()) {
    code ^= CodePatcher::GetInstanceCallAt(caller_frame_->pc(), caller_code_,
                                           &data);
  } else {
    ASSERT(old_data.IsICData() || old_data.IsMegamorphicCache());
    data = old_data.ptr();
  }
  HandleMissJIT(data, code, target_function);
#endif
}

#if defined(DART_PRECOMPILED_RUNTIME)

void PatchableCallHandler::HandleMissAOT(const Object& old_data,
                                         uword old_entry,
                                         const Function& target_function) {
  switch (old_data.GetClassId()) {
    case kUnlinkedCallCid:
      ASSERT(old_entry ==
             StubCode::SwitchableCallMiss().MonomorphicEntryPoint());
      DoUnlinkedCallAOT(UnlinkedCall::Cast(old_data), target_function);
      break;
    case kMonomorphicSmiableCallCid:
      ASSERT(old_entry ==
             StubCode::MonomorphicSmiableCheck().MonomorphicEntryPoint());
      FALL_THROUGH;
    case kSmiCid:
      DoMonomorphicMissAOT(old_data, target_function);
      break;
    case kSingleTargetCacheCid:
      ASSERT(old_entry == StubCode::SingleTargetCall().MonomorphicEntryPoint());
      DoSingleTargetMissAOT(SingleTargetCache::Cast(old_data), target_function);
      break;
    case kICDataCid:
      ASSERT(old_entry ==
             StubCode::ICCallThroughCode().MonomorphicEntryPoint());
      DoICDataMissAOT(ICData::Cast(old_data), target_function);
      break;
    case kMegamorphicCacheCid:
      ASSERT(old_entry == StubCode::MegamorphicCall().MonomorphicEntryPoint());
      DoMegamorphicMiss(MegamorphicCache::Cast(old_data), target_function);
      break;
    default:
      UNREACHABLE();
  }
}

#else

void PatchableCallHandler::HandleMissJIT(const Object& old_data,
                                         const Code& old_code,
                                         const Function& target_function) {
  switch (old_data.GetClassId()) {
    case kArrayCid:
      // ICData three-element array: Smi(receiver CID), Smi(count),
      // Function(target). It is the Array from ICData::entries_.
      DoMonomorphicMissJIT(old_data, target_function);
      break;
    case kICDataCid:
      DoICDataMissJIT(ICData::Cast(old_data), old_code, target_function);
      break;
    case kMegamorphicCacheCid:
      ASSERT(old_code.ptr() == StubCode::MegamorphicCall().ptr() ||
             (old_code.IsNull() && !should_consider_patching()));
      DoMegamorphicMiss(MegamorphicCache::Cast(old_data), target_function);
      break;
    default:
      UNREACHABLE();
  }
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

static void InlineCacheMissHandler(Thread* thread,
                                   Zone* zone,
                                   const GrowableArray<const Instance*>& args,
                                   const ICData& ic_data,
                                   NativeArguments native_arguments) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  const auto& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const auto& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  PatchableCallHandler handler(thread, args, MissHandler::kInlineCacheMiss,
                               native_arguments, caller_frame, caller_code,
                               caller_function);

  handler.ResolveSwitchAndReturn(ic_data);
#else
  UNREACHABLE();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg, 2) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(1));
  RELEASE_ASSERT(!FLAG_precompiled_mode);
  GrowableArray<const Instance*> args(1);
  args.Add(&receiver);
  InlineCacheMissHandler(thread, zone, args, ic_data, arguments);
}

// Handles inline cache misses by updating the IC data array of the call site.
//   Arg0: Receiver object.
//   Arg1: Argument after receiver.
//   Arg2: IC data object.
//   Returns: target function with compiled code or null.
// Modifies the instance call to hold the updated IC data array.
DEFINE_RUNTIME_ENTRY(InlineCacheMissHandlerTwoArgs, 3) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& other = Instance::CheckedHandle(zone, arguments.ArgAt(1));
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(2));
  RELEASE_ASSERT(!FLAG_precompiled_mode);
  GrowableArray<const Instance*> args(2);
  args.Add(&receiver);
  args.Add(&other);
  InlineCacheMissHandler(thread, zone, args, ic_data, arguments);
}

// Handle the first use of an instance call
//   Arg1: Receiver.
//   Arg0: Stub out.
//   Returns: the ICData used to continue with the call.
DEFINE_RUNTIME_ENTRY(SwitchableCallMiss, 2) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(1));

  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* exit_frame = iterator.NextFrame();
  ASSERT(exit_frame->IsExitFrame());
  StackFrame* miss_handler_frame = iterator.NextFrame();
  // This runtime entry can be called either from miss stub or from
  // switchable_call_miss "dart" stub/function set up in
  // [MegamorphicCacheTable::InitMissHandler].
  ASSERT(miss_handler_frame->IsStubFrame() ||
         miss_handler_frame->IsDartFrame());
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const Function& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  auto& old_data = Object::Handle(zone);
#if defined(DART_PRECOMPILED_RUNTIME)
  old_data =
      CodePatcher::GetSwitchableCallDataAt(caller_frame->pc(), caller_code);
#else
  CodePatcher::GetInstanceCallAt(caller_frame->pc(), caller_code, &old_data);
#endif

  GrowableArray<const Instance*> caller_arguments(1);
  caller_arguments.Add(&receiver);
  PatchableCallHandler handler(thread, caller_arguments,
                               MissHandler::kSwitchableCallMiss, arguments,
                               caller_frame, caller_code, caller_function);
  handler.ResolveSwitchAndReturn(old_data);
}

// Used to find the correct receiver and function to invoke or to fall back to
// invoking noSuchMethod when lazy dispatchers are disabled. Returns the
// result of the invocation or an Error.
static ObjectPtr InvokeCallThroughGetterOrNoSuchMethod(
    Thread* thread,
    Zone* zone,
    const Instance& receiver,
    const String& target_name,
    const Array& orig_arguments,
    const Array& orig_arguments_desc) {
  ASSERT(!FLAG_lazy_dispatchers);
  const bool is_dynamic_call =
      Function::IsDynamicInvocationForwarderName(target_name);
  String& demangled_target_name = String::Handle(zone, target_name.ptr());
  if (is_dynamic_call) {
    demangled_target_name =
        Function::DemangleDynamicInvocationForwarderName(target_name);
  }

  Class& cls = Class::Handle(zone, receiver.clazz());
  Function& function = Function::Handle(zone);

  // Dart distinguishes getters and regular methods and allows their calls
  // to mix with conversions, and its selectors are independent of arity. So do
  // a zigzagged lookup to see if this call failed because of an arity mismatch,
  // need for conversion, or there really is no such method.

  const bool is_getter = Field::IsGetterName(demangled_target_name);
  if (is_getter) {
    // Tear-off of a method
    // o.foo (o.get:foo) failed, closurize o.foo() if it exists.
    const auto& function_name =
        String::Handle(zone, Field::NameFromGetter(demangled_target_name));
    while (!cls.IsNull()) {
      // We don't generate dyn:* forwarders for method extractors so there is no
      // need to try to find a dyn:get:foo first (see assertion below)
      if (function.IsNull()) {
        if (cls.EnsureIsFinalized(thread) == Error::null()) {
          function = Resolver::ResolveDynamicFunction(zone, cls, function_name);
        }
      }
      if (!function.IsNull()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
        ASSERT(!kernel::NeedsDynamicInvocationForwarder(Function::Handle(
            function.GetMethodExtractor(demangled_target_name))));
#endif
        const Function& closure_function =
            Function::Handle(zone, function.ImplicitClosureFunction());
        const Object& result = Object::Handle(
            zone, closure_function.ImplicitInstanceClosure(receiver));
        return result.ptr();
      }
      cls = cls.SuperClass();
    }

    if (receiver.IsRecord()) {
      const Record& record = Record::Cast(receiver);
      const intptr_t field_index =
          record.GetFieldIndexByName(thread, function_name);
      if (field_index >= 0) {
        return record.FieldAt(field_index);
      }
    }

    // Fall through for noSuchMethod
  } else {
    // Call through field.
    // o.foo(...) failed, invoke noSuchMethod is foo exists but has the wrong
    // number of arguments, or try (o.foo).call(...)

    if ((target_name.ptr() == Symbols::call().ptr()) && receiver.IsClosure()) {
      // Special case: closures are implemented with a call getter instead of a
      // call method and with lazy dispatchers the field-invocation-dispatcher
      // would perform the closure call.
      return DartEntry::InvokeClosure(thread, orig_arguments,
                                      orig_arguments_desc);
    }

    // Dynamic call sites have to use the dynamic getter as well (if it was
    // created).
    const auto& getter_name =
        String::Handle(zone, Field::GetterName(demangled_target_name));
    const auto& dyn_getter_name = String::Handle(
        zone, is_dynamic_call
                  ? Function::CreateDynamicInvocationForwarderName(getter_name)
                  : getter_name.ptr());
    ArgumentsDescriptor args_desc(orig_arguments_desc);
    while (!cls.IsNull()) {
      // If there is a function with the target name but mismatched arguments
      // we need to call `receiver.noSuchMethod()`.
      if (cls.EnsureIsFinalized(thread) == Error::null()) {
        function = Resolver::ResolveDynamicFunction(zone, cls, target_name);
      }
      if (!function.IsNull()) {
        ASSERT(!function.AreValidArguments(args_desc, nullptr));
        break;  // mismatch, invoke noSuchMethod
      }
      if (is_dynamic_call) {
        function =
            Resolver::ResolveDynamicFunction(zone, cls, demangled_target_name);
        if (!function.IsNull()) {
          ASSERT(!function.AreValidArguments(args_desc, nullptr));
          break;  // mismatch, invoke noSuchMethod
        }
      }

      // If there is a getter we need to call-through-getter.
      if (is_dynamic_call) {
        function = Resolver::ResolveDynamicFunction(zone, cls, dyn_getter_name);
      }
      if (function.IsNull()) {
        function = Resolver::ResolveDynamicFunction(zone, cls, getter_name);
      }
      if (!function.IsNull()) {
        const Array& getter_arguments = Array::Handle(Array::New(1));
        getter_arguments.SetAt(0, receiver);
        const Object& getter_result = Object::Handle(
            zone, DartEntry::InvokeFunction(function, getter_arguments));
        if (getter_result.IsError()) {
          return getter_result.ptr();
        }
        ASSERT(getter_result.IsNull() || getter_result.IsInstance());

        orig_arguments.SetAt(args_desc.FirstArgIndex(), getter_result);
        return DartEntry::InvokeClosure(thread, orig_arguments,
                                        orig_arguments_desc);
      }
      cls = cls.SuperClass();
    }

    if (receiver.IsRecord()) {
      const Record& record = Record::Cast(receiver);
      const intptr_t field_index =
          record.GetFieldIndexByName(thread, demangled_target_name);
      if (field_index >= 0) {
        const Object& getter_result =
            Object::Handle(zone, record.FieldAt(field_index));
        ASSERT(getter_result.IsNull() || getter_result.IsInstance());
        orig_arguments.SetAt(args_desc.FirstArgIndex(), getter_result);
        return DartEntry::InvokeClosure(thread, orig_arguments,
                                        orig_arguments_desc);
      }
    }
  }

  const Object& result = Object::Handle(
      zone,
      DartEntry::InvokeNoSuchMethod(thread, receiver, demangled_target_name,
                                    orig_arguments, orig_arguments_desc));
  return result.ptr();
}

// Invoke appropriate noSuchMethod or closure from getter.
// Arg0: receiver
// Arg1: ICData or MegamorphicCache
// Arg2: arguments descriptor array
// Arg3: arguments array
DEFINE_RUNTIME_ENTRY(NoSuchMethodFromCallStub, 4) {
  ASSERT(!FLAG_lazy_dispatchers);
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Object& ic_data_or_cache = Object::Handle(zone, arguments.ArgAt(1));
  const Array& orig_arguments_desc =
      Array::CheckedHandle(zone, arguments.ArgAt(2));
  const Array& orig_arguments = Array::CheckedHandle(zone, arguments.ArgAt(3));
  String& target_name = String::Handle(zone);
  if (ic_data_or_cache.IsICData()) {
    target_name = ICData::Cast(ic_data_or_cache).target_name();
  } else {
    ASSERT(ic_data_or_cache.IsMegamorphicCache());
    target_name = MegamorphicCache::Cast(ic_data_or_cache).target_name();
  }

  const auto& result =
      Object::Handle(zone, InvokeCallThroughGetterOrNoSuchMethod(
                               thread, zone, receiver, target_name,
                               orig_arguments, orig_arguments_desc));
  ThrowIfError(result);
  arguments.SetReturn(result);
}

// Invoke appropriate noSuchMethod function.
// Arg0: receiver
// Arg1: function
// Arg1: arguments descriptor array.
// Arg3: arguments array.
DEFINE_RUNTIME_ENTRY(NoSuchMethodFromPrologue, 4) {
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(1));
  const Array& orig_arguments_desc =
      Array::CheckedHandle(zone, arguments.ArgAt(2));
  const Array& orig_arguments = Array::CheckedHandle(zone, arguments.ArgAt(3));

  String& orig_function_name = String::Handle(zone);
  if ((function.kind() == UntaggedFunction::kClosureFunction) ||
      (function.kind() == UntaggedFunction::kImplicitClosureFunction)) {
    // For closure the function name is always 'call'. Replace it with the
    // name of the closurized function so that exception contains more
    // relevant information.
    orig_function_name = function.QualifiedUserVisibleName();
  } else {
    orig_function_name = function.name();
  }

  const Object& result = Object::Handle(
      zone, DartEntry::InvokeNoSuchMethod(thread, receiver, orig_function_name,
                                          orig_arguments, orig_arguments_desc));
  ThrowIfError(result);
  arguments.SetReturn(result);
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
// The following code is used to stress test
//  - deoptimization
//  - debugger stack tracing
//  - garbage collection
//  - hot reload
static void HandleStackOverflowTestCases(Thread* thread) {
  auto isolate = thread->isolate();
  auto isolate_group = thread->isolate_group();

  if (FLAG_shared_slow_path_triggers_gc) {
    isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }

  bool do_deopt = false;
  bool do_stacktrace = false;
  bool do_reload = false;
  bool do_gc = false;
  const intptr_t isolate_reload_every =
      isolate->group()->reload_every_n_stack_overflow_checks();
  if ((FLAG_deoptimize_every > 0) || (FLAG_stacktrace_every > 0) ||
      (FLAG_gc_every > 0) || (isolate_reload_every > 0)) {
    if (!Isolate::IsSystemIsolate(isolate)) {
      // TODO(turnidge): To make --deoptimize_every and
      // --stacktrace-every faster we could move this increment/test to
      // the generated code.
      int32_t count = thread->IncrementAndGetStackOverflowCount();
      if (FLAG_deoptimize_every > 0 && (count % FLAG_deoptimize_every) == 0) {
        do_deopt = true;
      }
      if (FLAG_stacktrace_every > 0 && (count % FLAG_stacktrace_every) == 0) {
        do_stacktrace = true;
      }
      if (FLAG_gc_every > 0 && (count % FLAG_gc_every) == 0) {
        do_gc = true;
      }
      if ((isolate_reload_every > 0) && (count % isolate_reload_every) == 0) {
        do_reload = isolate->group()->CanReload();
      }
    }
  }
  if ((FLAG_deoptimize_filter != nullptr) ||
      (FLAG_stacktrace_filter != nullptr) || (FLAG_reload_every != 0)) {
    DartFrameIterator iterator(thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
    Code& code = Code::Handle();
    Function& function = Function::Handle();
    code = frame->LookupDartCode();
    ASSERT(!code.IsNull());
    function = code.function();
    ASSERT(!function.IsNull());
    const char* function_name = nullptr;
    if ((FLAG_deoptimize_filter != nullptr) ||
        (FLAG_stacktrace_filter != nullptr)) {
      function_name = function.ToFullyQualifiedCString();
      ASSERT(function_name != nullptr);
    }
    if (!code.IsNull()) {
      if (!code.is_optimized() && FLAG_reload_every_optimized) {
        // Don't do the reload if we aren't inside optimized code.
        do_reload = false;
      }
      if (code.is_optimized() && FLAG_deoptimize_filter != nullptr &&
          strstr(function_name, FLAG_deoptimize_filter) != nullptr &&
          !function.ForceOptimize()) {
        OS::PrintErr("*** Forcing deoptimization (%s)\n",
                     function.ToFullyQualifiedCString());
        do_deopt = true;
      }
    }
    if (FLAG_stacktrace_filter != nullptr &&
        strstr(function_name, FLAG_stacktrace_filter) != nullptr) {
      OS::PrintErr("*** Computing stacktrace (%s)\n",
                   function.ToFullyQualifiedCString());
      do_stacktrace = true;
    }
  }
  if (do_deopt) {
    // TODO(turnidge): Consider using DeoptimizeAt instead.
    DeoptimizeFunctionsOnStack();
  }
  if (do_reload) {
    // Maybe adjust the rate of future reloads.
    isolate_group->MaybeIncreaseReloadEveryNStackOverflowChecks();

    // Issue a reload.
    const char* script_uri = isolate_group->source()->script_uri;
    JSONStream js;
    const bool success =
        isolate_group->ReloadSources(&js, /*force_reload=*/true, script_uri);
    if (!success) {
      FATAL("*** Isolate reload failed:\n%s\n", js.ToCString());
    }
  }
  if (do_stacktrace) {
    String& var_name = String::Handle();
    Instance& var_value = Instance::Handle();
    DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
    intptr_t num_frames = stack->Length();
    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = stack->FrameAt(i);
      int num_vars = 0;
      // Variable locations and number are unknown when precompiling.
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (!frame->function().ForceOptimize()) {
        // Ensure that we have unoptimized code.
        frame->function().EnsureHasCompiledUnoptimizedCode();
        num_vars = frame->NumLocalVariables();
      }
#endif
      TokenPosition unused = TokenPosition::kNoSource;
      for (intptr_t v = 0; v < num_vars; v++) {
        frame->VariableAt(v, &var_name, &unused, &unused, &unused, &var_value);
      }
    }
    if (FLAG_stress_async_stacks) {
      DebuggerStackTrace::CollectAsyncCausal();
    }
  }
  if (do_gc) {
    isolate->group()->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
static void HandleOSRRequest(Thread* thread) {
  auto isolate_group = thread->isolate_group();
  ASSERT(isolate_group->use_osr());
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  const Code& code = Code::ZoneHandle(frame->LookupDartCode());
  ASSERT(!code.IsNull());
  ASSERT(!code.is_optimized());
  const Function& function = Function::Handle(code.function());
  ASSERT(!function.IsNull());

  // If the code of the frame does not match the function's unoptimized code,
  // we bail out since the code was reset by an isolate reload.
  if (code.ptr() != function.unoptimized_code()) {
    return;
  }

  // Since the code is referenced from the frame and the ZoneHandle,
  // it cannot have been removed from the function.
  ASSERT(function.HasCode());
  // Don't do OSR on intrinsified functions: The intrinsic code expects to be
  // called like a regular function and can't be entered via OSR.
  if (!Compiler::CanOptimizeFunction(thread, function) ||
      function.is_intrinsic()) {
    return;
  }

  // The unoptimized code is on the stack and should never be detached from
  // the function at this point.
  ASSERT(function.unoptimized_code() != Object::null());
  intptr_t osr_id =
      Code::Handle(function.unoptimized_code()).GetDeoptIdForOsr(frame->pc());
  ASSERT(osr_id != Compiler::kNoOSRDeoptId);
  if (FLAG_trace_osr) {
    OS::PrintErr("Attempting OSR for %s at id=%" Pd ", count=%" Pd "\n",
                 function.ToFullyQualifiedCString(), osr_id,
                 function.usage_counter());
  }

  // Since the code is referenced from the frame and the ZoneHandle,
  // it cannot have been removed from the function.
  const Object& result = Object::Handle(
      Compiler::CompileOptimizedFunction(thread, function, osr_id));
  ThrowIfError(result);

  if (!result.IsNull()) {
    const Code& code = Code::Cast(result);
    uword optimized_entry = code.EntryPoint();
    frame->set_pc(optimized_entry);
    frame->set_pc_marker(code.ptr());
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

DEFINE_RUNTIME_ENTRY(InterruptOrStackOverflow, 0) {
#if defined(USING_SIMULATOR)
  uword stack_pos = Simulator::Current()->get_sp();
  // If simulator was never called it may return 0 as a value of SPREG.
  if (stack_pos == 0) {
    // Use any reasonable value which would not be treated
    // as stack overflow.
    stack_pos = thread->saved_stack_limit();
  }
#else
  uword stack_pos = OSThread::GetCurrentStackPointer();
#endif
  // Always clear the stack overflow flags.  They are meant for this
  // particular stack overflow runtime call and are not meant to
  // persist.
  uword stack_overflow_flags = thread->GetAndClearStackOverflowFlags();

  // If an interrupt happens at the same time as a stack overflow, we
  // process the stack overflow now and leave the interrupt for next
  // time.
  if (!thread->os_thread()->HasStackHeadroom() ||
      IsCalleeFrameOf(thread->saved_stack_limit(), stack_pos)) {
    if (FLAG_verbose_stack_overflow) {
      OS::PrintErr("Stack overflow\n");
      OS::PrintErr("  Native SP = %" Px ", stack limit = %" Px "\n", stack_pos,
                   thread->saved_stack_limit());
      OS::PrintErr("Call stack:\n");
      OS::PrintErr("size | frame\n");
      StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                                StackFrameIterator::kNoCrossThreadIteration);
      uword fp = stack_pos;
      StackFrame* frame = frames.NextFrame();
      while (frame != nullptr) {
        uword delta = (frame->fp() - fp);
        fp = frame->fp();
        OS::PrintErr("%4" Pd " %s\n", delta, frame->ToCString());
        frame = frames.NextFrame();
      }
    }

    // Use the preallocated stack overflow exception to avoid calling
    // into dart code.
    const Instance& exception =
        Instance::Handle(isolate->group()->object_store()->stack_overflow());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  HandleStackOverflowTestCases(thread);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  // Handle interrupts:
  //  - store buffer overflow
  //  - OOB message (vm-service or dart:isolate)
  const Error& error = Error::Handle(thread->HandleInterrupts());
  ThrowIfError(error);

#if !defined(DART_PRECOMPILED_RUNTIME)
  if ((stack_overflow_flags & Thread::kOsrRequest) != 0) {
    HandleOSRRequest(thread);
  }
#else
  ASSERT((stack_overflow_flags & Thread::kOsrRequest) == 0);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

DEFINE_RUNTIME_ENTRY(TraceICCall, 2) {
  const ICData& ic_data = ICData::CheckedHandle(zone, arguments.ArgAt(0));
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(1));
  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  OS::PrintErr(
      "IC call @%#" Px ": ICData: %#" Px " cnt:%" Pd " nchecks: %" Pd " %s\n",
      frame->pc(), static_cast<uword>(ic_data.ptr()), function.usage_counter(),
      ic_data.NumberOfChecks(), function.ToFullyQualifiedCString());
}

// This is called from function that needs to be optimized.
// The requesting function can be already optimized (reoptimization).
// Returns the Code object where to continue execution.
DEFINE_RUNTIME_ENTRY(OptimizeInvokedFunction, 1) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Function& function = Function::CheckedHandle(zone, arguments.ArgAt(0));
  ASSERT(!function.IsNull());
  ASSERT(function.HasCode());

  if (Compiler::CanOptimizeFunction(thread, function)) {
    auto isolate_group = thread->isolate_group();
    if (FLAG_background_compilation) {
      if (isolate_group->background_compiler()->EnqueueCompilation(function)) {
        // Reduce the chance of triggering a compilation while the function is
        // being compiled in the background. INT32_MIN should ensure that it
        // takes long time to trigger a compilation.
        // Note that the background compilation queue rejects duplicate entries.
        function.SetUsageCounter(INT32_MIN);
        // Continue in the same code.
        arguments.SetReturn(function);
        return;
      }
    }

    // Reset usage counter for reoptimization before calling optimizer to
    // prevent recursive triggering of function optimization.
    function.SetUsageCounter(0);
    if (FLAG_trace_compiler || FLAG_trace_optimizing_compiler) {
      if (function.HasOptimizedCode()) {
        THR_Print("ReCompiling function: '%s' \n",
                  function.ToFullyQualifiedCString());
      }
    }
    Object& result = Object::Handle(
        zone, Compiler::CompileOptimizedFunction(thread, function));
    ThrowIfError(result);
  }
  arguments.SetReturn(function);
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
}

// The caller must be a static call in a Dart frame, or an entry frame.
// Patch static call to point to valid code's entry point.
DEFINE_RUNTIME_ENTRY(FixCallersTarget, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  while (frame->IsStubFrame() || frame->IsExitFrame()) {
    frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
  }
  if (frame->IsEntryFrame()) {
    // Since function's current code is always unpatched, the entry frame always
    // calls to unpatched code.
    UNREACHABLE();
  }
  ASSERT(frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, frame->LookupDartCode());
  RELEASE_ASSERT(caller_code.is_optimized());
  const Function& target_function = Function::Handle(
      zone, caller_code.GetStaticCallTargetFunctionAt(frame->pc()));

  const Code& current_target_code =
      Code::Handle(zone, target_function.EnsureHasCode());
  CodePatcher::PatchStaticCallAt(frame->pc(), caller_code, current_target_code);
  caller_code.SetStaticCallTargetCodeAt(frame->pc(), current_target_code);
  if (FLAG_trace_patching) {
    OS::PrintErr(
        "FixCallersTarget: caller %#" Px
        " "
        "target '%s' -> %#" Px " (%s)\n",
        frame->pc(), target_function.ToFullyQualifiedCString(),
        current_target_code.EntryPoint(),
        current_target_code.is_optimized() ? "optimized" : "unoptimized");
  }
  arguments.SetReturn(current_target_code);
#else
  UNREACHABLE();
#endif
}

// The caller must be a monomorphic call from unoptimized code.
// Patch call to point to new target.
DEFINE_RUNTIME_ENTRY(FixCallersTargetMonomorphic, 2) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Instance& receiver = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Array& switchable_call_data =
      Array::CheckedHandle(zone, arguments.ArgAt(1));

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  const auto& caller_code = Code::Handle(zone, caller_frame->LookupDartCode());
  const auto& caller_function =
      Function::Handle(zone, caller_frame->LookupDartFunction());

  GrowableArray<const Instance*> caller_arguments(1);
  caller_arguments.Add(&receiver);
  PatchableCallHandler handler(
      thread, caller_arguments, MissHandler::kFixCallersTargetMonomorphic,
      arguments, caller_frame, caller_code, caller_function);
  handler.ResolveSwitchAndReturn(switchable_call_data);
#else
  UNREACHABLE();
#endif
}

// The caller tried to allocate an instance via an invalidated allocation
// stub.
DEFINE_RUNTIME_ENTRY(FixAllocationStubTarget, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  StackFrameIterator iterator(ValidationPolicy::kDontValidateFrames, thread,
                              StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame != nullptr);
  while (frame->IsStubFrame() || frame->IsExitFrame()) {
    frame = iterator.NextFrame();
    ASSERT(frame != nullptr);
  }
  if (frame->IsEntryFrame()) {
    // There must be a valid Dart frame.
    UNREACHABLE();
  }
  ASSERT(frame->IsDartFrame());
  const Code& caller_code = Code::Handle(zone, frame->LookupDartCode());
  ASSERT(!caller_code.IsNull());
  const Code& stub = Code::Handle(
      CodePatcher::GetStaticCallTargetAt(frame->pc(), caller_code));
  Class& alloc_class = Class::ZoneHandle(zone);
  alloc_class ^= stub.owner();
  Code& alloc_stub = Code::Handle(zone, alloc_class.allocation_stub());
  if (alloc_stub.IsNull()) {
    alloc_stub = StubCode::GetAllocationStubForClass(alloc_class);
    ASSERT(!alloc_stub.IsDisabled());
  }
  CodePatcher::PatchStaticCallAt(frame->pc(), caller_code, alloc_stub);
  caller_code.SetStubCallTargetCodeAt(frame->pc(), alloc_stub);
  if (FLAG_trace_patching) {
    OS::PrintErr("FixAllocationStubTarget: caller %#" Px
                 " alloc-class %s "
                 " -> %#" Px "\n",
                 frame->pc(), alloc_class.ToCString(), alloc_stub.EntryPoint());
  }
  arguments.SetReturn(alloc_stub);
#else
  UNREACHABLE();
#endif
}

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason) {
  switch (deopt_reason) {
#define DEOPT_REASON_TO_TEXT(name)                                             \
  case ICData::kDeopt##name:                                                   \
    return #name;
    DEOPT_REASONS(DEOPT_REASON_TO_TEXT)
#undef DEOPT_REASON_TO_TEXT
    default:
      UNREACHABLE();
      return "";
  }
}

static bool IsSuspendedFrame(Zone* zone,
                             const Function& function,
                             StackFrame* frame) {
  if (!function.IsSuspendableFunction()) {
    return false;
  }
  auto& suspend_state = Object::Handle(
      zone, *reinterpret_cast<ObjectPtr*>(LocalVarAddress(
                frame->fp(), runtime_frame_layout.FrameSlotForVariableIndex(
                                 SuspendState::kSuspendStateVarIndex))));
  return suspend_state.IsSuspendState() &&
         (SuspendState::Cast(suspend_state).pc() != 0);
}

void DeoptimizeAt(Thread* mutator_thread,
                  const Code& optimized_code,
                  StackFrame* frame) {
  ASSERT(optimized_code.is_optimized());

  // Force-optimized code is optimized code which cannot deoptimize and doesn't
  // have unoptimized code to fall back to.
  ASSERT(!optimized_code.is_force_optimized());

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Function& function = Function::Handle(zone, optimized_code.function());
  const Error& error =
      Error::Handle(zone, Compiler::EnsureUnoptimizedCode(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
  const Code& unoptimized_code =
      Code::Handle(zone, function.unoptimized_code());
  ASSERT(!unoptimized_code.IsNull());
  // The switch to unoptimized code may have already occurred.
  if (function.HasOptimizedCode()) {
    function.SwitchToUnoptimizedCode();
  }

  if (IsSuspendedFrame(zone, function, frame)) {
    // Frame is suspended and going to be removed from the stack.
    if (FLAG_trace_deoptimization) {
      THR_Print("Not deoptimizing suspended frame, fp=%" Pp "\n", frame->fp());
    }
  } else if (frame->IsMarkedForLazyDeopt()) {
    // Deopt already scheduled.
    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt already scheduled for fp=%" Pp "\n", frame->fp());
    }
  } else {
    uword deopt_pc = frame->pc();
    ASSERT(optimized_code.ContainsInstructionAt(deopt_pc));

#if defined(DEBUG)
    ValidateFrames();
#endif

    // N.B.: Update the pending deopt table before updating the frame. The
    // profiler may attempt a stack walk in between.
    mutator_thread->pending_deopts().AddPendingDeopt(frame->fp(), deopt_pc);
    frame->MarkForLazyDeopt();

    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt scheduled for fp=%" Pp ", pc=%" Pp "\n",
                frame->fp(), deopt_pc);
    }
  }

  // Mark code as dead (do not GC its embedded objects).
  optimized_code.set_is_alive(false);
}

// Currently checks only that all optimized frames have kDeoptIndex
// and unoptimized code has the kDeoptAfter.
void DeoptimizeFunctionsOnStack() {
  auto thread = Thread::Current();
  // Have to grab program_lock before stopping everybody else.
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  auto isolate_group = thread->isolate_group();
  isolate_group->RunWithStoppedMutators([&]() {
    Code& optimized_code = Code::Handle();
    isolate_group->ForEachIsolate(
        [&](Isolate* isolate) {
          auto mutator_thread = isolate->mutator_thread();
          if (mutator_thread == nullptr) {
            return;
          }
          DartFrameIterator iterator(
              mutator_thread, StackFrameIterator::kAllowCrossThreadIteration);
          StackFrame* frame = iterator.NextFrame();
          while (frame != nullptr) {
            optimized_code = frame->LookupDartCode();
            if (optimized_code.is_optimized() &&
                !optimized_code.is_force_optimized()) {
              DeoptimizeAt(mutator_thread, optimized_code, frame);
            }
            frame = iterator.NextFrame();
          }
        },
        /*at_safepoint=*/true);
  });
}

static void DeoptimizeLastDartFrameIfOptimized() {
  auto thread = Thread::Current();
  // Have to grab program_lock before stopping everybody else.
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());

  auto isolate = thread->isolate();
  auto isolate_group = thread->isolate_group();
  isolate_group->RunWithStoppedMutators([&]() {
    auto mutator_thread = isolate->mutator_thread();
    if (mutator_thread == nullptr) {
      return;
    }
    DartFrameIterator iterator(mutator_thread,
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* frame = iterator.NextFrame();
    if (frame != nullptr) {
      const auto& optimized_code = Code::Handle(frame->LookupDartCode());
      if (optimized_code.is_optimized() &&
          !optimized_code.is_force_optimized()) {
        DeoptimizeAt(mutator_thread, optimized_code, frame);
      }
    }
  });
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static constexpr intptr_t kNumberOfSavedCpuRegisters = kNumberOfCpuRegisters;
static constexpr intptr_t kNumberOfSavedFpuRegisters = kNumberOfFpuRegisters;

static void CopySavedRegisters(uword saved_registers_address,
                               fpu_register_t** fpu_registers,
                               intptr_t** cpu_registers) {
  // Tell MemorySanitizer this region is initialized by generated code. This
  // region isn't already (fully) unpoisoned by FrameSetIterator::Unpoison
  // because it is in an exit frame and stack frame iteration doesn't have
  // access to true SP for exit frames.
  MSAN_UNPOISON(reinterpret_cast<void*>(saved_registers_address),
                kNumberOfSavedFpuRegisters * kFpuRegisterSize +
                    kNumberOfSavedCpuRegisters * kWordSize);

  ASSERT(sizeof(fpu_register_t) == kFpuRegisterSize);
  fpu_register_t* fpu_registers_copy =
      new fpu_register_t[kNumberOfSavedFpuRegisters];
  ASSERT(fpu_registers_copy != nullptr);
  for (intptr_t i = 0; i < kNumberOfSavedFpuRegisters; i++) {
    fpu_registers_copy[i] =
        *reinterpret_cast<fpu_register_t*>(saved_registers_address);
    saved_registers_address += kFpuRegisterSize;
  }
  *fpu_registers = fpu_registers_copy;

  ASSERT(sizeof(intptr_t) == kWordSize);
  intptr_t* cpu_registers_copy = new intptr_t[kNumberOfSavedCpuRegisters];
  ASSERT(cpu_registers_copy != nullptr);
  for (intptr_t i = 0; i < kNumberOfSavedCpuRegisters; i++) {
    cpu_registers_copy[i] =
        *reinterpret_cast<intptr_t*>(saved_registers_address);
    saved_registers_address += kWordSize;
  }
  *cpu_registers = cpu_registers_copy;
}
#endif

DEFINE_LEAF_RUNTIME_ENTRY(bool, TryDoubleAsInteger, 1, Thread* thread) {
  double value = thread->unboxed_double_runtime_arg();
  int64_t int_value = static_cast<int64_t>(value);
  double converted_double = static_cast<double>(int_value);
  if (converted_double != value) {
    return false;
  }
  thread->set_unboxed_int64_runtime_arg(int_value);
  return true;
}
END_LEAF_RUNTIME_ENTRY

// Copies saved registers and caller's frame into temporary buffers.
// Returns the stack size of unoptimized frame.
// The calling code must be optimized, but its function may not have
// have optimized code if the code is OSR code, or if the code was invalidated
// through class loading/finalization or field guard.
DEFINE_LEAF_RUNTIME_ENTRY(intptr_t,
                          DeoptimizeCopyFrame,
                          2,
                          uword saved_registers_address,
                          uword is_lazy_deopt) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  StackZone zone(thread);

  // All registers have been saved below last-fp as if they were locals.
  const uword last_fp =
      saved_registers_address + (kNumberOfSavedCpuRegisters * kWordSize) +
      (kNumberOfSavedFpuRegisters * kFpuRegisterSize) -
      ((runtime_frame_layout.first_local_from_fp + 1) * kWordSize);

  // Get optimized code and frame that need to be deoptimized.
  DartFrameIterator iterator(last_fp, thread,
                             StackFrameIterator::kNoCrossThreadIteration);

  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);
  const Code& optimized_code = Code::Handle(caller_frame->LookupDartCode());
  ASSERT(optimized_code.is_optimized());
  const Function& top_function =
      Function::Handle(thread->zone(), optimized_code.function());
  const bool deoptimizing_code = top_function.HasOptimizedCode();
  if (FLAG_trace_deoptimization) {
    const Function& function = Function::Handle(optimized_code.function());
    THR_Print("== Deoptimizing code for '%s', %s, %s\n",
              function.ToFullyQualifiedCString(),
              deoptimizing_code ? "code & frame" : "frame",
              (is_lazy_deopt != 0u) ? "lazy-deopt" : "");
  }

  if (is_lazy_deopt != 0u) {
    const uword deopt_pc =
        thread->pending_deopts().FindPendingDeopt(caller_frame->fp());

    // N.B.: Update frame before updating pending deopt table. The profiler
    // may attempt a stack walk in between.
    caller_frame->set_pc(deopt_pc);
    ASSERT(caller_frame->pc() == deopt_pc);
    ASSERT(optimized_code.ContainsInstructionAt(caller_frame->pc()));
    thread->pending_deopts().ClearPendingDeoptsAtOrBelow(
        caller_frame->fp(), PendingDeopts::kClearDueToDeopt);
  } else {
    if (FLAG_trace_deoptimization) {
      THR_Print("Eager deopt fp=%" Pp " pc=%" Pp "\n", caller_frame->fp(),
                caller_frame->pc());
    }
  }

  // Copy the saved registers from the stack.
  fpu_register_t* fpu_registers;
  intptr_t* cpu_registers;
  CopySavedRegisters(saved_registers_address, &fpu_registers, &cpu_registers);

  // Create the DeoptContext.
  DeoptContext* deopt_context = new DeoptContext(
      caller_frame, optimized_code, DeoptContext::kDestIsOriginalFrame,
      fpu_registers, cpu_registers, is_lazy_deopt != 0, deoptimizing_code);
  isolate->set_deopt_context(deopt_context);

  // Stack size (FP - SP) in bytes.
  return deopt_context->DestStackAdjustment() * kWordSize;
#else
  UNREACHABLE();
  return 0;
#endif  // !DART_PRECOMPILED_RUNTIME
}
END_LEAF_RUNTIME_ENTRY

// The stack has been adjusted to fit all values for unoptimized frame.
// Fill the unoptimized frame.
DEFINE_LEAF_RUNTIME_ENTRY(void, DeoptimizeFillFrame, 1, uword last_fp) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  StackZone zone(thread);

  DeoptContext* deopt_context = isolate->deopt_context();
  DartFrameIterator iterator(last_fp, thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* caller_frame = iterator.NextFrame();
  ASSERT(caller_frame != nullptr);

#if defined(DEBUG)
  {
    // The code from the deopt_context.
    const Code& code = Code::Handle(deopt_context->code());

    // The code from our frame.
    const Code& optimized_code = Code::Handle(caller_frame->LookupDartCode());
    const Function& function = Function::Handle(optimized_code.function());
    ASSERT(!function.IsNull());

    // The code will be the same as before.
    ASSERT(code.ptr() == optimized_code.ptr());

    // Some sanity checking of the optimized code.
    ASSERT(!optimized_code.IsNull() && optimized_code.is_optimized());
  }
#endif

  deopt_context->set_dest_frame(caller_frame);
  deopt_context->FillDestFrame();

#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
}
END_LEAF_RUNTIME_ENTRY

// This is the last step in the deoptimization, GC can occur.
// Returns number of bytes to remove from the expression stack of the
// bottom-most deoptimized frame. Those arguments were artificially injected
// under return address to keep them discoverable by GC that can occur during
// materialization phase.
DEFINE_RUNTIME_ENTRY(DeoptimizeMaterialize, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DEBUG)
  {
    // We may rendezvous for a safepoint at entry or GC from the allocations
    // below. Check the stack is walkable.
    ValidateFrames();
  }
#endif
  DeoptContext* deopt_context = isolate->deopt_context();
  intptr_t deopt_arg_count = deopt_context->MaterializeDeferredObjects();
  isolate->set_deopt_context(nullptr);
  delete deopt_context;

  // Return value tells deoptimization stub to remove the given number of bytes
  // from the stack.
  arguments.SetReturn(Smi::Handle(Smi::New(deopt_arg_count * kWordSize)));
#else
  UNREACHABLE();
#endif  // !DART_PRECOMPILED_RUNTIME
}

DEFINE_RUNTIME_ENTRY(RewindPostDeopt, 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
#if !defined(PRODUCT)
  isolate->debugger()->RewindPostDeopt();
#endif  // !PRODUCT
#endif  // !DART_PRECOMPILED_RUNTIME
  UNREACHABLE();
}

// Handle slow path actions for the resumed frame after it was
// copied back to the stack:
// 1) deoptimization;
// 2) breakpoint at resumption;
// 3) throwing an exception.
//
// Arg0: exception
// Arg1: stack trace
DEFINE_RUNTIME_ENTRY(ResumeFrame, 2) {
  const Instance& exception = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Instance& stacktrace =
      Instance::CheckedHandle(zone, arguments.ArgAt(1));

#if !defined(DART_PRECOMPILED_RUNTIME)
#if !defined(PRODUCT)
  if (isolate->has_resumption_breakpoints()) {
    isolate->debugger()->ResumptionBreakpoint();
  }
#endif

  DartFrameIterator iterator(thread,
                             StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = iterator.NextFrame();
  ASSERT(frame->IsDartFrame());
  ASSERT(Function::Handle(zone, frame->LookupDartFunction())
             .IsSuspendableFunction());
  const Code& caller_code = Code::Handle(zone, frame->LookupDartCode());
  if (caller_code.IsDisabled() && caller_code.is_optimized() &&
      !caller_code.is_force_optimized()) {
    const uword deopt_pc = frame->pc();
    thread->pending_deopts().AddPendingDeopt(frame->fp(), deopt_pc);
    frame->MarkForLazyDeopt();

    if (FLAG_trace_deoptimization) {
      THR_Print("Lazy deopt scheduled for resumed frame fp=%" Pp ", pc=%" Pp
                "\n",
                frame->fp(), deopt_pc);
    }
  }
#endif

  if (!exception.IsNull()) {
    Exceptions::ReThrow(thread, exception, stacktrace);
  }
}

void OnEveryRuntimeEntryCall(Thread* thread,
                             const char* runtime_call_name,
                             bool can_lazy_deopt) {
  ASSERT(FLAG_deoptimize_on_runtime_call_every > 0);
  if (FLAG_precompiled_mode) {
    return;
  }
  if (IsolateGroup::IsSystemIsolateGroup(thread->isolate_group())) {
    return;
  }
  const bool is_deopt_related =
      strstr(runtime_call_name, "Deoptimize") != nullptr;
  if (is_deopt_related) {
    return;
  }
  // For --deoptimize-on-every-runtime-call we only consider runtime calls that
  // can lazy-deopt.
  if (can_lazy_deopt) {
    if (FLAG_deoptimize_on_runtime_call_name_filter != nullptr &&
        (strlen(runtime_call_name) !=
             strlen(FLAG_deoptimize_on_runtime_call_name_filter) ||
         strstr(runtime_call_name,
                FLAG_deoptimize_on_runtime_call_name_filter) == nullptr)) {
      return;
    }
    const uint32_t count = thread->IncrementAndGetRuntimeCallCount();
    if ((count % FLAG_deoptimize_on_runtime_call_every) == 0) {
      DeoptimizeLastDartFrameIfOptimized();
    }
  }
}

double DartModulo(double left, double right) {
  double remainder = fmod_ieee(left, right);
  if (remainder == 0.0) {
    // We explicitly switch to the positive 0.0 (just in case it was negative).
    remainder = +0.0;
  } else if (remainder < 0.0) {
    if (right < 0) {
      remainder -= right;
    } else {
      remainder += right;
    }
  }
  return remainder;
}

// Update global type feedback recorded for a field recording the assignment
// of the given value.
//   Arg0: Field object;
//   Arg1: Value that is being stored.
DEFINE_RUNTIME_ENTRY(UpdateFieldCid, 2) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  const Object& value = Object::Handle(arguments.ArgAt(1));
  field.RecordStore(value);
#else
  UNREACHABLE();
#endif
}

DEFINE_RUNTIME_ENTRY(InitInstanceField, 2) {
  const Instance& instance = Instance::CheckedHandle(zone, arguments.ArgAt(0));
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(1));
  Object& result = Object::Handle(zone, field.InitializeInstance(instance));
  ThrowIfError(result);
  result = instance.GetField(field);
  ASSERT((result.ptr() != Object::sentinel().ptr()) &&
         (result.ptr() != Object::transition_sentinel().ptr()));
  arguments.SetReturn(result);
}

DEFINE_RUNTIME_ENTRY(InitStaticField, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Object& result = Object::Handle(zone, field.InitializeStatic());
  ThrowIfError(result);
  result = field.StaticValue();
  ASSERT((result.ptr() != Object::sentinel().ptr()) &&
         (result.ptr() != Object::transition_sentinel().ptr()));
  arguments.SetReturn(result);
}

DEFINE_RUNTIME_ENTRY(LateFieldAssignedDuringInitializationError, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowLateFieldAssignedDuringInitialization(
      String::Handle(field.name()));
}

DEFINE_RUNTIME_ENTRY(LateFieldNotInitializedError, 1) {
  const Field& field = Field::CheckedHandle(zone, arguments.ArgAt(0));
  Exceptions::ThrowLateFieldNotInitialized(String::Handle(field.name()));
}

DEFINE_RUNTIME_ENTRY(NotLoaded, 0) {
  // We could just use a trap instruction in the stub, but we get better stack
  // traces when there is an exit frame.
  FATAL("Not loaded");
}

// Use expected function signatures to help MSVC compiler resolve overloading.
typedef double (*UnaryMathCFunction)(double x);
typedef double (*BinaryMathCFunction)(double x, double y);

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcPow,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<BinaryMathCFunction>(&pow)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    DartModulo,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(
        static_cast<BinaryMathCFunction>(&DartModulo)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAtan2,
    2,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(
        static_cast<BinaryMathCFunction>(&atan2_ieee)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcFloor,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&floor)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcCeil,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&ceil)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcTrunc,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&trunc)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcRound,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&round)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcCos,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&cos)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcSin,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&sin)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAsin,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&asin)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAcos,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&acos)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcTan,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&tan)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcAtan,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&atan)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcExp,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&exp)));

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    LibcLog,
    1,
    true /* is_float */,
    reinterpret_cast<RuntimeFunction>(static_cast<UnaryMathCFunction>(&log)));

extern "C" void DFLRT_EnterSafepoint(NativeArguments __unusable_) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("%s", "EnterSafepoint");
  Thread* thread = Thread::Current();
  ASSERT(thread->top_exit_frame_info() != 0);
  ASSERT(thread->execution_state() == Thread::kThreadInNative);
  thread->EnterSafepoint();
  TRACE_RUNTIME_CALL("%s", "EnterSafepoint done");
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(EnterSafepoint, 0, false, &DFLRT_EnterSafepoint);

extern "C" void DFLRT_ExitSafepoint(NativeArguments __unusable_) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("%s", "ExitSafepoint");
  Thread* thread = Thread::Current();
  ASSERT(thread->top_exit_frame_info() != 0);

  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  if (thread->is_unwind_in_progress()) {
    // Clean up safepoint unwind error marker to prevent safepoint tripping.
    // The safepoint marker will get restored just before jumping back
    // to generated code.
    thread->SetUnwindErrorInProgress(false);
    NoSafepointScope no_safepoint;
    Error unwind_error;
    unwind_error ^=
        thread->isolate()->isolate_object_store()->preallocated_unwind_error();
    Exceptions::PropagateError(unwind_error);
  }
  thread->ExitSafepoint();

  TRACE_RUNTIME_CALL("%s", "ExitSafepoint done");
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(ExitSafepoint, 0, false, &DFLRT_ExitSafepoint);

// This is expected to be invoked when jumping to destination frame,
// during exception handling.
extern "C" void DFLRT_ExitSafepointIgnoreUnwindInProgress(
    NativeArguments __unusable_) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("%s", "ExitSafepointIgnoreUnwindInProgress");
  Thread* thread = Thread::Current();
  ASSERT(thread->top_exit_frame_info() != 0);

  ASSERT(thread->execution_state() == Thread::kThreadInVM);

  // Compared to ExitSafepoint above we are going to ignore
  // is_unwind_in_progress flag because this is called as part of JumpToFrame
  // exception handler - we want this transition to complete so that the next
  // safepoint check does error propagation.
  thread->ExitSafepoint();

  TRACE_RUNTIME_CALL("%s", "ExitSafepointIgnoreUnwindInProgress done");
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(ExitSafepointIgnoreUnwindInProgress,
                              0,
                              false,
                              &DFLRT_ExitSafepointIgnoreUnwindInProgress);

#if defined(DART_HOST_OS_WINDOWS)
#pragma intrinsic(_ReturnAddress)
#endif

// This is called by a native callback trampoline
// (see StubCodeCompiler::GenerateFfiCallbackTrampolineStub). Not registered as
// a runtime entry because we can't use Thread to look it up.
extern "C" Thread* DLRT_GetFfiCallbackMetadata(
    FfiCallbackMetadata::Trampoline trampoline,
    uword* out_entry_point,
    uword* out_trampoline_type) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("GetFfiCallbackMetadata %p",
                     reinterpret_cast<void*>(trampoline));

  auto metadata =
      FfiCallbackMetadata::Instance()->LookupMetadataForTrampoline(trampoline);
  if (!metadata.IsLive()) {
    FATAL("Callback invoked after it has been deleted.");
  }

  Isolate* target_isolate = metadata.target_isolate();
  ASSERT(out_entry_point != nullptr);
  *out_entry_point = metadata.target_entry_point();
  ASSERT(out_trampoline_type != nullptr);
  *out_trampoline_type = static_cast<uword>(metadata.trampoline_type());

  Thread* const thread = Thread::Current();
  if (thread == nullptr) {
    FATAL("Cannot invoke native callback outside an isolate.");
  }
  if (thread->no_callback_scope_depth() != 0) {
    FATAL("Cannot invoke native callback when API callbacks are prohibited.");
  }
  if (thread->is_unwind_in_progress()) {
    FATAL("Cannot invoke native callback while unwind error propagates.");
  }
  if (!thread->IsDartMutatorThread()) {
    FATAL("Native callbacks must be invoked on the mutator thread.");
  }
  if (thread->isolate() != target_isolate) {
    FATAL("Cannot invoke native callback from a different isolate.");
  }

  // Set the execution state to VM while waiting for the safepoint to end.
  // This isn't strictly necessary but enables tests to check that we're not
  // in native code anymore. See tests/ffi/function_gc_test.dart for example.
  thread->set_execution_state(Thread::kThreadInVM);

  thread->ExitSafepoint();

  TRACE_RUNTIME_CALL("GetFfiCallbackMetadata thread %p", thread);
  TRACE_RUNTIME_CALL("GetFfiCallbackMetadata entry_point %p",
                     (void*)*out_entry_point);
  TRACE_RUNTIME_CALL("GetFfiCallbackMetadata trampoline_type %p",
                     (void*)*out_trampoline_type);
  return thread;
}

extern "C" ApiLocalScope* DLRT_EnterHandleScope(Thread* thread) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("EnterHandleScope %p", thread);
  thread->EnterApiScope();
  ApiLocalScope* return_value = thread->api_top_scope();
  TRACE_RUNTIME_CALL("EnterHandleScope returning %p", return_value);
  return return_value;
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    EnterHandleScope,
    1,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&DLRT_EnterHandleScope));

extern "C" void DLRT_ExitHandleScope(Thread* thread) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("ExitHandleScope %p", thread);
  thread->ExitApiScope();
  TRACE_RUNTIME_CALL("ExitHandleScope %s", "done");
}
DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    ExitHandleScope,
    1,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&DLRT_ExitHandleScope));

extern "C" LocalHandle* DLRT_AllocateHandle(ApiLocalScope* scope) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("AllocateHandle %p", scope);
  LocalHandle* return_value = scope->local_handles()->AllocateHandle();
  // Don't return an uninitialised handle.
  return_value->set_ptr(Object::sentinel().ptr());
  TRACE_RUNTIME_CALL("AllocateHandle returning %p", return_value);
  return return_value;
}

DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    AllocateHandle,
    1,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&DLRT_AllocateHandle));

// Enables reusing `Dart_PropagateError` from `FfiCallInstr`.
// `Dart_PropagateError` requires the native state and transitions into the VM.
// So the flow is:
// - FfiCallInstr (slow path)
// - TransitionGeneratedToNative
// - DLRT_PropagateError (this)
// - Dart_PropagateError
// - TransitionNativeToVM
// - Throw
extern "C" void DLRT_PropagateError(Dart_Handle handle) {
  CHECK_STACK_ALIGNMENT;
  TRACE_RUNTIME_CALL("PropagateError %p", handle);
  ASSERT(Thread::Current()->execution_state() == Thread::kThreadInNative);
  ASSERT(Dart_IsError(handle));
  Dart_PropagateError(handle);
  // We should never exit through normal control flow.
  UNREACHABLE();
}

// Not a leaf-function, throws error.
DEFINE_RAW_LEAF_RUNTIME_ENTRY(
    PropagateError,
    1,
    false /* is_float */,
    reinterpret_cast<RuntimeFunction>(&DLRT_PropagateError));

#if defined(USING_MEMORY_SANITIZER)
#define MSAN_UNPOISON_RANGE reinterpret_cast<RuntimeFunction>(&__msan_unpoison)
#define MSAN_UNPOISON_PARAM                                                    \
  reinterpret_cast<RuntimeFunction>(&__msan_unpoison_param)
#else
#define MSAN_UNPOISON_RANGE nullptr
#define MSAN_UNPOISON_PARAM nullptr
#endif

#if defined(USING_THREAD_SANITIZER)
#define TSAN_ACQUIRE reinterpret_cast<RuntimeFunction>(&__tsan_acquire)
#define TSAN_RELEASE reinterpret_cast<RuntimeFunction>(&__tsan_release)
#else
#define TSAN_ACQUIRE nullptr
#define TSAN_RELEASE nullptr
#endif

// These runtime entries are defined even when not using MSAN / TSAN to keep
// offsets on Thread consistent.

DEFINE_RAW_LEAF_RUNTIME_ENTRY(MsanUnpoison,
                              /*argument_count=*/2,
                              /*is_float=*/false,
                              MSAN_UNPOISON_RANGE);

DEFINE_RAW_LEAF_RUNTIME_ENTRY(MsanUnpoisonParam,
                              /*argument_count=*/1,
                              /*is_float=*/false,
                              MSAN_UNPOISON_PARAM);

DEFINE_RAW_LEAF_RUNTIME_ENTRY(TsanLoadAcquire,
                              /*argument_count=*/1,
                              /*is_float=*/false,
                              TSAN_ACQUIRE);

DEFINE_RAW_LEAF_RUNTIME_ENTRY(TsanStoreRelease,
                              /*argument_count=*/1,
                              /*is_float=*/false,
                              TSAN_RELEASE);

}  // namespace dart
