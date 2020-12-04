// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_LOADER_H_
#define RUNTIME_VM_KERNEL_LOADER_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/bit_vector.h"
#include "vm/compiler/frontend/constant_reader.h"
#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/hash_map.h"
#include "vm/kernel.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {
namespace kernel {

class KernelLoader;

class BuildingTranslationHelper : public TranslationHelper {
 public:
  BuildingTranslationHelper(KernelLoader* loader,
                            Thread* thread,
                            Heap::Space space)
      : TranslationHelper(thread, space),
        loader_(loader),
        library_lookup_handle_(Library::Handle(thread->zone())) {}
  virtual ~BuildingTranslationHelper() {}

  virtual LibraryPtr LookupLibraryByKernelLibrary(NameIndex library);
  virtual ClassPtr LookupClassByKernelClass(NameIndex klass);

 private:
  KernelLoader* loader_;

#if defined(DEBUG)
  class LibraryLookupHandleScope {
   public:
    explicit LibraryLookupHandleScope(Library& lib) : lib_(lib) {
      ASSERT(lib_.IsNull());
    }

    ~LibraryLookupHandleScope() { lib_ = Library::null(); }

   private:
    Library& lib_;

    DISALLOW_COPY_AND_ASSIGN(LibraryLookupHandleScope);
  };
#endif  // defined(DEBUG)

  // Preallocated handle for use in LookupClassByKernelClass().
  Library& library_lookup_handle_;

  DISALLOW_COPY_AND_ASSIGN(BuildingTranslationHelper);
};

template <typename VmType>
class Mapping {
 public:
  bool Lookup(intptr_t canonical_name, VmType** handle) {
    typename MapType::Pair* pair = map_.LookupPair(canonical_name);
    if (pair != NULL) {
      *handle = pair->value;
      return true;
    }
    return false;
  }

  void Insert(intptr_t canonical_name, VmType* object) {
    map_.Insert(canonical_name, object);
  }

 private:
  typedef IntMap<VmType*> MapType;
  MapType map_;
};

class LibraryIndex {
 public:
  // |kernel_data| is the kernel data for one library alone.
  explicit LibraryIndex(const ExternalTypedData& kernel_data,
                        uint32_t binary_version);

  intptr_t class_count() const { return class_count_; }
  intptr_t procedure_count() const { return procedure_count_; }

  intptr_t ClassOffset(intptr_t index) const {
    return reader_.ReadUInt32At(class_index_offset_ + index * 4);
  }

  intptr_t ProcedureOffset(intptr_t index) const {
    return reader_.ReadUInt32At(procedure_index_offset_ + index * 4);
  }

  intptr_t SizeOfClassAtOffset(intptr_t class_offset) const {
    for (intptr_t i = 0, offset = class_index_offset_; i < class_count_;
         ++i, offset += 4) {
      if (static_cast<intptr_t>(reader_.ReadUInt32At(offset)) == class_offset) {
        return reader_.ReadUInt32At(offset + 4) - class_offset;
      }
    }
    UNREACHABLE();
    return -1;
  }

  intptr_t SourceReferencesOffset() { return source_references_offset_; }

 private:
  Reader reader_;
  uint32_t binary_version_;
  intptr_t source_references_offset_;
  intptr_t class_index_offset_;
  intptr_t class_count_;
  intptr_t procedure_index_offset_;
  intptr_t procedure_count_;

  DISALLOW_COPY_AND_ASSIGN(LibraryIndex);
};

class ClassIndex {
 public:
  // |class_offset| is the offset of class' kernel data in |buffer| of
  // size |size|. The size of the class' kernel data is |class_size|.
  ClassIndex(const uint8_t* buffer,
             intptr_t buffer_size,
             intptr_t class_offset,
             intptr_t class_size);

  // |class_offset| is the offset of class' kernel data in |kernel_data|.
  // The size of the class' kernel data is |class_size|.
  ClassIndex(const ExternalTypedData& kernel_data,
             intptr_t class_offset,
             intptr_t class_size);

  intptr_t procedure_count() const { return procedure_count_; }

  intptr_t ProcedureOffset(intptr_t index) const {
    return reader_.ReadUInt32At(procedure_index_offset_ + index * 4);
  }

 private:
  void Init(intptr_t class_offset, intptr_t class_size);

  Reader reader_;
  intptr_t procedure_count_;
  intptr_t procedure_index_offset_;

  DISALLOW_COPY_AND_ASSIGN(ClassIndex);
};

struct UriToSourceTableEntry : public ZoneAllocated {
  UriToSourceTableEntry() {}

  const String* uri = nullptr;
  const String* sources = nullptr;
  const TypedData* line_starts = nullptr;
};

struct UriToSourceTableTrait {
  typedef UriToSourceTableEntry* Value;
  typedef const UriToSourceTableEntry* Key;
  typedef UriToSourceTableEntry* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->uri->Hash(); }

  static inline bool IsKeyEqual(Pair kv, Key key) {
    // Only compare uri.
    return kv->uri->CompareTo(*key->uri) == 0;
  }
};

class KernelLoader : public ValueObject {
 public:
  explicit KernelLoader(
      Program* program,
      DirectChainedHashMap<UriToSourceTableTrait>* uri_to_source_table);
  static Object& LoadEntireProgram(Program* program,
                                   bool process_pending_classes = true);

  // Returns the library containing the main procedure, null if there
  // was no main procedure, or a failure object if there was an error.
  ObjectPtr LoadProgram(bool process_pending_classes = true);

  // Load given library.
  void LoadLibrary(const Library& library);

  // Returns the function which will evaluate the expression, or a failure
  // object if there was an error.
  ObjectPtr LoadExpressionEvaluationFunction(const String& library_url,
                                             const String& klass);

  // Finds all libraries that have been modified in this incremental
  // version of the kernel program file.
  //
  // When [force_reload] is false and if [p_num_classes], [p_num_procedures] are
  // not nullptr, then they are populated with number of classes and top-level
  // procedures in [program].
  static void FindModifiedLibraries(Program* program,
                                    Isolate* isolate,
                                    BitVector* modified_libs,
                                    bool force_reload,
                                    bool* is_empty_program,
                                    intptr_t* p_num_classes,
                                    intptr_t* p_num_procedures);

  static StringPtr FindSourceForScript(const uint8_t* kernel_buffer,
                                       intptr_t kernel_buffer_length,
                                       const String& url);

  void FinishTopLevelClassLoading(const Class& toplevel_class,
                                  const Library& library,
                                  const LibraryIndex& library_index);

  static void FinishLoading(const Class& klass);

  void ReadObfuscationProhibitions();
  void ReadLoadingUnits();

 private:
  // Check for the presence of a (possibly const) constructor for the
  // 'ExternalName' class. If found, returns the name parameter to the
  // constructor.
  StringPtr DetectExternalNameCtor();

  // Check for the presence of a (possibly const) constructor for the 'pragma'
  // class. Returns whether it was found (no details about the type of pragma).
  bool DetectPragmaCtor();

  bool IsClassName(NameIndex name, const String& library, const String& klass);

  void AnnotateNativeProcedures();
  void LoadNativeExtensionLibraries();
  void LoadNativeExtension(const Library& library, const String& uri_path);
  void EvaluateDelayedPragmas();

  void ReadVMAnnotations(const Library& library,
                         intptr_t annotation_count,
                         String* native_name,
                         bool* is_potential_native,
                         bool* has_pragma_annotation);

  KernelLoader(const Script& script,
               const ExternalTypedData& kernel_data,
               intptr_t data_program_offset,
               uint32_t kernel_binary_version);

  void InitializeFields(
      DirectChainedHashMap<UriToSourceTableTrait>* uri_to_source_table);

  LibraryPtr LoadLibrary(intptr_t index);

  const String& LibraryUri(intptr_t library_index) {
    return translation_helper_.DartSymbolPlain(
        translation_helper_.CanonicalNameString(
            library_canonical_name(library_index)));
  }

  intptr_t library_offset(intptr_t index) {
    kernel::Reader reader(program_->kernel_data(),
                          program_->kernel_data_size());
    return reader.ReadFromIndexNoReset(reader.size(),
                                       LibraryCountFieldCountFromEnd + 1,
                                       program_->library_count() + 1, index);
  }

  NameIndex library_canonical_name(intptr_t index) {
    kernel::Reader reader(program_->kernel_data(),
                          program_->kernel_data_size());
    reader.set_offset(library_offset(index));

    // Start reading library.
    // Note that this needs to be keep in sync with LibraryHelper.
    reader.ReadFlags();
    reader.ReadUInt();  // Read major language version.
    reader.ReadUInt();  // Read minor language version.
    return reader.ReadCanonicalNameReference();
  }

  uint8_t CharacterAt(StringIndex string_index, intptr_t index);

  static void index_programs(kernel::Reader* reader,
                             GrowableArray<intptr_t>* subprogram_file_starts);
  void walk_incremental_kernel(BitVector* modified_libs,
                               bool* is_empty_program,
                               intptr_t* p_num_classes,
                               intptr_t* p_num_procedures);

  void LoadPreliminaryClass(ClassHelper* class_helper,
                            intptr_t type_parameter_count);

  void ReadInferredType(const Field& field, intptr_t kernel_offset);
  void CheckForInitializer(const Field& field);

  void LoadClass(const Library& library,
                 const Class& toplevel_class,
                 intptr_t class_end,
                 Class* out_class);

  void FinishClassLoading(const Class& klass,
                          const Library& library,
                          const Class& toplevel_class,
                          intptr_t class_offset,
                          const ClassIndex& class_index,
                          ClassHelper* class_helper);

  void LoadProcedure(const Library& library,
                     const Class& owner,
                     bool in_class,
                     intptr_t procedure_end);

  ArrayPtr MakeFieldsArray();
  ArrayPtr MakeFunctionsArray();

  ScriptPtr LoadScriptAt(
      intptr_t index,
      DirectChainedHashMap<UriToSourceTableTrait>* uri_to_source_table);

  // If klass's script is not the script at the uri index, return a PatchClass
  // for klass whose script corresponds to the uri index.
  // Otherwise return klass.
  const Object& ClassForScriptAt(const Class& klass, intptr_t source_uri_index);
  ScriptPtr ScriptAt(intptr_t source_uri_index) {
    return kernel_program_info_.ScriptAt(source_uri_index);
  }

  // Returns the initial field value for a static function (if applicable).
  InstancePtr GenerateFieldAccessors(const Class& klass,
                                     const Field& field,
                                     FieldHelper* field_helper);
  bool FieldNeedsSetter(FieldHelper* field_helper);

  void LoadLibraryImportsAndExports(Library* library,
                                    const Class& toplevel_class);

  LibraryPtr LookupLibraryOrNull(NameIndex library);
  LibraryPtr LookupLibrary(NameIndex library);
  LibraryPtr LookupLibraryFromClass(NameIndex klass);
  ClassPtr LookupClass(const Library& library, NameIndex klass);

  FunctionLayout::Kind GetFunctionType(ProcedureHelper::Kind procedure_kind);

  void EnsureExternalClassIsLookedUp() {
    if (external_name_class_.IsNull()) {
      ASSERT(external_name_field_.IsNull());
      const Library& internal_lib =
          Library::Handle(zone_, dart::Library::InternalLibrary());
      external_name_class_ = internal_lib.LookupClass(Symbols::ExternalName());
      external_name_field_ = external_name_class_.LookupField(Symbols::name());
    }
    ASSERT(!external_name_class_.IsNull());
    ASSERT(!external_name_field_.IsNull());
    ASSERT(external_name_class_.is_declaration_loaded());
  }

  void EnsurePragmaClassIsLookedUp() {
    if (pragma_class_.IsNull()) {
      const Library& core_lib =
          Library::Handle(zone_, dart::Library::CoreLibrary());
      pragma_class_ = core_lib.LookupLocalClass(Symbols::Pragma());
    }
    ASSERT(!pragma_class_.IsNull());
    ASSERT(pragma_class_.is_declaration_loaded());
  }

  void EnsurePotentialNatives() {
    potential_natives_ = kernel_program_info_.potential_natives();
    if (potential_natives_.IsNull()) {
      // To avoid too many grows in this array, we'll set it's initial size to
      // something close to the actual number of potential native functions.
      potential_natives_ = GrowableObjectArray::New(100, Heap::kNew);
      kernel_program_info_.set_potential_natives(potential_natives_);
    }
  }

  void EnsurePotentialPragmaFunctions() {
    potential_pragma_functions_ =
        translation_helper_.EnsurePotentialPragmaFunctions();
  }

  Program* program_;

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;
  Array& patch_classes_;
  ActiveClass active_class_;
  // This is the offset of the current library within
  // the whole kernel program.
  intptr_t library_kernel_offset_;
  uint32_t kernel_binary_version_;
  // This is the offset by which offsets, which are set relative
  // to their library's kernel data, have to be corrected.
  intptr_t correction_offset_;
  bool loading_native_wrappers_library_;

  NameIndex skip_vmservice_library_;

  ExternalTypedData& library_kernel_data_;
  KernelProgramInfo& kernel_program_info_;
  BuildingTranslationHelper translation_helper_;
  KernelReaderHelper helper_;
  ConstantReader constant_reader_;
  TypeTranslator type_translator_;
  InferredTypeMetadataHelper inferred_type_metadata_helper_;

  Class& external_name_class_;
  Field& external_name_field_;
  GrowableObjectArray& potential_natives_;
  GrowableObjectArray& potential_pragma_functions_;
  Instance& static_field_value_;

  Class& pragma_class_;

  Smi& name_index_handle_;

  // We "re-use" the normal .dill file format for encoding compiled evaluation
  // expressions from the debugger.  This allows us to also reuse the normal
  // a) kernel loader b) flow graph building code.  The encoding is either one
  // of the following two options:
  //
  //   * Option a) The expression is evaluated inside an instance method call
  //               context:
  //
  //   Program:
  //   |> library "evaluate:source"
  //      |> class "#DebugClass"
  //         |> procedure ":Eval"
  //
  //   * Option b) The expression is evaluated outside an instance method call
  //               context:
  //
  //   Program:
  //   |> library "evaluate:source"
  //      |> procedure ":Eval"
  //
  // See
  //   * pkg/front_end/lib/src/fasta/incremental_compiler.dart,
  //       compileExpression
  //   * pkg/front_end/lib/src/fasta/kernel/utils.dart,
  //       createExpressionEvaluationComponent
  //
  Library& expression_evaluation_library_;

  GrowableArray<const Function*> functions_;
  GrowableArray<const Field*> fields_;

  friend class BuildingTranslationHelper;

  DISALLOW_COPY_AND_ASSIGN(KernelLoader);
};

FunctionPtr CreateFieldInitializerFunction(Thread* thread,
                                           Zone* zone,
                                           const Field& field);

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_LOADER_H_
