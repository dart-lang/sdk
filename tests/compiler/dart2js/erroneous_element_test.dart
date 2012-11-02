// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart' 
       show MessageKind;
import 'parser_helper.dart';

void main() {
  ErroneousElement e = new ErroneousElement(MessageKind.GENERIC, ['error'],
                                            buildSourceString('foo'), null);
  Expect.stringEquals('<foo: error>', '$e');
}
