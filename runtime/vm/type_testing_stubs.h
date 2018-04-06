// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TYPE_TESTING_STUBS_H_
#define RUNTIME_VM_TYPE_TESTING_STUBS_H_

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/il.h"

namespace dart {

class TypeTestingStubNamer {
 public:
  TypeTestingStubNamer();

  // Simple helper for stringinfying a [type] and prefix it with the type
  // testing
  //
  // (only during dart_boostrap).
  const char* StubNameForType(const AbstractType& type) const;

 private:
  const char* StringifyType(const AbstractType& type) const;
  static const char* AssemblerSafeName(char* cname);

  Library& lib_;
  Class& klass_;
  AbstractType& type_;
  TypeArguments& type_arguments_;
  String& string_;
};

class TypeTestingStubGenerator {
 public:
  // During bootstrapping it will return `null` for a whitelisted set of types,
  // otherwise it will return a default stub which tail-calls
  // subtypingtest/runtime code.
  static RawInstructions* DefaultCodeForType(const AbstractType& type);

  TypeTestingStubGenerator();

  // Creates new stub for [type] (and registers the tuple in object store
  // array) or returns default stub.
  RawInstructions* OptimizedCodeForType(const AbstractType& type);

 private:
#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
#if !defined(DART_PRECOMPILED_RUNTIME)
  RawInstructions* BuildCodeForType(const Type& type);
  static void BuildOptimizedTypeTestStub(Assembler* assembler,
                                         HierarchyInfo* hi,
                                         const Type& type,
                                         const Class& type_class);

  static void BuildOptimizedTypeTestStubFastCases(Assembler* assembler,
                                                  HierarchyInfo* hi,
                                                  const Type& type,
                                                  const Class& type_class,
                                                  Register instance_reg,
                                                  Register class_id_reg);

  static void BuildOptimizedSubtypeRangeCheck(Assembler* assembler,
                                              const CidRangeVector& ranges,
                                              Register class_id_reg,
                                              Register instance_reg,
                                              bool smi_is_ok);

  static void BuildOptimizedSubclassRangeCheckWithTypeArguments(
      Assembler* assembler,
      HierarchyInfo* hi,
      const Class& type_class,
      const TypeArguments& type_parameters,
      const TypeArguments& type_arguments);

  static void BuildOptimizedSubclassRangeCheckWithTypeArguments(
      Assembler* assembler,
      HierarchyInfo* hi,
      const Class& type_class,
      const TypeArguments& type_parameters,
      const TypeArguments& type_arguments,
      const Register class_id_reg,
      const Register instance_reg,
      const Register instance_type_args_reg);

  static void BuildOptimizedSubclassRangeCheck(Assembler* assembler,
                                               const CidRangeVector& ranges,
                                               Register class_id_reg,
                                               Register instance_reg,
                                               Label* check_failed);

  static void BuildOptimizedTypeArgumentValueCheck(
      Assembler* assembler,
      HierarchyInfo* hi,
      const AbstractType& type_arg,
      intptr_t type_param_value_offset_i,
      Label* check_failed);

  static void BuildOptimizedTypeArgumentValueCheck(
      Assembler* assembler,
      HierarchyInfo* hi,
      const AbstractType& type_arg,
      intptr_t type_param_value_offset_i,
      const Register class_id_reg,
      const Register instance_type_args_reg,
      const Register instantiator_type_args_reg,
      const Register function_type_args_reg,
      const Register type_arg_reg,
      Label* check_failed);

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)

  TypeTestingStubNamer namer_;
  ObjectStore* object_store_;
  GrowableObjectArray& array_;
  Instructions& instr_;
};

// It is assumed that the caller ensures, while this object lives there is no
// other access to [Isolate::Current()->object_store()->type_testing_stubs()].
class TypeTestingStubFinder {
 public:
  TypeTestingStubFinder();

  // When serializing an AOT snapshot via our clustered snapshot writer, we
  // write out references to the [Instructions] object for all the
  // [AbstractType] objects we encounter.
  //
  // This method is used for this mapping of stub entrypoint addresses to the
  // corresponding [Instructions] object.
  RawInstructions* LookupByAddresss(uword entry_point) const;

  // When generating an AOT snapshot as an assembly file (i.e. ".S" file) we
  // need to generate labels for the type testing stubs.
  //
  // This method maps stub entrypoint addresses to meaningful names.
  const char* StubNameFromAddresss(uword entry_point) const;

 private:
  // Sorts the tuples in [array_] according to entrypoint.
  void SortTableForFastLookup();

  // Returns the tuple index where [entry_point] was found.
  intptr_t LookupInSortedArray(uword entry_point) const;

  TypeTestingStubNamer namer_;
  GrowableObjectArray& array_;
  AbstractType& type_;
  Code& code_;
  Instructions& instr_;
};

}  // namespace dart

#endif  // RUNTIME_VM_TYPE_TESTING_STUBS_H_
