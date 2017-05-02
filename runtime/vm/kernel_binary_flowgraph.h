// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_
#define RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <map>

#include "vm/kernel.h"
#include "vm/kernel_binary.h"
#include "vm/kernel_to_il.h"
#include "vm/object.h"

namespace dart {
namespace kernel {

class StreamingConstantEvaluator {
 public:
  StreamingConstantEvaluator(StreamingFlowGraphBuilder* builder,
                             Zone* zone,
                             TranslationHelper* h,
                             DartTypeTranslator* type_translator);

  virtual ~StreamingConstantEvaluator() {}

  Instance& EvaluateExpression();

  void EvaluateStaticGet();
  void EvaluateSymbolLiteral();
  void EvaluateDoubleLiteral();

 private:
  RawObject* EvaluateConstConstructorCall(const dart::Class& type_class,
                                          const TypeArguments& type_arguments,
                                          const Function& constructor,
                                          const Object& argument);

  bool GetCachedConstant(intptr_t kernel_offset, Instance* value);
  void CacheConstantValue(intptr_t kernel_offset, const Instance& value);

  StreamingFlowGraphBuilder* builder_;
  Isolate* isolate_;
  Zone* zone_;
  TranslationHelper& translation_helper_;
  //  DartTypeTranslator& type_translator_;

  Script& script_;
  Instance& result_;
};


class StreamingFlowGraphBuilder {
 public:
  StreamingFlowGraphBuilder(FlowGraphBuilder* flow_graph_builder,
                            const uint8_t* buffer,
                            intptr_t buffer_length)
      : flow_graph_builder_(flow_graph_builder),
        translation_helper_(flow_graph_builder->translation_helper_),
        zone_(flow_graph_builder->zone_),
        reader_(new kernel::Reader(buffer, buffer_length)),
        constant_evaluator_(this,
                            flow_graph_builder->zone_,
                            &flow_graph_builder->translation_helper_,
                            &flow_graph_builder->type_translator_),
        canonical_names_(NULL),
        canonical_names_size_(-1),
        canonical_names_entries_read_(0),
        canonical_names_next_offset_(-1) {}

  virtual ~StreamingFlowGraphBuilder() {
    delete reader_;
    // The canonical names themselves are not (yet) deallocated.
    delete[] canonical_names_;
  }

  Fragment BuildAt(intptr_t kernel_offset);

 private:
  CanonicalName* GetCanonicalName(intptr_t index);

  intptr_t ReaderOffset();
  void SetOffset(intptr_t offset);
  void SkipBytes(intptr_t skip);
  uint32_t ReadUInt();
  intptr_t ReadListLength();
  TokenPosition ReadPosition(bool record = true);
  Tag ReadTag(uint8_t* payload = NULL);

  CatchBlock* catch_block();
  ScopeBuildingResult* scopes();
  ParsedFunction* parsed_function();

  Fragment DebugStepCheck(TokenPosition position);
  Fragment LoadLocal(LocalVariable* variable);
  Fragment PushArgument();
  Fragment RethrowException(TokenPosition position, int catch_try_index);
  Fragment ThrowNoSuchMethodError();
  Fragment Constant(const Object& value);
  Fragment IntConstant(int64_t value);
  Fragment LoadStaticField();
  Fragment StaticCall(TokenPosition position,
                      const Function& target,
                      intptr_t argument_count);

  Fragment BuildInvalidExpression();
  Fragment BuildStaticGet();
  Fragment BuildSymbolLiteral();
  Fragment BuildThisExpression();
  Fragment BuildRethrow();
  Fragment BuildBigIntLiteral();
  Fragment BuildStringLiteral();
  Fragment BuildIntLiteral(uint8_t payload);
  Fragment BuildIntLiteral(bool is_negative);
  Fragment BuildDoubleLiteral();
  Fragment BuildBoolLiteral(bool value);
  Fragment BuildNullLiteral();

  FlowGraphBuilder* flow_graph_builder_;
  TranslationHelper& translation_helper_;
  Zone* zone_;
  kernel::Reader* reader_;
  StreamingConstantEvaluator constant_evaluator_;

  CanonicalName** canonical_names_;
  intptr_t canonical_names_size_;
  intptr_t canonical_names_entries_read_;
  intptr_t canonical_names_next_offset_;

  friend class StreamingConstantEvaluator;
};


}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_BINARY_FLOWGRAPH_H_
