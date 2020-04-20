// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <functional>
#include <memory>
#include <utility>

#include "platform/assert.h"
#include "vm/code_descriptors.h"
#include "vm/exceptions.h"
#include "vm/unit_test.h"

namespace dart {

static CatchEntryMove NewMove(intptr_t src, intptr_t dst) {
  return CatchEntryMove::FromSlot(CatchEntryMove::SourceKind::kTaggedSlot, src,
                                  dst);
}
const auto kA = NewMove(1, 10);
const auto kB = NewMove(2, 20);
const auto kC = NewMove(3, 30);
const auto kD = NewMove(4, 40);
const auto kE = NewMove(5, 50);
const auto kX = NewMove(-1, -10);

const CatchEntryMove abcde[] = {kA, kB, kC, kD, kE};
const CatchEntryMove abcdx[] = {kA, kB, kC, kD, kX};
const CatchEntryMove xbcde[] = {kX, kB, kC, kD, kE};
const CatchEntryMove abxde[] = {kA, kB, kX, kD, kE};
const CatchEntryMove ab[] = {kA, kB};
const CatchEntryMove de[] = {kD, kE};

struct TestCaseMoves {
  const CatchEntryMove* moves;
  const intptr_t count;
};

void RunTestCaseWithPermutations(const TestCaseMoves* mapping,
                                 intptr_t* insert_permutation,
                                 intptr_t count) {
  CatchEntryMovesMapBuilder b;

  for (intptr_t i = 0; i < count; ++i) {
    auto expected_moves = mapping[insert_permutation[i]];
    b.NewMapping(/*pc_offset=*/insert_permutation[i]);
    for (intptr_t j = 0; j < expected_moves.count; ++j) {
      b.Append(expected_moves.moves[j]);
    }
    b.EndMapping();
  }

  const auto& bytes = TypedData::Handle(b.FinalizeCatchEntryMovesMap());
  CatchEntryMovesMapReader reader(bytes);

  for (intptr_t i = 0; i < count; ++i) {
    auto expected_moves = mapping[i];
    auto read_moves = reader.ReadMovesForPcOffset(i);
    EXPECT_EQ(expected_moves.count, read_moves->count());
    for (intptr_t j = 0; j < expected_moves.count; ++j) {
      EXPECT(expected_moves.moves[j] == read_moves->At(j));
    }
    free(read_moves);
  }
}

void RunTestCase(const TestCaseMoves* mapping, intptr_t count) {
  std::unique_ptr<intptr_t[]> permutation(new intptr_t[count]);
  for (intptr_t i = 0; i < count; ++i) {
    permutation[i] = i;
  }

  std::function<void(intptr_t)> run_all_permutations = [&](intptr_t offset) {
    if (offset == count) {
      RunTestCaseWithPermutations(mapping, &permutation[0], count);
    } else {
      for (intptr_t i = offset; i < count; ++i) {
        const intptr_t start = permutation[offset];
        const intptr_t replacement = permutation[i];

        permutation[offset] = replacement;
        permutation[i] = start;

        run_all_permutations(offset + 1);

        permutation[offset] = start;
        permutation[i] = replacement;
      }
    }
  };

  run_all_permutations(0);
}

ISOLATE_UNIT_TEST_CASE(CatchEntryMoves) {
  // Common prefix.
  const TestCaseMoves test1[] = {
      TestCaseMoves{
          abcde,
          ARRAY_SIZE(abcde),
      },
      TestCaseMoves{
          abcdx,
          ARRAY_SIZE(abcdx),
      },
  };
  RunTestCase(test1, ARRAY_SIZE(test1));

  // Common suffix.
  const TestCaseMoves test2[] = {
      TestCaseMoves{
          abcde,
          ARRAY_SIZE(abcde),
      },
      TestCaseMoves{
          xbcde,
          ARRAY_SIZE(xbcde),
      },
  };
  RunTestCase(test2, ARRAY_SIZE(test2));

  // Common prefix and suffix.
  const TestCaseMoves test3[] = {
      TestCaseMoves{
          abcde,
          ARRAY_SIZE(abcde),
      },
      TestCaseMoves{
          abxde,
          ARRAY_SIZE(abxde),
      },
  };
  RunTestCase(test3, ARRAY_SIZE(test3));

  // Subset of suffix.
  const TestCaseMoves test4[] = {
      TestCaseMoves{
          abcde,
          ARRAY_SIZE(abcde),
      },
      TestCaseMoves{
          de,
          ARRAY_SIZE(de),
      },
  };
  RunTestCase(test4, ARRAY_SIZE(test4));

  // Subset of prefix.
  const TestCaseMoves test5[] = {
      TestCaseMoves{
          abcde,
          ARRAY_SIZE(abcde),
      },
      TestCaseMoves{
          ab,
          ARRAY_SIZE(ab),
      },
  };
  RunTestCase(test5, ARRAY_SIZE(test5));

  // All moves (with duplicates).
  const TestCaseMoves test6[] = {
      TestCaseMoves{
          abcde,
          ARRAY_SIZE(abcde),
      },
      TestCaseMoves{
          abcde,
          ARRAY_SIZE(abcde),
      },
      TestCaseMoves{
          abcdx,
          ARRAY_SIZE(abcdx),
      },
      TestCaseMoves{
          xbcde,
          ARRAY_SIZE(xbcde),
      },
      TestCaseMoves{
          abxde,
          ARRAY_SIZE(abxde),
      },
      TestCaseMoves{
          ab,
          ARRAY_SIZE(ab),
      },
      TestCaseMoves{
          de,
          ARRAY_SIZE(de),
      },
      TestCaseMoves{
          de,
          ARRAY_SIZE(de),
      },
  };
  RunTestCase(test6, ARRAY_SIZE(test6));
}

}  // namespace dart
