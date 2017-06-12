// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {}

class BacklogListEditorState
    extends AbstractListEditorState<BacklogsState, BacklogListEditorState> {}

class BacklogsState extends MutableEntityState<BacklogsState> {}

abstract class AbstractListEditorState<ES extends ComponentState<ES>,
    S extends AbstractListEditorState<ES, S>> extends ComponentState<S> {}

abstract class ComponentState<S extends ComponentState<S>> {}

abstract class EntityState<ES extends EntityState<ES>>
    extends ComponentState<ES> {}

abstract class MutableEntityState<S extends MutableEntityState<S>>
    extends EntityState<S> implements ComponentState<S> {}
