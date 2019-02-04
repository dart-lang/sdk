// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_EVALUATOR_H_
#define RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_EVALUATOR_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/kernel_translation_helper.h"
#include "vm/hash_table.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class FlowGraphBuilder;

// There are several cases when we are compiling constant expressions:
//
//   * constant field initializers:
//      const FieldName = <expr>;
//
//   * constant expressions:
//      const [<expr>, ...]
//      const {<expr> : <expr>, ...}
//      const Constructor(<expr>, ...)
//
//   * constant default parameters:
//      f(a, [b = <expr>])
//      f(a, {b: <expr>})
//
//   * constant values to compare in a [SwitchCase]
//      case <expr>:
//
// In all cases `<expr>` must be recursively evaluated and canonicalized at
// compile-time.
class ConstantEvaluator {
 public:
  ConstantEvaluator(KernelReaderHelper* helper,
                    TypeTranslator* type_translator,
                    ActiveClass* active_class,
                    FlowGraphBuilder* flow_graph_builder = nullptr);

  virtual ~ConstantEvaluator() {}

  bool IsCached(intptr_t offset);

  RawInstance* EvaluateExpression(intptr_t offset, bool reset_position = true);
  Instance& EvaluateListLiteral(intptr_t offset, bool reset_position = true);
  Instance& EvaluateMapLiteral(intptr_t offset, bool reset_position = true);
  Instance& EvaluateConstructorInvocation(intptr_t offset,
                                          bool reset_position = true);
  Instance& EvaluateStaticInvocation(intptr_t offset,
                                     bool reset_position = true);
  RawObject* EvaluateExpressionSafe(intptr_t offset);
  RawObject* EvaluateAnnotations();

 private:
  void BailoutIfBackgroundCompilation();

  bool IsBuildingFlowGraph() const;
  bool IsAllowedToEvaluate() const;
  void EvaluateAsExpression();
  void EvaluateVariableGet(bool is_specialized);
  void EvaluatePropertyGet();
  void EvaluateDirectPropertyGet();
  void EvaluateStaticGet();
  void EvaluateMethodInvocation();
  void EvaluateDirectMethodInvocation();
  void EvaluateSuperMethodInvocation();
  void EvaluateStaticInvocation();
  void EvaluateConstructorInvocationInternal();
  void EvaluateNot();
  void EvaluateLogicalExpression();
  void EvaluateConditionalExpression();
  void EvaluateStringConcatenation();
  void EvaluateSymbolLiteral();
  void EvaluateTypeLiteral();
  void EvaluateListLiteralInternal();
  void EvaluateMapLiteralInternal();
  void EvaluateLet();
  void EvaluatePartialTearoffInstantiation();
  void EvaluateBigIntLiteral();
  void EvaluateStringLiteral();
  void EvaluateIntLiteral(uint8_t payload);
  void EvaluateIntLiteral(bool is_negative);
  void EvaluateDoubleLiteral();
  void EvaluateBoolLiteral(bool value);
  void EvaluateNullLiteral();
  void EvaluateConstantExpression();

  void EvaluateGetStringLength(intptr_t expression_offset,
                               TokenPosition position);

  const Object& RunFunction(const TokenPosition position,
                            const Function& function,
                            intptr_t argument_count,
                            const Instance* receiver,
                            const TypeArguments* type_args);

  const Object& RunFunction(const TokenPosition position,
                            const Function& function,
                            const Array& arguments,
                            const Array& names);

  const Object& RunMethodCall(const TokenPosition position,
                              const Function& function,
                              const Instance* receiver);

  RawObject* EvaluateConstConstructorCall(const Class& type_class,
                                          const TypeArguments& type_arguments,
                                          const Function& constructor,
                                          const Object& argument);

  const TypeArguments* TranslateTypeArguments(const Function& target,
                                              Class* target_klass);

  void AssertBool() {
    if (!result_.IsBool()) {
      translation_helper_.ReportError("Expected boolean expression.");
    }
  }

  bool EvaluateBooleanExpressionHere();

  bool GetCachedConstant(intptr_t kernel_offset, Instance* value);
  void CacheConstantValue(intptr_t kernel_offset, const Instance& value);

  KernelReaderHelper* helper_;
  Isolate* isolate_;
  Zone* zone_;
  TranslationHelper& translation_helper_;
  TypeTranslator& type_translator_;
  ActiveClass* active_class_;
  FlowGraphBuilder* flow_graph_builder_;
  const Script& script_;
  Instance& result_;

  DISALLOW_COPY_AND_ASSIGN(ConstantEvaluator);
};

// Helper class that reads a kernel Constant from binary.
class ConstantHelper {
 public:
  ConstantHelper(Zone* zone,
                 KernelReaderHelper* helper,
                 TypeTranslator* type_translator,
                 ActiveClass* active_class,
                 NameIndex skip_vmservice_library);

  // Reads the constant table from the binary.
  //
  // This method assumes the Reader is positioned already at the constant table
  // and an active class scope is setup.
  const Array& ReadConstantTable();

 private:
  void InstantiateTypeArguments(const Class& receiver_class,
                                TypeArguments* type_arguments);

  // If [index] has `dart:vm_service` as a parent and we are skipping the VM
  // service library, this method returns `true`, otherwise `false`.
  bool ShouldSkipConstant(NameIndex index);

  Zone* zone_;
  KernelReaderHelper& helper_;
  TypeTranslator& type_translator_;
  ActiveClass* const active_class_;
  ConstantEvaluator const_evaluator_;
  TranslationHelper& translation_helper_;
  NameIndex skip_vmservice_library_;
  Class& symbol_class_;
  Field& symbol_name_field_;
  AbstractType& temp_type_;
  TypeArguments& temp_type_arguments_;
  TypeArguments& temp_type_arguments2_;
  TypeArguments& temp_type_arguments3_;
  Object& temp_object_;
  String& temp_string_;
  Array& temp_array_;
  Instance& temp_instance_;
  Field& temp_field_;
  Class& temp_class_;
  Library& temp_library_;
  Function& temp_function_;
  Closure& temp_closure_;
  Context& temp_context_;
  Integer& temp_integer_;

  DISALLOW_COPY_AND_ASSIGN(ConstantHelper);
};

class KernelConstMapKeyEqualsTraits : public AllStatic {
 public:
  static const char* Name() { return "KernelConstMapKeyEqualsTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    const Smi& key1 = Smi::Cast(a);
    const Smi& key2 = Smi::Cast(b);
    return (key1.Value() == key2.Value());
  }
  static bool IsMatch(const intptr_t key1, const Object& b) {
    return KeyAsSmi(key1) == Smi::Cast(b).raw();
  }
  static uword Hash(const Object& obj) {
    const Smi& key = Smi::Cast(obj);
    return HashValue(key.Value());
  }
  static uword Hash(const intptr_t key) {
    return HashValue(Smi::Value(KeyAsSmi(key)));
  }
  static RawObject* NewKey(const intptr_t key) { return KeyAsSmi(key); }

 private:
  static uword HashValue(intptr_t pos) { return pos % (Smi::kMaxValue - 13); }

  static RawSmi* KeyAsSmi(const intptr_t key) {
    ASSERT(key >= 0);
    return Smi::New(key);
  }
};
typedef UnorderedHashMap<KernelConstMapKeyEqualsTraits> KernelConstantsMap;

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_EVALUATOR_H_
