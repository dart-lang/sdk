// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--optimization-counter-threshold=5

import "dart:ffi";
import "dart:io";

import "package:ffi/ffi.dart";
import "package:test/test.dart";

import '../lib/sqlite.dart';

void main() {
  final dbPath = Platform.script.resolve("test.db").path;
  test("sqlite integration test", () {
    Database d = Database(dbPath);
    d.execute("drop table if exists Cookies;");
    d.execute("""
      create table Cookies (
        id integer primary key,
        name text not null,
        alternative_name text
      );""");
    d.execute("""
      insert into Cookies (id, name, alternative_name)
      values
        (1,'Chocolade chip cookie', 'Chocolade cookie'),
        (2,'Ginger cookie', null),
        (3,'Cinnamon roll', null)
      ;""");
    Result result = d.query("""
      select
        id,
        name,
        alternative_name,
        case
          when id=1 then 'foo'
          when id=2 then 42
          when id=3 then null
        end as multi_typed_column
      from Cookies
      ;""");
    for (Row r in result) {
      int id = r.readColumnAsInt("id");
      expect(true, 1 <= id && id <= 3);
      String name = r.readColumnByIndex(1);
      expect(true, name is String);
      String alternativeName = r.readColumn("alternative_name");
      expect(true, alternativeName is String || alternativeName == null);
      dynamic multiTypedValue = r.readColumn("multi_typed_column");
      expect(
          true,
          multiTypedValue == 42 ||
              multiTypedValue == 'foo' ||
              multiTypedValue == null);
      print("$id $name $alternativeName $multiTypedValue");
    }
    result = d.query("""
      select
        id,
        name,
        alternative_name,
        case
          when id=1 then 'foo'
          when id=2 then 42
          when id=3 then null
        end as multi_typed_column
      from Cookies
      ;""");
    for (Row r in result) {
      int id = r.readColumnAsInt("id");
      expect(true, 1 <= id && id <= 3);
      String name = r.readColumnByIndex(1);
      expect(true, name is String);
      String alternativeName = r.readColumn("alternative_name");
      expect(true, alternativeName is String || alternativeName == null);
      dynamic multiTypedValue = r.readColumn("multi_typed_column");
      expect(
          true,
          multiTypedValue == 42 ||
              multiTypedValue == 'foo' ||
              multiTypedValue == null);
      print("$id $name $alternativeName $multiTypedValue");
      if (id == 2) {
        result.close();
        break;
      }
    }
    try {
      result.iterator.moveNext();
    } on SQLiteException catch (e) {
      print("expected exception on accessing result data after close: $e");
    }
    try {
      d.query("""
      select
        id,
        non_existing_column
      from Cookies
      ;""");
    } on SQLiteException catch (e) {
      print("expected this query to fail: $e");
    }
    d.execute("drop table Cookies;");
    d.close();
  });

  test("concurrent db open and queries", () {
    Database d = Database(dbPath);
    Database d2 = Database(dbPath);
    d.execute("drop table if exists Cookies;");
    d.execute("""
      create table Cookies (
        id integer primary key,
        name text not null,
        alternative_name text
      );""");
    d.execute("""
      insert into Cookies (id, name, alternative_name)
      values
        (1,'Chocolade chip cookie', 'Chocolade cookie'),
        (2,'Ginger cookie', null),
        (3,'Cinnamon roll', null)
      ;""");
    Result r = d.query("select * from Cookies;");
    Result r2 = d2.query("select * from Cookies;");
    r.iterator..moveNext();
    r2.iterator..moveNext();
    r.iterator..moveNext();
    Result r3 = d2.query("select * from Cookies;");
    r3.iterator..moveNext();
    expect(2, r.iterator.current.readColumn("id"));
    expect(1, r2.iterator.current.readColumn("id"));
    expect(1, r3.iterator.current.readColumn("id"));
    r.close();
    r2.close();
    r3.close();
    d.close();
    d2.close();
  });

  test("stress test", () {
    Database d = Database(dbPath);
    d.execute("drop table if exists Cookies;");
    d.execute("""
      create table Cookies (
        id integer primary key,
        name text not null,
        alternative_name text
      );""");
    int repeats = 100;
    for (int i = 0; i < repeats; i++) {
      d.execute("""
      insert into Cookies (name, alternative_name)
      values
        ('Chocolade chip cookie', 'Chocolade cookie'),
        ('Ginger cookie', null),
        ('Cinnamon roll', null)
      ;""");
    }
    Result r = d.query("select count(*) from Cookies;");
    int count = r.first.readColumnByIndexAsInt(0);
    expect(count, 3 * repeats);
    r.close();
    d.close();
  });
  test("Utf8 unit test", () {
    final String test = 'Hasta Mañana';
    final medium = Utf8.toUtf8(test);
    expect(test, medium.ref.toString());
    free(medium);
  });
}
