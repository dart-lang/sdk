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
  typedef ZoneGrowableHandlePtrArray<const AbstractType> PendingTypes;

  // Modes for finalization. The ordering is relevant.
  enum FinalizationKind {
    kFinalize,     // Finalize type and type arguments.
    kCanonicalize  // Finalize and canonicalize.
  };

  // Finalize given type.
  static AbstractTypePtr FinalizeType(
      const AbstractType& type,
      FinalizationKind finalization = kCanonicalize,
      PendingTypes* pending_types = NULL);

  // Finalize the types in the functions's signature.
  static void FinalizeSignature(const Function& function,
                                FinalizationKind finalization = kCanonicalize);

  // Return false if we still have classes pending to be finalized.
  static bool AllClassesFinalized();

  // Useful for sorting classes to make dispatch faster.
  static void SortClasses();
  static void RemapClassIds(intptr_t* old_to_new_cid);
  static void RehashTypes();
  static void ClearAllCode(bool including_nonchanging_cids = false);

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

  // Register class in the lists of direct subclasses and direct implementors.
  static void RegisterClassInHierarchy(Zone* zone, const Class& cls);

  // Ensures members of the class are loaded, class layout is finalized and size
  // registered in class table.
  static void FinalizeClass(const Class& cls);
  // Makes class instantiatable and usable by generated code.
  static ErrorPtr AllocateFinalizeClass(const Class& cls);

  // Completes loading of the class, this populates the function
  // and fields of the class.
  //
  // Returns Error::null() if there is no loading error.
  static ErrorPtr LoadClassMembers(const Class& cls);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Verify that the classes have been properly prefinalized. This is
  // needed during bootstrapping where the classes have been preloaded.
  static void VerifyBootstrapClasses();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

 private:
  static void AllocateEnumValues(const Class& enum_cls);
  static void FinalizeTypeParameters(const Class& cls);
  static intptr_t ExpandAndFinalizeTypeArguments(const AbstractType& type,
                                                 PendingTypes* pending_types);
  static void FinalizeTypeArguments(const Class& cls,
                                    const TypeArguments& arguments,
                                    intptr_t num_uninitialized_arguments,
                                    PendingTypes* pending_types,
                                    TrailPtr trail);
  static void CheckRecursiveType(const AbstractType& type,
                                 PendingTypes* pending_types);
  static void FinalizeUpperBounds(
      const Class& cls,
      FinalizationKind finalization = kCanonicalize);
  static void FinalizeMemberTypes(const Class& cls);
  static void PrintClassInformation(const Class& cls);

  static void ReportError(const Error& error);
  static void ReportError(const char* format, ...) PRINTF_ATTRIBUTE(1, 2);

  // Verify implicit offsets recorded in the VM for direct access to fields of
  // Dart instances (e.g: _TypedListView, _ByteDataView).
  static void VerifyImplicitFieldOffsets();
};

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_FINALIZER_H_
