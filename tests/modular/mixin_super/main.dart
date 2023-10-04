// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin Diagnosticable {
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

class DiagnosticPropertiesBuilder {}

abstract class PointerEvent with Diagnosticable {}

abstract class PointerSignalEvent extends PointerEvent {}

mixin _PointerEventDescription on PointerEvent {
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
mixin _CopyPointerScrollEvent on PointerEvent {}

class PointerScrollEvent extends PointerSignalEvent
    with _PointerEventDescription, _CopyPointerScrollEvent {
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}

main() {
  new PointerScrollEvent()
      .debugFillProperties(new DiagnosticPropertiesBuilder());
}
