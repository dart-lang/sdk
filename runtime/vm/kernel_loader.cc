// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_loader.h"

#include <string.h>

#include "vm/compiler/frontend/kernel_binary_flowgraph.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/kernel_binary.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/service_isolate.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {
namespace kernel {

#define Z (zone_)
#define I (isolate_)
#define T (builder_.type_translator_)
#define H (translation_helper_)

static const char* const kVMServiceIOLibraryUri = "dart:vmservice_io";

class SimpleExpressionConverter {
 public:
  SimpleExpressionConverter(TranslationHelper* helper,
                            StreamingFlowGraphBuilder* builder)
      : translation_helper_(*helper),
        zone_(translation_helper_.zone()),
        simple_value_(NULL),
        builder_(builder) {}

  bool IsSimple(intptr_t kernel_offset) {
    AlternativeReadingScope alt(builder_->reader_, kernel_offset);
    uint8_t payload = 0;
    Tag tag = builder_->ReadTag(&payload);  // read tag.
    switch (tag) {
      case kBigIntLiteral: {
        const String& literal_str =
            H.DartString(builder_->ReadStringReference(),
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
        simple_value_ = &H.DartSymbol(
            builder_->ReadStringReference());  // read index into string table.
        return true;
      case kSpecialIntLiteral:
        simple_value_ =
            &Integer::ZoneHandle(Z, Integer::New(static_cast<int32_t>(payload) -
                                                     SpecializedIntLiteralBias,
                                                 Heap::kOld));
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kNegativeIntLiteral:
        simple_value_ = &Integer::ZoneHandle(
            Z, Integer::New(-static_cast<int64_t>(builder_->ReadUInt()),
                            Heap::kOld));  // read value.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kPositiveIntLiteral:
        simple_value_ = &Integer::ZoneHandle(
            Z, Integer::New(static_cast<int64_t>(builder_->ReadUInt()),
                            Heap::kOld));  // read value.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kDoubleLiteral:
        simple_value_ = &Double::ZoneHandle(
            Z, Double::New(H.DartString(builder_->ReadStringReference()),
                           Heap::kOld));  // read string reference.
        *simple_value_ = H.Canonicalize(*simple_value_);
        return true;
      case kTrueLiteral:
        simple_value_ = &Bool::Handle(Z, Bool::Get(true).raw());
        return true;
      case kFalseLiteral:
        simple_value_ = &Bool::Handle(Z, Bool::Get(false).raw());
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
  StreamingFlowGraphBuilder* builder_;
};

RawArray* KernelLoader::MakeFunctionsArray() {
  const intptr_t len = functions_.length();
  const Array& res = Array::Handle(zone_, Array::New(len, Heap::kOld));
  for (intptr_t i = 0; i < len; i++) {
    res.SetAt(i, *functions_[i]);
  }
  return res.raw();
}

RawLibrary* BuildingTranslationHelper::LookupLibraryByKernelLibrary(
    NameIndex library) {
  return loader_->LookupLibrary(library).raw();
}

RawClass* BuildingTranslationHelper::LookupClassByKernelClass(NameIndex klass) {
  return loader_->LookupClass(klass).raw();
}

LibraryIndex::LibraryIndex(const TypedData& kernel_data)
    : reader_(kernel_data) {
  intptr_t data_size = reader_.size();

  procedure_count_ = reader_.ReadUInt32At(data_size - 4);
  procedure_index_offset_ = data_size - 4 - (procedure_count_ + 1) * 4;

  class_count_ = reader_.ReadUInt32At(procedure_index_offset_ - 4);
  class_index_offset_ = procedure_index_offset_ - 4 - (class_count_ + 1) * 4;
}

ClassIndex::ClassIndex(const uint8_t* buffer,
                       intptr_t buffer_size,
                       intptr_t class_offset,
                       intptr_t class_size)
    : reader_(buffer, buffer_size) {
  Init(class_offset, class_size);
}

ClassIndex::ClassIndex(const TypedData& library_kernel_data,
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

KernelLoader::KernelLoader(Program* program)
    : program_(program),
      thread_(Thread::Current()),
      zone_(thread_->zone()),
      isolate_(thread_->isolate()),
      is_service_isolate_(ServiceIsolate::NameEquals(I->name())),
      patch_classes_(Array::ZoneHandle(zone_)),
      library_kernel_offset_(-1),  // Set to the correct value in LoadLibrary
      correction_offset_(-1),      // Set to the correct value in LoadLibrary
      loading_native_wrappers_library_(false),
      library_kernel_data_(TypedData::ZoneHandle(zone_)),
      kernel_program_info_(KernelProgramInfo::ZoneHandle(zone_)),
      translation_helper_(this, thread_),
      builder_(&translation_helper_,
               zone_,
               program_->kernel_data(),
               program_->kernel_data_size(),
               0) {
  if (!program->is_single_program()) {
    FATAL(
        "Trying to load a concatenated dill file at a time where that is "
        "not allowed");
  }
  T.active_class_ = &active_class_;
  T.finalize_ = false;

  initialize_fields();
}

Object& KernelLoader::LoadEntireProgram(Program* program) {
  if (program->is_single_program()) {
    KernelLoader loader(program);
    return loader.LoadProgram();
  } else {
    kernel::Reader reader(program->kernel_data(), program->kernel_data_size());
    GrowableArray<intptr_t> subprogram_file_starts;
    index_programs(&reader, &subprogram_file_starts);

    Thread* thread = Thread::Current();
    Zone* zone = thread->zone();
    Library& library = Library::Handle(zone);
    // Create "fake programs" for each sub-program.
    intptr_t subprogram_count = subprogram_file_starts.length() - 1;
    for (intptr_t i = 0; i < subprogram_count; ++i) {
      intptr_t subprogram_start = subprogram_file_starts.At(i);
      intptr_t subprogram_end = subprogram_file_starts.At(i + 1);
      reader.set_raw_buffer(program->kernel_data() + subprogram_start);
      reader.set_size(subprogram_end - subprogram_start);
      reader.set_offset(0);
      Program* subprogram = Program::ReadFrom(&reader, false);
      ASSERT(subprogram->is_single_program());
      KernelLoader loader(subprogram);
      Object& load_result = loader.LoadProgram(false);
      if (load_result.IsError()) return load_result;

      if (library.IsNull() && load_result.IsLibrary()) {
        library ^= load_result.raw();
      }

      delete subprogram;
    }

    if (!ClassFinalizer::ProcessPendingClasses()) {
      // Class finalization failed -> sticky error would be set.
      Error& error = Error::Handle(zone);
      error = thread->sticky_error();
      thread->clear_sticky_error();
      return error;
    }

    return library;
  }
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

void KernelLoader::initialize_fields() {
  const intptr_t source_table_size = builder_.SourceTableSize();
  const Array& scripts =
      Array::Handle(Z, Array::New(source_table_size, Heap::kOld));
  patch_classes_ = Array::New(source_table_size, Heap::kOld);

  // Copy the Kernel string offsets out of the binary and into the VM's heap.
  ASSERT(program_->string_table_offset() >= 0);
  Reader reader(program_->kernel_data(), program_->kernel_data_size());
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

  // Copy the string data out of the binary and into the VM's heap.
  TypedData& data = TypedData::Handle(
      Z, TypedData::New(kTypedDataUint8ArrayCid, end_offset, Heap::kOld));
  reader.CopyDataToVMHeap(data, reader.offset(), end_offset);

  // Copy the canonical names into the VM's heap.  Encode them as unsigned, so
  // the parent indexes are adjusted when extracted.
  reader.set_offset(program_->name_table_offset());
  count = reader.ReadUInt() * 2;
  TypedData& names = TypedData::Handle(
      Z, TypedData::New(kTypedDataUint32ArrayCid, count, Heap::kOld));
  for (intptr_t i = 0; i < count; ++i) {
    names.SetUint32(i << 2, reader.ReadUInt());
  }

  // Metadata mappings immediately follow names table.
  const intptr_t metadata_mappings_start = reader.offset();

  // Copy metadata payloads into the VM's heap
  // TODO(alexmarkov): add more info to program index instead of guessing
  // the end of metadata payloads by offsets of the libraries.
  intptr_t metadata_payloads_end = program_->source_table_offset();
  for (intptr_t i = 0; i < program_->library_count(); ++i) {
    metadata_payloads_end =
        Utils::Minimum(metadata_payloads_end, library_offset(i));
  }
  ASSERT(metadata_payloads_end >= MetadataPayloadOffset);
  const intptr_t metadata_payloads_size =
      metadata_payloads_end - MetadataPayloadOffset;
  TypedData& metadata_payloads =
      TypedData::Handle(Z, TypedData::New(kTypedDataUint8ArrayCid,
                                          metadata_payloads_size, Heap::kOld));
  reader.CopyDataToVMHeap(metadata_payloads, MetadataPayloadOffset,
                          metadata_payloads_size);

  // Copy metadata mappings into the VM's heap
  const intptr_t metadata_mappings_size =
      program_->string_table_offset() - metadata_mappings_start;
  TypedData& metadata_mappings =
      TypedData::Handle(Z, TypedData::New(kTypedDataUint8ArrayCid,
                                          metadata_mappings_size, Heap::kOld));
  reader.CopyDataToVMHeap(metadata_mappings, metadata_mappings_start,
                          metadata_mappings_size);

  kernel_program_info_ = KernelProgramInfo::New(
      offsets, data, names, metadata_payloads, metadata_mappings, scripts);

  H.InitFromKernelProgramInfo(kernel_program_info_);

  Script& script = Script::Handle(Z);
  for (intptr_t index = 0; index < source_table_size; ++index) {
    script = LoadScriptAt(index);
    scripts.SetAt(index, script);
  }
}

KernelLoader::KernelLoader(const Script& script,
                           const TypedData& kernel_data,
                           intptr_t data_program_offset)
    : program_(NULL),
      thread_(Thread::Current()),
      zone_(thread_->zone()),
      isolate_(thread_->isolate()),
      patch_classes_(Array::ZoneHandle(zone_)),
      library_kernel_offset_(data_program_offset),
      correction_offset_(0),
      loading_native_wrappers_library_(false),
      library_kernel_data_(TypedData::ZoneHandle(zone_)),
      kernel_program_info_(
          KernelProgramInfo::ZoneHandle(zone_, script.kernel_program_info())),
      translation_helper_(this, thread_),
      builder_(&translation_helper_, script.raw(), zone_, kernel_data, 0) {
  T.active_class_ = &active_class_;
  T.finalize_ = false;

  const Array& scripts = Array::Handle(Z, kernel_program_info_.scripts());
  patch_classes_ = Array::New(scripts.Length(), Heap::kOld);
  library_kernel_data_ = kernel_data.raw();

  H.InitFromKernelProgramInfo(kernel_program_info_);
}

Object& KernelLoader::LoadProgram(bool process_pending_classes) {
  if (!program_->is_single_program()) {
    FATAL(
        "Trying to load a concatenated dill file at a time where that is "
        "not allowed");
  }

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    intptr_t length = program_->library_count();
    for (intptr_t i = 0; i < length; i++) {
      LoadLibrary(i);
    }

    if (process_pending_classes && ClassFinalizer::ProcessPendingClasses()) {
      // If 'main' is not found return a null library, this is the case
      // when bootstrapping is in progress.
      NameIndex main = program_->main_method();
      if (main == -1) {
        return Library::Handle(Z);
      }

      NameIndex main_library = H.EnclosingName(main);
      Library& library = LookupLibrary(main_library);
      return library;
    } else if (!process_pending_classes) {
      NameIndex main = program_->main_method();
      if (main == -1) {
        return Library::Handle(Z);
      }

      NameIndex main_library = H.EnclosingName(main);
      Library& library = LookupLibrary(main_library);
      return library;
    }
  }

  // Either class finalization failed or we caught a compile error.
  // In both cases sticky error would be set.
  Error& error = Error::Handle(Z);
  error = thread_->sticky_error();
  thread_->clear_sticky_error();
  return error;
}

void KernelLoader::FindModifiedLibraries(Program* program,
                                         Isolate* isolate,
                                         BitVector* modified_libs,
                                         bool force_reload) {
  LongJumpScope jump;
  Zone* zone = Thread::Current()->zone();
  if (setjmp(*jump.Set()) == 0) {
    if (force_reload) {
      // If a reload is being forced we mark all libraries as having
      // been modified.
      const GrowableObjectArray& libs =
          GrowableObjectArray::Handle(isolate->object_store()->libraries());
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

    // Now go through all the libraries that are present in the incremental
    // kernel files, these will constitute the modified libraries.
    if (program->is_single_program()) {
      KernelLoader loader(program);
      return loader.walk_incremental_kernel(modified_libs);
    } else {
      kernel::Reader reader(program->kernel_data(),
                            program->kernel_data_size());
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
        Program* subprogram = Program::ReadFrom(&reader, false);
        ASSERT(subprogram->is_single_program());
        KernelLoader loader(subprogram);
        loader.walk_incremental_kernel(modified_libs);
        delete subprogram;
      }
    }
  }
}

void KernelLoader::walk_incremental_kernel(BitVector* modified_libs) {
  intptr_t length = program_->library_count();
  for (intptr_t i = 0; i < length; i++) {
    intptr_t kernel_offset = library_offset(i);
    builder_.SetOffset(kernel_offset);
    LibraryHelper library_helper(&builder_);
    library_helper.ReadUntilIncluding(LibraryHelper::kCanonicalName);
    dart::Library& lib = LookupLibrary(library_helper.canonical_name_);
    if (!lib.IsNull() && !lib.is_dart_scheme()) {
      // This is a library that already exists so mark it as being modified.
      modified_libs->Add(lib.index());
    }
  }
}

void KernelLoader::LoadLibrary(intptr_t index) {
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

  // NOTE: Since |builder_| is used to load the overall kernel program,
  // it's reader's offset is an offset into the overall kernel program.
  // Hence, when setting the kernel offsets of field and functions, one
  // has to subtract the library's kernel offset from the reader's
  // offset.
  builder_.SetOffset(library_kernel_offset_);

  LibraryHelper library_helper(&builder_);
  library_helper.ReadUntilIncluding(LibraryHelper::kCanonicalName);
  if (!is_service_isolate_ && !FLAG_precompiled_mode) {
    StringIndex lib_name_index =
        H.CanonicalNameString(library_helper.canonical_name_);
    if (H.StringEquals(lib_name_index, kVMServiceIOLibraryUri)) {
      // We are not the service isolate and we are not generating an AOT
      // snapshot so we skip loading 'dart:vmservice_io'.
      return;
    }
  }

  Library& library = LookupLibrary(library_helper.canonical_name_);
  // The Kernel library is external implies that it is already loaded.
  ASSERT(!library_helper.IsExternal() || library.Loaded());
  if (library.Loaded()) return;

  library_kernel_data_ =
      TypedData::New(kTypedDataUint8ArrayCid, library_size, Heap::kOld);
  builder_.reader_->CopyDataToVMHeap(library_kernel_data_,
                                     library_kernel_offset_, library_size);
  library.set_kernel_data(library_kernel_data_);
  library.set_kernel_offset(library_kernel_offset_);

  LibraryIndex library_index(library_kernel_data_);
  intptr_t class_count = library_index.class_count();
  intptr_t procedure_count = library_index.procedure_count();

  library_helper.ReadUntilIncluding(LibraryHelper::kName);
  library.SetName(H.DartSymbol(library_helper.name_index_));

  // The bootstrapper will take care of creating the native wrapper classes, but
  // we will add the synthetic constructors to them here.
  if (library.name() ==
      Symbols::Symbol(Symbols::kDartNativeWrappersLibNameId).raw()) {
    ASSERT(library.LoadInProgress());
    loading_native_wrappers_library_ = true;
  } else {
    loading_native_wrappers_library_ = false;
    library.SetLoadInProgress();
  }
  StringIndex import_uri_index =
      H.CanonicalNameString(library_helper.canonical_name_);
  library_helper.ReadUntilIncluding(LibraryHelper::kSourceUriIndex);
  const Script& script = Script::Handle(
      Z, ScriptAt(library_helper.source_uri_index_, import_uri_index));

  library_helper.ReadUntilExcluding(LibraryHelper::kDependencies);
  LoadLibraryImportsAndExports(&library);
  library_helper.SetJustRead(LibraryHelper::kDependencies);

  // Setup toplevel class (which contains library fields/procedures).
  Class& toplevel_class =
      Class::Handle(Z, Class::New(library, Symbols::TopLevel(), script,
                                  TokenPosition::kNoSource));
  toplevel_class.set_is_cycle_free();
  library.set_toplevel_class(toplevel_class);

  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(Z, I->object_store()->pending_classes());

  // Everything up til the classes are skipped implicitly, and library_helper
  // is no longer used.

  // Load all classes.
  intptr_t next_class_offset = library_index.ClassOffset(0);
  for (intptr_t i = 0; i < class_count; ++i) {
    builder_.SetOffset(next_class_offset);
    next_class_offset = library_index.ClassOffset(i + 1);
    classes.Add(LoadClass(library, toplevel_class, next_class_offset),
                Heap::kOld);
  }
  builder_.SetOffset(next_class_offset);

  fields_.Clear();
  functions_.Clear();
  ActiveClassScope active_class_scope(&active_class_, &toplevel_class);
  // Load toplevel fields.
  intptr_t field_count = builder_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < field_count; ++i) {
    intptr_t field_offset = builder_.ReaderOffset() - correction_offset_;
    ActiveMemberScope active_member_scope(&active_class_, NULL);
    FieldHelper field_helper(&builder_);
    field_helper.ReadUntilExcluding(FieldHelper::kName);

    const String& name = builder_.ReadNameAsFieldName();
    field_helper.SetJustRead(FieldHelper::kName);
    field_helper.ReadUntilExcluding(FieldHelper::kType);
    const Object& script_class =
        ClassForScriptAt(toplevel_class, field_helper.source_uri_index_);
    // In the VM all const fields are implicitly final whereas in Kernel they
    // are not final because they are not explicitly declared that way.
    const bool is_final = field_helper.IsConst() || field_helper.IsFinal();
    Field& field = Field::Handle(
        Z,
        Field::NewTopLevel(name, is_final, field_helper.IsConst(), script_class,
                           field_helper.position_, field_helper.end_position_));
    field.set_kernel_offset(field_offset);
    const AbstractType& type = T.BuildType();  // read type.
    field.SetFieldType(type);
    field_helper.SetJustRead(FieldHelper::kType);
    field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
    intptr_t field_initializer_offset = builder_.ReaderOffset();
    field.set_has_initializer(builder_.PeekTag() == kSomething);
    field_helper.ReadUntilExcluding(FieldHelper::kEnd);
    {
      // GenerateFieldAccessors reads (some of) the initializer.
      AlternativeReadingScope alt(builder_.reader_, field_initializer_offset);
      GenerateFieldAccessors(toplevel_class, field, &field_helper);
    }
    if (FLAG_enable_mirrors && field_helper.annotation_count_ > 0) {
      library.AddFieldMetadata(field, TokenPosition::kNoSource, field_offset);
    }
    fields_.Add(&field);
    library.AddObject(field, name);
  }
  toplevel_class.AddFields(fields_);

  // Load toplevel procedures.
  intptr_t next_procedure_offset = library_index.ProcedureOffset(0);
  for (intptr_t i = 0; i < procedure_count; ++i) {
    builder_.SetOffset(next_procedure_offset);
    next_procedure_offset = library_index.ProcedureOffset(i + 1);
    LoadProcedure(library, toplevel_class, false, next_procedure_offset);
  }

  toplevel_class.SetFunctions(Array::Handle(MakeFunctionsArray()));
  classes.Add(toplevel_class, Heap::kOld);
  if (!library.Loaded()) library.SetLoaded();
}

void KernelLoader::LoadLibraryImportsAndExports(Library* library) {
  GrowableObjectArray& show_list = GrowableObjectArray::Handle(Z);
  GrowableObjectArray& hide_list = GrowableObjectArray::Handle(Z);
  Array& show_names = Array::Handle(Z);
  Array& hide_names = Array::Handle(Z);
  Namespace& ns = Namespace::Handle(Z);
  LibraryPrefix& library_prefix = LibraryPrefix::Handle(Z);

  const intptr_t deps_count = builder_.ReadListLength();
  for (intptr_t dep = 0; dep < deps_count; ++dep) {
    LibraryDependencyHelper dependency_helper(&builder_);
    dependency_helper.ReadUntilExcluding(LibraryDependencyHelper::kCombinators);

    // Ignore the dependency if the target library is invalid.
    // The error will be caught during compilation.
    if (dependency_helper.target_library_canonical_name_ < 0) {
      const intptr_t combinator_count = builder_.ReadListLength();
      for (intptr_t c = 0; c < combinator_count; ++c) {
        builder_.SkipLibraryCombinator();
      }
      continue;
    }

    // Prepare show and hide lists.
    show_list = GrowableObjectArray::New(Heap::kOld);
    hide_list = GrowableObjectArray::New(Heap::kOld);
    const intptr_t combinator_count = builder_.ReadListLength();
    for (intptr_t c = 0; c < combinator_count; ++c) {
      uint8_t flags = builder_.ReadFlags();
      intptr_t name_count = builder_.ReadListLength();
      for (intptr_t n = 0; n < name_count; ++n) {
        String& show_hide_name = H.DartSymbol(builder_.ReadStringReference());
        if (flags & LibraryDependencyHelper::Show) {
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

    Library& target_library =
        LookupLibrary(dependency_helper.target_library_canonical_name_);
    if (!FLAG_enable_mirrors &&
        target_library.url() == Symbols::DartMirrors().raw()) {
      H.ReportError("import of dart:mirrors with --enable-mirrors=false");
    }
    String& prefix = H.DartSymbol(dependency_helper.name_index_);
    ns = Namespace::New(target_library, show_names, hide_names);
    if (dependency_helper.flags_ & LibraryDependencyHelper::Export) {
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
              dependency_helper.flags_ & LibraryDependencyHelper::Deferred,
              *library);
          library->AddObject(library_prefix, prefix);
        }
      }
    }
  }
}

void KernelLoader::LoadPreliminaryClass(ClassHelper* class_helper,
                                        intptr_t type_parameter_count) {
  const Class* klass = active_class_.klass;
  // Note: This assumes that ClassHelper is exactly at the position where
  // the length of the type parameters have been read, and that the order in
  // the binary is as follows: [...], kTypeParameters, kSuperClass, kMixinType,
  // kImplementedClasses, [...].

  // Set type parameters.
  builder_.LoadAndSetupTypeParameters(
      &active_class_, *klass, type_parameter_count, Function::Handle(Z));

  // Set super type.  Some classes (e.g., Object) do not have one.
  Tag type_tag = builder_.ReadTag();  // read super class type (part 1).
  if (type_tag == kSomething) {
    AbstractType& super_type =
        T.BuildTypeWithoutFinalization();  // read super class type (part 2).
    if (super_type.IsMalformed()) H.ReportError("Malformed super type");
    klass->set_super_type(super_type);
  }

  class_helper->SetJustRead(ClassHelper::kSuperClass);
  class_helper->ReadUntilIncluding(ClassHelper::kMixinType);

  // Build implemented interface types
  intptr_t interface_count = builder_.ReadListLength();
  const Array& interfaces =
      Array::Handle(Z, Array::New(interface_count, Heap::kOld));
  for (intptr_t i = 0; i < interface_count; i++) {
    const AbstractType& type =
        T.BuildTypeWithoutFinalization();  // read ith type.
    if (type.IsMalformed()) H.ReportError("Malformed interface type.");
    interfaces.SetAt(i, type);
  }
  class_helper->SetJustRead(ClassHelper::kImplementedClasses);
  klass->set_interfaces(interfaces);

  if (class_helper->is_abstract_) klass->set_is_abstract();
}

Class& KernelLoader::LoadClass(const Library& library,
                               const Class& toplevel_class,
                               intptr_t class_end) {
  intptr_t class_offset = builder_.ReaderOffset();
  ClassIndex class_index(program_->kernel_data(), program_->kernel_data_size(),
                         class_offset, class_end - class_offset);

  ClassHelper class_helper(&builder_);
  class_helper.ReadUntilIncluding(ClassHelper::kCanonicalName);
  Class& klass = LookupClass(class_helper.canonical_name_);
  klass.set_kernel_offset(class_offset - correction_offset_);

  // The class needs to have a script because all the functions in the class
  // will inherit it.  The predicate Function::IsOptimizable uses the absence of
  // a script to detect test functions that should not be optimized.
  if (klass.script() == Script::null()) {
    class_helper.ReadUntilIncluding(ClassHelper::kSourceUriIndex);
    const Script& script =
        Script::Handle(Z, ScriptAt(class_helper.source_uri_index_));
    klass.set_script(script);
  }
  if (klass.token_pos() == TokenPosition::kNoSource) {
    class_helper.ReadUntilIncluding(ClassHelper::kPosition);
    klass.set_token_pos(class_helper.position_);
  }

  class_helper.ReadUntilIncluding(ClassHelper::kAnnotations);
  class_helper.ReadUntilExcluding(ClassHelper::kTypeParameters);
  intptr_t type_parameter_counts =
      builder_.ReadListLength();  // read type_parameters list length.

  ActiveClassScope active_class_scope(&active_class_, &klass);
  if (!klass.is_cycle_free()) {
    LoadPreliminaryClass(&class_helper, type_parameter_counts);
  } else {
    for (intptr_t i = 0; i < type_parameter_counts; ++i) {
      builder_.SkipStringReference();  // read ith name index.
      builder_.SkipDartType();         // read ith bound.
    }
    class_helper.SetJustRead(ClassHelper::kTypeParameters);
  }

  if (FLAG_enable_mirrors && class_helper.annotation_count_ > 0) {
    library.AddClassMetadata(klass, toplevel_class, TokenPosition::kNoSource,
                             class_offset - correction_offset_);
  }

  if (loading_native_wrappers_library_) {
    FinishClassLoading(klass, library, toplevel_class, class_offset,
                       class_index, &class_helper);
  }

  builder_.SetOffset(class_end);

  return klass;
}

void KernelLoader::FinishClassLoading(const Class& klass,
                                      const Library& library,
                                      const Class& toplevel_class,
                                      intptr_t class_offset,
                                      const ClassIndex& class_index,
                                      ClassHelper* class_helper) {
  fields_.Clear();
  functions_.Clear();

  ActiveClassScope active_class_scope(&active_class_, &klass);
  if (library.raw() == Library::InternalLibrary() &&
      klass.Name() == Symbols::ClassID().raw()) {
    // If this is a dart:internal.ClassID class ignore field declarations
    // contained in the Kernel file and instead inject our own const
    // fields.
    klass.InjectCIDFields();
  } else {
    class_helper->ReadUntilExcluding(ClassHelper::kFields);
    int field_count = builder_.ReadListLength();  // read list length.
    for (intptr_t i = 0; i < field_count; ++i) {
      intptr_t field_offset = builder_.ReaderOffset() - correction_offset_;
      ActiveMemberScope active_member(&active_class_, NULL);
      FieldHelper field_helper(&builder_);
      field_helper.ReadUntilExcluding(FieldHelper::kName);

      const String& name = builder_.ReadNameAsFieldName();
      field_helper.SetJustRead(FieldHelper::kName);
      field_helper.ReadUntilExcluding(FieldHelper::kType);
      const AbstractType& type =
          T.BuildTypeWithoutFinalization();  // read type.
      field_helper.SetJustRead(FieldHelper::kType);
      const Object& script_class =
          ClassForScriptAt(klass, field_helper.source_uri_index_);

      const bool is_reflectable =
          field_helper.position_.IsReal() &&
          !(library.is_dart_scheme() && library.IsPrivate(name));
      // In the VM all const fields are implicitly final whereas in Kernel they
      // are not final because they are not explicitly declared that way.
      const bool is_final = field_helper.IsConst() || field_helper.IsFinal();
      Field& field = Field::Handle(
          Z,
          Field::New(name, field_helper.IsStatic(), is_final,
                     field_helper.IsConst(), is_reflectable, script_class, type,
                     field_helper.position_, field_helper.end_position_));
      field.set_kernel_offset(field_offset);
      field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
      intptr_t field_initializer_offset = builder_.ReaderOffset();
      field.set_has_initializer(builder_.PeekTag() == kSomething);
      field_helper.ReadUntilExcluding(FieldHelper::kEnd);
      {
        // GenerateFieldAccessors reads (some of) the initializer.
        AlternativeReadingScope alt(builder_.reader_, field_initializer_offset);
        GenerateFieldAccessors(klass, field, &field_helper);
      }
      if (FLAG_enable_mirrors && field_helper.annotation_count_ > 0) {
        library.AddFieldMetadata(field, TokenPosition::kNoSource, field_offset);
      }
      fields_.Add(&field);
    }
    klass.AddFields(fields_);
    class_helper->SetJustRead(ClassHelper::kFields);
  }

  class_helper->ReadUntilExcluding(ClassHelper::kConstructors);
  int constructor_count = builder_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < constructor_count; ++i) {
    intptr_t constructor_offset = builder_.ReaderOffset() - correction_offset_;
    ActiveMemberScope active_member_scope(&active_class_, NULL);
    ConstructorHelper constructor_helper(&builder_);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kFunction);

    const String& name =
        H.DartConstructorName(constructor_helper.canonical_name_);
    Function& function = Function::ZoneHandle(
        Z, Function::New(name, RawFunction::kConstructor,
                         false,  // is_static
                         constructor_helper.IsConst(),
                         false,  // is_abstract
                         constructor_helper.IsExternal(),
                         false,  // is_native
                         klass, constructor_helper.position_));
    function.set_end_token_pos(constructor_helper.end_position_);
    functions_.Add(&function);
    function.set_kernel_offset(constructor_offset);
    function.set_result_type(T.ReceiverType(klass));

    FunctionNodeHelper function_node_helper(&builder_);
    function_node_helper.ReadUntilExcluding(
        FunctionNodeHelper::kTypeParameters);
    builder_.SetupFunctionParameters(&active_class_, klass, function,
                                     true,   // is_method
                                     false,  // is_closure
                                     &function_node_helper);
    function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);
    constructor_helper.SetJustRead(ConstructorHelper::kFunction);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kEnd);

    if (FLAG_enable_mirrors && constructor_helper.annotation_count_ > 0) {
      library.AddFunctionMetadata(function, TokenPosition::kNoSource,
                                  constructor_offset);
    }
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
    builder_.SetOffset(next_procedure_offset);
    next_procedure_offset = class_index.ProcedureOffset(i + 1) + correction;
    LoadProcedure(library, klass, true, next_procedure_offset);
  }

  klass.SetFunctions(Array::Handle(MakeFunctionsArray()));
}

void KernelLoader::FinishLoading(const Class& klass) {
  ASSERT(klass.kernel_offset() > 0);

  Zone* zone = Thread::Current()->zone();
  const Script& script = Script::Handle(zone, klass.script());
  const Library& library = Library::Handle(zone, klass.library());
  const Class& toplevel_class = Class::Handle(zone, library.toplevel_class());
  const TypedData& library_kernel_data =
      TypedData::Handle(zone, library.kernel_data());
  ASSERT(!library_kernel_data.IsNull());
  const intptr_t library_kernel_offset = library.kernel_offset();
  ASSERT(library_kernel_offset > 0);

  const intptr_t class_offset = klass.kernel_offset();
  KernelLoader kernel_loader(script, library_kernel_data,
                             library_kernel_offset);
  LibraryIndex library_index(library_kernel_data);
  ClassIndex class_index(
      library_kernel_data, class_offset,
      // Class offsets in library index are whole program offsets.
      // Hence, we need to add |library_kernel_offset| to
      // |class_offset| to lookup the entry for the class in the library
      // index.
      library_index.SizeOfClassAtOffset(class_offset + library_kernel_offset));

  kernel_loader.builder_.SetOffset(class_offset);
  ClassHelper class_helper(&kernel_loader.builder_);

  kernel_loader.FinishClassLoading(klass, library, toplevel_class, class_offset,
                                   class_index, &class_helper);
}

void KernelLoader::LoadProcedure(const Library& library,
                                 const Class& owner,
                                 bool in_class,
                                 intptr_t procedure_end) {
  intptr_t procedure_offset = builder_.ReaderOffset() - correction_offset_;
  ProcedureHelper procedure_helper(&builder_);

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kAnnotations);
  const String& name = H.DartProcedureName(procedure_helper.canonical_name_);
  bool is_method = in_class && !procedure_helper.IsStatic();
  bool is_abstract = procedure_helper.IsAbstract();
  bool is_external = procedure_helper.IsExternal();
  String* native_name = NULL;
  intptr_t annotation_count;
  if (is_external) {
    // Maybe it has a native implementation, which is not external as far as
    // the VM is concerned because it does have an implementation.  Check for
    // an ExternalName annotation and extract the string from it.
    annotation_count = builder_.ReadListLength();  // read list length.
    for (int i = 0; i < annotation_count; ++i) {
      if (builder_.PeekTag() != kConstructorInvocation &&
          builder_.PeekTag() != kConstConstructorInvocation) {
        builder_.SkipExpression();
        continue;
      }
      builder_.ReadTag();
      builder_.ReadPosition();
      NameIndex annotation_class = H.EnclosingName(
          builder_.ReadCanonicalNameReference());  // read target reference,
      ASSERT(H.IsClass(annotation_class));
      StringIndex class_name_index = H.CanonicalNameString(annotation_class);
      // Just compare by name, do not generate the annotation class.
      if (!H.StringEquals(class_name_index, "ExternalName")) {
        builder_.SkipArguments();
        continue;
      }
      ASSERT(H.IsLibrary(H.CanonicalNameParent(annotation_class)));
      StringIndex library_name_index =
          H.CanonicalNameString(H.CanonicalNameParent(annotation_class));
      if (!H.StringEquals(library_name_index, "dart:_internal")) {
        builder_.SkipArguments();
        continue;
      }

      is_external = false;
      // Read arguments:
      intptr_t total_arguments = builder_.ReadUInt();  // read argument count.
      builder_.SkipListOfDartTypes();                  // read list of types.
      intptr_t positional_arguments = builder_.ReadListLength();
      ASSERT(total_arguments == 1 && positional_arguments == 1);

      Tag tag = builder_.ReadTag();
      ASSERT(tag == kStringLiteral);
      native_name = &H.DartSymbol(
          builder_.ReadStringReference());  // read index into string table.

      // List of named.
      intptr_t list_length = builder_.ReadListLength();  // read list length.
      ASSERT(list_length == 0);

      // Skip remaining annotations
      for (++i; i < annotation_count; ++i) {
        builder_.SkipExpression();  // read ith annotation.
      }

      break;
    }
    procedure_helper.SetJustRead(ProcedureHelper::kAnnotations);
  } else {
    procedure_helper.ReadUntilIncluding(ProcedureHelper::kAnnotations);
    annotation_count = procedure_helper.annotation_count_;
  }
  const Object& script_class =
      ClassForScriptAt(owner, procedure_helper.source_uri_index_);
  Function& function = Function::ZoneHandle(
      Z, Function::New(name, GetFunctionType(procedure_helper.kind_),
                       !is_method,  // is_static
                       false,       // is_const
                       is_abstract, is_external,
                       native_name != NULL,  // is_native
                       script_class, procedure_helper.position_));
  function.set_end_token_pos(procedure_helper.end_position_);
  functions_.Add(&function);
  function.set_kernel_offset(procedure_offset);

  ActiveMemberScope active_member(&active_class_, &function);

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);

  Tag function_node_tag = builder_.ReadTag();
  ASSERT(function_node_tag == kSomething);
  FunctionNodeHelper function_node_helper(&builder_);
  function_node_helper.ReadUntilIncluding(FunctionNodeHelper::kDartAsyncMarker);
  function.set_is_debuggable(function_node_helper.dart_async_marker_ ==
                             FunctionNodeHelper::kSync);
  switch (function_node_helper.dart_async_marker_) {
    case FunctionNodeHelper::kSyncStar:
      function.set_modifier(RawFunction::kSyncGen);
      break;
    case FunctionNodeHelper::kAsync:
      function.set_modifier(RawFunction::kAsync);
      function.set_is_inlinable(!FLAG_causal_async_stacks);
      break;
    case FunctionNodeHelper::kAsyncStar:
      function.set_modifier(RawFunction::kAsyncGen);
      function.set_is_inlinable(!FLAG_causal_async_stacks);
      break;
    default:
      // no special modifier
      break;
  }
  ASSERT(function_node_helper.async_marker_ == FunctionNodeHelper::kSync);

  if (native_name != NULL) {
    function.set_native_name(*native_name);
  }

  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  builder_.SetupFunctionParameters(&active_class_, owner, function, is_method,
                                   false,  // is_closure
                                   &function_node_helper);

  // Everything else is skipped implicitly, and procedure_helper and
  // function_node_helper are no longer used.
  builder_.SetOffset(procedure_end);

  if (!in_class) {
    library.AddObject(function, name);
    ASSERT(!Object::Handle(
                Z, library.LookupObjectAllowPrivate(
                       H.DartProcedureName(procedure_helper.canonical_name_)))
                .IsNull());
  }

  if (FLAG_enable_mirrors && annotation_count > 0) {
    library.AddFunctionMetadata(function, TokenPosition::kNoSource,
                                procedure_offset);
  }
}

const Object& KernelLoader::ClassForScriptAt(const Class& klass,
                                             intptr_t source_uri_index) {
  const Script& correct_script = Script::Handle(Z, ScriptAt(source_uri_index));
  if (klass.script() != correct_script.raw()) {
    // Use cache for patch classes. This works best for in-order usages.
    PatchClass& patch_class = PatchClass::ZoneHandle(Z);
    patch_class ^= patch_classes_.At(source_uri_index);
    if (patch_class.IsNull() || patch_class.origin_class() != klass.raw()) {
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

RawScript* KernelLoader::LoadScriptAt(intptr_t index) {
  const String& uri_string = builder_.SourceTableUriFor(index);
  const Script& script =
      Script::Handle(Z, Script::New(uri_string, builder_.GetSourceFor(index),
                                    RawScript::kKernelTag));
  script.set_kernel_script_index(index);
  script.set_kernel_program_info(kernel_program_info_);
  script.set_line_starts(builder_.GetLineStartsFor(index));
  script.set_debug_positions(Array::Handle(Array::null()));
  script.set_yield_positions(Array::Handle(Array::null()));
  return script.raw();
}

RawScript* KernelLoader::ScriptAt(intptr_t index, StringIndex import_uri) {
  if (import_uri != -1) {
    const Script& script =
        Script::Handle(Z, kernel_program_info_.ScriptAt(index));
    script.set_url(H.DartString(import_uri, Heap::kOld));
    return script.raw();
  }
  return kernel_program_info_.ScriptAt(index);
}

void KernelLoader::GenerateFieldAccessors(const Class& klass,
                                          const Field& field,
                                          FieldHelper* field_helper) {
  Tag tag = builder_.PeekTag();
  if (field_helper->IsStatic() && tag == kNothing) {
    // Static fields without an initializer are implicitly initialized to null.
    // We do not need a getter.
    field.SetStaticValue(Instance::Handle(Z), true);
    return;
  }
  if (tag == kSomething) {
    SimpleExpressionConverter converter(&H, &builder_);
    const bool has_simple_initializer =
        converter.IsSimple(builder_.ReaderOffset() + 1);  // ignore the tag.
    if (field_helper->IsStatic()) {
      // Static fields with initializers either have the static value set to the
      // initializer value if it is simple enough or else set to an
      // uninitialized sentinel.
      if (has_simple_initializer) {
        // We do not need a getter.
        field.SetStaticValue(converter.SimpleValue(), true);
        return;
      }
      // We do need a getter that evaluates the initializer if necessary.
      field.SetStaticValue(Object::sentinel(), true);
    } else if (has_simple_initializer) {
      // Note: optimizer relies on DoubleInitialized bit in its field-unboxing
      // heuristics. See JitCallSpecializer::VisitStoreInstanceField for more
      // details.
      field.RecordStore(converter.SimpleValue());
      if (!converter.SimpleValue().IsNull() &&
          converter.SimpleValue().IsDouble()) {
        field.set_is_double_initialized(true);
      }
    }
  }

  const String& getter_name = H.DartGetterName(field_helper->canonical_name_);
  const Object& script_class =
      ClassForScriptAt(klass, field_helper->source_uri_index_);
  Function& getter = Function::ZoneHandle(
      Z,
      Function::New(
          getter_name,
          field_helper->IsStatic() ? RawFunction::kImplicitStaticFinalGetter
                                   : RawFunction::kImplicitGetter,
          field_helper->IsStatic(),
          // The functions created by the parser have is_const for static fields
          // that are const (not just final) and they have is_const for
          // non-static
          // fields that are final.
          field_helper->IsStatic() ? field_helper->IsConst()
                                   : field_helper->IsFinal(),
          false,  // is_abstract
          false,  // is_external
          false,  // is_native
          script_class, field_helper->position_));
  functions_.Add(&getter);
  getter.set_end_token_pos(field_helper->end_position_);
  getter.set_kernel_offset(field.kernel_offset());
  getter.set_result_type(AbstractType::Handle(Z, field.type()));
  getter.set_is_debuggable(false);
  SetupFieldAccessorFunction(klass, getter);

  if (!field_helper->IsStatic() && !field_helper->IsFinal()) {
    // Only static fields can be const.
    ASSERT(!field_helper->IsConst());
    const String& setter_name = H.DartSetterName(field_helper->canonical_name_);
    Function& setter = Function::ZoneHandle(
        Z, Function::New(setter_name, RawFunction::kImplicitSetter,
                         false,  // is_static
                         false,  // is_const
                         false,  // is_abstract
                         false,  // is_external
                         false,  // is_native
                         script_class, field_helper->position_));
    functions_.Add(&setter);
    setter.set_end_token_pos(field_helper->end_position_);
    setter.set_kernel_offset(field.kernel_offset());
    setter.set_result_type(Object::void_type());
    setter.set_is_debuggable(false);
    SetupFieldAccessorFunction(klass, setter);
  }
}

void KernelLoader::SetupFieldAccessorFunction(const Class& klass,
                                              const Function& function) {
  bool is_setter = function.IsImplicitSetterFunction();
  bool is_method = !function.IsStaticFunction();
  intptr_t parameter_count = (is_method ? 1 : 0) + (is_setter ? 1 : 0);

  function.SetNumOptionalParameters(0, false);
  function.set_num_fixed_parameters(parameter_count);
  function.set_parameter_types(
      Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));
  function.set_parameter_names(
      Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));

  intptr_t pos = 0;
  if (is_method) {
    function.SetParameterTypeAt(pos, T.ReceiverType(klass));
    function.SetParameterNameAt(pos, Symbols::This());
    pos++;
  }
  if (is_setter) {
    function.SetParameterTypeAt(pos, AbstractType::dynamic_type());
    function.SetParameterNameAt(pos, Symbols::Value());
    pos++;
  }
}

Library& KernelLoader::LookupLibrary(NameIndex library) {
  Library* handle = NULL;
  if (!libraries_.Lookup(library, &handle)) {
    const String& url = H.DartSymbol(H.CanonicalNameString(library));
    handle = &Library::Handle(Z, Library::LookupLibrary(thread_, url));
    if (handle->IsNull()) {
      *handle = Library::New(url);
      handle->Register(thread_);
    }
    ASSERT(!handle->IsNull());
    libraries_.Insert(library, handle);
  }
  return *handle;
}

Class& KernelLoader::LookupClass(NameIndex klass) {
  Class* handle = NULL;
  if (!classes_.Lookup(klass, &handle)) {
    Library& library = LookupLibrary(H.CanonicalNameParent(klass));
    const String& name = H.DartClassName(klass);
    handle = &Class::Handle(Z, library.LookupLocalClass(name));
    if (handle->IsNull()) {
      *handle = Class::New(library, name, Script::Handle(Z),
                           TokenPosition::kNoSource);
      library.AddClass(*handle);
    }
    // Insert the class in the cache before calling ReadPreliminaryClass so
    // we do not risk allocating the class again by calling LookupClass
    // recursively from ReadPreliminaryClass for the same class.
    classes_.Insert(klass, handle);
  }
  return *handle;
}

RawFunction::Kind KernelLoader::GetFunctionType(
    ProcedureHelper::Kind procedure_kind) {
  intptr_t lookuptable[] = {
      RawFunction::kRegularFunction,  // Procedure::kMethod
      RawFunction::kGetterFunction,   // Procedure::kGetter
      RawFunction::kSetterFunction,   // Procedure::kSetter
      RawFunction::kRegularFunction,  // Procedure::kOperator
      RawFunction::kConstructor,      // Procedure::kFactory
  };
  intptr_t kind = static_cast<int>(procedure_kind);
  ASSERT(0 <= kind && kind <= ProcedureHelper::kFactory);
  return static_cast<RawFunction::Kind>(lookuptable[kind]);
}

ParsedFunction* ParseStaticFieldInitializer(Zone* zone, const Field& field) {
  Thread* thread = Thread::Current();

  String& init_name = String::Handle(zone, field.name());
  init_name = Symbols::FromConcat(thread, Symbols::InitPrefix(), init_name);

  // Create a static initializer.
  const Object& owner = Object::Handle(field.RawOwner());
  const Function& initializer_fun = Function::ZoneHandle(
      zone, Function::New(init_name, RawFunction::kImplicitStaticFinalGetter,
                          true,   // is_static
                          false,  // is_const
                          false,  // is_abstract
                          false,  // is_external
                          false,  // is_native
                          owner, TokenPosition::kNoSource));
  initializer_fun.set_kernel_offset(field.kernel_offset());
  initializer_fun.set_result_type(AbstractType::Handle(zone, field.type()));
  initializer_fun.set_is_debuggable(false);
  initializer_fun.set_is_reflectable(false);
  initializer_fun.set_is_inlinable(false);
  return new (zone) ParsedFunction(thread, initializer_fun);
}

}  // namespace kernel
}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
