// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.metadata;

/// Use `@observable` to make a field automatically observable, or to indicate
/// that a property is observable. This only works on classes that extend or
/// mix in `Observable`.
const ObservableProperty observable = const ObservableProperty();

/// An annotation that is used to make a property observable.
/// Normally this is used via the [observable] constant, for example:
///
///     class Monster extends Observable {
///       @observable int health;
///     }
///
// TODO(sigmund): re-add this to the documentation when it's really true:
//     If needed, you can subclass this to create another annotation that will
//     also be treated as observable.
// Note: observable properties imply reflectable.
class ObservableProperty {
  const ObservableProperty();
}


/// This can be used to retain any properties that you wish to access with
/// Dart's mirror system. If you import `package:observe/mirrors_used.dart`, all
/// classes or members annotated with `@reflectable` wil be preserved by dart2js
/// during compilation.  This is necessary to make the member visible to
/// `PathObserver`, or similar systems, once the code is deployed, if you are
/// not doing a different kind of code-generation for your app. If you are using
/// polymer, you most likely don't need to use this annotation anymore.
const Reflectable reflectable = const Reflectable();

/// An annotation that is used to make a type or member reflectable. This makes
/// it available to `PathObserver` at runtime. For example:
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
