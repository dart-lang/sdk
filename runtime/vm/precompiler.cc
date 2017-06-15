// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/precompiler.h"

#include "vm/aot_optimizer.h"
#include "vm/assembler.h"
#include "vm/ast_printer.h"
#include "vm/branch_optimizer.h"
#include "vm/cha.h"
#include "vm/class_finalizer.h"
#include "vm/code_patcher.h"
#include "vm/compiler.h"
#include "vm/constant_propagator.h"
#include "vm/dart_entry.h"
#include "vm/disassembler.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_allocator.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_inliner.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/flow_graph_type_propagator.h"
#include "vm/hash_table.h"
#include "vm/il_printer.h"
#include "vm/isolate.h"
#include "vm/json_parser.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/program_visitor.h"
#include "vm/redundancy_elimination.h"
#include "vm/regexp_assembler.h"
#include "vm/regexp_parser.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/type_table.h"
#include "vm/version.h"

namespace dart {

#define T (thread())
#define I (isolate())
#define Z (zone())


DEFINE_FLAG(bool, print_unique_targets, false, "Print unique dynamic targets");
DEFINE_FLAG(bool, trace_precompiler, false, "Trace precompiler.");
DEFINE_FLAG(
    int,
    max_speculative_inlining_attempts,
    1,
    "Max number of attempts with speculative inlining (precompilation only)");
DEFINE_FLAG(int, precompiler_rounds, 1, "Number of precompiler iterations");

DECLARE_FLAG(bool, allocation_sinking);
DECLARE_FLAG(bool, common_subexpression_elimination);
DECLARE_FLAG(bool, constant_propagation);
DECLARE_FLAG(bool, loop_invariant_code_motion);
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);
DECLARE_FLAG(bool, range_analysis);
DECLARE_FLAG(bool, trace_compiler);
DECLARE_FLAG(bool, trace_optimizing_compiler);
DECLARE_FLAG(bool, trace_bailout);
DECLARE_FLAG(bool, use_inlining);
DECLARE_FLAG(bool, verify_compiler);
DECLARE_FLAG(bool, huge_method_cutoff_in_code_size);
DECLARE_FLAG(bool, trace_failed_optimization_attempts);
DECLARE_FLAG(bool, trace_inlining_intervals);
DECLARE_FLAG(bool, trace_irregexp);
DECLARE_FLAG(int, inlining_hotness);
DECLARE_FLAG(int, inlining_size_threshold);
DECLARE_FLAG(int, inlining_callee_size_threshold);
DECLARE_FLAG(int, inline_getters_setters_smaller_than);
DECLARE_FLAG(int, inlining_depth_threshold);
DECLARE_FLAG(int, inlining_caller_size_threshold);
DECLARE_FLAG(int, inlining_constant_arguments_max_size_threshold);
DECLARE_FLAG(int, inlining_constant_arguments_min_size_threshold);


#ifdef DART_PRECOMPILER

class DartPrecompilationPipeline : public DartCompilationPipeline {
 public:
  explicit DartPrecompilationPipeline(Zone* zone,
                                      FieldTypeMap* field_map = NULL)
      : zone_(zone), result_type_(CompileType::None()), field_map_(field_map) {}

  virtual void FinalizeCompilation(FlowGraph* flow_graph) {
    if ((field_map_ != NULL) &&
        flow_graph->function().IsGenerativeConstructor()) {
      for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
           !block_it.Done(); block_it.Advance()) {
        ForwardInstructionIterator it(block_it.Current());
        for (; !it.Done(); it.Advance()) {
          StoreInstanceFieldInstr* store = it.Current()->AsStoreInstanceField();
          if (store != NULL) {
            if (!store->field().IsNull() && store->field().is_final()) {
#ifndef PRODUCT
              if (FLAG_trace_precompiler && FLAG_support_il_printer) {
                THR_Print("Found store to %s <- %s\n",
                          store->field().ToCString(),
                          store->value()->Type()->ToCString());
              }
#endif  // !PRODUCT
              FieldTypePair* entry = field_map_->Lookup(&store->field());
              if (entry == NULL) {
                field_map_->Insert(FieldTypePair(
                    &Field::Handle(zone_, store->field().raw()),  // Re-wrap.
                    store->value()->Type()->ToCid()));
#ifndef PRODUCT
                if (FLAG_trace_precompiler && FLAG_support_il_printer) {
                  THR_Print(" initial type = %s\n",
                            store->value()->Type()->ToCString());
                }
#endif  // !PRODUCT
                continue;
              }
              CompileType type = CompileType::FromCid(entry->cid_);
#ifndef PRODUCT
              if (FLAG_trace_precompiler && FLAG_support_il_printer) {
                THR_Print(" old type = %s\n", type.ToCString());
              }
#endif  // !PRODUCT
              type.Union(store->value()->Type());
#ifndef PRODUCT
              if (FLAG_trace_precompiler && FLAG_support_il_printer) {
                THR_Print(" new type = %s\n", type.ToCString());
              }
#endif  // !PRODUCT
              entry->cid_ = type.ToCid();
            }
          }
        }
      }
    }

    CompileType result_type = CompileType::None();
    for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
         !block_it.Done(); block_it.Advance()) {
      ForwardInstructionIterator it(block_it.Current());
      for (; !it.Done(); it.Advance()) {
        ReturnInstr* return_instr = it.Current()->AsReturn();
        if (return_instr != NULL) {
          result_type.Union(return_instr->InputAt(0)->Type());
        }
      }
    }
    result_type_ = result_type;
  }

  CompileType result_type() { return result_type_; }

 private:
  Zone* zone_;
  CompileType result_type_;
  FieldTypeMap* field_map_;
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
  Isolate* isolate() const { return thread_->isolate(); }

  void FinalizeCompilation(Assembler* assembler,
                           FlowGraphCompiler* graph_compiler,
                           FlowGraph* flow_graph);

  Precompiler* precompiler_;
  ParsedFunction* parsed_function_;
  const bool optimized_;
  Thread* const thread_;

  DISALLOW_COPY_AND_ASSIGN(PrecompileParsedFunctionHelper);
};


static void Jump(const Error& error) {
  Thread::Current()->long_jump_base()->Jump(1, error);
}


TypeRangeCache::TypeRangeCache(Precompiler* precompiler,
                               Thread* thread,
                               intptr_t num_cids)
    : precompiler_(precompiler),
      thread_(thread),
      lower_limits_(thread->zone()->Alloc<intptr_t>(num_cids)),
      upper_limits_(thread->zone()->Alloc<intptr_t>(num_cids)) {
  for (intptr_t i = 0; i < num_cids; i++) {
    lower_limits_[i] = kNotComputed;
    upper_limits_[i] = kNotComputed;
  }
  ASSERT(precompiler->type_range_cache() == NULL);
  precompiler->set_type_range_cache(this);
}


TypeRangeCache::~TypeRangeCache() {
  ASSERT(precompiler_->type_range_cache() == this);
  precompiler_->set_type_range_cache(NULL);
}


RawError* Precompiler::CompileAll(
    Dart_QualifiedFunctionName embedder_entry_points[],
    uint8_t* jit_feedback,
    intptr_t jit_feedback_length) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Precompiler precompiler(Thread::Current());
    precompiler.LoadFeedback(jit_feedback, jit_feedback_length);
    precompiler.DoCompileAll(embedder_entry_points);
    return Error::null();
  } else {
    Thread* thread = Thread::Current();
    const Error& error = Error::Handle(thread->sticky_error());
    thread->clear_sticky_error();
    return error.raw();
  }
}


bool TypeRangeCache::InstanceOfHasClassRange(const AbstractType& type,
                                             intptr_t* lower_limit,
                                             intptr_t* upper_limit) {
  ASSERT(type.IsFinalized() && !type.IsMalformedOrMalbounded());

  if (!type.IsInstantiated()) return false;
  if (type.IsFunctionType()) return false;
  if (type.IsDartFunctionType()) return false;

  Zone* zone = thread_->zone();
  const TypeArguments& type_arguments =
      TypeArguments::Handle(zone, type.arguments());
  if (!type_arguments.IsNull() &&
      !type_arguments.IsRaw(0, type_arguments.Length()))
    return false;


  intptr_t type_cid = type.type_class_id();
  if (lower_limits_[type_cid] == kNotContiguous) return false;
  if (lower_limits_[type_cid] != kNotComputed) {
    *lower_limit = lower_limits_[type_cid];
    *upper_limit = upper_limits_[type_cid];
    return true;
  }


  *lower_limit = -1;
  *upper_limit = -1;
  intptr_t last_matching_cid = -1;

  ClassTable* table = thread_->isolate()->class_table();
  Class& cls = Class::Handle(zone);
  AbstractType& cls_type = AbstractType::Handle(zone);
  for (intptr_t cid = kInstanceCid; cid < table->NumCids(); cid++) {
    // Create local zone because deep hierarchies may allocate lots of handles
    // within one iteration of this loop.
    StackZone stack_zone(thread_);
    HANDLESCOPE(thread_);

    if (!table->HasValidClassAt(cid)) continue;
    if (cid == kVoidCid) continue;
    if (cid == kDynamicCid) continue;
    if (cid == kNullCid) continue;  // Instance is not at Bottom like Null type.
    cls = table->At(cid);
    if (cls.is_abstract()) continue;
    if (cls.is_patch()) continue;
    if (cls.IsTopLevel()) continue;

    cls_type = cls.RareType();
    if (cls_type.IsSubtypeOf(type, NULL, NULL, Heap::kNew)) {
      last_matching_cid = cid;
      if (*lower_limit == -1) {
        // Found beginning of range.
        *lower_limit = cid;
      } else if (*upper_limit == -1) {
        // Expanding range.
      } else {
        // Found a second range.
        lower_limits_[type_cid] = kNotContiguous;
        return false;
      }
    } else {
      if (*lower_limit == -1) {
        // Still before range.
      } else if (*upper_limit == -1) {
        // Found end of range.
        *upper_limit = last_matching_cid;
      } else {
        // After range.
      }
    }
  }
  if (*lower_limit == -1) {
    // Not implemented by any concrete class.
    *lower_limit = kIllegalCid;
    *upper_limit = kIllegalCid;
  }

  if (*upper_limit == -1) {
    ASSERT(last_matching_cid != -1);
    *upper_limit = last_matching_cid;
  }

  if (FLAG_trace_precompiler) {
    THR_Print("Type check for %s is cid range [%" Pd ", %" Pd "]\n",
              type.ToCString(), *lower_limit, *upper_limit);
  }

  lower_limits_[type_cid] = *lower_limit;
  upper_limits_[type_cid] = *upper_limit;
  return true;
}


Precompiler::Precompiler(Thread* thread)
    : thread_(thread),
      zone_(NULL),
      isolate_(thread->isolate()),
      jit_feedback_(NULL),
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
      enqueued_functions_(),
      fields_to_retain_(),
      functions_to_retain_(),
      classes_to_retain_(),
      typeargs_to_retain_(),
      types_to_retain_(),
      consts_to_retain_(),
      field_type_map_(),
      type_range_cache_(NULL),
      error_(Error::Handle()),
      get_runtime_type_is_unique_(false) {}


void Precompiler::LoadFeedback(uint8_t* buffer, intptr_t length) {
  if (buffer == NULL) {
    if (FLAG_trace_precompiler) {
      THR_Print("Precompiler running without JIT feedback\n");
    }

    // Flags affecting compilation only:
    // There is no counter feedback in precompilation, so ignore the counter
    // when making inlining decisions.
    FLAG_inlining_hotness = 0;
    // Use smaller thresholds in precompilation as we are compiling everything
    // with the optimizing compiler instead of only hot functions.
    FLAG_inlining_size_threshold = 5;
    FLAG_inline_getters_setters_smaller_than = 5;
    FLAG_inlining_callee_size_threshold = 20;
    FLAG_inlining_depth_threshold = 4;
    FLAG_inlining_caller_size_threshold = 1000;
    FLAG_inlining_constant_arguments_max_size_threshold = 100;
    FLAG_inlining_constant_arguments_min_size_threshold = 30;
    return;
  }

  if (FLAG_trace_precompiler) {
    THR_Print("Loading JIT feedback\n");
  }

  JSONParser parser(reinterpret_cast<const char*>(buffer), length,
                    Thread::Current()->zone());
  ParsedJSONValue* root = parser.ParseValue();
  if (root->IsError()) {
    ParsedJSONError* error = static_cast<ParsedJSONError*>(root);
    THR_Print("Error parsing JIT feedback: %s:%" Pd "\n", error->message(),
              error->position());
  } else if (!root->IsObject()) {
    THR_Print("Error parsing JIT feedback: object expected\n");
  } else {
    jit_feedback_ = static_cast<ParsedJSONObject*>(root);
  }
}


void Precompiler::DoCompileAll(
    Dart_QualifiedFunctionName embedder_entry_points[]) {
  ASSERT(I->compilation_allowed());

  {
    StackZone stack_zone(T);
    zone_ = stack_zone.GetZone();

    {
      HANDLESCOPE(T);
      // Make sure class hierarchy is stable before compilation so that CHA
      // can be used. Also ensures lookup of entry points won't miss functions
      // because their class hasn't been finalized yet.
      FinalizeAllClasses();

      ClassFinalizer::SortClasses();
      TypeRangeCache trc(this, T, I->class_table()->NumCids());
      VerifyJITFeedback();

      // Precompile static initializers to compute result type information.
      PrecompileStaticInitializers();

      // Precompile constructors to compute type information for final fields.
      ClassFinalizer::ClearAllCode();
      PrecompileConstructors();

      for (intptr_t round = 0; round < FLAG_precompiler_rounds; round++) {
        if (FLAG_trace_precompiler) {
          THR_Print("Precompiler round %" Pd "\n", round);
        }

        if (round > 0) {
          ResetPrecompilerState();
        }

        // TODO(rmacnak): We should be able to do a more thorough job and drop
        // some
        //  - implicit static closures
        //  - field initializers
        //  - invoke-field-dispatchers
        //  - method-extractors
        // that are needed in early iterations but optimized away in later
        // iterations.
        ClassFinalizer::ClearAllCode();

        CollectDynamicFunctionNames();

        // Start with the allocations and invocations that happen from C++.
        AddRoots(embedder_entry_points);

        // Compile newly found targets and add their callees until we reach a
        // fixed point.
        Iterate();
      }

      I->set_compilation_allowed(false);

      TraceForRetainedFunctions();
      DropFunctions();
      DropFields();
      TraceTypesFromRetainedClasses();
      DropTypes();
      DropTypeArguments();

      // Clear these before dropping classes as they may hold onto otherwise
      // dead instances of classes we will remove or otherwise unused symbols.
      DropScriptData();
      I->object_store()->set_unique_dynamic_targets(Array::null_array());
      Class& null_class = Class::Handle(Z);
      Function& null_function = Function::Handle(Z);
      I->object_store()->set_future_class(null_class);
      I->object_store()->set_completer_class(null_class);
      I->object_store()->set_stream_iterator_class(null_class);
      I->object_store()->set_symbol_class(null_class);
      I->object_store()->set_compiletime_error_class(null_class);
      I->object_store()->set_simple_instance_of_function(null_function);
      I->object_store()->set_simple_instance_of_true_function(null_function);
      I->object_store()->set_simple_instance_of_false_function(null_function);
      I->object_store()->set_async_set_thread_stack_trace(null_function);
      I->object_store()->set_async_star_move_next_helper(null_function);
      I->object_store()->set_complete_on_async_return(null_function);
      I->object_store()->set_async_star_stream_controller(null_class);
      DropLibraryEntries();
    }
    DropClasses();
    DropLibraries();

    BindStaticCalls();
    SwitchICCalls();

    ProgramVisitor::Dedup();

    zone_ = NULL;
  }

  intptr_t symbols_before = -1;
  intptr_t symbols_after = -1;
  intptr_t capacity = -1;
  if (FLAG_trace_precompiler) {
    Symbols::GetStats(I, &symbols_before, &capacity);
  }

  Symbols::Compact(I);

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


static void CompileStaticInitializerIgnoreErrors(const Field& field) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Precompiler::CompileStaticInitializer(field, /* compute_type = */ true);
  } else {
    // Ignore compile-time errors here. If the field is actually used,
    // the error will be reported later during Iterate().
  }
}


void Precompiler::PrecompileStaticInitializers() {
  class StaticInitializerVisitor : public ClassVisitor {
   public:
    explicit StaticInitializerVisitor(Zone* zone)
        : fields_(Array::Handle(zone)),
          field_(Field::Handle(zone)),
          function_(Function::Handle(zone)) {}
    void Visit(const Class& cls) {
      fields_ = cls.fields();
      for (intptr_t j = 0; j < fields_.Length(); j++) {
        field_ ^= fields_.At(j);
        if (field_.is_static() && field_.is_final() &&
            field_.has_initializer()) {
          if (FLAG_trace_precompiler) {
            THR_Print("Precompiling initializer for %s\n", field_.ToCString());
          }
          CompileStaticInitializerIgnoreErrors(field_);
        }
      }
    }

   private:
    Array& fields_;
    Field& field_;
    Function& function_;
  };

  HANDLESCOPE(T);
  StaticInitializerVisitor visitor(Z);
  ProgramVisitor::VisitClasses(&visitor);
}


void Precompiler::PrecompileConstructors() {
  class ConstructorVisitor : public FunctionVisitor {
   public:
    explicit ConstructorVisitor(Precompiler* precompiler, Zone* zone)
        : precompiler_(precompiler), zone_(zone) {}
    void Visit(const Function& function) {
      if (!function.IsGenerativeConstructor()) return;
      if (function.HasCode()) {
        // Const constructors may have been visited before. Recompile them here
        // to collect type information for final fields for them as well.
        function.ClearCode();
      }
      if (FLAG_trace_precompiler) {
        THR_Print("Precompiling constructor %s\n", function.ToCString());
      }
      CompileFunction(precompiler_, Thread::Current(), zone_, function,
                      precompiler_->field_type_map());
    }

   private:
    Precompiler* precompiler_;
    Zone* zone_;
  };

  HANDLESCOPE(T);
  ConstructorVisitor visitor(this, zone_);
  ProgramVisitor::VisitFunctions(&visitor);

  FieldTypeMap::Iterator it(field_type_map_.GetIterator());
  for (FieldTypePair* current = it.Next(); current != NULL;
       current = it.Next()) {
    const intptr_t cid = current->cid_;
    current->field_->set_guarded_cid(cid);
    current->field_->set_is_nullable(cid == kNullCid || cid == kDynamicCid);
    if (FLAG_trace_precompiler) {
      THR_Print(
          "Field %s <- Type %s\n", current->field_->ToCString(),
          Class::Handle(T->isolate()->class_table()->At(cid)).ToCString());
    }
  }
}


void Precompiler::AddRoots(Dart_QualifiedFunctionName embedder_entry_points[]) {
  // Note that <rootlibrary>.main is not a root. The appropriate main will be
  // discovered through _getMainClosure.

  AddSelector(Symbols::NoSuchMethod());

  AddSelector(Symbols::Call());  // For speed, not correctness.

  // Allocated from C++.
  Class& cls = Class::Handle(Z);
  for (intptr_t cid = kInstanceCid; cid < kNumPredefinedCids; cid++) {
    ASSERT(isolate()->class_table()->IsValidIndex(cid));
    if (!isolate()->class_table()->HasValidClassAt(cid)) {
      continue;
    }
    if ((cid == kDynamicCid) || (cid == kVoidCid) ||
        (cid == kFreeListElement) || (cid == kForwardingCorpse)) {
      continue;
    }
    cls = isolate()->class_table()->At(cid);
    AddInstantiatedClass(cls);
  }

  Dart_QualifiedFunctionName vm_entry_points[] = {
    // Functions
    {"dart:core", "::", "_completeDeferredLoads"},
    {"dart:core", "AbstractClassInstantiationError",
     "AbstractClassInstantiationError._create"},
    {"dart:core", "ArgumentError", "ArgumentError."},
    {"dart:core", "ArgumentError", "ArgumentError.value"},
    {"dart:core", "CyclicInitializationError", "CyclicInitializationError."},
    {"dart:core", "FallThroughError", "FallThroughError._create"},
    {"dart:core", "FormatException", "FormatException."},
    {"dart:core", "NoSuchMethodError", "NoSuchMethodError._withType"},
    {"dart:core", "NullThrownError", "NullThrownError."},
    {"dart:core", "OutOfMemoryError", "OutOfMemoryError."},
    {"dart:core", "RangeError", "RangeError."},
    {"dart:core", "RangeError", "RangeError.range"},
    {"dart:core", "StackOverflowError", "StackOverflowError."},
    {"dart:core", "UnsupportedError", "UnsupportedError."},
    {"dart:core", "_AssertionError", "_AssertionError._create"},
    {"dart:core", "_CastError", "_CastError._create"},
    {"dart:core", "_InternalError", "_InternalError."},
    {"dart:core", "_InvocationMirror", "_allocateInvocationMirror"},
    {"dart:core", "_TypeError", "_TypeError._create"},
    {"dart:isolate", "IsolateSpawnException", "IsolateSpawnException."},
    {"dart:isolate", "::", "_startIsolate"},
    {"dart:isolate", "_RawReceivePortImpl", "_handleMessage"},
    {"dart:isolate", "_RawReceivePortImpl", "_lookupHandler"},
    {"dart:isolate", "_SendPortImpl", "send"},
    {"dart:typed_data", "ByteData", "ByteData."},
    {"dart:typed_data", "ByteData", "ByteData._view"},
    {"dart:typed_data", "_ByteBuffer", "_ByteBuffer._New"},
    {"dart:_vmservice", "::", "boot"},
#if !defined(PRODUCT)
    {"dart:_vmservice", "::", "_registerIsolate"},
    {"dart:developer", "Metrics", "_printMetrics"},
    {"dart:developer", "::", "_runExtension"},
    {"dart:isolate", "::", "_runPendingImmediateCallback"},
#endif  // !PRODUCT
    // Fields
    {"dart:core", "Error", "_stackTrace"},
    {"dart:math", "_Random", "_state"},
    {NULL, NULL, NULL}  // Must be terminated with NULL entries.
  };

  AddEntryPoints(vm_entry_points);
  AddEntryPoints(embedder_entry_points);
  const Library& lib = Library::Handle(I->object_store()->root_library());
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


void Precompiler::AddEntryPoints(Dart_QualifiedFunctionName entry_points[]) {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Function& func = Function::Handle(Z);
  Field& field = Field::Handle(Z);
  String& library_uri = String::Handle(Z);
  String& class_name = String::Handle(Z);
  String& function_name = String::Handle(Z);

  for (intptr_t i = 0; entry_points[i].library_uri != NULL; i++) {
    library_uri = Symbols::New(thread(), entry_points[i].library_uri);
    class_name = Symbols::New(thread(), entry_points[i].class_name);
    function_name = Symbols::New(thread(), entry_points[i].function_name);

    if (library_uri.raw() == Symbols::TopLevel().raw()) {
      lib = I->object_store()->root_library();
    } else {
      lib = Library::LookupLibrary(T, library_uri);
    }
    if (lib.IsNull()) {
      String& msg =
          String::Handle(Z, String::NewFormatted("Cannot find entry point %s\n",
                                                 entry_points[i].library_uri));
      Jump(Error::Handle(Z, ApiError::New(msg)));
      UNREACHABLE();
    }

    if (class_name.raw() == Symbols::TopLevel().raw()) {
      if (Library::IsPrivate(function_name)) {
        function_name = lib.PrivateName(function_name);
      }
      func = lib.LookupLocalFunction(function_name);
      field = lib.LookupLocalField(function_name);
    } else {
      if (Library::IsPrivate(class_name)) {
        class_name = lib.PrivateName(class_name);
      }
      cls = lib.LookupLocalClass(class_name);
      if (cls.IsNull()) {
        String& msg = String::Handle(
            Z, String::NewFormatted("Cannot find entry point %s %s\n",
                                    entry_points[i].library_uri,
                                    entry_points[i].class_name));
        Jump(Error::Handle(Z, ApiError::New(msg)));
        UNREACHABLE();
      }

      ASSERT(!cls.IsNull());
      func = cls.LookupFunctionAllowPrivate(function_name);
      field = cls.LookupFieldAllowPrivate(function_name);
    }

    if (func.IsNull() && field.IsNull()) {
      String& msg = String::Handle(
          Z, String::NewFormatted("Cannot find entry point %s %s %s\n",
                                  entry_points[i].library_uri,
                                  entry_points[i].class_name,
                                  entry_points[i].function_name));
      Jump(Error::Handle(Z, ApiError::New(msg)));
      UNREACHABLE();
    }

    if (!func.IsNull()) {
      AddFunction(func);
      if (func.IsGenerativeConstructor()) {
        // Allocation stubs are referenced from the call site of the
        // constructor, not in the constructor itself. So compiling the
        // constructor isn't enough for us to discover the class is
        // instantiated if the class isn't otherwise instantiated from Dart
        // code and only instantiated from C++.
        AddInstantiatedClass(cls);
      }
    }
    if (!field.IsNull()) {
      AddField(field);
    }
  }
}


void Precompiler::Iterate() {
  Function& function = Function::Handle(Z);

  while (changed_) {
    changed_ = false;

    while (pending_functions_.Length() > 0) {
      function ^= pending_functions_.RemoveLast();
      ProcessFunction(function);
    }

    CheckForNewDynamicFunctions();
    if (!changed_) {
      TraceConstFunctions();
    }
    CollectCallbackFields();
  }
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
        args_desc = ArgumentsDescriptor::New(0,  // No type argument vector.
                                             function.num_fixed_parameters());
        cids.Clear();
        if (T->cha()->ConcreteSubclasses(cls, &cids)) {
          for (intptr_t j = 0; j < cids.length(); ++j) {
            subcls ^= I->class_table()->At(cids[j]);
            if (subcls.is_allocated()) {
              // Add dispatcher to cls.
              dispatcher = subcls.GetInvocationDispatcher(
                  field_name, args_desc, RawFunction::kInvokeFieldDispatcher,
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
  if (!function.HasCode()) {
    function_count_++;

    if (FLAG_trace_precompiler) {
      THR_Print("Precompiling %" Pd " %s (%s, %s)\n", function_count_,
                function.ToLibNamePrefixedQualifiedCString(),
                function.token_pos().ToCString(),
                Function::KindToCString(function.kind()));
    }

    ASSERT(!function.is_abstract());
    ASSERT(!function.IsRedirectingFactory());

    error_ = CompileFunction(this, thread_, zone_, function);
    if (!error_.IsNull()) {
      Jump(error_);
    }
    // Used in the JIT to save type-feedback across compilations.
    function.ClearICDataArray();
  } else {
    if (FLAG_trace_precompiler) {
      // This function was compiled from somewhere other than Precompiler,
      // such as const constructors compiled by the parser.
      THR_Print("Already has code: %s (%s, %s)\n",
                function.ToLibNamePrefixedQualifiedCString(),
                function.token_pos().ToCString(),
                Function::KindToCString(function.kind()));
    }
  }

  ASSERT(function.HasCode());
  AddCalleesOf(function);
}


void Precompiler::AddCalleesOf(const Function& function) {
  ASSERT(function.HasCode());

  const Code& code = Code::Handle(Z, function.CurrentCode());

  const Array& table = Array::Handle(Z, code.static_calls_target_table());
  Object& entry = Object::Handle(Z);
  Function& target = Function::Handle(Z);
  for (intptr_t i = 0; i < table.Length(); i++) {
    entry = table.At(i);
    if (entry.IsFunction()) {
      target ^= entry.raw();
      AddFunction(target);
    }
  }

#if defined(TARGET_ARCH_IA32)
  FATAL("Callee scanning unimplemented for IA32");
#endif

  const ObjectPool& pool = ObjectPool::Handle(Z, code.GetObjectPool());
  ObjectPoolInfo pool_info(pool);
  ICData& call_site = ICData::Handle(Z);
  MegamorphicCache& cache = MegamorphicCache::Handle(Z);
  String& selector = String::Handle(Z);
  Field& field = Field::Handle(Z);
  Class& cls = Class::Handle(Z);
  Instance& instance = Instance::Handle(Z);
  Code& target_code = Code::Handle(Z);
  for (intptr_t i = 0; i < pool.Length(); i++) {
    if (pool_info.InfoAt(i) == ObjectPool::kTaggedObject) {
      entry = pool.ObjectAt(i);
      if (entry.IsICData()) {
        // A dynamic call.
        call_site ^= entry.raw();
        ASSERT(!call_site.is_static_call());
        selector = call_site.target_name();
        AddSelector(selector);
        if (selector.raw() == Symbols::Call().raw()) {
          // Potential closure call.
          const Array& arguments_descriptor =
              Array::Handle(Z, call_site.arguments_descriptor());
          AddClosureCall(arguments_descriptor);
        }
      } else if (entry.IsMegamorphicCache()) {
        // A dynamic call.
        cache ^= entry.raw();
        selector = cache.target_name();
        AddSelector(selector);
        if (selector.raw() == Symbols::Call().raw()) {
          // Potential closure call.
          const Array& arguments_descriptor =
              Array::Handle(Z, cache.arguments_descriptor());
          AddClosureCall(arguments_descriptor);
        }
      } else if (entry.IsField()) {
        // Potential need for field initializer.
        field ^= entry.raw();
        AddField(field);
      } else if (entry.IsInstance()) {
        // Const object, literal or args descriptor.
        instance ^= entry.raw();
        if (entry.IsAbstractType()) {
          AddType(AbstractType::Cast(entry));
        } else {
          AddConstObject(instance);
        }
      } else if (entry.IsFunction()) {
        // Local closure function.
        target ^= entry.raw();
        AddFunction(target);
      } else if (entry.IsCode()) {
        target_code ^= entry.raw();
        if (target_code.IsAllocationStubCode()) {
          cls ^= target_code.owner();
          AddInstantiatedClass(cls);
        }
      } else if (entry.IsTypeArguments()) {
        AddTypeArguments(TypeArguments::Cast(entry));
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

  type = cls.mixin();
  AddType(type);

  if (cls.IsTypedefClass()) {
    AddTypesOf(Function::Handle(Z, cls.signature_function()));
  }
}


void Precompiler::AddTypesOf(const Function& function) {
  if (function.IsNull()) return;
  if (functions_to_retain_.HasKey(&function)) return;
  // We don't expect to see a reference to a redirecting factory. Only its
  // target should remain.
  ASSERT(!function.IsRedirectingFactory());
  functions_to_retain_.Insert(&Function::ZoneHandle(Z, function.raw()));

  AbstractType& type = AbstractType::Handle(Z);
  type = function.result_type();
  AddType(type);
  for (intptr_t i = 0; i < function.NumParameters(); i++) {
    type = function.ParameterTypeAt(i);
    AddType(type);
  }
  Code& code = Code::Handle(Z, function.CurrentCode());
  if (code.IsNull()) {
    ASSERT(function.kind() == RawFunction::kSignatureFunction);
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
  } else if (abstype.IsBoundedType()) {
    AbstractType& type = AbstractType::Handle(Z);
    type = BoundedType::Cast(abstype).type();
    AddType(type);
    type = BoundedType::Cast(abstype).bound();
    AddType(type);
  } else if (abstype.IsTypeRef()) {
    AbstractType& type = AbstractType::Handle(Z);
    type = TypeRef::Cast(abstype).type();
    AddType(type);
  } else if (abstype.IsTypeParameter()) {
    const AbstractType& type =
        AbstractType::Handle(Z, TypeParameter::Cast(abstype).bound());
    AddType(type);
    const Class& cls =
        Class::Handle(Z, TypeParameter::Cast(abstype).parameterized_class());
    AddTypesOf(cls);
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


void Precompiler::AddConstObject(const Instance& instance) {
  const Class& cls = Class::Handle(Z, instance.clazz());
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
    return;
  }

  // Can't ask immediate objects if they're canoncial.
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
        : ObjectPointerVisitor(isolate),
          precompiler_(precompiler),
          subinstance_(Object::Handle()) {}

    virtual void VisitPointers(RawObject** first, RawObject** last) {
      for (RawObject** current = first; current <= last; current++) {
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
  instance.raw()->VisitPointers(&visitor);
}


void Precompiler::AddClosureCall(const Array& arguments_descriptor) {
  const Class& cache_class =
      Class::Handle(Z, I->object_store()->closure_class());
  const Function& dispatcher = Function::Handle(
      Z, cache_class.GetInvocationDispatcher(
             Symbols::Call(), arguments_descriptor,
             RawFunction::kInvokeFieldDispatcher, true /* create_if_absent */));
  AddFunction(dispatcher);
}


void Precompiler::AddField(const Field& field) {
  if (fields_to_retain_.HasKey(&field)) return;

  fields_to_retain_.Insert(&Field::ZoneHandle(Z, field.raw()));

  if (field.is_static()) {
    const Object& value = Object::Handle(Z, field.StaticValue());
    if (value.IsInstance()) {
      AddConstObject(Instance::Cast(value));
    }

    if (field.has_initializer()) {
      // Should not be in the middle of initialization while precompiling.
      ASSERT(value.raw() != Object::transition_sentinel().raw());

      if (!field.HasPrecompiledInitializer() ||
          !Function::Handle(Z, field.PrecompiledInitializer()).HasCode()) {
        if (FLAG_trace_precompiler) {
          THR_Print("Precompiling initializer for %s\n", field.ToCString());
        }
        ASSERT(Dart::vm_snapshot_kind() != Snapshot::kFullAOT);
        const Function& initializer = Function::Handle(
            Z, CompileStaticInitializer(field, /* compute_type = */ true));
        ASSERT(!initializer.IsNull());
        field.SetPrecompiledInitializer(initializer);
        AddCalleesOf(initializer);
      }
    }
  }
}


RawFunction* Precompiler::CompileStaticInitializer(const Field& field,
                                                   bool compute_type) {
  ASSERT(field.is_static());
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  ParsedFunction* parsed_function;
  // Check if this field is coming from the Kernel binary.
  if (field.kernel_offset() > 0) {
    parsed_function = kernel::ParseStaticFieldInitializer(zone, field);
  } else {
    parsed_function = Parser::ParseStaticFieldInitializer(field);
    parsed_function->AllocateVariables();
  }


  DartPrecompilationPipeline pipeline(zone);
  PrecompileParsedFunctionHelper helper(/* precompiler = */ NULL,
                                        parsed_function,
                                        /* optimized = */ true);
  bool success = helper.Compile(&pipeline);
  ASSERT(success);

  if (compute_type && field.is_final()) {
    intptr_t result_cid = pipeline.result_type().ToCid();
    if (result_cid != kDynamicCid) {
#ifndef PRODUCT
      if (FLAG_trace_precompiler && FLAG_support_il_printer) {
        THR_Print("Setting guarded_cid of %s to %s\n", field.ToCString(),
                  pipeline.result_type().ToCString());
      }
#endif  // !PRODUCT
      field.set_guarded_cid(result_cid);
    }
  }

  if ((FLAG_disassemble || FLAG_disassemble_optimized) &&
      FlowGraphPrinter::ShouldPrint(parsed_function->function())) {
    Code& code = Code::Handle(parsed_function->function().CurrentCode());
    Disassembler::DisassembleCode(parsed_function->function(), code,
                                  /* optimized = */ true);
  }
  return parsed_function->function().raw();
}


RawObject* Precompiler::EvaluateStaticInitializer(const Field& field) {
  ASSERT(field.is_static());
  // The VM sets the field's value to transiton_sentinel prior to
  // evaluating the initializer value.
  ASSERT(field.StaticValue() == Object::transition_sentinel().raw());
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Under precompilation, the initializer may have already been compiled, in
    // which case use it. Under lazy compilation or early in precompilation, the
    // initializer has not yet been created, so create it now, but don't bother
    // remembering it because it won't be used again.
    Function& initializer = Function::Handle();
    if (!field.HasPrecompiledInitializer()) {
      initializer = CompileStaticInitializer(field, /* compute_type = */ false);
    } else {
      initializer ^= field.PrecompiledInitializer();
    }
    // Invoke the function to evaluate the expression.
    return DartEntry::InvokeFunction(initializer, Object::empty_array());
  } else {
    Thread* const thread = Thread::Current();
    StackZone zone(thread);
    const Error& error = Error::Handle(thread->zone(), thread->sticky_error());
    thread->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Object::null();
}


RawObject* Precompiler::ExecuteOnce(SequenceNode* fragment) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();
    if (FLAG_support_ast_printer && FLAG_trace_compiler) {
      THR_Print("compiling expression: ");
      AstPrinter ast_printer;
      ast_printer.PrintNode(fragment);
    }

    // Create a dummy function object for the code generator.
    // The function needs to be associated with a named Class: the interface
    // Function fits the bill.
    const char* kEvalConst = "eval_const";
    const Function& func = Function::ZoneHandle(Function::New(
        String::Handle(Symbols::New(thread, kEvalConst)),
        RawFunction::kRegularFunction,
        true,   // static function
        false,  // not const function
        false,  // not abstract
        false,  // not external
        false,  // not native
        Class::Handle(Type::Handle(Type::DartFunctionType()).type_class()),
        fragment->token_pos()));

    func.set_result_type(Object::dynamic_type());
    func.set_num_fixed_parameters(0);
    func.SetNumOptionalParameters(0, true);
    // Manually generated AST, do not recompile.
    func.SetIsOptimizable(false);
    func.set_is_debuggable(false);

    // We compile the function here, even though InvokeFunction() below
    // would compile func automatically. We are checking fewer invariants
    // here.
    ParsedFunction* parsed_function = new ParsedFunction(thread, func);
    parsed_function->SetNodeSequence(fragment);
    fragment->scope()->AddVariable(parsed_function->EnsureExpressionTemp());
    fragment->scope()->AddVariable(parsed_function->current_context_var());
    parsed_function->AllocateVariables();

    // Non-optimized code generator.
    DartPrecompilationPipeline pipeline(Thread::Current()->zone());
    PrecompileParsedFunctionHelper helper(/* precompiler = */ NULL,
                                          parsed_function,
                                          /* optimized = */ false);
    helper.Compile(&pipeline);
    Code::Handle(func.unoptimized_code())
        .set_var_descriptors(Object::empty_var_descriptors());

    const Object& result = PassiveObject::Handle(
        DartEntry::InvokeFunction(func, Object::empty_array()));
    return result.raw();
  } else {
    Thread* const thread = Thread::Current();
    const Object& result = PassiveObject::Handle(thread->sticky_error());
    thread->clear_sticky_error();
    return result.raw();
  }
  UNREACHABLE();
  return Object::null();
}


void Precompiler::AddFunction(const Function& function) {
  if (enqueued_functions_.HasKey(&function)) return;

  enqueued_functions_.Insert(&Function::ZoneHandle(Z, function.raw()));
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


void Precompiler::AddInstantiatedClass(const Class& cls) {
  if (cls.is_allocated()) return;

  class_count_++;
  cls.set_is_allocated(true);
  error_ = cls.EnsureIsFinalized(T);
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


void Precompiler::CheckForNewDynamicFunctions() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  Function& function2 = Function::Handle(Z);
  String& selector = String::Handle(Z);
  String& selector2 = String::Handle(Z);
  String& selector3 = String::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();

      if (!cls.is_allocated()) continue;

      functions = cls.functions();
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

        // Handle the implicit call type conversions.
        if (Field::IsGetterName(selector)) {
          selector2 = Field::NameFromGetter(selector);
          selector3 = Symbols::Lookup(thread(), selector2);
          if (IsSent(selector2)) {
            // Call-through-getter.
            // Function is get:foo and somewhere foo is called.
            AddFunction(function);
          }
          selector3 = Symbols::LookupFromConcat(
              thread(), Symbols::ClosurizePrefix(), selector2);
          if (IsSent(selector3)) {
            // Hash-closurization.
            // Function is get:foo and somewhere get:#foo is called.
            AddFunction(function);

            function2 = function.ImplicitClosureFunction();
            AddFunction(function2);

            // Add corresponding method extractor get:#foo.
            function2 = function.GetMethodExtractor(selector3);
            AddFunction(function2);
          }
        } else if (Field::IsSetterName(selector)) {
          selector2 = Symbols::LookupFromConcat(
              thread(), Symbols::ClosurizePrefix(), selector);
          if (IsSent(selector2)) {
            // Hash-closurization.
            // Function is set:foo and somewhere get:#set:foo is called.
            AddFunction(function);

            function2 = function.ImplicitClosureFunction();
            AddFunction(function2);

            // Add corresponding method extractor get:#set:foo.
            function2 = function.GetMethodExtractor(selector2);
            AddFunction(function2);
          }
        } else if (function.kind() == RawFunction::kRegularFunction) {
          selector2 = Field::LookupGetterSymbol(selector);
          if (IsSent(selector2)) {
            // Closurization.
            // Function is foo and somewhere get:foo is called.
            function2 = function.ImplicitClosureFunction();
            AddFunction(function2);

            // Add corresponding method extractor.
            function2 = function.GetMethodExtractor(selector2);
            AddFunction(function2);
          }
          selector2 = Symbols::LookupFromConcat(
              thread(), Symbols::ClosurizePrefix(), selector);
          if (IsSent(selector2)) {
            // Hash-closurization.
            // Function is foo and somewhere get:#foo is called.
            function2 = function.ImplicitClosureFunction();
            AddFunction(function2);

            // Add corresponding method extractor get:#foo
            function2 = function.GetMethodExtractor(selector2);
            AddFunction(function2);
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
  static RawObject* NewKey(const String& str) { return str.raw(); }
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


void Precompiler::CollectDynamicFunctionNames() {
  if (!FLAG_collect_dynamic_function_names) {
    return;
  }
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  String& fname = String::Handle(Z);
  Array& farray = Array::Handle(Z);

  Table table(HashTables::New<Table>(100));
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }
      functions = cls.functions();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        if (function.IsDynamicFunction()) {
          fname = function.name();
          if (function.IsSetterFunction() ||
              function.IsImplicitSetterFunction()) {
            AddNameToFunctionsTable(zone(), &table, fname, function);
          } else if (function.IsGetterFunction() ||
                     function.IsImplicitGetterFunction()) {
            // Enter both getter and non getter name.
            AddNameToFunctionsTable(zone(), &table, fname, function);
            fname = Field::NameFromGetter(fname);
            AddNameToFunctionsTable(zone(), &table, fname, function);
          } else if (function.IsMethodExtractor()) {
            // Skip. We already add getter names for regular methods below.
            continue;
          } else {
            // Regular function. Enter both getter and non getter name.
            AddNameToFunctionsTable(zone(), &table, fname, function);
            fname = Field::GetterName(fname);
            AddNameToFunctionsTable(zone(), &table, fname, function);
          }
        }
      }
    }
  }

  // Locate all entries with one function only
  Table::Iterator iter(&table);
  String& key = String::Handle(Z);
  UniqueFunctionsSet functions_set(HashTables::New<UniqueFunctionsSet>(20));
  while (iter.MoveNext()) {
    intptr_t curr_key = iter.Current();
    key ^= table.GetKey(curr_key);
    farray ^= table.GetOrNull(key);
    ASSERT(!farray.IsNull());
    if (farray.Length() == 1) {
      function ^= farray.At(0);
      cls = function.Owner();
      functions_set.Insert(function);
    }
  }

  farray ^= table.GetOrNull(Symbols::GetRuntimeType());

  get_runtime_type_is_unique_ = !farray.IsNull() && (farray.Length() == 1);

  if (FLAG_print_unique_targets) {
    UniqueFunctionsSet::Iterator unique_iter(&functions_set);
    while (unique_iter.MoveNext()) {
      intptr_t curr_key = unique_iter.Current();
      function ^= functions_set.GetKey(curr_key);
      THR_Print("* %s\n", function.ToQualifiedCString());
    }
    THR_Print("%" Pd " of %" Pd " dynamic selectors are unique\n",
              functions_set.NumOccupied(), table.NumOccupied());
  }

  isolate()->object_store()->set_unique_dynamic_targets(
      functions_set.Release());
  table.Release();
}


void Precompiler::TraceConstFunctions() {
  // Compilation of const accessors happens outside of the treeshakers
  // queue, so we haven't previously scanned its literal pool.

  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }

      functions = cls.functions();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        if (function.is_const() && function.HasCode()) {
          AddCalleesOf(function);
        }
      }
    }
  }
}


void Precompiler::TraceForRetainedFunctions() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  Function& function2 = Function::Handle(Z);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }

      functions = cls.functions();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        bool retain = enqueued_functions_.HasKey(&function);
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
    }
  }

  closures = isolate()->object_store()->closure_functions();
  for (intptr_t j = 0; j < closures.Length(); j++) {
    function ^= closures.At(j);
    bool retain = enqueued_functions_.HasKey(&function);
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


void Precompiler::DropFunctions() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& functions = Array::Handle(Z);
  Function& function = Function::Handle(Z);
  GrowableObjectArray& retained_functions = GrowableObjectArray::Handle(Z);
  GrowableObjectArray& closures = GrowableObjectArray::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }

      functions = cls.functions();
      retained_functions = GrowableObjectArray::New();
      for (intptr_t j = 0; j < functions.Length(); j++) {
        function ^= functions.At(j);
        bool retain = functions_to_retain_.HasKey(&function);
        function.DropUncompiledImplicitClosureFunction();
        if (retain) {
          retained_functions.Add(function);
        } else {
          dropped_function_count_++;
          if (FLAG_trace_precompiler) {
            THR_Print("Dropping function %s\n",
                      function.ToLibNamePrefixedQualifiedCString());
          }
        }
      }

      if (retained_functions.Length() > 0) {
        functions = Array::MakeArray(retained_functions);
        cls.SetFunctions(functions);
      } else {
        cls.SetFunctions(Object::empty_array());
      }
    }
  }

  closures = isolate()->object_store()->closure_functions();
  retained_functions = GrowableObjectArray::New();
  for (intptr_t j = 0; j < closures.Length(); j++) {
    function ^= closures.At(j);
    bool retain = functions_to_retain_.HasKey(&function);
    if (retain) {
      retained_functions.Add(function);
    } else {
      dropped_function_count_++;
      if (FLAG_trace_precompiler) {
        THR_Print("Dropping function %s\n",
                  function.ToLibNamePrefixedQualifiedCString());
      }
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

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }

      fields = cls.fields();
      retained_fields = GrowableObjectArray::New();
      for (intptr_t j = 0; j < fields.Length(); j++) {
        field ^= fields.At(j);
        bool retain = fields_to_retain_.HasKey(&field);
        if (retain) {
          retained_fields.Add(field);
          type = field.type();
          AddType(type);
        } else {
          dropped_field_count_++;
          if (FLAG_trace_precompiler) {
            THR_Print("Dropping field %s\n", field.ToCString());
          }
        }
      }

      if (retained_fields.Length() > 0) {
        fields = Array::MakeArray(retained_fields);
        cls.SetFields(fields);
      } else {
        cls.SetFields(Object::empty_array());
      }
    }
  }
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
    for (intptr_t i = 0; i < (types_array.Length() - 1); i++) {
      type ^= types_array.At(i);
      bool retain = types_to_retain_.HasKey(&type);
      if (retain) {
        retained_types.Add(type);
      } else {
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
    for (intptr_t i = 0; i < (typeargs_array.Length() - 1); i++) {
      typeargs ^= typeargs_array.At(i);
      bool retain = typeargs_to_retain_.HasKey(&typeargs);
      if (retain) {
        retained_typeargs.Add(typeargs);
      } else {
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


void Precompiler::DropScriptData() {
  Library& lib = Library::Handle(Z);
  Array& scripts = Array::Handle(Z);
  Script& script = Script::Handle(Z);
  const TokenStream& null_tokens = TokenStream::Handle(Z);
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    scripts = lib.LoadedScripts();
    for (intptr_t j = 0; j < scripts.Length(); j++) {
      script ^= scripts.At(j);
      script.set_compile_time_constants(Array::null_array());
      script.set_source(String::null_string());
      script.set_tokens(null_tokens);
    }
  }
}


void Precompiler::TraceTypesFromRetainedClasses() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  Array& members = Array::Handle(Z);
  Array& constants = Array::Handle(Z);
  GrowableObjectArray& retained_constants = GrowableObjectArray::Handle(Z);
  Instance& constant = Instance::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }

      // The subclasses array is only needed for CHA.
      cls.ClearDirectSubclasses();

      bool retain = false;
      members = cls.fields();
      if (members.Length() > 0) {
        retain = true;
      }
      members = cls.functions();
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
      for (intptr_t j = 0; j < constants.Length(); j++) {
        constant ^= constants.At(j);
        bool retain = consts_to_retain_.HasKey(&constant);
        if (retain) {
          retained_constants.Add(constant);
        }
      }
      intptr_t cid = cls.id();
      if ((cid == kMintCid) || (cid == kBigintCid) || (cid == kDoubleCid)) {
        // Constants stored as a plain list, no rehashing needed.
        constants = Array::MakeArray(retained_constants);
        cls.set_constants(constants);
      } else {
        // Rehash.
        cls.set_constants(Object::empty_array());
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


void Precompiler::DropLibraryEntries() {
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
        if (functions_to_retain_.HasKey(&Function::Cast(entry))) {
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

#if defined(DEBUG)
  // We are about to remove classes from the class table. For this to be safe,
  // there must be no instances of these classes on the heap, not even
  // corpses because the class table entry may be used to find the size of
  // corpses. Request a full GC and wait for the sweeper tasks to finish before
  // we continue.
  I->heap()->CollectAllGarbage();
  I->heap()->WaitForSweeperTasks(T);
#endif

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
    ASSERT(constants.Length() == 0);

#if defined(DEBUG)
    intptr_t instances =
        class_table->StatsWithUpdatedSize(cid)->post_gc.new_count +
        class_table->StatsWithUpdatedSize(cid)->post_gc.old_count;
    if (instances != 0) {
      FATAL2("Want to drop class %s, but it has %" Pd " instances\n",
             cls.ToCString(), instances);
    }
#endif

    dropped_class_count_++;
    if (FLAG_trace_precompiler) {
      THR_Print("Dropping class %" Pd " %s\n", cid, cls.ToCString());
    }

#if defined(DEBUG)
    class_table->Unregister(cid);
#endif
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
#if defined(DEBUG)
      I->class_table()->Unregister(toplevel_class.id());
#endif
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


void Precompiler::BindStaticCalls() {
  class BindStaticCallsVisitor : public FunctionVisitor {
   public:
    explicit BindStaticCallsVisitor(Zone* zone)
        : code_(Code::Handle(zone)),
          table_(Array::Handle(zone)),
          pc_offset_(Smi::Handle(zone)),
          target_(Function::Handle(zone)),
          target_code_(Code::Handle(zone)) {}

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      table_ = code_.static_calls_target_table();

      for (intptr_t i = 0; i < table_.Length();
           i += Code::kSCallTableEntryLength) {
        pc_offset_ ^= table_.At(i + Code::kSCallTableOffsetEntry);
        target_ ^= table_.At(i + Code::kSCallTableFunctionEntry);
        if (target_.IsNull()) {
          target_code_ ^= table_.At(i + Code::kSCallTableCodeEntry);
          ASSERT(!target_code_.IsNull());
          ASSERT(!target_code_.IsFunctionCode());
          // Allocation stub or AllocateContext or AllocateArray or ...
        } else {
          // Static calls initially call the CallStaticFunction stub because
          // their target might not be compiled yet. After tree shaking, all
          // static call targets are compiled.
          // Cf. runtime entry PatchStaticCall called from CallStaticFunction
          // stub.
          ASSERT(target_.HasCode());
          target_code_ ^= target_.CurrentCode();
          uword pc = pc_offset_.Value() + code_.PayloadStart();
          CodePatcher::PatchStaticCallAt(pc, code_, target_code_);
        }
      }

      // We won't patch static calls anymore, so drop the static call table to
      // save space.
      code_.set_static_calls_target_table(Object::empty_array());
    }

   private:
    Code& code_;
    Array& table_;
    Smi& pc_offset_;
    Function& target_;
    Code& target_code_;
  };

  BindStaticCallsVisitor visitor(Z);
  ProgramVisitor::VisitFunctions(&visitor);
}


void Precompiler::SwitchICCalls() {
#if !defined(TARGET_ARCH_DBC)
  // Now that all functions have been compiled, we can switch to an instance
  // call sequence that loads the Code object and entry point directly from
  // the ic data array instead indirectly through a Function in the ic data
  // array. Iterate all the object pools and rewrite the ic data from
  // (cid, target function, count) to (cid, target code, entry point), and
  // replace the ICCallThroughFunction stub with ICCallThroughCode.

  class SwitchICCallsVisitor : public FunctionVisitor {
   public:
    explicit SwitchICCallsVisitor(Zone* zone)
        : zone_(zone),
          code_(Code::Handle(zone)),
          pool_(ObjectPool::Handle(zone)),
          entry_(Object::Handle(zone)),
          info_array_(TypedData::Handle(zone)),
          ic_(ICData::Handle(zone)),
          target_name_(String::Handle(zone)),
          args_descriptor_(Array::Handle(zone)),
          unlinked_(UnlinkedCall::Handle(zone)),
          target_code_(Code::Handle(zone)),
          canonical_unlinked_calls_() {}

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }

      code_ = function.CurrentCode();
      pool_ = code_.object_pool();
      info_array_ = pool_.info_array();
      ObjectPoolInfo pool_info(info_array_);
      for (intptr_t i = 0; i < pool_.Length(); i++) {
        if (pool_info.InfoAt(i) != ObjectPool::kTaggedObject) continue;
        entry_ = pool_.ObjectAt(i);
        if (entry_.IsICData()) {
          // The only IC calls generated by precompilation are for switchable
          // calls.
          ic_ ^= entry_.raw();
          ic_.ResetSwitchable(zone_);

          unlinked_ = UnlinkedCall::New();
          target_name_ = ic_.target_name();
          unlinked_.set_target_name(target_name_);
          args_descriptor_ = ic_.arguments_descriptor();
          unlinked_.set_args_descriptor(args_descriptor_);
          unlinked_ = DedupUnlinkedCall(unlinked_);
          pool_.SetObjectAt(i, unlinked_);
        } else if (entry_.raw() ==
                   StubCode::ICCallThroughFunction_entry()->code()) {
          target_code_ = StubCode::UnlinkedCall_entry()->code();
          pool_.SetObjectAt(i, target_code_);
        }
      }
    }

    RawUnlinkedCall* DedupUnlinkedCall(const UnlinkedCall& unlinked) {
      const UnlinkedCall* canonical_unlinked =
          canonical_unlinked_calls_.LookupValue(&unlinked);
      if (canonical_unlinked == NULL) {
        canonical_unlinked_calls_.Insert(
            &UnlinkedCall::ZoneHandle(zone_, unlinked.raw()));
        return unlinked.raw();
      } else {
        return canonical_unlinked->raw();
      }
    }

   private:
    Zone* zone_;
    Code& code_;
    ObjectPool& pool_;
    Object& entry_;
    TypedData& info_array_;
    ICData& ic_;
    String& target_name_;
    Array& args_descriptor_;
    UnlinkedCall& unlinked_;
    Code& target_code_;
    UnlinkedCallSet canonical_unlinked_calls_;
  };

  ASSERT(!I->compilation_allowed());
  SwitchICCallsVisitor visitor(Z);
  ProgramVisitor::VisitFunctions(&visitor);
#endif
}


void Precompiler::FinalizeAllClasses() {
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    if (!lib.Loaded()) {
      String& uri = String::Handle(Z, lib.url());
      String& msg = String::Handle(
          Z,
          String::NewFormatted("Library '%s' is not loaded. "
                               "Did you forget to call Dart_FinalizeLoading?",
                               uri.ToCString()));
      Jump(Error::Handle(Z, ApiError::New(msg)));
    }

    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }
      error_ = cls.EnsureIsFinalized(T);
      if (!error_.IsNull()) {
        Jump(error_);
      }
    }
  }
  I->set_all_classes_finalized(true);
}



void Precompiler::VerifyJITFeedback() {
  if (jit_feedback_ == NULL) return;

  ParsedJSONString* js_vmversion = jit_feedback_->StringAt("vmVersion");
  if ((js_vmversion == NULL) ||
      strcmp(js_vmversion->value(), Version::CommitString()) != 0) {
    THR_Print(
        "JIT feedback contains invalid vm version "
        "(saw %s, expected %s).\n",
        js_vmversion->value(), Version::CommitString());
    jit_feedback_ = NULL;
    return;
  }
  ParsedJSONBoolean* js_asserts = jit_feedback_->BooleanAt("asserts");
  if ((js_asserts == NULL) || (FLAG_enable_asserts != js_asserts->value())) {
    THR_Print("JIT feedback contains invalid FLAG_enable_asserts\n");
    jit_feedback_ = NULL;
    return;
  }
  ParsedJSONBoolean* js_typechecks = jit_feedback_->BooleanAt("typeChecks");
  if ((js_typechecks == NULL) ||
      (FLAG_enable_type_checks != js_typechecks->value())) {
    THR_Print("JIT feedback contains invalid FLAG_enable_type_checks\n");
    jit_feedback_ = NULL;
    return;
  }

  ParsedJSONArray* js_scripts = jit_feedback_->ArrayAt("scripts");
  ASSERT(js_scripts != NULL);
  Script& script = Script::Handle(Z);
  for (intptr_t i = 0; i < js_scripts->Length(); i++) {
    ParsedJSONObject* js_script = js_scripts->ObjectAt(i);
    ASSERT(js_script != NULL);
    ParsedJSONString* js_uri = js_script->StringAt("uri");
    ASSERT(js_uri != NULL);
    ParsedJSONNumber* js_fp = js_script->NumberAt("checksum");
    ASSERT(js_fp != NULL);
    script = LookupScript(js_uri->value());
    if (script.IsNull()) {
      THR_Print("Cannot find script %s\n", js_uri->value());
      continue;
    }
    intptr_t fp = script.SourceFingerprint();
    if (fp != js_fp->value()) {
      THR_Print(
          "Fingerprint has changed for %s. Continuing without JIT "
          "feedback.\n",
          js_uri->value());
      jit_feedback_ = NULL;
      return;
    }
  }

  ParsedJSONArray* js_classes = jit_feedback_->ArrayAt("classes");
  ASSERT(js_classes != NULL);
  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);
  String& str = String::Handle(Z);
  for (intptr_t i = 0; i < js_classes->Length(); i++) {
    ParsedJSONObject* js_class = js_classes->ObjectAt(i);
    ASSERT(js_class != NULL);
    ParsedJSONString* js_uri = js_class->StringAt("uri");
    ASSERT(js_uri != NULL);
    ParsedJSONString* js_name = js_class->StringAt("name");
    ASSERT(js_name != NULL);
    ParsedJSONNumber* js_cid = js_class->NumberAt("cid");
    ASSERT(js_cid != NULL);

    str = String::New(js_uri->value());
    lib = Library::LookupLibrary(T, str);
    if (lib.IsNull()) {
      THR_Print("Cannot find library %s\n", js_uri->value());
      continue;
    }
    str = String::New(js_name->value());
    if (str.Equals(Symbols::TopLevel())) {
      cls = lib.toplevel_class();
    } else {
      cls = lib.LookupClassAllowPrivate(str);
    }
    if (cls.IsNull()) {
      THR_Print("Missing class %s\n", js_name->value());
      continue;
    }

    feedback_cid_map_.Insert(IntptrPair(js_cid->value(), cls.id()));
  }

  ParsedJSONArray* js_functions = jit_feedback_->ArrayAt("functions");
  ASSERT(js_functions != NULL);
  for (intptr_t i = 0; i < js_functions->Length(); i++) {
    ParsedJSONObject* js_function = js_functions->ObjectAt(i);
    ASSERT(js_function != NULL);
    ParsedJSONString* js_name = js_function->StringAt("name");
    ASSERT(js_name != NULL);
    ParsedJSONNumber* js_cid = js_function->NumberAt("class");
    ASSERT(js_cid != NULL);
    ParsedJSONNumber* js_token = js_function->NumberAt("tokenPos");
    ASSERT(js_token != NULL);
    ParsedJSONNumber* js_kind = js_function->NumberAt("kind");
    ASSERT(js_kind != NULL);
    function_feedback_map_.Insert(FunctionFeedbackPair(
        FunctionFeedbackKey(MapCid(js_cid->value()), js_token->value(),
                            js_kind->value()),
        js_function));
  }

  class ApplyUsageVisitor : public FunctionVisitor {
   public:
    explicit ApplyUsageVisitor(Precompiler* precompiler)
        : precompiler_(precompiler) {}
    void Visit(const Function& function) {
      ParsedJSONObject* js_function = precompiler_->LookupFeedback(function);
      if (js_function == NULL) {
        function.set_usage_counter(0);
      } else {
        ParsedJSONNumber* js_usage = js_function->NumberAt("usageCounter");
        ASSERT(js_usage != NULL);
        function.set_usage_counter(js_usage->value());
      }
    }

   private:
    Precompiler* precompiler_;
  };

  ApplyUsageVisitor visitor(this);
  ProgramVisitor::VisitFunctions(&visitor);
}


ParsedJSONObject* Precompiler::LookupFeedback(const Function& function) {
  const Class& owner = Class::Handle(Z, function.Owner());

  FunctionFeedbackKey key(owner.id(), function.token_pos().value(),
                          function.kind());
  FunctionFeedbackPair* pair = function_feedback_map_.Lookup(key);
  if (pair == NULL) {
    return NULL;
  }
  return pair->value_;
}


RawScript* Precompiler::LookupScript(const char* uri) {
  String& dart_uri = String::Handle(Z, String::New(uri));
  Library& lib = Library::Handle(Z);
  Script& script = Script::Handle(Z);
  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    script = lib.LookupScript(dart_uri);
    if (!script.IsNull()) {
      return script.raw();
    }
  }
  return Script::null();
}


intptr_t Precompiler::MapCid(intptr_t feedback_cid) {
  if (feedback_cid < kNumPredefinedCids) {
    return feedback_cid;
  }
  IntptrPair* pair = feedback_cid_map_.Lookup(feedback_cid);
  if (pair == NULL) return kIllegalCid;
  return pair->value_;
}


void Precompiler::PopulateWithICData(const Function& function,
                                     FlowGraph* graph) {
  Zone* zone = Thread::Current()->zone();

  for (BlockIterator block_it = graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    ForwardInstructionIterator it(block_it.Current());
    for (; !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (instr->IsInstanceCall()) {
        InstanceCallInstr* call = instr->AsInstanceCall();
        if (!call->HasICData()) {
          const Array& arguments_descriptor =
              Array::Handle(zone, call->GetArgumentsDescriptor());
          const ICData& ic_data = ICData::ZoneHandle(
              zone, ICData::New(function, call->function_name(),
                                arguments_descriptor, call->deopt_id(),
                                call->checked_argument_count(), false));
          call->set_ic_data(&ic_data);
        }
      } else if (instr->IsStaticCall()) {
        StaticCallInstr* call = instr->AsStaticCall();
        if (!call->HasICData()) {
          const Array& arguments_descriptor =
              Array::Handle(zone, call->GetArgumentsDescriptor());
          const Function& target = call->function();
          MethodRecognizer::Kind recognized_kind =
              MethodRecognizer::RecognizeKind(target);
          int num_args_checked = 0;
          switch (recognized_kind) {
            case MethodRecognizer::kDoubleFromInteger:
            case MethodRecognizer::kMathMin:
            case MethodRecognizer::kMathMax:
              num_args_checked = 2;
              break;
            default:
              break;
          }
          const ICData& ic_data = ICData::ZoneHandle(
              zone, ICData::New(function, String::Handle(zone, target.name()),
                                arguments_descriptor, call->deopt_id(),
                                num_args_checked, true));
          ic_data.AddTarget(target);
          call->set_ic_data(&ic_data);
        }
      }
    }
  }
}


void Precompiler::TryApplyFeedback(const Function& function, FlowGraph* graph) {
  ParsedJSONObject* js_function = LookupFeedback(function);
  if (js_function == NULL) {
    if (FLAG_trace_precompiler) {
      THR_Print("No feedback available for %s\n",
                function.ToQualifiedCString());
    }
    return;
  }

  ParsedJSONArray* js_icdatas = js_function->ArrayAt("ics");
  ASSERT(js_icdatas != NULL);

  for (BlockIterator block_it = graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    ForwardInstructionIterator it(block_it.Current());
    for (; !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (instr->IsInstanceCall()) {
        InstanceCallInstr* call = instr->AsInstanceCall();
        TryApplyFeedback(js_icdatas, *call->ic_data());
      } else if (instr->IsStaticCall()) {
        StaticCallInstr* call = instr->AsStaticCall();
        TryApplyFeedback(js_icdatas, *call->ic_data());
      }
    }
  }
}


void Precompiler::TryApplyFeedback(ParsedJSONArray* js_icdatas,
                                   const ICData& ic) {
  for (intptr_t j = 0; j < js_icdatas->Length(); j++) {
    ParsedJSONObject* js_icdata = js_icdatas->ObjectAt(j);
    ASSERT(js_icdata != NULL);

    ParsedJSONNumber* js_deoptid = js_icdata->NumberAt("deoptId");
    ASSERT(js_deoptid != NULL);
    if (js_deoptid->value() != ic.deopt_id()) continue;

    ParsedJSONBoolean* js_isstaticcall = js_icdata->BooleanAt("isStaticCall");
    ASSERT(js_isstaticcall != NULL);
    if (js_isstaticcall->value() != ic.is_static_call()) return;

    ParsedJSONNumber* js_argsTested = js_icdata->NumberAt("argsTested");
    ASSERT(js_argsTested != NULL);
    if (js_argsTested->value() != ic.NumArgsTested()) return;

    ParsedJSONString* js_selector = js_icdata->StringAt("selector");
    ASSERT(js_selector != NULL);
    const String& feedback_selector =
        String::Handle(String::New(js_selector->value()));
    const String& selector = String::Handle(ic.target_name());
    // N.B.: EqualsIgnoringPrivateKey is not symmetric.
    if (!String::EqualsIgnoringPrivateKey(selector, feedback_selector)) return;

    ParsedJSONArray* js_entries = js_icdata->ArrayAt("entries");
    ASSERT(js_entries != NULL);
    if (ic.is_static_call()) {
      // [cid [cid]] target count
      ParsedJSONNumber* entry = js_entries->NumberAt(js_entries->Length() - 1);
      ASSERT(entry != NULL);
      ic.SetCountAt(0, entry->value());
    } else {
      // [cid [cid [cid]]] target count
      const Array& arguments_descriptor =
          Array::Handle(ic.arguments_descriptor());
      ArgumentsDescriptor args_desc(arguments_descriptor);

      intptr_t num_args_checked = ic.NumArgsTested();
      for (intptr_t k = 0; k < js_entries->Length();
           k += num_args_checked + 1) {
        GrowableArray<intptr_t> class_ids(num_args_checked);
        for (intptr_t arg = 0; arg < num_args_checked; arg++) {
          ParsedJSONNumber* entry = js_entries->NumberAt(k + arg);
          ASSERT(entry != NULL);
          class_ids.Add(MapCid(entry->value()));
        }
        ParsedJSONNumber* entry = js_entries->NumberAt(k + num_args_checked);
        ASSERT(entry != NULL);
        intptr_t count = entry->value();

        bool has_missing_cid = false;
        for (intptr_t arg = 0; arg < num_args_checked; arg++) {
          if (class_ids[arg] == kIllegalCid) {
            has_missing_cid = true;
          }
        }
        if (has_missing_cid) continue;

        intptr_t receiver_cid = class_ids[0];
        const Class& receiver_cls =
            Class::Handle(I->class_table()->At(receiver_cid));
        if (receiver_cls.IsClass()) {
          const Function& target =
              Function::Handle(Resolver::ResolveDynamicForReceiverClass(
                  receiver_cls, selector, args_desc, false));
          // TODO(rmacnak): Create missing dispatchers.
          if (!target.IsNull()) {
            if (num_args_checked == 1) {
              ic.AddReceiverCheck(receiver_cid, target, count);
            } else {
              ic.AddCheck(class_ids, target, count);
            }
          }
        }
      }
    }

    return;
  }
}


void Precompiler::ResetPrecompilerState() {
  changed_ = false;
  function_count_ = 0;
  class_count_ = 0;
  selector_count_ = 0;
  dropped_function_count_ = 0;
  dropped_field_count_ = 0;
  ASSERT(pending_functions_.Length() == 0);
  sent_selectors_.Clear();
  enqueued_functions_.Clear();

  classes_to_retain_.Clear();
  consts_to_retain_.Clear();
  fields_to_retain_.Clear();
  functions_to_retain_.Clear();
  typeargs_to_retain_.Clear();
  types_to_retain_.Clear();

  Library& lib = Library::Handle(Z);
  Class& cls = Class::Handle(Z);

  for (intptr_t i = 0; i < libraries_.Length(); i++) {
    lib ^= libraries_.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }
      cls.set_is_allocated(false);
    }
  }
}


void PrecompileParsedFunctionHelper::FinalizeCompilation(
    Assembler* assembler,
    FlowGraphCompiler* graph_compiler,
    FlowGraph* flow_graph) {
  const Function& function = parsed_function()->function();
  Zone* const zone = thread()->zone();

  CSTAT_TIMER_SCOPE(thread(), codefinalizer_timer);
  // CreateDeoptInfo uses the object pool and needs to be done before
  // FinalizeCode.
  const Array& deopt_info_array =
      Array::Handle(zone, graph_compiler->CreateDeoptInfo(assembler));
  INC_STAT(thread(), total_code_size,
           deopt_info_array.Length() * sizeof(uword));
  // Allocates instruction object. Since this occurs only at safepoint,
  // there can be no concurrent access to the instruction page.
  const Code& code =
      Code::Handle(Code::FinalizeCode(function, assembler, optimized()));
  code.set_is_optimized(optimized());
  code.set_owner(function);
  if (!function.IsOptimizable()) {
    // A function with huge unoptimized code can become non-optimizable
    // after generating unoptimized code.
    function.set_usage_counter(INT_MIN);
  }

  graph_compiler->FinalizePcDescriptors(code);
  code.set_deopt_info_array(deopt_info_array);

  graph_compiler->FinalizeStackMaps(code);
  graph_compiler->FinalizeVarDescriptors(code);
  graph_compiler->FinalizeExceptionHandlers(code);
  graph_compiler->FinalizeCatchEntryStateMap(code);
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
  ASSERT(!parsed_function()->HasDeferredPrefixes());
  ASSERT(FLAG_load_deferred_eagerly);
}


// Return false if bailed out.
// If optimized_result_code is not NULL then it is caller's responsibility
// to install code.
bool PrecompileParsedFunctionHelper::Compile(CompilationPipeline* pipeline) {
  ASSERT(FLAG_precompiled_mode);
  const Function& function = parsed_function()->function();
  if (optimized() && !function.IsOptimizable()) {
    // All functions compiled by precompiler must be optimizable.
    UNREACHABLE();
    return false;
  }
  bool is_compiled = false;
  Zone* const zone = thread()->zone();
#ifndef PRODUCT
  TimelineStream* compiler_timeline = Timeline::GetCompilerStream();
#endif  // !PRODUCT
  CSTAT_TIMER_SCOPE(thread(), codegen_timer);
  HANDLESCOPE(thread());

  // We may reattempt compilation if the function needs to be assembled using
  // far branches on ARM and MIPS. In the else branch of the setjmp call,
  // done is set to false, and use_far_branches is set to true if there is a
  // longjmp from the ARM or MIPS assemblers. In all other paths through this
  // while loop, done is set to true. use_far_branches is always false on ia32
  // and x64.
  bool done = false;
  // volatile because the variable may be clobbered by a longjmp.
  volatile bool use_far_branches = false;
  volatile bool use_speculative_inlining =
      FLAG_max_speculative_inlining_attempts > 0;
  GrowableArray<intptr_t> inlining_black_list;

  while (!done) {
    const intptr_t prev_deopt_id = thread()->deopt_id();
    thread()->set_deopt_id(0);
    LongJumpScope jump;
    const intptr_t val = setjmp(*jump.Set());
    if (val == 0) {
      FlowGraph* flow_graph = NULL;

      // Class hierarchy analysis is registered with the thread in the
      // constructor and unregisters itself upon destruction.
      CHA cha(thread());

      // TimerScope needs an isolate to be properly terminated in case of a
      // LongJump.
      {
        CSTAT_TIMER_SCOPE(thread(), graphbuilder_timer);
        ZoneGrowableArray<const ICData*>* ic_data_array =
            new (zone) ZoneGrowableArray<const ICData*>();
#ifndef PRODUCT
        TimelineDurationScope tds(thread(), compiler_timeline,
                                  "BuildFlowGraph");
#endif  // !PRODUCT
        flow_graph = pipeline->BuildFlowGraph(
            zone, parsed_function(), *ic_data_array, Compiler::kNoOSRDeoptId);
      }

      if (optimized()) {
        Precompiler::PopulateWithICData(parsed_function()->function(),
                                        flow_graph);
        if (precompiler_ != NULL) {
          precompiler_->TryApplyFeedback(parsed_function()->function(),
                                         flow_graph);
        }
      }

      const bool print_flow_graph =
          (FLAG_print_flow_graph ||
           (optimized() && FLAG_print_flow_graph_optimized)) &&
          FlowGraphPrinter::ShouldPrint(function);

      if (print_flow_graph) {
        FlowGraphPrinter::PrintGraph("Before Optimizations", flow_graph);
      }

      if (optimized()) {
#ifndef PRODUCT
        TimelineDurationScope tds(thread(), compiler_timeline, "ComputeSSA");
#endif  // !PRODUCT
        CSTAT_TIMER_SCOPE(thread(), ssa_timer);
        // Transform to SSA (virtual register 0 and no inlining arguments).
        flow_graph->ComputeSSA(0, NULL);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
        if (print_flow_graph) {
          FlowGraphPrinter::PrintGraph("After SSA", flow_graph);
        }
      }

      // Maps inline_id_to_function[inline_id] -> function. Top scope
      // function has inline_id 0. The map is populated by the inliner.
      GrowableArray<const Function*> inline_id_to_function;
      // Token position where inlining occured.
      GrowableArray<TokenPosition> inline_id_to_token_pos;
      // For a given inlining-id(index) specifies the caller's inlining-id.
      GrowableArray<intptr_t> caller_inline_id;
      // Collect all instance fields that are loaded in the graph and
      // have non-generic type feedback attached to them that can
      // potentially affect optimizations.
      if (optimized()) {
#ifndef PRODUCT
        TimelineDurationScope tds(thread(), compiler_timeline,
                                  "OptimizationPasses");
#endif  // !PRODUCT
        inline_id_to_function.Add(&function);
        // We do not add the token position now because we don't know the
        // position of the inlined call until later. A side effect of this
        // is that the length of |inline_id_to_function| is always larger
        // than the length of |inline_id_to_token_pos| by one.
        // Top scope function has no caller (-1). We do this because we expect
        // all token positions to be at an inlined call.
        // Top scope function has no caller (-1).
        caller_inline_id.Add(-1);
        CSTAT_TIMER_SCOPE(thread(), graphoptimizer_timer);

        AotOptimizer optimizer(precompiler_, flow_graph,
                               use_speculative_inlining, &inlining_black_list);

        optimizer.ApplyClassIds();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        optimizer.ApplyICData();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Optimize (a << b) & c patterns, merge operations.
        // Run early in order to have more opportunity to optimize left shifts.
        flow_graph->TryOptimizePatterns();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        FlowGraphInliner::SetInliningId(flow_graph, 0);

        // Inlining (mutates the flow graph)
        if (FLAG_use_inlining) {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline, "Inlining");
#endif  // !PRODUCT
          CSTAT_TIMER_SCOPE(thread(), graphinliner_timer);
          // Propagate types to create more inlining opportunities.
          FlowGraphTypePropagator::Propagate(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          // Use propagated class-ids to create more inlining opportunities.
          optimizer.ApplyClassIds();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          FlowGraphInliner inliner(flow_graph, &inline_id_to_function,
                                   &inline_id_to_token_pos, &caller_inline_id,
                                   use_speculative_inlining,
                                   &inlining_black_list, precompiler_);
          inliner.Inline();
          // Use lists are maintained and validated by the inliner.
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Propagate types and eliminate more type tests.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "ApplyClassIds");
#endif  // !PRODUCT
          // Use propagated class-ids to optimize further.
          optimizer.ApplyClassIds();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Propagate types for potentially newly added instructions by
        // ApplyClassIds(). Must occur before canonicalization.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Do optimizations that depend on the propagated type information.
        if (flow_graph->Canonicalize()) {
          // Invoke Canonicalize twice in order to fully canonicalize patterns
          // like "if (a & const == 0) { }".
          flow_graph->Canonicalize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "BranchSimplifier");
#endif  // !PRODUCT
          BranchSimplifier::Simplify(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          IfConverter::Simplify(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        if (FLAG_constant_propagation) {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "ConstantPropagation");
#endif  // !PRODUCT
          ConstantPropagator::Optimize(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
          // A canonicalization pass to remove e.g. smi checks on smi constants.
          flow_graph->Canonicalize();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
          // Canonicalization introduced more opportunities for constant
          // propagation.
          ConstantPropagator::Optimize(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Optimistically convert loop phis that have a single non-smi input
        // coming from the loop pre-header into smi-phis.
        if (FLAG_loop_invariant_code_motion) {
          LICM licm(flow_graph);
          licm.OptimisticallySpecializeSmiPhis();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Propagate types and eliminate even more type tests.
        // Recompute types after constant propagation to infer more precise
        // types for uses that were previously reached by now eliminated phis.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "SelectRepresentations");
#endif  // !PRODUCT
          // Where beneficial convert Smi operations into Int32 operations.
          // Only meanigful for 32bit platforms right now.
          flow_graph->WidenSmiToInt32();

          // Unbox doubles. Performed after constant propagation to minimize
          // interference from phis merging double values and tagged
          // values coming from dead paths.
          flow_graph->SelectRepresentations();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "CommonSubexpressionElimination");
#endif  // !PRODUCT
          if (FLAG_common_subexpression_elimination ||
              FLAG_loop_invariant_code_motion) {
            flow_graph->ComputeBlockEffects();
          }

          if (FLAG_common_subexpression_elimination) {
            if (DominatorBasedCSE::Optimize(flow_graph)) {
              DEBUG_ASSERT(flow_graph->VerifyUseLists());
              flow_graph->Canonicalize();
              // Do another round of CSE to take secondary effects into account:
              // e.g. when eliminating dependent loads (a.x[0] + a.x[0])
              // TODO(fschneider): Change to a one-pass optimization pass.
              if (DominatorBasedCSE::Optimize(flow_graph)) {
                flow_graph->Canonicalize();
              }
              DEBUG_ASSERT(flow_graph->VerifyUseLists());
            }
          }

          // Run loop-invariant code motion right after load elimination since
          // it depends on the numbering of loads from the previous
          // load-elimination.
          if (FLAG_loop_invariant_code_motion) {
            flow_graph->RenameUsesDominatedByRedefinitions();
            DEBUG_ASSERT(flow_graph->VerifyRedefinitions());
            LICM licm(flow_graph);
            licm.Optimize();
            DEBUG_ASSERT(flow_graph->VerifyUseLists());
          }
          flow_graph->RemoveRedefinitions();
        }

        // Optimize (a << b) & c patterns, merge operations.
        // Run after CSE in order to have more opportunity to merge
        // instructions that have same inputs.
        flow_graph->TryOptimizePatterns();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "DeadStoreElimination");
#endif  // !PRODUCT
          DeadStoreElimination::Optimize(flow_graph);
        }

        if (FLAG_range_analysis) {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "RangeAnalysis");
#endif  // !PRODUCT
          // Propagate types after store-load-forwarding. Some phis may have
          // become smi phis that can be processed by range analysis.
          FlowGraphTypePropagator::Propagate(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          // We have to perform range analysis after LICM because it
          // optimistically moves CheckSmi through phis into loop preheaders
          // making some phis smi.
          RangeAnalysis range_analysis(flow_graph);
          range_analysis.Analyze();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        if (FLAG_constant_propagation) {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "ConstantPropagator::OptimizeBranches");
#endif  // !PRODUCT
          // Constant propagation can use information from range analysis to
          // find unreachable branch targets and eliminate branches that have
          // the same true- and false-target.
          ConstantPropagator::OptimizeBranches(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Recompute types after code movement was done to ensure correct
        // reaching types for hoisted values.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "TryCatchAnalyzer::Optimize");
#endif  // !PRODUCT
          // Optimize try-blocks.
          TryCatchAnalyzer::Optimize(flow_graph);
        }

        // Detach environments from the instructions that can't deoptimize.
        // Do it before we attempt to perform allocation sinking to minimize
        // amount of materializations it has to perform.
        flow_graph->EliminateEnvironments();

        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "EliminateDeadPhis");
#endif  // !PRODUCT
          DeadCodeElimination::EliminateDeadPhis(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        if (flow_graph->Canonicalize()) {
          flow_graph->Canonicalize();
        }

        // Attempt to sink allocations of temporary non-escaping objects to
        // the deoptimization path.
        AllocationSinking* sinking = NULL;
        if (FLAG_allocation_sinking &&
            (flow_graph->graph_entry()->SuccessorCount() == 1)) {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "AllocationSinking::Optimize");
#endif  // !PRODUCT
          // TODO(fschneider): Support allocation sinking with try-catch.
          sinking = new AllocationSinking(flow_graph);
          sinking->Optimize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        DeadCodeElimination::EliminateDeadPhis(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "SelectRepresentations");
#endif  // !PRODUCT
          // Ensure that all phis inserted by optimization passes have
          // consistent representations.
          flow_graph->SelectRepresentations();
        }

        if (flow_graph->Canonicalize()) {
          // To fully remove redundant boxing (e.g. BoxDouble used only in
          // environments and UnboxDouble instructions) instruction we
          // first need to replace all their uses and then fold them away.
          // For now we just repeat Canonicalize twice to do that.
          // TODO(vegorov): implement a separate representation folding pass.
          flow_graph->Canonicalize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        if (sinking != NULL) {
#ifndef PRODUCT
          TimelineDurationScope tds2(
              thread(), compiler_timeline,
              "AllocationSinking::DetachMaterializations");
#endif  // !PRODUCT
          // Remove all MaterializeObject instructions inserted by allocation
          // sinking from the flow graph and let them float on the side
          // referenced only from environments. Register allocator will consider
          // them as part of a deoptimization environment.
          sinking->DetachMaterializations();
        }

        // Replace bounds check instruction with a generic one.
        optimizer.ReplaceArrayBoundChecks();

        // Compute and store graph informations (call & instruction counts)
        // to be later used by the inliner.
        FlowGraphInliner::CollectGraphInfo(flow_graph, true);

        flow_graph->RemoveRedefinitions();
        {
#ifndef PRODUCT
          TimelineDurationScope tds2(thread(), compiler_timeline,
                                     "AllocateRegisters");
#endif  // !PRODUCT
          // Perform register allocation on the SSA graph.
          FlowGraphAllocator allocator(*flow_graph);
          allocator.AllocateRegisters();
        }

        if (print_flow_graph) {
          FlowGraphPrinter::PrintGraph("After Optimizations", flow_graph);
        }
      }

      ASSERT(inline_id_to_function.length() == caller_inline_id.length());
      Assembler assembler(use_far_branches);
      FlowGraphCompiler graph_compiler(
          &assembler, flow_graph, *parsed_function(), optimized(),
          inline_id_to_function, inline_id_to_token_pos, caller_inline_id);
      {
        CSTAT_TIMER_SCOPE(thread(), graphcompiler_timer);
#ifndef PRODUCT
        TimelineDurationScope tds(thread(), compiler_timeline, "CompileGraph");
#endif  // !PRODUCT
        graph_compiler.CompileGraph();
        pipeline->FinalizeCompilation(flow_graph);
      }
      {
#ifndef PRODUCT
        TimelineDurationScope tds(thread(), compiler_timeline,
                                  "FinalizeCompilation");
#endif  // !PRODUCT
        ASSERT(thread()->IsMutatorThread());
        FinalizeCompilation(&assembler, &graph_compiler, flow_graph);
      }
      // Exit the loop and the function with the correct result value.
      is_compiled = true;
      done = true;
    } else {
      // We bailed out or we encountered an error.
      const Error& error = Error::Handle(thread()->sticky_error());

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
        if (!use_speculative_inlining) {
          // Assert that we don't repeatedly retry speculation.
          UNREACHABLE();
        }
#if defined(DEBUG)
        for (intptr_t i = 0; i < inlining_black_list.length(); ++i) {
          ASSERT(inlining_black_list[i] != val);
        }
#endif
        inlining_black_list.Add(val);
        const intptr_t max_attempts = FLAG_max_speculative_inlining_attempts;
        if (inlining_black_list.length() >= max_attempts) {
          use_speculative_inlining = false;
          if (FLAG_trace_compiler || FLAG_trace_optimizing_compiler) {
            THR_Print("Disabled speculative inlining after %" Pd " attempts.\n",
                      inlining_black_list.length());
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

      // Clear the error if it was not a real error, but just a bailout.
      if (error.IsLanguageError() &&
          (LanguageError::Cast(error).kind() == Report::kBailout)) {
        thread()->clear_sticky_error();
      }
      is_compiled = false;
    }
    // Reset global isolate state.
    thread()->set_deopt_id(prev_deopt_id);
  }
  return is_compiled;
}


static RawError* PrecompileFunctionHelper(Precompiler* precompiler,
                                          CompilationPipeline* pipeline,
                                          const Function& function,
                                          bool optimized) {
  // Check that we optimize, except if the function is not optimizable.
  ASSERT(FLAG_precompiled_mode);
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
    INC_STAT(thread, num_functions_compiled, 1);
    if (optimized) {
      INC_STAT(thread, num_functions_optimized, 1);
    }
    {
      HANDLESCOPE(thread);
      const int64_t num_tokens_before = STAT_VALUE(thread, num_tokens_consumed);
      pipeline->ParseFunction(parsed_function);
      const int64_t num_tokens_after = STAT_VALUE(thread, num_tokens_consumed);
      INC_STAT(thread, num_func_tokens_compiled,
               num_tokens_after - num_tokens_before);
    }

    PrecompileParsedFunctionHelper helper(precompiler, parsed_function,
                                          optimized);
    const bool success = helper.Compile(pipeline);
    if (!success) {
      // Encountered error.
      Error& error = Error::Handle();
      // We got an error during compilation.
      error = thread->sticky_error();
      thread->clear_sticky_error();
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
    Error& error = Error::Handle();
    // We got an error during compilation.
    error = thread->sticky_error();
    thread->clear_sticky_error();
    // Precompilation may encounter compile-time errors.
    // Do not attempt to optimize functions that can cause errors.
    function.set_is_optimizable(false);
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


RawError* Precompiler::CompileFunction(Precompiler* precompiler,
                                       Thread* thread,
                                       Zone* zone,
                                       const Function& function,
                                       FieldTypeMap* field_type_map) {
  VMTagScope tagScope(thread, VMTag::kCompileUnoptimizedTagId);
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread, "CompileFunction", function);

  ASSERT(FLAG_precompiled_mode);
  const bool optimized = function.IsOptimizable();  // False for natives.
  DartPrecompilationPipeline pipeline(zone, field_type_map);
  return PrecompileFunctionHelper(precompiler, &pipeline, function, optimized);
}

#endif  // DART_PRECOMPILER

}  // namespace dart
