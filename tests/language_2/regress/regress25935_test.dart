// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  AddIssueSourceMember2 m = new AddIssueSourceMember2();
}

abstract class RepoListEditorState2<M extends RepoListMember2<M>,
        S extends RepoListEditorState2<M, S>>
    extends AbstractListEditorState2<M, S> {}

abstract class AbstractListEditorState2<
    M extends AbstractListMember2<Object, M>,
    S extends AbstractListEditorState2<M, S>> extends ComponentState2<S> {}

class AddIssueSourceMember2 extends RepoListMember2<AddIssueSourceMember2> {}

class RepoListMember2<M extends RepoListMember2<M>>
    extends AbstractListMember2<Object, M> {}

abstract class AbstractListMember2<E, M extends AbstractListMember2<E, M>>
    extends ComponentState2<M> {}

abstract class ComponentState2<S extends ComponentState2<S>> {}
