// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.summary.flat_buffers_test;

import 'package:analyzer/src/summary/flat_buffers.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(BuilderTest);
}

@reflectiveTest
class BuilderTest {
  void test_error_addInt32_withoutStartTable() {
    Builder builder = new Builder();
    expect(() {
      builder.addInt32(0, 0);
    }, throwsStateError);
  }

  void test_error_addOffset_withoutStartTable() {
    Builder builder = new Builder();
    expect(() {
      builder.addOffset(0, new Offset(0));
    }, throwsStateError);
  }

  void test_error_endTable_withoutStartTable() {
    Builder builder = new Builder();
    expect(() {
      builder.endTable();
    }, throwsStateError);
  }

  void test_error_startTable_duringTable() {
    Builder builder = new Builder();
    builder.startTable();
    expect(() {
      builder.startTable();
    }, throwsStateError);
  }

  void test_error_writeString_duringTable() {
    Builder builder = new Builder();
    builder.startTable();
    expect(() {
      builder.writeString('12345');
    }, throwsStateError);
  }

  void test_low() {
    Builder builder = new Builder(initialSize: 0);
    builder.lowReset();
    expect((builder..lowWriteUint8(1)).lowFinish(), [1]);
    expect((builder..lowWriteUint32(2)).lowFinish(), [2, 0, 0, 0, 0, 0, 0, 1]);
    expect((builder..lowWriteUint8(3)).lowFinish(),
        [0, 0, 0, 3, 2, 0, 0, 0, 0, 0, 0, 1]);
    expect((builder..lowWriteUint8(4)).lowFinish(),
        [0, 0, 4, 3, 2, 0, 0, 0, 0, 0, 0, 1]);
    expect((builder..lowWriteUint8(5)).lowFinish(),
        [0, 5, 4, 3, 2, 0, 0, 0, 0, 0, 0, 1]);
    expect((builder..lowWriteUint32(6)).lowFinish(),
        [6, 0, 0, 0, 0, 5, 4, 3, 2, 0, 0, 0, 0, 0, 0, 1]);
  }

  void test_table_default() {
    List<int> byteList;
    {
      Builder builder = new Builder(initialSize: 0);
      builder.startTable();
      builder.addInt32(0, 10, 10);
      builder.addInt32(1, 20, 10);
      Offset offset = builder.endTable();
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferPointer object = new BufferPointer.fromBytes(byteList).derefObject();
    // was not written, so uses the new default value
    expect(const Int32Reader().vTableGet(object, 0, 15), 15);
    // has the written value
    expect(const Int32Reader().vTableGet(object, 1, 15), 20);
  }

  void test_table_types() {
    List<int> byteList;
    {
      Builder builder = new Builder(initialSize: 0);
      Offset<String> stringOffset = builder.writeString('12345');
      builder.startTable();
      builder.addBool(0, true);
      builder.addInt8(1, 10);
      builder.addInt32(2, 20);
      builder.addOffset(3, stringOffset);
      builder.addInt32(4, 40);
      Offset offset = builder.endTable();
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferPointer object = new BufferPointer.fromBytes(byteList).derefObject();
    expect(const BoolReader().vTableGet(object, 0), true);
    expect(const Int8Reader().vTableGet(object, 1), 10);
    expect(const Int32Reader().vTableGet(object, 2), 20);
    expect(const StringReader().vTableGet(object, 3), '12345');
    expect(const Int32Reader().vTableGet(object, 4), 40);
  }

  void test_writeList_ofFloat64() {
    List<double> values = <double>[-1.234567, 3.4E+9, -5.6E-13, 7.8, 12.13];
    // write
    List<int> byteList;
    {
      Builder builder = new Builder(initialSize: 0);
      Offset offset = builder.writeListFloat64(values);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferPointer root = new BufferPointer.fromBytes(byteList);
    List<double> items = const Float64ListReader().read(root);
    expect(items, hasLength(5));
    expect(items, orderedEquals(values));
  }

  void test_writeList_ofInt32() {
    List<int> byteList;
    {
      Builder builder = new Builder(initialSize: 0);
      Offset offset = builder.writeListInt32(<int>[1, 2, 3, 4, 5]);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferPointer root = new BufferPointer.fromBytes(byteList);
    List<int> items = const ListReader<int>(const Int32Reader()).read(root);
    expect(items, hasLength(5));
    expect(items, orderedEquals(<int>[1, 2, 3, 4, 5]));
  }

  void test_writeList_ofObjects() {
    List<int> byteList;
    {
      Builder builder = new Builder(initialSize: 0);
      // write the object #1
      Offset object1;
      {
        builder.startTable();
        builder.addInt32(0, 10);
        builder.addInt32(1, 20);
        object1 = builder.endTable();
      }
      // write the object #1
      Offset object2;
      {
        builder.startTable();
        builder.addInt32(0, 100);
        builder.addInt32(1, 200);
        object2 = builder.endTable();
      }
      // write the list
      Offset offset = builder.writeList([object1, object2]);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferPointer root = new BufferPointer.fromBytes(byteList);
    List<TestPointImpl> items =
        const ListReader<TestPointImpl>(const TestPointReader()).read(root);
    expect(items, hasLength(2));
    expect(items[0].x, 10);
    expect(items[0].y, 20);
    expect(items[1].x, 100);
    expect(items[1].y, 200);
  }

  void test_writeList_ofStrings_asRoot() {
    List<int> byteList;
    {
      Builder builder = new Builder(initialSize: 0);
      Offset<String> str1 = builder.writeString('12345');
      Offset<String> str2 = builder.writeString('ABC');
      Offset offset = builder.writeList([str1, str2]);
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferPointer root = new BufferPointer.fromBytes(byteList);
    List<String> items =
        const ListReader<String>(const StringReader()).read(root);
    expect(items, hasLength(2));
    expect(items, contains('12345'));
    expect(items, contains('ABC'));
  }

  void test_writeList_ofStrings_inObject() {
    List<int> byteList;
    {
      Builder builder = new Builder(initialSize: 0);
      Offset listOffset = builder.writeList(
          [builder.writeString('12345'), builder.writeString('ABC')]);
      builder.startTable();
      builder.addOffset(0, listOffset);
      Offset offset = builder.endTable();
      byteList = builder.finish(offset);
    }
    // read and verify
    BufferPointer root = new BufferPointer.fromBytes(byteList);
    StringListWrapperImpl reader = new StringListWrapperReader().read(root);
    List<String> items = reader.items;
    expect(items, hasLength(2));
    expect(items, contains('12345'));
    expect(items, contains('ABC'));
  }
}

class StringListWrapperImpl {
  final BufferPointer bp;

  StringListWrapperImpl(this.bp);

  List<String> get items =>
      const ListReader<String>(const StringReader()).vTableGet(bp, 0);
}

class StringListWrapperReader extends TableReader<StringListWrapperImpl> {
  const StringListWrapperReader();

  @override
  StringListWrapperImpl createObject(BufferPointer object) {
    return new StringListWrapperImpl(object);
  }
}

class TestPointImpl {
  final BufferPointer bp;

  TestPointImpl(this.bp);

  int get x => const Int32Reader().vTableGet(bp, 0, 0);

  int get y => const Int32Reader().vTableGet(bp, 1, 0);
}

class TestPointReader extends TableReader<TestPointImpl> {
  const TestPointReader();

  @override
  TestPointImpl createObject(BufferPointer object) {
    return new TestPointImpl(object);
  }
}
