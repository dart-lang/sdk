// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_KERNEL_READER_H_
#define VM_KERNEL_READER_H_

#include <map>

#include "vm/kernel.h"
#include "vm/kernel_to_il.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class KernelReader;

class BuildingTranslationHelper : public TranslationHelper {
 public:
  BuildingTranslationHelper(KernelReader* reader, dart::Thread* thread,
                            dart::Zone* zone, Isolate* isolate)
      : TranslationHelper(thread, zone, isolate), reader_(reader) {}
  virtual ~BuildingTranslationHelper() {}

  virtual void SetFinalize(bool finalize);

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
  KernelReader(const uint8_t* buffer, intptr_t len, bool bootstrapping = false)
      : thread_(dart::Thread::Current()),
        zone_(thread_->zone()),
        isolate_(thread_->isolate()),
        translation_helper_(this, thread_, zone_, isolate_),
        type_translator_(&translation_helper_, &active_class_, !bootstrapping),
        bootstrapping_(bootstrapping),
        finalize_(!bootstrapping),
        buffer_(buffer),
        buffer_length_(len) {}

  // Returns either a library or a failure object.
  dart::Object& ReadProgram();

  static void SetupFunctionParameters(TranslationHelper translation_helper_,
                                      DartTypeTranslator type_translator_,
                                      const dart::Class& owner,
                                      const dart::Function& function,
                                      FunctionNode* kernel_function,
                                      bool is_method, bool is_closure);

  void ReadLibrary(Library* kernel_library);

 private:
  friend class BuildingTranslationHelper;

  void ReadPreliminaryClass(dart::Class* klass, Class* kernel_klass);
  void ReadClass(const dart::Library& library, Class* kernel_klass);
  void ReadProcedure(const dart::Library& library, const dart::Class& owner,
                     Procedure* procedure, Class* kernel_klass = NULL);

  void GenerateFieldAccessors(const dart::Class& klass,
                              const dart::Field& field, Field* kernel_field);

  void SetupFieldAccessorFunction(const dart::Class& klass,
                                  const dart::Function& function);

  dart::Library& LookupLibrary(Library* library);
  dart::Class& LookupClass(Class* klass);

  dart::RawFunction::Kind GetFunctionType(Procedure* kernel_procedure);

  dart::Thread* thread_;
  dart::Zone* zone_;
  dart::Isolate* isolate_;
  ActiveClass active_class_;
  BuildingTranslationHelper translation_helper_;
  DartTypeTranslator type_translator_;

  bool bootstrapping_;

  // Should created classes be finalized when they are created?
  bool finalize_;

  const uint8_t* buffer_;
  intptr_t buffer_length_;

  Mapping<Library, dart::Library> libraries_;
  Mapping<Class, dart::Class> classes_;
};

}  // namespace kernel
}  // namespace dart

#endif  // VM_KERNEL_READER_H_
