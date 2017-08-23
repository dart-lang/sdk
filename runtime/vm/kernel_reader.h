// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_READER_H_
#define RUNTIME_VM_KERNEL_READER_H_

#if !defined(DART_PRECOMPILED_RUNTIME)
#include <map>

#include "vm/kernel.h"
#include "vm/kernel_binary_flowgraph.h"
#include "vm/kernel_to_il.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class KernelReader;

class BuildingTranslationHelper : public TranslationHelper {
 public:
  BuildingTranslationHelper(KernelReader* reader, Thread* thread)
      : TranslationHelper(thread), reader_(reader) {}
  virtual ~BuildingTranslationHelper() {}

  virtual RawLibrary* LookupLibraryByKernelLibrary(NameIndex library);
  virtual RawClass* LookupClassByKernelClass(NameIndex klass);

 private:
  KernelReader* reader_;
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

class KernelReader {
 public:
  explicit KernelReader(Program* program);

  // Returns the library containing the main procedure, null if there
  // was no main procedure, or a failure object if there was an error.
  Object& ReadProgram();

  // Finds all libraries that have been modified in this incremental
  // version of the kernel program file.
  void FindModifiedLibraries(Isolate* isolate,
                             BitVector* modified_libs,
                             bool force_reload);

  void ReadLibrary(intptr_t kernel_offset);

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
    reader.set_offset(reader.size() - 4 -
                      (program_->library_count() - index) * 4);
    return reader.ReadUInt32();
  }

  NameIndex library_canonical_name(intptr_t index) {
    kernel::Reader reader(program_->kernel_data(),
                          program_->kernel_data_size());
    reader.set_offset(reader.size() - 4 -
                      (program_->library_count() - index) * 4);
    reader.set_offset(reader.ReadUInt32());

    // Start reading library.
    reader.ReadFlags();
    return reader.ReadCanonicalNameReference();
  }

  uint8_t CharacterAt(StringIndex string_index, intptr_t index);

  static bool FieldHasFunctionLiteralInitializer(const Field& field,
                                                 TokenPosition* start,
                                                 TokenPosition* end);

 private:
  friend class BuildingTranslationHelper;

  void ReadPreliminaryClass(Class* klass,
                            ClassHelper* class_helper,
                            intptr_t type_parameter_count);
  Class& ReadClass(const Library& library, const Class& toplevel_class);
  void ReadProcedure(const Library& library, const Class& owner, bool in_class);

  void ReadAndSetupTypeParameters(const Object& set_on,
                                  intptr_t type_parameter_count,
                                  const Class& parameterized_class,
                                  const Function& parameterized_function);

  RawArray* MakeFunctionsArray();

  // If klass's script is not the script at the uri index, return a PatchClass
  // for klass whose script corresponds to the uri index.
  // Otherwise return klass.
  const Object& ClassForScriptAt(const Class& klass, intptr_t source_uri_index);
  Script& ScriptAt(intptr_t source_uri_index,
                   StringIndex import_uri = StringIndex());

  void GenerateFieldAccessors(const Class& klass,
                              const Field& field,
                              FieldHelper* field_helper,
                              intptr_t field_offset);

  void SetupFieldAccessorFunction(const Class& klass, const Function& function);

  Library& LookupLibrary(NameIndex library);
  Class& LookupClass(NameIndex klass);

  RawFunction::Kind GetFunctionType(ProcedureHelper::Kind procedure_kind);

  Program* program_;

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;
  Array& scripts_;
  Array& patch_classes_;
  ActiveClass active_class_;
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
#endif  // RUNTIME_VM_KERNEL_READER_H_
