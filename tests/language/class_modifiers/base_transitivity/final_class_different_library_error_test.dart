// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the invalid uses of a final class defined in a different library

import "shared_library_definitions.dart" show FinalClass, SimpleClass;
import 'shared_library_definitions_legacy.dart' show LegacyImplementFinalCore;

mixin _MixinOnObject {}

/// It is an error if FinalClass is extended.

// Simple extension.

class SimpleExtend extends FinalClass {}
//                         ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

base class BaseExtend extends FinalClass {}
//                            ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

interface class InterfaceExtend extends FinalClass {}
//                                      ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

final class FinalExtend extends FinalClass {}
//                              ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

sealed class SealedExtend extends FinalClass {}
//                                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

// Extending via an anonymous mixin class.

class SimpleExtendWith extends FinalClass with _MixinOnObject {}
//                             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

base class BaseExtendWith extends FinalClass with _MixinOnObject {}
//                                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

interface class InterfaceExtendWith extends FinalClass with _MixinOnObject {}
//                                          ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

final class FinalExtendWith extends FinalClass with _MixinOnObject {}
//                                  ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

sealed class SealedExtendWith extends FinalClass with _MixinOnObject {}
//                                    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

// Extending via an anonymous mixin application class.

class SimpleExtendApplication = FinalClass with _MixinOnObject;
//                              ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

base class BaseExtendApplication = FinalClass with _MixinOnObject;
//                                 ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

interface class InterfaceExtendApplication = FinalClass with _MixinOnObject;
//                                           ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

final class FinalExtendApplication = FinalClass with _MixinOnObject;
//                                   ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

sealed class SealedExtendApplication = FinalClass with _MixinOnObject;
//                                     ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be extended outside of its library because it's a final class.

/// It is an error if FinalClass is implemented by something which is not base,
/// final or sealed.

// Simple implementation.

class SimpleImplement implements FinalClass {}
//                               ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

base class BaseImplement implements FinalClass {}
//                                  ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

interface class InterfaceImplement implements FinalClass {}
//                                            ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

final class FinalImplement implements FinalClass {}
//                                    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

sealed class SealedImplement implements FinalClass {}
//                                      ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

// Implementing with a mixin class.

mixin class SimpleMixinClassImplement implements FinalClass {}
//                                               ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

base mixin class BaseMixinClassImplement implements FinalClass {}
//                                                  ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

// Implementing with a mixin application class.

class SimpleImplementApplication = Object
    with _MixinOnObject
    implements FinalClass;
//             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

base class BaseImplementApplication = Object
    with _MixinOnObject
    implements FinalClass;
//             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

interface class InterfaceImplementApplication = Object
    with _MixinOnObject
    implements FinalClass;
//             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

final class FinalImplementApplication = Object
    with _MixinOnObject
    implements FinalClass;
//             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

sealed class SealedImplementApplication = Object
    with _MixinOnObject
    implements FinalClass;
//             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

// Implementing with a mixin.

mixin SimpleMixinImplement implements FinalClass {}
//                                    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

base mixin BaseMixinImplement implements FinalClass {}
//                                       ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be implemented outside of its library because it's a final class.

// Implementing a legacy class that implements a core library final class.

class LegacyImplement implements LegacyImplementFinalCore {
//                               ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] unspecified
  int get key => 0;
  int get value => 1;
  String toString() => "Bad";
}

// It is an error if FinalClass is the `on` type of a mixin outside of
// FinalClass' library.

mixin SimpleMixinOn on FinalClass {}
//                     ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be used as a mixin superclass constraint outside of its library because it's a final class.

mixin SimpleMixinOnFinalSimple on FinalClass, SimpleClass {}
//                                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be used as a mixin superclass constraint outside of its library because it's a final class.

mixin SimpleMixinOnSimpleFinal on SimpleClass, FinalClass {}
//                                             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be used as a mixin superclass constraint outside of its library because it's a final class.

base mixin BaseMixinOn on FinalClass {}
//                        ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be used as a mixin superclass constraint outside of its library because it's a final class.

base mixin BaseMixinOnFinalSimple on SimpleClass, FinalClass {}
//                                                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be used as a mixin superclass constraint outside of its library because it's a final class.

base mixin BaseMixinOnSimpleFinal on FinalClass, SimpleClass {}
//                                   ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'FinalClass' can't be used as a mixin superclass constraint outside of its library because it's a final class.

main() {}
