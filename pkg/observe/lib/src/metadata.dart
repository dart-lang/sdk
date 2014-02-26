// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.metadata;

/// Use `@observable` to make a field automatically observable, or to indicate
/// that a property is observable.
const ObservableProperty observable = const ObservableProperty();

/// An annotation that is used to make a property observable.
/// Normally this is used via the [observable] constant, for example:
///
///     class Monster {
///       @observable int health;
///     }
///
/// If needed, you can subclass this to create another annotation that will also
/// be treated as observable.
// Note: observable properties imply reflectable.
class ObservableProperty {
  const ObservableProperty();
}


/// Use `@reflectable` to make a type or member available to reflection in the
/// observe package. This is necessary to make the member visible to
/// [PathObserver], or similar systems, once the code is deployed.
const Reflectable reflectable = const Reflectable();

/// An annotation that is used to make a type or member reflectable. This makes
/// it available to [PathObserver] at runtime. For example:
///
///     @reflectable
///     class Monster extends ChangeNotifier {
///       int _health;
///       int get health => _health;
///       ...
///     }
///     ...
///       // This will work even if the code has been tree-shaken/minified:
///       final monster = new Monster();
///       new PathObserver(monster, 'health').changes.listen(...);
class Reflectable {
  const Reflectable();
}
