// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_READER_H_
#define RUNTIME_VM_KERNEL_READER_H_

#if !defined(DART_PRECOMPILED_RUNTIME)
#include <map>

#include "vm/kernel.h"
#include "vm/kernel_to_il.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class KernelReader;

class BuildingTranslationHelper : public TranslationHelper {
 public:
  BuildingTranslationHelper(KernelReader* reader,
                            dart::Thread* thread,
                            dart::Zone* zone,
                            Isolate* isolate)
      : TranslationHelper(thread, zone, isolate), reader_(reader) {}
  virtual ~BuildingTranslationHelper() {}

  virtual RawLibrary* LookupLibraryByKernelLibrary(Library* library);
  virtual RawClass* LookupClassByKernelClass(Class* klass);

 private:
  KernelReader* reader_;
};

template <typename KernelType, typename VmType>
class Mapping {
 public:
  bool Lookup(KernelType* node, VmType** handle) {
    typename MapType::iterator value = map_.find(node);
    if (value != map_.end()) {
      *handle = value->second;
      return true;
    }
    return false;
  }

  void Insert(KernelType* node, VmType* object) { map_[node] = object; }

 private:
  typedef typename std::map<KernelType*, VmType*> MapType;
  MapType map_;
};

class KernelReader {
 public:
  KernelReader(const uint8_t* buffer, intptr_t len)
      : thread_(dart::Thread::Current()),
        zone_(thread_->zone()),
        isolate_(thread_->isolate()),
        scripts_(Array::ZoneHandle(zone_)),
        program_(NULL),
        translation_helper_(this, thread_, zone_, isolate_),
        type_translator_(&translation_helper_,
                         &active_class_,
                         /*finalize=*/false),
        buffer_(buffer),
        buffer_length_(len) {}

  // Returns either pointer to a program or null.
  Program* ReadPrecompiledProgram();

  // Returns either a library or a failure object.
  dart::Object& ReadProgram();

  static void SetupFunctionParameters(TranslationHelper translation_helper_,
                                      DartTypeTranslator type_translator_,
                                      const dart::Class& owner,
                                      const dart::Function& function,
                                      FunctionNode* kernel_function,
                                      bool is_method,
                                      bool is_closure);

  void ReadLibrary(Library* kernel_library);

 private:
  friend class BuildingTranslationHelper;

  void ReadPreliminaryClass(dart::Class* klass, Class* kernel_klass);
  dart::Class& ReadClass(const dart::Library& library, Class* kernel_klass);
  void ReadProcedure(const dart::Library& library,
                     const dart::Class& owner,
                     Procedure* procedure,
                     Class* kernel_klass = NULL);

  // If klass's script is not the script at the uri index, return a PatchClass
  // for klass whose script corresponds to the uri index.
  // Otherwise return klass.
  const Object& ClassForScriptAt(const dart::Class& klass,
                                 intptr_t source_uri_index);
  Script& ScriptAt(intptr_t source_uri_index);

  void GenerateFieldAccessors(const dart::Class& klass,
                              const dart::Field& field,
                              Field* kernel_field);

  void SetupFieldAccessorFunction(const dart::Class& klass,
                                  const dart::Function& function);

  dart::Library& LookupLibrary(Library* library);
  dart::Class& LookupClass(Class* klass);

  dart::RawFunction::Kind GetFunctionType(Procedure* kernel_procedure);

  dart::Thread* thread_;
  dart::Zone* zone_;
  dart::Isolate* isolate_;
  Array& scripts_;
  Program* program_;
  ActiveClass active_class_;
  BuildingTranslationHelper translation_helper_;
  DartTypeTranslator type_translator_;

  const uint8_t* buffer_;
  intptr_t buffer_length_;

  Mapping<Library, dart::Library> libraries_;
  Mapping<Class, dart::Class> classes_;
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_READER_H_
