// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/aot/precompiler.h"

#include "platform/unicode.h"
#include "vm/canonical_tables.h"
#include "vm/class_finalizer.h"
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
#include "vm/compiler/backend/il_serializer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/backend/redundancy_elimination.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
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
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/type_testing_stubs.h"
#include "vm/version.h"
#include "vm/zone_text_buffer.h"

namespace dart {

#define T (thread())
#define I (isolate())
#define Z (zone())

DEFINE_FLAG(bool, print_unique_targets, false, "Print unique dynamic targets");
DEFINE_FLAG(bool, print_gop, false, "Print global object pool");
DEFINE_FLAG(bool, trace_precompiler, false, "Trace precompiler.");
DEFINE_FLAG(
    int,
    max_speculative_inlining_attempts,
    1,
    "Max number of attempts with speculative inlining (precompilation only)");

DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, trace_optimizing_compiler);
DECLARE_FLAG(bool, trace_bailout);
DECLARE_FLAG(bool, huge_method_cutoff_in_code_size);
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

DEFINE_FLAG(charp,
            serialize_flow_graphs_to,
            nullptr,
            "Serialize flow graphs to the given file");

DEFINE_FLAG(bool,
            populate_llvm_constant_pool,
            false,
            "Add constant pool entries from flow graphs to a special pool "
            "serialized in AOT snapshots (with --serialize_flow_graphs_to)");

Precompiler* Precompiler::singleton_ = nullptr;

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

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
  Isolate* isolate() const { return thread_->isolate(); }

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
    return Error::null();
  } else {
    return Thread::Current()->StealStickyError();
  }
}

Precompiler::Precompiler(Thread* thread)
    : thread_(thread),
      zone_(NULL),
      isolate_(thread->isolate()),
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
      dropped_library_count_(0),
      libraries_(GrowableObjectArray::Handle(I->object_store()->libraries())),
      pending_functions_(
          GrowableObjectArray::Handle(GrowableObjectArray::New())),
      sent_selectors_(),
      seen_functions_(HashTables::New<FunctionSet>(/*initial_capacity=*/1024)),
      possibly_retained_functions_(
          HashTables::New<FunctionSet>(/*initial_capacity=*/1024)),
      fields_to_retain_(),
      functions_to_retain_(
          HashTables::New<FunctionSet>(/*initial_capacity=*/1024)),
      classes_to_retain_(),
      typeargs_to_retain_(),
      types_to_retain_(),
      typeparams_to_retain_(),
      consts_to_retain_(),
      seen_table_selectors_(),
      error_(Error::Handle()),
      get_runtime_type_is_unique_(false),
      il_serialization_stream_(nullptr) {
  ASSERT(Precompiler::singleton_ == NULL);
  Precompiler::singleton_ = this;
}

Precompiler::~Precompiler() {
  // We have to call Release() in DEBUG mode.
  seen_functions_.Release();
  possibly_retained_functions_.Release();
  functions_to_retain_.Release();

  ASSERT(Precompiler::singleton_ == this);
  Precompiler::singleton_ = NULL;
}

void Precompiler::DoCompileAll() {
  {
    StackZone stack_zone(T);
    zone_ = stack_zone.GetZone();

    if (FLAG_use_bare_instructions) {
      // Since we keep the object pool until the end of AOT compilation, it
      // will hang on to its entries until the very end. Therefore we have
      // to use handles which survive that long, so we use [zone_] here.
      global_object_pool_builder_.InitializeWithZone(zone_);
    }

    {
      HANDLESCOPE(T);

      // Make sure class hierarchy is stable before compilation so that CHA
      // can be used. Also ensures lookup of entry points won't miss functions
      // because their class hasn't been finalized yet.
      FinalizeAllClasses();
      ASSERT(Error::Handle(Z, T->sticky_error()).IsNull());

      ClassFinalizer::SortClasses();

      // Collects type usage information which allows us to decide when/how to
      // optimize runtime type tests.
      TypeUsageInfo type_usage_info(T);

      // The cid-ranges of subclasses of a class are e.g. used for is/as checks
      // as well as other type checks.
      HierarchyInfo hierarchy_info(T);

      if (FLAG_use_bare_instructions && FLAG_use_table_dispatch) {
        dispatch_table_generator_ = new compiler::DispatchTableGenerator(Z);
        dispatch_table_generator_->Initialize(I->class_table());
      }

      // Precompile constructors to compute information such as
      // optimized instruction count (used in inlining heuristics).
      ClassFinalizer::ClearAllCode(
          /*including_nonchanging_cids=*/FLAG_use_bare_instructions);

      {
        CompilerState state(thread_, /*is_aot=*/true, /*is_optimizing=*/true);
        PrecompileConstructors();
      }

      ClassFinalizer::ClearAllCode(
          /*including_nonchanging_cids=*/FLAG_use_bare_instructions);

      // After this point, it should be safe to serialize flow graphs produced
      // during compilation and add constants to the LLVM constant pool.
      //
      // Check that both the file open and write callbacks are available, though
      // we only use the latter during IL processing.
      if (FLAG_serialize_flow_graphs_to != nullptr &&
          Dart::file_write_callback() != nullptr) {
        if (auto file_open = Dart::file_open_callback()) {
          auto file = file_open(FLAG_serialize_flow_graphs_to, /*write=*/true);
          set_il_serialization_stream(file);
        }
        if (FLAG_populate_llvm_constant_pool) {
          auto const object_store = I->object_store();
          auto& llvm_constants = GrowableObjectArray::Handle(
              Z, GrowableObjectArray::New(16, Heap::kOld));
          auto& llvm_functions = GrowableObjectArray::Handle(
              Z, GrowableObjectArray::New(16, Heap::kOld));
          auto& llvm_constant_hash_table = Array::Handle(
              Z, HashTables::New<FlowGraphSerializer::LLVMPoolMap>(16,
                                                                   Heap::kOld));
          object_store->set_llvm_constant_pool(llvm_constants);
          object_store->set_llvm_function_pool(llvm_functions);
          object_store->set_llvm_constant_hash_table(llvm_constant_hash_table);
        }
      }

      tracer_ = PrecompilerTracer::StartTracingIfRequested(this);

      // All stubs have already been generated, all of them share the same pool.
      // We use that pool to initialize our global object pool, to guarantee
      // stubs as well as code compiled from here on will have the same pool.
      if (FLAG_use_bare_instructions) {
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
  I->object_store()->set_##member(stub_code);
        OBJECT_STORE_STUB_CODE_LIST(DO)
#undef DO
        stub_code =
            StubCode::GetBuildMethodExtractorStub(global_object_pool_builder());
        I->object_store()->set_build_method_extractor_code(stub_code);
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
      // canonical.
      AddTypeArguments(
          TypeArguments::Handle(Z, I->object_store()->type_argument_int()));
      AddTypeArguments(
          TypeArguments::Handle(Z, I->object_store()->type_argument_double()));
      AddTypeArguments(
          TypeArguments::Handle(Z, I->object_store()->type_argument_string()));
      AddTypeArguments(TypeArguments::Handle(
          Z, I->object_store()->type_argument_string_dynamic()));
      AddTypeArguments(TypeArguments::Handle(
          Z, I->object_store()->type_argument_string_string()));

      // Compile newly found targets and add their callees until we reach a
      // fixed point.
      Iterate();

      // Replace the default type testing stubs installed on [Type]s with new
      // [Type]-specialized stubs.
      AttachOptimizedTypeTestingStub();

      if (FLAG_use_bare_instructions) {
        // Now we generate the actual object pool instance and attach it to the
        // object store. The AOT runtime will use it from there in the enter
        // dart code stub.
        const auto& pool = ObjectPool::Handle(
            ObjectPool::NewFromBuilder(*global_object_pool_builder()));
        I->object_store()->set_global_object_pool(pool);
        global_object_pool_builder()->Reset();

        if (FLAG_print_gop) {
          THR_Print("Global object pool:\n");
          pool.DebugPrint();
        }
      }

      if (FLAG_serialize_flow_graphs_to != nullptr &&
          Dart::file_write_callback() != nullptr) {
        if (auto file_close = Dart::file_close_callback()) {
          file_close(il_serialization_stream());
        }
        set_il_serialization_stream(nullptr);
        if (FLAG_populate_llvm_constant_pool) {
          // We don't want the Array backing for any mappings in the snapshot,
          // only the pools themselves.
          I->object_store()->set_llvm_constant_hash_table(Array::null_array());

          // Keep any functions, classes, etc. referenced from the LLVM pools,
          // even if they could have been dropped due to not being otherwise
          // needed at runtime.
          const auto& constant_pool = GrowableObjectArray::Handle(
              Z, I->object_store()->llvm_constant_pool());
          auto& object = Object::Handle(Z);
          for (intptr_t i = 0; i < constant_pool.Length(); i++) {
            object = constant_pool.At(i);
            if (object.IsNull()) continue;
            if (object.IsInstance()) {
              AddConstObject(Instance::Cast(object));
            } else if (object.IsField()) {
              AddField(Field::Cast(object));
            } else if (object.IsFunction()) {
              AddFunction(Function::Cast(object));
            }
          }

          const auto& function_pool = GrowableObjectArray::Handle(
              Z, I->object_store()->llvm_function_pool());
          auto& function = Function::Handle(Z);
          for (intptr_t i = 0; i < function_pool.Length(); i++) {
            function ^= function_pool.At(i);
            AddFunction(function);
          }
        }
      }

      if (tracer_ != nullptr) {
        tracer_->Finalize();
        tracer_ = nullptr;
      }

      TraceForRetainedFunctions();
      FinalizeDispatchTable();
      ReplaceFunctionStaticCallEntries();

      DropFunctions();
      DropFields();
      TraceTypesFromRetainedClasses();
      DropTypes();
      DropTypeParameters();
      DropTypeArguments();

      // Clear these before dropping classes as they may hold onto otherwise
      // dead instances of classes we will remove or otherwise unused symbols.
      I->object_store()->set_unique_dynamic_targets(Array::null_array());
      Class& null_class = Class::Handle(Z);
      Function& null_function = Function::Handle(Z);
      Field& null_field = Field::Handle(Z);
      I->object_store()->set_pragma_class(null_class);
      I->object_store()->set_pragma_name(null_field);
      I->object_store()->set_pragma_options(null_field);
      I->object_store()->set_completer_class(null_class);
      I->object_store()->set_symbol_class(null_class);
      I->object_store()->set_compiletime_error_class(null_class);
      I->object_store()->set_growable_list_factory(null_function);
      I->object_store()->set_simple_instance_of_function(null_function);
      I->object_store()->set_simple_instance_of_true_function(null_function);
      I->object_store()->set_simple_instance_of_false_function(null_function);
      I->object_store()->set_async_star_move_next_helper(null_function);
      I->object_store()->set_complete_on_async_return(null_function);
      I->object_store()->set_async_star_stream_controller(null_class);
      DropMetadata();
      DropLibraryEntries();
    }
    DropClasses();
    DropLibraries();

    Obfuscate();

#if defined(DEBUG)
    const auto& non_visited =
        Function::Handle(Z, FindUnvisitedRetainedFunction());
    if (!non_visited.IsNull()) {
      FATAL1("Code visitor would miss the code for function \"%s\"\n",
             non_visited.ToFullyQualifiedCString());
    }
#endif
    ProgramVisitor::Dedup(T);

    zone_ = NULL;
  }

  intptr_t symbols_before = -1;
  intptr_t symbols_after = -1;
  intptr_t capacity = -1;
  if (FLAG_trace_precompiler) {
    Symbols::GetStats(I, &symbols_before, &capacity);
  }

  if (FLAG_trace_precompiler) {
    Symbols::GetStats(I, &symbols_after, &capacity);
    THR_Print("Precompiled %" Pd " functions,", function_count_);
    THR_Print(" %" Pd " dynamic types,", class_count_);
    THR_Print(" %" Pd " dynamic selectors.\n", selector_count_);

    THR_Print("Dropped %" Pd " functions,", dropped_function_count_);
    THR_Print(" %" Pd " fields,", dropped_field_count_);
    THR_Print(" %" Pd " symbols,", symbols_before - symbols_after);
    THR_Print(" %" Pd " types,", dropped_type_count_);
    THR_Print(" %" Pd " type arguments,", dropped_typearg_count_);
    THR_Print(" %" Pd " classes,", dropped_class_count_);
    THR_Print(" %" Pd " libraries.\n", dropped_library_count_);
  }
}

void Precompiler::PrecompileConstructors() {
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
      CompileFunction(precompiler_, Thread::Current(), zone_, function);
    }

   private:
    Precompiler* precompiler_;
    Zone* zone_;
  };

  phase_ = Phase::kCompilingConstructorsForInstructionCounts;
  HANDLESCOPE(T);
  ConstructorVisitor visitor(this, Z);
  ProgramVisitor::WalkProgram(Z, I, &visitor);
  phase_ = Phase::kPreparation;
}

void Precompiler::AddRoots() {
  // Note that <rootlibrary>.main is not a root. The appropriate main will be
  // discovered through _getMainClosure.

  AddSelector(Symbols::NoSuchMethod());

  AddSelector(Symbols::Call());  // For speed, not correctness.

  const Library& lib = Library::Handle(I->object_store()->root_library());
  if (lib.IsNull()) {
    const String& msg = String::Handle(
        Z, String::New("Cannot find root library in isolate.\n"));
    Jump(Error::Handle(Z, ApiError::New(msg)));
    UNREACHABLE();
  }

  const String& name = String::Handle(String::New("main"));
  const Object& main_closure = Object::Handle(lib.GetFunctionClosure(name));
  if (main_closure.IsClosure()) {
    if (lib.LookupLocalFunction(name) == Function::null()) {
      // Check whether the function is in exported namespace of library, in
      // this case we have to retain the root library caches.
      if (lib.LookupFunctionAllowPrivate(name) != Function::null() ||
          lib.LookupReExport(name) != Object::null()) {
        retain_root_library_caches_ = true;
      }
    }
    AddConstObject(Closure::Cast(main_closure));
  } else if (main_closure.IsError()) {
    const Error& error = Error::Cast(main_closure);
    String& msg =
        String::Handle(Z, String::NewFormatted("Cannot find main closure %s\n",
                                               error.ToErrorCString()));
    Jump(Error::Handle(Z, ApiError::New(msg)));
    UNREACHABLE();
  }
}

void Precompiler::Iterate() {
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
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Class& subcls = Class::Handle(Z);
  Array& fields = Array::Handle(Z);
  Field& field = Field::Handle(Z);
  Function& function = Function::Handle(Z);
  Function& dispatcher = Function::Handle(Z);
  Array& args_desc = Array::Handle(Z);
  AbstractType& field_type = AbstractType::Handle(Z);
  String& field_name = String::Handle(Z);
  GrowableArray<intptr_t> cids;

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
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
        function = Type::Cast(field_type).signature();
        if (function.IsGeneric()) continue;
        if (function.HasOptionalParameters()) continue;
        if (FLAG_trace_precompiler) {
          THR_Print("Found callback field %s\n", field_name.ToCString());
        }

        // TODO(dartbug.com/33549): Update this code to use the size of the
        // parameters when supporting calls to non-static methods with
        // unboxed parameters.
        args_desc =
            ArgumentsDescriptor::NewBoxed(0,  // No type argument vector.
                                          function.num_fixed_parameters());
        cids.Clear();
        if (CHA::ConcreteSubclasses(cls, &cids)) {
          for (intptr_t j = 0; j < cids.length(); ++j) {
            subcls = I->class_table()->At(cids[j]);
            if (subcls.is_allocated()) {
              // Add dispatcher to cls.
              dispatcher = subcls.GetInvocationDispatcher(
                  field_name, args_desc, FunctionLayout::kInvokeFieldDispatcher,
                  /* create_if_absent = */ true);
              if (FLAG_trace_precompiler) {
                THR_Print("Added invoke-field-dispatcher for %s to %s\n",
                          field_name.ToCString(), subcls.ToCString());
              }
              AddFunction(dispatcher);
            }
          }
        }
      }
    }
  }
}

void Precompiler::ProcessFunction(const Function& function) {
  const intptr_t gop_offset =
      FLAG_use_bare_instructions ? global_object_pool_builder()->CurrentLength()
                                 : 0;
  RELEASE_ASSERT(!function.HasCode());

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
      AddFunction(Function::Cast(entry), FLAG_retain_function_objects);
      ASSERT(view.Get<Code::kSCallTableCodeOrTypeTarget>() == Code::null());
      continue;
    }
    entry = view.Get<Code::kSCallTableCodeOrTypeTarget>();
    if (entry.IsCode() && Code::Cast(entry).IsAllocationStubCode()) {
      cls ^= Code::Cast(entry).owner();
      AddInstantiatedClass(cls);
    }
  }

#if defined(TARGET_ARCH_IA32)
  FATAL("Callee scanning unimplemented for IA32");
#endif

  String& selector = String::Handle(Z);
  // When tracing we want to scan the object pool attached to the code object
  // rather than scanning global object pool - because we want to include
  // *all* outgoing references into the trace. Scanning GOP would exclude
  // references that have been deduplicated.
  if (FLAG_use_bare_instructions && !is_tracing()) {
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

  const Array& inlined_functions =
      Array::Handle(Z, code.inlined_id_to_function());
  for (intptr_t i = 0; i < inlined_functions.Length(); i++) {
    target ^= inlined_functions.At(i);
    AddTypesOf(target);
  }
}

static bool IsPotentialClosureCall(const String& selector) {
  return selector.raw() == Symbols::Call().raw() ||
         selector.raw() == Symbols::DynamicCall().raw();
}

void Precompiler::AddCalleesOfHelper(const Object& entry,
                                     String* temp_selector,
                                     Class* temp_cls) {
  if (entry.IsUnlinkedCall()) {
    const auto& call_site = UnlinkedCall::Cast(entry);
    // A dynamic call.
    *temp_selector = call_site.target_name();
    AddSelector(*temp_selector);
    if (IsPotentialClosureCall(*temp_selector)) {
      const Array& arguments_descriptor =
          Array::Handle(Z, call_site.arguments_descriptor());
      AddClosureCall(*temp_selector, arguments_descriptor);
    }
  } else if (entry.IsMegamorphicCache()) {
    // A dynamic call.
    const auto& cache = MegamorphicCache::Cast(entry);
    *temp_selector = cache.target_name();
    AddSelector(*temp_selector);
    if (IsPotentialClosureCall(*temp_selector)) {
      const Array& arguments_descriptor =
          Array::Handle(Z, cache.arguments_descriptor());
      AddClosureCall(*temp_selector, arguments_descriptor);
    }
  } else if (entry.IsField()) {
    // Potential need for field initializer.
    const auto& field = Field::Cast(entry);
    AddField(field);
  } else if (entry.IsInstance()) {
    // Const object, literal or args descriptor.
    const auto& instance = Instance::Cast(entry);
    AddConstObject(instance);
  } else if (entry.IsFunction()) {
    // Local closure function.
    const auto& target = Function::Cast(entry);
    AddFunction(target);
  } else if (entry.IsCode()) {
    const auto& target_code = Code::Cast(entry);
    if (target_code.IsAllocationStubCode()) {
      *temp_cls ^= target_code.owner();
      AddInstantiatedClass(*temp_cls);
    }
  }
}

void Precompiler::AddTypesOf(const Class& cls) {
  if (cls.IsNull()) return;
  if (classes_to_retain_.HasKey(&cls)) return;
  classes_to_retain_.Insert(&Class::ZoneHandle(Z, cls.raw()));

  Array& interfaces = Array::Handle(Z, cls.interfaces());
  AbstractType& type = AbstractType::Handle(Z);
  for (intptr_t i = 0; i < interfaces.Length(); i++) {
    type ^= interfaces.At(i);
    AddType(type);
  }

  AddTypeArguments(TypeArguments::Handle(Z, cls.type_parameters()));

  type = cls.super_type();
  AddType(type);

  if (cls.IsTypedefClass()) {
    AddTypesOf(Function::Handle(Z, cls.signature_function()));
  }
}

void Precompiler::AddTypesOf(const Function& function) {
  if (function.IsNull()) return;
  if (functions_to_retain_.ContainsKey(function)) return;
  functions_to_retain_.Insert(function);

  AddTypeArguments(TypeArguments::Handle(Z, function.type_parameters()));

  AbstractType& type = AbstractType::Handle(Z);
  type = function.result_type();
  AddType(type);
  for (intptr_t i = 0; i < function.NumParameters(); i++) {
    type = function.ParameterTypeAt(i);
    AddType(type);
  }
  // At this point, ensure any cached default type arguments are canonicalized.
  function.UpdateCachedDefaultTypeArguments(thread());
  if (function.CachesDefaultTypeArguments()) {
    const auto& defaults = TypeArguments::Handle(
        Z, function.default_type_arguments(/*kind_out=*/nullptr));
    ASSERT(defaults.IsCanonical());
    AddTypeArguments(defaults);
  }
  Code& code = Code::Handle(Z, function.CurrentCode());
  if (code.IsNull()) {
    ASSERT(function.kind() == FunctionLayout::kSignatureFunction);
  } else {
    const ExceptionHandlers& handlers =
        ExceptionHandlers::Handle(Z, code.exception_handlers());
    if (!handlers.IsNull()) {
      Array& types = Array::Handle(Z);
      for (intptr_t i = 0; i < handlers.num_entries(); i++) {
        types = handlers.GetHandledTypes(i);
        for (intptr_t j = 0; j < types.Length(); j++) {
          type ^= types.At(j);
          AddType(type);
        }
      }
    }
  }
  // A function can always be inlined and have only a nested local function
  // remain.
  const Function& parent = Function::Handle(Z, function.parent_function());
  if (!parent.IsNull()) {
    AddTypesOf(parent);
  }
  if (function.IsSignatureFunction() || function.IsClosureFunction()) {
    type = function.ExistingSignatureType();
    if (!type.IsNull()) {
      AddType(type);
    }
  }
  // A class may have all functions inlined except a local function.
  const Class& owner = Class::Handle(Z, function.Owner());
  AddTypesOf(owner);
}

void Precompiler::AddType(const AbstractType& abstype) {
  if (abstype.IsNull()) return;

  if (abstype.IsTypeParameter()) {
    const auto& param = TypeParameter::Cast(abstype);
    if (typeparams_to_retain_.HasKey(&param)) return;
    typeparams_to_retain_.Insert(&TypeParameter::ZoneHandle(Z, param.raw()));

    auto& type = AbstractType::Handle(Z, param.bound());
    AddType(type);
    type = param.default_argument();
    AddType(type);
    const auto& function = Function::Handle(Z, param.parameterized_function());
    AddTypesOf(function);
    const Class& cls = Class::Handle(Z, param.parameterized_class());
    AddTypesOf(cls);
    return;
  }

  if (types_to_retain_.HasKey(&abstype)) return;
  types_to_retain_.Insert(&AbstractType::ZoneHandle(Z, abstype.raw()));

  if (abstype.IsType()) {
    const Type& type = Type::Cast(abstype);
    const Class& cls = Class::Handle(Z, type.type_class());
    AddTypesOf(cls);
    const TypeArguments& vector = TypeArguments::Handle(Z, abstype.arguments());
    AddTypeArguments(vector);
    if (type.IsFunctionType()) {
      const Function& func = Function::Handle(Z, type.signature());
      AddTypesOf(func);
    }
  } else if (abstype.IsTypeRef()) {
    AbstractType& type = AbstractType::Handle(Z);
    type = TypeRef::Cast(abstype).type();
    AddType(type);
  }
}

void Precompiler::AddTypeArguments(const TypeArguments& args) {
  if (args.IsNull()) return;

  if (typeargs_to_retain_.HasKey(&args)) return;
  typeargs_to_retain_.Insert(&TypeArguments::ZoneHandle(Z, args.raw()));

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

  if (instance.raw() == Object::sentinel().raw() ||
      instance.raw() == Object::transition_sentinel().raw()) {
    return;
  }

  Class& cls = Class::Handle(Z, instance.clazz());
  AddInstantiatedClass(cls);

  if (instance.IsClosure()) {
    // An implicit static closure.
    const Function& func =
        Function::Handle(Z, Closure::Cast(instance).function());
    ASSERT(func.is_static());
    AddFunction(func);
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
      classes_to_retain_.Insert(&Class::ZoneHandle(Z, cls.raw()));
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

  consts_to_retain_.Insert(&Instance::ZoneHandle(Z, instance.raw()));

  if (cls.NumTypeArguments() > 0) {
    AddTypeArguments(TypeArguments::Handle(Z, instance.GetTypeArguments()));
  }

  class ConstObjectVisitor : public ObjectPointerVisitor {
   public:
    ConstObjectVisitor(Precompiler* precompiler, Isolate* isolate)
        : ObjectPointerVisitor(isolate->group()),
          precompiler_(precompiler),
          subinstance_(Object::Handle()) {}

    virtual void VisitPointers(ObjectPtr* first, ObjectPtr* last) {
      for (ObjectPtr* current = first; current <= last; current++) {
        subinstance_ = *current;
        if (subinstance_.IsInstance()) {
          precompiler_->AddConstObject(Instance::Cast(subinstance_));
        }
      }
      subinstance_ = Object::null();
    }

   private:
    Precompiler* precompiler_;
    Object& subinstance_;
  };

  ConstObjectVisitor visitor(this, I);
  instance.raw()->ptr()->VisitPointers(&visitor);
}

void Precompiler::AddClosureCall(const String& call_selector,
                                 const Array& arguments_descriptor) {
  const Class& cache_class =
      Class::Handle(Z, I->object_store()->closure_class());
  const Function& dispatcher =
      Function::Handle(Z, cache_class.GetInvocationDispatcher(
                              call_selector, arguments_descriptor,
                              FunctionLayout::kInvokeFieldDispatcher,
                              true /* create_if_absent */));
  AddFunction(dispatcher);
}

void Precompiler::AddField(const Field& field) {
  if (is_tracing()) {
    tracer_->WriteFieldRef(field);
  }

  if (fields_to_retain_.HasKey(&field)) return;

  fields_to_retain_.Insert(&Field::ZoneHandle(Z, field.raw()));

  if (field.is_static()) {
    const Object& value = Object::Handle(Z, field.StaticValue());
    // Should not be in the middle of initialization while precompiling.
    ASSERT(value.raw() != Object::transition_sentinel().raw());

    if (value.raw() != Object::sentinel().raw() &&
        value.raw() != Object::null()) {
      ASSERT(value.IsInstance());
      AddConstObject(Instance::Cast(value));
    }
  }

  if (field.has_nontrivial_initializer() &&
      (field.is_static() || field.is_late())) {
    const Function& initializer =
        Function::ZoneHandle(Z, field.EnsureInitializerFunction());
    AddFunction(initializer);
  }
}

bool Precompiler::MustRetainFunction(const Function& function) {
  // There are some cases where we must retain, even if there are no directly
  // observable need for function objects at runtime. Here, we check for cases
  // where the function is not marked with the vm:entry-point pragma, which also
  // forces retention:
  //
  // * Native functions (for LinkNativeCall)
  // * Selector matches a symbol used in Resolver::ResolveDynamic calls
  //   in dart_entry.cc or dart_api_impl.cc.
  // * _Closure.call (used in async stack handling)
  if (function.is_native()) return true;

  // Resolver::ResolveDynamic uses.
  const auto& selector = String::Handle(Z, function.name());
  if (selector.raw() == Symbols::toString().raw()) return true;
  if (selector.raw() == Symbols::AssignIndexToken().raw()) return true;
  if (selector.raw() == Symbols::IndexToken().raw()) return true;
  if (selector.raw() == Symbols::hashCode().raw()) return true;
  if (selector.raw() == Symbols::NoSuchMethod().raw()) return true;
  if (selector.raw() == Symbols::EqualOperator().raw()) return true;

  // Use the same check for _Closure.call as in stack_trace.{h|cc}.
  if (selector.raw() == Symbols::Call().raw()) {
    const auto& name = String::Handle(Z, function.QualifiedScrubbedName());
    if (name.Equals(Symbols::_ClosureCall())) return true;
  }

  // We have to retain functions which can be a target of a SwitchableCall
  // at AOT runtime, since the AOT runtime needs to be able to find the
  // function object in the class.
  if (function.NeedsMonomorphicCheckedEntry(Z) ||
      Function::IsDynamicInvocationForwarderName(function.name())) {
    return true;
  }

  return false;
}

void Precompiler::AddFunction(const Function& function, bool retain) {
  if (is_tracing()) {
    tracer_->WriteFunctionRef(function);
  }

  if (possibly_retained_functions_.ContainsKey(function)) return;
  if (retain || MustRetainFunction(function)) {
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
    sent_selectors_.Insert(&String::ZoneHandle(Z, selector.raw()));
    selector_count_++;
    changed_ = true;

    if (FLAG_trace_precompiler) {
      THR_Print("Enqueueing selector %" Pd " %s\n", selector_count_,
                selector.ToCString());
    }
  }
}

void Precompiler::AddTableSelector(const compiler::TableSelector* selector) {
  ASSERT(FLAG_use_bare_instructions && FLAG_use_table_dispatch);

  if (is_tracing()) {
    tracer_->WriteTableSelectorRef(selector->id);
  }

  if (seen_table_selectors_.HasKey(selector->id)) return;

  seen_table_selectors_.Insert(selector->id);
  changed_ = true;
}

bool Precompiler::IsHitByTableSelector(const Function& function) {
  if (!(FLAG_use_bare_instructions && FLAG_use_table_dispatch)) {
    return false;
  }

  const int32_t selector_id = selector_map()->SelectorId(function);
  if (selector_id == compiler::SelectorMap::kInvalidSelectorId) return false;
  return seen_table_selectors_.HasKey(selector_id);
}

void Precompiler::AddInstantiatedClass(const Class& cls) {
  if (is_tracing()) {
    tracer_->WriteClassInstantiationRef(cls);
  }

  if (cls.is_allocated()) return;

  class_count_++;
  cls.set_is_allocated(true);
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
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();

      // Check for @pragma on the class itself.
      if (cls.has_pragma()) {
        metadata ^= lib.GetMetadata(cls);
        if (FindEntryPointPragma(isolate(), metadata, &reusable_field_handle,
                                 &reusable_object_handle) ==
            EntryPointPragma::kAlways) {
          AddInstantiatedClass(cls);
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
          EntryPointPragma pragma =
              FindEntryPointPragma(isolate(), metadata, &reusable_field_handle,
                                   &reusable_object_handle);
          if (pragma == EntryPointPragma::kNever) continue;

          AddField(field);

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
          auto type =
              FindEntryPointPragma(isolate(), metadata, &reusable_field_handle,
                                   &reusable_object_handle);

          if (type == EntryPointPragma::kAlways ||
              type == EntryPointPragma::kCallOnly) {
            AddFunction(function);
          }

          if ((type == EntryPointPragma::kAlways ||
               type == EntryPointPragma::kGetterOnly) &&
              function.kind() != FunctionLayout::kConstructor &&
              !function.IsSetterFunction()) {
            function2 = function.ImplicitClosureFunction();
            AddFunction(function2);
          }

          if (function.IsGenerativeConstructor()) {
            AddInstantiatedClass(cls);
          }
        }
        if (function.kind() == FunctionLayout::kImplicitGetter &&
            !implicit_getters.IsNull()) {
          for (intptr_t i = 0; i < implicit_getters.Length(); ++i) {
            field ^= implicit_getters.At(i);
            if (function.accessor_field() == field.raw()) {
              AddFunction(function);
            }
          }
        }
        if (function.kind() == FunctionLayout::kImplicitSetter &&
            !implicit_setters.IsNull()) {
          for (intptr_t i = 0; i < implicit_setters.Length(); ++i) {
            field ^= implicit_setters.At(i);
            if (function.accessor_field() == field.raw()) {
              AddFunction(function);
            }
          }
        }
        if (function.kind() == FunctionLayout::kImplicitStaticGetter &&
            !implicit_static_getters.IsNull()) {
          for (intptr_t i = 0; i < implicit_static_getters.Length(); ++i) {
            field ^= implicit_static_getters.At(i);
            if (function.accessor_field() == field.raw()) {
              AddFunction(function);
            }
          }
        }
      }

      implicit_getters = GrowableObjectArray::null();
      implicit_setters = GrowableObjectArray::null();
      implicit_static_getters = GrowableObjectArray::null();
    }
  }
}

void Precompiler::CheckForNewDynamicFunctions() {
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
          AddFunction(function);
        }
        if (IsHitByTableSelector(function)) {
          AddFunction(function, FLAG_retain_function_objects);
        }

        bool found_metadata = false;
        kernel::ProcedureAttributesMetadata metadata;

        // Handle the implicit call type conversions.
        if (Field::IsGetterName(selector) &&
            (function.kind() != FunctionLayout::kMethodExtractor)) {
          // Call-through-getter.
          // Function is get:foo and somewhere foo (or dyn:foo) is called.
          // Note that we need to skip method extractors (which were potentially
          // created by DispatchTableGenerator): call of foo will never
          // hit method extractor get:foo, because it will hit an existing
          // method foo first.
          selector2 = Field::NameFromGetter(selector);
          if (IsSent(selector2)) {
            AddFunction(function);
          }
          selector2 = Function::CreateDynamicInvocationForwarderName(selector2);
          if (IsSent(selector2)) {
            selector2 =
                Function::CreateDynamicInvocationForwarderName(selector);
            function2 = function.GetDynamicInvocationForwarder(selector2);
            AddFunction(function2);
          }
        } else if (function.kind() == FunctionLayout::kRegularFunction) {
          selector2 = Field::LookupGetterSymbol(selector);
          selector3 = String::null();
          if (!selector2.IsNull()) {
            selector3 =
                Function::CreateDynamicInvocationForwarderName(selector2);
          }
          if (IsSent(selector2) || IsSent(selector3)) {
            metadata = kernel::ProcedureAttributesOf(function, Z);
            found_metadata = true;

            if (metadata.has_tearoff_uses) {
              // Closurization.
              // Function is foo and somewhere get:foo is called.
              function2 = function.ImplicitClosureFunction();
              AddFunction(function2);

              // Add corresponding method extractor.
              function2 = function.GetMethodExtractor(selector2);
              AddFunction(function2);
            }
          }
        }

        const bool is_getter =
            function.kind() == FunctionLayout::kImplicitGetter ||
            function.kind() == FunctionLayout::kGetterFunction;
        const bool is_setter =
            function.kind() == FunctionLayout::kImplicitSetter ||
            function.kind() == FunctionLayout::kSetterFunction;
        const bool is_regular =
            function.kind() == FunctionLayout::kRegularFunction;
        if (is_getter || is_setter || is_regular) {
          selector2 = Function::CreateDynamicInvocationForwarderName(selector);
          if (IsSent(selector2)) {
            if (function.kind() == FunctionLayout::kImplicitGetter ||
                function.kind() == FunctionLayout::kImplicitSetter) {
              field = function.accessor_field();
              metadata = kernel::ProcedureAttributesOf(field, Z);
            } else if (!found_metadata) {
              metadata = kernel::ProcedureAttributesOf(function, Z);
            }

            if (is_getter) {
              if (metadata.getter_called_dynamically) {
                function2 = function.GetDynamicInvocationForwarder(selector2);
                AddFunction(function2);
              }
            } else {
              if (metadata.method_or_setter_called_dynamically) {
                function2 = function.GetDynamicInvocationForwarder(selector2);
                AddFunction(function2);
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
  static ObjectPtr NewKey(const String& str) { return str.raw(); }
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

  *dyn_function = function.raw();
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
      key_demangled = key.raw();
      if (Function::IsDynamicInvocationForwarderName(key)) {
        key_demangled = Function::DemangleDynamicInvocationForwarderName(key);
      }
      if (function.name() != key.raw() &&
          function.name() != key_demangled.raw()) {
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

  isolate()->object_store()->set_unique_dynamic_targets(
      functions_map.Release());
  table.Release();
}

void Precompiler::TraceForRetainedFunctions() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  String& name = String::Handle(Z);
  Function& function = Function::Handle(Z);
  Function& function2 = Function::Handle(Z);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      functions = cls.current_functions();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        bool retain = possibly_retained_functions_.ContainsKey(function);
        if (!retain && function.HasImplicitClosureFunction()) {
          // It can happen that all uses of an implicit closure inline their
          // target function, leaving the target function uncompiled. Keep
          // the target function anyway so we can enumerate it to bind its
          // static calls, etc.
          function2 = function.ImplicitClosureFunction();
          retain = function2.HasCode();
        }
        if (retain) {
          function.DropUncompiledImplicitClosureFunction();
          AddTypesOf(function);
        }
      }

      {
        functions = cls.invocation_dispatcher_cache();
        InvocationDispatcherTable dispatchers(functions);
        for (auto dispatcher : dispatchers) {
          name = dispatcher.Get<Class::kInvocationDispatcherName>();
          if (name.IsNull()) break;  // Reached last entry.
          function = dispatcher.Get<Class::kInvocationDispatcherFunction>();
          if (possibly_retained_functions_.ContainsKey(function)) {
            AddTypesOf(function);
          }
        }
      }
    }
  }

  closures = isolate()->object_store()->closure_functions();
  for (intptr_t j = 0; j < closures.Length(); j++) {
    function ^= closures.At(j);
    bool retain = possibly_retained_functions_.ContainsKey(function);
    if (retain) {
      AddTypesOf(function);

      cls = function.Owner();
      AddTypesOf(cls);

      // It can happen that all uses of a function are inlined, leaving
      // a compiled local function with an uncompiled parent. Retain such
      // parents and their enclosing classes and libraries.
      function = function.parent_function();
      while (!function.IsNull()) {
        AddTypesOf(function);
        function = function.parent_function();
      }
    }
  }
}

void Precompiler::FinalizeDispatchTable() {
  if (!FLAG_use_bare_instructions || !FLAG_use_table_dispatch) return;
  // Build the entries used to serialize the dispatch table before
  // dropping functions, as we may clear references to Code objects.
  const auto& entries =
      Array::Handle(Z, dispatch_table_generator_->BuildCodeArray());
  I->object_store()->set_dispatch_table_code_entries(entries);
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
  class StaticCallTableEntryFixer : public CodeVisitor {
   public:
    explicit StaticCallTableEntryFixer(Zone* zone)
        : table_(Array::Handle(zone)),
          kind_and_offset_(Smi::Handle(zone)),
          target_function_(Function::Handle(zone)),
          target_code_(Code::Handle(zone)) {}

    void VisitCode(const Code& code) {
      if (!code.IsFunctionCode()) return;
      table_ = code.static_calls_target_table();
      StaticCallsTable static_calls(table_);
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
        }
        if (FLAG_trace_precompiler) {
          THR_Print("Updated static call entry to %s in \"%s\"\n",
                    target_function_.ToFullyQualifiedCString(),
                    code.ToCString());
        }
      }
    }

   private:
    Array& table_;
    Smi& kind_and_offset_;
    Function& target_function_;
    Code& target_code_;
  };

  HANDLESCOPE(T);
  StaticCallTableEntryFixer visitor(Z);
  ProgramVisitor::WalkProgram(Z, I, &visitor);
}

void Precompiler::DropFunctions() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  Code& code = Code::Handle(Z);
  Object& owner = Object::Handle(Z);
  GrowableObjectArray& retained_functions = GrowableObjectArray::Handle(Z);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(Z);

  auto drop_function = [&](const Function& function) {
    if (function.HasCode()) {
      code = function.CurrentCode();
      function.ClearCode();
      // Wrap the owner of the code object in case the code object will be
      // serialized but the function object will not.
      owner = code.owner();
      owner = WeakSerializationReference::Wrap(Z, owner);
      code.set_owner(owner);
    }
    dropped_function_count_++;
    if (FLAG_trace_precompiler) {
      THR_Print("Dropping function %s\n",
                function.ToLibNamePrefixedQualifiedCString());
    }
  };

  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
  auto& dispatchers_array = Array::Handle(Z);
  auto& name = String::Handle(Z);
  auto& desc = Array::Handle(Z);
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      functions = cls.functions();
      retained_functions = GrowableObjectArray::New();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        function.DropUncompiledImplicitClosureFunction();
        if (functions_to_retain_.ContainsKey(function)) {
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
      {
        dispatchers_array = cls.invocation_dispatcher_cache();
        InvocationDispatcherTable dispatchers(dispatchers_array);
        for (auto dispatcher : dispatchers) {
          name = dispatcher.Get<Class::kInvocationDispatcherName>();
          if (name.IsNull()) break;  // Reached last entry.
          desc = dispatcher.Get<Class::kInvocationDispatcherArgsDesc>();
          function = dispatcher.Get<Class::kInvocationDispatcherFunction>();
          if (functions_to_retain_.ContainsKey(function)) {
            retained_functions.Add(name);
            retained_functions.Add(desc);
            retained_functions.Add(function);
          } else {
            drop_function(function);
          }
        }
      }
      if (retained_functions.Length() > 0) {
        // Last entry must be null.
        retained_functions.Add(Object::null_object());
        retained_functions.Add(Object::null_object());
        retained_functions.Add(Object::null_object());
        functions = Array::MakeFixedLength(retained_functions);
      } else {
        functions = Object::empty_array().raw();
      }
      cls.set_invocation_dispatcher_cache(functions);
    }
  }

  closures = isolate()->object_store()->closure_functions();
  retained_functions = GrowableObjectArray::New();
  for (intptr_t j = 0; j < closures.Length(); j++) {
    function ^= closures.At(j);
    if (functions_to_retain_.ContainsKey(function)) {
      retained_functions.Add(function);
    } else {
      drop_function(function);
    }
  }
  isolate()->object_store()->set_closure_functions(retained_functions);
}

void Precompiler::DropFields() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& fields = Array::Handle(Z);
  Field& field = Field::Handle(Z);
  GrowableObjectArray& retained_fields = GrowableObjectArray::Handle(Z);
  AbstractType& type = AbstractType::Handle(Z);

  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
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
          retained_fields.Add(field);
          type = field.type();
          AddType(type);
        } else {
          dropped_field_count_++;
          if (FLAG_trace_precompiler) {
            THR_Print("Dropping field %s\n", field.ToCString());
          }

          // This cleans up references to field current and initial values.
          if (field.is_static()) {
            field.SetStaticValue(Object::null_instance(),
                                 /*save_initial_value=*/true);
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
  Isolate::Current()->heap()->CollectAllGarbage();
  GrowableHandlePtrArray<const AbstractType> types(Z, 200);
  {
    class TypesCollector : public ObjectVisitor {
     public:
      explicit TypesCollector(Zone* zone,
                              GrowableHandlePtrArray<const AbstractType>* types)
          : type_(AbstractType::Handle(zone)), types_(types) {}

      void VisitObject(ObjectPtr obj) {
        if (obj->GetClassId() == kTypeCid || obj->GetClassId() == kTypeRefCid) {
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
    I->heap()->VisitObjects(&visitor);

    // Find all type objects in the vm-isolate.
    Dart::vm_isolate()->heap()->VisitObjects(&visitor);
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

void Precompiler::DropTypes() {
  ObjectStore* object_store = I->object_store();
  GrowableObjectArray& retained_types =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  Array& types_array = Array::Handle(Z);
  Type& type = Type::Handle(Z);
  // First drop all the types that are not referenced.
  {
    CanonicalTypeSet types_table(Z, object_store->canonical_types());
    types_array = HashTables::ToArray(types_table, false);
    for (intptr_t i = 0; i < types_array.Length(); i++) {
      type ^= types_array.At(i);
      bool retain = types_to_retain_.HasKey(&type);
      if (retain) {
        retained_types.Add(type);
      } else {
        type.ClearCanonical();
        dropped_type_count_++;
      }
    }
    types_table.Release();
  }

  // Now construct a new type table and save in the object store.
  const intptr_t dict_size =
      Utils::RoundUpToPowerOfTwo(retained_types.Length() * 4 / 3);
  types_array = HashTables::New<CanonicalTypeSet>(dict_size, Heap::kOld);
  CanonicalTypeSet types_table(Z, types_array.raw());
  bool present;
  for (intptr_t i = 0; i < retained_types.Length(); i++) {
    type ^= retained_types.At(i);
    present = types_table.Insert(type);
    ASSERT(!present);
  }
  object_store->set_canonical_types(types_table.Release());
}

void Precompiler::DropTypeParameters() {
  ObjectStore* object_store = I->object_store();
  GrowableObjectArray& retained_typeparams =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  Array& typeparams_array = Array::Handle(Z);
  TypeParameter& typeparam = TypeParameter::Handle(Z);
  // First drop all the type parameters that are not referenced.
  // Note that we only visit 'free-floating' type parameters and not
  // declarations of type parameters contained in the 'type_parameters'
  // array in generic classes and functions.
  {
    CanonicalTypeParameterSet typeparams_table(
        Z, object_store->canonical_type_parameters());
    typeparams_array = HashTables::ToArray(typeparams_table, false);
    for (intptr_t i = 0; i < typeparams_array.Length(); i++) {
      typeparam ^= typeparams_array.At(i);
      bool retain = typeparams_to_retain_.HasKey(&typeparam);
      if (retain) {
        retained_typeparams.Add(typeparam);
      } else {
        typeparam.ClearCanonical();
        dropped_typeparam_count_++;
      }
    }
    typeparams_table.Release();
  }

  // Now construct a new type parameter table and save in the object store.
  const intptr_t dict_size =
      Utils::RoundUpToPowerOfTwo(retained_typeparams.Length() * 4 / 3);
  typeparams_array =
      HashTables::New<CanonicalTypeParameterSet>(dict_size, Heap::kOld);
  CanonicalTypeParameterSet typeparams_table(Z, typeparams_array.raw());
  bool present;
  for (intptr_t i = 0; i < retained_typeparams.Length(); i++) {
    typeparam ^= retained_typeparams.At(i);
    present = typeparams_table.Insert(typeparam);
    ASSERT(!present);
  }
  object_store->set_canonical_type_parameters(typeparams_table.Release());
}

void Precompiler::DropTypeArguments() {
  ObjectStore* object_store = I->object_store();
  Array& typeargs_array = Array::Handle(Z);
  GrowableObjectArray& retained_typeargs =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  TypeArguments& typeargs = TypeArguments::Handle(Z);
  // First drop all the type arguments that are not referenced.
  {
    CanonicalTypeArgumentsSet typeargs_table(
        Z, object_store->canonical_type_arguments());
    typeargs_array = HashTables::ToArray(typeargs_table, false);
    for (intptr_t i = 0; i < typeargs_array.Length(); i++) {
      typeargs ^= typeargs_array.At(i);
      bool retain = typeargs_to_retain_.HasKey(&typeargs);
      if (retain) {
        retained_typeargs.Add(typeargs);
      } else {
        typeargs.ClearCanonical();
        dropped_typearg_count_++;
      }
    }
    typeargs_table.Release();
  }

  // Now construct a new type arguments table and save in the object store.
  const intptr_t dict_size =
      Utils::RoundUpToPowerOfTwo(retained_typeargs.Length() * 4 / 3);
  typeargs_array =
      HashTables::New<CanonicalTypeArgumentsSet>(dict_size, Heap::kOld);
  CanonicalTypeArgumentsSet typeargs_table(Z, typeargs_array.raw());
  bool present;
  for (intptr_t i = 0; i < retained_typeargs.Length(); i++) {
    typeargs ^= retained_typeargs.At(i);
    present = typeargs_table.Insert(typeargs);
    ASSERT(!present);
  }
  object_store->set_canonical_type_arguments(typeargs_table.Release());
}

void Precompiler::TraceTypesFromRetainedClasses() {
  auto& lib = Library::Handle(Z);
  auto& cls = Class::Handle(Z);
  auto& members = Array::Handle(Z);
  auto& constants = Array::Handle(Z);
  auto& retained_constants = GrowableObjectArray::Handle(Z);
  auto& constant = Instance::Handle(Z);

  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();

      // The subclasses/implementors array is only needed for CHA.
      cls.ClearDirectSubclasses();
      cls.ClearDirectImplementors();

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
      if (cls.is_enum_class()) {
        // Enum classes have live instances, so we cannot unregister
        // them.
        retain = true;
      }

      constants = cls.constants();
      retained_constants = GrowableObjectArray::New();
      if (!constants.IsNull()) {
        for (intptr_t j = 0; j < constants.Length(); j++) {
          constant ^= constants.At(j);
          bool retain = consts_to_retain_.HasKey(&constant);
          if (retain) {
            retained_constants.Add(constant);
          }
        }
      }
      intptr_t cid = cls.id();
      if (cid == kDoubleCid) {
        // Rehash.
        cls.set_constants(Object::null_array());
        for (intptr_t j = 0; j < retained_constants.Length(); j++) {
          constant ^= retained_constants.At(j);
          cls.InsertCanonicalDouble(Z, Double::Cast(constant));
        }
      } else if (cid == kMintCid) {
        // Rehash.
        cls.set_constants(Object::null_array());
        for (intptr_t j = 0; j < retained_constants.Length(); j++) {
          constant ^= retained_constants.At(j);
          cls.InsertCanonicalMint(Z, Mint::Cast(constant));
        }
      } else {
        // Rehash.
        cls.set_constants(Object::null_array());
        for (intptr_t j = 0; j < retained_constants.Length(); j++) {
          constant ^= retained_constants.At(j);
          cls.InsertCanonicalConstant(Z, constant);
        }
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
  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());

  Library& lib = Library::Handle(Z);
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    lib.set_metadata(Array::null_array());
  }
}

void Precompiler::DropLibraryEntries() {
  Library& lib = Library::Handle(Z);
  Array& dict = Array::Handle(Z);
  Object& entry = Object::Handle(Z);

  Array& scripts = Array::Handle(Z);
  Script& script = Script::Handle(Z);
  KernelProgramInfo& program_info = KernelProgramInfo::Handle(Z);
  const TypedData& null_typed_data = TypedData::Handle(Z);
  const KernelProgramInfo& null_info = KernelProgramInfo::Handle(Z);

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
        FATAL1("Unexpected library entry: %s", entry.ToCString());
      }
      dict.SetAt(j, Object::null_object());
    }

    scripts = lib.LoadedScripts();
    if (!scripts.IsNull()) {
      for (intptr_t i = 0; i < scripts.Length(); ++i) {
        script = Script::RawCast(scripts.At(i));
        program_info = script.kernel_program_info();
        if (!program_info.IsNull()) {
          program_info.set_constants(Array::null_array());
          program_info.set_scripts(Array::null_array());
          program_info.set_libraries_cache(Array::null_array());
          program_info.set_classes_cache(Array::null_array());
        }
        script.set_resolved_url(String::null_string());
        script.set_compile_time_constants(Array::null_array());
        script.set_line_starts(null_typed_data);
        script.set_debug_positions(Array::null_array());
        script.set_kernel_program_info(null_info);
        script.set_source(String::null_string());
      }
    }

    lib.RehashDictionary(dict, used * 4 / 3 + 1);
    if (!(retain_root_library_caches_ &&
          (lib.raw() == I->object_store()->root_library()))) {
      lib.DropDependenciesAndCaches();
    }
  }
}

void Precompiler::DropClasses() {
  Class& cls = Class::Handle(Z);
  Array& constants = Array::Handle(Z);

  // We are about to remove classes from the class table. For this to be safe,
  // there must be no instances of these classes on the heap, not even
  // corpses because the class table entry may be used to find the size of
  // corpses. Request a full GC and wait for the sweeper tasks to finish before
  // we continue.
  I->heap()->CollectAllGarbage();
  I->heap()->WaitForSweeperTasks(T);

  ClassTable* class_table = I->class_table();
  intptr_t num_cids = class_table->NumCids();

  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    if (!class_table->IsValidIndex(cid)) continue;
    if (!class_table->HasValidClassAt(cid)) continue;

    cls = class_table->At(cid);
    ASSERT(!cls.IsNull());

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

    class_table->Unregister(cid);
    cls.set_id(kIllegalCid);  // We check this when serializing.
  }
}

void Precompiler::DropLibraries() {
  const GrowableObjectArray& retained_libraries =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  const Library& root_lib =
      Library::Handle(Z, I->object_store()->root_library());
  Library& lib = Library::Handle(Z);
  Class& toplevel_class = Class::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
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
    } else if (lib.raw() == root_lib.raw()) {
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

      I->class_table()->UnregisterTopLevel(toplevel_class.id());
      toplevel_class.set_id(kIllegalCid);  // We check this when serializing.

      dropped_library_count_++;
      lib.set_index(-1);
      if (FLAG_trace_precompiler) {
        THR_Print("Dropping library %s\n", lib.ToCString());
      }
    }
  }

  Library::RegisterLibraries(T, retained_libraries);
  libraries_ = retained_libraries.raw();
}

// Traits for the HashTable template.
struct CodeKeyTraits {
  static uint32_t Hash(const Object& key) { return Code::Cast(key).Size(); }
  static const char* Name() { return "CodeKeyTraits"; }
  static bool IsMatch(const Object& x, const Object& y) {
    return x.raw() == y.raw();
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
  ProgramVisitor::WalkProgram(Z, I, &visitor);
  const CodeSet& visited = visitor.visited();

  FunctionSet::Iterator it(&functions_to_retain_);
  Function& function = Function::Handle(Z);
  Code& code = Code::Handle(Z);
  while (it.MoveNext()) {
    function ^= functions_to_retain_.GetKey(it.Current());
    if (!function.HasCode()) continue;
    code = function.CurrentCode();
    if (!visited.ContainsKey(code)) return function.raw();
  }
  return Function::null();
}
#endif

void Precompiler::Obfuscate() {
  if (!I->obfuscate()) {
    return;
  }

  class ScriptsCollector : public ObjectVisitor {
   public:
    explicit ScriptsCollector(Zone* zone,
                              GrowableHandlePtrArray<const Script>* scripts)
        : script_(Script::Handle(zone)), scripts_(scripts) {}

    void VisitObject(ObjectPtr obj) {
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
  Isolate::Current()->heap()->CollectAllGarbage();
  {
    HeapIterationScope his(T);
    ScriptsCollector visitor(Z, &scripts);
    I->heap()->VisitObjects(&visitor);
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

  // Obfuscation is done. Move obfuscation map into malloced memory.
  I->set_obfuscation_map(Obfuscator::SerializeMap(T));

  // Discard obfuscation mappings to avoid including them into snapshot.
  I->object_store()->set_obfuscation_map(Array::Handle(Z));
}

void Precompiler::FinalizeAllClasses() {
  // Create a fresh Zone because kernel reading during class finalization
  // may create zone handles. Those handles may prevent garbage collection of
  // otherwise unreachable constants of dropped classes, which would
  // cause assertion failures during GC after classes are dropped.
  StackZone stack_zone(thread());
  HANDLESCOPE(thread());

  error_ = Library::FinalizeAllClasses();
  if (!error_.IsNull()) {
    Jump(error_);
  }
  I->set_all_classes_finalized(true);
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
  const auto pool_attachment = FLAG_use_bare_instructions
                                   ? Code::PoolAttachment::kNotAttachPool
                                   : Code::PoolAttachment::kAttachPool;
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
    ASSERT(thread()->IsMutatorThread());
    function.InstallOptimizedCode(code);
  } else {  // not optimized.
    function.set_unoptimized_code(code);
    function.AttachCode(code);
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
  volatile bool use_far_branches = false;
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

      {
        ic_data_array = new (zone) ZoneGrowableArray<const ICData*>();

        TIMELINE_DURATION(thread(), CompilerVerbose, "BuildFlowGraph");
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

      ASSERT(!FLAG_use_bare_instructions || precompiler_ != nullptr);

      if (FLAG_use_bare_instructions) {
        // When generating code in bare instruction mode all code objects
        // share the same global object pool. To reduce interleaving of
        // unrelated object pool entries from different code objects
        // we attempt to pregenerate stubs referenced by the code
        // we are going to generate.
        //
        // Reducing interleaving means reducing recompilations triggered by
        // failure to commit object pool into the global object pool.
        GenerateNecessaryAllocationStubs(flow_graph);
      }

      // Even in bare instructions mode we don't directly add objects into
      // the global object pool because code generation can bail out
      // (e.g. due to speculative optimization or branch offsets being
      // too big). If we were adding objects into the global pool directly
      // these recompilations would leave dead entries behind.
      // Instead we add objects into an intermediary pool which gets
      // commited into the global object pool at the end of the compilation.
      // This makes an assumption that global object pool itself does not
      // grow during code generation - unfortunately this is not the case
      // becase we might have nested code generation (i.e. we might generate
      // some stubs). If this indeed happens we retry the compilation.
      // (See TryCommitToParent invocation below).
      compiler::ObjectPoolBuilder object_pool_builder(
          FLAG_use_bare_instructions
              ? precompiler_->global_object_pool_builder()
              : nullptr);
      compiler::Assembler assembler(&object_pool_builder, use_far_branches);

      CodeStatistics* function_stats = NULL;
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
      {
        TIMELINE_DURATION(thread(), CompilerVerbose, "CompileGraph");
        graph_compiler.CompileGraph();
      }
      {
        TIMELINE_DURATION(thread(), CompilerVerbose, "FinalizeCompilation");
        ASSERT(thread()->IsMutatorThread());
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
      if (FLAG_use_bare_instructions &&
          !object_pool_builder.TryCommitToParent()) {
        done = false;
        continue;
      }
      // Exit the loop and the function with the correct result value.
      is_compiled = true;
      done = true;
    } else {
      // We bailed out or we encountered an error.
      const Error& error = Error::Handle(thread()->StealStickyError());

      if (error.raw() == Object::branch_offset_error().raw()) {
        // Compilation failed due to an out of range branch offset in the
        // assembler. We try again (done = false) with far branches enabled.
        done = false;
        ASSERT(!use_far_branches);
        use_far_branches = true;
      } else if (error.raw() == Object::speculative_inlining_error().raw()) {
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
    Timer per_compile_timer(trace_compiler, "Compilation time");
    per_compile_timer.Start();

    ParsedFunction* parsed_function = new (zone)
        ParsedFunction(thread, Function::ZoneHandle(zone, function.raw()));
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
      return error.raw();
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
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}

ErrorPtr Precompiler::CompileFunction(Precompiler* precompiler,
                                      Thread* thread,
                                      Zone* zone,
                                      const Function& function) {
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
    : state_(NULL) {
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  if (!isolate->obfuscate()) {
    // Nothing to do.
    return;
  }

  // Create ObfuscationState from ObjectStore::obfusction_map().
  ObjectStore* store = thread->isolate()->object_store();
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
    InitializeRenamingMap(isolate);
  }
}

Obfuscator::~Obfuscator() {
  if (state_ != NULL) {
    state_->SaveState();
  }
}

void Obfuscator::InitializeRenamingMap(Isolate* isolate) {
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
  PreventRenaming("_RandomAccessFileOpsImpl");
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
  return renamed_.raw();
}

static const char* const kGetterPrefix = "get:";
static const intptr_t kGetterPrefixLength = strlen(kGetterPrefix);
static const char* const kSetterPrefix = "set:";
static const intptr_t kSetterPrefixLength = strlen(kSetterPrefix);

void Obfuscator::PreventRenaming(const char* name) {
  // For constructor names Class.name skip class name (if any) and a dot.
  const char* dot = strchr(name, '.');
  if (dot != NULL) {
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
  thread_->isolate()->object_store()->set_obfuscation_map(saved_state_);
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
  } while (renames_.GetOrNull(renamed_) == renamed_.raw());
  return renamed_.raw();
}

StringPtr Obfuscator::ObfuscationState::BuildRename(const String& name,
                                                    bool atomic) {
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
    return string_.raw();
  } else {
    return NewAtomicRename(is_private);
  }
}

void Obfuscator::Deobfuscate(Thread* thread,
                             const GrowableObjectArray& pieces) {
  const Array& obfuscation_state = Array::Handle(
      thread->zone(), thread->isolate()->object_store()->obfuscation_map());
  if (obfuscation_state.IsNull()) {
    return;
  }

  const Array& renames = Array::Handle(
      thread->zone(), GetRenamesFromSavedState(obfuscation_state));

  ObfuscationMap renames_map(renames.raw());
  String& piece = String::Handle();
  for (intptr_t i = 0; i < pieces.Length(); i++) {
    piece ^= pieces.At(i);
    ASSERT(piece.IsSymbol());

    // Fast path: skip '.'
    if (piece.raw() == Symbols::Dot().raw()) {
      continue;
    }

    // Fast path: check if piece has an identity obfuscation.
    if (renames_map.GetOrNull(piece) == piece.raw()) {
      continue;
    }

    // Search through the whole obfuscation map until matching value is found.
    // We are using linear search instead of generating a reverse mapping
    // because we assume that Deobfuscate() method is almost never called.
    ObfuscationMap::Iterator it(&renames_map);
    while (it.MoveNext()) {
      const intptr_t entry = it.Current();
      if (renames_map.GetPayload(entry, 0) == piece.raw()) {
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
  const Array& obfuscation_state = Array::Handle(
      thread->zone(), thread->isolate()->object_store()->obfuscation_map());
  if (obfuscation_state.IsNull()) {
    return NULL;
  }

  const Array& renames = Array::Handle(
      thread->zone(), GetRenamesFromSavedState(obfuscation_state));
  ObfuscationMap renames_map(renames.raw());

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
  result[idx++] = NULL;
  renames_map.Release();

  return result;
}

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

}  // namespace dart
