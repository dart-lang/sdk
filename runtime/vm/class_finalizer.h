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
  // Register class in the lists of direct subclasses and direct implementors.
  static void RegisterClassInHierarchy(Zone* zone, const Class& cls);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Ensures members of the class are loaded, class layout is finalized and size
  // registered in class table.
  static void FinalizeClass(const Class& cls);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Makes class instantiatable and usable by generated code.
  static ErrorPtr AllocateFinalizeClass(const Class& cls);

  // Completes loading of the class, this populates the function
  // and fields of the class.
  //
  // Returns Error::null() if there is no loading error.
  static ErrorPtr LoadClassMembers(const Class& cls);

  // Verify that the classes have been properly prefinalized. This is
  // needed during bootstrapping where the classes have been preloaded.
  static void VerifyBootstrapClasses();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

 private:
  // Finalize given type argument vector.
  static TypeArgumentsPtr FinalizeTypeArguments(
      Zone* zone,
      const TypeArguments& type_args,
      FinalizationKind finalization = kCanonicalize,
      PendingTypes* pending_types = NULL);

  // Finalize the types in the signature and the signature itself.
  static AbstractTypePtr FinalizeSignature(
      Zone* zone,
      const FunctionType& signature,
      FinalizationKind finalization = kCanonicalize,
      PendingTypes* pending_types = NULL);

#if !defined(DART_PRECOMPILED_RUNTIME)
  static void AllocateEnumValues(const Class& enum_cls);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  static void FinalizeTypeParameters(
      Zone* zone,
      const Class& cls,
      const FunctionType& signature,
      FinalizationKind finalization = kCanonicalize,
      PendingTypes* pending_types = NULL);

  static intptr_t ExpandAndFinalizeTypeArguments(Zone* zone,
                                                 const AbstractType& type,
                                                 PendingTypes* pending_types);
  static void FillAndFinalizeTypeArguments(Zone* zone,
                                           const Class& cls,
                                           const TypeArguments& arguments,
                                           intptr_t num_uninitialized_arguments,
                                           PendingTypes* pending_types,
                                           TrailPtr trail);
  static void CheckRecursiveType(const AbstractType& type,
                                 PendingTypes* pending_types);

#if !defined(DART_PRECOMPILED_RUNTIME)
  static void FinalizeMemberTypes(const Class& cls);
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

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_FINALIZER_H_
