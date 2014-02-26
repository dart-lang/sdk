// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.change_record;

import 'package:observe/observe.dart';


/// Records a change to an [Observable].
// TODO(jmesserly): remove this type
abstract class ChangeRecord {}

/// A change record to a field of an observable object.
class PropertyChangeRecord<T> extends ChangeRecord {
  /// The object that changed.
  final object;

  /// The name of the property that changed.
  final Symbol name;

  /// The previous value of the property.
  final T oldValue;

  /// The new value of the property.
  final T newValue;

  PropertyChangeRecord(this.object, this.name, this.oldValue, this.newValue);

  String toString() =>
      '#<PropertyChangeRecord $name from: $oldValue to: $newValue>';
}
