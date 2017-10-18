// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error-on-bad-type

library regress_25389;

part 'regress_25389_part.dart';

main() {
  new IssueListEditorState();
}

abstract class AbstractListEditor<D, S extends AbstractListEditorState<D, S>> {}
