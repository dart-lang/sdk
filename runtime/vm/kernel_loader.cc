// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/kernel_loader.h"

#include <string.h>

#include <memory>

#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/frontend/constant_reader.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/heap/heap.h"
#include "vm/kernel_binary.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/reusable_handles.h"
#include "vm/service_isolate.h"
#include "vm/symbols.h"
#include "vm/thread.h"

namespace dart {
namespace kernel {

#define Z (zone_)
#define I (isolate_)
#define IG (thread_->isolate_group())
#define T (type_translator_)
#define H (translation_helper_)

static const char* const kVMServiceIOLibraryUri = "dart:vmservice_io";

class SimpleExpressionConverter {
 public:
  SimpleExpressionConverter(TranslationHelper* translation_helper,
                            KernelReaderHelper* reader_helper)
      : translation_helper_(*translation_helper),
        zone_(translation_helper_.zone()),
        simple_value_(nullptr),
        helper_(reader_helper) {}

  bool IsSimple(intptr_t kernel_offset) {
    AlternativeReadingScope alt(&helper_->reader_, kernel_offset);
    uint8_t payload = 0;
    Tag tag = helper_->ReadTag(&payload);  // read tag.
    switch (tag) {
      case kBigIntLiteral: {
        const String& literal_str =
            H.DartString(helper_->ReadStringReference(),
                         Heap::kOld);  // read index into string table.
        simple_value_ = &Integer::ZoneHandle(Z, Integer::New(literal_str));
        if (simple_value_->IsNull()) {
          H.ReportError("Integer literal %s is out of range",
                        literal_str.ToCString());
          UNREACHABLE();
        }
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      }
      case kStringLiteral:
        simple_value_ = &H.DartSymbolPlain(
            helper_->ReadStringReference());  // read index into string table.
        return true;
      case kSpecializedIntLiteral:
        simple_value_ =
            &Integer::ZoneHandle(Z, Integer::New(static_cast<int32_t>(payload) -
                                                     SpecializedIntLiteralBias,
                                                 Heap::kOld));
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kNegativeIntLiteral:
        simple_value_ = &Integer::ZoneHandle(
            Z, Integer::New(-static_cast<int64_t>(helper_->ReadUInt()),
                            Heap::kOld));  // read value.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kPositiveIntLiteral:
        simple_value_ = &Integer::ZoneHandle(
            Z, Integer::New(static_cast<int64_t>(helper_->ReadUInt()),
                            Heap::kOld));  // read value.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kDoubleLiteral:
        simple_value_ = &Double::ZoneHandle(
            Z, Double::New(helper_->ReadDouble(), Heap::kOld));  // read value.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kTrueLiteral:
        simple_value_ = &Bool::Handle(Z, Bool::Get(true).ptr());
        return true;
      case kFalseLiteral:
        simple_value_ = &Bool::Handle(Z, Bool::Get(false).ptr());
        return true;
      case kNullLiteral:
        simple_value_ = &Instance::ZoneHandle(Z, Instance::null());
        return true;
      default:
        return false;
    }
  }

  const Instance& SimpleValue() { return *simple_value_; }
  Zone* zone() const { return zone_; }

 private:
  TranslationHelper& translation_helper_;
  Zone* zone_;
  Instance* simple_value_;
  KernelReaderHelper* helper_;

  DISALLOW_COPY_AND_ASSIGN(SimpleExpressionConverter);
};

ArrayPtr KernelLoader::MakeFieldsArray() {
  const intptr_t len = fields_.length();
  const Array& res = Array::Handle(zone_, Array::New(len, Heap::kOld));
  for (intptr_t i = 0; i < len; i++) {
    res.SetAt(i, *fields_[i]);
  }
  return res.ptr();
}

ArrayPtr KernelLoader::MakeFunctionsArray() {
  const intptr_t len = functions_.length();
  const Array& res = Array::Handle(zone_, Array::New(len, Heap::kOld));
  for (intptr_t i = 0; i < len; i++) {
    res.SetAt(i, *functions_[i]);
  }
  return res.ptr();
}

LibraryPtr BuildingTranslationHelper::LookupLibraryByKernelLibrary(
    NameIndex library,
    bool required) {
  return loader_->LookupLibrary(library);
}

ClassPtr BuildingTranslationHelper::LookupClassByKernelClass(NameIndex klass,
                                                             bool required) {
#if defined(DEBUG)
  LibraryLookupHandleScope library_lookup_handle_scope(library_lookup_handle_);
#endif  // defined(DEBUG)
  library_lookup_handle_ = loader_->LookupLibraryFromClass(klass);
  return loader_->LookupClass(library_lookup_handle_, klass);
}

LibraryIndex::LibraryIndex(const ExternalTypedData& kernel_data)
    : reader_(kernel_data) {
  intptr_t data_size = reader_.size();

  procedure_count_ = reader_.ReadUInt32At(data_size - 4);
  procedure_index_offset_ = data_size - 4 - (procedure_count_ + 1) * 4;

  class_count_ = reader_.ReadUInt32At(procedure_index_offset_ - 4);
  class_index_offset_ = procedure_index_offset_ - 4 - (class_count_ + 1) * 4;

  source_references_offset_ = -1;
  source_references_offset_ = reader_.ReadUInt32At(class_index_offset_ - 4);
}

ClassIndex::ClassIndex(const ProgramBinary& binary,
                       intptr_t class_offset,
                       intptr_t class_size)
    : reader_(binary) {
  Init(class_offset, class_size);
}

ClassIndex::ClassIndex(const ExternalTypedData& library_kernel_data,
                       intptr_t class_offset,
                       intptr_t class_size)
    : reader_(library_kernel_data) {
  Init(class_offset, class_size);
}

void ClassIndex::Init(intptr_t class_offset, intptr_t class_size) {
  procedure_count_ = reader_.ReadUInt32At(class_offset + class_size - 4);
  procedure_index_offset_ =
      class_offset + class_size - 4 - (procedure_count_ + 1) * 4;
}

using UriToSourceTable = DirectChainedHashMap<UriToSourceTableTrait>;

KernelLoader::KernelLoader(Program* program,
                           UriToSourceTable* uri_to_source_table)
    : program_(program),
      thread_(Thread::Current()),
      zone_(thread_->zone()),
      no_active_isolate_scope_(),
      patch_classes_(Array::ZoneHandle(zone_)),
      active_class_(),
      library_kernel_offset_(-1),  // Set to the correct value in LoadLibrary
      correction_offset_(-1),      // Set to the correct value in LoadLibrary
      loading_native_wrappers_library_(false),
      library_kernel_data_(ExternalTypedData::ZoneHandle(zone_)),
      kernel_program_info_(KernelProgramInfo::ZoneHandle(zone_)),
      translation_helper_(this, thread_, Heap::kOld),
      helper_(zone_,
              &translation_helper_,
              program_->binary(),
              /*data_program_offset=*/0),
      constant_reader_(&helper_, &active_class_),
      type_translator_(&helper_,
                       &constant_reader_,
                       &active_class_,
                       /* finalize= */ false),
      inferred_type_metadata_helper_(&helper_, &constant_reader_),
      static_field_value_(Object::Handle(Z)),
      pragma_class_(Class::Handle(Z)),
      pragma_name_field_(Field::Handle(Z)),
      pragma_options_field_(Field::Handle(Z)),
      name_index_handle_(Smi::Handle(Z)),
      expression_evaluation_library_(Library::Handle(Z)) {
  if (!program->is_single_program()) {
    FATAL(
        "Trying to load a concatenated dill file at a time where that is "
        "not allowed");
  }
  InitializeFields(uri_to_source_table);
}

void KernelLoader::ReadObfuscationProhibitions() {
  ObfuscationProhibitionsMetadataHelper helper(&helper_);
  helper.ReadProhibitions();
}

void KernelLoader::ReadLoadingUnits() {
  LoadingUnitsMetadataHelper helper(&helper_);
  helper.ReadLoadingUnits();
}

Object& KernelLoader::LoadEntireProgram(Program* program,
                                        bool process_pending_classes) {
  Thread* thread = Thread::Current();

  TIMELINE_DURATION(thread, Isolate, "LoadKernel");

  if (program->is_single_program()) {
    KernelLoader loader(program, /*uri_to_source_table=*/nullptr);
    return Object::Handle(loader.LoadProgram(process_pending_classes));
  }

  kernel::Reader reader(program->binary());
  GrowableArray<intptr_t> subprogram_file_starts;
  index_programs(&reader, &subprogram_file_starts);

  Zone* zone = thread->zone();
  Library& library = Library::Handle(zone);
  intptr_t subprogram_count = subprogram_file_starts.length() - 1;

  // First index all source tables.
  UriToSourceTable uri_to_source_table;
  UriToSourceTableEntry wrapper;
  for (intptr_t i = subprogram_count - 1; i >= 0; --i) {
    intptr_t subprogram_start = subprogram_file_starts.At(i);
    intptr_t subprogram_end = subprogram_file_starts.At(i + 1);
    Thread* thread_ = Thread::Current();
    Zone* zone_ = thread_->zone();
    TranslationHelper translation_helper(thread);
    KernelReaderHelper helper_(
        zone_, &translation_helper,
        program->binary().SubView(subprogram_start, subprogram_end), 0);  // ,
    const intptr_t source_table_size = helper_.SourceTableSize();
    for (intptr_t index = 0; index < source_table_size; ++index) {
      const String& uri_string = helper_.SourceTableUriFor(index);
      wrapper.uri = &uri_string;
      TypedData& line_starts =
          TypedData::Handle(Z, helper_.GetLineStartsFor(index));
      if (line_starts.Length() == 0) continue;
      const String& script_source = helper_.GetSourceFor(index);
      wrapper.uri = &uri_string;
      UriToSourceTableEntry* pair = uri_to_source_table.LookupValue(&wrapper);
      if (pair != nullptr) {
        // At least two entries with content. Unless the content is the same
        // that's not valid.
        const bool src_differ = pair->sources->CompareTo(script_source) != 0;
        const bool line_starts_differ =
            !pair->line_starts->CanonicalizeEquals(line_starts);
        if (src_differ || line_starts_differ) {
          FATAL(
              "Invalid kernel binary: Contains at least two source entries "
              "that do not agree. URI '%s', difference: %s. Subprogram count: "
              "%" Pd ".",
              uri_string.ToCString(),
              src_differ && line_starts_differ
                  ? "src and line starts"
                  : (src_differ ? "src" : "line starts"),
              subprogram_count);
        }
      } else {
        UriToSourceTableEntry* tmp = new UriToSourceTableEntry();
        tmp->uri = &uri_string;
        tmp->sources = &script_source;
        tmp->line_starts = &line_starts;
        uri_to_source_table.Insert(tmp);
      }
    }
  }

  // Create "fake programs" for each sub-program.
  for (intptr_t i = subprogram_count - 1; i >= 0; --i) {
    intptr_t subprogram_start = subprogram_file_starts.At(i);
    intptr_t subprogram_end = subprogram_file_starts.At(i + 1);
    reader.set_raw_buffer(program->kernel_data() + subprogram_start);
    reader.set_size(subprogram_end - subprogram_start);
    reader.set_offset(0);
    const char* error = nullptr;
    std::unique_ptr<Program> subprogram = Program::ReadFrom(&reader, &error);
    if (subprogram == nullptr) {
      FATAL("Failed to load kernel file: %s", error);
    }
    ASSERT(subprogram->is_single_program());
    KernelLoader loader(subprogram.get(), &uri_to_source_table);
    Object& load_result = Object::Handle(loader.LoadProgram(false));
    if (load_result.IsError()) return load_result;

    if (load_result.IsLibrary()) {
      library ^= load_result.ptr();
    }
  }

  if (process_pending_classes && !ClassFinalizer::ProcessPendingClasses()) {
    // Class finalization failed -> sticky error would be set.
    return Error::Handle(thread->StealStickyError());
  }

  return library;
}

void KernelLoader::index_programs(
    kernel::Reader* reader,
    GrowableArray<intptr_t>* subprogram_file_starts) {
  // Dill files can be concatenated (e.g. cat a.dill b.dill > c.dill), so we
  // need to first index the (possibly combined) file.
  // First entry becomes last entry.
  // Last entry is for ease of calculating size of last subprogram.
  subprogram_file_starts->Add(reader->size());
  reader->set_offset(reader->size() - 4);
  while (reader->offset() > 0) {
    intptr_t size = reader->ReadUInt32();
    intptr_t start = reader->offset() - size;
    if (start < 0) {
      FATAL("Invalid kernel binary: Indicated size is invalid.");
    }
    subprogram_file_starts->Add(start);
    reader->set_offset(start - 4);
  }
  subprogram_file_starts->Reverse();
}

StringPtr KernelLoader::FindSourceForScript(const uint8_t* kernel_buffer,
                                            intptr_t kernel_buffer_length,
                                            const String& uri) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  TranslationHelper translation_helper(thread);
  // Note: it is okay to have typed_data be nullptr here because we are not
  // creating any long living views into the kernel_buffer.
  const ProgramBinary binary = {/*typed_data=*/nullptr, kernel_buffer,
                                kernel_buffer_length};
  KernelReaderHelper reader(zone, &translation_helper, binary, 0);
  intptr_t source_table_size = reader.SourceTableSize();
  for (intptr_t i = 0; i < source_table_size; ++i) {
    const String& source_uri = reader.SourceTableUriFor(i);
    if (source_uri.EndsWith(uri)) {
      return reader.GetSourceFor(i).ptr();
    }
  }
  return String::null();
}

void KernelLoader::InitializeFields(UriToSourceTable* uri_to_source_table) {
  const intptr_t source_table_size = helper_.SourceTableSize();
  const Array& scripts =
      Array::Handle(Z, Array::New(source_table_size, Heap::kOld));

  // Copy the Kernel string offsets out of the binary and into the VM's heap.
  ASSERT(program_->string_table_offset() >= 0);
  Reader reader(program_->binary());
  reader.set_offset(program_->string_table_offset());
  intptr_t count = reader.ReadUInt() + 1;
  TypedData& offsets = TypedData::Handle(
      Z, TypedData::New(kTypedDataUint32ArrayCid, count, Heap::kOld));
  offsets.SetUint32(0, 0);
  intptr_t end_offset = 0;
  for (intptr_t i = 1; i < count; ++i) {
    end_offset = reader.ReadUInt();
    offsets.SetUint32(i << 2, end_offset);
  }

  // Create view of the string data.
  const ExternalTypedData& data = ExternalTypedData::Handle(
      Z,
      reader.ExternalDataFromTo(reader.offset(), reader.offset() + end_offset));

  // Create a view of the constants table (first part)
  // and the constant table index (second part).
  const ExternalTypedData& constants_table = ExternalTypedData::Handle(
      Z, reader.ExternalDataFromTo(program_->constant_table_offset(),
                                   program_->name_table_offset()));

  // Copy the canonical names into the VM's heap.  Encode them as unsigned, so
  // the parent indexes are adjusted when extracted.
  reader.set_offset(program_->name_table_offset());
  count = reader.ReadUInt() * 2;
  TypedData& names = TypedData::Handle(
      Z, TypedData::New(kTypedDataUint32ArrayCid, count, Heap::kOld));
  for (intptr_t i = 0; i < count; ++i) {
    names.SetUint32(i << 2, reader.ReadUInt());
  }

  // Create view of metadata payloads.
  const ExternalTypedData& metadata_payloads = ExternalTypedData::Handle(
      Z, reader.ExternalDataFromTo(program_->metadata_payloads_offset(),
                                   program_->metadata_mappings_offset()));
  ASSERT(Utils::IsAligned(metadata_payloads.DataAddr(0), kWordSize));

  // Create view of metadata mappings.
  const ExternalTypedData& metadata_mappings = ExternalTypedData::Handle(
      Z, reader.ExternalDataFromTo(program_->metadata_mappings_offset(),
                                   program_->string_table_offset()));

#if defined(DEBUG)
  MetadataHelper::VerifyMetadataMappings(metadata_mappings);
#endif

  const Array& libraries_cache =
      Array::Handle(Z, HashTables::New<UnorderedHashMap<SmiTraits>>(
                           program_->library_count(), Heap::kOld));

  const intptr_t kClassesPerLibraryGuess = 5;
  const Array& classes_cache = Array::Handle(
      Z, HashTables::New<UnorderedHashMap<SmiTraits>>(
             kClassesPerLibraryGuess * program_->library_count(), Heap::kOld));

  kernel_program_info_ = KernelProgramInfo::New(
      offsets, data, names, metadata_payloads, metadata_mappings,
      constants_table, scripts, libraries_cache, classes_cache,
      program_->typed_data() == nullptr ? Object::null_object()
                                        : *program_->typed_data());

  H.InitFromKernelProgramInfo(kernel_program_info_);

  Script& script = Script::Handle(Z);
  for (intptr_t index = 0; index < source_table_size; ++index) {
    script = LoadScriptAt(index, uri_to_source_table);
    scripts.SetAt(index, script);
  }
}

KernelLoader::KernelLoader(const Script& script,
                           const ExternalTypedData& kernel_data,
                           intptr_t data_program_offset)
    : program_(nullptr),
      thread_(Thread::Current()),
      zone_(thread_->zone()),
      no_active_isolate_scope_(),
      patch_classes_(Array::ZoneHandle(zone_)),
      library_kernel_offset_(data_program_offset),
      correction_offset_(0),
      loading_native_wrappers_library_(false),
      library_kernel_data_(ExternalTypedData::ZoneHandle(zone_)),
      kernel_program_info_(
          KernelProgramInfo::ZoneHandle(zone_, script.kernel_program_info())),
      translation_helper_(this, thread_, Heap::kOld),
      helper_(zone_, &translation_helper_, script, kernel_data, 0),
      constant_reader_(&helper_, &active_class_),
      type_translator_(&helper_,
                       &constant_reader_,
                       &active_class_,
                       /* finalize= */ false),
      inferred_type_metadata_helper_(&helper_, &constant_reader_),
      static_field_value_(Object::Handle(Z)),
      pragma_class_(Class::Handle(Z)),
      pragma_name_field_(Field::Handle(Z)),
      pragma_options_field_(Field::Handle(Z)),
      name_index_handle_(Smi::Handle(Z)),
      expression_evaluation_library_(Library::Handle(Z)) {
  ASSERT(T.active_class_ == &active_class_);
  T.finalize_ = false;
  library_kernel_data_ = kernel_data.ptr();
  H.InitFromKernelProgramInfo(kernel_program_info_);
}

bool KernelLoader::IsClassName(NameIndex name,
                               const String& library,
                               const String& klass) {
  ASSERT(H.IsClass(name));
  StringIndex class_name_index = H.CanonicalNameString(name);

  if (!H.StringEquals(class_name_index, klass.ToCString())) {
    return false;
  }
  ASSERT(H.IsLibrary(H.CanonicalNameParent(name)));
  StringIndex library_name_index =
      H.CanonicalNameString(H.CanonicalNameParent(name));
  return H.StringEquals(library_name_index, library.ToCString());
}

ObjectPtr KernelLoader::LoadProgram(bool process_pending_classes) {
  SafepointWriteRwLocker ml(thread_, thread_->isolate_group()->program_lock());
  ASSERT(kernel_program_info_.constants() == Array::null());

  if (!program_->is_single_program()) {
    FATAL(
        "Trying to load a concatenated dill file at a time where that is "
        "not allowed");
  }

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Note that `problemsAsJson` on Component is implicitly skipped.
    const intptr_t length = program_->library_count();
    for (intptr_t i = 0; i < length; i++) {
      LoadLibrary(i);
    }

    // Finalize still pending classes if requested.
    if (process_pending_classes) {
      if (!ClassFinalizer::ProcessPendingClasses()) {
        // Class finalization failed -> sticky error would be set.
        return H.thread()->StealStickyError();
      }
    }

    // Ensure that `pragma` class is looked up before we install the constants
    // table: Once the constants table is installed finalization of classes will
    // eagerly want to evaluate constants and doing so will require those two
    // classes to be available.
    EnsurePragmaClassIsLookedUp();

    // Sets the constants array to an empty array with the length equal to
    // the number of constants. The array gets filled lazily while reading
    // constants.
    ASSERT(kernel_program_info_.constants_table() != ExternalTypedData::null());
    ConstantReader constant_reader(&helper_, &active_class_);
    const intptr_t num_consts = constant_reader.NumConstants();
    const Array& array = Array::Handle(Z, Array::New(num_consts, Heap::kOld));
    for (intptr_t i = 0; i < num_consts; i++) {
      array.SetAt(i, Object::sentinel());
    }
    kernel_program_info_.set_constants(array);
    H.SetConstants(array);  // for caching

    NameIndex main = program_->main_method();
    if (main != -1) {
      NameIndex main_library = H.EnclosingName(main);
      return LookupLibrary(main_library);
    }

    return Library::null();
  }

  // Either class finalization failed or we caught a compile error.
  // In both cases sticky error would be set.
  return Thread::Current()->StealStickyError();
}

void KernelLoader::LoadLibrary(const Library& library) {
  // This will be invoked by VM bootstrapping code.
  SafepointWriteRwLocker ml(thread_, thread_->isolate_group()->program_lock());

  ASSERT(!library.Loaded());

  const auto& uri = String::Handle(Z, library.url());
  const intptr_t num_libraries = program_->library_count();
  for (intptr_t i = 0; i < num_libraries; ++i) {
    const String& library_uri = LibraryUri(i);
    if (library_uri.Equals(uri)) {
      LoadLibrary(i);
      return;
    }
  }
}

ObjectPtr KernelLoader::LoadExpressionEvaluationFunction(
    const String& library_url,
    const String& klass) {
  // Find the original context, i.e. library/class, in which the evaluation will
  // happen.
  const Library& real_library =
      Library::Handle(Z, Library::LookupLibrary(thread_, library_url));
  ASSERT(!real_library.IsNull());
  const Class& real_class = Class::Handle(
      Z, klass.IsNull() ? real_library.toplevel_class()
                        : real_library.LookupClassAllowPrivate(klass));
  ASSERT(!real_class.IsNull());

  const intptr_t num_cids = IG->class_table()->NumCids();
  const intptr_t num_libs =
      GrowableObjectArray::Handle(IG->object_store()->libraries()).Length();

  // Load the "evaluate:source" expression evaluation library.
  ASSERT(expression_evaluation_library_.IsNull());
  ASSERT(H.GetExpressionEvaluationClass().IsNull());
  ASSERT(H.GetExpressionEvaluationFunction().IsNull());
  H.SetExpressionEvaluationRealClass(real_class);
  const Object& result = Object::Handle(Z, LoadProgram(true));
  if (result.IsError()) {
    return result.ptr();
  }
  const Function& function = H.GetExpressionEvaluationFunction();
  ASSERT(!function.IsNull());
  ASSERT(
      GrowableObjectArray::Handle(IG->object_store()->libraries()).Length() ==
      num_libs);
  ASSERT(IG->class_table()->NumCids() == num_cids);

  // Make the expression evaluation function have the right script,
  // kernel data and parent.
  const auto& eval_script = Script::Handle(Z, function.script());
  ASSERT(!expression_evaluation_library_.IsNull());
  auto& kernel_data = ExternalTypedData::Handle(
      Z, expression_evaluation_library_.kernel_data());
  intptr_t kernel_offset = expression_evaluation_library_.kernel_offset();
  function.SetKernelDataAndScript(eval_script, kernel_data, kernel_offset);

  function.set_owner(real_class);

  ASSERT(real_class.is_finalized());
  // The owner class has already been marked as finalized so the signature of
  // this added function must be finalized here, since finalization of member
  // types will not be called anymore.
  FunctionType& signature = FunctionType::Handle(Z, function.signature());
  if (!function.is_static()) {
    // Patch the illegal receiver type (type class with kIllegalCid) to dynamic.
    signature.SetParameterTypeAt(0, Object::dynamic_type());
  }
  signature ^= ClassFinalizer::FinalizeType(signature);
  function.SetSignature(signature);

  return function.ptr();
}

void KernelLoader::FindModifiedLibraries(Program* program,
                                         IsolateGroup* isolate_group,
                                         BitVector* modified_libs,
                                         bool force_reload,
                                         bool* is_empty_program,
                                         intptr_t* p_num_classes,
                                         intptr_t* p_num_procedures) {
  LongJumpScope jump;
  Zone* zone = Thread::Current()->zone();
  if (setjmp(*jump.Set()) == 0) {
    if (force_reload) {
      // If a reload is being forced we mark all libraries as having
      // been modified.
      const auto& libs = GrowableObjectArray::Handle(
          isolate_group->object_store()->libraries());
      intptr_t num_libs = libs.Length();
      Library& lib = dart::Library::Handle(zone);
      for (intptr_t i = 0; i < num_libs; i++) {
        lib ^= libs.At(i);
        if (!lib.is_dart_scheme()) {
          modified_libs->Add(lib.index());
        }
      }
      return;
    }

    if (p_num_classes != nullptr) {
      *p_num_classes = 0;
    }
    if (p_num_procedures != nullptr) {
      *p_num_procedures = 0;
    }

    // Now go through all the libraries that are present in the incremental
    // kernel files, these will constitute the modified libraries.
    *is_empty_program = true;
    if (program->is_single_program()) {
      KernelLoader loader(program, /*uri_to_source_table=*/nullptr);
      loader.walk_incremental_kernel(modified_libs, is_empty_program,
                                     p_num_classes, p_num_procedures);
    }
    kernel::Reader reader(program->binary());
    GrowableArray<intptr_t> subprogram_file_starts;
    index_programs(&reader, &subprogram_file_starts);

    // Create "fake programs" for each sub-program.
    intptr_t subprogram_count = subprogram_file_starts.length() - 1;
    for (intptr_t i = 0; i < subprogram_count; ++i) {
      intptr_t subprogram_start = subprogram_file_starts.At(i);
      intptr_t subprogram_end = subprogram_file_starts.At(i + 1);
      reader.set_raw_buffer(program->kernel_data() + subprogram_start);
      reader.set_size(subprogram_end - subprogram_start);
      reader.set_offset(0);
      const char* error = nullptr;
      std::unique_ptr<Program> subprogram = Program::ReadFrom(&reader, &error);
      if (subprogram == nullptr) {
        FATAL("Failed to load kernel file: %s", error);
      }
      ASSERT(subprogram->is_single_program());
      KernelLoader loader(subprogram.get(), /*uri_to_source_table=*/nullptr);
      loader.walk_incremental_kernel(modified_libs, is_empty_program,
                                     p_num_classes, p_num_procedures);
    }
  }
}

void KernelLoader::walk_incremental_kernel(BitVector* modified_libs,
                                           bool* is_empty_program,
                                           intptr_t* p_num_classes,
                                           intptr_t* p_num_procedures) {
  intptr_t length = program_->library_count();
  *is_empty_program = *is_empty_program && (length == 0);
  bool collect_library_stats =
      p_num_classes != nullptr || p_num_procedures != nullptr;
  intptr_t num_classes = 0;
  intptr_t num_procedures = 0;
  Library& lib = Library::Handle(Z);
  for (intptr_t i = 0; i < length; i++) {
    intptr_t kernel_offset = library_offset(i);
    helper_.SetOffset(kernel_offset);
    LibraryHelper library_helper(&helper_);
    library_helper.ReadUntilIncluding(LibraryHelper::kCanonicalName);
    lib = LookupLibraryOrNull(library_helper.canonical_name_);
    if (!lib.IsNull() && !lib.is_dart_scheme()) {
      // This is a library that already exists so mark it as being modified.
      modified_libs->Add(lib.index());
    }
    if (collect_library_stats) {
      intptr_t library_end = library_offset(i + 1);
      library_kernel_data_ =
          helper_.reader_.ExternalDataFromTo(kernel_offset, library_end);
      LibraryIndex library_index(library_kernel_data_);
      num_classes += library_index.class_count();
      num_procedures += library_index.procedure_count();
    }
  }
  if (p_num_classes != nullptr) {
    *p_num_classes += num_classes;
  }
  if (p_num_procedures != nullptr) {
    *p_num_procedures += num_procedures;
  }
}

void KernelLoader::ReadInferredType(const Field& field,
                                    intptr_t kernel_offset) {
  const InferredTypeMetadata type =
      inferred_type_metadata_helper_.GetInferredType(kernel_offset,
                                                     /*read_constant=*/false);
  if (type.IsTrivial()) {
    return;
  }
  field.set_guarded_cid(type.cid);
  field.set_is_nullable(type.IsNullable());
  field.set_guarded_list_length(Field::kNoFixedLength);
  if (FLAG_precompiled_mode) {
    field.set_is_unboxed(!field.is_late() && !field.is_static() &&
                         !field.is_nullable() &&
                         ((field.guarded_cid() == kDoubleCid &&
                           FlowGraphCompiler::SupportsUnboxedDoubles()) ||
                          (field.guarded_cid() == kFloat32x4Cid &&
                           FlowGraphCompiler::SupportsUnboxedSimd128()) ||
                          (field.guarded_cid() == kFloat64x2Cid &&
                           FlowGraphCompiler::SupportsUnboxedSimd128()) ||
                          type.IsInt()));
  }
}

void KernelLoader::CheckForInitializer(const Field& field) {
  if (helper_.PeekTag() == kSomething) {
    field.set_has_initializer(true);
    SimpleExpressionConverter converter(&H, &helper_);
    const bool has_simple_initializer =
        converter.IsSimple(helper_.ReaderOffset() + 1);
    if (!has_simple_initializer ||
        (!field.is_static() && !converter.SimpleValue().IsNull())) {
      field.set_has_nontrivial_initializer(true);
    }
    return;
  }
  field.set_has_initializer(false);
  field.set_has_nontrivial_initializer(false);
}

LibraryPtr KernelLoader::LoadLibrary(intptr_t index) {
  if (!program_->is_single_program()) {
    FATAL(
        "Trying to load a concatenated dill file at a time where that is "
        "not allowed");
  }

  // Read library index.
  library_kernel_offset_ = library_offset(index);
  correction_offset_ = library_kernel_offset_;
  intptr_t library_end = library_offset(index + 1);
  intptr_t library_size = library_end - library_kernel_offset_;

  // NOTE: Since |helper_| is used to load the overall kernel program,
  // it's reader's offset is an offset into the overall kernel program.
  // Hence, when setting the kernel offsets of field and functions, one
  // has to subtract the library's kernel offset from the reader's
  // offset.
  helper_.SetOffset(library_kernel_offset_);

  LibraryHelper library_helper(&helper_);
  library_helper.ReadUntilIncluding(LibraryHelper::kCanonicalName);
  if (!FLAG_precompiled_mode && !IG->should_load_vmservice()) {
    StringIndex lib_name_index =
        H.CanonicalNameString(library_helper.canonical_name_);
    if (H.StringEquals(lib_name_index, kVMServiceIOLibraryUri)) {
      // We are not the service isolate and we are not generating an AOT
      // snapshot so we skip loading 'dart:vmservice_io'.
      skip_vmservice_library_ = library_helper.canonical_name_;
      ASSERT(H.IsLibrary(skip_vmservice_library_));
      return Library::null();
    }
  }

  Library& library =
      Library::Handle(Z, LookupLibrary(library_helper.canonical_name_));

  if (library.Loaded()) return library.ptr();

  library.set_is_nnbd(library_helper.IsNonNullableByDefault());
  const NNBDCompiledMode mode =
      library_helper.GetNonNullableByDefaultCompiledMode();
  if (mode == NNBDCompiledMode::kInvalid) {
    H.ReportError(
        "Library '%s' was compiled in an unsupported mixed mode between sound "
        "null safety and not sound null safety.",
        String::Handle(library.url()).ToCString());
  }
  if (!IG->null_safety() && mode == NNBDCompiledMode::kStrong) {
    H.ReportError(
        "Library '%s' was compiled with sound null safety (in strong mode) and "
        "it "
        "requires --sound-null-safety option at runtime",
        String::Handle(library.url()).ToCString());
  }
  if (IG->null_safety() && (mode == NNBDCompiledMode::kWeak)) {
    H.ReportError(
        "Library '%s' was compiled without sound null safety (in weak mode) "
        "and it "
        "cannot be used with --sound-null-safety at runtime",
        String::Handle(library.url()).ToCString());
  }
  library.set_nnbd_compiled_mode(mode);

  library_kernel_data_ = helper_.reader_.ExternalDataFromTo(
      library_kernel_offset_, library_kernel_offset_ + library_size);
  library.set_kernel_data(library_kernel_data_);
  library.set_kernel_offset(library_kernel_offset_);

  LibraryIndex library_index(library_kernel_data_);
  intptr_t class_count = library_index.class_count();

  library_helper.ReadUntilIncluding(LibraryHelper::kName);
  library.SetName(H.DartSymbolObfuscate(library_helper.name_index_));

  // The bootstrapper will take care of creating the native wrapper classes, but
  // we will add the synthetic constructors to them here.
  if (library.name() ==
      Symbols::Symbol(Symbols::kDartNativeWrappersLibNameId).ptr()) {
    ASSERT(library.LoadInProgress());
    loading_native_wrappers_library_ = true;
  } else {
    loading_native_wrappers_library_ = false;
    library.SetLoadInProgress();
  }

  if (library.url() == Symbols::vm_ffi_native_assets().ptr()) {
    const auto& native_assets_library =
        Library::Handle(IG->object_store()->native_assets_library());
    ASSERT(native_assets_library.IsNull());
    IG->object_store()->set_native_assets_library(library);
  }

  library_helper.ReadUntilIncluding(LibraryHelper::kSourceUriIndex);
  const Script& script =
      Script::Handle(Z, ScriptAt(library_helper.source_uri_index_));

  library_helper.ReadUntilExcluding(LibraryHelper::kAnnotations);
  intptr_t annotations_kernel_offset =
      helper_.ReaderOffset() - correction_offset_;
  const intptr_t annotation_count =
      helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < annotation_count; ++i) {
    helper_.SkipExpression();  // read ith annotation.
  }
  library_helper.SetJustRead(LibraryHelper::kAnnotations);

  // Setup toplevel class (which contains library fields/procedures).

  // We do not register expression evaluation classes with the VM:
  // The expression evaluation functions should be GC-able as soon as
  // they are not reachable anymore and we never look them up by name.
  const bool register_class =
      library.ptr() != expression_evaluation_library_.ptr();

  Class& toplevel_class =
      Class::Handle(Z, Class::New(library, Symbols::TopLevel(), script,
                                  TokenPosition::kNoSource, register_class));
  toplevel_class.set_is_abstract();
  toplevel_class.set_is_declaration_loaded();
  toplevel_class.set_is_type_finalized();
  toplevel_class.set_num_type_arguments_unsafe(0);
  library.set_toplevel_class(toplevel_class);

  library_helper.ReadUntilExcluding(LibraryHelper::kDependencies);
  LoadLibraryImportsAndExports(&library, toplevel_class);
  library_helper.SetJustRead(LibraryHelper::kDependencies);

  // Everything up til the classes are skipped implicitly, and library_helper
  // is no longer used.

  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(Z, IG->object_store()->pending_classes());

  // Load all classes.
  intptr_t next_class_offset = library_index.ClassOffset(0);
  Class& klass = Class::Handle(Z);
  for (intptr_t i = 0; i < class_count; ++i) {
    helper_.SetOffset(next_class_offset);
    next_class_offset = library_index.ClassOffset(i + 1);
    LoadClass(library, toplevel_class, next_class_offset, &klass);
    if (register_class) {
      classes.Add(klass, Heap::kOld);
    }
  }

  if (loading_native_wrappers_library_ || !register_class) {
    FinishTopLevelClassLoading(toplevel_class, library, library_index);
  }

  // Used for mirrors and allows VM to recognize @pragma annotations on
  // libraries.
  if (annotation_count > 0) {
    ASSERT(annotations_kernel_offset > 0);
    library.AddMetadata(library, annotations_kernel_offset);
  }

  if (register_class) {
    helper_.SetOffset(library_index.SourceReferencesOffset());
    intptr_t count = helper_.ReadUInt();
    const GrowableObjectArray& used_scripts =
        GrowableObjectArray::Handle(library.used_scripts());
    Script& script = Script::Handle(Z);
    for (intptr_t i = 0; i < count; i++) {
      intptr_t uri_index = helper_.ReadUInt();
      script = ScriptAt(uri_index);
      used_scripts.Add(script);
    }
  }
  if (!library.Loaded()) library.SetLoaded();

  return library.ptr();
}

void KernelLoader::FinishTopLevelClassLoading(
    const Class& toplevel_class,
    const Library& library,
    const LibraryIndex& library_index) {
  if (toplevel_class.is_loaded()) {
    return;
  }
  TIMELINE_DURATION(Thread::Current(), Isolate, "FinishTopLevelClassLoading");

  ActiveClassScope active_class_scope(&active_class_, &toplevel_class);

  // Offsets within library index are whole program offsets and not
  // relative to the library.
  const intptr_t correction = correction_offset_ - library_kernel_offset_;
  helper_.SetOffset(library_index.ClassOffset(library_index.class_count()) +
                    correction);

  const intptr_t extension_count = helper_.ReadListLength();
  for (intptr_t i = 0; i < extension_count; ++i) {
    helper_.ReadTag();                     // read tag.
    helper_.SkipCanonicalNameReference();  // skip canonical name.
    helper_.SkipStringReference();         // skip name.
    helper_.SkipListOfExpressions();       // skip annotations.
    helper_.ReadUInt();                    // read source uri index.
    helper_.ReadPosition();                // read file offset.
    helper_.ReadByte();                    // skip flags.
    helper_.SkipTypeParametersList();      // skip type parameter list.
    helper_.SkipDartType();                // skip on-type.
    Tag tag = helper_.ReadTag();
    if (tag != kNothing) {
      helper_.SkipListOfDartTypes();                // skip shown types.
      helper_.SkipListOfCanonicalNameReferences();  // skip shown members.
      helper_.SkipListOfCanonicalNameReferences();  // skip shown getters.
      helper_.SkipListOfCanonicalNameReferences();  // skip shown setters.
      helper_.SkipListOfCanonicalNameReferences();  // skip shown operators.
      helper_.SkipListOfDartTypes();                // skip hidden types.
      helper_.SkipListOfCanonicalNameReferences();  // skip hidden members.
      helper_.SkipListOfCanonicalNameReferences();  // skip hidden getters.
      helper_.SkipListOfCanonicalNameReferences();  // skip hidden setters.
      helper_.SkipListOfCanonicalNameReferences();  // skip hidden operators.
    }

    const intptr_t extension_member_count = helper_.ReadListLength();
    for (intptr_t j = 0; j < extension_member_count; ++j) {
      helper_.SkipName();                    // skip name.
      helper_.ReadByte();                    // read kind.
      helper_.ReadByte();                    // read flags.
      helper_.SkipCanonicalNameReference();  // skip member reference
    }
  }

  const intptr_t inline_class_count = helper_.ReadListLength();
  for (intptr_t i = 0; i < inline_class_count; ++i) {
    helper_.ReadTag();                     // read tag.
    helper_.SkipCanonicalNameReference();  // skip canonical name.
    helper_.SkipStringReference();         // skip name.
    helper_.SkipListOfExpressions();       // skip annotations.
    helper_.ReadUInt();                    // read source uri index.
    helper_.ReadPosition();                // read file offset.
    helper_.ReadByte();                    // skip flags.
    helper_.SkipTypeParametersList();      // skip type parameter list.
    helper_.SkipDartType();                // skip declared representation type.
    helper_.SkipStringReference();         // skip representation name.
    helper_.SkipListOfDartTypes();         // skip implements types.

    const intptr_t inline_class_member_count = helper_.ReadListLength();
    for (intptr_t j = 0; j < inline_class_member_count; ++j) {
      helper_.SkipName();                    // skip name.
      helper_.ReadByte();                    // read kind.
      helper_.ReadByte();                    // read flags.
      helper_.SkipCanonicalNameReference();  // skip member reference
    }
  }

  fields_.Clear();
  functions_.Clear();

  // Load toplevel fields.
  const intptr_t field_count = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < field_count; ++i) {
    intptr_t field_offset = helper_.ReaderOffset() - correction_offset_;
    ActiveMemberScope active_member_scope(&active_class_, nullptr);
    FieldHelper field_helper(&helper_);
    field_helper.ReadUntilExcluding(FieldHelper::kName);

    const String& name = helper_.ReadNameAsFieldName();
    field_helper.SetJustRead(FieldHelper::kName);

    field_helper.ReadUntilExcluding(FieldHelper::kAnnotations);
    intptr_t annotation_count = helper_.ReadListLength();
    bool has_pragma_annotation;
    ReadVMAnnotations(library, annotation_count, /*native_name=*/nullptr,
                      /*is_invisible_function=*/nullptr,
                      /*is_isolate_unsendable=*/nullptr,
                      &has_pragma_annotation);
    field_helper.SetJustRead(FieldHelper::kAnnotations);

    field_helper.ReadUntilExcluding(FieldHelper::kType);
    const Object& script_class =
        ClassForScriptAt(toplevel_class, field_helper.source_uri_index_);
    // In the VM all const fields are implicitly final whereas in Kernel they
    // are not final because they are not explicitly declared that way.
    const bool is_final = field_helper.IsConst() || field_helper.IsFinal();
    // Only instance fields could be covariant.
    ASSERT(!field_helper.IsCovariant() &&
           !field_helper.IsGenericCovariantImpl());
    const bool is_late = field_helper.IsLate();
    const bool is_extension_member = field_helper.IsExtensionMember();
    const Field& field = Field::Handle(
        Z, Field::NewTopLevel(name, is_final, field_helper.IsConst(), is_late,
                              script_class, field_helper.position_,
                              field_helper.end_position_));
    field.set_kernel_offset(field_offset);
    field.set_has_pragma(has_pragma_annotation);
    field.set_is_extension_member(is_extension_member);
    const AbstractType& type = T.BuildType();  // read type.
    field.SetFieldType(type);
    ReadInferredType(field, field_offset + library_kernel_offset_);
    CheckForInitializer(field);
    // In NNBD libraries, static fields with initializers are
    // implicitly late.
    if (field.has_initializer() && library.is_nnbd()) {
      field.set_is_late(true);
    }
    field_helper.SetJustRead(FieldHelper::kType);
    field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
    intptr_t field_initializer_offset = helper_.ReaderOffset();
    field_helper.ReadUntilExcluding(FieldHelper::kEnd);

    {
      AlternativeReadingScope alt(&helper_.reader_, field_initializer_offset);
      static_field_value_ = ReadInitialFieldValue(field, &field_helper);
    }
    GenerateFieldAccessors(toplevel_class, field, &field_helper);
    IG->RegisterStaticField(field, static_field_value_);

    if ((FLAG_enable_mirrors || has_pragma_annotation) &&
        annotation_count > 0) {
      library.AddMetadata(field, field_offset);
    }
    fields_.Add(&field);
  }

  ASSERT(!toplevel_class.is_loaded());

  // Load toplevel procedures.
  intptr_t next_procedure_offset =
      library_index.ProcedureOffset(0) + correction;
  const intptr_t procedure_count = library_index.procedure_count();
  for (intptr_t i = 0; i < procedure_count; ++i) {
    helper_.SetOffset(next_procedure_offset);
    next_procedure_offset = library_index.ProcedureOffset(i + 1) + correction;
    LoadProcedure(library, toplevel_class, false, next_procedure_offset);
    // LoadProcedure calls Library::GetMetadata which invokes Dart code
    // which may recursively trigger class finalization and
    // FinishTopLevelClassLoading.
    // In such case, return immediately and avoid overwriting already finalized
    // functions with freshly loaded and not yet finalized.
    if (toplevel_class.is_loaded()) {
      return;
    }
  }

  toplevel_class.SetFields(Array::Handle(MakeFieldsArray()));
  toplevel_class.SetFunctions(Array::Handle(MakeFunctionsArray()));

  String& name = String::Handle(Z);
  for (intptr_t i = 0, n = fields_.length(); i < n; ++i) {
    const Field* field = fields_.At(i);
    name = field->name();
    library.AddObject(*field, name);
  }
  for (intptr_t i = 0, n = functions_.length(); i < n; ++i) {
    const Function* function = functions_.At(i);
    name = function->name();
    library.AddObject(*function, name);
  }

  ASSERT(!toplevel_class.is_loaded());
  toplevel_class.set_is_loaded(true);
}

void KernelLoader::LoadLibraryImportsAndExports(Library* library,
                                                const Class& toplevel_class) {
  GrowableObjectArray& show_list = GrowableObjectArray::Handle(Z);
  GrowableObjectArray& hide_list = GrowableObjectArray::Handle(Z);
  Array& show_names = Array::Handle(Z);
  Array& hide_names = Array::Handle(Z);
  Namespace& ns = Namespace::Handle(Z);
  LibraryPrefix& library_prefix = LibraryPrefix::Handle(Z);

  const intptr_t deps_count = helper_.ReadListLength();
  const Array& deps = Array::Handle(Array::New(deps_count));
  for (intptr_t dep = 0; dep < deps_count; ++dep) {
    LibraryDependencyHelper dependency_helper(&helper_);

    dependency_helper.ReadUntilExcluding(LibraryDependencyHelper::kAnnotations);
    intptr_t annotations_kernel_offset =
        helper_.ReaderOffset() - correction_offset_;

    dependency_helper.ReadUntilExcluding(LibraryDependencyHelper::kCombinators);

    // Ignore the dependency if the target library is invalid.
    // The error will be caught during compilation.
    if (dependency_helper.target_library_canonical_name_ < 0) {
      const intptr_t combinator_count = helper_.ReadListLength();
      for (intptr_t c = 0; c < combinator_count; ++c) {
        helper_.SkipLibraryCombinator();
      }
      continue;
    }

    // Prepare show and hide lists.
    show_list = GrowableObjectArray::New(Heap::kOld);
    hide_list = GrowableObjectArray::New(Heap::kOld);
    const intptr_t combinator_count = helper_.ReadListLength();
    for (intptr_t c = 0; c < combinator_count; ++c) {
      uint8_t flags = helper_.ReadFlags();
      intptr_t name_count = helper_.ReadListLength();
      for (intptr_t n = 0; n < name_count; ++n) {
        String& show_hide_name =
            H.DartSymbolObfuscate(helper_.ReadStringReference());
        if ((flags & LibraryDependencyHelper::Show) != 0) {
          show_list.Add(show_hide_name, Heap::kOld);
        } else {
          hide_list.Add(show_hide_name, Heap::kOld);
        }
      }
    }

    if (show_list.Length() > 0) {
      show_names = Array::MakeFixedLength(show_list);
    } else {
      show_names = Array::null();
    }

    if (hide_list.Length() > 0) {
      hide_names = Array::MakeFixedLength(hide_list);
    } else {
      hide_names = Array::null();
    }

    Library& target_library = Library::Handle(
        Z, LookupLibrary(dependency_helper.target_library_canonical_name_));
    if (!FLAG_enable_mirrors &&
        target_library.url() == Symbols::DartMirrors().ptr()) {
      H.ReportError(
          "import of dart:mirrors is not supported in the current Dart "
          "runtime");
    }
    if (!Api::IsFfiEnabled() &&
        target_library.url() == Symbols::DartFfi().ptr() &&
        library->url() != Symbols::DartCore().ptr() &&
        library->url() != Symbols::DartInternal().ptr() &&
        library->url() != Symbols::DartFfi().ptr()) {
      H.ReportError(
          "import of dart:ffi is not supported in the current Dart runtime");
    }
    String& prefix = H.DartSymbolPlain(dependency_helper.name_index_);
    ns = Namespace::New(target_library, show_names, hide_names, *library);
    if ((dependency_helper.flags_ & LibraryDependencyHelper::Export) != 0) {
      library->AddExport(ns);
    } else {
      if (prefix.IsNull() || prefix.Length() == 0) {
        library->AddImport(ns);
      } else {
        library_prefix = library->LookupLocalLibraryPrefix(prefix);
        if (!library_prefix.IsNull()) {
          library_prefix.AddImport(ns);
        } else {
          library_prefix = LibraryPrefix::New(
              prefix, ns,
              (dependency_helper.flags_ & LibraryDependencyHelper::Deferred) !=
                  0,
              *library);
          library->AddObject(library_prefix, prefix);
        }
      }
    }

    if (FLAG_enable_mirrors && dependency_helper.annotation_count_ > 0) {
      ASSERT(annotations_kernel_offset > 0);
      library->AddMetadata(ns, annotations_kernel_offset);
    }

    if (prefix.IsNull()) {
      deps.SetAt(dep, ns);
    } else {
      deps.SetAt(dep, library_prefix);
    }
  }

  library->set_dependencies(deps);
}

void KernelLoader::LoadPreliminaryClass(ClassHelper* class_helper,
                                        intptr_t type_parameter_count) {
  const Class* klass = active_class_.klass;

  // Enable access to type_parameters().
  klass->set_is_declaration_loaded();

  // Note: This assumes that ClassHelper is exactly at the position where
  // the length of the type parameters have been read, and that the order in
  // the binary is as follows: [...], kTypeParameters, kSuperClass, kMixinType,
  // kImplementedClasses, [...].

  // Set type parameters.
  T.LoadAndSetupTypeParameters(&active_class_, Object::null_function(), *klass,
                               Object::null_function_type(),
                               type_parameter_count);

  ActiveTypeParametersScope scope(&active_class_, nullptr, Z);

  T.LoadAndSetupBounds(&active_class_, Object::null_function(), *klass,
                       Object::null_function_type(), type_parameter_count);

  // Set super type.  Some classes (e.g., Object) do not have one.
  Tag type_tag = helper_.ReadTag();  // read super class type (part 1).
  if (type_tag == kSomething) {
    AbstractType& super_type =
        T.BuildTypeWithoutFinalization();  // read super class type (part 2).
    klass->set_super_type(Type::Cast(super_type));
  }

  class_helper->SetJustRead(ClassHelper::kSuperClass);
  class_helper->ReadUntilIncluding(ClassHelper::kMixinType);

  // Build implemented interface types
  intptr_t interface_count = helper_.ReadListLength();
  if (interface_count == 0) {
    klass->set_interfaces(Object::empty_array());
  } else {
    const Array& interfaces =
        Array::Handle(Z, Array::New(interface_count, Heap::kOld));
    for (intptr_t i = 0; i < interface_count; i++) {
      const AbstractType& type =
          T.BuildTypeWithoutFinalization();  // read ith type.
      interfaces.SetAt(i, type);
    }
    klass->set_interfaces(interfaces);
  }
  class_helper->SetJustRead(ClassHelper::kImplementedClasses);

  if (class_helper->is_abstract()) {
    klass->set_is_abstract();
  }
  if (class_helper->is_transformed_mixin_application()) {
    klass->set_is_transformed_mixin_application();
  }
  if (class_helper->has_const_constructor()) {
    klass->set_is_const();
  }
  if (class_helper->is_sealed()) {
    klass->set_is_sealed();
  }
  if (class_helper->is_mixin_class()) {
    klass->set_is_mixin_class();
  }
  if (class_helper->is_base()) {
    klass->set_is_base_class();
  }
  if (class_helper->is_interface()) {
    klass->set_is_interface_class();
  }
  if (class_helper->is_final()) {
    klass->set_is_final();
  }
}

void KernelLoader::LoadClass(const Library& library,
                             const Class& toplevel_class,
                             intptr_t class_end,
                             Class* out_class) {
  intptr_t class_offset = helper_.ReaderOffset();
  ClassIndex class_index(program_->binary(), class_offset,
                         class_end - class_offset);

  ClassHelper class_helper(&helper_);
  class_helper.ReadUntilIncluding(ClassHelper::kCanonicalName);
  *out_class = LookupClass(library, class_helper.canonical_name_);
  out_class->set_kernel_offset(class_offset - correction_offset_);

  // The class needs to have a script because all the functions in the class
  // will inherit it.  The predicate Function::IsOptimizable uses the absence of
  // a script to detect test functions that should not be optimized.
  if (out_class->script() == Script::null()) {
    class_helper.ReadUntilIncluding(ClassHelper::kSourceUriIndex);
    const Script& script =
        Script::Handle(Z, ScriptAt(class_helper.source_uri_index_));
    out_class->set_script(script);
  }
  if (out_class->token_pos() == TokenPosition::kNoSource) {
    class_helper.ReadUntilIncluding(ClassHelper::kEndPosition);
    out_class->set_token_pos(class_helper.start_position_);
    out_class->set_end_token_pos(class_helper.end_position_);
  }

  class_helper.ReadUntilIncluding(ClassHelper::kFlags);
  if (class_helper.is_enum_class()) {
    out_class->set_is_enum_class();
  }

  class_helper.ReadUntilExcluding(ClassHelper::kAnnotations);
  intptr_t annotation_count = helper_.ReadListLength();
  bool has_pragma_annotation = false;
  bool is_isolate_unsendable = false;
  ReadVMAnnotations(library, annotation_count, /*native_name=*/nullptr,
                    /*is_invisible_function=*/nullptr, &is_isolate_unsendable,
                    &has_pragma_annotation);
  if (is_isolate_unsendable) {
    out_class->set_is_isolate_unsendable_due_to_pragma(true);
  }
  if (has_pragma_annotation) {
    out_class->set_has_pragma(true);
  }
  class_helper.SetJustRead(ClassHelper::kAnnotations);
  class_helper.ReadUntilExcluding(ClassHelper::kTypeParameters);
  intptr_t type_parameter_counts =
      helper_.ReadListLength();  // read type_parameters list length.

  ActiveClassScope active_class_scope(&active_class_, out_class);
  if (!out_class->is_declaration_loaded()) {
    LoadPreliminaryClass(&class_helper, type_parameter_counts);
  } else {
    ASSERT(type_parameter_counts == 0);
    class_helper.SetJustRead(ClassHelper::kTypeParameters);
  }

  if ((FLAG_enable_mirrors || has_pragma_annotation) && annotation_count > 0) {
    library.AddMetadata(*out_class, class_offset - correction_offset_);
  }

  // We do not register expression evaluation classes with the VM:
  // The expression evaluation functions should be GC-able as soon as
  // they are not reachable anymore and we never look them up by name.
  const bool register_class =
      library.ptr() != expression_evaluation_library_.ptr();
  if (!register_class) {
    H.SetExpressionEvaluationClass(*out_class);
  }

  if (loading_native_wrappers_library_ || !register_class) {
    FinishClassLoading(*out_class, library, toplevel_class, class_offset,
                       class_index, &class_helper);
  }

  helper_.SetOffset(class_end);
}

void KernelLoader::FinishClassLoading(const Class& klass,
                                      const Library& library,
                                      const Class& toplevel_class,
                                      intptr_t class_offset,
                                      const ClassIndex& class_index,
                                      ClassHelper* class_helper) {
  if (klass.is_loaded()) {
    return;
  }

  TIMELINE_DURATION(Thread::Current(), Isolate, "FinishClassLoading");

  ActiveClassScope active_class_scope(&active_class_, &klass);

  // If this is a dart:internal.ClassID class ignore field declarations
  // contained in the Kernel file and instead inject our own const
  // fields.
  const bool discard_fields = klass.InjectCIDFields();

  fields_.Clear();
  functions_.Clear();
  if (!discard_fields) {
    class_helper->ReadUntilExcluding(ClassHelper::kFields);
    int field_count = helper_.ReadListLength();  // read list length.
    for (intptr_t i = 0; i < field_count; ++i) {
      intptr_t field_offset = helper_.ReaderOffset() - correction_offset_;
      ActiveMemberScope active_member(&active_class_, nullptr);
      FieldHelper field_helper(&helper_);

      field_helper.ReadUntilIncluding(FieldHelper::kSourceUriIndex);
      const Object& script_class =
          ClassForScriptAt(klass, field_helper.source_uri_index_);

      field_helper.ReadUntilExcluding(FieldHelper::kName);
      const String& name = helper_.ReadNameAsFieldName();
      field_helper.SetJustRead(FieldHelper::kName);

      field_helper.ReadUntilExcluding(FieldHelper::kAnnotations);
      intptr_t annotation_count = helper_.ReadListLength();
      bool has_pragma_annotation;
      ReadVMAnnotations(library, annotation_count, /*native_name=*/nullptr,
                        /*is_invisible_function=*/nullptr,
                        /*is_isolate_unsendable=*/nullptr,
                        &has_pragma_annotation);
      field_helper.SetJustRead(FieldHelper::kAnnotations);

      field_helper.ReadUntilExcluding(FieldHelper::kType);
      const AbstractType& type =
          T.BuildTypeWithoutFinalization();  // read type.
      field_helper.SetJustRead(FieldHelper::kType);

      const bool is_reflectable =
          field_helper.position_.IsReal() &&
          !(library.is_dart_scheme() && library.IsPrivate(name));
      // In the VM all const fields are implicitly final whereas in Kernel they
      // are not final because they are not explicitly declared that way.
      const bool is_final = field_helper.IsConst() || field_helper.IsFinal();
      const bool is_late = field_helper.IsLate();
      const bool is_extension_member = field_helper.IsExtensionMember();
      Field& field = Field::Handle(
          Z, Field::New(name, field_helper.IsStatic(), is_final,
                        field_helper.IsConst(), is_reflectable, is_late,
                        script_class, type, field_helper.position_,
                        field_helper.end_position_));
      field.set_kernel_offset(field_offset);
      field.set_has_pragma(has_pragma_annotation);
      field.set_is_covariant(field_helper.IsCovariant());
      field.set_is_generic_covariant_impl(
          field_helper.IsGenericCovariantImpl());
      field.set_is_extension_member(is_extension_member);
      ReadInferredType(field, field_offset + library_kernel_offset_);
      CheckForInitializer(field);
      // In NNBD libraries, static fields with initializers are
      // implicitly late.
      if (field_helper.IsStatic() && field.has_initializer() &&
          library.is_nnbd()) {
        field.set_is_late(true);
      }
      field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
      intptr_t field_initializer_offset = helper_.ReaderOffset();
      field_helper.ReadUntilExcluding(FieldHelper::kEnd);

      {
        AlternativeReadingScope alt(&helper_.reader_, field_initializer_offset);
        static_field_value_ = ReadInitialFieldValue(field, &field_helper);
      }
      GenerateFieldAccessors(klass, field, &field_helper);
      if (field.is_static()) {
        IG->RegisterStaticField(field, static_field_value_);
      }
      if ((FLAG_enable_mirrors || has_pragma_annotation) &&
          annotation_count > 0) {
        library.AddMetadata(field, field_offset);
      }
      fields_.Add(&field);
    }
    class_helper->SetJustRead(ClassHelper::kFields);

    if (klass.is_enum_class()) {
      // Add static field 'const _deleted_enum_sentinel'.
      // This field does not need to be of type E.
      Field& deleted_enum_sentinel = Field::ZoneHandle(Z);
      deleted_enum_sentinel =
          Field::New(Symbols::_DeletedEnumSentinel(),
                     /* is_static = */ true,
                     /* is_final = */ true,
                     /* is_const = */ true,
                     /* is_reflectable = */ false,
                     /* is_late = */ false, klass, Object::dynamic_type(),
                     TokenPosition::kNoSource, TokenPosition::kNoSource);
      IG->RegisterStaticField(deleted_enum_sentinel, Object::Handle());
      fields_.Add(&deleted_enum_sentinel);
    }

    // TODO(https://dartbug.com/44454): Make VM recognize the Struct class.
    //
    // The FfiTrampolines currently allocate subtypes of structs and store
    // TypedData in them, without using guards because they are force
    // optimized. We immediately set the guarded_cid_ to kDynamicCid, which
    // is effectively the same as calling this method first with Pointer and
    // subsequently with TypedData with field guards.
    if (klass.UserVisibleName() == Symbols::Compound().ptr() &&
        Library::Handle(Z, klass.library()).url() == Symbols::DartFfi().ptr()) {
      ASSERT(fields_.length() == 1);
      ASSERT(String::Handle(Z, fields_[0]->name())
                 .StartsWith(Symbols::_typedDataBase()));
      fields_[0]->set_guarded_cid(kDynamicCid);
      fields_[0]->set_is_nullable(true);
    }

    // Check that subclasses of AbiSpecificInteger have a mapping for the
    // current ABI.
    //
    // TODO(https://github.com/dart-lang/language/issues/1889): If we make
    // kernel know about the target platform, we can move this check to the
    // frontend.
    const auto& super_class = Class::Handle(Z, klass.SuperClass());
    if (!super_class.IsNull() &&
        super_class.UserVisibleName() == Symbols::AbiSpecificInteger().ptr() &&
        Library::Handle(Z, super_class.library()).url() ==
            Symbols::DartFfi().ptr()) {
      const char* error = nullptr;
      compiler::ffi::NativeType::FromAbstractType(
          Z, AbstractType::Handle(Z, klass.DeclarationType()), &error);
      if (error != nullptr) {
        H.ReportError("%s", error);
      }
    }

    // Due to ReadVMAnnotations(), the klass may have been loaded at this point
    // (loading the class while evaluating annotations).
    if (klass.is_loaded()) {
      return;
    }

    klass.SetFields(Array::Handle(Z, MakeFieldsArray()));
  }

  class_helper->ReadUntilExcluding(ClassHelper::kConstructors);
  int constructor_count = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < constructor_count; ++i) {
    intptr_t constructor_offset = helper_.ReaderOffset() - correction_offset_;
    ActiveMemberScope active_member_scope(&active_class_, nullptr);
    ConstructorHelper constructor_helper(&helper_);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kAnnotations);
    intptr_t annotation_count = helper_.ReadListLength();
    bool has_pragma_annotation;
    bool is_invisible_function;
    ReadVMAnnotations(library, annotation_count, /*native_name=*/nullptr,
                      &is_invisible_function, /*isolate_unsendable=*/nullptr,
                      &has_pragma_annotation);
    constructor_helper.SetJustRead(ConstructorHelper::kAnnotations);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kFunction);

    const String& name =
        H.DartConstructorName(constructor_helper.canonical_name_);

    // We can have synthetic constructors, which will not have a source uri
    // attached to them (which means the index into the source uri table is 0,
    // see `package:kernel/binary/ast_to_binary::writeUriReference`.
    const Object* owner = &klass;
    const intptr_t source_uri_index = constructor_helper.source_uri_index_;
    if (source_uri_index != 0) {
      owner = &ClassForScriptAt(klass, source_uri_index);
    }

    FunctionType& signature = FunctionType::Handle(Z, FunctionType::New());
    const Function& function = Function::ZoneHandle(
        Z, Function::New(signature, name, UntaggedFunction::kConstructor,
                         false,  // is_static
                         constructor_helper.IsConst(),
                         false,  // is_abstract
                         constructor_helper.IsExternal(),
                         false,  // is_native
                         *owner, constructor_helper.start_position_));
    function.set_end_token_pos(constructor_helper.end_position_);
    function.set_kernel_offset(constructor_offset);
    signature.set_result_type(T.ReceiverType(klass));
    function.set_has_pragma(has_pragma_annotation);
    function.set_is_visible(!is_invisible_function);

    FunctionNodeHelper function_node_helper(&helper_);
    function_node_helper.ReadUntilExcluding(
        FunctionNodeHelper::kTypeParameters);
    T.SetupFunctionParameters(klass, function,
                              true,   // is_method
                              false,  // is_closure
                              &function_node_helper);
    T.SetupUnboxingInfoMetadata(function, library_kernel_offset_);

    if (library.is_dart_scheme() &&
        H.IsPrivate(constructor_helper.canonical_name_)) {
      function.set_is_reflectable(false);
    }

    if (constructor_helper.IsSynthetic()) {
      function.set_is_debuggable(false);
    }

    function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);
    constructor_helper.SetJustRead(ConstructorHelper::kFunction);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kEnd);

    if (klass.is_finalized()) {
      // The owner class has already been marked as finalized (e.g. class
      // 'NativeFieldWrapperClass1'), so the signature of this added constructor
      // must be finalized here, since finalization of member types will not be
      // called anymore.
      signature ^= ClassFinalizer::FinalizeType(signature);
      function.SetSignature(signature);
    }
    functions_.Add(&function);

    if ((FLAG_enable_mirrors || has_pragma_annotation) &&
        annotation_count > 0) {
      library.AddMetadata(function, constructor_offset);
    }
  }

  // Due to ReadVMAnnotations(), the klass may have been loaded at this point
  // (loading the class while evaluating annotations).
  if (klass.is_loaded()) {
    return;
  }

  // Everything up til the procedures are skipped implicitly, and class_helper
  // is no longer used.

  intptr_t procedure_count = class_index.procedure_count();
  // Procedure offsets within a class index are whole program offsets and not
  // relative to the library of the class. Hence, we need a correction to get
  // the currect procedure offset within the current data.
  intptr_t correction = correction_offset_ - library_kernel_offset_;
  intptr_t next_procedure_offset = class_index.ProcedureOffset(0) + correction;
  for (intptr_t i = 0; i < procedure_count; ++i) {
    helper_.SetOffset(next_procedure_offset);
    next_procedure_offset = class_index.ProcedureOffset(i + 1) + correction;
    LoadProcedure(library, klass, true, next_procedure_offset);
    // LoadProcedure calls Library::GetMetadata which invokes Dart code
    // which may recursively trigger class finalization and FinishClassLoading.
    // In such case, return immediately and avoid overwriting already finalized
    // functions with freshly loaded and not yet finalized.
    if (klass.is_loaded()) {
      return;
    }
  }

  klass.SetFunctions(Array::Handle(MakeFunctionsArray()));

  ASSERT(!klass.is_loaded());
  klass.set_is_loaded(true);
}

void KernelLoader::FinishLoading(const Class& klass) {
  ASSERT(klass.IsTopLevel() || (klass.kernel_offset() > 0));

  Zone* zone = Thread::Current()->zone();
  const Script& script = Script::Handle(zone, klass.script());
  const Library& library = Library::Handle(zone, klass.library());
  const Class& toplevel_class = Class::Handle(zone, library.toplevel_class());
  const ExternalTypedData& library_kernel_data =
      ExternalTypedData::Handle(zone, library.kernel_data());
  ASSERT(!library_kernel_data.IsNull());
  const intptr_t library_kernel_offset = library.kernel_offset();
  ASSERT(library_kernel_offset > 0);

  KernelLoader kernel_loader(script, library_kernel_data,
                             library_kernel_offset);
  LibraryIndex library_index(library_kernel_data);

  if (klass.IsTopLevel()) {
    ASSERT(klass.ptr() == toplevel_class.ptr());
    kernel_loader.FinishTopLevelClassLoading(klass, library, library_index);
    return;
  }

  const intptr_t class_offset = klass.kernel_offset();
  ClassIndex class_index(
      library_kernel_data, class_offset,
      // Class offsets in library index are whole program offsets.
      // Hence, we need to add |library_kernel_offset| to
      // |class_offset| to lookup the entry for the class in the library
      // index.
      library_index.SizeOfClassAtOffset(class_offset + library_kernel_offset));

  kernel_loader.helper_.SetOffset(class_offset);
  ClassHelper class_helper(&kernel_loader.helper_);

  kernel_loader.FinishClassLoading(klass, library, toplevel_class, class_offset,
                                   class_index, &class_helper);
}

// Read annotations on a procedure or a class to identify potential VM-specific
// directives.
//
// Output parameters:
//
//   `is_invisible_function`: if `@pragma('vm:invisible)` was found.
//
//   `native_name`: set if @pragma('vm:external-name)` was identified.
//
//   `has_pragma_annotation`: if `@pragma(...)` was found (no information
//   is given on the kind of pragma directive).
//
void KernelLoader::ReadVMAnnotations(const Library& library,
                                     intptr_t annotation_count,
                                     String* native_name,
                                     bool* is_invisible_function,
                                     bool* is_isolate_unsendable,
                                     bool* has_pragma_annotation) {
  if (is_invisible_function != nullptr) {
    *is_invisible_function = false;
  }
  *has_pragma_annotation = false;
  if (annotation_count == 0) {
    return;
  }

  for (intptr_t i = 0; i < annotation_count; ++i) {
    const intptr_t tag = helper_.PeekTag();
    if (tag == kConstantExpression) {
      helper_.ReadByte();      // Skip the tag.
      helper_.ReadPosition();  // Skip fileOffset.
      helper_.SkipDartType();  // Skip type.
      const intptr_t index_in_constant_table = helper_.ReadUInt();

      // Prepare lazy constant reading.
      ConstantReader constant_reader(&helper_, &active_class_);

      intptr_t name_index = -1;
      intptr_t options_index = -1;
      if (constant_reader.IsPragmaInstanceConstant(
              index_in_constant_table, &name_index, &options_index)) {
        *has_pragma_annotation = true;

        if (is_invisible_function != nullptr) {
          if (constant_reader.IsStringConstant(name_index, "vm:invisible")) {
            *is_invisible_function = true;
          }
        }
        if (native_name != nullptr) {
          if (constant_reader.IsStringConstant(name_index,
                                               "vm:external-name")) {
            constant_reader.GetStringConstant(options_index, native_name);
          }
        }
        if (is_isolate_unsendable != nullptr) {
          if (constant_reader.IsStringConstant(name_index,
                                               "vm:isolate-unsendable")) {
            *is_isolate_unsendable = true;
          }
        }
      }
    } else {
      helper_.SkipExpression();
      continue;
    }
  }
}

void KernelLoader::LoadProcedure(const Library& library,
                                 const Class& owner,
                                 bool in_class,
                                 intptr_t procedure_end) {
  intptr_t procedure_offset = helper_.ReaderOffset() - correction_offset_;
  ProcedureHelper procedure_helper(&helper_);

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kAnnotations);
  // CFE adds 'member signature' abstract functions to a legacy class deriving
  // or implementing an opted-in interface. The signature of these functions is
  // legacy erased and used as the target of interface calls. They are used for
  // static reasoning about the program by CFE, but not really needed by the VM.
  // In certain situations (e.g. issue 162073826), a large number of these
  // additional functions can cause strain on the VM. They are therefore skipped
  // in jit mode and their associated origin function is used instead as
  // interface call target.
  if (!FLAG_precompiled_mode && procedure_helper.IsMemberSignature()) {
    helper_.SetOffset(procedure_end);
    return;
  }
  const String& name = H.DartProcedureName(procedure_helper.canonical_name_);
  bool is_method = in_class && !procedure_helper.IsStatic();
  bool is_abstract = procedure_helper.IsAbstract();
  bool is_external = procedure_helper.IsExternal();
  bool is_extension_member = procedure_helper.IsExtensionMember();
  bool is_synthetic = procedure_helper.IsSynthetic();
  String& native_name = String::Handle(Z);
  bool has_pragma_annotation;
  bool is_invisible_function;
  const intptr_t annotation_count = helper_.ReadListLength();
  ReadVMAnnotations(library, annotation_count, &native_name,
                    &is_invisible_function, /*isolate_unsendable=*/nullptr,
                    &has_pragma_annotation);
  is_external = is_external && native_name.IsNull();
  procedure_helper.SetJustRead(ProcedureHelper::kAnnotations);
  const Object& script_class =
      ClassForScriptAt(owner, procedure_helper.source_uri_index_);
  UntaggedFunction::Kind kind = GetFunctionType(procedure_helper.kind_);

  // We do not register expression evaluation libraries with the VM:
  // The expression evaluation functions should be GC-able as soon as
  // they are not reachable anymore and we never look them up by name.
  const bool register_function = !name.Equals(Symbols::DebugProcedureName());

  const FunctionType& signature = FunctionType::Handle(Z, FunctionType::New());
  const Function& function = Function::ZoneHandle(
      Z, Function::New(signature, name, kind,
                       !is_method,  // is_static
                       false,       // is_const
                       is_abstract, is_external,
                       !native_name.IsNull(),  // is_native
                       script_class, procedure_helper.start_position_));
  function.set_has_pragma(has_pragma_annotation);
  function.set_end_token_pos(procedure_helper.end_position_);
  function.set_is_synthetic(procedure_helper.IsNoSuchMethodForwarder() ||
                            procedure_helper.IsMemberSignature() ||
                            is_synthetic);
  function.set_is_visible(!is_invisible_function);
  if (register_function) {
    functions_.Add(&function);
  } else {
    H.SetExpressionEvaluationFunction(function);
  }
  function.set_kernel_offset(procedure_offset);
  function.set_is_extension_member(is_extension_member);
  if ((library.is_dart_scheme() &&
       H.IsPrivate(procedure_helper.canonical_name_)) ||
      (function.is_static() && (library.ptr() == Library::InternalLibrary()))) {
    function.set_is_reflectable(false);
  }
  if (procedure_helper.IsMemberSignature()) {
    function.set_is_reflectable(false);
  }

  ActiveMemberScope active_member(&active_class_, &function);

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);

  FunctionNodeHelper function_node_helper(&helper_);
  function_node_helper.ReadUntilIncluding(FunctionNodeHelper::kDartAsyncMarker);
  if (function_node_helper.async_marker_ == FunctionNodeHelper::kAsync) {
    function.set_modifier(UntaggedFunction::kAsync);
    function.set_is_inlinable(false);
    ASSERT(function.IsAsyncFunction());
  } else if (function_node_helper.async_marker_ ==
             FunctionNodeHelper::kAsyncStar) {
    function.set_modifier(UntaggedFunction::kAsyncGen);
    function.set_is_inlinable(false);
    ASSERT(function.IsAsyncGenerator());
  } else if (function_node_helper.async_marker_ ==
             FunctionNodeHelper::kSyncStar) {
    function.set_modifier(UntaggedFunction::kSyncGen);
    function.set_is_inlinable(false);
    ASSERT(function.IsSyncGenerator());
  } else {
    ASSERT(function_node_helper.async_marker_ == FunctionNodeHelper::kSync);
    ASSERT(!function.IsAsyncFunction());
    ASSERT(!function.IsAsyncGenerator());
    ASSERT(!function.IsSyncGenerator());
  }

  if (!native_name.IsNull()) {
    function.set_native_name(native_name);
  }

  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  T.SetupFunctionParameters(owner, function, is_method,
                            false,  // is_closure
                            &function_node_helper);
  T.SetupUnboxingInfoMetadata(function, library_kernel_offset_);

  function_node_helper.ReadUntilExcluding(
      FunctionNodeHelper::kRedirectingFactoryTarget);
  function.set_is_redirecting_factory(helper_.ReadTag() == kSomething);

  // Everything else is skipped implicitly, and procedure_helper and
  // function_node_helper are no longer used.
  helper_.SetOffset(procedure_end);

  if (annotation_count > 0) {
    library.AddMetadata(function, procedure_offset);
  }
}

const Object& KernelLoader::ClassForScriptAt(const Class& klass,
                                             intptr_t source_uri_index) {
  const Script& correct_script = Script::Handle(Z, ScriptAt(source_uri_index));
  if (klass.script() != correct_script.ptr()) {
    // Lazily create the [patch_classes_] array in case we need it.
    if (patch_classes_.IsNull()) {
      const Array& scripts = Array::Handle(Z, kernel_program_info_.scripts());
      ASSERT(!scripts.IsNull());
      patch_classes_ = Array::New(scripts.Length(), Heap::kOld);
    }

    // Use cache for patch classes. This works best for in-order usages.
    PatchClass& patch_class = PatchClass::ZoneHandle(Z);
    patch_class ^= patch_classes_.At(source_uri_index);
    if (patch_class.IsNull() || patch_class.origin_class() != klass.ptr()) {
      ASSERT(!library_kernel_data_.IsNull());
      patch_class = PatchClass::New(klass, correct_script);
      patch_class.set_library_kernel_data(library_kernel_data_);
      patch_class.set_library_kernel_offset(library_kernel_offset_);
      patch_classes_.SetAt(source_uri_index, patch_class);
    }
    return patch_class;
  }
  return klass;
}

ScriptPtr KernelLoader::LoadScriptAt(intptr_t index,
                                     UriToSourceTable* uri_to_source_table) {
  const String& uri_string = helper_.SourceTableUriFor(index);
  const String& import_uri_string = helper_.SourceTableImportUriFor(index);
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  ExternalTypedData& constant_coverage =
      ExternalTypedData::Handle(Z, helper_.GetConstantCoverageFor(index));
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  String& sources = String::Handle(Z);
  TypedData& line_starts = TypedData::Handle(Z);

  if (uri_to_source_table != nullptr) {
    UriToSourceTableEntry wrapper;
    wrapper.uri = &uri_string;
    UriToSourceTableEntry* pair = uri_to_source_table->LookupValue(&wrapper);
    if (pair != nullptr) {
      sources = pair->sources->ptr();
      line_starts = pair->line_starts->ptr();
    }
  }

  if (sources.IsNull() || line_starts.IsNull()) {
    const String& script_source = helper_.GetSourceFor(index);
    line_starts = helper_.GetLineStartsFor(index);

    if (script_source.ptr() == Symbols::Empty().ptr() &&
        line_starts.Length() == 0 && uri_string.Length() > 0) {
      // Entry included only to provide URI - actual source should already exist
      // in the VM, so try to find it.
      Library& lib = Library::Handle(Z);
      Script& script = Script::Handle(Z);
      const GrowableObjectArray& libs =
          GrowableObjectArray::Handle(IG->object_store()->libraries());
      for (intptr_t i = 0; i < libs.Length(); i++) {
        lib ^= libs.At(i);
        script = lib.LookupScript(uri_string, /* useResolvedUri = */ true);
        if (!script.IsNull()) {
          sources = script.Source();
          line_starts = script.line_starts();
          break;
        }
      }
    } else {
      sources = script_source.ptr();
    }
  }

  const Script& script =
      Script::Handle(Z, Script::New(import_uri_string, uri_string, sources));
  script.set_kernel_script_index(index);
  script.set_kernel_program_info(kernel_program_info_);
  script.set_line_starts(line_starts);
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  script.set_constant_coverage(constant_coverage);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  script.set_debug_positions(Array::null_array());
  return script.ptr();
}

ObjectPtr KernelLoader::ReadInitialFieldValue(const Field& field,
                                              FieldHelper* field_helper) {
  const Tag tag = helper_.PeekTag();
  const bool has_initializer = (tag == kSomething);

  if (has_initializer) {
    SimpleExpressionConverter converter(&H, &helper_);
    const bool has_simple_initializer =
        converter.IsSimple(helper_.ReaderOffset() + 1);  // ignore the tag.
    if (has_simple_initializer) {
      if (field_helper->IsStatic()) {
        return converter.SimpleValue().ptr();
      } else {
        field.RecordStore(converter.SimpleValue());
      }
    }
  }

  if (field_helper->IsStatic()) {
    if (!has_initializer && !field_helper->IsLate()) {
      // Static fields without an initializer are implicitly initialized to
      // null.
      return Instance::null();
    }
  }
  ASSERT(field.NeedsGetter());

  // If static, we do need a getter that evaluates the initializer if necessary.
  return field_helper->IsStatic() ? Object::sentinel().ptr() : Object::null();
}

void KernelLoader::GenerateFieldAccessors(const Class& klass,
                                          const Field& field,
                                          FieldHelper* field_helper) {
  const bool needs_getter = field.NeedsGetter();
  const bool needs_setter = field.NeedsSetter();

  if (!needs_getter && !needs_setter) {
    return;
  }

  const Object& script_class =
      ClassForScriptAt(klass, field_helper->source_uri_index_);
  const AbstractType& field_type = AbstractType::Handle(Z, field.type());

  if (needs_getter) {
    const String& getter_name =
        H.DartGetterName(field_helper->canonical_name_getter_);
    const FunctionType& signature =
        FunctionType::Handle(Z, FunctionType::New());
    Function& getter = Function::ZoneHandle(
        Z,
        Function::New(
            signature, getter_name,
            field_helper->IsStatic() ? UntaggedFunction::kImplicitStaticGetter
                                     : UntaggedFunction::kImplicitGetter,
            field_helper->IsStatic(),
            // The functions created by the parser have is_const for static
            // fields that are const (not just final) and they have is_const
            // for non-static fields that are final.
            field_helper->IsStatic() ? field_helper->IsConst()
                                     : field_helper->IsFinal(),
            false,  // is_abstract
            false,  // is_external
            false,  // is_native
            script_class, field_helper->position_));
    functions_.Add(&getter);
    getter.set_end_token_pos(field_helper->end_position_);
    getter.set_kernel_offset(field.kernel_offset());
    signature.set_result_type(field_type);
    getter.set_is_debuggable(false);
    getter.set_accessor_field(field);
    getter.set_is_extension_member(field.is_extension_member());
    H.SetupFieldAccessorFunction(klass, getter, field_type);
    T.SetupUnboxingInfoMetadataForFieldAccessors(getter,
                                                 library_kernel_offset_);
  }

  if (needs_setter) {
    // Only static fields can be const.
    ASSERT(!field_helper->IsConst());
    const String& setter_name =
        H.DartSetterName(field_helper->canonical_name_setter_);
    const FunctionType& signature =
        FunctionType::Handle(Z, FunctionType::New());
    Function& setter = Function::ZoneHandle(
        Z,
        Function::New(signature, setter_name, UntaggedFunction::kImplicitSetter,
                      field_helper->IsStatic(),
                      false,  // is_const
                      false,  // is_abstract
                      false,  // is_external
                      false,  // is_native
                      script_class, field_helper->position_));
    functions_.Add(&setter);
    setter.set_end_token_pos(field_helper->end_position_);
    setter.set_kernel_offset(field.kernel_offset());
    signature.set_result_type(Object::void_type());
    setter.set_is_debuggable(false);
    setter.set_accessor_field(field);
    setter.set_is_extension_member(field.is_extension_member());
    H.SetupFieldAccessorFunction(klass, setter, field_type);
    T.SetupUnboxingInfoMetadataForFieldAccessors(setter,
                                                 library_kernel_offset_);
  }
}

LibraryPtr KernelLoader::LookupLibraryOrNull(NameIndex library) {
  LibraryPtr result;
  name_index_handle_ = Smi::New(library);
  {
    result = kernel_program_info_.LookupLibrary(thread_, name_index_handle_);
    NoSafepointScope no_safepoint_scope(thread_);
    if (result != Library::null()) {
      return result;
    }
  }
  const String& url = H.DartString(H.CanonicalNameString(library));
  {
    result = Library::LookupLibrary(thread_, url);
    NoSafepointScope no_safepoint_scope(thread_);
    if (result == Library::null()) {
      return result;
    }
  }
  const Library& handle = Library::Handle(Z, result);
  name_index_handle_ = Smi::New(library);
  return kernel_program_info_.InsertLibrary(thread_, name_index_handle_,
                                            handle);
}

LibraryPtr KernelLoader::LookupLibrary(NameIndex library) {
  name_index_handle_ = Smi::New(library);
  {
    LibraryPtr result =
        kernel_program_info_.LookupLibrary(thread_, name_index_handle_);
    NoSafepointScope no_safepoint_scope(thread_);
    if (result != Library::null()) {
      return result;
    }
  }

  Library& handle = Library::Handle(Z);
  const String& url = H.DartSymbolPlain(H.CanonicalNameString(library));
  // We do not register expression evaluation libraries with the VM:
  // The expression evaluation functions should be GC-able as soon as
  // they are not reachable anymore and we never look them up by name.
  if (url.Equals(Symbols::EvalSourceUri())) {
    if (expression_evaluation_library_.IsNull()) {
      handle = Library::New(url);
      expression_evaluation_library_ = handle.ptr();
    }
    return expression_evaluation_library_.ptr();
  }
  handle = Library::LookupLibrary(thread_, url);
  if (handle.IsNull()) {
    handle = Library::New(url);
    handle.Register(thread_);
  }
  ASSERT(!handle.IsNull());
  name_index_handle_ = Smi::New(library);
  return kernel_program_info_.InsertLibrary(thread_, name_index_handle_,
                                            handle);
}

LibraryPtr KernelLoader::LookupLibraryFromClass(NameIndex klass) {
  return LookupLibrary(H.CanonicalNameParent(klass));
}

ClassPtr KernelLoader::LookupClass(const Library& library, NameIndex klass) {
  name_index_handle_ = Smi::New(klass);
  {
    ClassPtr raw_class =
        kernel_program_info_.LookupClass(thread_, name_index_handle_);
    NoSafepointScope no_safepoint_scope(thread_);
    if (raw_class != Class::null()) {
      return raw_class;
    }
  }

  ASSERT(!library.IsNull());
  const String& name = H.DartClassName(klass);
  Class& handle = Class::Handle(Z, library.LookupLocalClass(name));
  bool register_class = true;
  if (handle.IsNull()) {
    // We do not register expression evaluation classes with the VM:
    // The expression evaluation functions should be GC-able as soon as
    // they are not reachable anymore and we never look them up by name.
    register_class = library.ptr() != expression_evaluation_library_.ptr();

    handle = Class::New(library, name, Script::Handle(Z),
                        TokenPosition::kNoSource, register_class);
    if (register_class) {
      library.AddClass(handle);
    }
  }
  ASSERT(!handle.IsNull());
  if (register_class) {
    name_index_handle_ = Smi::New(klass);
    kernel_program_info_.InsertClass(thread_, name_index_handle_, handle);
  }
  return handle.ptr();
}

UntaggedFunction::Kind KernelLoader::GetFunctionType(
    ProcedureHelper::Kind procedure_kind) {
  intptr_t lookuptable[] = {
      UntaggedFunction::kRegularFunction,  // Procedure::kMethod
      UntaggedFunction::kGetterFunction,   // Procedure::kGetter
      UntaggedFunction::kSetterFunction,   // Procedure::kSetter
      UntaggedFunction::kRegularFunction,  // Procedure::kOperator
      UntaggedFunction::kConstructor,      // Procedure::kFactory
  };
  intptr_t kind = static_cast<int>(procedure_kind);
  ASSERT(0 <= kind && kind <= ProcedureHelper::kFactory);
  return static_cast<UntaggedFunction::Kind>(lookuptable[kind]);
}

FunctionPtr CreateFieldInitializerFunction(Thread* thread,
                                           Zone* zone,
                                           const Field& field) {
  ASSERT(field.InitializerFunction() == Function::null());

  String& init_name = String::Handle(zone, field.name());
  init_name = Symbols::FromConcat(thread, Symbols::InitPrefix(), init_name);

  // Static field initializers are not added as members of their owning class,
  // so they must be preemptively given a patch class to avoid the meaning of
  // their kernel/token position changing during a reload. Compare
  // Class::PatchFieldsAndFunctions().
  // This might also be necessary for lazy computation of local var descriptors.
  // Compare https://codereview.chromium.org//1317753004
  const Script& script = Script::Handle(zone, field.Script());
  const Class& field_owner = Class::Handle(zone, field.Owner());
  const PatchClass& initializer_owner =
      PatchClass::Handle(zone, PatchClass::New(field_owner, script));
  const Library& lib = Library::Handle(zone, field_owner.library());
  initializer_owner.set_library_kernel_data(
      ExternalTypedData::Handle(zone, lib.kernel_data()));
  initializer_owner.set_library_kernel_offset(lib.kernel_offset());

  // Create a static initializer.
  FunctionType& signature = FunctionType::Handle(zone, FunctionType::New());
  const Function& initializer_fun = Function::Handle(
      zone,
      Function::New(signature, init_name, UntaggedFunction::kFieldInitializer,
                    field.is_static(),  // is_static
                    false,              // is_const
                    false,              // is_abstract
                    false,              // is_external
                    false,              // is_native
                    initializer_owner, TokenPosition::kNoSource));
  if (!field.is_static()) {
    signature.set_num_fixed_parameters(1);
    signature.set_parameter_types(
        Array::Handle(zone, Array::New(1, Heap::kOld)));
    signature.SetParameterTypeAt(
        0, AbstractType::Handle(zone, field_owner.DeclarationType()));
    initializer_fun.CreateNameArray();
    initializer_fun.SetParameterNameAt(0, Symbols::This());
  }
  signature.set_result_type(AbstractType::Handle(zone, field.type()));
  initializer_fun.set_is_reflectable(false);
  initializer_fun.set_is_inlinable(false);
  initializer_fun.set_token_pos(field.token_pos());
  initializer_fun.set_end_token_pos(field.end_token_pos());
  initializer_fun.set_accessor_field(field);
  initializer_fun.InheritKernelOffsetFrom(field);
  initializer_fun.set_is_extension_member(field.is_extension_member());

  signature ^= ClassFinalizer::FinalizeType(signature);
  initializer_fun.SetSignature(signature);

  field.SetInitializerFunction(initializer_fun);
  return initializer_fun.ptr();
}

}  // namespace kernel
}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
