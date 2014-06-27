// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <algorithm>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "platform/assert.h"
#include "vm/unit_test.h"
#include "vm/hash_table.h"

namespace dart {

// Various ways to look up strings. Uses length as the hash code to make it
// easy to engineer collisions.
class TestTraits {
 public:
  static bool IsMatch(const char* key, const Object& obj) {
    return String::Cast(obj).Equals(key);
  }
  static uword Hash(const char* key) {
    return static_cast<uword>(strlen(key));
  }
  static bool IsMatch(const Object& a, const Object& b) {
    return a.IsString() && b.IsString() &&
        String::Cast(a).Equals(String::Cast(b));
  }
  static uword Hash(const Object& obj) {
    return String::Cast(obj).Length();
  }
};


template<typename Table>
void Validate(const Table& table) {
  // Verify consistency of entry state tracking.
  intptr_t num_entries = table.NumEntries();
  intptr_t num_unused = table.NumUnused();
  intptr_t num_occupied = table.NumOccupied();
  intptr_t num_deleted = table.NumDeleted();
  for (intptr_t i = 0; i < num_entries; ++i) {
    EXPECT_EQ(1, table.IsUnused(i) + table.IsOccupied(i) + table.IsDeleted(i));
    num_unused -= table.IsUnused(i);
    num_occupied -= table.IsOccupied(i);
    num_deleted -= table.IsDeleted(i);
  }
  EXPECT_EQ(0, num_unused);
  EXPECT_EQ(0, num_occupied);
  EXPECT_EQ(0, num_deleted);
}


TEST_CASE(HashTable) {
  typedef HashTable<TestTraits, 2, 1> Table;
  Table table(Array::Handle(HashTables::New<Table>(5)));
  // Ensure that we did get at least 5 entries.
  EXPECT_LE(5, table.NumEntries());
  EXPECT_EQ(0, table.NumOccupied());
  Validate(table);
  EXPECT_EQ(-1, table.FindKey("a"));

  // Insertion and lookup.
  intptr_t a_entry = -1;
  EXPECT(!table.FindKeyOrDeletedOrUnused("a", &a_entry));
  EXPECT_NE(-1, a_entry);
  String& a = String::Handle(String::New("a"));
  table.InsertKey(a_entry, a);
  EXPECT_EQ(1, table.NumOccupied());
  Validate(table);
  EXPECT_EQ(a_entry, table.FindKey("a"));
  EXPECT_EQ(-1, table.FindKey("b"));
  intptr_t a_entry_again = -1;
  EXPECT(table.FindKeyOrDeletedOrUnused("a", &a_entry_again));
  EXPECT_EQ(a_entry, a_entry_again);
  intptr_t b_entry = -1;
  EXPECT(!table.FindKeyOrDeletedOrUnused("b", &b_entry));
  String& b = String::Handle(String::New("b"));
  table.InsertKey(b_entry, b);
  EXPECT_EQ(2, table.NumOccupied());
  Validate(table);

  // Deletion.
  table.DeleteEntry(a_entry);
  EXPECT_EQ(1, table.NumOccupied());
  Validate(table);
  EXPECT_EQ(-1, table.FindKey("a"));
  EXPECT_EQ(b_entry, table.FindKey("b"));
  intptr_t c_entry = -1;
  EXPECT(!table.FindKeyOrDeletedOrUnused("c", &c_entry));
  String& c = String::Handle(String::New("c"));
  table.InsertKey(c_entry, c);
  EXPECT_EQ(2, table.NumOccupied());
  Validate(table);
  EXPECT_EQ(c_entry, table.FindKey("c"));

  // Ensure we can actually reach 5 occupied entries (without expansion).
  {
    intptr_t entry = -1;
    EXPECT(!table.FindKeyOrDeletedOrUnused("d", &entry));
    String& k = String::Handle(String::New("d"));
    table.InsertKey(entry, k);
    EXPECT(!table.FindKeyOrDeletedOrUnused("e", &entry));
    k = String::New("e");
    table.InsertKey(entry, k);
    EXPECT(!table.FindKeyOrDeletedOrUnused("f", &entry));
    k = String::New("f");
    table.InsertKey(entry, k);
    EXPECT_EQ(5, table.NumOccupied());
  }
  table.Release();
}


TEST_CASE(EnumIndexHashMap) {
  typedef EnumIndexHashMap<TestTraits> Table;
  Table table(Array::Handle(HashTables::New<Table>(5)));
  table.UpdateOrInsert(String::Handle(String::New("a")),
                       String::Handle(String::New("A")));
  EXPECT(table.ContainsKey("a"));
  table.UpdateValue("a", String::Handle(String::New("AAA")));
  String& a_value = String::Handle();
  a_value ^= table.GetOrNull("a");
  EXPECT(a_value.Equals("AAA"));
  Object& null_value = Object::Handle(table.GetOrNull("0"));
  EXPECT(null_value.IsNull());
  table.Release();
}


std::string ToStdString(const String& str) {
  EXPECT(str.IsOneByteString());
  std::string result;
  for (intptr_t i = 0; i < str.Length(); ++i) {
    result += static_cast<char>(str.CharAt(i));
  }
  return result;
}


// Checks that 'expected' and 'actual' are equal sets. If 'ordered' is true,
// it also verifies that their iteration orders match, i.e., that actual's
// insertion order coincides with lexicographic order.
template<typename Set>
void VerifyStringSetsEqual(const std::set<std::string>& expected,
                           const Set& actual,
                           bool ordered) {
  // Get actual keys in iteration order.
  Array& keys = Array::Handle(HashTables::ToArray(actual, true));
  // Cardinality must match.
  EXPECT_EQ(static_cast<intptr_t>(expected.size()), keys.Length());
  std::vector<std::string> expected_vec(expected.begin(), expected.end());
  // Check containment.
  for (uintptr_t i = 0; i < expected_vec.size(); ++i) {
    EXPECT(actual.ContainsKey(expected_vec[i].c_str()));
  }
  // Equality, including order, if requested.
  std::vector<std::string> actual_vec;
  String& key = String::Handle();
  for (int i = 0; i < keys.Length(); ++i) {
    key ^= keys.At(i);
    actual_vec.push_back(ToStdString(key));
  }
  if (!ordered) {
    std::sort(actual_vec.begin(), actual_vec.end());
  }
  EXPECT(std::equal(actual_vec.begin(), actual_vec.end(),
                    expected_vec.begin()));
}


// Checks that 'expected' and 'actual' are equal maps. If 'ordered' is true,
// it also verifies that their iteration orders match, i.e., that actual's
// insertion order coincides with lexicographic order.
template<typename Map>
void VerifyStringMapsEqual(const std::map<std::string, int>& expected,
                           const Map& actual,
                           bool ordered) {
  intptr_t expected_size = expected.size();
  // Get actual concatenated (key, value) pairs in iteration order.
  Array& entries = Array::Handle(HashTables::ToArray(actual, true));
  // Cardinality must match.
  EXPECT_EQ(expected_size * 2, entries.Length());
  std::vector<std::pair<std::string, int> > expected_vec(expected.begin(),
                                                         expected.end());
  // Check containment.
  Smi& value = Smi::Handle();
  for (uintptr_t i = 0; i < expected_vec.size(); ++i) {
    std::string key = expected_vec[i].first;
    EXPECT(actual.ContainsKey(key.c_str()));
    value ^= actual.GetOrNull(key.c_str());
    EXPECT_EQ(expected_vec[i].second, value.Value());
  }
  if (!ordered) {
    return;
  }
  // Equality including order.
  std::vector<std::string> actual_vec;
  String& key = String::Handle();
  for (int i = 0; i < expected_size; ++i) {
    key ^= entries.At(2 * i);
    value ^= entries.At(2 * i + 1);
    EXPECT(expected_vec[i].first == ToStdString(key));
    EXPECT_EQ(expected_vec[i].second, value.Value());
  }
}


template<typename Set>
void TestSet(intptr_t initial_capacity, bool ordered) {
  std::set<std::string> expected;
  Set actual(Array::Handle(HashTables::New<Set>(initial_capacity)));
  // Insert the following strings twice:
  // aaa...aaa (length 26)
  // bbb..bbb
  // ...
  // yy
  // z
  for (int i = 0; i < 2; ++i) {
    for (char ch = 'a'; ch <= 'z'; ++ch) {
      std::string key('z' - ch + 1, ch);
      expected.insert(key);
      bool present = actual.Insert(String::Handle(String::New(key.c_str())));
      EXPECT_EQ((i != 0), present);
      Validate(actual);
      VerifyStringSetsEqual(expected, actual, ordered);
    }
  }
  // TODO(koda): Delete all entries.
  actual.Release();
}


template<typename Map>
void TestMap(intptr_t initial_capacity, bool ordered) {
  std::map<std::string, int> expected;
  Map actual(Array::Handle(HashTables::New<Map>(initial_capacity)));
  // Insert the following (strings, int) mapping:
  // aaa...aaa -> 26
  // bbb..bbb -> 25
  // ...
  // yy -> 2
  // z -> 1
  for (int i = 0; i < 2; ++i) {
    for (char ch = 'a'; ch <= 'z'; ++ch) {
      int length = 'z' - ch + 1;
      std::string key(length, ch);
      // Map everything to zero initially, then update to their final values.
      int value = length * i;
      expected[key] = value;
      bool present =
          actual.UpdateOrInsert(String::Handle(String::New(key.c_str())),
                                Smi::Handle(Smi::New(value)));
      EXPECT_EQ((i != 0), present);
      Validate(actual);
      VerifyStringMapsEqual(expected, actual, ordered);
    }
  }
  // TODO(koda): Delete all entries.
  actual.Release();
}


TEST_CASE(Sets) {
  for (intptr_t initial_capacity = 0;
       initial_capacity < 32;
       ++initial_capacity) {
    TestSet<UnorderedHashSet<TestTraits> >(initial_capacity, false);
    TestSet<EnumIndexHashSet<TestTraits> >(initial_capacity, true);
  }
}


TEST_CASE(Maps) {
  for (intptr_t initial_capacity = 0;
       initial_capacity < 32;
       ++initial_capacity) {
    TestMap<UnorderedHashMap<TestTraits> >(initial_capacity, false);
    TestMap<EnumIndexHashMap<TestTraits> >(initial_capacity, true);
  }
}

}  // namespace dart
