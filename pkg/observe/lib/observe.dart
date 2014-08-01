// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for observing changes in model-view architectures.
///
/// **Warning:** This library is experimental, and APIs are subject to change.
///
/// This library is used to observe changes to [Observable] types. It also
/// has helpers to make implementing and using [Observable] objects easy.
///
/// You can provide an observable object in two ways. The simplest way is to
/// use dirty checking to discover changes automatically:
///
///     import 'package:observe/observe.dart';
///     import 'package:observe/mirrors_used.dart'; // for smaller code
///
///     class Monster extends Unit with Observable {
///       @observable int health = 100;
///
///       void damage(int amount) {
///         print('$this takes $amount damage!');
///         health -= amount;
///       }
///
///       toString() => 'Monster with $health hit points';
///     }
///
///     main() {
///       var obj = new Monster();
///       obj.changes.listen((records) {
///         print('Changes to $obj were: $records');
///       });
///       // No changes are delivered until we check for them
///       obj.damage(10);
///       obj.damage(20);
///       print('dirty checking!');
///       Observable.dirtyCheck();
///       print('done!');
///     }
///
/// A more sophisticated approach is to implement the change notification
/// manually. This avoids the potentially expensive [Observable.dirtyCheck]
/// operation, but requires more work in the object:
///
///     import 'package:observe/observe.dart';
///     import 'package:observe/mirrors_used.dart'; // for smaller code
///
///     class Monster extends Unit with ChangeNotifier {
///       int _health = 100;
///       @reflectable get health => _health;
///       @reflectable set health(val) {
///         _health = notifyPropertyChange(#health, _health, val);
///       }
///
///       void damage(int amount) {
///         print('$this takes $amount damage!');
///         health -= amount;
///       }
///
///       toString() => 'Monster with $health hit points';
///     }
///
///     main() {
///       var obj = new Monster();
///       obj.changes.listen((records) {
///         print('Changes to $obj were: $records');
///       });
///       // Schedules asynchronous delivery of these changes
///       obj.damage(10);
///       obj.damage(20);
///       print('done!');
///     }
///
/// **Note**: by default this package uses mirrors to access getters and setters
/// marked with `@reflectable`. Dart2js disables tree-shaking if there are any
/// uses of mirrors, unless you declare how mirrors are used (via the
/// [MirrorsUsed](https://api.dartlang.org/apidocs/channels/stable/#dart-mirrors.MirrorsUsed)
/// annotation).
///
/// As of version 0.10.0, this package doesn't declare `@MirrorsUsed`. This is
/// because we intend to use mirrors for development time, but assume that
/// frameworks and apps that use this pacakge will either generate code that
/// replaces the use of mirrors, or add the `@MirrorsUsed` declaration
/// themselves.  For convenience, you can import
/// `package:observe/mirrors_used.dart` as shown on the first example above.
/// That will add a `@MirrorsUsed` annotation that preserves properties and
/// classes labeled with `@reflectable` and properties labeled with
/// `@observable`.
///
/// If you are using the `package:observe/mirrors_used.dart` import, you can
/// also make use of `@reflectable` on your own classes and dart2js will
/// preserve all of its members for reflection.
///
/// [Tools](https://www.dartlang.org/polymer-dart/) exist to convert the first
/// form into the second form automatically, to get the best of both worlds.
library observe;

// This library contains code ported from observe-js:
// https://github.com/Polymer/observe-js/blob/0152d542350239563d0f2cad39d22d3254bd6c2a/src/observe.js
// We port what is needed for data bindings. Most of the functionality is
// ported, except where differences are needed for Dart's Observable type.

export 'src/bindable.dart';
export 'src/bind_property.dart';
export 'src/change_notifier.dart';
export 'src/change_record.dart';
export 'src/list_path_observer.dart';
export 'src/list_diff.dart' show ListChangeRecord;
export 'src/metadata.dart';
export 'src/observable.dart' hide notifyPropertyChangeHelper;
export 'src/observable_box.dart';
export 'src/observable_list.dart';
export 'src/observable_map.dart';
export 'src/observer_transform.dart';
export 'src/path_observer.dart' hide getSegmentsOfPropertyPathForTesting;
export 'src/to_observable.dart';
