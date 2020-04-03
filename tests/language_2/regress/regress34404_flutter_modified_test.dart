// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test case is a reduction of some Flutter code, modified to use the new
// mixin syntax.  We wish to verify that the class _DismissibleState doesn't
// have any type inference errors.

class _DismissibleState extends State<Dismissible>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {}

abstract class State<T extends StatefulWidget> extends Diagnosticable {}

abstract class StatefulWidget extends Widget {}

abstract class Widget extends DiagnosticableTree {}

abstract class DiagnosticableTree extends Diagnosticable {}

abstract class Diagnosticable {}

class Dismissible extends StatefulWidget {}

mixin TickerProviderStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {}

abstract class TickerProvider {}

mixin AutomaticKeepAliveClientMixin<T extends StatefulWidget> on State<T> {}

main() {
  new _DismissibleState();
}
