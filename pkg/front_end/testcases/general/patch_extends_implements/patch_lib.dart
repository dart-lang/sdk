// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class Class1a {}

@patch
abstract class Class1b {}

@patch
class Class2a {}

@patch
class Class2b extends SuperClass {}

@patch
class Class3a {}

@patch
class Class3b implements Interface {}

@patch
class Class4a {}

@patch
class Class4b with Mixin {}

@patch
class Class5a {
  @patch
  factory Class5a() = Class5aImpl;
}

@patch
class Class5aImpl {}

@patch
class Class5b {
  @patch
  factory Class5b() = Class5bImpl;
}

@patch
class Class5bImpl implements Class5b {}

@patch
class Class5c {
  @patch
  factory Class5c() = Class5cImpl;
}

@patch
class Class5cImpl {}

@patch
class Class6a<T> {
  @patch
  factory Class6a(void Function(T) f) = _Class6aImpl<T>;
}

class _Class6aImpl<T> {
  _Class6aImpl(void Function(T) f);
}

@patch
class Class6b<T> {
  @patch
  factory Class6b(void Function(T) f) = _Class6bImpl<T>;
}

class _Class6bImpl<T> implements Class6b<T> {
  _Class6bImpl(void Function(T) f);
}

@patch
class Class6c<T> {
  @patch
  factory Class6c(void Function(T) f) = _Class6cImpl<T>;
}

class _Class6cImpl<T> {
  _Class6cImpl(void Function(T) f);
}
