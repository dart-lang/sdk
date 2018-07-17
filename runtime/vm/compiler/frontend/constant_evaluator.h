// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_EVALUATOR_H_
#define RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_EVALUATOR_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/kernel_translation_helper.h"
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
  RawObject* EvaluateExpressionSafe(intptr_t offset);

 private:
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
  AbstractType& temp_type_;
  TypeArguments& temp_type_arguments_;
  TypeArguments& temp_type_arguments2_;
  TypeArguments& temp_type_arguments3_;
  Object& temp_object_;
  Array& temp_array_;
  Instance& temp_instance_;
  Field& temp_field_;
  Class& temp_class_;
  Function& temp_function_;
  Closure& temp_closure_;
  Context& temp_context_;
  Integer& temp_integer_;

  DISALLOW_COPY_AND_ASSIGN(ConstantHelper);
};

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_COMPILER_FRONTEND_CONSTANT_EVALUATOR_H_
