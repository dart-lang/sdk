// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLASS_FINALIZER_H_
#define RUNTIME_VM_CLASS_FINALIZER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"

namespace dart {

// Traverses all pending, unfinalized classes, validates and marks them as
// finalized.
class ClassFinalizer : public AllStatic {
 public:
  typedef ZoneGrowableHandlePtrArray<const AbstractType> PendingTypes;

  // Modes for type resolution and finalization. The ordering is relevant.
  enum FinalizationKind {
    kIgnore,                 // Type is ignored and replaced by dynamic.
    kDoNotResolve,           // Type resolution is postponed.
    kResolveTypeParameters,  // Resolve type parameters only.
    kFinalize,               // Resolve and finalize type and type arguments.
    kCanonicalize            // Finalize, check bounds, and canonicalize.
  };

  // Finalize given type while parsing class cls.
  // Also canonicalize and bound check type if applicable.
  static RawAbstractType* FinalizeType(
      const Class& cls,
      const AbstractType& type,
      FinalizationKind finalization = kCanonicalize,
      PendingTypes* pending_types = NULL);

  // Finalize the types in the functions's signature while parsing class cls.
  static void FinalizeSignature(const Class& cls,
                                const Function& function,
                                FinalizationKind finalization = kCanonicalize);

  // Allocate, finalize, and return a new malformed type as if it was declared
  // in class cls at the given token position.
  // If not null, prepend prev_error to the error message built from the format
  // string and its arguments.
  static RawType* NewFinalizedMalformedType(const Error& prev_error,
                                            const Script& script,
                                            TokenPosition type_pos,
                                            const char* format,
                                            ...) PRINTF_ATTRIBUTE(4, 5);

  // Mark the given type as malformed.
  // If not null, prepend prev_error to the error message built from the format
  // string and its arguments.
  static void FinalizeMalformedType(const Error& prev_error,
                                    const Script& script,
                                    const Type& type,
                                    const char* format,
                                    ...) PRINTF_ATTRIBUTE(4, 5);

  // Mark the given type as malbounded.
  // If not null, prepend prev_error to the error message built from the format
  // string and its arguments.
  static void FinalizeMalboundedType(const Error& prev_error,
                                     const Script& script,
                                     const AbstractType& type,
                                     const char* format,
                                     ...) PRINTF_ATTRIBUTE(4, 5);

  // Return false if we still have classes pending to be finalized.
  static bool AllClassesFinalized();

  // Useful for sorting classes to make dispatch faster.
  static void SortClasses();
  static void RemapClassIds(intptr_t* old_to_new_cid);
  static void RehashTypes();
  static void ClearAllCode();

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

  // Finalize the class including its fields and functions.
  static void FinalizeClass(const Class& cls);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Verify that the classes have been properly prefinalized. This is
  // needed during bootstrapping where the classes have been preloaded.
  static void VerifyBootstrapClasses();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Resolve the class of the type, but not the type's type arguments.
  // May promote the type to function type by setting its signature field.
  static void ResolveTypeClass(const Class& cls, const Type& type);

  // Resolve the type and target of the redirecting factory.
  static void ResolveRedirectingFactory(const Class& cls,
                                        const Function& factory);

  // Apply the mixin type to the mixin application class.
  static void ApplyMixinType(const Class& mixin_app_class,
                             PendingTypes* pending_types = NULL);

 private:
  static void AllocateEnumValues(const Class& enum_cls);
  static bool IsSuperCycleFree(const Class& cls);
  static bool IsTypedefCycleFree(const Class& cls,
                                 const AbstractType& type,
                                 GrowableArray<intptr_t>* visited);
  static bool IsMixinCycleFree(const Class& cls,
                               GrowableArray<intptr_t>* visited);
  static void CheckForLegalConstClass(const Class& cls);
  static RawClass* ResolveClass(const Class& cls,
                                const UnresolvedClass& unresolved_class);
  static void ResolveType(const Class& cls, const AbstractType& type);
  static void ResolveRedirectingFactoryTarget(
      const Class& cls,
      const Function& factory,
      const GrowableObjectArray& visited_factories);
  static void CloneMixinAppTypeParameters(const Class& mixin_app_class);
  static void ApplyMixinAppAlias(const Class& mixin_app_class,
                                 const TypeArguments& instantiator);
  static void ApplyMixinMembers(const Class& cls);
  static void CreateForwardingConstructors(
      const Class& mixin_app,
      const Class& mixin_cls,
      const GrowableObjectArray& cloned_funcs);
  static void CollectTypeArguments(const Class& cls,
                                   const Type& type,
                                   const GrowableObjectArray& collected_args);
  static RawType* ResolveMixinAppType(const Class& cls,
                                      const MixinAppType& mixin_app_type);
  static void ResolveSuperTypeAndInterfaces(const Class& cls,
                                            GrowableArray<intptr_t>* visited);
  static void FinalizeTypeParameters(const Class& cls,
                                     PendingTypes* pending_types = NULL);
  static intptr_t ExpandAndFinalizeTypeArguments(const Class& cls,
                                                 const AbstractType& type,
                                                 PendingTypes* pending_types);
  static void FinalizeTypeArguments(const Class& cls,
                                    const TypeArguments& arguments,
                                    intptr_t num_uninitialized_arguments,
                                    Error* bound_error,
                                    PendingTypes* pending_types,
                                    TrailPtr trail);
  static void CheckRecursiveType(const Class& cls,
                                 const AbstractType& type,
                                 PendingTypes* pending_types);
  static void CheckTypeBounds(const Class& cls, const AbstractType& type);
  static void CheckTypeArgumentBounds(const Class& cls,
                                      const TypeArguments& arguments,
                                      Error* bound_error);
  static void ResolveUpperBounds(const Class& cls);
  static void FinalizeUpperBounds(
      const Class& cls,
      FinalizationKind finalization = kCanonicalize);
  static void ResolveSignature(const Class& cls, const Function& function);
  static void ResolveAndFinalizeMemberTypes(const Class& cls);
  static void PrintClassInformation(const Class& cls);
  static void CollectInterfaces(const Class& cls,
                                GrowableArray<const Class*>* collected);

  static void MarkTypeMalformed(const Error& prev_error,
                                const Script& script,
                                const Type& type,
                                const char* format,
                                va_list args);
  static void ReportError(const Error& error);
  static void ReportError(const Class& cls,
                          TokenPosition token_pos,
                          const char* format,
                          ...) PRINTF_ATTRIBUTE(3, 4);
  static void ReportErrors(const Error& prev_error,
                           const Class& cls,
                           TokenPosition token_pos,
                           const char* format,
                           ...) PRINTF_ATTRIBUTE(4, 5);

  // Verify implicit offsets recorded in the VM for direct access to fields of
  // Dart instances (e.g: _TypedListView, _ByteDataView).
  static void VerifyImplicitFieldOffsets();
};

}  // namespace dart

#endif  // RUNTIME_VM_CLASS_FINALIZER_H_
