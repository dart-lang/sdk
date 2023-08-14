// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when applying the mixin modifier to a class whose superclass is not
// Object.

mixin class NotObject {}

mixin class AlsoNotObject {}

mixin class MixinClass extends NotObject {}
//                             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT
// [cfe] The class 'MixinClass' can't be used as a mixin because it extends a class other than 'Object'.

abstract mixin class AbstractMixinClass extends NotObject {}
//                                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT
// [cfe] The class 'AbstractMixinClass' can't be used as a mixin because it extends a class other than 'Object'.

class SubclassNotObject with MixinClass {}
//                           ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_INHERITS_FROM_NOT_OBJECT
// [cfe] The class 'MixinClass' can't be used as a mixin because it extends a class other than 'Object'.

class AbstractSubclassNotObject with AbstractMixinClass {}
//                                   ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_INHERITS_FROM_NOT_OBJECT
// [cfe] The class 'AbstractMixinClass' can't be used as a mixin because it extends a class other than 'Object'.

mixin class TypeAliasWithTwo = Object with AlsoNotObject, NotObject;
//          ^
// [cfe] The class 'TypeAliasWithTwo' can't be used as a mixin because it extends a class other than 'Object'.
//                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT
