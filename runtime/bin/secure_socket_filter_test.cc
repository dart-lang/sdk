// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "bin/secure_socket_filter.h"

#include "vm/unit_test.h"

namespace dart {
namespace bin {

VM_UNIT_TEST_CASE(SSLFilter_BufferRangesAreBoundsChecked) {
  EXPECT(SSLFilter::IsValidBufferRange(0, 0, 1));
  EXPECT(SSLFilter::IsValidBufferRange(7, 0, 8));
  EXPECT(!SSLFilter::IsValidBufferRange(-1, 0, 8));
  EXPECT(!SSLFilter::IsValidBufferRange(0, -1, 8));
  EXPECT(!SSLFilter::IsValidBufferRange(8, 0, 8));
  EXPECT(!SSLFilter::IsValidBufferRange(0, 8, 8));
  EXPECT(!SSLFilter::IsValidBufferRange(0, 0, 0));
}

VM_UNIT_TEST_CASE(SSLFilter_PrefetchedDataIsStrictlyBounded) {
  EXPECT_EQ(0, SSLFilter::BoundedPrefetchedDataLength(0, 0));
  EXPECT_EQ(1, SSLFilter::BoundedPrefetchedDataLength(1, 0));
  EXPECT_EQ(1, SSLFilter::BoundedPrefetchedDataLength(10, 9));
  EXPECT_EQ(SSLFilter::kMaxPrefetchedData,
            SSLFilter::BoundedPrefetchedDataLength(
                SSLFilter::kMaxPrefetchedData * 4, 0));
  EXPECT_EQ(
      SSLFilter::kMaxPrefetchedData,
      SSLFilter::BoundedPrefetchedDataLength(SSLFilter::kMaxPrefetchedData * 4,
                                             SSLFilter::kMaxPrefetchedData));
  EXPECT_EQ(-1, SSLFilter::BoundedPrefetchedDataLength(1, -1));
  EXPECT_EQ(-1, SSLFilter::BoundedPrefetchedDataLength(1, 2));
  EXPECT_EQ(-1, SSLFilter::BoundedPrefetchedDataLength(-1, 0));

  EXPECT(!SSLFilter::PrefetchedDataHasTail(0, 0, 0));
  EXPECT(!SSLFilter::PrefetchedDataHasTail(1, 0, 1));
  EXPECT(SSLFilter::PrefetchedDataHasTail(SSLFilter::kMaxPrefetchedData + 1, 0,
                                          SSLFilter::kMaxPrefetchedData));
  EXPECT(SSLFilter::PrefetchedDataHasTail(SSLFilter::kMaxPrefetchedData * 4,
                                          SSLFilter::kMaxPrefetchedData,
                                          SSLFilter::kMaxPrefetchedData));
  EXPECT(!SSLFilter::PrefetchedDataHasTail(1, 2, 0));
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
