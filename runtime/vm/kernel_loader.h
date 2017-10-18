// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_LOADER_H_
#define RUNTIME_VM_KERNEL_LOADER_H_

#if !defined(DART_PRECOMPILED_RUNTIME)
#include <map>

#include "vm/compiler/frontend/kernel_binary_flowgraph.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/kernel.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class KernelLoader;

class BuildingTranslationHelper : public TranslationHelper {
 public:
  BuildingTranslationHelper(KernelLoader* loader, Thread* thread)
      : TranslationHelper(thread), loader_(loader) {}
  virtual ~BuildingTranslationHelper() {}

  virtual RawLibrary* LookupLibraryByKernelLibrary(NameIndex library);
  virtual RawClass* LookupClassByKernelClass(NameIndex klass);

 private:
  KernelLoader* loader_;
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

class KernelLoader {
 public:
  explicit KernelLoader(Program* program);

  // Returns the library containing the main procedure, null if there
  // was no main procedure, or a failure object if there was an error.
  Object& LoadProgram();

  // Finds all libraries that have been modified in this incremental
  // version of the kernel program file.
  void FindModifiedLibraries(Isolate* isolate,
                             BitVector* modified_libs,
                             bool force_reload);

  void LoadLibrary(intptr_t index);

  const String& DartSymbol(StringIndex index) {
    return translation_helper_.DartSymbol(index);
  }

  const String& LibraryUri(intptr_t library_index) {
    return translation_helper_.DartSymbol(
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
    reader.ReadFlags();
    return reader.ReadCanonicalNameReference();
  }

  uint8_t CharacterAt(StringIndex string_index, intptr_t index);

 private:
  friend class BuildingTranslationHelper;

  void LoadPreliminaryClass(ClassHelper* class_helper,
                            intptr_t type_parameter_count);
  Class& LoadClass(const Library& library,
                   const Class& toplevel_class,
                   intptr_t class_end);
  void LoadProcedure(const Library& library,
                     const Class& owner,
                     bool in_class,
                     intptr_t procedure_end);

  RawArray* MakeFunctionsArray();

  RawScript* LoadScriptAt(intptr_t index);

  // If klass's script is not the script at the uri index, return a PatchClass
  // for klass whose script corresponds to the uri index.
  // Otherwise return klass.
  const Object& ClassForScriptAt(const Class& klass, intptr_t source_uri_index);
  RawScript* ScriptAt(intptr_t source_uri_index,
                      StringIndex import_uri = StringIndex());

  void GenerateFieldAccessors(const Class& klass,
                              const Field& field,
                              FieldHelper* field_helper);

  void SetupFieldAccessorFunction(const Class& klass, const Function& function);

  void LoadLibraryImportsAndExports(Library* library);

  Library& LookupLibrary(NameIndex library);
  Class& LookupClass(NameIndex klass);

  RawFunction::Kind GetFunctionType(ProcedureHelper::Kind procedure_kind);

  Program* program_;

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;
  Array& patch_classes_;
  ActiveClass active_class_;
  intptr_t library_kernel_offset_;
  TypedData& library_kernel_data_;
  KernelProgramInfo& kernel_program_info_;
  BuildingTranslationHelper translation_helper_;
  StreamingFlowGraphBuilder builder_;

  Mapping<Library> libraries_;
  Mapping<Class> classes_;

  GrowableArray<const Function*> functions_;
  GrowableArray<const Field*> fields_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_LOADER_H_
