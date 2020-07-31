// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of regress_25389;

abstract class ComponentState<S extends ComponentState<S>> {}

abstract class AbstractListEditorState<D,
    S extends AbstractListEditorState<D, S>> extends ComponentState<S> {}

class IssueListEditorState
    extends AbstractListEditorState<String, IssueListEditorState>
    implements ComponentState<IssueListEditorState> {}
