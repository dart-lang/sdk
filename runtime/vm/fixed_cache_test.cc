// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <string.h>
#include "platform/assert.h"
#include "vm/fixed_cache.h"
#include "vm/unit_test.h"

namespace dart {

UNIT_TEST_CASE(FixedCacheEmpty) {
  FixedCache<int, int, 2> cache;
  EXPECT(cache.Lookup(0) == NULL);
  EXPECT(cache.Lookup(1) == NULL);
  cache.Insert(1, 2);
  EXPECT(*cache.Lookup(1) == 2);
  EXPECT(cache.Lookup(0) == NULL);
}


UNIT_TEST_CASE(FixedCacheHalfFull) {
  FixedCache<int, const char*, 8> cache;
  // Insert at end.
  cache.Insert(10, "a");
  cache.Insert(20, "b");
  cache.Insert(40, "c");
  // Insert in the middle.
  cache.Insert(15, "ab");
  cache.Insert(25, "bc");
  // Insert in front.
  cache.Insert(5, "_");
  // Check all items.
  EXPECT(strcmp(*cache.Lookup(5), "_") == 0);
  EXPECT(strcmp(*cache.Lookup(10), "a") == 0);
  EXPECT(strcmp(*cache.Lookup(20), "b") == 0);
  EXPECT(strcmp(*cache.Lookup(40), "c") == 0);
  EXPECT(strcmp(*cache.Lookup(25), "bc") == 0);
  // Non-existent - front, middle, end.
  EXPECT(cache.Lookup(1) == NULL);
  EXPECT(cache.Lookup(35) == NULL);
  EXPECT(cache.Lookup(50) == NULL);
}


struct Resource {
  Resource() : id(0), stuff(NULL) {}
  explicit Resource(int id_) : id(id_), stuff(new int) {}

  int id;
  int* stuff;
};

static void freeResource(Resource* res) {
  delete res->stuff;
}


UNIT_TEST_CASE(FixedCacheFullDeleter) {
  FixedCache<int, Resource, 6> cache(freeResource);
  cache.Insert(10, Resource(2));
  cache.Insert(20, Resource(4));
  cache.Insert(40, Resource(16));
  cache.Insert(30, Resource(8));
  EXPECT(cache.Lookup(40)->id == 16);
  EXPECT(cache.Lookup(5) == NULL);
  EXPECT(cache.Lookup(0) == NULL);
  // Insert in the front, middle.
  cache.Insert(5, Resource(1));
  cache.Insert(15, Resource(3));
  cache.Insert(25, Resource(6));
  // 40 got removed by shifting.
  EXPECT(cache.Lookup(40) == NULL);
  EXPECT(cache.Lookup(5)->id == 1);
  EXPECT(cache.Lookup(15)->id == 3);
  EXPECT(cache.Lookup(25)->id == 6);

  // Insert at end top - 30 gets replaced by 40.
  cache.Insert(40, Resource(16));
  EXPECT(cache.Lookup(40)->id == 16);
  EXPECT(cache.Lookup(30) == NULL);
}

}  // namespace dart
