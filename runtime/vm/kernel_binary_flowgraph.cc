// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_binary_flowgraph.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {
namespace kernel {

Fragment StreamingFlowGraphBuilder::BuildAt(intptr_t kernel_offset) {
  reader_->set_offset(kernel_offset);

  uint8_t payload = 0;
  Tag tag = reader_->ReadTag(&payload);
  switch (tag) {
    //    case kInvalidExpression:
    //      return InvalidExpression::ReadFrom(reader_);
    //    case kVariableGet:
    //      return VariableGet::ReadFrom(reader_);
    //    case kSpecializedVariableGet:
    //      return VariableGet::ReadFrom(reader_, payload);
    //    case kVariableSet:
    //      return VariableSet::ReadFrom(reader_);
    //    case kSpecializedVariableSet:
    //      return VariableSet::ReadFrom(reader_, payload);
    //    case kPropertyGet:
    //      return PropertyGet::ReadFrom(reader_);
    //    case kPropertySet:
    //      return PropertySet::ReadFrom(reader_);
    //    case kDirectPropertyGet:
    //      return DirectPropertyGet::ReadFrom(reader_);
    //    case kDirectPropertySet:
    //      return DirectPropertySet::ReadFrom(reader_);
    //    case kStaticGet:
    //      return StaticGet::ReadFrom(reader_);
    //    case kStaticSet:
    //      return StaticSet::ReadFrom(reader_);
    //    case kMethodInvocation:
    //      return MethodInvocation::ReadFrom(reader_);
    //    case kDirectMethodInvocation:
    //      return DirectMethodInvocation::ReadFrom(reader_);
    //    case kStaticInvocation:
    //      return StaticInvocation::ReadFrom(reader_, false);
    //    case kConstStaticInvocation:
    //      return StaticInvocation::ReadFrom(reader_, true);
    //    case kConstructorInvocation:
    //      return ConstructorInvocation::ReadFrom(reader_, false);
    //    case kConstConstructorInvocation:
    //      return ConstructorInvocation::ReadFrom(reader_, true);
    //    case kNot:
    //      return Not::ReadFrom(reader_);
    //    case kLogicalExpression:
    //      return LogicalExpression::ReadFrom(reader_);
    //    case kConditionalExpression:
    //      return ConditionalExpression::ReadFrom(reader_);
    //    case kStringConcatenation:
    //      return StringConcatenation::ReadFrom(reader_);
    //    case kIsExpression:
    //      return IsExpression::ReadFrom(reader_);
    //    case kAsExpression:
    //      return AsExpression::ReadFrom(reader_);
    //    case kSymbolLiteral:
    //      return SymbolLiteral::ReadFrom(reader_);
    //    case kTypeLiteral:
    //      return TypeLiteral::ReadFrom(reader_);
    //    case kThisExpression:
    //      return ThisExpression::ReadFrom(reader_);
    case kRethrow:
      return BuildRethrow();
    //    case kThrow:
    //      return Throw::ReadFrom(reader_);
    //    case kListLiteral:
    //      return ListLiteral::ReadFrom(reader_, false);
    //    case kConstListLiteral:
    //      return ListLiteral::ReadFrom(reader_, true);
    //    case kMapLiteral:
    //      return MapLiteral::ReadFrom(reader_, false);
    //    case kConstMapLiteral:
    //      return MapLiteral::ReadFrom(reader_, true);
    //    case kAwaitExpression:
    //      return AwaitExpression::ReadFrom(reader_);
    //    case kFunctionExpression:
    //      return FunctionExpression::ReadFrom(reader_);
    //    case kLet:
    //      return Let::ReadFrom(reader_);
    //    case kBigIntLiteral:
    //      return BigintLiteral::ReadFrom(reader_);
    //    case kStringLiteral:
    //      return StringLiteral::ReadFrom(reader_);
    //    case kSpecialIntLiteral:
    //      return IntLiteral::ReadFrom(reader_, payload);
    //    case kNegativeIntLiteral:
    //      return IntLiteral::ReadFrom(reader_, true);
    //    case kPositiveIntLiteral:
    //      return IntLiteral::ReadFrom(reader_, false);
    //    case kDoubleLiteral:
    //      return DoubleLiteral::ReadFrom(reader_);
    //    case kTrueLiteral:
    //      return BoolLiteral::ReadFrom(reader_, true);
    //    case kFalseLiteral:
    //      return BoolLiteral::ReadFrom(reader_, false);
    //    case kNullLiteral:
    //      return NullLiteral::ReadFrom(reader_);
    default:
      UNREACHABLE();
  }

  return Fragment();
}

TokenPosition StreamingFlowGraphBuilder::ReadPosition(bool record) {
  return reader_->ReadPosition(record);
}

CatchBlock* StreamingFlowGraphBuilder::catch_block() {
  return flow_graph_builder_->catch_block_;
}

Fragment StreamingFlowGraphBuilder::DebugStepCheck(TokenPosition position) {
  return flow_graph_builder_->DebugStepCheck(position);
}

Fragment StreamingFlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  return flow_graph_builder_->LoadLocal(variable);
}

Fragment StreamingFlowGraphBuilder::PushArgument() {
  return flow_graph_builder_->PushArgument();
}

Fragment StreamingFlowGraphBuilder::RethrowException(TokenPosition position,
                                                     int catch_try_index) {
  return flow_graph_builder_->RethrowException(position, catch_try_index);
}

Fragment StreamingFlowGraphBuilder::BuildRethrow() {
  TokenPosition position = ReadPosition();
  Fragment instructions = DebugStepCheck(position);
  instructions += LoadLocal(catch_block()->exception_var());
  instructions += PushArgument();
  instructions += LoadLocal(catch_block()->stack_trace_var());
  instructions += PushArgument();
  instructions += RethrowException(position, catch_block()->catch_try_index());

  return instructions;
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
