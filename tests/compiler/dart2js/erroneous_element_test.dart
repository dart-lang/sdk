// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:compiler/implementation/elements/elements.dart';
import 'parser_helper.dart';

import 'package:compiler/implementation/elements/modelx.dart'
    show ErroneousElementX;

import 'package:compiler/implementation/dart2jslib.dart'
    show MessageKind;

void main() {
  ErroneousElement e = new ErroneousElementX(MessageKind.GENERIC,
                                             {'text': 'error'},
                                             'foo', null);
  Expect.stringEquals('<foo: error>', '$e');
}
