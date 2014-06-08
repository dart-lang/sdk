// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index.b_plus_tree;

import 'dart:math';

import 'package:analysis_server/src/index/b_plus_tree.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  group('BTree', () {
    runReflectiveTests(BPlusTreeTest);
  });
}


void _assertDebugString(BPlusTree tree, String expected) {
  String dump = _getDebugString(tree);
  expect(dump, expected);
}


String _getDebugString(BPlusTree tree) {
  StringBuffer buffer = new StringBuffer();
  tree.writeOn(buffer);
  return buffer.toString();
}


int _intComparator(int a, int b) => a - b;


@ReflectiveTestCase()
class BPlusTreeTest {
  BPlusTree<int, String> tree = new BPlusTree<int, String>(4, 4, _intComparator);

  test_NoSuchMethodError() {
    expect(() {
      (tree as dynamic).thereIsNoSuchMethod();
    }, throwsA(new isInstanceOf<NoSuchMethodError>()));
  }

  void test_find() {
    _insertValues(12);
    expect(tree.find(-1), isNull);
    expect(tree.find(1000), isNull);
    for (int key = 0; key < 12; key++) {
      expect(tree.find(key), 'V$key');
    }
  }

  void test_insert_01() {
    _insert(0, 'A');
    _assertDebugString(tree, 'LNode {0: A}\n');
  }

  void test_insert_02() {
    _insert(1, 'B');
    _insert(0, 'A');
    _assertDebugString(tree, 'LNode {0: A, 1: B}\n');
  }

  void test_insert_03() {
    _insert(2, 'C');
    _insert(0, 'A');
    _insert(1, 'B');
    _assertDebugString(tree, 'LNode {0: A, 1: B, 2: C}\n');
  }

  void test_insert_05() {
    _insertValues(5);
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1}
  2
    LNode {2: V2, 3: V3, 4: V4}
}
''');
  }

  void test_insert_09() {
    _insertValues(9);
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1}
  2
    LNode {2: V2, 3: V3}
  4
    LNode {4: V4, 5: V5}
  6
    LNode {6: V6, 7: V7, 8: V8}
}
''');
  }

  void test_insert_innerSplitLeft() {
    // Prepare a tree with '0' key missing.
    for (int i = 1; i < 12; i++) {
      _insert(i, "V$i");
    }
    _assertDebugString(tree, '''
INode {
    LNode {1: V1, 2: V2}
  3
    LNode {3: V3, 4: V4}
  5
    LNode {5: V5, 6: V6}
  7
    LNode {7: V7, 8: V8}
  9
    LNode {9: V9, 10: V10, 11: V11}
}
''');
    // Split and insert into the 'left' child.
    _insert(0, 'V0');
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {0: V0, 1: V1, 2: V2}
      3
        LNode {3: V3, 4: V4}
      5
        LNode {5: V5, 6: V6}
    }
  7
    INode {
        LNode {7: V7, 8: V8}
      9
        LNode {9: V9, 10: V10, 11: V11}
    }
}
''');
  }

  void test_insert_innerSplitRight() {
    _insertValues(12);
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {0: V0, 1: V1}
      2
        LNode {2: V2, 3: V3}
      4
        LNode {4: V4, 5: V5}
    }
  6
    INode {
        LNode {6: V6, 7: V7}
      8
        LNode {8: V8, 9: V9, 10: V10, 11: V11}
    }
}
''');
  }

  void test_insert_replace() {
    _insert(0, 'A');
    _insert(1, 'B');
    _insert(2, 'C');
    _assertDebugString(tree, 'LNode {0: A, 1: B, 2: C}\n');
    _insert(2, 'C2');
    _insert(1, 'B2');
    _insert(0, 'A2');
    _assertDebugString(tree, 'LNode {0: A2, 1: B2, 2: C2}\n');
  }

  void test_remove_inner_borrowLeft() {
    tree = new BPlusTree<int, String>(10, 4, _intComparator);
    for (int i = 100; i < 125; i++) {
      _insert(i, 'V$i');
    }
    for (int i = 0; i < 10; i++) {
      _insert(i, 'V$i');
    }
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {0: V0, 1: V1}
      2
        LNode {2: V2, 3: V3}
      4
        LNode {4: V4, 5: V5}
      6
        LNode {6: V6, 7: V7}
      8
        LNode {8: V8, 9: V9, 100: V100, 101: V101}
      102
        LNode {102: V102, 103: V103}
      104
        LNode {104: V104, 105: V105}
      106
        LNode {106: V106, 107: V107}
      108
        LNode {108: V108, 109: V109}
      110
        LNode {110: V110, 111: V111}
    }
  112
    INode {
        LNode {112: V112, 113: V113}
      114
        LNode {114: V114, 115: V115}
      116
        LNode {116: V116, 117: V117}
      118
        LNode {118: V118, 119: V119}
      120
        LNode {120: V120, 121: V121}
      122
        LNode {122: V122, 123: V123, 124: V124}
    }
}
''');
    expect(tree.remove(112), 'V112');
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {0: V0, 1: V1}
      2
        LNode {2: V2, 3: V3}
      4
        LNode {4: V4, 5: V5}
      6
        LNode {6: V6, 7: V7}
      8
        LNode {8: V8, 9: V9, 100: V100, 101: V101}
      102
        LNode {102: V102, 103: V103}
      104
        LNode {104: V104, 105: V105}
    }
  106
    INode {
        LNode {106: V106, 107: V107}
      108
        LNode {108: V108, 109: V109}
      110
        LNode {110: V110, 111: V111}
      112
        LNode {113: V113, 114: V114, 115: V115}
      116
        LNode {116: V116, 117: V117}
      118
        LNode {118: V118, 119: V119}
      120
        LNode {120: V120, 121: V121}
      122
        LNode {122: V122, 123: V123, 124: V124}
    }
}
''');
  }

  void test_remove_inner_borrowRight() {
    tree = new BPlusTree<int, String>(10, 4, _intComparator);
    for (int i = 100; i < 135; i++) {
      _insert(i, 'V$i');
    }
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {100: V100, 101: V101}
      102
        LNode {102: V102, 103: V103}
      104
        LNode {104: V104, 105: V105}
      106
        LNode {106: V106, 107: V107}
      108
        LNode {108: V108, 109: V109}
      110
        LNode {110: V110, 111: V111}
    }
  112
    INode {
        LNode {112: V112, 113: V113}
      114
        LNode {114: V114, 115: V115}
      116
        LNode {116: V116, 117: V117}
      118
        LNode {118: V118, 119: V119}
      120
        LNode {120: V120, 121: V121}
      122
        LNode {122: V122, 123: V123}
      124
        LNode {124: V124, 125: V125}
      126
        LNode {126: V126, 127: V127}
      128
        LNode {128: V128, 129: V129}
      130
        LNode {130: V130, 131: V131}
      132
        LNode {132: V132, 133: V133, 134: V134}
    }
}
''');
    expect(tree.remove(100), 'V100');
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {101: V101, 102: V102, 103: V103}
      104
        LNode {104: V104, 105: V105}
      106
        LNode {106: V106, 107: V107}
      108
        LNode {108: V108, 109: V109}
      110
        LNode {110: V110, 111: V111}
      112
        LNode {112: V112, 113: V113}
      114
        LNode {114: V114, 115: V115}
      116
        LNode {116: V116, 117: V117}
    }
  118
    INode {
        LNode {118: V118, 119: V119}
      120
        LNode {120: V120, 121: V121}
      122
        LNode {122: V122, 123: V123}
      124
        LNode {124: V124, 125: V125}
      126
        LNode {126: V126, 127: V127}
      128
        LNode {128: V128, 129: V129}
      130
        LNode {130: V130, 131: V131}
      132
        LNode {132: V132, 133: V133, 134: V134}
    }
}
''');
  }

  void test_remove_inner_mergeLeft() {
    _insertValues(15);
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {0: V0, 1: V1}
      2
        LNode {2: V2, 3: V3}
      4
        LNode {4: V4, 5: V5}
    }
  6
    INode {
        LNode {6: V6, 7: V7}
      8
        LNode {8: V8, 9: V9}
      10
        LNode {10: V10, 11: V11}
      12
        LNode {12: V12, 13: V13, 14: V14}
    }
}
''');
    expect(tree.remove(12), 'V12');
    expect(tree.remove(13), 'V13');
    expect(tree.remove(14), 'V14');
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {0: V0, 1: V1}
      2
        LNode {2: V2, 3: V3}
      4
        LNode {4: V4, 5: V5}
    }
  6
    INode {
        LNode {6: V6, 7: V7}
      8
        LNode {8: V8, 9: V9}
      10
        LNode {10: V10, 11: V11}
    }
}
''');
    expect(tree.remove(8), 'V8');
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1}
  2
    LNode {2: V2, 3: V3}
  4
    LNode {4: V4, 5: V5}
  6
    LNode {6: V6, 7: V7, 9: V9}
  10
    LNode {10: V10, 11: V11}
}
''');
  }

  void test_remove_inner_mergeRight() {
    _insertValues(12);
    _assertDebugString(tree, '''
INode {
    INode {
        LNode {0: V0, 1: V1}
      2
        LNode {2: V2, 3: V3}
      4
        LNode {4: V4, 5: V5}
    }
  6
    INode {
        LNode {6: V6, 7: V7}
      8
        LNode {8: V8, 9: V9, 10: V10, 11: V11}
    }
}
''');
    expect(tree.remove(0), 'V0');
    _assertDebugString(tree, '''
INode {
    LNode {1: V1, 2: V2, 3: V3}
  4
    LNode {4: V4, 5: V5}
  6
    LNode {6: V6, 7: V7}
  8
    LNode {8: V8, 9: V9, 10: V10, 11: V11}
}
''');
  }

  void test_remove_inner_notFound() {
    _insertValues(20);
    expect(tree.remove(100), isNull);
  }

  void test_remove_leafRoot_becomesEmpty() {
    _insertValues(1);
    _assertDebugString(tree, 'LNode {0: V0}\n');
    expect(tree.remove(0), 'V0');
    _assertDebugString(tree, 'LNode {}\n');
  }

  void test_remove_leafRoot_first() {
    _insertValues(3);
    _assertDebugString(tree, 'LNode {0: V0, 1: V1, 2: V2}\n');
    expect(tree.remove(0), 'V0');
    _assertDebugString(tree, 'LNode {1: V1, 2: V2}\n');
  }

  void test_remove_leafRoot_last() {
    _insertValues(3);
    _assertDebugString(tree, 'LNode {0: V0, 1: V1, 2: V2}\n');
    expect(tree.remove(2), 'V2');
    _assertDebugString(tree, 'LNode {0: V0, 1: V1}\n');
  }

  void test_remove_leafRoot_middle() {
    _insertValues(3);
    _assertDebugString(tree, 'LNode {0: V0, 1: V1, 2: V2}\n');
    expect(tree.remove(1), 'V1');
    _assertDebugString(tree, 'LNode {0: V0, 2: V2}\n');
  }

  void test_remove_leafRoot_notFound() {
    _insertValues(1);
    _assertDebugString(tree, 'LNode {0: V0}\n');
    expect(tree.remove(10), null);
    _assertDebugString(tree, 'LNode {0: V0}\n');
  }

  void test_remove_leaf_borrowLeft() {
    tree = new BPlusTree<int, String>(10, 10, _intComparator);
    for (int i = 20; i < 40; i++) {
      _insert(i, 'V$i');
    }
    for (int i = 0; i < 5; i++) {
      _insert(i, 'V$i');
    }
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1, 2: V2, 3: V3, 4: V4, 20: V20, 21: V21, 22: V22, 23: V23, 24: V24}
  25
    LNode {25: V25, 26: V26, 27: V27, 28: V28, 29: V29}
  30
    LNode {30: V30, 31: V31, 32: V32, 33: V33, 34: V34, 35: V35, 36: V36, 37: V37, 38: V38, 39: V39}
}
''');
    expect(tree.remove(25), 'V25');
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1, 2: V2, 3: V3, 4: V4, 20: V20, 21: V21}
  22
    LNode {22: V22, 23: V23, 24: V24, 26: V26, 27: V27, 28: V28, 29: V29}
  30
    LNode {30: V30, 31: V31, 32: V32, 33: V33, 34: V34, 35: V35, 36: V36, 37: V37, 38: V38, 39: V39}
}
''');
  }

  void test_remove_leaf_borrowRight() {
    tree = new BPlusTree<int, String>(10, 10, _intComparator);
    _insertValues(15);
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1, 2: V2, 3: V3, 4: V4}
  5
    LNode {5: V5, 6: V6, 7: V7, 8: V8, 9: V9, 10: V10, 11: V11, 12: V12, 13: V13, 14: V14}
}
''');
    expect(tree.remove(0), 'V0');
    _assertDebugString(tree, '''
INode {
    LNode {1: V1, 2: V2, 3: V3, 4: V4, 5: V5, 6: V6, 7: V7}
  8
    LNode {8: V8, 9: V9, 10: V10, 11: V11, 12: V12, 13: V13, 14: V14}
}
''');
  }

  void test_remove_leaf_mergeLeft() {
    _insertValues(9);
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1}
  2
    LNode {2: V2, 3: V3}
  4
    LNode {4: V4, 5: V5}
  6
    LNode {6: V6, 7: V7, 8: V8}
}
''');
    expect(tree.remove(2), 'V2');
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1, 3: V3}
  4
    LNode {4: V4, 5: V5}
  6
    LNode {6: V6, 7: V7, 8: V8}
}
''');
  }

  void test_remove_leaf_mergeRight() {
    _insertValues(9);
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1}
  2
    LNode {2: V2, 3: V3}
  4
    LNode {4: V4, 5: V5}
  6
    LNode {6: V6, 7: V7, 8: V8}
}
''');
    expect(tree.remove(1), 'V1');
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 2: V2, 3: V3}
  4
    LNode {4: V4, 5: V5}
  6
    LNode {6: V6, 7: V7, 8: V8}
}
''');
  }

  void test_remove_leaf_noReorder() {
    _insertValues(5);
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1}
  2
    LNode {2: V2, 3: V3, 4: V4}
}
''');
    expect(tree.remove(3), 'V3');
    _assertDebugString(tree, '''
INode {
    LNode {0: V0, 1: V1}
  2
    LNode {2: V2, 4: V4}
}
''');
  }

  void test_stress_evenOdd() {
    int count = 1000;
    // insert odd, forward
    for (int i = 1; i < count; i += 2) {
      _insert(i, 'V$i');
    }
    // insert even, backward
    for (int i = count - 2; i >= 0; i -= 2) {
      _insert(i, 'V$i');
    }
    // find every
    for (int i = 0; i < count; i++) {
      expect(tree.find(i), 'V$i');
    }
    // remove odd, backward
    for (int i = count - 1; i >= 1; i -= 2) {
      expect(tree.remove(i), 'V$i');
    }
    for (int i = 0; i < count; i++) {
      if (i.isEven) {
        expect(tree.find(i), 'V$i');
      } else {
        expect(tree.find(i), isNull);
      }
    }
    // remove even, forward
    for (int i = 0; i < count; i += 2) {
      tree.remove(i);
    }
    for (int i = 0; i < count; i++) {
      expect(tree.find(i), isNull);
    }
  }

  void test_stress_random() {
    tree = new BPlusTree<int, String>(10, 10, _intComparator);
    int maxKey = 1000000;
    int tryCount = 1000;
    Set<int> keys = new Set<int>();
    {
      Random random = new Random();
      for (int i = 0; i < tryCount; i++) {
        int key = random.nextInt(maxKey);
        keys.add(key);
        _insert(key, 'V$key');
      }
    }
    // find every
    for (int key in keys) {
      expect(tree.find(key), 'V$key');
    }
    // remove random keys
    {
      Random random = new Random();
      for (int key in new Set<int>.from(keys)) {
        if (random.nextBool()) {
          keys.remove(key);
          expect(tree.remove(key), 'V$key');
        }
      }
    }
    // find every remaining key
    for (int key in keys) {
      expect(tree.find(key), 'V$key');
    }
  }

  void _insert(int key, String value) {
    tree.insert(key, value);
  }

  void _insertValues(int count) {
    for (int i = 0; i < count; i++) {
      _insert(i, 'V$i');
    }
  }
}
