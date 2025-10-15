// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:js/js.dart' as pkgJs;

@pkgJs.JS()
class PkgJS {}

@pkgJs.JS()
@pkgJs.anonymous
class Anonymous {}

@JS()
extension type ExtensionType._(JSObject _) {
  external PkgJS get getter;
  //                 ^
  // [web] External JS interop member contains an invalid type: 'PkgJS'.

  external set setter(Anonymous _);
  //           ^
  // [web] External JS interop member contains an invalid type: 'Anonymous'.
}

extension ExtensionTypeExtension on ExtensionType {
  external PkgJS get extensionGetter;
  //                 ^
  // [web] External JS interop member contains an invalid type: 'PkgJS'.

  external set extensionSetter(Anonymous _);
  //           ^
  // [web] External JS interop member contains an invalid type: 'Anonymous'.
}

@JS()
external PkgJS get getter;
//                 ^
// [web] External JS interop member contains an invalid type: 'PkgJS'.

@JS()
external set setter(Anonymous _);
//           ^
// [web] External JS interop member contains an invalid type: 'Anonymous'.

@JS()
external void optionalParameters(List _, [Anonymous __]);
//            ^
// [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*, *Anonymous*)'.

// While users can't use both positional and named parameters, make sure that
// the error around invalid types is still accurate.
@JS()
external void positionalAndNamedParameters(List _, {Anonymous a});
//            ^
// [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*, {*a: Anonymous*})'.
//                                                            ^
// [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.

void main() {}
