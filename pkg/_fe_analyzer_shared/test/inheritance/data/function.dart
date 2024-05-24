// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:A,Object*/
class A
    implements /*analyzer.error: CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY*/
        /*cfe|cfe:builder.error: FinalClassImplementedOutsideOfLibrary*/ Function {}

/*class: B:B,Object*/
class B
    extends /*analyzer.error: CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY*/ /*cfe|cfe:builder.error: FinalClassExtendedOutsideOfLibrary*/ Function {}

/*cfe|cfe:builder.class: C:C,Object,_C&Object&Function*/
/*analyzer.class: C:C,Object*/
/*cfe|cfe:builder.class: _C&Object&Function:Object,_C&Object&Function*/
class /*cfe|cfe:builder.error: SubtypeOfFinalIsNotBaseFinalOrSealed*/ C
    extends Object
    with /*analyzer.error: CompileTimeErrorCode.CLASS_USED_AS_MIXIN*/
        /*cfe|cfe:builder.error: CantUseClassAsMixin*/ Function {}

// CFE hides that this is a mixin declaration since its mixed in type has been
// removed.
/*cfe|cfe:builder.class: D:D,Object*/
class D = Object
    with /*analyzer.error: CompileTimeErrorCode.CLASS_USED_AS_MIXIN*/ /*cfe|cfe:builder.error: CantUseClassAsMixin*/
        Function;
