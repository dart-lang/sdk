// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/evaluator.h"

namespace dart {

static IntegerPtr BinaryIntegerEvaluateRaw(const Integer& left,
                                           const Integer& right,
                                           Token::Kind token_kind) {
  switch (token_kind) {
    case Token::kTRUNCDIV:
      FALL_THROUGH;
    case Token::kMOD:
      // Check right value for zero.
      if (right.AsInt64Value() == 0) {
        break;  // Will throw.
      }
      FALL_THROUGH;
    case Token::kADD:
      FALL_THROUGH;
    case Token::kSUB:
      FALL_THROUGH;
    case Token::kMUL:
      return left.ArithmeticOp(token_kind, right, Heap::kOld);
    case Token::kSHL:
      FALL_THROUGH;
    case Token::kSHR:
      if (right.AsInt64Value() >= 0) {
        return left.ShiftOp(token_kind, right, Heap::kOld);
      }
      break;
    case Token::kBIT_AND:
      FALL_THROUGH;
    case Token::kBIT_OR:
      FALL_THROUGH;
    case Token::kBIT_XOR:
      return left.BitOp(token_kind, right, Heap::kOld);
    case Token::kDIV:
      break;
    default:
      UNREACHABLE();
  }

  return Integer::null();
}

static IntegerPtr UnaryIntegerEvaluateRaw(const Integer& value,
                                          Token::Kind token_kind,
                                          Zone* zone) {
  switch (token_kind) {
    case Token::kNEGATE:
      return value.ArithmeticOp(Token::kMUL, Smi::Handle(zone, Smi::New(-1)),
                                Heap::kOld);
    case Token::kBIT_NOT:
      if (value.IsSmi()) {
        return Integer::New(~Smi::Cast(value).Value(), Heap::kOld);
      } else if (value.IsMint()) {
        return Integer::New(~Mint::Cast(value).value(), Heap::kOld);
      }
      break;
    default:
      UNREACHABLE();
  }
  return Integer::null();
}

int64_t Evaluator::TruncateTo(int64_t v, Representation r) {
  switch (r) {
    case kTagged: {
      // Smi occupies word minus kSmiTagShift bits.
      const intptr_t kTruncateBits =
          (kBitsPerInt64 - kBitsPerWord) + kSmiTagShift;
      return Utils::ShiftLeftWithTruncation(v, kTruncateBits) >> kTruncateBits;
    }
    case kUnboxedInt32:
      return Utils::ShiftLeftWithTruncation(v, kBitsPerInt32) >> kBitsPerInt32;
    case kUnboxedUint32:
      return v & kMaxUint32;
    case kUnboxedInt64:
      return v;
    default:
      UNREACHABLE();
  }
}

IntegerPtr Evaluator::BinaryIntegerEvaluate(const Object& left,
                                            const Object& right,
                                            Token::Kind token_kind,
                                            bool is_truncating,
                                            Representation representation,
                                            Thread* thread) {
  if (!left.IsInteger() || !right.IsInteger()) {
    return Integer::null();
  }
  Zone* zone = thread->zone();
  const Integer& left_int = Integer::Cast(left);
  const Integer& right_int = Integer::Cast(right);
  Integer& result = Integer::Handle(
      zone, BinaryIntegerEvaluateRaw(left_int, right_int, token_kind));

  if (!result.IsNull()) {
    if (is_truncating) {
      const int64_t truncated =
          TruncateTo(result.AsTruncatedInt64Value(), representation);
      result = Integer::New(truncated, Heap::kOld);
      ASSERT(FlowGraph::IsConstantRepresentable(
          result, representation, /*tagged_value_must_be_smi=*/true));
    } else if (!FlowGraph::IsConstantRepresentable(
                   result, representation, /*tagged_value_must_be_smi=*/true)) {
      // If this operation is not truncating it would deoptimize on overflow.
      // Check that we match this behavior and don't produce a value that is
      // larger than something this operation can produce. We could have
      // specialized instructions that use this value under this assumption.
      return Integer::null();
    }
    result ^= result.Canonicalize(thread);
  }

  return result.raw();
}

IntegerPtr Evaluator::UnaryIntegerEvaluate(const Object& value,
                                           Token::Kind token_kind,
                                           Representation representation,
                                           Thread* thread) {
  if (!value.IsInteger()) {
    return Integer::null();
  }
  Zone* zone = thread->zone();
  const Integer& value_int = Integer::Cast(value);
  Integer& result = Integer::Handle(
      zone, UnaryIntegerEvaluateRaw(value_int, token_kind, zone));

  if (!result.IsNull()) {
    if (!FlowGraph::IsConstantRepresentable(
            result, representation,
            /*tagged_value_must_be_smi=*/true)) {
      // If this operation is not truncating it would deoptimize on overflow.
      // Check that we match this behavior and don't produce a value that is
      // larger than something this operation can produce. We could have
      // specialized instructions that use this value under this assumption.
      return Integer::null();
    }

    result ^= result.Canonicalize(thread);
  }

  return result.raw();
}

double Evaluator::EvaluateDoubleOp(const double left,
                                   const double right,
                                   Token::Kind token_kind) {
  switch (token_kind) {
    case Token::kADD:
      return left + right;
    case Token::kSUB:
      return left - right;
    case Token::kMUL:
      return left * right;
    case Token::kDIV:
      return left / right;
    default:
      UNREACHABLE();
  }
}

bool Evaluator::ToIntegerConstant(Value* value, int64_t* result) {
  if (!value->BindsToConstant()) {
    UnboxInstr* unbox = value->definition()->AsUnbox();
    if (unbox != nullptr) {
      switch (unbox->representation()) {
        case kUnboxedDouble:
        case kUnboxedInt64:
          return ToIntegerConstant(unbox->value(), result);
        case kUnboxedUint32:
          if (ToIntegerConstant(unbox->value(), result)) {
            *result = Evaluator::TruncateTo(*result, kUnboxedUint32);
            return true;
          }
          break;
          // No need to handle Unbox<Int32>(Constant(C)) because it gets
          // canonicalized to UnboxedConstant<Int32>(C).
        case kUnboxedInt32:
        default:
          break;
      }
    }
    return false;
  }
  const Object& constant = value->BoundConstant();
  if (constant.IsDouble()) {
    const Double& double_constant = Double::Cast(constant);
    *result = Utils::SafeDoubleToInt<int64_t>(double_constant.value());
    return (static_cast<double>(*result) == double_constant.value());
  } else if (constant.IsSmi()) {
    *result = Smi::Cast(constant).Value();
    return true;
  } else if (constant.IsMint()) {
    *result = Mint::Cast(constant).value();
    return true;
  }
  return false;
}

}  // namespace dart
