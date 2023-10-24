// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

typedef RecordType = (int, String);

typedef FunctionType = void Function();

typedef NullableInterfaceType = String?;

typedef NullableExtensionType = ExtensionType?;

extension Extension on int {}

class Class {}

class GenericClass<T> {}

typedef Alias = Class;

typedef GenericAlias<T> = GenericClass<T>;

extension type ExtensionType(int it) {}

extension type GenericExtensionType<T>(T it) {}

extension type ET_Null(Null it) implements Null /* Error */ {}

extension type ET_Dynamic(dynamic it) implements dynamic /* Error */ {}

extension type ET_Void(Null it) implements void /* Error */ {}

extension type ET_Never(Never it) implements Never /* Error */ {}

extension type ET_Object(Object it) implements Object /* Error */ {}

extension type ET_Record(Record it) implements Record /* Error */ {}

extension type ET_RecordType(RecordType it) implements RecordType /* Error */ {}

extension type ET_Function(Function it) implements Function /* Error */ {}

extension type ET_FunctionType(FunctionType it)
    implements FunctionType /* Error */ {}

extension type ET_NullableInterfaceType(NullableInterfaceType it)
    implements NullableInterfaceType /* Error */ {}

extension type ET_NullableExtensionType(int it)
    implements NullableExtensionType /* Error */ {}

extension type ET_FutureOr(FutureOr<int> it)
    implements FutureOr<int> /* Error */ {}

extension type ET_Extension(int it) implements Extension /* Error */ {}

extension type ET_TypeVariable<T>(T it) implements T /* Error */ {}

extension type ET_Class(Class it) implements Class /* Ok */ {}

extension type ET_GenericClass<T>(GenericClass<T> it)
    implements GenericClass<T> /* Ok */ {}

extension type ET_Alias(Alias it) implements Alias /* Ok */ {}

extension type ET_GenericAlias<T>(GenericAlias<T> it)
    implements GenericAlias<T> /* Ok */ {}

extension type ET_ExtensionType(int it)
    implements ExtensionType /* Ok */ {}

extension type ET_GenericExtensionType<T>(T it)
    implements GenericExtensionType<T> /* Ok */ {}
