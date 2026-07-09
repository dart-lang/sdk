// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method1(List<dynamic> o) {
  switch (o) {
    case [...]:
      print(o);
  }
  switch (o) {
    case [_, ...]:
      print(o);
  }
  switch (o) {
    case [..., _]:
      print(o);
  }
  switch (o) {
    case [...var a]:
      print(a);
  }
  switch (o) {
    case [_, ...var a]:
      print(a);
  }
  switch (o) {
    case [...var a, _]:
      print(a);
  }
}

method2(o) {
  switch (o) {
    case [...]:
      print(o);
  }
  switch (o) {
    case [_, ...]:
      print(o);
  }
  switch (o) {
    case [..., _]:
      print(o);
  }
  switch (o) {
    case [...var a]:
      print(a);
  }
  switch (o) {
    case [_, ...var a]:
      print(a);
  }
  switch (o) {
    case [...var a, _]:
      print(a);
  }
}
