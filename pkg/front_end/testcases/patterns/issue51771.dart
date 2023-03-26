// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method1(List<dynamic> o) {
  switch (o) {
    case [_]:
      print(o);
  }
  switch (o) {
    case [_, _]:
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
    case [_, ..., _]:
      print(o);
  }
}

method2(o) {
  switch (o) {
    case [_]:
      print(o);
  }
  switch (o) {
    case [_, _]:
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
    case [_, ..., _]:
      print(o);
  }
}

method3(List<dynamic> o) {
  switch (o) {
    case [_, 1]:
      print(o);
  }
  switch (o) {
    case [1, _]:
      print(o);
  }
  switch (o) {
    case [_, ...var a]:
      print(o);
  }
  switch (o) {
    case [...var a, _]:
      print(o);
  }
  switch (o) {
    case [1, ..., _]:
      print(o);
  }
  switch (o) {
    case [_, ..., 1]:
      print(o);
  }
}

method4(o) {
  switch (o) {
    case [_, 1]:
      print(o);
  }
  switch (o) {
    case [1, _]:
      print(o);
  }
  switch (o) {
    case [_, ...var a]:
      print(o);
  }
  switch (o) {
    case [...var a, _]:
      print(o);
  }
  switch (o) {
    case [1, ..., _]:
      print(o);
  }
  switch (o) {
    case [_, ..., 1]:
      print(o);
  }
}

method5(o) {
  switch (o) {
    case [int _]:
      print(o);
  }
  switch (o) {
    case [int _, String _]:
      print(o);
  }
  switch (o) {
    case [int _, ...]:
      print(o);
  }
  switch (o) {
    case [..., String _]:
      print(o);
  }
  switch (o) {
    case [String _, ..., int _]:
      print(o);
  }
}
