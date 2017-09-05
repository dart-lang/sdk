// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/optimizer.h"

#include "vm/compiler/backend/il.h"
#include "vm/object.h"

namespace dart {

static bool CidTestResultsContains(const ZoneGrowableArray<intptr_t>& results,
                                   intptr_t test_cid) {
  for (intptr_t i = 0; i < results.length(); i += 2) {
    if (results[i] == test_cid) return true;
  }
  return false;
}

static void TryAddTest(ZoneGrowableArray<intptr_t>* results,
                       intptr_t test_cid,
                       bool result) {
  if (!CidTestResultsContains(*results, test_cid)) {
    results->Add(test_cid);
    results->Add(result);
  }
}

// Used when we only need the positive result because we return false by
// default.
static void PurgeNegativeTestCidsEntries(ZoneGrowableArray<intptr_t>* results) {
  // We can't purge the Smi entry at the beginning since it is used in the
  // Smi check before the Cid is loaded.
  int dest = 2;
  for (intptr_t i = 2; i < results->length(); i += 2) {
    if (results->At(i + 1) != 0) {
      (*results)[dest++] = results->At(i);
      (*results)[dest++] = results->At(i + 1);
    }
  }
  results->SetLength(dest);
}

bool Optimizer::SpecializeTestCidsForNumericTypes(
    ZoneGrowableArray<intptr_t>* results,
    const AbstractType& type) {
  ASSERT(results->length() >= 2);  // At least on entry.
  const ClassTable& class_table = *Isolate::Current()->class_table();
  if ((*results)[0] != kSmiCid) {
    const Class& cls = Class::Handle(class_table.At(kSmiCid));
    const Class& type_class = Class::Handle(type.type_class());
    const bool smi_is_subtype =
        cls.IsSubtypeOf(Object::null_type_arguments(), type_class,
                        Object::null_type_arguments(), NULL, NULL, Heap::kOld);
    results->Add((*results)[results->length() - 2]);
    results->Add((*results)[results->length() - 2]);
    for (intptr_t i = results->length() - 3; i > 1; --i) {
      (*results)[i] = (*results)[i - 2];
    }
    (*results)[0] = kSmiCid;
    (*results)[1] = smi_is_subtype;
  }

  ASSERT(type.IsInstantiated() && !type.IsMalformedOrMalbounded());
  ASSERT(results->length() >= 2);
  if (type.IsSmiType()) {
    ASSERT((*results)[0] == kSmiCid);
    PurgeNegativeTestCidsEntries(results);
    return false;
  } else if (type.IsIntType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kMintCid, true);
    TryAddTest(results, kBigintCid, true);
    // Cannot deoptimize since all tests returning true have been added.
    PurgeNegativeTestCidsEntries(results);
    return false;
  } else if (type.IsNumberType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kMintCid, true);
    TryAddTest(results, kBigintCid, true);
    TryAddTest(results, kDoubleCid, true);
    PurgeNegativeTestCidsEntries(results);
    return false;
  } else if (type.IsDoubleType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kDoubleCid, true);
    PurgeNegativeTestCidsEntries(results);
    return false;
  }
  return true;  // May deoptimize since we have not identified all 'true' tests.
}

}  // namespace dart
