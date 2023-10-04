// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/aot/precompiler.h"

#include <memory>

#include "platform/unicode.h"
#include "platform/utils.h"
#include "vm/canonical_tables.h"
#include "vm/class_finalizer.h"
#include "vm/closure_functions_cache.h"
#include "vm/code_patcher.h"
#include "vm/compiler/aot/aot_call_specializer.h"
#include "vm/compiler/aot/precompiler_tracer.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/branch_optimizer.h"
#include "vm/compiler/backend/constant_propagator.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/backend/redundancy_elimination.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/compiler_timings.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/ffi/native_assets.h"
#include "vm/flags.h"
#include "vm/hash_table.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/program_visitor.h"
#include "vm/regexp_assembler.h"
#include "vm/regexp_parser.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/stack_trace.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/type_testing_stubs.h"
#include "vm/version.h"
#include "vm/zone_text_buffer.h"

namespace dart {

#define T (thread())
#define IG (isolate_group())
#define Z (zone())

DEFINE_FLAG(bool,
            print_precompiler_timings,
            false,
            "Print per-phase breakdown of time spent precompiling");
DEFINE_FLAG(bool, print_unique_targets, false, "Print unique dynamic targets");
DEFINE_FLAG(charp,
            print_object_layout_to,
            nullptr,
            "Print layout of Dart objects to the given file");
DEFINE_FLAG(bool, trace_precompiler, false, "Trace precompiler.");
DEFINE_FLAG(
    int,
    max_speculative_inlining_attempts,
    1,
    "Max number of attempts with speculative inlining (precompilation only)");
DEFINE_FLAG(charp,
            write_retained_reasons_to,
            nullptr,
            "Print reasons for retaining objects to the given file");

DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, trace_optimizing_compiler);
DECLARE_FLAG(bool, trace_bailout);
DECLARE_FLAG(bool, trace_failed_optimization_attempts);
DECLARE_FLAG(bool, trace_inlining_intervals);
DECLARE_FLAG(int, inlining_hotness);
DECLARE_FLAG(int, inlining_size_threshold);
DECLARE_FLAG(int, inlining_callee_size_threshold);
DECLARE_FLAG(int, inline_getters_setters_smaller_than);
DECLARE_FLAG(int, inlining_depth_threshold);
DECLARE_FLAG(int, inlining_caller_size_threshold);
DECLARE_FLAG(int, inlining_constant_arguments_max_size_threshold);
DECLARE_FLAG(int, inlining_constant_arguments_min_size_threshold);
DECLARE_FLAG(bool, print_instruction_stats);

Precompiler* Precompiler::singleton_ = nullptr;

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

// Reasons for retaining a given object.
struct RetainReasons : public AllStatic {
  // The LLVM pools are active and the object appears in one of them.
  static constexpr const char* kLLVMPool = "llvm pool";
  // The object is an invoke field dispatcher.
  static constexpr const char* kInvokeFieldDispatcher =
      "invoke field dispatcher";
  // The object is a dynamic invocation forwarder.
  static constexpr const char* kDynamicInvocationForwarder =
      "dynamic invocation forwarder";
  // The object is a method extractor.
  static constexpr const char* kMethodExtractor = "method extractor";
  // The object is for a compiled implicit closure.
  static constexpr const char* kImplicitClosure = "implicit closure";
  // The object is a local closure.
  static constexpr const char* kLocalClosure = "local closure";
  // The object is needed for async stack unwinding.
  static constexpr const char* kAsyncStackUnwinding =
      "needed for async stack unwinding";
  // The object is the initializer for a static field.
  static constexpr const char* kStaticFieldInitializer =
      "static field initializer";
  // The object is the initializer for a instance field.
  static constexpr const char* kInstanceFieldInitializer =
      "instance field initializer";
  // The object is the initializer for a late field.
  static constexpr const char* kLateFieldInitializer = "late field initializer";
  // The object is an implicit getter.
  static constexpr const char* kImplicitGetter = "implicit getter";
  // The object is an implicit setter.
  static constexpr const char* kImplicitSetter = "implicit setter";
  // The object is an implicit static getter.
  static constexpr const char* kImplicitStaticGetter = "implicit static getter";
  // The object is a function that is called through a getter method.
  static constexpr const char* kCalledThroughGetter = "called through getter";
  // The object is a function that is called via selector.
  static constexpr const char* kCalledViaSelector = "called via selector";
  // The object is a function and the flag --retain-function-objects is enabled.
  static constexpr const char* kForcedRetain = "forced via flag";
  // The object is a function and symbolic stack traces are enabled.
  static constexpr const char* kSymbolicStackTraces =
      "needed for symbolic stack traces";
  // The object is a parent function of a non-inlined local function.
  static constexpr const char* kLocalParent = "parent of a local function";
  // The object is a main function of the root library.
  static constexpr const char* kMainFunction =
      "this is main function of the root library";
  // The object has an entry point pragma that requires it be retained.
  static constexpr const char* kEntryPointPragma = "entry point pragma";
  // The function is a target of FFI callback.
  static constexpr const char* kFfiCallbackTarget = "ffi callback target";
  // The signature is used in a closure function.
  static constexpr const char* kClosureSignature = "closure signature";
  // The signature is used in an FFI trampoline.
  static constexpr const char* kFfiTrampolineSignature =
      "FFI trampoline signature";
  // The signature is used in a native function.
  static constexpr const char* kNativeSignature = "native function signature";
  // The signature has required named parameters.
  static constexpr const char* kRequiredNamedParameters =
      "signature has required named parameters";
  // The signature is used in a function that has dynamic calls.
  static constexpr const char* kDynamicallyCalledSignature =
      "signature of dynamically called function";
  // The signature is used in a function with an entry point pragma.
  static constexpr const char* kEntryPointPragmaSignature =
      "signature of entry point function";
};

class RetainedReasonsWriter : public ValueObject {
 public:
  explicit RetainedReasonsWriter(Zone* zone)
      : zone_(zone), retained_reasons_map_(zone) {}

  bool Init(const char* filename) {
    if (filename == nullptr) return false;

    if ((Dart::file_write_callback() == nullptr) ||
        (Dart::file_open_callback() == nullptr) ||
        (Dart::file_close_callback() == nullptr)) {
      OS::PrintErr("warning: Could not access file callbacks.");
      return false;
    }

    void* file = Dart::file_open_callback()(filename, /*write=*/true);
    if (file == nullptr) {
      OS::PrintErr("warning: Failed to write retained reasons: %s\n", filename);
      return false;
    }

    file_ = file;
    // We open the array here so that we can also print some objects to the
    // JSON as we go, instead of requiring all information be collected
    // and printed at one point. This avoids having to keep otherwise
    // unneeded information around.
    writer_.OpenArray();
    return true;
  }

  void AddDropped(const Object& obj) {
    if (HasReason(obj)) {
      FATAL("dropped object has reasons to retain");
    }
    writer_.OpenObject();
    WriteRetainedObjectSpecificFields(obj);
    writer_.PrintPropertyBool("retained", false);
    writer_.CloseObject();
  }

  bool HasReason(const Object& obj) const {
    return retained_reasons_map_.HasKey(&obj);
  }

  void AddReason(const Object& obj, const char* reason) {
    if (auto const kv = retained_reasons_map_.Lookup(&obj)) {
      if (kv->value->Lookup(reason) == nullptr) {
        kv->value->Insert(reason);
      }
      return;
    }
    auto const key = &Object::ZoneHandle(zone_, obj.ptr());
    auto const value = new (zone_) ZoneCStringSet(zone_);
    value->Insert(reason);
    retained_reasons_map_.Insert(RetainedReasonsTrait::Pair(key, value));
  }

  // Finalizes the JSON output and writes it.
  void Write() {
    if (file_ == nullptr) return;

    // Add all the objects for which we have reasons to retain.
    auto it = retained_reasons_map_.GetIterator();

    for (auto kv = it.Next(); kv != nullptr; kv = it.Next()) {
      writer_.OpenObject();
      WriteRetainedObjectSpecificFields(*kv->key);
      writer_.PrintPropertyBool("retained", true);

      writer_.OpenArray("reasons");
      auto it = kv->value->GetIterator();
      for (auto cstrp = it.Next(); cstrp != nullptr; cstrp = it.Next()) {
        ASSERT(*cstrp != nullptr);
        writer_.PrintValue(*cstrp);
      }
      writer_.CloseArray();

      writer_.CloseObject();
    }

    writer_.CloseArray();
    char* output = nullptr;
    intptr_t length = -1;
    writer_.Steal(&output, &length);

    if (const auto file_write = Dart::file_write_callback()) {
      file_write(output, length, file_);
    }

    if (const auto file_close = Dart::file_close_callback()) {
      file_close(file_);
    }

    free(output);
  }

 private:
  struct RetainedReasonsTrait {
    using Key = const Object*;
    using Value = ZoneCStringSet*;

    struct Pair {
      Key key;
      Value value;

      Pair() : key(nullptr), value(nullptr) {}
      Pair(Key key, Value value) : key(key), value(value) {}
    };

    static Key KeyOf(Pair kv) { return kv.key; }

    static Value ValueOf(Pair kv) { return kv.value; }

    static inline uword Hash(Key key) {
      if (key->IsFunction()) {
        return Function::Cast(*key).Hash();
      }
      if (key->IsClass()) {
        return Utils::WordHash(Class::Cast(*key).id());
      }
      if (key->IsAbstractType()) {
        return AbstractType::Cast(*key).Hash();
      }
      return Utils::WordHash(key->GetClassId());
    }

    static inline bool IsKeyEqual(Pair pair, Key key) {
      return pair.key->ptr() == key->ptr();
    }
  };

  using RetainedReasonsMap = DirectChainedHashMap<RetainedReasonsTrait>;

  void WriteRetainedObjectSpecificFields(const Object& obj) {
    if (obj.IsFunction()) {
      writer_.PrintProperty("type", "Function");
      const auto& function = Function::Cast(obj);
      writer_.PrintProperty("name",
                            function.ToLibNamePrefixedQualifiedCString());
      writer_.PrintProperty("kind",
                            UntaggedFunction::KindToCString(function.kind()));
      return;
    } else if (obj.IsFunctionType()) {
      writer_.PrintProperty("type", "FunctionType");
      const auto& sig = FunctionType::Cast(obj);
      writer_.PrintProperty("name", sig.ToCString());
      return;
    }
    FATAL("Unexpected object %s", obj.ToCString());
  }

  Zone* const zone_;
  RetainedReasonsMap retained_reasons_map_;
  JSONWriter writer_;
  void* file_;
};

class PrecompileParsedFunctionHelper : public ValueObject {
 public:
  PrecompileParsedFunctionHelper(Precompiler* precompiler,
                                 ParsedFunction* parsed_function,
                                 bool optimized)
      : precompiler_(precompiler),
        parsed_function_(parsed_function),
        optimized_(optimized),
        thread_(Thread::Current()) {}

  bool Compile(CompilationPipeline* pipeline);

 private:
  ParsedFunction* parsed_function() const { return parsed_function_; }
  bool optimized() const { return optimized_; }
  Thread* thread() const { return thread_; }

  void FinalizeCompilation(compiler::Assembler* assembler,
                           FlowGraphCompiler* graph_compiler,
                           FlowGraph* flow_graph,
                           CodeStatistics* stats);

  Precompiler* precompiler_;
  ParsedFunction* parsed_function_;
  const bool optimized_;
  Thread* const thread_;

  DISALLOW_COPY_AND_ASSIGN(PrecompileParsedFunctionHelper);
};

static void Jump(const Error& error) {
  Thread::Current()->long_jump_base()->Jump(1, error);
}

ErrorPtr Precompiler::CompileAll() {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Precompiler precompiler(Thread::Current());
    precompiler.DoCompileAll();
    precompiler.ReportStats();
    return Error::null();
  } else {
    return Thread::Current()->StealStickyError();
  }
}

void Precompiler::ReportStats() {
  if (!FLAG_print_precompiler_timings) {
    return;
  }

  thread()->compiler_timings()->Print();
}

Precompiler::Precompiler(Thread* thread)
    : thread_(thread),
      zone_(nullptr),
      changed_(false),
      retain_root_library_caches_(false),
      function_count_(0),
      class_count_(0),
      selector_count_(0),
      dropped_function_count_(0),
      dropped_field_count_(0),
      dropped_class_count_(0),
      dropped_typearg_count_(0),
      dropped_type_count_(0),
      dropped_functiontype_count_(0),
      dropped_typeparam_count_(0),
      dropped_library_count_(0),
      dropped_constants_arrays_entries_count_(0),
      libraries_(GrowableObjectArray::Handle(
          thread->isolate_group()->object_store()->libraries())),
      pending_functions_(
          GrowableObjectArray::Handle(GrowableObjectArray::New())),
      sent_selectors_(),
      functions_called_dynamically_(
          HashTables::New<FunctionSet>(/*initial_capacity=*/1024)),
      functions_with_entry_point_pragmas_(
          HashTables::New<FunctionSet>(/*initial_capacity=*/1024)),
      seen_functions_(HashTables::New<FunctionSet>(/*initial_capacity=*/1024)),
      possibly_retained_functions_(
          HashTables::New<FunctionSet>(/*initial_capacity=*/1024)),
      fields_to_retain_(),
      functions_to_retain_(
          HashTables::New<FunctionSet>(/*initial_capacity=*/1024)),
      classes_to_retain_(),
      typeargs_to_retain_(),
      types_to_retain_(),
      functiontypes_to_retain_(),
      typeparams_to_retain_(),
      consts_to_retain_(),
      seen_table_selectors_(),
      api_uses_(),
      error_(Error::Handle()),
      get_runtime_type_is_unique_(false) {
  ASSERT(Precompiler::singleton_ == nullptr);
  Precompiler::singleton_ = this;

  if (FLAG_print_precompiler_timings) {
    thread->set_compiler_timings(new CompilerTimings());
  }
}

Precompiler::~Precompiler() {
  // We have to call Release() in DEBUG mode.
  functions_called_dynamically_.Release();
  functions_with_entry_point_pragmas_.Release();
  seen_functions_.Release();
  possibly_retained_functions_.Release();
  functions_to_retain_.Release();

  ASSERT(Precompiler::singleton_ == this);
  Precompiler::singleton_ = nullptr;

  delete thread()->compiler_timings();
  thread()->set_compiler_timings(nullptr);
}

void Precompiler::DoCompileAll() {
  PRECOMPILER_TIMER_SCOPE(this, CompileAll);
  {
    StackZone stack_zone(T);
    zone_ = stack_zone.GetZone();
    RetainedReasonsWriter reasons_writer(zone_);

    if (reasons_writer.Init(FLAG_write_retained_reasons_to)) {
      retained_reasons_writer_ = &reasons_writer;
    }

    // Since we keep the object pool until the end of AOT compilation, it
    // will hang on to its entries until the very end. Therefore we have
    // to use handles which survive that long, so we use [zone_] here.
    global_object_pool_builder_.InitializeWithZone(zone_);

    {
      HANDLESCOPE(T);

      // Make sure class hierarchy is stable before compilation so that CHA
      // can be used. Also ensures lookup of entry points won't miss functions
      // because their class hasn't been finalized yet.
      FinalizeAllClasses();
      ASSERT(Error::Handle(Z, T->sticky_error()).IsNull());

      if (FLAG_print_object_layout_to != nullptr) {
        IG->class_table()->PrintObjectLayout(FLAG_print_object_layout_to);
      }

      ClassFinalizer::SortClasses();

      // Collects type usage information which allows us to decide when/how to
      // optimize runtime type tests.
      TypeUsageInfo type_usage_info(T);

      // The cid-ranges of subclasses of a class are e.g. used for is/as checks
      // as well as other type checks.
      HierarchyInfo hierarchy_info(T);

      dispatch_table_generator_ = new compiler::DispatchTableGenerator(Z);
      dispatch_table_generator_->Initialize(IG->class_table());

      // After finding all code, and before starting to trace, populate the
      // assets map.
      GetNativeAssetsMap(T);

      // Precompile constructors to compute information such as
      // optimized instruction count (used in inlining heuristics).
      ClassFinalizer::ClearAllCode(
          /*including_nonchanging_cids=*/true);

      {
        CompilerState state(thread_, /*is_aot=*/true, /*is_optimizing=*/true);
        PrecompileConstructors();
      }

      ClassFinalizer::ClearAllCode(
          /*including_nonchanging_cids=*/true);

      tracer_ = PrecompilerTracer::StartTracingIfRequested(this);

      // All stubs have already been generated, all of them share the same pool.
      // We use that pool to initialize our global object pool, to guarantee
      // stubs as well as code compiled from here on will have the same pool.
      {
        // We use any stub here to get it's object pool (all stubs share the
        // same object pool in bare instructions mode).
        const Code& code = StubCode::LazyCompile();
        const ObjectPool& stub_pool = ObjectPool::Handle(code.object_pool());

        global_object_pool_builder()->Reset();
        stub_pool.CopyInto(global_object_pool_builder());

        // We have various stubs we would like to generate inside the isolate,
        // to ensure the rest of the AOT compilation will use the
        // isolate-specific stubs (callable via pc-relative calls).
        auto& stub_code = Code::Handle();
#define DO(member, name)                                                       \
  stub_code = StubCode::BuildIsolateSpecific##name##Stub(                      \
      global_object_pool_builder());                                           \
  IG->object_store()->set_##member(stub_code);
        OBJECT_STORE_STUB_CODE_LIST(DO)
#undef DO

        {
          SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
          stub_code = StubCode::GetBuildGenericMethodExtractorStub(
              global_object_pool_builder());
        }
        IG->object_store()->set_build_generic_method_extractor_code(stub_code);

        {
          SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
          stub_code = StubCode::GetBuildNonGenericMethodExtractorStub(
              global_object_pool_builder());
        }
        IG->object_store()->set_build_nongeneric_method_extractor_code(
            stub_code);
      }

      CollectDynamicFunctionNames();

      // Start with the allocations and invocations that happen from C++.
      {
        TracingScope scope(this);
        AddRoots();
        AddAnnotatedRoots();
      }

      // With the nnbd experiment enabled, these non-nullable type arguments may
      // not be retained, although they will be used and expected to be
      // canonical by Dart_NewListOfType.
      AddTypeArguments(
          TypeArguments::Handle(Z, IG->object_store()->type_argument_int()));
      AddTypeArguments(
          TypeArguments::Handle(Z, IG->object_store()->type_argument_double()));
      AddTypeArguments(
          TypeArguments::Handle(Z, IG->object_store()->type_argument_string()));
      AddTypeArguments(TypeArguments::Handle(
          Z, IG->object_store()->type_argument_string_dynamic()));
      AddTypeArguments(TypeArguments::Handle(
          Z, IG->object_store()->type_argument_string_string()));

      // Compile newly found targets and add their callees until we reach a
      // fixed point.
      Iterate();

      // Replace the default type testing stubs installed on [Type]s with new
      // [Type]-specialized stubs.
      AttachOptimizedTypeTestingStub();

      {
        // Now we generate the actual object pool instance and attach it to the
        // object store. The AOT runtime will use it from there in the enter
        // dart code stub.
        const auto& pool = ObjectPool::Handle(
            ObjectPool::NewFromBuilder(*global_object_pool_builder()));
        IG->object_store()->set_global_object_pool(pool);
        global_object_pool_builder()->Reset();

        if (FLAG_disassemble) {
          THR_Print("Global object pool:\n");
          pool.DebugPrint();
        }
      }

      if (tracer_ != nullptr) {
        tracer_->Finalize();
        tracer_ = nullptr;
      }

      {
        PRECOMPILER_TIMER_SCOPE(this, TraceForRetainedFunctions);
        TraceForRetainedFunctions();
      }

      FinalizeDispatchTable();
      ReplaceFunctionStaticCallEntries();

      {
        PRECOMPILER_TIMER_SCOPE(this, Drop);

        DropFunctions();
        DropFields();
        DropTransitiveUserDefinedConstants();
        TraceTypesFromRetainedClasses();

        // Clear these before dropping classes as they may hold onto otherwise
        // dead instances of classes we will remove or otherwise unused symbols.
        IG->object_store()->set_unique_dynamic_targets(Array::null_array());
        Library& null_library = Library::Handle(Z);
        Class& null_class = Class::Handle(Z);
        Function& null_function = Function::Handle(Z);
        Field& null_field = Field::Handle(Z);
        IG->object_store()->set_pragma_class(null_class);
        IG->object_store()->set_pragma_name(null_field);
        IG->object_store()->set_pragma_options(null_field);
        IG->object_store()->set_compiletime_error_class(null_class);
        IG->object_store()->set_growable_list_factory(null_function);
        IG->object_store()->set_simple_instance_of_function(null_function);
        IG->object_store()->set_simple_instance_of_true_function(null_function);
        IG->object_store()->set_simple_instance_of_false_function(
            null_function);
        IG->object_store()->set_async_star_stream_controller(null_class);
        IG->object_store()->set_native_assets_library(null_library);
        DropMetadata();
        DropLibraryEntries();
      }
    }

    {
      PRECOMPILER_TIMER_SCOPE(this, Drop);
      DropClasses();
      DropLibraries();
    }

    {
      PRECOMPILER_TIMER_SCOPE(this, Obfuscate);
      Obfuscate();
    }

#if defined(DEBUG)
    const auto& non_visited =
        Function::Handle(Z, FindUnvisitedRetainedFunction());
    if (!non_visited.IsNull()) {
      FATAL("Code visitor would miss the code for function \"%s\"\n",
            non_visited.ToFullyQualifiedCString());
    }
#endif
    DiscardCodeObjects();

    {
      PRECOMPILER_TIMER_SCOPE(this, Dedup);
      ProgramVisitor::Dedup(T);
    }

    PruneDictionaries();

    if (retained_reasons_writer_ != nullptr) {
      reasons_writer.Write();
      retained_reasons_writer_ = nullptr;
    }

    zone_ = nullptr;
  }

  intptr_t symbols_before = -1;
  intptr_t symbols_after = -1;
  intptr_t capacity = -1;
  if (FLAG_trace_precompiler) {
    Symbols::GetStats(IG, &symbols_before, &capacity);
  }

  if (FLAG_trace_precompiler) {
    Symbols::GetStats(IG, &symbols_after, &capacity);
    THR_Print("Precompiled %" Pd " functions,", function_count_);
    THR_Print(" %" Pd " dynamic types,", class_count_);
    THR_Print(" %" Pd " dynamic selectors.\n", selector_count_);

    THR_Print("Dropped %" Pd " functions,", dropped_function_count_);
    THR_Print(" %" Pd " fields,", dropped_field_count_);
    THR_Print(" %" Pd " symbols,", symbols_before - symbols_after);
    THR_Print(" %" Pd " types,", dropped_type_count_);
    THR_Print(" %" Pd " function types,", dropped_functiontype_count_);
    THR_Print(" %" Pd " type parameters,", dropped_typeparam_count_);
    THR_Print(" %" Pd " type arguments,", dropped_typearg_count_);
    THR_Print(" %" Pd " classes,", dropped_class_count_);
    THR_Print(" %" Pd " libraries,", dropped_library_count_);
    THR_Print(" %" Pd " constants arrays entries.\n",
              dropped_constants_arrays_entries_count_);
  }
}

void Precompiler::PrecompileConstructors() {
  PRECOMPILER_TIMER_SCOPE(this, PrecompileConstructors);
  class ConstructorVisitor : public FunctionVisitor {
   public:
    explicit ConstructorVisitor(Precompiler* precompiler, Zone* zone)
        : precompiler_(precompiler), zone_(zone) {}
    void VisitFunction(const Function& function) {
      if (!function.IsGenerativeConstructor()) return;
      if (function.HasCode()) {
        // Const constructors may have been visited before. Recompile them here
        // to collect type information for final fields for them as well.
        function.ClearCode();
      }
      if (FLAG_trace_precompiler) {
        THR_Print("Precompiling constructor %s\n", function.ToCString());
      }
      ASSERT(Class::Handle(zone_, function.Owner()).is_finalized());
      CompileFunction(precompiler_, Thread::Current(), zone_, function);
    }

   private:
    Precompiler* precompiler_;
    Zone* zone_;
  };

  phase_ = Phase::kCompilingConstructorsForInstructionCounts;
  HANDLESCOPE(T);
  ConstructorVisitor visitor(this, Z);
  ProgramVisitor::WalkProgram(Z, IG, &visitor);
  phase_ = Phase::kPreparation;
}

void Precompiler::AddRoots() {
  HANDLESCOPE(T);
  AddSelector(Symbols::NoSuchMethod());
  AddSelector(Symbols::call());  // For speed, not correctness.

  // Add main as an entry point.
  const Library& lib = Library::Handle(IG->object_store()->root_library());
  if (lib.IsNull()) {
    const String& msg = String::Handle(
        Z, String::New("Cannot find root library in isolate.\n"));
    Jump(Error::Handle(Z, ApiError::New(msg)));
    UNREACHABLE();
  }

  const String& name = String::Handle(String::New("main"));
  Function& main = Function::Handle(lib.LookupFunctionAllowPrivate(name));
  if (main.IsNull()) {
    const Object& obj = Object::Handle(lib.LookupReExport(name));
    if (obj.IsFunction()) {
      main ^= obj.ptr();
    }
  }
  if (!main.IsNull()) {
    AddApiUse(main);
    if (lib.LookupFunctionAllowPrivate(name) == Function::null()) {
      retain_root_library_caches_ = true;
    }
    AddRetainReason(main, RetainReasons::kMainFunction);
    AddTypesOf(main);
    // Create closure object from main.
    main = main.ImplicitClosureFunction();
    AddConstObject(Closure::Handle(main.ImplicitStaticClosure()));
  } else {
    String& msg = String::Handle(
        Z, String::NewFormatted("Cannot find main in library %s\n",
                                lib.ToCString()));
    Jump(Error::Handle(Z, ApiError::New(msg)));
    UNREACHABLE();
  }
}

void Precompiler::Iterate() {
  PRECOMPILER_TIMER_SCOPE(this, Iterate);

  Function& function = Function::Handle(Z);

  phase_ = Phase::kFixpointCodeGeneration;
  while (changed_) {
    changed_ = false;

    while (pending_functions_.Length() > 0) {
      function ^= pending_functions_.RemoveLast();
      ProcessFunction(function);
    }

    CheckForNewDynamicFunctions();
    CollectCallbackFields();
  }
  phase_ = Phase::kDone;
}

void Precompiler::CollectCallbackFields() {
  PRECOMPILER_TIMER_SCOPE(this, CollectCallbackFields);
  HANDLESCOPE(T);
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Class& subcls = Class::Handle(Z);
  Array& fields = Array::Handle(Z);
  Field& field = Field::Handle(Z);
  FunctionType& signature = FunctionType::Handle(Z);
  Function& dispatcher = Function::Handle(Z);
  Array& args_desc = Array::Handle(Z);
  AbstractType& field_type = AbstractType::Handle(Z);
  String& field_name = String::Handle(Z);
  GrowableArray<intptr_t> cids;

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();

      if (!cls.is_allocated()) continue;

      fields = cls.fields();
      for (intptr_t k = 0; k < fields.Length(); k++) {
        field ^= fields.At(k);
        if (field.is_static()) continue;
        field_type = field.type();
        if (!field_type.IsFunctionType()) continue;
        field_name = field.name();
        if (!IsSent(field_name)) continue;
        // Create arguments descriptor with fixed parameters from
        // signature of field_type.
        signature ^= field_type.ptr();
        if (signature.IsGeneric()) continue;
        if (signature.HasOptionalParameters()) continue;
        if (FLAG_trace_precompiler) {
          THR_Print("Found callback field %s\n", field_name.ToCString());
        }

        // TODO(dartbug.com/33549): Update this code to use the size of the
        // parameters when supporting calls to non-static methods with
        // unboxed parameters.
        args_desc =
            ArgumentsDescriptor::NewBoxed(0,  // No type argument vector.
                                          signature.num_fixed_parameters());
        cids.Clear();
        if (CHA::ConcreteSubclasses(cls, &cids)) {
          for (intptr_t j = 0; j < cids.length(); ++j) {
            subcls = IG->class_table()->At(cids[j]);
            if (subcls.is_allocated()) {
              // Add dispatcher to cls.
              dispatcher = subcls.GetInvocationDispatcher(
                  field_name, args_desc,
                  UntaggedFunction::kInvokeFieldDispatcher,
                  /* create_if_absent = */ true);
              if (FLAG_trace_precompiler) {
                THR_Print("Added invoke-field-dispatcher for %s to %s\n",
                          field_name.ToCString(), subcls.ToCString());
              }
              AddFunction(dispatcher, RetainReasons::kInvokeFieldDispatcher);
            }
          }
        }
      }
    }
  }
}

void Precompiler::ProcessFunction(const Function& function) {
  HANDLESCOPE(T);
  const intptr_t gop_offset = global_object_pool_builder()->CurrentLength();
  RELEASE_ASSERT(!function.HasCode());
  // Ffi trampoline functions have no signature.
  ASSERT(function.kind() == UntaggedFunction::kFfiTrampoline ||
         FunctionType::Handle(Z, function.signature()).IsFinalized());

  TracingScope tracing_scope(this);
  function_count_++;

  if (FLAG_trace_precompiler) {
    THR_Print("Precompiling %" Pd " %s (%s, %s)\n", function_count_,
              function.ToLibNamePrefixedQualifiedCString(),
              function.token_pos().ToCString(),
              Function::KindToCString(function.kind()));
  }

  ASSERT(!function.is_abstract());

  error_ = CompileFunction(this, thread_, zone_, function);
  if (!error_.IsNull()) {
    Jump(error_);
  }

  // Used in the JIT to save type-feedback across compilations.
  function.ClearICDataArray();
  AddCalleesOf(function, gop_offset);
}

void Precompiler::AddCalleesOf(const Function& function, intptr_t gop_offset) {
  PRECOMPILER_TIMER_SCOPE(this, AddCalleesOf);
  ASSERT(function.HasCode());

  const Code& code = Code::Handle(Z, function.CurrentCode());

  Object& entry = Object::Handle(Z);
  Class& cls = Class::Handle(Z);
  Function& target = Function::Handle(Z);

  const Array& table = Array::Handle(Z, code.static_calls_target_table());
  StaticCallsTable static_calls(table);
  for (auto& view : static_calls) {
    entry = view.Get<Code::kSCallTableFunctionTarget>();
    if (entry.IsFunction()) {
      // Since generally function objects are retained when symbolic stack
      // traces are enabled, only return kForcedRetain to mark that retention
      // was otherwise forced.
      const char* const reason =
          FLAG_retain_function_objects
              ? (!FLAG_dwarf_stack_traces_mode
                     ? RetainReasons::kSymbolicStackTraces
                     : RetainReasons::kForcedRetain)
              : nullptr;
      AddFunction(Function::Cast(entry), reason);
      ASSERT(view.Get<Code::kSCallTableCodeOrTypeTarget>() == Code::null());
      continue;
    }
    entry = view.Get<Code::kSCallTableCodeOrTypeTarget>();
    if (entry.IsCode() && Code::Cast(entry).IsAllocationStubCode()) {
      cls ^= Code::Cast(entry).owner();
      AddInstantiatedClass(cls);
    }
  }

  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(Z, code.exception_handlers());
  if (!handlers.IsNull()) {
#if defined(PRODUCT)
    // List of handled types is only used by debugger and
    // can be removed in PRODUCT mode.
    for (intptr_t i = 0; i < handlers.num_entries(); i++) {
      handlers.SetHandledTypes(i, Array::empty_array());
    }
#else
    Array& types = Array::Handle(Z);
    AbstractType& type = AbstractType::Handle(Z);
    for (intptr_t i = 0; i < handlers.num_entries(); i++) {
      types = handlers.GetHandledTypes(i);
      for (intptr_t j = 0; j < types.Length(); j++) {
        type ^= types.At(j);
        AddType(type);
      }
    }
#endif  // defined(PRODUCT)
  }

#if defined(TARGET_ARCH_IA32)
  FATAL("Callee scanning unimplemented for IA32");
#endif

  String& selector = String::Handle(Z);
  // When tracing we want to scan the object pool attached to the code object
  // rather than scanning global object pool - because we want to include
  // *all* outgoing references into the trace. Scanning GOP would exclude
  // references that have been deduplicated.
  if (!is_tracing()) {
    for (intptr_t i = gop_offset;
         i < global_object_pool_builder()->CurrentLength(); i++) {
      const auto& wrapper_entry = global_object_pool_builder()->EntryAt(i);
      if (wrapper_entry.type() ==
          compiler::ObjectPoolBuilderEntry::kTaggedObject) {
        const auto& entry = *wrapper_entry.obj_;
        AddCalleesOfHelper(entry, &selector, &cls);
      }
    }
  } else {
    const auto& pool = ObjectPool::Handle(Z, code.object_pool());
    auto& entry = Object::Handle(Z);
    for (intptr_t i = 0; i < pool.Length(); i++) {
      if (pool.TypeAt(i) == ObjectPool::EntryType::kTaggedObject) {
        entry = pool.ObjectAt(i);
        AddCalleesOfHelper(entry, &selector, &cls);
      }
    }
  }

  if (!FLAG_dwarf_stack_traces_mode) {
    const Array& inlined_functions =
        Array::Handle(Z, code.inlined_id_to_function());
    for (intptr_t i = 0; i < inlined_functions.Length(); i++) {
      target ^= inlined_functions.At(i);
      AddRetainReason(target, RetainReasons::kSymbolicStackTraces);
      AddTypesOf(target);
    }
  }
}

static bool IsPotentialClosureCall(const String& selector) {
  return selector.ptr() == Symbols::call().ptr() ||
         selector.ptr() == Symbols::DynamicCall().ptr();
}

void Precompiler::AddCalleesOfHelper(const Object& entry,
                                     String* temp_selector,
                                     Class* temp_cls) {
  switch (entry.GetClassId()) {
    case kOneByteStringCid:
    case kNullCid:
      // Skip common leaf constants early in order to
      // process object pools faster.
      return;
    case kUnlinkedCallCid: {
      const auto& call_site = UnlinkedCall::Cast(entry);
      // A dynamic call.
      *temp_selector = call_site.target_name();
      AddSelector(*temp_selector);
      if (IsPotentialClosureCall(*temp_selector)) {
        const Array& arguments_descriptor =
            Array::Handle(Z, call_site.arguments_descriptor());
        AddClosureCall(*temp_selector, arguments_descriptor);
      }
      break;
    }
    case kMegamorphicCacheCid: {
      // A dynamic call.
      const auto& cache = MegamorphicCache::Cast(entry);
      *temp_selector = cache.target_name();
      AddSelector(*temp_selector);
      if (IsPotentialClosureCall(*temp_selector)) {
        const Array& arguments_descriptor =
            Array::Handle(Z, cache.arguments_descriptor());
        AddClosureCall(*temp_selector, arguments_descriptor);
      }
      break;
    }
    case kFieldCid: {
      // Potential need for field initializer.
      const auto& field = Field::Cast(entry);
      AddField(field);
      break;
    }
    case kFunctionCid: {
      // Local closure function.
      const auto& target = Function::Cast(entry);
      AddFunction(target, RetainReasons::kLocalClosure);
      if (target.IsFfiTrampoline()) {
        const auto& callback_target =
            Function::Handle(Z, target.FfiCallbackTarget());
        if (!callback_target.IsNull()) {
          AddFunction(callback_target, RetainReasons::kFfiCallbackTarget);
        }
        AddTypesOf(target);
      }
      break;
    }
    case kCodeCid: {
      const auto& target_code = Code::Cast(entry);
      if (target_code.IsAllocationStubCode()) {
        *temp_cls ^= target_code.owner();
        AddInstantiatedClass(*temp_cls);
      }
      break;
    }
    default:
      if (entry.IsInstance()) {
        // Const object, literal or args descriptor.
        const auto& instance = Instance::Cast(entry);
        AddConstObject(instance);
      }
      break;
  }
}

void Precompiler::AddTypesOf(const Class& cls) {
  if (cls.IsNull()) return;
  if (classes_to_retain_.HasKey(&cls)) return;
  classes_to_retain_.Insert(&Class::ZoneHandle(Z, cls.ptr()));

  Array& interfaces = Array::Handle(Z, cls.interfaces());
  AbstractType& type = AbstractType::Handle(Z);
  for (intptr_t i = 0; i < interfaces.Length(); i++) {
    type ^= interfaces.At(i);
    AddType(type);
  }

  AddTypeParameters(TypeParameters::Handle(Z, cls.type_parameters()));

  type = cls.super_type();
  AddType(type);
}

void Precompiler::AddRetainReason(const Object& obj, const char* reason) {
  if (retained_reasons_writer_ == nullptr || reason == nullptr) return;
  retained_reasons_writer_->AddReason(obj, reason);
}

void Precompiler::AddTypesOf(const Function& function) {
  if (function.IsNull()) return;
  if (functions_to_retain_.ContainsKey(function)) return;
  functions_to_retain_.Insert(function);

  if (retained_reasons_writer_ != nullptr &&
      !retained_reasons_writer_->HasReason(function)) {
    FATAL("no retaining reasons given");
  }

  if (function.NeedsMonomorphicCheckedEntry(Z) ||
      Function::IsDynamicInvocationForwarderName(function.name())) {
    functions_called_dynamically_.Insert(function);
  }

  const FunctionType& signature = FunctionType::Handle(Z, function.signature());
  AddType(signature);

  // A class may have all functions inlined except a local function.
  const Class& owner = Class::Handle(Z, function.Owner());
  AddTypesOf(owner);

  if (function.IsFfiTrampoline()) {
    AddType(FunctionType::Handle(Z, function.FfiCSignature()));
  }

  const auto& parent_function = Function::Handle(Z, function.parent_function());
  if (parent_function.IsNull()) {
    return;
  }

  // It can happen that all uses of a function are inlined, leaving
  // a compiled local function with an uncompiled parent. Retain such
  // parents and their enclosing classes and libraries when needed.

  // We always retain parents if symbolic stack traces are enabled.
  if (!FLAG_dwarf_stack_traces_mode) {
    AddRetainReason(parent_function, RetainReasons::kSymbolicStackTraces);
    AddTypesOf(parent_function);
    return;
  }

  // We're not retaining the parent due to this function, so wrap it with
  // a weak serialization reference.
  const auto& data = ClosureData::CheckedHandle(Z, function.data());
  const auto& wsr =
      Object::Handle(Z, WeakSerializationReference::New(
                            parent_function, Object::null_function()));
  data.set_parent_function(wsr);
}

void Precompiler::AddType(const AbstractType& abstype) {
  if (abstype.IsNull()) return;

  if (abstype.IsTypeParameter()) {
    const auto& param = TypeParameter::Cast(abstype);
    if (typeparams_to_retain_.HasKey(&param)) return;
    typeparams_to_retain_.Insert(&TypeParameter::ZoneHandle(Z, param.ptr()));

    if (param.IsClassTypeParameter()) {
      AddTypesOf(Class::Handle(Z, param.parameterized_class()));
    } else {
      AddType(FunctionType::Handle(Z, param.parameterized_function_type()));
    }
    return;
  }

  if (abstype.IsFunctionType()) {
    if (functiontypes_to_retain_.HasKey(&FunctionType::Cast(abstype))) return;
    const FunctionType& signature =
        FunctionType::ZoneHandle(Z, FunctionType::Cast(abstype).ptr());
    functiontypes_to_retain_.Insert(&signature);

    AddTypeParameters(TypeParameters::Handle(Z, signature.type_parameters()));

    AbstractType& type = AbstractType::Handle(Z);
    type = signature.result_type();
    AddType(type);
    for (intptr_t i = 0; i < signature.NumParameters(); i++) {
      type = signature.ParameterTypeAt(i);
      AddType(type);
    }
    return;
  }

  if (types_to_retain_.HasKey(&abstype)) return;
  types_to_retain_.Insert(&AbstractType::ZoneHandle(Z, abstype.ptr()));

  if (abstype.IsType()) {
    const Type& type = Type::Cast(abstype);
    const Class& cls = Class::Handle(Z, type.type_class());
    AddTypesOf(cls);
    const TypeArguments& vector = TypeArguments::Handle(Z, type.arguments());
    AddTypeArguments(vector);
  } else if (abstype.IsRecordType()) {
    const auto& rec = RecordType::Cast(abstype);
    AbstractType& type = AbstractType::Handle(Z);
    for (intptr_t i = 0, n = rec.NumFields(); i < n; ++i) {
      type = rec.FieldTypeAt(i);
      AddType(type);
    }
  }
}

void Precompiler::AddTypeParameters(const TypeParameters& params) {
  if (params.IsNull()) return;

  TypeArguments& args = TypeArguments::Handle();
  args = params.bounds();
  AddTypeArguments(args);
  args = params.defaults();
  AddTypeArguments(args);
}

void Precompiler::AddTypeArguments(const TypeArguments& args) {
  if (args.IsNull()) return;

  if (typeargs_to_retain_.HasKey(&args)) return;
  typeargs_to_retain_.Insert(&TypeArguments::ZoneHandle(Z, args.ptr()));

  AbstractType& arg = AbstractType::Handle(Z);
  for (intptr_t i = 0; i < args.Length(); i++) {
    arg = args.TypeAt(i);
    AddType(arg);
  }
}

void Precompiler::AddConstObject(const class Instance& instance) {
  // Types, type parameters, and type arguments require special handling.
  if (instance.IsAbstractType()) {  // Includes type parameter.
    AddType(AbstractType::Cast(instance));
    return;
  } else if (instance.IsTypeArguments()) {
    AddTypeArguments(TypeArguments::Cast(instance));
    return;
  }

  if (instance.ptr() == Object::sentinel().ptr() ||
      instance.ptr() == Object::transition_sentinel().ptr()) {
    return;
  }

  Class& cls = Class::Handle(Z, instance.clazz());
  AddInstantiatedClass(cls);

  if (instance.IsClosure()) {
    // An implicit static closure.
    const Function& func =
        Function::Handle(Z, Closure::Cast(instance).function());
    ASSERT(func.is_static());
    AddFunction(func, RetainReasons::kImplicitClosure);
    AddTypeArguments(TypeArguments::Handle(
        Z, Closure::Cast(instance).instantiator_type_arguments()));
    AddTypeArguments(TypeArguments::Handle(
        Z, Closure::Cast(instance).function_type_arguments()));
    AddTypeArguments(TypeArguments::Handle(
        Z, Closure::Cast(instance).delayed_type_arguments()));
    return;
  }

  if (instance.IsLibraryPrefix()) {
    const LibraryPrefix& prefix = LibraryPrefix::Cast(instance);
    ASSERT(prefix.is_deferred_load());
    const Library& target = Library::Handle(Z, prefix.GetLibrary(0));
    cls = target.toplevel_class();
    if (!classes_to_retain_.HasKey(&cls)) {
      classes_to_retain_.Insert(&Class::ZoneHandle(Z, cls.ptr()));
    }
    return;
  }

  // Can't ask immediate objects if they're canonical.
  if (instance.IsSmi()) return;

  // Some Instances in the ObjectPool aren't const objects, such as
  // argument descriptors.
  if (!instance.IsCanonical()) return;

  // Constants are canonicalized and we avoid repeated processing of them.
  if (consts_to_retain_.HasKey(&instance)) return;

  consts_to_retain_.Insert(&Instance::ZoneHandle(Z, instance.ptr()));

  if (cls.NumTypeArguments() > 0) {
    AddTypeArguments(TypeArguments::Handle(Z, instance.GetTypeArguments()));
  }

  class ConstObjectVisitor : public ObjectPointerVisitor {
   public:
    ConstObjectVisitor(Precompiler* precompiler, IsolateGroup* isolate_group)
        : ObjectPointerVisitor(isolate_group),
          precompiler_(precompiler),
          subinstance_(Object::Handle()) {}

    void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
      for (ObjectPtr* current = first; current <= last; current++) {
        subinstance_ = *current;
        if (subinstance_.IsInstance()) {
          precompiler_->AddConstObject(Instance::Cast(subinstance_));
        }
      }
      subinstance_ = Object::null();
    }

#if defined(DART_COMPRESSED_POINTERS)
    void VisitCompressedPointers(uword heap_base,
                                 CompressedObjectPtr* first,
                                 CompressedObjectPtr* last) override {
      for (CompressedObjectPtr* current = first; current <= last; current++) {
        subinstance_ = current->Decompress(heap_base);
        if (subinstance_.IsInstance()) {
          precompiler_->AddConstObject(Instance::Cast(subinstance_));
        }
      }
      subinstance_ = Object::null();
    }
#endif

   private:
    Precompiler* precompiler_;
    Object& subinstance_;
  };

  ConstObjectVisitor visitor(this, IG);
  instance.ptr()->untag()->VisitPointers(&visitor);
}

void Precompiler::AddClosureCall(const String& call_selector,
                                 const Array& arguments_descriptor) {
  const Class& cache_class =
      Class::Handle(Z, IG->object_store()->closure_class());
  const Function& dispatcher =
      Function::Handle(Z, cache_class.GetInvocationDispatcher(
                              call_selector, arguments_descriptor,
                              UntaggedFunction::kInvokeFieldDispatcher,
                              true /* create_if_absent */));
  AddFunction(dispatcher, RetainReasons::kInvokeFieldDispatcher);
}

void Precompiler::AddField(const Field& field) {
  if (is_tracing()) {
    tracer_->WriteFieldRef(field);
  }

  if (fields_to_retain_.HasKey(&field)) return;

  fields_to_retain_.Insert(&Field::ZoneHandle(Z, field.ptr()));

  if (field.is_static()) {
    const Object& value =
        Object::Handle(Z, IG->initial_field_table()->At(field.field_id()));
    // Should not be in the middle of initialization while precompiling.
    ASSERT(value.ptr() != Object::transition_sentinel().ptr());

    if (value.ptr() != Object::sentinel().ptr() &&
        value.ptr() != Object::null()) {
      ASSERT(value.IsInstance());
      AddConstObject(Instance::Cast(value));
    }
  }

  if (field.has_nontrivial_initializer() &&
      (field.is_static() || field.is_late())) {
    const Function& initializer =
        Function::ZoneHandle(Z, field.EnsureInitializerFunction());
    const char* const reason = field.is_static()
                                   ? RetainReasons::kStaticFieldInitializer
                                   : RetainReasons::kLateFieldInitializer;
    AddFunction(initializer, reason);
  }
}

const char* Precompiler::MustRetainFunction(const Function& function) {
  // There are some cases where we must retain, even if there are no directly
  // observable need for function objects at runtime. Here, we check for cases
  // where the function is not marked with the vm:entry-point pragma, which also
  // forces retention:
  //
  // * Native functions (for LinkNativeCall)
  // * Selector matches a symbol used in Resolver::ResolveDynamic calls
  //   in dart_entry.cc or dart_api_impl.cc.
  // * _Closure.call (used in async stack handling)
  if (function.is_native()) {
    return "native function";
  }

  // Use the same check for _Closure.call as in stack_trace.{h|cc}.
  const auto& selector = String::Handle(Z, function.name());
  if (selector.ptr() == Symbols::call().ptr()) {
    const auto& name = String::Handle(Z, function.QualifiedScrubbedName());
    if (name.Equals(Symbols::_ClosureCall())) {
      return "_Closure.call";
    }
  }

  // We have to retain functions which can be a target of a SwitchableCall
  // at AOT runtime, since the AOT runtime needs to be able to find the
  // function object in the class.
  if (function.NeedsMonomorphicCheckedEntry(Z)) {
    return "needs monomorphic checked entry";
  }
  if (Function::IsDynamicInvocationForwarderName(function.name())) {
    return "dynamic invocation forwarder";
  }

  if (StackTraceUtils::IsNeededForAsyncAwareUnwinding(function)) {
    return RetainReasons::kAsyncStackUnwinding;
  }

  return nullptr;
}

void Precompiler::AddFunction(const Function& function,
                              const char* retain_reason) {
  ASSERT(!function.is_abstract());
  if (is_tracing()) {
    tracer_->WriteFunctionRef(function);
  }

  if (retain_reason == nullptr) {
    retain_reason = MustRetainFunction(function);
  }
  // Add even if we've already marked this function as possibly retained
  // because this could be an additional reason for doing so.
  AddRetainReason(function, retain_reason);

  if (possibly_retained_functions_.ContainsKey(function)) return;
  if (retain_reason != nullptr) {
    possibly_retained_functions_.Insert(function);
  }

  if (seen_functions_.ContainsKey(function)) return;
  seen_functions_.Insert(function);
  pending_functions_.Add(function);
  changed_ = true;
}

bool Precompiler::IsSent(const String& selector) {
  if (selector.IsNull()) {
    return false;
  }
  return sent_selectors_.HasKey(&selector);
}

void Precompiler::AddSelector(const String& selector) {
  if (is_tracing()) {
    tracer_->WriteSelectorRef(selector);
  }

  ASSERT(!selector.IsNull());
  if (!IsSent(selector)) {
    sent_selectors_.Insert(&String::ZoneHandle(Z, selector.ptr()));
    selector_count_++;
    changed_ = true;

    if (FLAG_trace_precompiler) {
      THR_Print("Enqueueing selector %" Pd " %s\n", selector_count_,
                selector.ToCString());
    }
  }
}

void Precompiler::AddTableSelector(const compiler::TableSelector* selector) {
  if (is_tracing()) {
    tracer_->WriteTableSelectorRef(selector->id);
  }

  if (seen_table_selectors_.HasKey(selector->id)) return;

  seen_table_selectors_.Insert(selector->id);
  changed_ = true;
}

bool Precompiler::IsHitByTableSelector(const Function& function) {
  const int32_t selector_id = selector_map()->SelectorId(function);
  if (selector_id == compiler::SelectorMap::kInvalidSelectorId) return false;
  return seen_table_selectors_.HasKey(selector_id);
}

void Precompiler::AddApiUse(const Object& obj) {
  api_uses_.Insert(&Object::ZoneHandle(Z, obj.ptr()));
}

bool Precompiler::HasApiUse(const Object& obj) {
  return api_uses_.HasKey(&obj);
}

void Precompiler::AddInstantiatedClass(const Class& cls) {
  if (is_tracing()) {
    tracer_->WriteClassInstantiationRef(cls);
  }

  if (cls.is_allocated()) return;

  class_count_++;
  cls.set_is_allocated_unsafe(true);
  error_ = cls.EnsureIsAllocateFinalized(T);
  if (!error_.IsNull()) {
    Jump(error_);
  }

  changed_ = true;

  if (FLAG_trace_precompiler) {
    THR_Print("Allocation %" Pd " %s\n", class_count_, cls.ToCString());
  }

  const Class& superclass = Class::Handle(cls.SuperClass());
  if (!superclass.IsNull()) {
    AddInstantiatedClass(superclass);
  }
}

// Adds all values annotated with @pragma('vm:entry-point') as roots.
void Precompiler::AddAnnotatedRoots() {
  HANDLESCOPE(T);
  auto& lib = Library::Handle(Z);
  auto& cls = Class::Handle(Z);
  auto& members = Array::Handle(Z);
  auto& function = Function::Handle(Z);
  auto& function2 = Function::Handle(Z);
  auto& field = Field::Handle(Z);
  auto& metadata = Array::Handle(Z);
  auto& reusable_object_handle = Object::Handle(Z);
  auto& reusable_field_handle = Field::Handle(Z);

  // Lists of fields which need implicit getter/setter/static final getter
  // added.
  auto& implicit_getters = GrowableObjectArray::Handle(Z);
  auto& implicit_setters = GrowableObjectArray::Handle(Z);
  auto& implicit_static_getters = GrowableObjectArray::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();

      // Check for @pragma on the class itself.
      if (cls.has_pragma()) {
        metadata ^= lib.GetMetadata(cls);
        if (FindEntryPointPragma(IG, metadata, &reusable_field_handle,
                                 &reusable_object_handle) ==
            EntryPointPragma::kAlways) {
          AddInstantiatedClass(cls);
          AddApiUse(cls);
        }
      }

      // Check for @pragma on any fields in the class.
      members = cls.fields();
      implicit_getters = GrowableObjectArray::New(members.Length());
      implicit_setters = GrowableObjectArray::New(members.Length());
      implicit_static_getters = GrowableObjectArray::New(members.Length());
      for (intptr_t k = 0; k < members.Length(); ++k) {
        field ^= members.At(k);
        if (field.has_pragma()) {
          metadata ^= lib.GetMetadata(field);
          if (metadata.IsNull()) continue;
          EntryPointPragma pragma = FindEntryPointPragma(
              IG, metadata, &reusable_field_handle, &reusable_object_handle);
          if (pragma == EntryPointPragma::kNever) continue;

          AddField(field);
          AddApiUse(field);

          if (!field.is_static()) {
            if (pragma != EntryPointPragma::kSetterOnly) {
              implicit_getters.Add(field);
            }
            if (pragma != EntryPointPragma::kGetterOnly) {
              implicit_setters.Add(field);
            }
          } else {
            implicit_static_getters.Add(field);
          }
        }
      }

      // Check for @pragma on any functions in the class.
      members = cls.current_functions();
      for (intptr_t k = 0; k < members.Length(); k++) {
        function ^= members.At(k);
        if (function.has_pragma()) {
          metadata ^= lib.GetMetadata(function);
          if (metadata.IsNull()) continue;
          auto type = FindEntryPointPragma(IG, metadata, &reusable_field_handle,
                                           &reusable_object_handle);

          if (type == EntryPointPragma::kAlways ||
              type == EntryPointPragma::kCallOnly) {
            functions_with_entry_point_pragmas_.Insert(function);
            AddApiUse(function);
            if (!function.is_abstract()) {
              AddFunction(function, RetainReasons::kEntryPointPragma);
            }
          }

          if ((type == EntryPointPragma::kAlways ||
               type == EntryPointPragma::kGetterOnly) &&
              function.kind() != UntaggedFunction::kConstructor &&
              !function.IsSetterFunction()) {
            function2 = function.ImplicitClosureFunction();
            functions_with_entry_point_pragmas_.Insert(function2);
            AddFunction(function2, RetainReasons::kEntryPointPragma);

            // Not `function2`: Dart_GetField will lookup the regular function
            // and get the implicit closure function from that.
            AddApiUse(function);
          }

          if (function.IsGenerativeConstructor()) {
            AddInstantiatedClass(cls);
            AddApiUse(function);
            AddApiUse(cls);
          }
        }
        if (function.kind() == UntaggedFunction::kImplicitGetter &&
            !implicit_getters.IsNull()) {
          for (intptr_t i = 0; i < implicit_getters.Length(); ++i) {
            field ^= implicit_getters.At(i);
            if (function.accessor_field() == field.ptr()) {
              functions_with_entry_point_pragmas_.Insert(function);
              AddFunction(function, RetainReasons::kImplicitGetter);
              AddApiUse(function);
            }
          }
        }
        if (function.kind() == UntaggedFunction::kImplicitSetter &&
            !implicit_setters.IsNull()) {
          for (intptr_t i = 0; i < implicit_setters.Length(); ++i) {
            field ^= implicit_setters.At(i);
            if (function.accessor_field() == field.ptr()) {
              functions_with_entry_point_pragmas_.Insert(function);
              AddFunction(function, RetainReasons::kImplicitSetter);
              AddApiUse(function);
            }
          }
        }
        if (function.kind() == UntaggedFunction::kImplicitStaticGetter &&
            !implicit_static_getters.IsNull()) {
          for (intptr_t i = 0; i < implicit_static_getters.Length(); ++i) {
            field ^= implicit_static_getters.At(i);
            if (function.accessor_field() == field.ptr()) {
              functions_with_entry_point_pragmas_.Insert(function);
              AddFunction(function, RetainReasons::kImplicitStaticGetter);
              AddApiUse(function);
            }
          }
        }
        if (function.is_native()) {
          // The embedder will need to lookup this library to provide the native
          // resolver, even if there are no embedder calls into the library.
          AddApiUse(lib);
        }
      }

      implicit_getters = GrowableObjectArray::null();
      implicit_setters = GrowableObjectArray::null();
      implicit_static_getters = GrowableObjectArray::null();
    }
  }
}

void Precompiler::CheckForNewDynamicFunctions() {
  PRECOMPILER_TIMER_SCOPE(this, CheckForNewDynamicFunctions);
  HANDLESCOPE(T);
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  Function& function2 = Function::Handle(Z);
  String& selector = String::Handle(Z);
  String& selector2 = String::Handle(Z);
  String& selector3 = String::Handle(Z);
  Field& field = Field::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();

      if (!cls.is_allocated()) continue;

      functions = cls.current_functions();
      for (intptr_t k = 0; k < functions.Length(); k++) {
        function ^= functions.At(k);

        if (function.is_static() || function.is_abstract()) continue;

        // Don't bail out early if there is already code because we may discover
        // the corresponding getter selector is sent in some later iteration.
        // if (function.HasCode()) continue;

        selector = function.name();
        if (IsSent(selector)) {
          AddFunction(function, RetainReasons::kCalledViaSelector);
        }
        if (IsHitByTableSelector(function)) {
          AddFunction(function, FLAG_retain_function_objects
                                    ? RetainReasons::kForcedRetain
                                    : nullptr);
        }

        bool found_metadata = false;
        kernel::ProcedureAttributesMetadata metadata;

        // Handle the implicit call type conversions.
        if (Field::IsGetterName(selector) &&
            (function.kind() != UntaggedFunction::kMethodExtractor)) {
          // Call-through-getter.
          // Function is get:foo and somewhere foo (or dyn:foo) is called.
          // Note that we need to skip method extractors (which were potentially
          // created by DispatchTableGenerator): call of foo will never
          // hit method extractor get:foo, because it will hit an existing
          // method foo first.
          selector2 = Field::NameFromGetter(selector);
          if (IsSent(selector2)) {
            AddFunction(function, RetainReasons::kCalledThroughGetter);
          }
          selector2 = Function::CreateDynamicInvocationForwarderName(selector2);
          if (IsSent(selector2)) {
            selector2 =
                Function::CreateDynamicInvocationForwarderName(selector);
            function2 = function.GetDynamicInvocationForwarder(selector2);
            AddFunction(function2, RetainReasons::kDynamicInvocationForwarder);
            functions_called_dynamically_.Insert(function2);
          }
        } else if (function.kind() == UntaggedFunction::kRegularFunction) {
          selector2 = Field::GetterSymbol(selector);
          selector3 = Function::CreateDynamicInvocationForwarderName(selector2);
          if (IsSent(selector2) || IsSent(selector3)) {
            metadata = kernel::ProcedureAttributesOf(function, Z);
            found_metadata = true;

            if (metadata.has_tearoff_uses) {
              // Closurization.
              // Function is foo and somewhere get:foo is called.
              function2 = function.ImplicitClosureFunction();
              AddFunction(function2, RetainReasons::kImplicitClosure);

              // Add corresponding method extractor.
              function2 = function.GetMethodExtractor(selector2);
              AddFunction(function2, RetainReasons::kMethodExtractor);
            }
          }
        }

        const bool is_getter =
            function.kind() == UntaggedFunction::kImplicitGetter ||
            function.kind() == UntaggedFunction::kGetterFunction;
        const bool is_setter =
            function.kind() == UntaggedFunction::kImplicitSetter ||
            function.kind() == UntaggedFunction::kSetterFunction;
        const bool is_regular =
            function.kind() == UntaggedFunction::kRegularFunction;
        if (is_getter || is_setter || is_regular) {
          selector2 = Function::CreateDynamicInvocationForwarderName(selector);
          if (IsSent(selector2)) {
            if (function.kind() == UntaggedFunction::kImplicitGetter ||
                function.kind() == UntaggedFunction::kImplicitSetter) {
              field = function.accessor_field();
              metadata = kernel::ProcedureAttributesOf(field, Z);
            } else if (!found_metadata) {
              metadata = kernel::ProcedureAttributesOf(function, Z);
            }

            if (is_getter) {
              if (metadata.getter_called_dynamically) {
                function2 = function.GetDynamicInvocationForwarder(selector2);
                AddFunction(function2,
                            RetainReasons::kDynamicInvocationForwarder);
                functions_called_dynamically_.Insert(function2);
              }
            } else {
              if (metadata.method_or_setter_called_dynamically) {
                function2 = function.GetDynamicInvocationForwarder(selector2);
                AddFunction(function2,
                            RetainReasons::kDynamicInvocationForwarder);
                functions_called_dynamically_.Insert(function2);
              }
            }
          }
        }
      }
    }
  }
}

class NameFunctionsTraits {
 public:
  static const char* Name() { return "NameFunctionsTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    return a.IsString() && b.IsString() &&
           String::Cast(a).Equals(String::Cast(b));
  }
  static uword Hash(const Object& obj) { return String::Cast(obj).Hash(); }
  static ObjectPtr NewKey(const String& str) { return str.ptr(); }
};

typedef UnorderedHashMap<NameFunctionsTraits> Table;

static void AddNameToFunctionsTable(Zone* zone,
                                    Table* table,
                                    const String& fname,
                                    const Function& function) {
  Array& farray = Array::Handle(zone);
  farray ^= table->InsertNewOrGetValue(fname, Array::empty_array());
  farray = Array::Grow(farray, farray.Length() + 1);
  farray.SetAt(farray.Length() - 1, function);
  table->UpdateValue(fname, farray);
}

static void AddNamesToFunctionsTable(Zone* zone,
                                     Table* table,
                                     const String& fname,
                                     const Function& function,
                                     String* mangled_name,
                                     Function* dyn_function) {
  AddNameToFunctionsTable(zone, table, fname, function);

  *dyn_function = function.ptr();
  if (kernel::NeedsDynamicInvocationForwarder(function)) {
    *mangled_name = function.name();
    *mangled_name =
        Function::CreateDynamicInvocationForwarderName(*mangled_name);
    *dyn_function = function.GetDynamicInvocationForwarder(*mangled_name,
                                                           /*allow_add=*/true);
  }
  *mangled_name = Function::CreateDynamicInvocationForwarderName(fname);
  AddNameToFunctionsTable(zone, table, *mangled_name, *dyn_function);
}

void Precompiler::CollectDynamicFunctionNames() {
  if (!FLAG_collect_dynamic_function_names) {
    return;
  }
  HANDLESCOPE(T);
  auto& lib = Library::Handle(Z);
  auto& cls = Class::Handle(Z);
  auto& functions = Array::Handle(Z);
  auto& function = Function::Handle(Z);
  auto& fname = String::Handle(Z);
  auto& farray = Array::Handle(Z);
  auto& mangled_name = String::Handle(Z);
  auto& dyn_function = Function::Handle(Z);

  Table table(HashTables::New<Table>(100));
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      functions = cls.current_functions();

      const intptr_t length = functions.Length();
      for (intptr_t j = 0; j < length; j++) {
        function ^= functions.At(j);
        if (function.IsDynamicFunction()) {
          fname = function.name();
          if (function.IsSetterFunction() ||
              function.IsImplicitSetterFunction()) {
            AddNamesToFunctionsTable(zone(), &table, fname, function,
                                     &mangled_name, &dyn_function);
          } else if (function.IsGetterFunction() ||
                     function.IsImplicitGetterFunction()) {
            // Enter both getter and non getter name.
            AddNamesToFunctionsTable(zone(), &table, fname, function,
                                     &mangled_name, &dyn_function);
            fname = Field::NameFromGetter(fname);
            AddNamesToFunctionsTable(zone(), &table, fname, function,
                                     &mangled_name, &dyn_function);
          } else if (function.IsMethodExtractor()) {
            // Skip. We already add getter names for regular methods below.
            continue;
          } else {
            // Regular function. Enter both getter and non getter name.
            AddNamesToFunctionsTable(zone(), &table, fname, function,
                                     &mangled_name, &dyn_function);
            fname = Field::GetterName(fname);
            AddNamesToFunctionsTable(zone(), &table, fname, function,
                                     &mangled_name, &dyn_function);
          }
        }
      }
    }
  }

  // Locate all entries with one function only
  Table::Iterator iter(&table);
  String& key = String::Handle(Z);
  String& key_demangled = String::Handle(Z);
  UniqueFunctionsMap functions_map(HashTables::New<UniqueFunctionsMap>(20));
  while (iter.MoveNext()) {
    intptr_t curr_key = iter.Current();
    key ^= table.GetKey(curr_key);
    farray ^= table.GetOrNull(key);
    ASSERT(!farray.IsNull());
    if (farray.Length() == 1) {
      function ^= farray.At(0);

      // It looks like there is exactly one target for the given name. Though we
      // have to be careful: e.g. A name like `dyn:get:foo` might have a target
      // `foo()`. Though the actual target would be a lazily created method
      // extractor `get:foo` for the `foo` function.
      //
      // We'd like to prevent eager creation of functions which we normally
      // create lazily.
      // => We disable unique target optimization if the target belongs to the
      //    lazily created functions.
      key_demangled = key.ptr();
      if (Function::IsDynamicInvocationForwarderName(key)) {
        key_demangled = Function::DemangleDynamicInvocationForwarderName(key);
      }
      if (function.name() != key.ptr() &&
          function.name() != key_demangled.ptr()) {
        continue;
      }
      functions_map.UpdateOrInsert(key, function);
    }
  }

  farray ^= table.GetOrNull(Symbols::GetRuntimeType());

  get_runtime_type_is_unique_ = !farray.IsNull() && (farray.Length() == 1);

  if (FLAG_print_unique_targets) {
    UniqueFunctionsMap::Iterator unique_iter(&functions_map);
    while (unique_iter.MoveNext()) {
      intptr_t curr_key = unique_iter.Current();
      function ^= functions_map.GetPayload(curr_key, 0);
      THR_Print("* %s\n", function.ToQualifiedCString());
    }
    THR_Print("%" Pd " of %" Pd " dynamic selectors are unique\n",
              functions_map.NumOccupied(), table.NumOccupied());
  }

  IG->object_store()->set_unique_dynamic_targets(functions_map.Release());
  table.Release();
}

void Precompiler::TraceForRetainedFunctions() {
  HANDLESCOPE(T);
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  Function& function2 = Function::Handle(Z);
  Array& fields = Array::Handle(Z);
  Field& field = Field::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      functions = cls.current_functions();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
        function ^= functions.At(j);
        function.DropUncompiledImplicitClosureFunction();

        const bool retained =
            possibly_retained_functions_.ContainsKey(function);
        if (retained) {
          AddTypesOf(function);
        }
        if (function.HasImplicitClosureFunction()) {
          function2 = function.ImplicitClosureFunction();

          if (possibly_retained_functions_.ContainsKey(function2)) {
            AddTypesOf(function2);
            // If function has @pragma('vm:entry-point', 'get') we need to keep
            // the function itself around so that runtime could find it and
            // get to the implicit closure through it.
            if (!retained &&
                functions_with_entry_point_pragmas_.ContainsKey(function2)) {
              AddRetainReason(function, RetainReasons::kEntryPointPragma);
              AddTypesOf(function);
            }
          }
        }
      }

      fields = cls.fields();
      for (intptr_t j = 0; j < fields.Length(); j++) {
        field ^= fields.At(j);
        if (fields_to_retain_.HasKey(&field) &&
            field.HasInitializerFunction()) {
          function = field.InitializerFunction();
          if (possibly_retained_functions_.ContainsKey(function)) {
            AddTypesOf(function);
          }
        }
      }

      if (cls.invocation_dispatcher_cache() != Array::empty_array().ptr()) {
        DispatcherSet dispatchers(cls.invocation_dispatcher_cache());
        DispatcherSet::Iterator it(&dispatchers);
        while (it.MoveNext()) {
          function ^= dispatchers.GetKey(it.Current());
          if (possibly_retained_functions_.ContainsKey(function)) {
            AddTypesOf(function);
          }
        }
        dispatchers.Release();
      }
    }
  }

  ClosureFunctionsCache::ForAllClosureFunctions([&](const Function& function) {
    if (possibly_retained_functions_.ContainsKey(function)) {
      AddTypesOf(function);
    }
    return true;  // Continue iteration.
  });

#ifdef DEBUG
  // Make sure functions_to_retain_ is a super-set of
  // possibly_retained_functions_.
  FunctionSet::Iterator it(&possibly_retained_functions_);
  while (it.MoveNext()) {
    function ^= possibly_retained_functions_.GetKey(it.Current());
    // Ffi trampoline functions are not reachable from program structure,
    // they are referenced only from code (object pool).
    if (!functions_to_retain_.ContainsKey(function) &&
        !function.IsFfiTrampoline()) {
      FATAL("Function %s was not traced in TraceForRetainedFunctions\n",
            function.ToFullyQualifiedCString());
    }
  }
#endif  // DEBUG
}

void Precompiler::FinalizeDispatchTable() {
  PRECOMPILER_TIMER_SCOPE(this, FinalizeDispatchTable);
  HANDLESCOPE(T);
  // Build the entries used to serialize the dispatch table before
  // dropping functions, as we may clear references to Code objects.
  const auto& entries =
      Array::Handle(Z, dispatch_table_generator_->BuildCodeArray());
  IG->object_store()->set_dispatch_table_code_entries(entries);
  // Delete the dispatch table generator to ensure there's no attempt
  // to add new entries after this point.
  delete dispatch_table_generator_;
  dispatch_table_generator_ = nullptr;

  if (FLAG_retain_function_objects || !FLAG_trace_precompiler) return;

  FunctionSet printed(HashTables::New<FunctionSet>(/*initial_capacity=*/1024));
  auto& code = Code::Handle(Z);
  auto& function = Function::Handle(Z);
  for (intptr_t i = 0; i < entries.Length(); i++) {
    code = Code::RawCast(entries.At(i));
    if (code.IsNull()) continue;
    if (!code.IsFunctionCode()) continue;
    function = code.function();
    ASSERT(!function.IsNull());
    if (printed.ContainsKey(function)) continue;
    if (functions_to_retain_.ContainsKey(function)) continue;
    THR_Print("Dispatch table references code for function to drop: %s\n",
              function.ToLibNamePrefixedQualifiedCString());
    printed.Insert(function);
  }
  printed.Release();
}

void Precompiler::ReplaceFunctionStaticCallEntries() {
  PRECOMPILER_TIMER_SCOPE(this, ReplaceFunctionStaticCallEntries);
  class StaticCallTableEntryFixer : public CodeVisitor {
   public:
    explicit StaticCallTableEntryFixer(Zone* zone)
        : table_(Array::Handle(zone)),
          kind_and_offset_(Smi::Handle(zone)),
          target_function_(Function::Handle(zone)),
          target_code_(Code::Handle(zone)),
          pool_(ObjectPool::Handle(zone)) {}

    void VisitCode(const Code& code) {
      if (!code.IsFunctionCode()) return;
      table_ = code.static_calls_target_table();
      StaticCallsTable static_calls(table_);

      // With bare instructions, there is a global pool and per-Code local
      // pools. Instructions are generated to use offsets into the global pool,
      // but we still use the local pool to track which Code are using which
      // pool values for the purposes of analyzing snapshot size
      // (--write_v8_snapshot_profile_to and --print_instructions_sizes_to) and
      // deferred loading deciding which snapshots to place pool values in.
      // We don't keep track of which offsets in the local pools correspond to
      // which entries in the static call table, so we don't properly replace
      // the old references to the CallStaticFunction stub, but it is sufficient
      // for the local pool to include the actual call target.
      compiler::ObjectPoolBuilder builder;
      pool_ = code.object_pool();
      pool_.CopyInto(&builder);

      for (auto& view : static_calls) {
        kind_and_offset_ = view.Get<Code::kSCallTableKindAndOffset>();
        auto const kind = Code::KindField::decode(kind_and_offset_.Value());

        if ((kind != Code::kCallViaCode) && (kind != Code::kPcRelativeCall))
          continue;

        target_function_ = view.Get<Code::kSCallTableFunctionTarget>();
        if (target_function_.IsNull()) continue;

        ASSERT(view.Get<Code::kSCallTableCodeOrTypeTarget>() == Code::null());
        ASSERT(target_function_.HasCode());
        target_code_ = target_function_.CurrentCode();
        ASSERT(!target_code_.IsStubCode());
        view.Set<Code::kSCallTableCodeOrTypeTarget>(target_code_);
        view.Set<Code::kSCallTableFunctionTarget>(Object::null_function());
        if (kind == Code::kCallViaCode) {
          auto const pc_offset =
              Code::OffsetField::decode(kind_and_offset_.Value());
          const uword pc = pc_offset + code.PayloadStart();
          CodePatcher::PatchStaticCallAt(pc, code, target_code_);
          builder.AddObject(Object::ZoneHandle(target_code_.ptr()));
        }
        if (FLAG_trace_precompiler) {
          THR_Print("Updated static call entry to %s in \"%s\"\n",
                    target_function_.ToFullyQualifiedCString(),
                    code.ToCString());
        }
      }

      code.set_object_pool(ObjectPool::NewFromBuilder(builder));
    }

   private:
    Array& table_;
    Smi& kind_and_offset_;
    Function& target_function_;
    Code& target_code_;
    ObjectPool& pool_;
  };

  HANDLESCOPE(T);
  StaticCallTableEntryFixer visitor(Z);
  ProgramVisitor::WalkProgram(Z, IG, &visitor);
}

void Precompiler::DropFunctions() {
  HANDLESCOPE(T);
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  Function& target = Function::Handle(Z);
  Function& implicit_closure = Function::Handle(Z);
  Code& code = Code::Handle(Z);
  Object& owner = Object::Handle(Z);
  GrowableObjectArray& retained_functions = GrowableObjectArray::Handle(Z);
  auto& sig = FunctionType::Handle(Z);
  auto& ref = Object::Handle(Z);

  auto trim_function = [&](const Function& function) {
    if (function.IsDynamicInvocationForwarder()) {
      // For dynamic invocation forwarders sever strong connection between the
      // forwarder and the target function if we are not going to retain
      // target function anyway. The only use of the forwarding target outside
      // of compilation pipeline is in Function::script() and that should not
      // be used when we are dropping functions (cause we are not going to
      // emit symbolic stack traces anyway).
      // Note that we still need Function::script() to work during snapshot
      // generation to generate DWARF, that's why we are using WSR and not
      // simply setting forwarding target to null.
      target = function.ForwardingTarget();
      if (!functions_to_retain_.ContainsKey(target)) {
        ref =
            WeakSerializationReference::New(target, Function::null_function());
        function.set_data(ref);
      }
    }

    sig = function.signature();
    // In the AOT runtime, most calls are direct or through the dispatch table,
    // not resolved via dynamic lookup. Thus, we only need to retain the
    // function signature in the following cases:
    if (function.IsClosureFunction()) {
      // Dynamic calls to closures go through dynamic closure call dispatchers,
      // which need the signature.
      return AddRetainReason(sig, RetainReasons::kClosureSignature);
    }
    if (function.IsFfiTrampoline()) {
      // FFI trampolines may be dynamically called.
      return AddRetainReason(sig, RetainReasons::kFfiTrampolineSignature);
    }
    if (function.is_native()) {
      return AddRetainReason(sig, RetainReasons::kNativeSignature);
    }
    if (function.HasRequiredNamedParameters()) {
      // Required named parameters must be checked, so a NoSuchMethod exception
      // can be thrown if they are not provided.
      return AddRetainReason(sig, RetainReasons::kRequiredNamedParameters);
    }
    if (functions_called_dynamically_.ContainsKey(function)) {
      // Dynamic resolution of these functions checks for valid arguments.
      return AddRetainReason(sig, RetainReasons::kDynamicallyCalledSignature);
    }
    if (functions_with_entry_point_pragmas_.ContainsKey(function)) {
      // Dynamic resolution of entry points also checks for valid arguments.
      return AddRetainReason(sig, RetainReasons::kEntryPointPragmaSignature);
    }
    if (StackTraceUtils::IsNeededForAsyncAwareUnwinding(function)) {
      return AddRetainReason(sig, RetainReasons::kAsyncStackUnwinding);
    }
    if (FLAG_trace_precompiler) {
      THR_Print("Clearing signature for function %s\n",
                function.ToLibNamePrefixedQualifiedCString());
    }
    // Other functions not listed here may end up in dynamic resolution via
    // UnlinkedCalls. However, since it is not a dynamic invocation and has
    // been type checked at compile time, we already know the arguments are
    // valid. Thus, we can skip checking arguments for functions with dropped
    // signatures in ResolveDynamicForReceiverClassWithCustomLookup.
    ref = WeakSerializationReference::New(sig, Object::null_function_type());
    function.set_signature(ref);
  };

  auto drop_function = [&](const Function& function) {
    if (function.HasCode()) {
      code = function.CurrentCode();
      function.ClearCode();
      // Wrap the owner of the code object in case the code object will be
      // serialized but the function object will not.
      owner = code.owner();
      owner = WeakSerializationReference::New(
          owner, Smi::Handle(Smi::New(owner.GetClassId())));
      code.set_owner(owner);
    }
    if (function.HasImplicitClosureFunction()) {
      // If we are going to drop the function which has a compiled
      // implicit closure move the closure itself to the list of closures
      // attached to the object store so that ProgramVisitor could find it.
      // The list of closures is going to be dropped during PRODUCT snapshotting
      // so there is no overhead in doing so.
      implicit_closure = function.ImplicitClosureFunction();
      RELEASE_ASSERT(functions_to_retain_.ContainsKey(implicit_closure));
      ClosureFunctionsCache::AddClosureFunctionLocked(
          implicit_closure, /*allow_implicit_closure_functions=*/true);
    }
    dropped_function_count_++;
    if (FLAG_trace_precompiler) {
      THR_Print("Dropping function %s\n",
                function.ToLibNamePrefixedQualifiedCString());
    }
    if (retained_reasons_writer_ != nullptr) {
      retained_reasons_writer_->AddDropped(function);
    }
  };

  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      functions = cls.functions();
      retained_functions = GrowableObjectArray::New();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        function.DropUncompiledImplicitClosureFunction();
        if (functions_to_retain_.ContainsKey(function)) {
          trim_function(function);
          retained_functions.Add(function);
        } else {
          drop_function(function);
        }
      }

      if (retained_functions.Length() > 0) {
        functions = Array::MakeFixedLength(retained_functions);
        cls.SetFunctions(functions);
      } else {
        cls.SetFunctions(Object::empty_array());
      }

      retained_functions = GrowableObjectArray::New();
      if (cls.invocation_dispatcher_cache() != Array::empty_array().ptr()) {
        DispatcherSet dispatchers(Z, cls.invocation_dispatcher_cache());
        DispatcherSet::Iterator it(&dispatchers);
        while (it.MoveNext()) {
          function ^= dispatchers.GetKey(it.Current());
          if (functions_to_retain_.ContainsKey(function)) {
            trim_function(function);
            retained_functions.Add(function);
          } else {
            drop_function(function);
          }
        }
        dispatchers.Release();
      }
      if (retained_functions.Length() == 0) {
        cls.set_invocation_dispatcher_cache(Array::empty_array());
      } else {
        DispatcherSet retained_dispatchers(
            Z, HashTables::New<DispatcherSet>(retained_functions.Length(),
                                              Heap::kOld));
        for (intptr_t j = 0; j < retained_functions.Length(); j++) {
          function ^= retained_functions.At(j);
          retained_dispatchers.Insert(function);
        }
        cls.set_invocation_dispatcher_cache(retained_dispatchers.Release());
      }
    }
  }

  retained_functions = GrowableObjectArray::New();
  ClosureFunctionsCache::ForAllClosureFunctions([&](const Function& function) {
    if (functions_to_retain_.ContainsKey(function)) {
      trim_function(function);
      retained_functions.Add(function);
    } else {
      drop_function(function);
    }
    return true;  // Continue iteration.
  });

  // Note: in PRODUCT mode snapshotter will drop this field when serializing.
  // This is done in ProgramSerializationRoots.
  IG->object_store()->set_closure_functions(retained_functions);

  // Only needed during compilation.
  IG->object_store()->set_closure_functions_table(Object::null_array());
}

void Precompiler::DropFields() {
  HANDLESCOPE(T);
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& fields = Array::Handle(Z);
  Field& field = Field::Handle(Z);
  GrowableObjectArray& retained_fields = GrowableObjectArray::Handle(Z);
  AbstractType& type = AbstractType::Handle(Z);

  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      fields = cls.fields();
      retained_fields = GrowableObjectArray::New();
      for (intptr_t j = 0; j < fields.Length(); j++) {
        field ^= fields.At(j);
        bool retain = fields_to_retain_.HasKey(&field);
#if !defined(PRODUCT)
        if (field.is_instance() && cls.is_allocated()) {
          // Keep instance fields so their names are available to graph tools.
          retain = true;
        }
#endif
        if (retain) {
          if (FLAG_trace_precompiler) {
            THR_Print("Retaining %s field %s\n",
                      field.is_static() ? "static" : "instance",
                      field.ToCString());
          }
          retained_fields.Add(field);
          type = field.type();
          AddType(type);
        } else {
          dropped_field_count_++;
          if (FLAG_trace_precompiler) {
            THR_Print("Dropping %s field %s\n",
                      field.is_static() ? "static" : "instance",
                      field.ToCString());
          }

          // This cleans up references to field current and initial values.
          if (field.is_static()) {
            field.SetStaticValue(Object::null_instance());
            field.SetStaticConstFieldValue(Object::null_instance(),
                                           /*assert_initializing_store=*/false);
          }
        }
      }

      if (retained_fields.Length() > 0) {
        fields = Array::MakeFixedLength(retained_fields);
        cls.SetFields(fields);
      } else {
        cls.SetFields(Object::empty_array());
      }
    }
  }
}

void Precompiler::AttachOptimizedTypeTestingStub() {
  PRECOMPILER_TIMER_SCOPE(this, AttachOptimizedTypeTestingStub);
  HANDLESCOPE(T);
  IsolateGroup::Current()->heap()->CollectAllGarbage();
  GrowableHandlePtrArray<const AbstractType> types(Z, 200);
  {
    class TypesCollector : public ObjectVisitor {
     public:
      explicit TypesCollector(Zone* zone,
                              GrowableHandlePtrArray<const AbstractType>* types)
          : type_(AbstractType::Handle(zone)), types_(types) {}

      void VisitObject(ObjectPtr obj) override {
        if (obj->GetClassId() == kTypeCid ||
            obj->GetClassId() == kFunctionTypeCid ||
            obj->GetClassId() == kRecordTypeCid) {
          type_ ^= obj;
          types_->Add(type_);
        }
      }

     private:
      AbstractType& type_;
      GrowableHandlePtrArray<const AbstractType>* types_;
    };

    HeapIterationScope his(T);
    TypesCollector visitor(Z, &types);

    // Find all type objects in this isolate.
    IG->heap()->VisitObjects(&visitor);

    // Find all type objects in the vm-isolate.
    Dart::vm_isolate_group()->heap()->VisitObjects(&visitor);
  }

  TypeUsageInfo* type_usage_info = Thread::Current()->type_usage_info();

  // At this point we're not generating any new code, so we build a picture of
  // which types we might type-test against.
  type_usage_info->BuildTypeUsageInformation();

  TypeTestingStubGenerator type_testing_stubs;
  Code& code = Code::Handle();
  for (intptr_t i = 0; i < types.length(); i++) {
    const AbstractType& type = types.At(i);

    if (type.InVMIsolateHeap()) {
      // The only important types in the vm isolate are
      // "dynamic"/"void"/"Never", which will get their optimized
      // testing stub installed at creation.
      continue;
    }

    if (type_usage_info->IsUsedInTypeTest(type)) {
      code = type_testing_stubs.OptimizedCodeForType(type);
      type.SetTypeTestingStub(code);

      // Ensure we retain the type.
      AddType(type);
    }
  }

  ASSERT(Object::dynamic_type().type_test_stub_entry_point() ==
         StubCode::TopTypeTypeTest().EntryPoint());
}

enum ConstantVisitedValue { kNotVisited = 0, kRetain, kDrop };

static bool IsUserDefinedClass(Zone* zone,
                               ClassPtr cls,
                               ObjectStore* object_store) {
  intptr_t cid = cls.untag()->id();
  if (cid < kNumPredefinedCids) {
    return false;
  }

  return true;
}

/// Updates |visited| weak table with information about whether object
/// (transitively) references constants of user-defined classes: |kDrop|
/// indicates it does, |kRetain| - does not.
class ConstantInstanceVisitor {
 public:
  ConstantInstanceVisitor(Zone* zone,
                          WeakTable* visited,
                          ObjectStore* object_store)
      : zone_(zone),
        visited_(visited),
        object_store_(object_store),
        object_(Object::Handle(zone)),
        array_(Array::Handle(zone)) {}

  void Visit(ObjectPtr object_ptr) {
    if (!object_ptr->IsHeapObject()) {
      return;
    }
    ConstantVisitedValue value = static_cast<ConstantVisitedValue>(
        visited_->GetValueExclusive(object_ptr));
    if (value != kNotVisited) {
      return;
    }
    object_ = object_ptr;
    if (IsUserDefinedClass(zone_, object_.clazz(), object_store_)) {
      visited_->SetValueExclusive(object_ptr, kDrop);
      return;
    }

    // Conservatively assume an object will be retained.
    visited_->SetValueExclusive(object_ptr, kRetain);
    switch (object_ptr.untag()->GetClassId()) {
      case kImmutableArrayCid: {
        array_ ^= object_ptr;
        for (intptr_t i = 0; i < array_.Length(); i++) {
          ObjectPtr element = array_.At(i);
          Visit(element);
          if (static_cast<ConstantVisitedValue>(
                  visited_->GetValueExclusive(element)) == kDrop) {
            visited_->SetValueExclusive(object_ptr, kDrop);
            break;
          }
        }
        break;
      }
      case kConstMapCid: {
        const Map& map = Map::Handle(Map::RawCast(object_ptr));
        Map::Iterator iterator(map);
        while (iterator.MoveNext()) {
          ObjectPtr element = iterator.CurrentKey();
          Visit(element);
          if (static_cast<ConstantVisitedValue>(
                  visited_->GetValueExclusive(element)) == kDrop) {
            visited_->SetValueExclusive(object_ptr, kDrop);
            break;
          }
          element = iterator.CurrentValue();
          Visit(element);
          if (static_cast<ConstantVisitedValue>(
                  visited_->GetValueExclusive(element)) == kDrop) {
            visited_->SetValueExclusive(object_ptr, kDrop);
            break;
          }
        }
        break;
      }
      case kConstSetCid: {
        const Set& set = Set::Handle(Set::RawCast(object_ptr));
        Set::Iterator iterator(set);
        while (iterator.MoveNext()) {
          ObjectPtr element = iterator.CurrentKey();
          Visit(element);
          if (static_cast<ConstantVisitedValue>(
                  visited_->GetValueExclusive(element)) == kDrop) {
            visited_->SetValueExclusive(object_ptr, kDrop);
            break;
          }
        }
        break;
      }
    }
  }

 private:
  Zone* zone_;
  WeakTable* visited_;
  ObjectStore* object_store_;
  Object& object_;
  Array& array_;
};

// To reduce snapshot size, we remove from constant tables all constants that
// cannot be sent in messages between isolate groups. Such constants will not
// be canonicalized at runtime.
void Precompiler::DropTransitiveUserDefinedConstants() {
  HANDLESCOPE(T);
  auto& constants = Array::Handle(Z);
  auto& obj = Object::Handle(Z);
  auto& lib = Library::Handle(Z);
  auto& cls = Class::Handle(Z);
  auto& instance = Instance::Handle(Z);

  {
    NoSafepointScope no_safepoint(T);
    std::unique_ptr<WeakTable> visited(new WeakTable());
    ObjectStore* object_store = IG->object_store();
    ConstantInstanceVisitor visitor(Z, visited.get(), object_store);

    for (intptr_t i = 0; i < libraries_.Length(); i++) {
      lib ^= libraries_.At(i);
      HANDLESCOPE(T);
      ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
      while (it.HasNext()) {
        cls = it.GetNextClass();
        if (cls.constants() == Array::null()) {
          continue;
        }
        typedef UnorderedHashSet<CanonicalInstanceTraits> CanonicalInstancesSet;

        CanonicalInstancesSet constants_set(cls.constants());
        CanonicalInstancesSet::Iterator iterator(&constants_set);

        if (IsUserDefinedClass(Z, cls.ptr(), object_store)) {
          // All constants for user-defined classes can be dropped.
          constants = cls.constants();
          dropped_constants_arrays_entries_count_ += constants.Length();
          if (FLAG_trace_precompiler) {
            THR_Print("Dropping %" Pd " entries from constants for class %s\n",
                      constants.Length(), cls.ToCString());
          }
          while (iterator.MoveNext()) {
            obj = constants_set.GetKey(iterator.Current());
            instance = Instance::RawCast(obj.ptr());
            consts_to_retain_.Remove(&instance);
            visited->SetValueExclusive(obj.ptr(), kDrop);
          }
        } else {
          // Core classes might have constants that refer to user-defined
          // classes. Those should be dropped too.
          while (iterator.MoveNext()) {
            obj = constants_set.GetKey(iterator.Current());
            ConstantVisitedValue value = static_cast<ConstantVisitedValue>(
                visited->GetValueExclusive(obj.ptr()));
            if (value == kNotVisited) {
              visitor.Visit(obj.ptr());
              value = static_cast<ConstantVisitedValue>(
                  visited->GetValueExclusive(obj.ptr()));
            }
            ASSERT(value == kDrop || value == kRetain);
            if (value == kDrop) {
              dropped_constants_arrays_entries_count_++;
              if (FLAG_trace_precompiler) {
                THR_Print("Dropping constant entry for class %s instance:%s\n",
                          cls.ToCString(), obj.ToCString());
              }
              instance = Instance::RawCast(obj.ptr());
              consts_to_retain_.Remove(&instance);
            }
          }
        }
        constants_set.Release();
      }
    }
  }
}

void Precompiler::TraceTypesFromRetainedClasses() {
  HANDLESCOPE(T);
  auto& lib = Library::Handle(Z);
  auto& cls = Class::Handle(Z);
  auto& members = Array::Handle(Z);
  auto& constants = Array::Handle(Z);
  auto& retained_constants = GrowableObjectArray::Handle(Z);
  auto& obj = Object::Handle(Z);
  auto& constant = Instance::Handle(Z);

  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();

      bool retain = false;
      members = cls.fields();
      if (members.Length() > 0) {
        retain = true;
      }
      members = cls.current_functions();
      if (members.Length() > 0) {
        retain = true;
      }
      if (cls.is_allocated()) {
        retain = true;
      }

      constants = cls.constants();
      retained_constants = GrowableObjectArray::New();
      if (!constants.IsNull()) {
        for (intptr_t j = 0; j < constants.Length(); j++) {
          obj = constants.At(j);
          if ((obj.ptr() == HashTableBase::UnusedMarker().ptr()) ||
              (obj.ptr() == HashTableBase::DeletedMarker().ptr())) {
            continue;
          }
          constant ^= obj.ptr();
          bool retain = consts_to_retain_.HasKey(&constant);
          if (retain) {
            retained_constants.Add(constant);
          }
        }
      }
      // Rehash.
      cls.set_constants(Object::null_array());
      for (intptr_t j = 0; j < retained_constants.Length(); j++) {
        constant ^= retained_constants.At(j);
        cls.InsertCanonicalConstant(Z, constant);
      }

      if (retained_constants.Length() > 0) {
        ASSERT(retain);  // This shouldn't be the reason we keep a class.
        retain = true;
      }

      if (retain) {
        AddTypesOf(cls);
      }
    }
  }
}

void Precompiler::DropMetadata() {
  HANDLESCOPE(T);
  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());

  Library& lib = Library::Handle(Z);
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    lib.set_metadata(Array::null_array());
  }
}

void Precompiler::DropLibraryEntries() {
  HANDLESCOPE(T);
  Library& lib = Library::Handle(Z);
  Array& dict = Array::Handle(Z);
  Object& entry = Object::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);

    dict = lib.dictionary();
    intptr_t dict_size = dict.Length() - 1;
    intptr_t used = 0;
    for (intptr_t j = 0; j < dict_size; j++) {
      entry = dict.At(j);
      if (entry.IsNull()) continue;

      if (entry.IsClass()) {
        if (classes_to_retain_.HasKey(&Class::Cast(entry))) {
          used++;
          continue;
        }
      } else if (entry.IsFunction()) {
        if (functions_to_retain_.ContainsKey(Function::Cast(entry))) {
          used++;
          continue;
        }
      } else if (entry.IsField()) {
        if (fields_to_retain_.HasKey(&Field::Cast(entry))) {
          used++;
          continue;
        }
      } else if (entry.IsLibraryPrefix()) {
        // Always drop.
      } else {
        FATAL("Unexpected library entry: %s", entry.ToCString());
      }
      dict.SetAt(j, Object::null_object());
    }

    lib.RehashDictionary(dict, used * 4 / 3 + 1);
    if (!(retain_root_library_caches_ &&
          (lib.ptr() == IG->object_store()->root_library()))) {
      lib.DropDependenciesAndCaches();
    }
  }
}

void Precompiler::DropClasses() {
  HANDLESCOPE(T);
  Class& cls = Class::Handle(Z);
  Array& constants = Array::Handle(Z);
  GrowableObjectArray& implementors = GrowableObjectArray::Handle(Z);
  GrowableObjectArray& retained_implementors = GrowableObjectArray::Handle(Z);
  Class& implementor = Class::Handle(Z);
  GrowableObjectArray& subclasses = GrowableObjectArray::Handle(Z);
  GrowableObjectArray& retained_subclasses = GrowableObjectArray::Handle(Z);
  Class& subclass = Class::Handle(Z);

  // We are about to remove classes from the class table. For this to be safe,
  // there must be no instances of these classes on the heap, not even
  // corpses because the class table entry may be used to find the size of
  // corpses. Request a full GC and wait for the sweeper tasks to finish before
  // we continue.
  IG->heap()->CollectAllGarbage();
  IG->heap()->WaitForSweeperTasks(T);

  SafepointWriteRwLocker ml(T, IG->program_lock());
  ClassTable* class_table = IG->class_table();
  intptr_t num_cids = class_table->NumCids();

  for (intptr_t cid = 0; cid < num_cids; cid++) {
    if (!class_table->IsValidIndex(cid)) continue;
    if (!class_table->HasValidClassAt(cid)) continue;
    cls = class_table->At(cid);
    constants = cls.constants();
    HashTables::Weaken(constants);
  }

  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    if (!class_table->IsValidIndex(cid)) continue;
    if (!class_table->HasValidClassAt(cid)) continue;

    cls = class_table->At(cid);
    ASSERT(!cls.IsNull());

    implementors = cls.direct_implementors();
    if (!implementors.IsNull()) {
      retained_implementors = GrowableObjectArray::New();
      for (intptr_t i = 0; i < implementors.Length(); i++) {
        implementor ^= implementors.At(i);
        if (classes_to_retain_.HasKey(&implementor)) {
          retained_implementors.Add(implementor);
        }
      }
      cls.set_direct_implementors(retained_implementors);
    }

    subclasses = cls.direct_subclasses();
    if (!subclasses.IsNull()) {
      retained_subclasses = GrowableObjectArray::New();
      for (intptr_t i = 0; i < subclasses.Length(); i++) {
        subclass ^= subclasses.At(i);
        if (classes_to_retain_.HasKey(&subclass)) {
          retained_subclasses.Add(subclass);
        }
      }
      cls.set_direct_subclasses(retained_subclasses);
    }

    if (cls.IsTopLevel()) {
      // Top-level classes are referenced directly from their library. They
      // will only be removed as a consequence of an entire library being
      // removed.
      continue;
    }

    bool retain = classes_to_retain_.HasKey(&cls);
    if (retain) {
      continue;
    }

    ASSERT(!cls.is_allocated());
    constants = cls.constants();
    ASSERT(constants.IsNull() || (constants.Length() == 0));

    dropped_class_count_++;
    if (FLAG_trace_precompiler) {
      THR_Print("Dropping class %" Pd " %s\n", cid, cls.ToCString());
    }

    cls.set_id(kIllegalCid);  // We check this when serializing.
  }
}

void Precompiler::DropLibraries() {
  HANDLESCOPE(T);
  const GrowableObjectArray& retained_libraries =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  const Library& root_lib =
      Library::Handle(Z, IG->object_store()->root_library());
  Library& lib = Library::Handle(Z);
  Class& toplevel_class = Class::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    HANDLESCOPE(T);
    intptr_t entries = 0;
    DictionaryIterator it(lib);
    while (it.HasNext()) {
      entries++;
      it.GetNext();
    }
    bool retain = false;
    if (entries > 0) {
      retain = true;
    } else if (lib.is_dart_scheme()) {
      // The core libraries are referenced from the object store.
      retain = true;
    } else if (lib.ptr() == root_lib.ptr()) {
      // The root library might have no surviving members if it only exports
      // main from another library. It will still be referenced from the object
      // store, so retain it.
      retain = true;
    } else {
      // A type for a top-level class may be referenced from an object pool as
      // part of an error message.
      toplevel_class = lib.toplevel_class();
      if (classes_to_retain_.HasKey(&toplevel_class)) {
        retain = true;
      }
    }

    if (retain) {
      lib.set_index(retained_libraries.Length());
      retained_libraries.Add(lib);
    } else {
      toplevel_class = lib.toplevel_class();

      IG->class_table()->UnregisterTopLevel(toplevel_class.id());
      toplevel_class.set_id(kIllegalCid);  // We check this when serializing.

      dropped_library_count_++;
      lib.set_index(-1);
      if (FLAG_trace_precompiler) {
        THR_Print("Dropping library %s\n", lib.ToCString());
      }
    }
  }

  Library::RegisterLibraries(T, retained_libraries);
  libraries_ = retained_libraries.ptr();
}

// Traverse program structure and mark Code objects
// which do not have useful information as discarded.
// Should be called after Precompiler::ReplaceFunctionStaticCallEntries().
// Should be called before ProgramVisitor::Dedup() as Dedup may clear
// static calls target table.
void Precompiler::DiscardCodeObjects() {
  class DiscardCodeVisitor : public CodeVisitor {
   public:
    DiscardCodeVisitor(Zone* zone,
                       const FunctionSet& functions_to_retain,
                       const FunctionSet& functions_called_dynamically)
        : zone_(zone),
          function_(Function::Handle(zone)),
          parent_function_(Function::Handle(zone)),
          class_(Class::Handle(zone)),
          library_(Library::Handle(zone)),
          loading_unit_(LoadingUnit::Handle(zone)),
          static_calls_target_table_(Array::Handle(zone)),
          kind_and_offset_(Smi::Handle(zone)),
          call_target_(Code::Handle(zone)),
          targets_of_calls_via_code_(
              GrowableObjectArray::Handle(zone, GrowableObjectArray::New())),
          functions_to_retain_(functions_to_retain),
          functions_called_dynamically_(functions_called_dynamically) {}

    // Certain static calls (e.g. between different loading units) are
    // performed through Code objects indirectly. Such Code objects
    // cannot be fully discarded.
    void RecordCodeObjectsUsedForCalls(const Code& code) {
      static_calls_target_table_ = code.static_calls_target_table();
      if (static_calls_target_table_.IsNull()) return;

      StaticCallsTable static_calls(static_calls_target_table_);
      for (const auto& view : static_calls) {
        kind_and_offset_ = view.Get<Code::kSCallTableKindAndOffset>();
        auto const kind = Code::KindField::decode(kind_and_offset_.Value());
        if (kind == Code::kCallViaCode) {
          call_target_ =
              Code::RawCast(view.Get<Code::kSCallTableCodeOrTypeTarget>());
          ASSERT(!call_target_.IsNull());
          targets_of_calls_via_code_.Add(call_target_);
        }
      }
    }

    void VisitCode(const Code& code) override {
      ++total_code_objects_;

      RecordCodeObjectsUsedForCalls(code);

      // Only discard Code objects corresponding to Dart functions.
      if (!code.IsFunctionCode() || code.IsUnknownDartCode()) {
        ++non_function_codes_;
        return;
      }

      // Retain Code object if it has exception handlers or PC descriptors.
      if (code.exception_handlers() !=
          Object::empty_exception_handlers().ptr()) {
        ++codes_with_exception_handlers_;
        return;
      }
      if (code.pc_descriptors() != Object::empty_descriptors().ptr()) {
        ++codes_with_pc_descriptors_;
        return;
      }

      function_ = code.function();
      if (functions_to_retain_.ContainsKey(function_)) {
        // Retain Code objects corresponding to native functions
        // (to find native implementation).
        if (function_.is_native()) {
          ++codes_with_native_function_;
          return;
        }

        // Retain Code objects corresponding to dynamically
        // called functions.
        if (functions_called_dynamically_.ContainsKey(function_)) {
          ++codes_with_dynamically_called_function_;
          return;
        }

        if (StackTraceUtils::IsNeededForAsyncAwareUnwinding(function_)) {
          ++codes_with_function_needed_for_async_unwinding_;
          return;
        }
      } else {
        ASSERT(!functions_called_dynamically_.ContainsKey(function_));
      }

      // Retain Code objects in the non-root loading unit as
      // they are allocated while loading root unit but filled
      // while loading another unit.
      class_ = function_.Owner();
      library_ = class_.library();
      loading_unit_ = library_.loading_unit();
      if (loading_unit_.id() != LoadingUnit::kRootId) {
        ++codes_with_deferred_function_;
        return;
      }

      // Retain Code objects corresponding to FFI trampolines.
      if (function_.IsFfiTrampoline()) {
        ++codes_with_ffi_trampoline_function_;
        return;
      }

      code.set_is_discarded(true);
      if (FLAG_trace_precompiler) {
        THR_Print("Discarding code object corresponding to %s\n",
                  function_.ToFullyQualifiedCString());
      }
      ++discarded_codes_;
    }

    void RetainCodeObjectsUsedAsCallTargets() {
      for (intptr_t i = 0, n = targets_of_calls_via_code_.Length(); i < n;
           ++i) {
        call_target_ = Code::RawCast(targets_of_calls_via_code_.At(i));
        if (call_target_.is_discarded()) {
          call_target_.set_is_discarded(false);
          ++codes_used_as_call_targets_;
          --discarded_codes_;
        }
      }
    }

    void PrintStatistics() const {
      THR_Print("Discarding Code objects:\n");
      THR_Print("    %8" Pd " non-function Codes\n", non_function_codes_);
      THR_Print("    %8" Pd " Codes with exception handlers\n",
                codes_with_exception_handlers_);
      THR_Print("    %8" Pd " Codes with pc descriptors\n",
                codes_with_pc_descriptors_);
      THR_Print("    %8" Pd " Codes with native functions\n",
                codes_with_native_function_);
      THR_Print("    %8" Pd " Codes with dynamically called functions\n",
                codes_with_dynamically_called_function_);
      THR_Print("    %8" Pd " Codes with async unwinding related functions\n",
                codes_with_function_needed_for_async_unwinding_);
      THR_Print("    %8" Pd " Codes with deferred functions\n",
                codes_with_deferred_function_);
      THR_Print("    %8" Pd " Codes with ffi trampoline functions\n",
                codes_with_ffi_trampoline_function_);
      THR_Print("    %8" Pd " Codes used as call targets\n",
                codes_used_as_call_targets_);
      THR_Print("    %8" Pd " Codes discarded\n", discarded_codes_);
      THR_Print("    %8" Pd " Codes total\n", total_code_objects_);
    }

   private:
    Zone* zone_;
    Function& function_;
    Function& parent_function_;
    Class& class_;
    Library& library_;
    LoadingUnit& loading_unit_;
    Array& static_calls_target_table_;
    Smi& kind_and_offset_;
    Code& call_target_;
    GrowableObjectArray& targets_of_calls_via_code_;
    const FunctionSet& functions_to_retain_;
    const FunctionSet& functions_called_dynamically_;

    // Statistics
    intptr_t total_code_objects_ = 0;
    intptr_t non_function_codes_ = 0;
    intptr_t codes_with_exception_handlers_ = 0;
    intptr_t codes_with_pc_descriptors_ = 0;
    intptr_t codes_with_native_function_ = 0;
    intptr_t codes_with_dynamically_called_function_ = 0;
    intptr_t codes_with_function_needed_for_async_unwinding_ = 0;
    intptr_t codes_with_deferred_function_ = 0;
    intptr_t codes_with_ffi_trampoline_function_ = 0;
    intptr_t codes_used_as_call_targets_ = 0;
    intptr_t discarded_codes_ = 0;
  };

  // Code objects are used by stack traces if not dwarf_stack_traces.
  // Code objects are used by profiler in non-PRODUCT mode.
  if (!FLAG_dwarf_stack_traces_mode || FLAG_retain_code_objects) {
    return;
  }

  HANDLESCOPE(T);
  DiscardCodeVisitor visitor(Z, functions_to_retain_,
                             functions_called_dynamically_);
  ProgramVisitor::WalkProgram(Z, IG, &visitor);
  visitor.RetainCodeObjectsUsedAsCallTargets();

  if (FLAG_trace_precompiler) {
    visitor.PrintStatistics();
  }
}

void Precompiler::PruneDictionaries() {
#if defined(DEBUG)
  // Verify that api_uses_ is stable: any entry in it can be found. This
  // check serves to catch bugs when ProgramElementSet::Hash is accidentally
  // defined using unstable values.
  ProgramElementSet::Iterator it = api_uses_.GetIterator();
  while (auto entry = it.Next()) {
    ASSERT(api_uses_.HasKey(*entry));
  }
#endif

  // PRODUCT-only: pruning interferes with various uses of the service protocol,
  // including heap analysis tools.
#if defined(PRODUCT)
  class PruneDictionariesVisitor {
   public:
    GrowableObjectArrayPtr PruneLibraries(
        const GrowableObjectArray& libraries) {
      for (intptr_t i = 0; i < libraries.Length(); i++) {
        lib_ ^= libraries.At(i);
        bool retain = PruneLibrary(lib_);
        if (retain) {
          lib_.set_index(retained_libraries_.Length());
          retained_libraries_.Add(lib_);
        } else {
          lib_.set_index(-1);
          lib_.set_private_key(null_string_);
        }
      }

      Library::RegisterLibraries(Thread::Current(), retained_libraries_);
      return retained_libraries_.ptr();
    }

    bool PruneLibrary(const Library& lib) {
      dict_ = lib.dictionary();
      intptr_t dict_size = dict_.Length() - 1;
      intptr_t used = 0;
      for (intptr_t i = 0; i < dict_size; i++) {
        entry_ = dict_.At(i);
        if (entry_.IsNull()) continue;

        bool retain = false;
        if (entry_.IsClass()) {
          // dart:async: Fix async stack trace lookups in dart:async to annotate
          // entry points or fail gracefully.
          // dart:core, dart:collection, dart:typed_data: Isolate messaging
          // between groups allows any class in these libraries.
          retain = PruneClass(Class::Cast(entry_)) ||
                   (lib.url() == Symbols::DartAsync().ptr()) ||
                   (lib.url() == Symbols::DartCore().ptr()) ||
                   (lib.url() == Symbols::DartCollection().ptr()) ||
                   (lib.url() == Symbols::DartTypedData().ptr());
        } else if (entry_.IsFunction() || entry_.IsField()) {
          retain = precompiler_->HasApiUse(entry_);
        } else {
          FATAL("Unexpected library entry: %s", entry_.ToCString());
        }
        if (retain) {
          used++;
        } else {
          dict_.SetAt(i, Object::null_object());
        }
      }
      lib.RehashDictionary(dict_, used * 4 / 3 + 1);

      bool retain = used > 0;
      cls_ = lib.toplevel_class();
      if (PruneClass(cls_)) {
        retain = true;
      }
      if (lib.is_dart_scheme()) {
        retain = true;
      }
      if (lib.ptr() == root_lib_.ptr()) {
        retain = true;
      }
      if (precompiler_->HasApiUse(lib)) {
        retain = true;
      }
      return retain;
    }

    bool PruneClass(const Class& cls) {
      bool retain = precompiler_->HasApiUse(cls);

      functions_ = cls.functions();
      retained_functions_ = GrowableObjectArray::New();
      for (intptr_t i = 0; i < functions_.Length(); i++) {
        function_ ^= functions_.At(i);
        if (precompiler_->HasApiUse(function_)) {
          retained_functions_.Add(function_);
          retain = true;
        } else if (precompiler_->functions_called_dynamically_.ContainsKey(
                       function_)) {
          retained_functions_.Add(function_);
          // No `retain = true`: the function must appear in the method
          // dictionary for lookup, but the class may still be removed from the
          // library.
        }
      }
      if (retained_functions_.Length() > 0) {
        functions_ = Array::MakeFixedLength(retained_functions_);
        cls.SetFunctions(functions_);
      } else {
        cls.SetFunctions(Object::empty_array());
      }

      fields_ = cls.fields();
      retained_fields_ = GrowableObjectArray::New();
      for (intptr_t i = 0; i < fields_.Length(); i++) {
        field_ ^= fields_.At(i);
        if (precompiler_->HasApiUse(field_)) {
          retained_fields_.Add(field_);
          retain = true;
        }
      }
      if (retained_fields_.Length() > 0) {
        fields_ = Array::MakeFixedLength(retained_fields_);
        cls.SetFields(fields_);
      } else {
        cls.SetFields(Object::empty_array());
      }

      return retain;
    }

    explicit PruneDictionariesVisitor(Precompiler* precompiler, Zone* zone)
        : precompiler_(precompiler),
          lib_(Library::Handle(zone)),
          dict_(Array::Handle(zone)),
          entry_(Object::Handle(zone)),
          cls_(Class::Handle(zone)),
          functions_(Array::Handle(zone)),
          fields_(Array::Handle(zone)),
          function_(Function::Handle(zone)),
          field_(Field::Handle(zone)),
          retained_functions_(GrowableObjectArray::Handle(zone)),
          retained_fields_(GrowableObjectArray::Handle(zone)),
          retained_libraries_(
              GrowableObjectArray::Handle(zone, GrowableObjectArray::New())),
          root_lib_(Library::Handle(
              zone,
              precompiler->isolate_group()->object_store()->root_library())),
          null_string_(String::Handle(zone)) {}

   private:
    Precompiler* const precompiler_;
    Library& lib_;
    Array& dict_;
    Object& entry_;
    Class& cls_;
    Array& functions_;
    Array& fields_;
    Function& function_;
    Field& field_;
    GrowableObjectArray& retained_functions_;
    GrowableObjectArray& retained_fields_;
    const GrowableObjectArray& retained_libraries_;
    const Library& root_lib_;
    const String& null_string_;
  };

  HANDLESCOPE(T);
  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
  PruneDictionariesVisitor visitor(this, Z);
  libraries_ = visitor.PruneLibraries(libraries_);
#endif  // defined(PRODUCT)
}

// Traits for the HashTable template.
struct CodeKeyTraits {
  static uint32_t Hash(const Object& key) { return Code::Cast(key).Size(); }
  static const char* Name() { return "CodeKeyTraits"; }
  static bool IsMatch(const Object& x, const Object& y) {
    return x.ptr() == y.ptr();
  }
  static bool ReportStats() { return false; }
};

typedef UnorderedHashSet<CodeKeyTraits> CodeSet;

#if defined(DEBUG)
FunctionPtr Precompiler::FindUnvisitedRetainedFunction() {
  class CodeChecker : public CodeVisitor {
   public:
    CodeChecker()
        : visited_code_(HashTables::New<CodeSet>(/*initial_capacity=*/1024)) {}
    ~CodeChecker() { visited_code_.Release(); }

    const CodeSet& visited() const { return visited_code_; }

    void VisitCode(const Code& code) { visited_code_.Insert(code); }

   private:
    CodeSet visited_code_;
  };

  CodeChecker visitor;
  ProgramVisitor::WalkProgram(Z, IG, &visitor);
  const CodeSet& visited = visitor.visited();

  FunctionSet::Iterator it(&functions_to_retain_);
  Function& function = Function::Handle(Z);
  Code& code = Code::Handle(Z);
  while (it.MoveNext()) {
    function ^= functions_to_retain_.GetKey(it.Current());
    if (!function.HasCode()) continue;
    code = function.CurrentCode();
    if (!visited.ContainsKey(code)) return function.ptr();
  }
  return Function::null();
}
#endif

void Precompiler::Obfuscate() {
  if (!IG->obfuscate()) {
    return;
  }

  class ScriptsCollector : public ObjectVisitor {
   public:
    explicit ScriptsCollector(Zone* zone,
                              GrowableHandlePtrArray<const Script>* scripts)
        : script_(Script::Handle(zone)), scripts_(scripts) {}

    void VisitObject(ObjectPtr obj) override {
      if (obj->GetClassId() == kScriptCid) {
        script_ ^= obj;
        scripts_->Add(Script::Cast(script_));
      }
    }

   private:
    Script& script_;
    GrowableHandlePtrArray<const Script>* scripts_;
  };

  GrowableHandlePtrArray<const Script> scripts(Z, 100);
  IsolateGroup::Current()->heap()->CollectAllGarbage();
  {
    HeapIterationScope his(T);
    ScriptsCollector visitor(Z, &scripts);
    IG->heap()->VisitObjects(&visitor);
  }

  {
    // Note: when this object is destroyed it will commit obfuscation
    // mappings into the ObjectStore. Hence the block around it - to
    // ensure that destructor is called before we save obfuscation
    // mappings and clear the ObjectStore.
    Obfuscator obfuscator(T, /*private_key=*/String::Handle(Z));
    String& str = String::Handle(Z);
    for (intptr_t i = 0; i < scripts.length(); i++) {
      const Script& script = scripts.At(i);

      str = script.url();
      str = Symbols::New(T, str);
      str = obfuscator.Rename(str, /*atomic=*/true);
      script.set_url(str);
    }

    Library& lib = Library::Handle();
    for (intptr_t i = 0; i < libraries_.Length(); i++) {
      lib ^= libraries_.At(i);
      if (!lib.is_dart_scheme()) {
        str = lib.name();
        str = obfuscator.Rename(str, /*atomic=*/true);
        lib.set_name(str);

        str = lib.url();
        str = Symbols::New(T, str);
        str = obfuscator.Rename(str, /*atomic=*/true);
        lib.set_url(str);
      }
    }
    Library::RegisterLibraries(T, libraries_);
  }

  // Obfuscation is done. Move obfuscation map into mallocated memory.
  IG->set_obfuscation_map(Obfuscator::SerializeMap(T));

  // Discard obfuscation mappings to avoid including them into snapshot.
  IG->object_store()->set_obfuscation_map(Array::Handle(Z));
}

void Precompiler::FinalizeAllClasses() {
  // Create a fresh Zone because kernel reading during class finalization
  // may create zone handles. Those handles may prevent garbage collection of
  // otherwise unreachable constants of dropped classes, which would
  // cause assertion failures during GC after classes are dropped.
  StackZone stack_zone(thread());

  error_ = Library::FinalizeAllClasses();
  if (!error_.IsNull()) {
    Jump(error_);
  }
  IG->set_all_classes_finalized(true);
}

void PrecompileParsedFunctionHelper::FinalizeCompilation(
    compiler::Assembler* assembler,
    FlowGraphCompiler* graph_compiler,
    FlowGraph* flow_graph,
    CodeStatistics* stats) {
  const Function& function = parsed_function()->function();
  Zone* const zone = thread()->zone();

  // CreateDeoptInfo uses the object pool and needs to be done before
  // FinalizeCode.
  const Array& deopt_info_array =
      Array::Handle(zone, graph_compiler->CreateDeoptInfo(assembler));
  // Allocates instruction object. Since this occurs only at safepoint,
  // there can be no concurrent access to the instruction page.
  const auto pool_attachment = Code::PoolAttachment::kNotAttachPool;

  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
  const Code& code = Code::Handle(
      Code::FinalizeCodeAndNotify(function, graph_compiler, assembler,
                                  pool_attachment, optimized(), stats));
  code.set_is_optimized(optimized());
  code.set_owner(function);
  if (!function.IsOptimizable()) {
    // A function with huge unoptimized code can become non-optimizable
    // after generating unoptimized code.
    function.set_usage_counter(INT32_MIN);
  }

  graph_compiler->FinalizePcDescriptors(code);
  code.set_deopt_info_array(deopt_info_array);

  graph_compiler->FinalizeStackMaps(code);
  graph_compiler->FinalizeVarDescriptors(code);
  graph_compiler->FinalizeExceptionHandlers(code);
  graph_compiler->FinalizeCatchEntryMovesMap(code);
  graph_compiler->FinalizeStaticCallTargetsTable(code);
  graph_compiler->FinalizeCodeSourceMap(code);

  if (optimized()) {
    // Installs code while at safepoint.
    ASSERT(thread()->IsDartMutatorThread());
    function.InstallOptimizedCode(code);
  } else {  // not optimized.
    function.set_unoptimized_code(code);
    function.AttachCode(code);
  }

  if (function.IsFfiTrampoline() &&
      function.GetFfiFunctionKind() != FfiFunctionKind::kCall) {
    compiler::ffi::SetFfiCallbackCode(thread(), function, code);
  }
}

// Generate allocation stubs referenced by AllocateObject instructions.
static void GenerateNecessaryAllocationStubs(FlowGraph* flow_graph) {
  for (auto block : flow_graph->reverse_postorder()) {
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      if (auto allocation = it.Current()->AsAllocateObject()) {
        StubCode::GetAllocationStubForClass(allocation->cls());
      }
    }
  }
}

// Return false if bailed out.
bool PrecompileParsedFunctionHelper::Compile(CompilationPipeline* pipeline) {
  ASSERT(CompilerState::Current().is_aot());
  if (optimized() && !parsed_function()->function().IsOptimizable()) {
    // All functions compiled by precompiler must be optimizable.
    UNREACHABLE();
    return false;
  }
  volatile bool is_compiled = false;
  Zone* const zone = thread()->zone();
  HANDLESCOPE(thread());

  // We may reattempt compilation if the function needs to be assembled using
  // far branches on ARM. In the else branch of the setjmp call, done is set to
  // false, and use_far_branches is set to true if there is a longjmp from the
  // ARM assembler. In all other paths through this while loop, done is set to
  // true. use_far_branches is always false on ia32 and x64.
  bool done = false;
  // volatile because the variable may be clobbered by a longjmp.
  volatile intptr_t far_branch_level = 0;
  SpeculativeInliningPolicy speculative_policy(
      true, FLAG_max_speculative_inlining_attempts);

  while (!done) {
    LongJumpScope jump;
    const intptr_t val = setjmp(*jump.Set());
    if (val == 0) {
      FlowGraph* flow_graph = nullptr;
      ZoneGrowableArray<const ICData*>* ic_data_array = nullptr;
      const Function& function = parsed_function()->function();

      CompilerState compiler_state(thread(), /*is_aot=*/true, optimized(),
                                   CompilerState::ShouldTrace(function));
      compiler_state.set_function(function);

      {
        ic_data_array = new (zone) ZoneGrowableArray<const ICData*>();

        TIMELINE_DURATION(thread(), CompilerVerbose, "BuildFlowGraph");
        COMPILER_TIMINGS_TIMER_SCOPE(thread(), BuildGraph);
        flow_graph =
            pipeline->BuildFlowGraph(zone, parsed_function(), ic_data_array,
                                     Compiler::kNoOSRDeoptId, optimized());
      }

      if (optimized()) {
        flow_graph->PopulateWithICData(function);
      }

      const bool print_flow_graph =
          (FLAG_print_flow_graph ||
           (optimized() && FLAG_print_flow_graph_optimized)) &&
          FlowGraphPrinter::ShouldPrint(function);

      if (print_flow_graph && !optimized()) {
        FlowGraphPrinter::PrintGraph("Unoptimized Compilation", flow_graph);
      }

      CompilerPassState pass_state(thread(), flow_graph, &speculative_policy,
                                   precompiler_);
      pass_state.reorder_blocks =
          FlowGraph::ShouldReorderBlocks(function, optimized());

      if (function.ForceOptimize()) {
        ASSERT(optimized());
        TIMELINE_DURATION(thread(), CompilerVerbose, "OptimizationPasses");
        flow_graph = CompilerPass::RunForceOptimizedPipeline(CompilerPass::kAOT,
                                                             &pass_state);
      } else if (optimized()) {
        TIMELINE_DURATION(thread(), CompilerVerbose, "OptimizationPasses");

        AotCallSpecializer call_specializer(precompiler_, flow_graph,
                                            &speculative_policy);
        pass_state.call_specializer = &call_specializer;

        flow_graph = CompilerPass::RunPipeline(CompilerPass::kAOT, &pass_state);
      }

      ASSERT(pass_state.inline_id_to_function.length() ==
             pass_state.caller_inline_id.length());

      ASSERT(precompiler_ != nullptr);

      // When generating code in bare instruction mode all code objects
      // share the same global object pool. To reduce interleaving of
      // unrelated object pool entries from different code objects
      // we attempt to pregenerate stubs referenced by the code
      // we are going to generate.
      //
      // Reducing interleaving means reducing recompilations triggered by
      // failure to commit object pool into the global object pool.
      GenerateNecessaryAllocationStubs(flow_graph);

      // Even in bare instructions mode we don't directly add objects into
      // the global object pool because code generation can bail out
      // (e.g. due to speculative optimization or branch offsets being
      // too big). If we were adding objects into the global pool directly
      // these recompilations would leave dead entries behind.
      // Instead we add objects into an intermediary pool which gets
      // committed into the global object pool at the end of the compilation.
      // This makes an assumption that global object pool itself does not
      // grow during code generation - unfortunately this is not the case
      // because we might have nested code generation (i.e. we might generate
      // some stubs). If this indeed happens we retry the compilation.
      // (See TryCommitToParent invocation below).
      compiler::ObjectPoolBuilder object_pool_builder(
          precompiler_->global_object_pool_builder());
      compiler::Assembler assembler(&object_pool_builder, far_branch_level);

      CodeStatistics* function_stats = nullptr;
      if (FLAG_print_instruction_stats) {
        // At the moment we are leaking CodeStatistics objects for
        // simplicity because this is just a development mode flag.
        function_stats = new CodeStatistics(&assembler);
      }

      FlowGraphCompiler graph_compiler(
          &assembler, flow_graph, *parsed_function(), optimized(),
          &speculative_policy, pass_state.inline_id_to_function,
          pass_state.inline_id_to_token_pos, pass_state.caller_inline_id,
          ic_data_array, function_stats);
      pass_state.graph_compiler = &graph_compiler;
      CompilerPass::GenerateCode(&pass_state);
      {
        COMPILER_TIMINGS_TIMER_SCOPE(thread(), FinalizeCode);
        TIMELINE_DURATION(thread(), CompilerVerbose, "FinalizeCompilation");
        ASSERT(thread()->IsDartMutatorThread());
        FinalizeCompilation(&assembler, &graph_compiler, flow_graph,
                            function_stats);
      }

      if (precompiler_->phase() ==
          Precompiler::Phase::kFixpointCodeGeneration) {
        for (intptr_t i = 0; i < graph_compiler.used_static_fields().length();
             i++) {
          precompiler_->AddField(*graph_compiler.used_static_fields().At(i));
        }

        const GrowableArray<const compiler::TableSelector*>& call_selectors =
            graph_compiler.dispatch_table_call_targets();
        for (intptr_t i = 0; i < call_selectors.length(); i++) {
          precompiler_->AddTableSelector(call_selectors[i]);
        }
      } else {
        // We should not be generating code outside of these two specific
        // precompilation phases.
        RELEASE_ASSERT(
            precompiler_->phase() ==
            Precompiler::Phase::kCompilingConstructorsForInstructionCounts);
      }

      // In bare instructions mode try adding all entries from the object
      // pool into the global object pool. This might fail if we have
      // nested code generation (i.e. we generated some stubs) which means
      // that some of the object indices we used are already occupied in the
      // global object pool.
      //
      // In this case we simply retry compilation assuming that we are not
      // going to hit this problem on the second attempt.
      //
      // Note: currently we can't assume that two compilations of the same
      // method will lead to the same IR due to instability of inlining
      // heuristics (under some conditions we might end up inlining
      // more aggressively on the second attempt).
      if (!object_pool_builder.TryCommitToParent()) {
        done = false;
        continue;
      }
      // Exit the loop and the function with the correct result value.
      is_compiled = true;
      done = true;
    } else {
      // We bailed out or we encountered an error.
      const Error& error = Error::Handle(thread()->StealStickyError());

      if (error.ptr() == Object::branch_offset_error().ptr()) {
        // Compilation failed due to an out of range branch offset in the
        // assembler. We try again (done = false) with far branches enabled.
        done = false;
        RELEASE_ASSERT(far_branch_level < 2);
        far_branch_level++;
      } else if (error.ptr() == Object::speculative_inlining_error().ptr()) {
        // The return value of setjmp is the deopt id of the check instruction
        // that caused the bailout.
        done = false;
        if (!speculative_policy.AllowsSpeculativeInlining()) {
          // Assert that we don't repeatedly retry speculation.
          UNREACHABLE();
        }
        if (!speculative_policy.AddBlockedDeoptId(val)) {
          if (FLAG_trace_compiler || FLAG_trace_optimizing_compiler) {
            THR_Print("Disabled speculative inlining after %" Pd " attempts.\n",
                      speculative_policy.length());
          }
        }
      } else {
        // If the error isn't due to an out of range branch offset, we don't
        // try again (done = true), and indicate that we did not finish
        // compiling (is_compiled = false).
        if (FLAG_trace_bailout) {
          THR_Print("%s\n", error.ToErrorCString());
        }
        done = true;
      }

      if (error.IsLanguageError() &&
          (LanguageError::Cast(error).kind() == Report::kBailout)) {
        // Discard the error if it was not a real error, but just a bailout.
      } else {
        // Otherwise, continue propagating.
        thread()->set_sticky_error(error);
      }
      is_compiled = false;
    }
  }
  return is_compiled;
}

static ErrorPtr PrecompileFunctionHelper(Precompiler* precompiler,
                                         CompilationPipeline* pipeline,
                                         const Function& function,
                                         bool optimized) {
  // Check that we optimize, except if the function is not optimizable.
  ASSERT(CompilerState::Current().is_aot());
  ASSERT(!function.IsOptimizable() || optimized);
  ASSERT(!function.HasCode());
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();
    StackZone stack_zone(thread);
    Zone* const zone = stack_zone.GetZone();
    const bool trace_compiler =
        FLAG_trace_compiler || (FLAG_trace_optimizing_compiler && optimized);
    Timer per_compile_timer;
    per_compile_timer.Start();

    ParsedFunction* parsed_function = new (zone)
        ParsedFunction(thread, Function::ZoneHandle(zone, function.ptr()));
    if (trace_compiler) {
      THR_Print("Precompiling %sfunction: '%s' @ token %" Pd ", size %" Pd "\n",
                (optimized ? "optimized " : ""),
                function.ToFullyQualifiedCString(), function.token_pos().Pos(),
                (function.end_token_pos().Pos() - function.token_pos().Pos()));
    }
    {
      HANDLESCOPE(thread);
      pipeline->ParseFunction(parsed_function);
    }

    PrecompileParsedFunctionHelper helper(precompiler, parsed_function,
                                          optimized);
    const bool success = helper.Compile(pipeline);
    if (!success) {
      // We got an error during compilation.
      const Error& error = Error::Handle(thread->StealStickyError());
      ASSERT(error.IsLanguageError() &&
             LanguageError::Cast(error).kind() != Report::kBailout);
      return error.ptr();
    }

    per_compile_timer.Stop();

    if (trace_compiler) {
      THR_Print("--> '%s' entry: %#" Px " size: %" Pd " time: %" Pd64 " us\n",
                function.ToFullyQualifiedCString(),
                Code::Handle(function.CurrentCode()).PayloadStart(),
                Code::Handle(function.CurrentCode()).Size(),
                per_compile_timer.TotalElapsedTime());
    }

    if (FLAG_disassemble && FlowGraphPrinter::ShouldPrint(function)) {
      Code& code = Code::Handle(function.CurrentCode());
      Disassembler::DisassembleCode(function, code, optimized);
    } else if (FLAG_disassemble_optimized && optimized &&
               FlowGraphPrinter::ShouldPrint(function)) {
      Code& code = Code::Handle(function.CurrentCode());
      Disassembler::DisassembleCode(function, code, true);
    }
    return Error::null();
  } else {
    Thread* const thread = Thread::Current();
    StackZone stack_zone(thread);
    // We got an error during compilation.
    const Error& error = Error::Handle(thread->StealStickyError());
    // Precompilation may encounter compile-time errors.
    // Do not attempt to optimize functions that can cause errors.
    function.set_is_optimizable(false);
    return error.ptr();
  }
  UNREACHABLE();
  return Error::null();
}

ErrorPtr Precompiler::CompileFunction(Precompiler* precompiler,
                                      Thread* thread,
                                      Zone* zone,
                                      const Function& function) {
  PRECOMPILER_TIMER_SCOPE(precompiler, CompileFunction);
  NoActiveIsolateScope no_isolate_scope;

  VMTagScope tagScope(thread, VMTag::kCompileUnoptimizedTagId);
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread, "CompileFunction", function);

  ASSERT(CompilerState::Current().is_aot());
  const bool optimized = function.IsOptimizable();  // False for natives.
  DartCompilationPipeline pipeline;
  if (precompiler->is_tracing()) {
    precompiler->tracer_->WriteCompileFunctionEvent(function);
  }

  return PrecompileFunctionHelper(precompiler, &pipeline, function, optimized);
}

Obfuscator::Obfuscator(Thread* thread, const String& private_key)
    : state_(nullptr) {
  auto isolate_group = thread->isolate_group();
  if (!isolate_group->obfuscate()) {
    // Nothing to do.
    return;
  }
  auto zone = thread->zone();

  // Create ObfuscationState from ObjectStore::obfuscation_map().
  ObjectStore* store = isolate_group->object_store();
  Array& obfuscation_state = Array::Handle(zone, store->obfuscation_map());

  if (store->obfuscation_map() == Array::null()) {
    // We are just starting the obfuscation. Create initial state.
    const int kInitialPrivateCapacity = 256;
    obfuscation_state = Array::New(kSavedStateSize);
    obfuscation_state.SetAt(
        1, Array::Handle(zone, HashTables::New<ObfuscationMap>(
                                   kInitialPrivateCapacity, Heap::kOld)));
  }

  state_ = new (zone) ObfuscationState(thread, obfuscation_state, private_key);

  if (store->obfuscation_map() == Array::null()) {
    // We are just starting the obfuscation. Initialize the renaming map.
    // Note: InitializeRenamingMap uses state_.
    InitializeRenamingMap();
  }
}

Obfuscator::~Obfuscator() {
  if (state_ != nullptr) {
    state_->SaveState();
  }
}

void Obfuscator::InitializeRenamingMap() {
// Prevent renaming of all pseudo-keywords and operators.
// Note: not all pseudo-keywords are mentioned in DART_KEYWORD_LIST
// (for example 'hide', 'show' and async related keywords are omitted).
// Those are protected from renaming as part of all symbols.
#define PREVENT_RENAMING(name, value, priority, attr)                          \
  do {                                                                         \
    if (Token::CanBeOverloaded(Token::name) ||                                 \
        ((Token::attr & Token::kPseudoKeyword) != 0)) {                        \
      PreventRenaming(value);                                                  \
    }                                                                          \
  } while (0);

  DART_TOKEN_LIST(PREVENT_RENAMING)
  DART_KEYWORD_LIST(PREVENT_RENAMING)
#undef PREVENT_RENAMING

  // this is a keyword token unless it occurs in the string interpolation
  // which causes it to be obfuscated.
  PreventRenaming("this");

// Protect all symbols from renaming.
#define PREVENT_RENAMING(name, value) PreventRenaming(value);
  PREDEFINED_SYMBOLS_LIST(PREVENT_RENAMING)
#undef PREVENT_RENAMING

  // Protect NativeFieldWrapperClassX names from being obfuscated. Those
  // classes are created manually by the runtime system.
  // TODO(dartbug.com/30524) instead call to Obfuscator::Rename from a place
  // where these are created.
  PreventRenaming("NativeFieldWrapperClass1");
  PreventRenaming("NativeFieldWrapperClass2");
  PreventRenaming("NativeFieldWrapperClass3");
  PreventRenaming("NativeFieldWrapperClass4");

// Prevent renaming of ClassID.cid* fields. These fields are injected by
// runtime.
// TODO(dartbug.com/30524) instead call to Obfuscator::Rename from a place
// where these are created.
#define CLASS_LIST_WITH_NULL(V)                                                \
  V(Null)                                                                      \
  CLASS_LIST_NO_OBJECT(V)
#define PREVENT_RENAMING(clazz) PreventRenaming("cid" #clazz);
  CLASS_LIST_WITH_NULL(PREVENT_RENAMING)
#undef PREVENT_RENAMING
#undef CLASS_LIST_WITH_NULL

// Prevent renaming of methods that are looked up by method recognizer.
// TODO(dartbug.com/30524) instead call to Obfuscator::Rename from a place
// where these are looked up.
#define PREVENT_RENAMING(class_name, function_name, recognized_enum,           \
                         fingerprint)                                          \
  do {                                                                         \
    PreventRenaming(#class_name);                                              \
    PreventRenaming(#function_name);                                           \
  } while (0);
  RECOGNIZED_LIST(PREVENT_RENAMING)
#undef PREVENT_RENAMING

// Prevent renaming of methods that are looked up by method recognizer.
// TODO(dartbug.com/30524) instead call to Obfuscator::Rename from a place
// where these are looked up.
#define PREVENT_RENAMING(class_name, function_name, recognized_enum,           \
                         fingerprint)                                          \
  do {                                                                         \
    PreventRenaming(#class_name);                                              \
    PreventRenaming(#function_name);                                           \
  } while (0);
  POLYMORPHIC_TARGET_LIST(PREVENT_RENAMING)
#undef PREVENT_RENAMING

  // These are not mentioned by entry points but are still looked up by name.
  // (They are not mentioned in the entry points because we don't need them
  // after the compilation)
  PreventRenaming("_resolveScriptUri");

  // Precompiler is looking up "main".
  // TODO(dartbug.com/30524) instead call to Obfuscator::Rename from a place
  // where these are created.
  PreventRenaming("main");

  // Fast path for common conditional import. See Deobfuscate method.
  PreventRenaming("dart");
  PreventRenaming("library");
  PreventRenaming("io");
  PreventRenaming("html");

  // Looked up by name via "DartUtils::GetDartType".
  PreventRenaming("_RandomAccessFile");
  PreventRenaming("_RandomAccessFileOpsImpl");
  PreventRenaming("ResourceHandle");
  PreventRenaming("_ResourceHandleImpl");
  PreventRenaming("_SocketControlMessageImpl");
  PreventRenaming("_NamespaceImpl");
}

StringPtr Obfuscator::ObfuscationState::RenameImpl(const String& name,
                                                   bool atomic) {
  ASSERT(name.IsSymbol());

  renamed_ ^= renames_.GetOrNull(name);
  if (renamed_.IsNull()) {
    renamed_ = BuildRename(name, atomic);
    renames_.UpdateOrInsert(name, renamed_);
  }
  return renamed_.ptr();
}

static const char* const kGetterPrefix = "get:";
static const intptr_t kGetterPrefixLength = strlen(kGetterPrefix);
static const char* const kSetterPrefix = "set:";
static const intptr_t kSetterPrefixLength = strlen(kSetterPrefix);

void Obfuscator::PreventRenaming(const char* name) {
  // For constructor names Class.name skip class name (if any) and a dot.
  const char* dot = strchr(name, '.');
  if (dot != nullptr) {
    name = dot + 1;
  }

  // Empty name: do nothing.
  if (name[0] == '\0') {
    return;
  }

  // Skip get: and set: prefixes.
  if (strncmp(name, kGetterPrefix, kGetterPrefixLength) == 0) {
    name = name + kGetterPrefixLength;
  } else if (strncmp(name, kSetterPrefix, kSetterPrefixLength) == 0) {
    name = name + kSetterPrefixLength;
  }

  state_->PreventRenaming(name);
}

void Obfuscator::ObfuscationState::SaveState() {
  saved_state_.SetAt(kSavedStateNameIndex, String::Handle(String::New(name_)));
  saved_state_.SetAt(kSavedStateRenamesIndex, renames_.Release());
  thread_->isolate_group()->object_store()->set_obfuscation_map(saved_state_);
}

void Obfuscator::ObfuscationState::PreventRenaming(const char* name) {
  string_ = Symbols::New(thread_, name);
  PreventRenaming(string_);
}

void Obfuscator::ObfuscationState::PreventRenaming(const String& name) {
  renames_.UpdateOrInsert(name, name);
}

void Obfuscator::ObfuscationState::NextName() {
  // We apply the following rules:
  //
  //         inc(a) = b, ... , inc(z) = A, ..., inc(Z) = a & carry.
  //
  for (intptr_t i = 0;; i++) {
    const char digit = name_[i];
    if (digit == '\0') {
      name_[i] = 'a';
    } else if (digit < 'Z') {
      name_[i]++;
    } else if (digit == 'Z') {
      name_[i] = 'a';
      continue;  // Carry.
    } else if (digit < 'z') {
      name_[i]++;
    } else {
      name_[i] = 'A';
    }
    break;
  }
}

StringPtr Obfuscator::ObfuscationState::NewAtomicRename(
    bool should_be_private) {
  do {
    NextName();
    renamed_ = Symbols::NewFormatted(thread_, "%s%s",
                                     should_be_private ? "_" : "", name_);
    // Must check if our generated name clashes with something that will
    // have an identity renaming.
  } while (renames_.GetOrNull(renamed_) == renamed_.ptr());
  return renamed_.ptr();
}

StringPtr Obfuscator::ObfuscationState::BuildRename(const String& name,
                                                    bool atomic) {
  // Do not rename record positional field names $1, $2 etc
  // in order to handle them properly during dynamic invocations.
  if (Record::GetPositionalFieldIndexFromFieldName(name) >= 0) {
    return name.ptr();
  }

  if (atomic) {
    return NewAtomicRename(name.CharAt(0) == '_');
  }

  intptr_t start = 0;
  intptr_t end = name.Length();

  // Follow the rules:
  //
  //         Rename(get:foo) = get:Rename(foo).
  //         Rename(set:foo) = set:Rename(foo).
  //
  bool is_getter = false;
  bool is_setter = false;
  if (Field::IsGetterName(name)) {
    is_getter = true;
    start = kGetterPrefixLength;
  } else if (Field::IsSetterName(name)) {
    is_setter = true;
    start = kSetterPrefixLength;
  }

  // Follow the rule:
  //
  //         Rename(_ident@key) = Rename(_ident)@private_key_.
  //
  const bool is_private = name.CharAt(start) == '_';
  if (is_private) {
    // Find the first '@'.
    intptr_t i = start;
    while (i < name.Length() && name.CharAt(i) != '@') {
      i++;
    }
    end = i;
  }

  if (is_getter || is_setter || is_private) {
    string_ = Symbols::New(thread_, name, start, end - start);
    // It's OK to call RenameImpl() recursively because 'string_' is used
    // only if atomic == false.
    string_ = RenameImpl(string_, /*atomic=*/true);
    if (is_private && (end < name.Length())) {
      string_ = Symbols::FromConcat(thread_, string_, private_key_);
    }
    if (is_getter) {
      return Symbols::FromGet(thread_, string_);
    } else if (is_setter) {
      return Symbols::FromSet(thread_, string_);
    }
    return string_.ptr();
  } else {
    return NewAtomicRename(is_private);
  }
}

void Obfuscator::Deobfuscate(Thread* thread,
                             const GrowableObjectArray& pieces) {
  const Array& obfuscation_state =
      Array::Handle(thread->zone(),
                    thread->isolate_group()->object_store()->obfuscation_map());
  if (obfuscation_state.IsNull()) {
    return;
  }

  const Array& renames = Array::Handle(
      thread->zone(), GetRenamesFromSavedState(obfuscation_state));

  ObfuscationMap renames_map(renames.ptr());
  String& piece = String::Handle();
  for (intptr_t i = 0; i < pieces.Length(); i++) {
    piece ^= pieces.At(i);
    ASSERT(piece.IsSymbol());

    // Fast path: skip '.'
    if (piece.ptr() == Symbols::Dot().ptr()) {
      continue;
    }

    // Fast path: check if piece has an identity obfuscation.
    if (renames_map.GetOrNull(piece) == piece.ptr()) {
      continue;
    }

    // Search through the whole obfuscation map until matching value is found.
    // We are using linear search instead of generating a reverse mapping
    // because we assume that Deobfuscate() method is almost never called.
    ObfuscationMap::Iterator it(&renames_map);
    while (it.MoveNext()) {
      const intptr_t entry = it.Current();
      if (renames_map.GetPayload(entry, 0) == piece.ptr()) {
        piece ^= renames_map.GetKey(entry);
        pieces.SetAt(i, piece);
        break;
      }
    }
  }
  renames_map.Release();
}

static const char* StringToCString(const String& str) {
  const intptr_t len = Utf8::Length(str);
  char* result = new char[len + 1];
  str.ToUTF8(reinterpret_cast<uint8_t*>(result), len);
  result[len] = 0;
  return result;
}

const char** Obfuscator::SerializeMap(Thread* thread) {
  const Array& obfuscation_state =
      Array::Handle(thread->zone(),
                    thread->isolate_group()->object_store()->obfuscation_map());
  if (obfuscation_state.IsNull()) {
    return nullptr;
  }

  const Array& renames = Array::Handle(
      thread->zone(), GetRenamesFromSavedState(obfuscation_state));
  ObfuscationMap renames_map(renames.ptr());

  const char** result = new const char*[renames_map.NumOccupied() * 2 + 1];
  intptr_t idx = 0;
  String& str = String::Handle();

  ObfuscationMap::Iterator it(&renames_map);
  while (it.MoveNext()) {
    const intptr_t entry = it.Current();
    str ^= renames_map.GetKey(entry);
    result[idx++] = StringToCString(str);
    str ^= renames_map.GetPayload(entry, 0);
    result[idx++] = StringToCString(str);
  }
  result[idx++] = nullptr;
  renames_map.Release();

  return result;
}

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

}  // namespace dart
