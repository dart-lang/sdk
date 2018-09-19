// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_loader.h"

#include <string.h>

#include "vm/compiler/frontend/constant_evaluator.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/kernel_binary.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/reusable_handles.h"
#include "vm/service_isolate.h"
#include "vm/symbols.h"
#include "vm/thread.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {
namespace kernel {

#define Z (zone_)
#define I (isolate_)
#define T (type_translator_)
#define H (translation_helper_)

static const char* const kVMServiceIOLibraryUri = "dart:vmservice_io";

class SimpleExpressionConverter {
 public:
  SimpleExpressionConverter(TranslationHelper* translation_helper,
                            KernelReaderHelper* reader_helper)
      : translation_helper_(*translation_helper),
        zone_(translation_helper_.zone()),
        simple_value_(NULL),
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
  KernelReaderHelper* helper_;

  DISALLOW_COPY_AND_ASSIGN(SimpleExpressionConverter);
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

LibraryIndex::LibraryIndex(const ExternalTypedData& kernel_data)
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

KernelLoader::KernelLoader(Program* program)
    : program_(program),
      thread_(Thread::Current()),
      zone_(thread_->zone()),
      isolate_(thread_->isolate()),
      patch_classes_(Array::ZoneHandle(zone_)),
      library_kernel_offset_(-1),  // Set to the correct value in LoadLibrary
      correction_offset_(-1),      // Set to the correct value in LoadLibrary
      loading_native_wrappers_library_(false),
      library_kernel_data_(ExternalTypedData::ZoneHandle(zone_)),
      kernel_program_info_(KernelProgramInfo::ZoneHandle(zone_)),
      translation_helper_(this, thread_),
      helper_(zone_,
              &translation_helper_,
              program_->kernel_data(),
              program_->kernel_data_size(),
              0),
      type_translator_(&helper_, &active_class_, /* finalize= */ false),
      external_name_class_(Class::Handle(Z)),
      external_name_field_(Field::Handle(Z)),
      potential_natives_(GrowableObjectArray::Handle(Z)),
      potential_pragma_functions_(GrowableObjectArray::Handle(Z)),
      potential_extension_libraries_(GrowableObjectArray::Handle(Z)),
      pragma_class_(Class::Handle(Z)),
      expression_evaluation_library_(Library::Handle(Z)),
      expression_evaluation_function_(Function::Handle(Z)) {
  if (!program->is_single_program()) {
    FATAL(
        "Trying to load a concatenated dill file at a time where that is "
        "not allowed");
  }
  InitializeFields();
}

Object& KernelLoader::LoadEntireProgram(Program* program,
                                        bool process_pending_classes) {
  if (program->is_single_program()) {
    KernelLoader loader(program);
    return Object::Handle(loader.LoadProgram(process_pending_classes));
  }

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
    Program* subprogram = Program::ReadFrom(&reader);
    ASSERT(subprogram->is_single_program());
    KernelLoader loader(subprogram);
    Object& load_result = Object::Handle(loader.LoadProgram(false));
    if (load_result.IsError()) return load_result;

    if (library.IsNull() && load_result.IsLibrary()) {
      library ^= load_result.raw();
    }

    delete subprogram;
  }

  if (process_pending_classes && !ClassFinalizer::ProcessPendingClasses()) {
    // Class finalization failed -> sticky error would be set.
    Error& error = Error::Handle(zone);
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error;
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

void KernelLoader::InitializeFields() {
  const intptr_t source_table_size = helper_.SourceTableSize();
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

  // Create view of the string data.
  const ExternalTypedData& data = ExternalTypedData::Handle(
      Z,
      reader.ExternalDataFromTo(reader.offset(), reader.offset() + end_offset));

  // Create a view of the constants table. The trailing ComponentIndex is
  // negligible in size.
  const ExternalTypedData& constants_table = ExternalTypedData::Handle(
      Z, reader.ExternalDataFromTo(program_->constant_table_offset(),
                                   program_->kernel_data_size()));

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

  // Create view of metadata mappings.
  const ExternalTypedData& metadata_mappings = ExternalTypedData::Handle(
      Z, reader.ExternalDataFromTo(program_->metadata_mappings_offset(),
                                   program_->string_table_offset()));

  kernel_program_info_ =
      KernelProgramInfo::New(offsets, data, names, metadata_payloads,
                             metadata_mappings, constants_table, scripts);

  H.InitFromKernelProgramInfo(kernel_program_info_);

  Script& script = Script::Handle(Z);
  for (intptr_t index = 0; index < source_table_size; ++index) {
    script = LoadScriptAt(index);
    scripts.SetAt(index, script);
  }
}

KernelLoader::KernelLoader(const Script& script,
                           const ExternalTypedData& kernel_data,
                           intptr_t data_program_offset)
    : program_(NULL),
      thread_(Thread::Current()),
      zone_(thread_->zone()),
      isolate_(thread_->isolate()),
      patch_classes_(Array::ZoneHandle(zone_)),
      library_kernel_offset_(data_program_offset),
      correction_offset_(0),
      loading_native_wrappers_library_(false),
      library_kernel_data_(ExternalTypedData::ZoneHandle(zone_)),
      kernel_program_info_(
          KernelProgramInfo::ZoneHandle(zone_, script.kernel_program_info())),
      translation_helper_(this, thread_),
      helper_(zone_, &translation_helper_, script, kernel_data, 0),
      type_translator_(&helper_, &active_class_, /* finalize= */ false),
      external_name_class_(Class::Handle(Z)),
      external_name_field_(Field::Handle(Z)),
      potential_natives_(GrowableObjectArray::Handle(Z)),
      potential_pragma_functions_(GrowableObjectArray::Handle(Z)),
      potential_extension_libraries_(GrowableObjectArray::Handle(Z)),
      pragma_class_(Class::Handle(Z)),
      expression_evaluation_library_(Library::Handle(Z)),
      expression_evaluation_function_(Function::Handle(Z)) {
  ASSERT(T.active_class_ == &active_class_);
  T.finalize_ = false;

  const Array& scripts = Array::Handle(Z, kernel_program_info_.scripts());
  patch_classes_ = Array::New(scripts.Length(), Heap::kOld);
  library_kernel_data_ = kernel_data.raw();

  H.InitFromKernelProgramInfo(kernel_program_info_);
}

const Array& KernelLoader::ReadConstantTable() {
  // We use the very first library's toplevel class as an owner for an
  // [ActiveClassScope]
  //
  // Though since constants cannot refer to types containing type parameter
  // references, the only purpose of the class is to serve as an owner for
  // signature functions (which get created for function types).
  const dart::Library& owner_library = LookupLibrary(library_canonical_name(0));
  const dart::Class& toplevel_class =
      Class::Handle(Z, owner_library.toplevel_class());
  ActiveClassScope active_class_scope(&active_class_, &toplevel_class);

  helper_.SetOffset(program_->constant_table_offset());
  TypeTranslator type_translator_(&helper_, &active_class_,
                                  true /* finalize */);
  ASSERT(type_translator_.active_class_ == &active_class_);

  ConstantHelper helper(Z, &helper_, &type_translator_, &active_class_,
                        skip_vmservice_library_);
  return helper.ReadConstantTable();
}

void KernelLoader::EvaluateDelayedPragmas() {
  if (potential_pragma_functions_.IsNull()) return;
  Thread* thread = Thread::Current();
  NoOOBMessageScope no_msg_scope(thread);
  NoReloadScope no_reload_scope(thread->isolate(), thread);

  Function& function = Function::Handle();
  Library& library = Library::Handle();
  Class& klass = Class::Handle();
  for (int i = 0; i < potential_pragma_functions_.Length(); ++i) {
    function ^= potential_pragma_functions_.At(i);
    klass = function.Owner();
    library = klass.library();
    library.GetMetadata(function);
  }

  potential_pragma_functions_ = GrowableObjectArray::null();
  kernel_program_info_.set_potential_pragma_functions(
      GrowableObjectArray::Handle(Z));
}

void KernelLoader::AnnotateNativeProcedures(const Array& constant_table_array) {
  KernelConstantsMap constant_table(constant_table_array.raw());
  potential_natives_ = kernel_program_info_.potential_natives();
  const intptr_t length =
      !potential_natives_.IsNull() ? potential_natives_.Length() : 0;
  if (length > 0) {
    // Obtain `dart:_internal::ExternalName.name`.
    EnsureExternalClassIsLookedUp();
    Instance& constant = Instance::Handle(Z);
    String& native_name = String::Handle(Z);

    // Start scanning all candidates in [potential_natives] for the annotation
    // constant.  If the annotation is found, flag the [Function] as native and
    // attach the native name to it.
    Function& function = Function::Handle(Z);
    for (intptr_t i = 0; i < length; ++i) {
      function ^= potential_natives_.At(i);
      helper_.SetOffset(function.KernelDataProgramOffset() +
                        function.kernel_offset());
      {
        ProcedureHelper procedure_helper(&helper_);
        procedure_helper.ReadUntilExcluding(ProcedureHelper::kAnnotations);
      }

      const intptr_t annotation_count = helper_.ReadListLength();
      for (intptr_t j = 0; j < annotation_count; ++j) {
        const intptr_t tag = helper_.PeekTag();
        if (tag == kConstantExpression) {
          helper_.ReadByte();  // Skip the tag.

          // We have a candiate.  Let's look if it's an instance of the
          // ExternalName class.
          const intptr_t constant_table_offset = helper_.ReadUInt();
          constant ^= constant_table.GetOrDie(constant_table_offset);
          if (constant.clazz() == external_name_class_.raw()) {
            // We found the annotation, let's flag the function as native and
            // set the native name!
            native_name ^= constant.GetField(external_name_field_);
            function.set_is_native(true);
            function.set_native_name(native_name);
            function.set_is_external(false);
            break;
          }
        } else {
          helper_.SkipExpression();
        }
      }
    }

    // Clear out the list of [Function] objects which might need their native
    // name to be set after reading the constant table from the kernel blob.
    potential_natives_ = GrowableObjectArray::null();
    kernel_program_info_.set_potential_natives(potential_natives_);
  }
  ASSERT(constant_table.Release().raw() == constant_table_array.raw());
}

RawString* KernelLoader::DetectExternalNameCtor() {
  helper_.ReadTag();
  helper_.ReadPosition();
  NameIndex annotation_class = H.EnclosingName(
      helper_.ReadCanonicalNameReference());  // read target reference,

  if (!IsClassName(annotation_class, Symbols::DartInternal(),
                   Symbols::ExternalName())) {
    helper_.SkipArguments();
    return String::null();
  }

  // Read arguments:
  intptr_t total_arguments = helper_.ReadUInt();  // read argument count.
  helper_.SkipListOfDartTypes();                  // read list of types.
  intptr_t positional_arguments = helper_.ReadListLength();
  ASSERT(total_arguments == 1 && positional_arguments == 1);

  Tag tag = helper_.ReadTag();
  ASSERT(tag == kStringLiteral);
  String& result = H.DartSymbolPlain(
      helper_.ReadStringReference());  // read index into string table.

  // List of named.
  intptr_t list_length = helper_.ReadListLength();  // read list length.
  ASSERT(list_length == 0);

  return result.raw();
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

bool KernelLoader::DetectPragmaCtor() {
  helper_.ReadTag();
  helper_.ReadPosition();
  NameIndex annotation_class = H.EnclosingName(
      helper_.ReadCanonicalNameReference());  // read target reference
  helper_.SkipArguments();
  return IsClassName(annotation_class, Symbols::DartCore(), Symbols::Pragma());
}

void KernelLoader::LoadNativeExtensionLibraries(
    const Array& constant_table_array) {
  const intptr_t length = !potential_extension_libraries_.IsNull()
                              ? potential_extension_libraries_.Length()
                              : 0;
  if (length == 0) return;

  KernelConstantsMap constant_table(constant_table_array.raw());

  // Obtain `dart:_internal::ExternalName.name`.
  EnsureExternalClassIsLookedUp();

  Instance& constant = Instance::Handle(Z);
  String& uri_path = String::Handle(Z);
  Library& library = Library::Handle(Z);
  Object& result = Object::Handle(Z);

  for (intptr_t i = 0; i < length; ++i) {
    library ^= potential_extension_libraries_.At(i);
    helper_.SetOffset(library.kernel_offset());

    LibraryHelper library_helper(&helper_);
    library_helper.ReadUntilExcluding(LibraryHelper::kAnnotations);

    const intptr_t annotation_count = helper_.ReadListLength();
    for (intptr_t j = 0; j < annotation_count; ++j) {
      uri_path = String::null();

      const intptr_t tag = helper_.PeekTag();
      if (tag == kConstantExpression) {
        helper_.ReadByte();  // Skip the tag.

        const intptr_t constant_table_index = helper_.ReadUInt();
        constant ^= constant_table.GetOrDie(constant_table_index);
        if (constant.clazz() == external_name_class_.raw()) {
          uri_path ^= constant.GetField(external_name_field_);
        }
      } else if (tag == kConstructorInvocation ||
                 tag == kConstConstructorInvocation) {
        uri_path = DetectExternalNameCtor();
      } else {
        helper_.SkipExpression();
      }

      if (uri_path.IsNull()) continue;

      Dart_LibraryTagHandler handler = I->library_tag_handler();
      if (handler == NULL) {
        H.ReportError("no library handler registered.");
      }

      I->BlockClassFinalization();
      {
        TransitionVMToNative transition(thread_);
        Api::Scope api_scope(thread_);
        Dart_Handle retval = handler(Dart_kImportExtensionTag,
                                     Api::NewHandle(thread_, library.raw()),
                                     Api::NewHandle(thread_, uri_path.raw()));
        result = Api::UnwrapHandle(retval);
      }
      I->UnblockClassFinalization();

      if (result.IsError()) {
        H.ReportError(Error::Cast(result), "library handler failed");
      }
    }
  }
  potential_extension_libraries_ = GrowableObjectArray::null();
  ASSERT(constant_table.Release().raw() == constant_table_array.raw());
}

RawObject* KernelLoader::LoadProgram(bool process_pending_classes) {
  ASSERT(kernel_program_info_.constants() == Array::null());

  if (!program_->is_single_program()) {
    FATAL(
        "Trying to load a concatenated dill file at a time where that is "
        "not allowed");
  }

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    const intptr_t length = program_->library_count();
    Object& last_library = Library::Handle(Z);
    for (intptr_t i = 0; i < length; i++) {
      last_library = LoadLibrary(i);
    }

    if (process_pending_classes) {
      if (!ClassFinalizer::ProcessPendingClasses()) {
        // Class finalization failed -> sticky error would be set.
        RawError* error = H.thread()->sticky_error();
        H.thread()->clear_sticky_error();
        return error;
      }
    }

    // All classes were successfully loaded, so let's:
    //     a) load & canonicalize the constant table
    const Array& constants = ReadConstantTable();

    //     b) set the native names for native functions which have been created
    //        so far (the rest will be directly set during LoadProcedure)
    AnnotateNativeProcedures(constants);
    LoadNativeExtensionLibraries(constants);

    //     c) update all scripts with the constants array
    ASSERT(kernel_program_info_.constants() == Array::null());
    kernel_program_info_.set_constants(constants);
    kernel_program_info_.set_constants_table(ExternalTypedData::Handle(Z));

    EvaluateDelayedPragmas();

    NameIndex main = program_->main_method();
    if (main == -1) {
      return Library::null();
    }

    NameIndex main_library = H.EnclosingName(main);
    Library& library = LookupLibrary(main_library);

    return library.raw();
  }

  // Either class finalization failed or we caught a compile error.
  // In both cases sticky error would be set.
  RawError* error = thread_->sticky_error();
  thread_->clear_sticky_error();
  return error;
}

RawObject* KernelLoader::LoadExpressionEvaluationFunction(
    const String& library_url,
    const String& klass) {
  // Find the original context, i.e. library/class, in which the evaluation will
  // happen.
  const Library& real_library = Library::Handle(
      Z, Library::LookupLibrary(Thread::Current(), library_url));
  ASSERT(!real_library.IsNull());
  const Class& real_class = Class::Handle(
      Z, klass.IsNull() ? real_library.toplevel_class()
                        : real_library.LookupClassAllowPrivate(klass));
  ASSERT(!real_class.IsNull());

  const intptr_t num_cids = I->class_table()->NumCids();
  const intptr_t num_libs =
      GrowableObjectArray::Handle(I->object_store()->libraries()).Length();

  // Load the "evaluate:source" expression evaluation library.
  ASSERT(expression_evaluation_library_.IsNull());
  ASSERT(expression_evaluation_function_.IsNull());
  const Object& result = Object::Handle(Z, LoadProgram(true));
  if (result.IsError()) {
    return result.raw();
  }
  ASSERT(!expression_evaluation_library_.IsNull());
  ASSERT(!expression_evaluation_function_.IsNull());
  ASSERT(GrowableObjectArray::Handle(I->object_store()->libraries()).Length() ==
         num_libs);
  ASSERT(I->class_table()->NumCids() == num_cids);

  // Make the expression evaluation function have the right kernel data and
  // parent.
  auto& eval_data = ExternalTypedData::Handle(
      Z, expression_evaluation_library_.kernel_data());
  auto& eval_script =
      Script::Handle(Z, expression_evaluation_function_.script());
  expression_evaluation_function_.SetKernelDataAndScript(
      eval_script, eval_data, expression_evaluation_library_.kernel_offset());
  expression_evaluation_function_.set_owner(real_class);

  return expression_evaluation_function_.raw();
}

void KernelLoader::FindModifiedLibraries(Program* program,
                                         Isolate* isolate,
                                         BitVector* modified_libs,
                                         bool force_reload,
                                         bool* is_empty_program) {
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
    *is_empty_program = true;
    if (program->is_single_program()) {
      KernelLoader loader(program);
      return loader.walk_incremental_kernel(modified_libs, is_empty_program);
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
        Program* subprogram = Program::ReadFrom(&reader);
        ASSERT(subprogram->is_single_program());
        KernelLoader loader(subprogram);
        loader.walk_incremental_kernel(modified_libs, is_empty_program);
        delete subprogram;
      }
    }
  }
}

void KernelLoader::walk_incremental_kernel(BitVector* modified_libs,
                                           bool* is_empty_program) {
  intptr_t length = program_->library_count();
  *is_empty_program = *is_empty_program && (length == 0);
  for (intptr_t i = 0; i < length; i++) {
    intptr_t kernel_offset = library_offset(i);
    helper_.SetOffset(kernel_offset);
    LibraryHelper library_helper(&helper_);
    library_helper.ReadUntilIncluding(LibraryHelper::kCanonicalName);
    dart::Library& lib = LookupLibraryOrNull(library_helper.canonical_name_);
    if (!lib.IsNull() && !lib.is_dart_scheme()) {
      // This is a library that already exists so mark it as being modified.
      modified_libs->Add(lib.index());
    }
  }
}

void KernelLoader::CheckForInitializer(const Field& field) {
  if (helper_.PeekTag() == kSomething) {
    SimpleExpressionConverter converter(&H, &helper_);
    const bool has_simple_initializer =
        converter.IsSimple(helper_.ReaderOffset() + 1);
    if (!has_simple_initializer || !converter.SimpleValue().IsNull()) {
      field.set_has_initializer(true);
      return;
    }
  }
  field.set_has_initializer(false);
}

RawLibrary* KernelLoader::LoadLibrary(intptr_t index) {
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
  if (!FLAG_precompiled_mode && !I->should_load_vmservice()) {
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
      Library::Handle(Z, LookupLibrary(library_helper.canonical_name_).raw());

  // The Kernel library is external implies that it is already loaded.
  ASSERT(!library_helper.IsExternal() || library.Loaded());
  if (library.Loaded()) return library.raw();

  library_kernel_data_ = helper_.reader_.ExternalDataFromTo(
      library_kernel_offset_, library_kernel_offset_ + library_size);
  library.set_kernel_data(library_kernel_data_);
  library.set_kernel_offset(library_kernel_offset_);

  LibraryIndex library_index(library_kernel_data_);
  intptr_t class_count = library_index.class_count();
  intptr_t procedure_count = library_index.procedure_count();

  library_helper.ReadUntilIncluding(LibraryHelper::kName);
  library.SetName(H.DartSymbolObfuscate(library_helper.name_index_));

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

  library_helper.ReadUntilExcluding(LibraryHelper::kAnnotations);
  intptr_t annotations_kernel_offset =
      helper_.ReaderOffset() - correction_offset_;
  intptr_t annotation_count = helper_.ReadListLength();  // read list length.
  if (annotation_count > 0) {
    EnsurePotentialExtensionLibraries();
    potential_extension_libraries_.Add(library);
  }
  for (intptr_t i = 0; i < annotation_count; ++i) {
    helper_.SkipExpression();  // read ith annotation.
  }
  library_helper.SetJustRead(LibraryHelper::kAnnotations);

  // Setup toplevel class (which contains library fields/procedures).

  // We do not register expression evaluation classes with the VM:
  // The expression evaluation functions should be GC-able as soon as
  // they are not reachable anymore and we never look them up by name.
  const bool register_class =
      library.raw() != expression_evaluation_library_.raw();

  Class& toplevel_class =
      Class::Handle(Z, Class::New(library, Symbols::TopLevel(), script,
                                  TokenPosition::kNoSource, register_class));
  toplevel_class.set_is_cycle_free();
  library.set_toplevel_class(toplevel_class);

  library_helper.ReadUntilExcluding(LibraryHelper::kDependencies);
  LoadLibraryImportsAndExports(&library, toplevel_class);
  library_helper.SetJustRead(LibraryHelper::kDependencies);

  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(Z, I->object_store()->pending_classes());

  // Everything up til the classes are skipped implicitly, and library_helper
  // is no longer used.

  // Load all classes.
  intptr_t next_class_offset = library_index.ClassOffset(0);
  for (intptr_t i = 0; i < class_count; ++i) {
    helper_.SetOffset(next_class_offset);
    next_class_offset = library_index.ClassOffset(i + 1);
    const Class& klass = LoadClass(library, toplevel_class, next_class_offset);
    if (register_class) {
      classes.Add(klass, Heap::kOld);
    }
  }
  helper_.SetOffset(next_class_offset);

  fields_.Clear();
  functions_.Clear();
  ActiveClassScope active_class_scope(&active_class_, &toplevel_class);
  // Load toplevel fields.
  intptr_t field_count = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < field_count; ++i) {
    intptr_t field_offset = helper_.ReaderOffset() - correction_offset_;
    ActiveMemberScope active_member_scope(&active_class_, NULL);
    FieldHelper field_helper(&helper_);
    field_helper.ReadUntilExcluding(FieldHelper::kName);

    const String& name = helper_.ReadNameAsFieldName();
    field_helper.SetJustRead(FieldHelper::kName);

    field_helper.ReadUntilExcluding(FieldHelper::kAnnotations);
    intptr_t annotation_count = helper_.ReadListLength();
    bool has_pragma_annotation;
    {
      String& native_name_unused = String::Handle();
      bool is_potential_native_unused;
      ReadVMAnnotations(annotation_count, &native_name_unused,
                        &is_potential_native_unused, &has_pragma_annotation);
    }
    if (has_pragma_annotation) {
      toplevel_class.set_has_pragma(true);
    }
    field_helper.SetJustRead(FieldHelper::kAnnotations);

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
    CheckForInitializer(field);
    field_helper.SetJustRead(FieldHelper::kType);
    field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
    intptr_t field_initializer_offset = helper_.ReaderOffset();
    field_helper.ReadUntilExcluding(FieldHelper::kEnd);
    {
      // GenerateFieldAccessors reads (some of) the initializer.
      AlternativeReadingScope alt(&helper_.reader_, field_initializer_offset);
      GenerateFieldAccessors(toplevel_class, field, &field_helper);
    }
    if ((FLAG_enable_mirrors || has_pragma_annotation) &&
        annotation_count > 0) {
      library.AddFieldMetadata(field, TokenPosition::kNoSource, field_offset);
    }
    fields_.Add(&field);
    library.AddObject(field, name);
  }
  toplevel_class.AddFields(fields_);

  // Load toplevel procedures.
  intptr_t next_procedure_offset = library_index.ProcedureOffset(0);
  for (intptr_t i = 0; i < procedure_count; ++i) {
    helper_.SetOffset(next_procedure_offset);
    next_procedure_offset = library_index.ProcedureOffset(i + 1);
    LoadProcedure(library, toplevel_class, false, next_procedure_offset);
  }

  if (FLAG_enable_mirrors && annotation_count > 0) {
    ASSERT(annotations_kernel_offset > 0);
    library.AddLibraryMetadata(toplevel_class, TokenPosition::kNoSource,
                               annotations_kernel_offset);
  }

  toplevel_class.SetFunctions(Array::Handle(MakeFunctionsArray()));
  if (register_class) {
    classes.Add(toplevel_class, Heap::kOld);
  }
  if (!library.Loaded()) library.SetLoaded();

  return library.raw();
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
    String& prefix = H.DartSymbolPlain(dependency_helper.name_index_);
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
    if (FLAG_enable_mirrors && dependency_helper.annotation_count_ > 0) {
      ASSERT(annotations_kernel_offset > 0);
      ns.AddMetadata(toplevel_class, TokenPosition::kNoSource,
                     annotations_kernel_offset);
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
  T.LoadAndSetupTypeParameters(&active_class_, *klass, type_parameter_count,
                               Function::Handle(Z));

  // Set super type.  Some classes (e.g., Object) do not have one.
  Tag type_tag = helper_.ReadTag();  // read super class type (part 1).
  if (type_tag == kSomething) {
    AbstractType& super_type =
        T.BuildTypeWithoutFinalization();  // read super class type (part 2).
    if (super_type.IsMalformed()) H.ReportError("Malformed super type");
    klass->set_super_type(super_type);
  }

  class_helper->SetJustRead(ClassHelper::kSuperClass);
  class_helper->ReadUntilIncluding(ClassHelper::kMixinType);

  // Build implemented interface types
  intptr_t interface_count = helper_.ReadListLength();
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

  if (class_helper->is_abstract()) klass->set_is_abstract();

  if (class_helper->is_transformed_mixin_application()) {
    klass->set_is_transformed_mixin_application();
  }
}

// Workaround for http://dartbug.com/32087: currently Kernel front-end
// embeds absolute build-time paths to core library sources into Kernel
// binaries this introduces discrepancy between how stack traces were
// looked like in legacy pipeline and how they look in Dart 2 pipeline and
// breaks users' code that attempts to pattern match and filter various
// irrelevant frames (e.g. frames from dart:async).
// This also breaks debugging experience in external debuggers because
// debugger attempts to open files that don't exist in the local file
// system.
// To work around this issue we reformat urls of scripts belonging to
// dart:-scheme libraries to look like they looked like in legacy pipeline:
//
//               dart:libname/filename.dart
//               dart:libname/runtime/lib/filename.dart
//               dart:libname/runtime/bin/filename.dart
//
void KernelLoader::FixCoreLibraryScriptUri(const Library& library,
                                           const Script& script) {
  struct Helper {
    static bool EndsWithCString(const String& haystack,
                                const char* needle,
                                intptr_t needle_length,
                                intptr_t end_pos) {
      const intptr_t start = end_pos - needle_length + 1;
      if (start >= 0) {
        for (intptr_t i = 0; i < needle_length; i++) {
          if (haystack.CharAt(start + i) != needle[i]) {
            return false;
          }
        }
        return true;
      }
      return false;
    }
  };

  if (library.is_dart_scheme()) {
    String& url = String::Handle(zone_, script.url());
    if (!url.StartsWith(Symbols::DartScheme())) {
      // Search backwards until '/' is found. That gives us the filename.
      // Note: can't use reusable handle in the code below because
      // concat also needs it.
      intptr_t pos = url.Length() - 1;
      while (pos >= 0 && url.CharAt(pos) != '/') {
        pos--;
      }

      static const char* kRuntimeLib = "runtime/lib/";
      static const intptr_t kRuntimeLibLen = strlen(kRuntimeLib);
      const bool inside_runtime_lib =
          Helper::EndsWithCString(url, kRuntimeLib, kRuntimeLibLen, pos);

      static const char* kRuntimeBin = "runtime/bin/";
      static const intptr_t kRuntimeBinLen = strlen(kRuntimeBin);
      const bool inside_runtime_bin =
          Helper::EndsWithCString(url, kRuntimeBin, kRuntimeBinLen, pos);

      String& tmp = String::Handle(zone_);
      url = String::SubString(url, pos + 1);
      if (inside_runtime_lib) {
        tmp = String::New("runtime/lib", Heap::kNew);
        url = String::Concat(tmp, url);
      } else if (inside_runtime_bin) {
        tmp = String::New("runtime/bin", Heap::kNew);
        url = String::Concat(tmp, url);
      }
      tmp = library.url();
      url = String::Concat(Symbols::Slash(), url);
      url = String::Concat(tmp, url);
      script.set_url(url);
    }
  }
}

Class& KernelLoader::LoadClass(const Library& library,
                               const Class& toplevel_class,
                               intptr_t class_end) {
  intptr_t class_offset = helper_.ReaderOffset();
  ClassIndex class_index(program_->kernel_data(), program_->kernel_data_size(),
                         class_offset, class_end - class_offset);

  ClassHelper class_helper(&helper_);
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
    FixCoreLibraryScriptUri(library, script);
  }
  if (klass.token_pos() == TokenPosition::kNoSource) {
    class_helper.ReadUntilIncluding(ClassHelper::kStartPosition);
    klass.set_token_pos(class_helper.start_position_);
  }

  class_helper.ReadUntilIncluding(ClassHelper::kFlags);
  if (class_helper.is_enum_class()) klass.set_is_enum_class();

  class_helper.ReadUntilExcluding(ClassHelper::kAnnotations);
  intptr_t annotation_count = helper_.ReadListLength();
  bool has_pragma_annotation = false;
  {
    String& native_name_unused = String::Handle(Z);
    bool is_potential_native_unused = false;
    ReadVMAnnotations(annotation_count, &native_name_unused,
                      &is_potential_native_unused, &has_pragma_annotation);
  }
  if (has_pragma_annotation) {
    klass.set_has_pragma(true);
  }
  class_helper.SetJustRead(ClassHelper::kAnnotations);
  class_helper.ReadUntilExcluding(ClassHelper::kTypeParameters);
  intptr_t type_parameter_counts =
      helper_.ReadListLength();  // read type_parameters list length.

  ActiveClassScope active_class_scope(&active_class_, &klass);
  if (!klass.is_cycle_free()) {
    LoadPreliminaryClass(&class_helper, type_parameter_counts);
  } else {
    for (intptr_t i = 0; i < type_parameter_counts; ++i) {
      helper_.SkipStringReference();  // read ith name index.
      helper_.SkipDartType();         // read ith bound.
    }
    class_helper.SetJustRead(ClassHelper::kTypeParameters);
  }

  if ((FLAG_enable_mirrors || has_pragma_annotation) && annotation_count > 0) {
    library.AddClassMetadata(klass, toplevel_class, TokenPosition::kNoSource,
                             class_offset - correction_offset_);
  }

  // We do not register expression evaluation classes with the VM:
  // The expression evaluation functions should be GC-able as soon as
  // they are not reachable anymore and we never look them up by name.
  const bool register_class =
      library.raw() != expression_evaluation_library_.raw();

  if (loading_native_wrappers_library_ || !register_class) {
    FinishClassLoading(klass, library, toplevel_class, class_offset,
                       class_index, &class_helper);
  }

  helper_.SetOffset(class_end);

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
    int field_count = helper_.ReadListLength();  // read list length.
    for (intptr_t i = 0; i < field_count; ++i) {
      intptr_t field_offset = helper_.ReaderOffset() - correction_offset_;
      ActiveMemberScope active_member(&active_class_, NULL);
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
      {
        String& native_name_unused = String::Handle();
        bool is_potential_native_unused;
        ReadVMAnnotations(annotation_count, &native_name_unused,
                          &is_potential_native_unused, &has_pragma_annotation);
      }
      if (has_pragma_annotation) {
        klass.set_has_pragma(true);
      }
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
      Field& field = Field::Handle(
          Z,
          Field::New(name, field_helper.IsStatic(), is_final,
                     field_helper.IsConst(), is_reflectable, script_class, type,
                     field_helper.position_, field_helper.end_position_));
      field.set_kernel_offset(field_offset);
      CheckForInitializer(field);
      field_helper.ReadUntilExcluding(FieldHelper::kInitializer);
      intptr_t field_initializer_offset = helper_.ReaderOffset();
      field_helper.ReadUntilExcluding(FieldHelper::kEnd);
      {
        // GenerateFieldAccessors reads (some of) the initializer.
        AlternativeReadingScope alt(&helper_.reader_, field_initializer_offset);
        GenerateFieldAccessors(klass, field, &field_helper);
      }
      if ((FLAG_enable_mirrors || has_pragma_annotation) &&
          annotation_count > 0) {
        library.AddFieldMetadata(field, TokenPosition::kNoSource, field_offset);
      }
      fields_.Add(&field);
    }
    class_helper->SetJustRead(ClassHelper::kFields);

    if (klass.is_enum_class()) {
      // Add static field 'const _deleted_enum_sentinel'.
      // This field does not need to be of type E.
      Field& deleted_enum_sentinel = Field::ZoneHandle(Z);
      deleted_enum_sentinel = Field::New(
          Symbols::_DeletedEnumSentinel(),
          /* is_static = */ true,
          /* is_final = */ true,
          /* is_const = */ true,
          /* is_reflectable = */ false, klass, Object::dynamic_type(),
          TokenPosition::kNoSource, TokenPosition::kNoSource);
      fields_.Add(&deleted_enum_sentinel);
    }
    klass.AddFields(fields_);
  }

  class_helper->ReadUntilExcluding(ClassHelper::kConstructors);
  int constructor_count = helper_.ReadListLength();  // read list length.
  for (intptr_t i = 0; i < constructor_count; ++i) {
    intptr_t constructor_offset = helper_.ReaderOffset() - correction_offset_;
    ActiveMemberScope active_member_scope(&active_class_, NULL);
    ConstructorHelper constructor_helper(&helper_);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kAnnotations);
    intptr_t annotation_count = helper_.ReadListLength();
    bool has_pragma_annotation;
    {
      String& native_name_unused = String::Handle();
      bool is_potential_native_unused;
      ReadVMAnnotations(annotation_count, &native_name_unused,
                        &is_potential_native_unused, &has_pragma_annotation);
    }
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

    Function& function = Function::ZoneHandle(
        Z, Function::New(name, RawFunction::kConstructor,
                         false,  // is_static
                         constructor_helper.IsConst(),
                         false,  // is_abstract
                         constructor_helper.IsExternal(),
                         false,  // is_native
                         *owner, constructor_helper.start_position_));
    function.set_end_token_pos(constructor_helper.end_position_);
    functions_.Add(&function);
    function.set_kernel_offset(constructor_offset);
    function.set_result_type(T.ReceiverType(klass));
    function.set_has_pragma(has_pragma_annotation);

    FunctionNodeHelper function_node_helper(&helper_);
    function_node_helper.ReadUntilExcluding(
        FunctionNodeHelper::kTypeParameters);
    T.SetupFunctionParameters(klass, function,
                              true,   // is_method
                              false,  // is_closure
                              &function_node_helper);

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

    if ((FLAG_enable_mirrors || has_pragma_annotation) &&
        annotation_count > 0) {
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
    helper_.SetOffset(next_procedure_offset);
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
  const ExternalTypedData& library_kernel_data =
      ExternalTypedData::Handle(zone, library.kernel_data());
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

  kernel_loader.helper_.SetOffset(class_offset);
  ClassHelper class_helper(&kernel_loader.helper_);

  kernel_loader.FinishClassLoading(klass, library, toplevel_class, class_offset,
                                   class_index, &class_helper);
}

// Read annotations on a procedure to identify potential VM-specific directives.
//
// Output parameters:
//
//   `native_name`: non-null if `@ExternalName(...)` was identified.
//
//   `is_potential_native`: non-null if there may be an `@ExternalName(...)`
//   annotation and we need to re-try after reading the constants table.
//
//   `has_pragma_annotation`: non-null if @pragma(...) was found (no information
//   is given on the kind of pragma directive).
//
void KernelLoader::ReadVMAnnotations(intptr_t annotation_count,
                                     String* native_name,
                                     bool* is_potential_native,
                                     bool* has_pragma_annotation) {
  *is_potential_native = false;
  *has_pragma_annotation = false;
  String& detected_name = String::Handle(Z);
  for (intptr_t i = 0; i < annotation_count; ++i) {
    const intptr_t tag = helper_.PeekTag();
    if (tag == kConstructorInvocation || tag == kConstConstructorInvocation) {
      const intptr_t start = helper_.ReaderOffset();
      detected_name = DetectExternalNameCtor();
      if (!detected_name.IsNull()) {
        *native_name = detected_name.raw();
        continue;
      }

      helper_.SetOffset(start);
      if (DetectPragmaCtor()) {
        *has_pragma_annotation = true;
      }
    } else if (tag == kConstantExpression) {
      const Array& constant_table_array =
          Array::Handle(kernel_program_info_.constants());
      if (constant_table_array.IsNull()) {
        // We can only read in the constant table once all classes have been
        // finalized (otherwise we can't create instances of the classes!).
        //
        // We therefore delay the scanning for `ExternalName {name: ... }`
        // constants in the annotation list to later.
        *is_potential_native = true;

        ASSERT(kernel_program_info_.constants_table() !=
               ExternalTypedData::null());

        // For pragma annotations, we seek into the constants table and peek
        // into the Kernel representation of the constant.
        //
        // TODO(sjindel): Refactor `ExternalName` handling to do this as well
        // and avoid the "potential natives" list.

        helper_.ReadByte();  // Skip the tag.

        const intptr_t offset_in_constant_table = helper_.ReadUInt();

        AlternativeReadingScope scope(
            &helper_.reader_,
            &ExternalTypedData::Handle(Z,
                                       kernel_program_info_.constants_table()),
            0);

        // Seek into the position within the constant table where we can inspect
        // this constant's Kernel representation.
        helper_.ReadUInt();  // skip constant table size
        helper_.SkipBytes(offset_in_constant_table);
        uint8_t tag = helper_.ReadTag();
        if (tag == kInstanceConstant) {
          *has_pragma_annotation =
              *has_pragma_annotation ||
              IsClassName(helper_.ReadCanonicalNameReference(),
                          Symbols::DartCore(), Symbols::Pragma());
        }
      } else {
        KernelConstantsMap constant_table(constant_table_array.raw());
        helper_.ReadByte();  // Skip the tag.

        // Obtain `dart:_internal::ExternalName.name`.
        EnsureExternalClassIsLookedUp();

        // Obtain `dart:_internal::pragma`.
        EnsurePragmaClassIsLookedUp();

        const intptr_t constant_table_index = helper_.ReadUInt();
        const Object& constant =
            Object::Handle(constant_table.GetOrDie(constant_table_index));
        if (constant.clazz() == external_name_class_.raw()) {
          const Instance& instance =
              Instance::Handle(Instance::RawCast(constant.raw()));
          *native_name =
              String::RawCast(instance.GetField(external_name_field_));
        } else if (constant.clazz() == pragma_class_.raw()) {
          *has_pragma_annotation = true;
        }
        ASSERT(constant_table.Release().raw() == constant_table_array.raw());
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
  if (procedure_helper.IsRedirectingFactoryConstructor()) {
    helper_.SetOffset(procedure_end);
    return;
  }
  const String& name = H.DartProcedureName(procedure_helper.canonical_name_);
  bool is_method = in_class && !procedure_helper.IsStatic();
  bool is_abstract = procedure_helper.IsAbstract();
  bool is_external = procedure_helper.IsExternal();
  String& native_name = String::Handle(Z);
  bool is_potential_native;
  bool has_pragma_annotation;
  const intptr_t annotation_count = helper_.ReadListLength();
  ReadVMAnnotations(annotation_count, &native_name, &is_potential_native,
                    &has_pragma_annotation);
  // If this is a potential native, we'll unset is_external in
  // AnnotateNativeProcedures instead.
  is_external = is_external && native_name.IsNull();
  procedure_helper.SetJustRead(ProcedureHelper::kAnnotations);
  const Object& script_class =
      ClassForScriptAt(owner, procedure_helper.source_uri_index_);
  RawFunction::Kind kind = GetFunctionType(procedure_helper.kind_);

  // We do not register expression evaluation libraries with the VM:
  // The expression evaluation functions should be GC-able as soon as
  // they are not reachable anymore and we never look them up by name.
  const bool register_function = !name.Equals(Symbols::DebugProcedureName());

  Function& function = Function::ZoneHandle(
      Z, Function::New(name, kind,
                       !is_method,  // is_static
                       false,       // is_const
                       is_abstract, is_external,
                       !native_name.IsNull(),  // is_native
                       script_class, procedure_helper.start_position_));
  function.set_has_pragma(has_pragma_annotation);
  function.set_end_token_pos(procedure_helper.end_position_);
  if (register_function) {
    functions_.Add(&function);
  } else {
    expression_evaluation_function_ = function.raw();
  }
  function.set_kernel_offset(procedure_offset);
  if ((library.is_dart_scheme() &&
       H.IsPrivate(procedure_helper.canonical_name_)) ||
      (function.is_static() && (library.raw() == Library::InternalLibrary()))) {
    function.set_is_reflectable(false);
  }

  ActiveMemberScope active_member(&active_class_, &function);

  procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);

  Tag function_node_tag = helper_.ReadTag();
  ASSERT(function_node_tag == kSomething);
  FunctionNodeHelper function_node_helper(&helper_);
  function_node_helper.ReadUntilIncluding(FunctionNodeHelper::kDartAsyncMarker);
  // _AsyncAwaitCompleter.future should be made non-debuggable, otherwise
  // stepping out of async methods will keep hitting breakpoint resulting in
  // infinite loop.
  bool isAsyncAwaitCompleterFuture =
      Symbols::_AsyncAwaitCompleter().Equals(
          String::Handle(owner.ScrubbedName())) &&
      Symbols::CompleterGetFuture().Equals(String::Handle(function.name()));
  function.set_is_debuggable(function_node_helper.dart_async_marker_ ==
                                 FunctionNodeHelper::kSync &&
                             !isAsyncAwaitCompleterFuture);
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

  if (!native_name.IsNull()) {
    function.set_native_name(native_name);
  }
  if (is_potential_native) {
    EnsurePotentialNatives();
    potential_natives_.Add(function);
  }

  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kTypeParameters);
  T.SetupFunctionParameters(owner, function, is_method,
                            false,  // is_closure
                            &function_node_helper);

  // Everything else is skipped implicitly, and procedure_helper and
  // function_node_helper are no longer used.
  helper_.SetOffset(procedure_end);

  if (!in_class) {
    library.AddObject(function, name);
    ASSERT(!Object::Handle(
                Z, library.LookupObjectAllowPrivate(
                       H.DartProcedureName(procedure_helper.canonical_name_)))
                .IsNull());
  }

  if (annotation_count > 0) {
    library.AddFunctionMetadata(function, TokenPosition::kNoSource,
                                procedure_offset);
  }

  if (has_pragma_annotation) {
    if (kernel_program_info_.constants() == Array::null()) {
      EnsurePotentialPragmaFunctions();
      potential_pragma_functions_.Add(function);
    } else {
      Thread* thread = Thread::Current();
      NoOOBMessageScope no_msg_scope(thread);
      NoReloadScope no_reload_scope(thread->isolate(), thread);
      library.GetMetadata(function);
    }
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
      FixCoreLibraryScriptUri(Library::Handle(klass.library()), correct_script);
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
  const String& uri_string = helper_.SourceTableUriFor(index);
  String& sources = helper_.GetSourceFor(index);
  TypedData& line_starts =
      TypedData::Handle(Z, helper_.GetLineStartsFor(index));
  if (sources.Length() == 0 && line_starts.Length() == 0 &&
      uri_string.Length() > 0) {
    // Entry included only to provide URI - actual source should already exist
    // in the VM, so try to find it.
    Library& lib = Library::Handle(Z);
    Script& script = Script::Handle(Z);
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(isolate_->object_store()->libraries());
    for (intptr_t i = 0; i < libs.Length(); i++) {
      lib ^= libs.At(i);
      script = lib.LookupScript(uri_string, /* useResolvedUri = */ true);
      if (!script.IsNull() && script.kind() == RawScript::kKernelTag) {
        sources ^= script.Source();
        line_starts ^= script.line_starts();
        break;
      }
    }
  }

  const Script& script = Script::Handle(
      Z, Script::New(uri_string, sources, RawScript::kKernelTag));
  String& script_url = String::Handle();
  script_url = script.url();
  script.set_kernel_script_index(index);
  script.set_kernel_program_info(kernel_program_info_);
  script.set_line_starts(line_starts);
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
  Tag tag = helper_.PeekTag();
  if (field_helper->IsStatic() && tag == kNothing) {
    // Static fields without an initializer are implicitly initialized to null.
    // We do not need a getter.
    field.SetStaticValue(Instance::Handle(Z), true);
    return;
  }
  if (tag == kSomething) {
    SimpleExpressionConverter converter(&H, &helper_);
    const bool has_simple_initializer =
        converter.IsSimple(helper_.ReaderOffset() + 1);  // ignore the tag.
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
  const AbstractType& field_type = AbstractType::Handle(Z, field.type());
  getter.set_result_type(field_type);
  getter.set_is_debuggable(false);
  SetupFieldAccessorFunction(klass, getter, field_type);

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
    SetupFieldAccessorFunction(klass, setter, field_type);
  }
}

void KernelLoader::SetupFieldAccessorFunction(const Class& klass,
                                              const Function& function,
                                              const AbstractType& field_type) {
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
    function.SetParameterTypeAt(pos, field_type);
    function.SetParameterNameAt(pos, Symbols::Value());
    pos++;
  }
}

Library& KernelLoader::LookupLibraryOrNull(NameIndex library) {
  Library* handle = NULL;
  if (!libraries_.Lookup(library, &handle)) {
    const String& url = H.DartString(H.CanonicalNameString(library));
    handle = &Library::Handle(Z, Library::LookupLibrary(thread_, url));
    if (!handle->IsNull()) {
      libraries_.Insert(library, handle);
    }
  }
  return *handle;
}

Library& KernelLoader::LookupLibrary(NameIndex library) {
  Library* handle = NULL;
  if (!libraries_.Lookup(library, &handle)) {
    handle = &Library::Handle(Z);
    const String& url = H.DartSymbolPlain(H.CanonicalNameString(library));

    // We do not register expression evaluation libraries with the VM:
    // The expression evaluation functions should be GC-able as soon as
    // they are not reachable anymore and we never look them up by name.
    if (url.Equals(Symbols::EvalSourceUri())) {
      if (handle->IsNull()) {
        *handle = Library::New(url);
        expression_evaluation_library_ = handle->raw();
      }
    } else {
      *handle = Library::LookupLibrary(thread_, url);
      if (handle->IsNull()) {
        *handle = Library::New(url);
        handle->Register(thread_);
      }
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
      // We do not register expression evaluation classes with the VM:
      // The expression evaluation functions should be GC-able as soon as
      // they are not reachable anymore and we never look them up by name.
      const bool register_class =
          library.raw() != expression_evaluation_library_.raw();

      *handle = Class::New(library, name, Script::Handle(Z),
                           TokenPosition::kNoSource, register_class);
      if (register_class) {
        library.AddClass(*handle);
      }
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

RawFunction* CreateFieldInitializerFunction(Thread* thread,
                                            Zone* zone,
                                            const Field& field) {
  String& init_name = String::Handle(zone, field.name());
  init_name = Symbols::FromConcat(thread, Symbols::InitPrefix(), init_name);

  // Static field initializers are not added as members of their owning class,
  // so they must be pre-emptively given a patch class to avoid the meaning of
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
  const Function& initializer_fun = Function::Handle(
      zone, Function::New(init_name,
                          // TODO(alexmarkov): Consider creating a separate
                          // function kind for field initializers.
                          RawFunction::kImplicitStaticFinalGetter,
                          true,   // is_static
                          false,  // is_const
                          false,  // is_abstract
                          false,  // is_external
                          false,  // is_native
                          initializer_owner, TokenPosition::kNoSource));
  initializer_fun.set_kernel_offset(field.kernel_offset());
  initializer_fun.set_result_type(AbstractType::Handle(zone, field.type()));
  initializer_fun.set_is_debuggable(false);
  initializer_fun.set_is_reflectable(false);
  initializer_fun.set_is_inlinable(false);
  return initializer_fun.raw();
}

ParsedFunction* ParseStaticFieldInitializer(Zone* zone, const Field& field) {
  Thread* thread = Thread::Current();

  const Function& initializer_fun = Function::ZoneHandle(
      zone, CreateFieldInitializerFunction(thread, zone, field));

  return new (zone) ParsedFunction(thread, initializer_fun);
}

}  // namespace kernel
}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
