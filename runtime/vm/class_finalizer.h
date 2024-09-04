// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLASS_FINALIZER_H_
#define RUNTIME_VM_CLASS_FINALIZER_H_

#include <memory>

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"

namespace dart {

// Traverses all pending, unfinalized classes, validates and marks them as
// finalized.
class ClassFinalizer : public AllStatic {
 public:
  // Modes for finalization. The ordering is relevant.
  enum FinalizationKind {
    kFinalize,     // Finalize type and type arguments.
    kCanonicalize  // Finalize and canonicalize.
  };

  // Finalize given type.
  static AbstractTypePtr FinalizeType(
      const AbstractType& type,
      FinalizationKind finalization = kCanonicalize);

  // Return false if we still have classes pending to be finalized.
  static bool AllClassesFinalized();

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Useful for sorting classes to make dispatch faster.
  static void SortClasses();
  static void RemapClassIds(intptr_t* old_to_new_cid);
  static void RehashTypes();
  static void ClearAllCode(bool including_nonchanging_cids = false);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Return whether processing pending classes (ObjectStore::pending_classes_)
  // failed. The function returns true if the processing was successful.
  // If processing fails, an error message is set in the sticky error field
  // in the object store.
  static bool ProcessPendingClasses();

  // Finalize the types appearing in the declaration of class 'cls', i.e. its
  // type parameters and their upper bounds, its super type and interfaces.
  // Note that the fields and functions have not been parsed yet (unless cls
  // is an anonymous top level class).
  static void FinalizeTypesInClass(const Class& cls);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Mark [cls], its superclass and superinterfaces as can_be_future().
  static void MarkClassCanBeFuture(Zone* zone, const Class& cls);

  // Mark [cls] and all its superclasses and superinterfaces as
  // has_dynamically_extendable_subtypes().
  static void MarkClassHasDynamicallyExtendableSubtypes(Zone* zone,
                                                        const Class& cls);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Ensures members of the class are loaded, class layout is finalized and size
  // registered in class table.
  static void FinalizeClass(const Class& cls);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Makes class instantiatable and usable by generated code.
  static ErrorPtr AllocateFinalizeClass(const Class& cls);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME) || defined(DART_DYNAMIC_MODULES)
  // Completes loading of the class, this populates the function
  // and fields of the class.
  //
  // Returns Error::null() if there is no loading error.
  static ErrorPtr LoadClassMembers(const Class& cls);
#endif  // !defined(DART_PRECOMPILED_RUNTIME) || defined(DART_DYNAMIC_MODULES)

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Verify that the classes have been properly prefinalized. This is
  // needed during bootstrapping where the classes have been preloaded.
  static void VerifyBootstrapClasses();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

 private:
  // Finalize given type argument vector.
  static TypeArgumentsPtr FinalizeTypeArguments(
      Zone* zone,
      const TypeArguments& type_args,
      FinalizationKind finalization = kCanonicalize);

  static void FinalizeTypeParameters(Zone* zone,
                                     const TypeParameters& type_params,
                                     FinalizationKind finalization);

#if !defined(DART_PRECOMPILED_RUNTIME) || defined(DART_DYNAMIC_MODULES)
  static void FinalizeMemberTypes(const Class& cls);
#endif  // !defined(DART_PRECOMPILED_RUNTIME) || defined(DART_DYNAMIC_MODULES)
#if !defined(DART_PRECOMPILED_RUNTIME)
  static void PrintClassInformation(const Class& cls);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  static void ReportError(const Error& error);
  static void ReportError(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Verify implicit offsets recorded in the VM for direct access to fields of
  // Dart instances (e.g: _TypedListView, _ByteDataView).
  static void VerifyImplicitFieldOffsets();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};

class ClassHiearchyUpdater : public ValueObject {
 public:
  explicit ClassHiearchyUpdater(Zone* zone) : zone_(zone) {}

  // Register class in the lists of direct subclasses and direct implementors.
  void Register(const Class& cls);

 private:
  void MarkImplemented(const Class& interface);

  Zone* const zone_;

  AbstractType& type_ = AbstractType::Handle(zone_);
  Class& super_ = Class::Handle(zone_);
  Class& implemented_ = Class::Handle(zone_);
  Class& interface_ = Class::Handle(zone_);
  Array& interfaces_ = Array::Handle(zone_);

  class ClassWorklist {
   public:
    explicit ClassWorklist(Zone* zone) : zone_(zone) {}

    bool IsEmpty() const { return size_ == 0; }

    void Add(const Class& cls) {
      if (worklist_.length() == size_) {
        worklist_.Add(&Class::Handle(zone_));
      }
      *worklist_[size_] = cls.ptr();
      size_++;
    }

    ClassPtr RemoveLast() {
      size_--;
      return worklist_[size_]->ptr();
    }

   private:
    Zone* const zone_;
    GrowableArray<Class*> worklist_;
    intptr_t size_ = 0;
  };

  ClassWorklist worklist_{zone_};
};

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_FINALIZER_H_
