// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  ContentTabsWidget();
}

class StatefulWidget {}

class State<T> {}

class WidgetsBindingObserver {}

class IBase {}

class ContentTabsWidget extends BaseStatefulWidget<ContentTabsState, dynamic> {}

class ContentTabsState<W extends ContentTabsWidget>
    extends BaseState<W, dynamic> {}

class BaseStatefulWidget<ST extends SuperState, T>
    extends SuperStatefulWidget<ST, T, IBase> {}

class BaseState<W extends StatefulWidget, T> extends SuperState<W, T, IBase> {}

class SuperStatefulWidget<S extends SuperState, T, B> extends StatefulWidget {}

class SuperState<W extends StatefulWidget, T, B> extends State<W>
    with WidgetsBindingObserver {}
