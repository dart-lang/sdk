// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The js library allows Dart library authors to export their APIs to JavaScript
 * and to define Dart interfaces for JavaScript objects.
 */
library js;

export 'dart:js' show allowInterop, allowInteropCaptureThis;

/// A metadata annotation that indicates that a Library, Class, or member is
/// implemented directly in JavaScript. All external members of a class or
/// library with this annotation implicitly have it as well.
///
/// Specifying [name] customizes the JavaScript name to use. By default the
/// dart name is used. It is not valid to specify a custom [name] for class
/// instance members.
///
/// Example 1:
///
///     @Js('google.maps')
///     library maps;
///
///     external Map get map;
///
///     @Js("LatLng")
///     class Location {
///       external Location(num lat, num lng);
///     }
///
///     @Js()
///     class Map {
///       external Map(Location location);
///       external Location getLocation();
///     }
///
/// In this example the top level map getter will invoke the JavaScript getter
///     google.maps.map
/// Calls to the Map constructor will be translated to calls to the JavaScript
///     new google.maps.Map(location)
/// Calls to the Location constructor willbe translated to calls to the
/// JavaScript
///     new google.maps.LatLng(lat, lng)
/// because a custom JavaScript name for the Location class.
/// In general, we recommend against using custom JavaScript names whenever
/// possible as it is easier for users if the JavaScript names and Dart names
/// are consistent.
///
/// Example 2:
///     library utils;
///
///     @Js("JSON.stringify")
///     external String stringify(obj);
///
///     @Js()
///     void debugger();
///
/// In this example no custom JavaScript namespace is specified.
/// Calls to debugger map to calls to JavaScript
///     self.debugger()
/// Calls to stringify map to calls to
///     JSON.stringify(obj)
class Js {
  final String name;
  const Js([this.name]);
}
