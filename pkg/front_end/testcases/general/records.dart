// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(int, String) method1(int a, String b) => (a, b);
int method2([(int, String) record = const (0, '')]) => record.$1;
String method3([(int, String) record = const (0, '')]) => record.$2;
({int a, String b}) method4(int a, String b) => (a: a, b: b);
int method5([({int a, String b}) record = const (a: 0, b: '')]) => record.a;
String method6([({int a, String b}) record = const (a: 0, b: '')]) => record.b;
