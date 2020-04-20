// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SNAPSHOT_IDS_H_
#define RUNTIME_VM_SNAPSHOT_IDS_H_

#include "vm/dart_entry.h"
#include "vm/raw_object.h"

namespace dart {

// Index for predefined singleton objects used in a snapshot.
enum {
  kNullObject = 0,
  kSentinelObject,
  kTransitionSentinelObject,
  kEmptyArrayObject,
  kZeroArrayObject,
  kTrueValue,
  kFalseValue,
  // Marker for special encoding of double objects in message snapshots.
  kDoubleObject,
  // Object id has been optimized away; reader should use next available id.
  kOmittedObjectId,

  kClassIdsOffset = kOmittedObjectId,

  // The class ids of predefined classes are included in this list
  // at an offset of kClassIdsOffset.

  kFirstTypeSnapshotId = (kNumPredefinedCids + kClassIdsOffset),
  kLegacyObjectType = kFirstTypeSnapshotId,
  kNullableObjectType,
  kNullType,
  kDynamicType,
  kVoidType,
  kNeverType,
  kLegacyFunctionType,
  kLegacyNumberType,
  kLegacySmiType,
  kLegacyMintType,
  kLegacyDoubleType,
  kLegacyIntType,
  kLegacyBoolType,
  kLegacyStringType,
  kLegacyArrayType,
  kNonNullableObjectType,
  kNonNullableFunctionType,
  kNonNullableNumberType,
  kNonNullableSmiType,
  kNonNullableMintType,
  kNonNullableDoubleType,
  kNonNullableIntType,
  kNonNullableBoolType,
  kNonNullableStringType,
  kNonNullableArrayType,
  kLastTypeSnapshotId = kNonNullableArrayType,

  kFirstTypeArgumentsSnapshotId = kLastTypeSnapshotId + 1,
  kLegacyIntTypeArguments = kFirstTypeArgumentsSnapshotId,
  kLegacyDoubleTypeArguments,
  kLegacyStringTypeArguments,
  kLegacyStringDynamicTypeArguments,
  kLegacyStringLegacyStringTypeArguments,
  kNonNullableIntTypeArguments,
  kNonNullableDoubleTypeArguments,
  kNonNullableStringTypeArguments,
  kNonNullableStringDynamicTypeArguments,
  kNonNullableStringNonNullableStringTypeArguments,
  kEmptyTypeArguments,
  kLastTypeArgumentsSnapshotId = kEmptyTypeArguments,

  kExtractorParameterTypes,
  kExtractorParameterNames,
  kEmptyContextScopeObject,
  kImplicitClosureScopeObject,
  kEmptyObjectPool,
  kEmptyDescriptors,
  kEmptyVarDescriptors,
  kEmptyExceptionHandlers,
  kCachedArgumentsDescriptor0,
  kCachedArgumentsDescriptorN =
      (kCachedArgumentsDescriptor0 +
       ArgumentsDescriptor::kCachedDescriptorCount - 1),
  kCachedICDataArray0,
  kCachedICDataArrayN =
      (kCachedICDataArray0 + ICData::kCachedICDataArrayCount - 1),

  kInstanceObjectId,
  kStaticImplicitClosureObjectId,
  kMaxPredefinedObjectIds,
  kInvalidIndex = -1,
};

}  // namespace dart

#endif  // RUNTIME_VM_SNAPSHOT_IDS_H_
