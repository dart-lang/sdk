// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the invalid uses of an interface class defined in a different library

import "shared_library_definitions.dart" show InterfaceClass;

mixin _MixinOnObject {}

/// Interface classes can not be extended.

// Simple extension.

class SimpleExtend extends InterfaceClass {}
//                         ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

base class BaseExtend extends InterfaceClass {}
//                            ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

interface class InterfaceExtend extends InterfaceClass {}
//                                      ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

final class FinalExtend extends InterfaceClass {}
//                              ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

// Extending with a sealed class.

sealed class SealedExtend extends InterfaceClass {}
//                                ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

// Extending via an anonymous mixin class.

class SimpleExtendWith extends InterfaceClass with _MixinOnObject {}
//                             ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

base class BaseExtendWith extends InterfaceClass with _MixinOnObject {}
//                                ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

interface class InterfaceExtendWith extends InterfaceClass
//                                          ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.
    with
        _MixinOnObject {}

final class FinalExtendWith extends InterfaceClass with _MixinOnObject {}
//                                  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

sealed class SealedExtendWith extends InterfaceClass with _MixinOnObject {}
//                                    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

// Extending via an anonymous mixin application class.

class SimpleExtendApplication = InterfaceClass with _MixinOnObject;
//                              ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

interface class InterfaceExtendApplication = InterfaceClass with _MixinOnObject;
//                                           ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

final class FinalExtendApplication = InterfaceClass with _MixinOnObject;
//                                   ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

base class BaseExtendApplication = InterfaceClass with _MixinOnObject;
//                                 ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

sealed class SealedExtendApplication = InterfaceClass with _MixinOnObject;
//                                     ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'InterfaceClass' can't be extended outside of its library because it's an interface class.

main() {}
