// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAliasElementTest_keepLinking);
    defineReflectiveTests(TypeAliasElementTest_fromBytes);
    // TODO(scheglov): implement augmentation
    // defineReflectiveTests(TypeAliasElementTest_augmentation_keepLinking);
    // defineReflectiveTests(TypeAliasElementTest_augmentation_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class TypeAliasElementTest extends ElementsBaseTest {
  test_codeRange_functionTypeAlias() async {
    var library = await buildLibrary('''
typedef Raw();

/// Comment 1.
/// Comment 2.
typedef HasDocComment();

@Object()
typedef HasAnnotation();

@Object()
/// Comment 1.
/// Comment 2.
typedef AnnotationThenComment();

/// Comment 1.
/// Comment 2.
@Object()
typedef CommentThenAnnotation();

/// Comment 1.
@Object()
/// Comment 2.
typedef CommentAroundAnnotation();
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 Raw @8
          element: <testLibrary>::@typeAlias::Raw
        #F2 HasDocComment @54
          element: <testLibrary>::@typeAlias::HasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
        #F3 HasAnnotation @90
          element: <testLibrary>::@typeAlias::HasAnnotation
          metadata
            Annotation
              atSign: @ @72
              name: SimpleIdentifier
                token: Object @73
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @79
                rightParenthesis: ) @80
              element2: dart:core::@class::Object::@constructor::new
        #F4 AnnotationThenComment @156
          element: <testLibrary>::@typeAlias::AnnotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @108
              name: SimpleIdentifier
                token: Object @109
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @115
                rightParenthesis: ) @116
              element2: dart:core::@class::Object::@constructor::new
        #F5 CommentThenAnnotation @230
          element: <testLibrary>::@typeAlias::CommentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @212
              name: SimpleIdentifier
                token: Object @213
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @219
                rightParenthesis: ) @220
              element2: dart:core::@class::Object::@constructor::new
        #F6 CommentAroundAnnotation @304
          element: <testLibrary>::@typeAlias::CommentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @271
              name: SimpleIdentifier
                token: Object @272
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @278
                rightParenthesis: ) @279
              element2: dart:core::@class::Object::@constructor::new
  typeAliases
    Raw
      reference: <testLibrary>::@typeAlias::Raw
      firstFragment: #F1
      aliasedType: dynamic Function()
    HasDocComment
      reference: <testLibrary>::@typeAlias::HasDocComment
      firstFragment: #F2
      documentationComment: /// Comment 1.\n/// Comment 2.
      aliasedType: dynamic Function()
    HasAnnotation
      reference: <testLibrary>::@typeAlias::HasAnnotation
      firstFragment: #F3
      metadata
        Annotation
          atSign: @ @72
          name: SimpleIdentifier
            token: Object @73
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @79
            rightParenthesis: ) @80
          element2: dart:core::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    AnnotationThenComment
      reference: <testLibrary>::@typeAlias::AnnotationThenComment
      firstFragment: #F4
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @108
          name: SimpleIdentifier
            token: Object @109
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @115
            rightParenthesis: ) @116
          element2: dart:core::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    CommentThenAnnotation
      reference: <testLibrary>::@typeAlias::CommentThenAnnotation
      firstFragment: #F5
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @212
          name: SimpleIdentifier
            token: Object @213
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @219
            rightParenthesis: ) @220
          element2: dart:core::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    CommentAroundAnnotation
      reference: <testLibrary>::@typeAlias::CommentAroundAnnotation
      firstFragment: #F6
      documentationComment: /// Comment 2.
      metadata
        Annotation
          atSign: @ @271
          name: SimpleIdentifier
            token: Object @272
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @278
            rightParenthesis: ) @279
          element2: dart:core::@class::Object::@constructor::new
      aliasedType: dynamic Function()
''');
  }

  test_codeRange_genericTypeAlias() async {
    var library = await buildLibrary('''
typedef Raw = Function();

/// Comment 1.
/// Comment 2.
typedef HasDocComment = Function();

@Object()
typedef HasAnnotation = Function();

@Object()
/// Comment 1.
/// Comment 2.
typedef AnnotationThenComment = Function();

/// Comment 1.
/// Comment 2.
@Object()
typedef CommentThenAnnotation = Function();

/// Comment 1.
@Object()
/// Comment 2.
typedef CommentAroundAnnotation = Function();
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 Raw @8
          element: <testLibrary>::@typeAlias::Raw
        #F2 HasDocComment @65
          element: <testLibrary>::@typeAlias::HasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
        #F3 HasAnnotation @112
          element: <testLibrary>::@typeAlias::HasAnnotation
          metadata
            Annotation
              atSign: @ @94
              name: SimpleIdentifier
                token: Object @95
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @101
                rightParenthesis: ) @102
              element2: dart:core::@class::Object::@constructor::new
        #F4 AnnotationThenComment @189
          element: <testLibrary>::@typeAlias::AnnotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @141
              name: SimpleIdentifier
                token: Object @142
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @148
                rightParenthesis: ) @149
              element2: dart:core::@class::Object::@constructor::new
        #F5 CommentThenAnnotation @274
          element: <testLibrary>::@typeAlias::CommentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @256
              name: SimpleIdentifier
                token: Object @257
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @263
                rightParenthesis: ) @264
              element2: dart:core::@class::Object::@constructor::new
        #F6 CommentAroundAnnotation @359
          element: <testLibrary>::@typeAlias::CommentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @326
              name: SimpleIdentifier
                token: Object @327
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @333
                rightParenthesis: ) @334
              element2: dart:core::@class::Object::@constructor::new
  typeAliases
    Raw
      reference: <testLibrary>::@typeAlias::Raw
      firstFragment: #F1
      aliasedType: dynamic Function()
    HasDocComment
      reference: <testLibrary>::@typeAlias::HasDocComment
      firstFragment: #F2
      documentationComment: /// Comment 1.\n/// Comment 2.
      aliasedType: dynamic Function()
    HasAnnotation
      reference: <testLibrary>::@typeAlias::HasAnnotation
      firstFragment: #F3
      metadata
        Annotation
          atSign: @ @94
          name: SimpleIdentifier
            token: Object @95
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @101
            rightParenthesis: ) @102
          element2: dart:core::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    AnnotationThenComment
      reference: <testLibrary>::@typeAlias::AnnotationThenComment
      firstFragment: #F4
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @141
          name: SimpleIdentifier
            token: Object @142
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @148
            rightParenthesis: ) @149
          element2: dart:core::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    CommentThenAnnotation
      reference: <testLibrary>::@typeAlias::CommentThenAnnotation
      firstFragment: #F5
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @256
          name: SimpleIdentifier
            token: Object @257
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @263
            rightParenthesis: ) @264
          element2: dart:core::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    CommentAroundAnnotation
      reference: <testLibrary>::@typeAlias::CommentAroundAnnotation
      firstFragment: #F6
      documentationComment: /// Comment 2.
      metadata
        Annotation
          atSign: @ @326
          name: SimpleIdentifier
            token: Object @327
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @333
            rightParenthesis: ) @334
          element2: dart:core::@class::Object::@constructor::new
      aliasedType: dynamic Function()
''');
  }

  test_functionTypeAlias_enclosingElements() async {
    var library = await buildLibrary(r'''
typedef void F<T>(int a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @15
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(int)
''');
  }

  test_functionTypeAlias_type_element() async {
    var library = await buildLibrary(r'''
typedef T F<T>();
void f(F<int> a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
      functions
        #F3 f @23
          element: <testLibrary>::@function::f
          formalParameters
            #F4 a @32
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function()
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F4
          type: int Function()
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
      returnType: void
''');
  }

  test_functionTypeAlias_typeParameters_variance_contravariant() async {
    var library = await buildLibrary(r'''
typedef void F<T>(T a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @15
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(T)
''');
  }

  test_functionTypeAlias_typeParameters_variance_contravariant2() async {
    var library = await buildLibrary(r'''
typedef void F1<T>(T a);
typedef F1<T> F2<T>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 @13
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F2 T @16
              element: #E0 T
        #F3 F2 @39
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F4 T @42
              element: #E1 T
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(T)
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: void Function(T) Function()
''');
  }

  test_functionTypeAlias_typeParameters_variance_contravariant3() async {
    var library = await buildLibrary(r'''
typedef F1<T> F2<T>();
typedef void F1<T>(T a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F2 @14
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F2 T @17
              element: #E0 T
        #F3 F1 @36
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F4 T @39
              element: #E1 T
  typeAliases
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(T) Function()
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: void Function(T)
''');
  }

  test_functionTypeAlias_typeParameters_variance_covariant() async {
    var library = await buildLibrary(r'''
typedef T F<T>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function()
''');
  }

  test_functionTypeAlias_typeParameters_variance_covariant2() async {
    var library = await buildLibrary(r'''
typedef List<T> F<T>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @16
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @18
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: List<T> Function()
''');
  }

  test_functionTypeAlias_typeParameters_variance_covariant3() async {
    var library = await buildLibrary(r'''
typedef T F1<T>();
typedef F1<T> F2<T>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 @10
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F2 T @13
              element: #E0 T
        #F3 F2 @33
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F4 T @36
              element: #E1 T
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function()
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: T Function() Function()
''');
  }

  test_functionTypeAlias_typeParameters_variance_covariant4() async {
    var library = await buildLibrary(r'''
typedef void F1<T>(T a);
typedef void F2<T>(F1<T> a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 @13
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F2 T @16
              element: #E0 T
        #F3 F2 @38
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F4 T @41
              element: #E1 T
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(T)
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: void Function(void Function(T))
''');
  }

  test_functionTypeAlias_typeParameters_variance_invariant() async {
    var library = await buildLibrary(r'''
typedef T F<T>(T a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function(T)
''');
  }

  test_functionTypeAlias_typeParameters_variance_invariant2() async {
    var library = await buildLibrary(r'''
typedef T F1<T>();
typedef F1<T> F2<T>(T a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 @10
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F2 T @13
              element: #E0 T
        #F3 F2 @33
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F4 T @36
              element: #E1 T
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function()
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: T Function() Function(T)
''');
  }

  test_functionTypeAlias_typeParameters_variance_unrelated() async {
    var library = await buildLibrary(r'''
typedef void F<T>(int a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @15
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(int)
''');
  }

  test_genericTypeAlias_enclosingElements() async {
    var library = await buildLibrary(r'''
typedef F<T> = void Function<U>(int a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function<U>(int)
''');
  }

  test_genericTypeAlias_recursive() async {
    var library = await buildLibrary('''
typedef F<X extends F> = Function(F);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 X @10
              element: #E0 X
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
          bound: dynamic
      aliasedType: dynamic Function(dynamic)
''');
  }

  test_new_typedef_function_notSimplyBounded_functionType_returnType() async {
    var library = await buildLibrary('''
typedef F = G Function();
typedef G = F Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
        #F2 G @34
          element: <testLibrary>::@typeAlias::G
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function()
    notSimplyBounded G
      reference: <testLibrary>::@typeAlias::G
      firstFragment: #F2
      aliasedType: dynamic Function()
''');
  }

  test_new_typedef_function_notSimplyBounded_functionType_returnType_viaInterfaceType() async {
    var library = await buildLibrary('''
typedef F = List<F> Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: List<dynamic> Function()
''');
  }

  test_new_typedef_function_notSimplyBounded_self() async {
    var library = await buildLibrary('''
typedef F<T extends F> = void Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      aliasedType: void Function()
''');
  }

  test_new_typedef_function_notSimplyBounded_simple_no_bounds() async {
    var library = await buildLibrary('''
typedef F<T> = void Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function()
''');
  }

  test_new_typedef_function_notSimplyBounded_simple_non_generic() async {
    var library = await buildLibrary('''
typedef F = void Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function()
''');
  }

  test_new_typedef_nonFunction_notSimplyBounded_self() async {
    var library = await buildLibrary('''
typedef F<T extends F> = List<int>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      aliasedType: List<int>
''');
  }

  test_new_typedef_nonFunction_notSimplyBounded_viaInterfaceType() async {
    var library = await buildLibrary('''
typedef F = List<F>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: List<dynamic>
''');
  }

  test_typeAlias_formalParameters_optional() async {
    var library = await buildLibrary(r'''
typedef A = void Function({int p});

void f(A a) {}
''');
    configuration.withFunctionTypeParameters = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
      functions
        #F2 f @42
          element: <testLibrary>::@function::f
          formalParameters
            #F3 a @46
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      aliasedType: void Function({int p})
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: void Function({int p})
            alias: <testLibrary>::@typeAlias::A
      returnType: void
''');
  }

  test_typeAlias_parameter_typeParameters() async {
    var library = await buildLibrary(r'''
typedef void F(T a<T, U>(U u));
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function(T Function<T, U>(U))
''');
  }

  test_typeAlias_typeParameters_variance_function_contravariant() async {
    var library = await buildLibrary(r'''
typedef F<T> = void Function(T);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(T)
''');
  }

  test_typeAlias_typeParameters_variance_function_contravariant2() async {
    var library = await buildLibrary(r'''
typedef F1<T> = void Function(T);
typedef F2<T> = F1<T> Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 @8
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F2 T @11
              element: #E0 T
        #F3 F2 @42
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F4 T @45
              element: #E1 T
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(T)
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: void Function(T) Function()
''');
  }

  test_typeAlias_typeParameters_variance_function_covariant() async {
    var library = await buildLibrary(r'''
typedef F<T> = T Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function()
''');
  }

  test_typeAlias_typeParameters_variance_function_covariant2() async {
    var library = await buildLibrary(r'''
typedef F<T> = List<T> Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: List<T> Function()
''');
  }

  test_typeAlias_typeParameters_variance_function_covariant3() async {
    var library = await buildLibrary(r'''
typedef F1<T> = T Function();
typedef F2<T> = F1<T> Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 @8
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F2 T @11
              element: #E0 T
        #F3 F2 @38
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F4 T @41
              element: #E1 T
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function()
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: T Function() Function()
''');
  }

  test_typeAlias_typeParameters_variance_function_covariant4() async {
    var library = await buildLibrary(r'''
typedef F1<T> = void Function(T);
typedef F2<T> = void Function(F1<T>);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 @8
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F2 T @11
              element: #E0 T
        #F3 F2 @42
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F4 T @45
              element: #E1 T
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(T)
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: void Function(void Function(T))
''');
  }

  test_typeAlias_typeParameters_variance_function_invalid() async {
    var library = await buildLibrary(r'''
class A {}
typedef F<T> = void Function(A<int>);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F3 F @19
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F4 T @21
              element: #E0 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
      aliasedType: void Function(A)
''');
  }

  test_typeAlias_typeParameters_variance_function_invalid2() async {
    var library = await buildLibrary(r'''
typedef F = void Function();
typedef G<T> = void Function(F<int>);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
        #F2 G @37
          element: <testLibrary>::@typeAlias::G
          typeParameters
            #F3 T @39
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function()
    G
      reference: <testLibrary>::@typeAlias::G
      firstFragment: #F2
      typeParameters
        #E0 T
          firstFragment: #F3
      aliasedType: void Function(void Function())
''');
  }

  test_typeAlias_typeParameters_variance_function_invariant() async {
    var library = await buildLibrary(r'''
typedef F<T> = T Function(T);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function(T)
''');
  }

  test_typeAlias_typeParameters_variance_function_invariant2() async {
    var library = await buildLibrary(r'''
typedef F1<T> = T Function();
typedef F2<T> = F1<T> Function(T);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 @8
          element: <testLibrary>::@typeAlias::F1
          typeParameters
            #F2 T @11
              element: #E0 T
        #F3 F2 @38
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F4 T @41
              element: #E1 T
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function()
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: T Function() Function(T)
''');
  }

  test_typeAlias_typeParameters_variance_function_unrelated() async {
    var library = await buildLibrary(r'''
typedef F<T> = void Function(int);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(int)
''');
  }

  test_typeAlias_typeParameters_variance_interface_contravariant() async {
    var library = await buildLibrary(r'''
typedef A<T> = List<void Function(T)>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: List<void Function(T)>
''');
  }

  test_typeAlias_typeParameters_variance_interface_contravariant2() async {
    var library = await buildLibrary(r'''
typedef A<T> = void Function(T);
typedef B<T> = List<A<T>>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
        #F3 B @41
          element: <testLibrary>::@typeAlias::B
          typeParameters
            #F4 T @43
              element: #E1 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function(T)
    B
      reference: <testLibrary>::@typeAlias::B
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: List<void Function(T)>
''');
  }

  test_typeAlias_typeParameters_variance_interface_covariant() async {
    var library = await buildLibrary(r'''
typedef A<T> = List<T>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: List<T>
''');
  }

  test_typeAlias_typeParameters_variance_interface_covariant2() async {
    var library = await buildLibrary(r'''
typedef A<T> = Map<int, T>;
typedef B<T> = List<A<T>>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
        #F3 B @36
          element: <testLibrary>::@typeAlias::B
          typeParameters
            #F4 T @38
              element: #E1 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: Map<int, T>
    B
      reference: <testLibrary>::@typeAlias::B
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: List<Map<int, T>>
''');
  }

  test_typeAlias_typeParameters_variance_record_contravariant() async {
    var library = await buildLibrary(r'''
typedef A<T> = (void Function(T), int);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: (void Function(T), int)
''');
  }

  test_typeAlias_typeParameters_variance_record_contravariant2() async {
    var library = await buildLibrary(r'''
typedef A<T> = (void Function(T), int);
typedef B<T> = List<A<T>>;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
        #F3 B @48
          element: <testLibrary>::@typeAlias::B
          typeParameters
            #F4 T @50
              element: #E1 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: (void Function(T), int)
    B
      reference: <testLibrary>::@typeAlias::B
      firstFragment: #F3
      typeParameters
        #E1 T
          firstFragment: #F4
      aliasedType: List<(void Function(T), int)>
''');
  }

  test_typeAlias_typeParameters_variance_record_covariant() async {
    var library = await buildLibrary(r'''
typedef A<T> = (T, int);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: (T, int)
''');
  }

  test_typeAlias_typeParameters_variance_record_invariant() async {
    var library = await buildLibrary(r'''
typedef A<T> = (T Function(T), int);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: (T Function(T), int)
''');
  }

  test_typeAlias_typeParameters_variance_record_unrelated() async {
    var library = await buildLibrary(r'''
typedef A<T> = (int, String);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: (int, String)
''');
  }

  test_typedef_function_generic() async {
    var library = await buildLibrary(
      'typedef F<T> = int Function<S>(List<S> list, num Function<A>(A), T);',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: int Function<S>(List<S>, num Function<A>(A), T)
''');
  }

  test_typedef_function_generic_asFieldType() async {
    var library = await buildLibrary(r'''
typedef Foo<S> = S Function<T>(T x);
class A {
  Foo<int> f;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @43
          element: <testLibrary>::@class::A
          fields
            #F2 f @58
              element: <testLibrary>::@class::A::@field::f
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic f
              element: <testLibrary>::@class::A::@getter::f
          setters
            #F5 synthetic f
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F6 value
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
      typeAliases
        #F7 Foo @8
          element: <testLibrary>::@typeAlias::Foo
          typeParameters
            #F8 S @12
              element: #E0 S
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F2
          type: int Function<T>(T)
            alias: <testLibrary>::@typeAlias::Foo
              typeArguments
                int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int Function<T>(T)
            alias: <testLibrary>::@typeAlias::Foo
              typeArguments
                int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F6
              type: int Function<T>(T)
                alias: <testLibrary>::@typeAlias::Foo
                  typeArguments
                    int
          returnType: void
  typeAliases
    Foo
      reference: <testLibrary>::@typeAlias::Foo
      firstFragment: #F7
      typeParameters
        #E0 S
          firstFragment: #F8
      aliasedType: S Function<T>(T)
''');
  }

  test_typedef_function_notSimplyBounded_dependency_via_param_type_name_included() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await buildLibrary('''
typedef F = void Function(C c);
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @38
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @40
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F @8
          element: <testLibrary>::@typeAlias::F
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: void Function(C<C<dynamic>>)
''');
  }

  test_typedef_function_notSimplyBounded_dependency_via_param_type_name_omitted() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await buildLibrary('''
typedef F = void Function(C);
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @36
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @38
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F @8
          element: <testLibrary>::@typeAlias::F
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: void Function(C<C<dynamic>>)
''');
  }

  test_typedef_function_notSimplyBounded_dependency_via_return_type() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await buildLibrary('''
typedef F = C Function();
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @32
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @34
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F @8
          element: <testLibrary>::@typeAlias::F
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: C<C<dynamic>> Function()
''');
  }

  test_typedef_function_typeParameters_f_bound_simple() async {
    var library = await buildLibrary(
      'typedef F<T extends U, U> = U Function(T t);',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
            #F3 U @23
              element: #E1 U
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: U
        #E1 U
          firstFragment: #F3
      aliasedType: U Function(T)
''');
  }

  test_typedef_legacy_documented() async {
    var library = await buildLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
typedef F();''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @68
          element: <testLibrary>::@typeAlias::F
          documentationComment: /**\n * Docs\n */
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      aliasedType: dynamic Function()
''');
  }

  test_typedef_legacy_notSimplyBounded_dependency_via_param_type() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await buildLibrary('''
typedef void F(C c);
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @27
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @29
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F @13
          element: <testLibrary>::@typeAlias::F
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: void Function(C<C<dynamic>>)
''');
  }

  test_typedef_legacy_notSimplyBounded_dependency_via_return_type() async {
    // F is considered "not simply bounded" because it expands to a type that
    // refers to C, which is not simply bounded.
    var library = await buildLibrary('''
typedef C F();
class C<T extends C<T>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @21
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T @23
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F @10
          element: <testLibrary>::@typeAlias::F
  classes
    notSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: C<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: C<C<dynamic>> Function()
''');
  }

  test_typedef_legacy_notSimplyBounded_self() async {
    var library = await buildLibrary('''
typedef void F<T extends F>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @15
              element: #E0 T
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_notSimplyBounded_simple_because_non_generic() async {
    var library = await buildLibrary('''
typedef void F();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_notSimplyBounded_simple_no_bounds() async {
    var library = await buildLibrary('typedef void F<T>();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @15
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_parameter_hasImplicitType() async {
    var library = await buildLibrary(r'''
typedef void F(int a, b, [int c, d]);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function(int, dynamic, [int, dynamic])
''');
  }

  test_typedef_legacy_parameter_parameters() async {
    var library = await buildLibrary('typedef F(g(x, y));');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function(dynamic Function(dynamic, dynamic))
''');
  }

  test_typedef_legacy_parameter_parameters_in_generic_class() async {
    var library = await buildLibrary('typedef F<A, B>(A g(B x));');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 A @10
              element: #E0 A
            #F3 B @13
              element: #E1 B
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 A
          firstFragment: #F2
        #E1 B
          firstFragment: #F3
      aliasedType: dynamic Function(A Function(B))
''');
  }

  test_typedef_legacy_parameter_return_type() async {
    var library = await buildLibrary('typedef F(int g());');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function(int Function())
''');
  }

  test_typedef_legacy_parameter_type() async {
    var library = await buildLibrary('typedef F(int i);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function(int)
''');
  }

  test_typedef_legacy_parameter_type_generic() async {
    var library = await buildLibrary('typedef F<T>(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @10
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: dynamic Function(T)
''');
  }

  test_typedef_legacy_parameters() async {
    var library = await buildLibrary('typedef F(x, y);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function(dynamic, dynamic)
''');
  }

  test_typedef_legacy_parameters_named() async {
    var library = await buildLibrary('typedef F({y, z, x});');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function({dynamic x, dynamic y, dynamic z})
''');
  }

  test_typedef_legacy_return_type() async {
    var library = await buildLibrary('typedef int F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @12
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: int Function()
''');
  }

  test_typedef_legacy_return_type_generic() async {
    var library = await buildLibrary('typedef T F<T>();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T Function()
''');
  }

  test_typedef_legacy_return_type_implicit() async {
    var library = await buildLibrary('typedef F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function()
''');
  }

  test_typedef_legacy_return_type_void() async {
    var library = await buildLibrary('typedef void F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_typeParameters() async {
    var library = await buildLibrary('typedef U F<T, U>(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
            #F3 U @15
              element: #E1 U
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      aliasedType: U Function(T)
''');
  }

  test_typedef_legacy_typeParameters_bound() async {
    var library = await buildLibrary(
      'typedef U F<T extends Object, U extends D>(T t); class D {}',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class D @55
          element: <testLibrary>::@class::D
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F3 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F4 T @12
              element: #E0 T
            #F5 U @30
              element: #E1 U
  classes
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F2
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F4
          bound: Object
        #E1 U
          firstFragment: #F5
          bound: D
      aliasedType: U Function(T)
''');
  }

  test_typedef_legacy_typeParameters_bound_recursive() async {
    var library = await buildLibrary('typedef void F<T extends F>();');
    // Typedefs cannot reference themselves.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @15
              element: #E0 T
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_typeParameters_bound_recursive2() async {
    var library = await buildLibrary('typedef void F<T extends List<F>>();');
    // Typedefs cannot reference themselves.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @15
              element: #E0 T
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: List<dynamic>
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_typeParameters_f_bound_complex() async {
    var library = await buildLibrary('typedef U F<T extends List<U>, U>(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
            #F3 U @31
              element: #E1 U
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: List<U>
        #E1 U
          firstFragment: #F3
      aliasedType: U Function(T)
''');
  }

  test_typedef_legacy_typeParameters_f_bound_simple() async {
    var library = await buildLibrary('typedef U F<T extends U, U>(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @10
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T @12
              element: #E0 T
            #F3 U @25
              element: #E1 U
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: U
        #E1 U
          firstFragment: #F3
      aliasedType: U Function(T)
''');
  }

  @SkippedTest(
    issue: 'https://github.com/dart-lang/sdk/issues/45291',
    reason: 'Type dynamic is special, no support for its aliases yet',
  )
  test_typedef_nonFunction_aliasElement_dynamic() async {
    var library = await buildLibrary(r'''
typedef A = dynamic;
void f(A a) {}
''');

    checkElementText(library, r'''
typedef A = dynamic;
void f(dynamic<aliasElement: self::@typeAlias::A> a) {}
''');
  }

  test_typedef_nonFunction_aliasElement_functionType() async {
    var library = await buildLibrary(r'''
typedef A1 = void Function();
typedef A2<R> = R Function();
void f1(A1 a) {}
void f2(A2<int> a) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A1 @8
          element: <testLibrary>::@typeAlias::A1
        #F2 A2 @38
          element: <testLibrary>::@typeAlias::A2
          typeParameters
            #F3 R @41
              element: #E0 R
      functions
        #F4 f1 @65
          element: <testLibrary>::@function::f1
          formalParameters
            #F5 a @71
              element: <testLibrary>::@function::f1::@formalParameter::a
        #F6 f2 @82
          element: <testLibrary>::@function::f2
          formalParameters
            #F7 a @93
              element: <testLibrary>::@function::f2::@formalParameter::a
  typeAliases
    A1
      reference: <testLibrary>::@typeAlias::A1
      firstFragment: #F1
      aliasedType: void Function()
    A2
      reference: <testLibrary>::@typeAlias::A2
      firstFragment: #F2
      typeParameters
        #E0 R
          firstFragment: #F3
      aliasedType: R Function()
  functions
    f1
      reference: <testLibrary>::@function::f1
      firstFragment: #F4
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F5
          type: void Function()
            alias: <testLibrary>::@typeAlias::A1
      returnType: void
    f2
      reference: <testLibrary>::@function::f2
      firstFragment: #F6
      formalParameters
        #E2 requiredPositional a
          firstFragment: #F7
          type: int Function()
            alias: <testLibrary>::@typeAlias::A2
              typeArguments
                int
      returnType: void
''');
  }

  test_typedef_nonFunction_aliasElement_interfaceType() async {
    var library = await buildLibrary(r'''
typedef A1 = List<int>;
typedef A2<T, U> = Map<T, U>;
void f1(A1 a) {}
void f2(A2<int, String> a) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A1 @8
          element: <testLibrary>::@typeAlias::A1
        #F2 A2 @32
          element: <testLibrary>::@typeAlias::A2
          typeParameters
            #F3 T @35
              element: #E0 T
            #F4 U @38
              element: #E1 U
      functions
        #F5 f1 @59
          element: <testLibrary>::@function::f1
          formalParameters
            #F6 a @65
              element: <testLibrary>::@function::f1::@formalParameter::a
        #F7 f2 @76
          element: <testLibrary>::@function::f2
          formalParameters
            #F8 a @95
              element: <testLibrary>::@function::f2::@formalParameter::a
  typeAliases
    A1
      reference: <testLibrary>::@typeAlias::A1
      firstFragment: #F1
      aliasedType: List<int>
    A2
      reference: <testLibrary>::@typeAlias::A2
      firstFragment: #F2
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F4
      aliasedType: Map<T, U>
  functions
    f1
      reference: <testLibrary>::@function::f1
      firstFragment: #F5
      formalParameters
        #E2 requiredPositional a
          firstFragment: #F6
          type: List<int>
            alias: <testLibrary>::@typeAlias::A1
      returnType: void
    f2
      reference: <testLibrary>::@function::f2
      firstFragment: #F7
      formalParameters
        #E3 requiredPositional a
          firstFragment: #F8
          type: Map<int, String>
            alias: <testLibrary>::@typeAlias::A2
              typeArguments
                int
                String
      returnType: void
''');
  }

  @SkippedTest(
    issue: 'https://github.com/dart-lang/sdk/issues/45291',
    reason: 'Type Never is special, no support for its aliases yet',
  )
  test_typedef_nonFunction_aliasElement_never() async {
    var library = await buildLibrary(r'''
typedef A1 = Never;
typedef A2<T> = Never?;
void f1(A1 a) {}
void f2(A2<int> a) {}
''');

    checkElementText(library, r'''
typedef A1 = Never;
typedef A2<T> = Never?;
void f1(Never<aliasElement: self::@typeAlias::A1> a) {}
void f2(Never?<aliasElement: self::@typeAlias::A2, aliasArguments: [int]> a) {}
''');
  }

  test_typedef_nonFunction_aliasElement_recordType_generic() async {
    var library = await buildLibrary(r'''
typedef A<T, U> = (T, U);
void f(A<int, String> a) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
            #F3 U @13
              element: #E1 U
      functions
        #F4 f @31
          element: <testLibrary>::@function::f
          formalParameters
            #F5 a @48
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      aliasedType: (T, U)
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F4
      formalParameters
        #E2 requiredPositional a
          firstFragment: #F5
          type: (int, String)
            alias: <testLibrary>::@typeAlias::A
              typeArguments
                int
                String
      returnType: void
''');
  }

  test_typedef_nonFunction_aliasElement_typeParameterType() async {
    var library = await buildLibrary(r'''
typedef A<T> = T;
void f<U>(A<U> a) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
      functions
        #F3 f @23
          element: <testLibrary>::@function::f
          typeParameters
            #F4 U @25
              element: #E1 U
          formalParameters
            #F5 a @33
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      typeParameters
        #E1 U
          firstFragment: #F4
      formalParameters
        #E2 requiredPositional a
          firstFragment: #F5
          type: U
            alias: <testLibrary>::@typeAlias::A
              typeArguments
                U
      returnType: void
''');
  }

  @SkippedTest(
    issue: 'https://github.com/dart-lang/sdk/issues/45291',
    reason: 'Type void is special, no support for its aliases yet',
  )
  test_typedef_nonFunction_aliasElement_void() async {
    var library = await buildLibrary(r'''
typedef A = void;
void f(A a) {}
''');

    checkElementText(library, r'''
typedef A = void;
void f(void<aliasElement: self::@typeAlias::A> a) {}
''');
  }

  test_typedef_nonFunction_asInterfaceType_interfaceType_none() async {
    var library = await buildLibrary(r'''
typedef X<T> = A<int, T>;
class A<T, U> {}
class B implements X<String> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @32
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @34
              element: #E0 T
            #F3 U @37
              element: #E1 U
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F5 class B @49
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      typeAliases
        #F7 X @8
          element: <testLibrary>::@typeAlias::X
          typeParameters
            #F8 T @10
              element: #E2 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      interfaces
        A<int, String>
          alias: <testLibrary>::@typeAlias::X
            typeArguments
              String
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      aliasedType: A<int, T>
''');
  }

  test_typedef_nonFunction_asInterfaceType_interfaceType_question() async {
    var library = await buildLibrary(r'''
typedef X<T> = A<T>?;
class A<T> {}
class B {}
class C {}
class D implements B, X<int>, C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @28
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @30
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B @42
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F6 class C @53
          element: <testLibrary>::@class::C
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F8 class D @64
          element: <testLibrary>::@class::D
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F10 X @8
          element: <testLibrary>::@typeAlias::X
          typeParameters
            #F11 T @10
              element: #E1 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F7
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F8
      interfaces
        B
        C
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F9
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F10
      typeParameters
        #E1 T
          firstFragment: #F11
      aliasedType: A<T>?
''');
  }

  test_typedef_nonFunction_asInterfaceType_interfaceType_question2() async {
    var library = await buildLibrary(r'''
typedef X<T> = A<T?>;
class A<T> {}
class B {}
class C {}
class D implements B, X<int>, C {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @28
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @30
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B @42
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F6 class C @53
          element: <testLibrary>::@class::C
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F8 class D @64
          element: <testLibrary>::@class::D
          constructors
            #F9 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F10 X @8
          element: <testLibrary>::@typeAlias::X
          typeParameters
            #F11 T @10
              element: #E1 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F7
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F8
      interfaces
        B
        A<int?>
          alias: <testLibrary>::@typeAlias::X
            typeArguments
              int
        C
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F9
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F10
      typeParameters
        #E1 T
          firstFragment: #F11
      aliasedType: A<T?>
''');
  }

  test_typedef_nonFunction_asInterfaceType_Never_none() async {
    var library = await buildLibrary(r'''
typedef X = Never;
class A implements X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @25
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F3 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F3
      aliasedType: Never
''');
  }

  test_typedef_nonFunction_asInterfaceType_Null_none() async {
    var library = await buildLibrary(r'''
typedef X = Null;
class A implements X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @24
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F3 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F3
      aliasedType: Null
''');
  }

  test_typedef_nonFunction_asInterfaceType_typeParameterType() async {
    var library = await buildLibrary(r'''
typedef X<T> = T;
class A {}
class B {}
class C<U> implements A, X<U>, B {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @24
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B @35
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C @46
          element: <testLibrary>::@class::C
          typeParameters
            #F6 U @48
              element: #E0 U
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F8 X @8
          element: <testLibrary>::@typeAlias::X
          typeParameters
            #F9 T @10
              element: #E1 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      typeParameters
        #E0 U
          firstFragment: #F6
      interfaces
        A
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F7
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F8
      typeParameters
        #E1 T
          firstFragment: #F9
      aliasedType: T
''');
  }

  test_typedef_nonFunction_asInterfaceType_void() async {
    var library = await buildLibrary(r'''
typedef X = void;
class A {}
class B {}
class C implements A, X, B {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @24
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B @35
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C @46
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F7 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      interfaces
        A
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F7
      aliasedType: void
''');
  }

  test_typedef_nonFunction_asMixinType_none() async {
    var library = await buildLibrary(r'''
typedef X = A<int>;
class A<T> {}
class B with X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @26
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @28
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B @40
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      typeAliases
        #F6 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: Object
      mixins
        A<int>
          alias: <testLibrary>::@typeAlias::X
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F6
      aliasedType: A<int>
''');
  }

  test_typedef_nonFunction_asMixinType_question() async {
    var library = await buildLibrary(r'''
typedef X = A<int>?;
class A<T> {}
mixin M1 {}
mixin M2 {}
class B with M1, X, M2 {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @27
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @29
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B @65
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      mixins
        #F6 mixin M1 @41
          element: <testLibrary>::@mixin::M1
        #F7 mixin M2 @53
          element: <testLibrary>::@mixin::M2
      typeAliases
        #F8 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: Object
      mixins
        M1
        M2
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F6
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F7
      superclassConstraints
        Object
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F8
      aliasedType: A<int>?
''');
  }

  test_typedef_nonFunction_asMixinType_question2() async {
    var library = await buildLibrary(r'''
typedef X = A<int?>;
class A<T> {}
mixin M1 {}
mixin M2 {}
class B with M1, X, M2 {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @27
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @29
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B @65
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      mixins
        #F6 mixin M1 @41
          element: <testLibrary>::@mixin::M1
        #F7 mixin M2 @53
          element: <testLibrary>::@mixin::M2
      typeAliases
        #F8 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: Object
      mixins
        M1
        A<int?>
          alias: <testLibrary>::@typeAlias::X
        M2
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F6
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F7
      superclassConstraints
        Object
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F8
      aliasedType: A<int?>
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_Never_none() async {
    var library = await buildLibrary(r'''
typedef X = Never;
class A extends X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @25
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F3 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F3
      aliasedType: Never
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_none() async {
    var library = await buildLibrary(r'''
typedef X = A<int>;
class A<T> {}
class B extends X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @26
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @28
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B @40
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      typeAliases
        #F6 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A<int>
        alias: <testLibrary>::@typeAlias::X
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int}
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F6
      aliasedType: A<int>
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_none_viaTypeParameter() async {
    var library = await buildLibrary(r'''
typedef X<T> = T;
class A<T> {}
class B extends X<A<int>> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @24
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @26
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B @38
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      typeAliases
        #F6 X @8
          element: <testLibrary>::@typeAlias::X
          typeParameters
            #F7 T @10
              element: #E1 T
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A<int>
        alias: <testLibrary>::@typeAlias::X
          typeArguments
            A<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int}
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
      aliasedType: T
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_Null_none() async {
    var library = await buildLibrary(r'''
typedef X = Null;
class A extends X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @24
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F3 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F3
      aliasedType: Null
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_question() async {
    var library = await buildLibrary(r'''
typedef X = A<int>?;
class A<T> {}
class D extends X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @27
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @29
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class D @41
          element: <testLibrary>::@class::D
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F6 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F6
      aliasedType: A<int>?
''');
  }

  test_typedef_nonFunction_asSuperType_interfaceType_question2() async {
    var library = await buildLibrary(r'''
typedef X = A<int?>;
class A<T> {}
class D extends X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @27
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @29
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class D @41
          element: <testLibrary>::@class::D
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F6 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      supertype: A<int?>
        alias: <testLibrary>::@typeAlias::X
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int?}
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F6
      aliasedType: A<int?>
''');
  }

  test_typedef_nonFunction_asSuperType_Never_none() async {
    var library = await buildLibrary(r'''
typedef X = Never;
class A extends X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @25
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F3 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F3
      aliasedType: Never
''');
  }

  test_typedef_nonFunction_asSuperType_Null_none() async {
    var library = await buildLibrary(r'''
typedef X = Null;
class A extends X {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @24
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      typeAliases
        #F3 X @8
          element: <testLibrary>::@typeAlias::X
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  typeAliases
    X
      reference: <testLibrary>::@typeAlias::X
      firstFragment: #F3
      aliasedType: Null
''');
  }

  test_typedef_nonFunction_missingName() async {
    var library = await buildLibrary(r'''
typedef = int;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 <null-name> (offset=0)
          element: <testLibrary>::@typeAlias::0
  typeAliases
    <null-name>
      reference: <testLibrary>::@typeAlias::0
      firstFragment: #F1
      aliasedType: int
''');
  }

  test_typedef_nonFunction_using_dynamic() async {
    var library = await buildLibrary(r'''
typedef A = dynamic;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
      functions
        #F2 f @26
          element: <testLibrary>::@function::f
          formalParameters
            #F3 a @30
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      aliasedType: dynamic
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: dynamic
      returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_disabled() async {
    var library = await buildLibrary(r'''
// @dart = 2.12
typedef A = int;
void f(A a) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @24
          element: <testLibrary>::@typeAlias::A
      functions
        #F2 f @38
          element: <testLibrary>::@function::f
          formalParameters
            #F3 a @42
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      aliasedType: dynamic Function()
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::A
      returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_noTypeParameters() async {
    var library = await buildLibrary(r'''
typedef A = int;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
      functions
        #F2 f @22
          element: <testLibrary>::@function::f
          formalParameters
            #F3 a @26
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      aliasedType: int
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: int
            alias: <testLibrary>::@typeAlias::A
      returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_noTypeParameters_question() async {
    var library = await buildLibrary(r'''
typedef A = int?;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
      functions
        #F2 f @23
          element: <testLibrary>::@function::f
          formalParameters
            #F3 a @27
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      aliasedType: int?
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: int?
            alias: <testLibrary>::@typeAlias::A
      returnType: void
''');
  }

  test_typedef_nonFunction_using_interface_withTypeParameters() async {
    var library = await buildLibrary(r'''
typedef A<T> = Map<int, T>;
void f(A<String> a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
      functions
        #F3 f @33
          element: <testLibrary>::@function::f
          formalParameters
            #F4 a @45
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: Map<int, T>
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F3
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F4
          type: Map<int, String>
            alias: <testLibrary>::@typeAlias::A
              typeArguments
                String
      returnType: void
''');
  }

  test_typedef_nonFunction_using_Never_none() async {
    var library = await buildLibrary(r'''
typedef A = Never;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
      functions
        #F2 f @24
          element: <testLibrary>::@function::f
          formalParameters
            #F3 a @28
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      aliasedType: Never
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: Never
      returnType: void
''');
  }

  test_typedef_nonFunction_using_Never_question() async {
    var library = await buildLibrary(r'''
typedef A = Never?;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
      functions
        #F2 f @25
          element: <testLibrary>::@function::f
          formalParameters
            #F3 a @29
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      aliasedType: Never?
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: Never?
      returnType: void
''');
  }

  test_typedef_nonFunction_using_typeParameter_none() async {
    var library = await buildLibrary(r'''
typedef A<T> = T;
void f1(A a) {}
void f2(A<int> a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
      functions
        #F3 f1 @23
          element: <testLibrary>::@function::f1
          formalParameters
            #F4 a @28
              element: <testLibrary>::@function::f1::@formalParameter::a
        #F5 f2 @39
          element: <testLibrary>::@function::f2
          formalParameters
            #F6 a @49
              element: <testLibrary>::@function::f2::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T
  functions
    f1
      reference: <testLibrary>::@function::f1
      firstFragment: #F3
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F4
          type: dynamic
      returnType: void
    f2
      reference: <testLibrary>::@function::f2
      firstFragment: #F5
      formalParameters
        #E2 requiredPositional a
          firstFragment: #F6
          type: int
            alias: <testLibrary>::@typeAlias::A
              typeArguments
                int
      returnType: void
''');
  }

  test_typedef_nonFunction_using_typeParameter_question() async {
    var library = await buildLibrary(r'''
typedef A<T> = T?;
void f1(A a) {}
void f2(A<int> a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
          typeParameters
            #F2 T @10
              element: #E0 T
      functions
        #F3 f1 @24
          element: <testLibrary>::@function::f1
          formalParameters
            #F4 a @29
              element: <testLibrary>::@function::f1::@formalParameter::a
        #F5 f2 @40
          element: <testLibrary>::@function::f2
          formalParameters
            #F6 a @50
              element: <testLibrary>::@function::f2::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      aliasedType: T?
  functions
    f1
      reference: <testLibrary>::@function::f1
      firstFragment: #F3
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F4
          type: dynamic
      returnType: void
    f2
      reference: <testLibrary>::@function::f2
      firstFragment: #F5
      formalParameters
        #E2 requiredPositional a
          firstFragment: #F6
          type: int?
            alias: <testLibrary>::@typeAlias::A
              typeArguments
                int
      returnType: void
''');
  }

  test_typedef_nonFunction_using_void() async {
    var library = await buildLibrary(r'''
typedef A = void;
void f(A a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 A @8
          element: <testLibrary>::@typeAlias::A
      functions
        #F2 f @23
          element: <testLibrary>::@function::f
          formalParameters
            #F3 a @27
              element: <testLibrary>::@function::f::@formalParameter::a
  typeAliases
    A
      reference: <testLibrary>::@typeAlias::A
      firstFragment: #F1
      aliasedType: void
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: void
      returnType: void
''');
  }

  test_typedef_selfReference_recordType() async {
    var library = await buildLibrary(r'''
typedef F = (F, int) Function();
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @8
          element: <testLibrary>::@typeAlias::F
  typeAliases
    notSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: (dynamic, int) Function()
''');
  }

  test_typedefs() async {
    var library = await buildLibrary('f() {} g() {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @0
          element: <testLibrary>::@function::f
        #F2 g @7
          element: <testLibrary>::@function::g
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      returnType: dynamic
    g
      reference: <testLibrary>::@function::g
      firstFragment: #F2
      returnType: dynamic
''');
  }
}

abstract class TypeAliasElementTest_augmentation extends ElementsBaseTest {
  test_typeAlias_augments_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment typedef A = int;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      typeAliases
        augment A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          aliasedType: int
          augmentationTargetAny: <testLibraryFragment>::@class::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <testLibrary>::@typeAlias::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
  typeAliases
    A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
      aliasedType: int
''');
  }

  test_typeAlias_augments_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment typedef A = int;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
void A() {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      functions
        A @20
          reference: <testLibraryFragment>::@function::A
          enclosingElement3: <testLibraryFragment>
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      typeAliases
        augment A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          aliasedType: int
          augmentationTargetAny: <testLibraryFragment>::@function::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      functions
        A @20
          reference: <testLibraryFragment>::@function::A
          element: <testLibrary>::@function::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <testLibrary>::@typeAlias::A
  typeAliases
    A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
      aliasedType: int
  functions
    A
      reference: <testLibrary>::@function::A
      firstFragment: <testLibraryFragment>::@function::A
      returnType: void
''');
  }

  test_typeAlias_augments_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment typedef A = int;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
int get A => 0;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static A @-1
          reference: <testLibraryFragment>::@topLevelVariable::A
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static get A @23
          reference: <testLibraryFragment>::@getter::A
          enclosingElement3: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      typeAliases
        augment A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          aliasedType: int
          augmentationTargetAny: <testLibraryFragment>::@getter::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic A (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::A
          element: <testLibrary>::@topLevelVariable::A
          getter2: <testLibraryFragment>::@getter::A
      getters
        get A @23
          reference: <testLibraryFragment>::@getter::A
          element: <testLibraryFragment>::@getter::A#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <testLibrary>::@typeAlias::A
  typeAliases
    A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
      aliasedType: int
  topLevelVariables
    synthetic A
      reference: <testLibrary>::@topLevelVariable::A
      firstFragment: <testLibraryFragment>::@topLevelVariable::A
      type: int
      getter: <testLibraryFragment>::@getter::A#element
  getters
    static get A
      firstFragment: <testLibraryFragment>::@getter::A
''');
  }

  test_typeAlias_augments_nothing() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment typedef A = int;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      typeAliases
        augment A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          aliasedType: int
  exportedReferences
  exportNamespace
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <testLibrary>::@typeAlias::A
  typeAliases
    A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
      aliasedType: int
  exportedReferences
  exportNamespace
''');
  }

  test_typeAlias_augments_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment typedef A = int;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
set A(int _) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static A @-1
          reference: <testLibraryFragment>::@topLevelVariable::A
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static set A= @19
          reference: <testLibraryFragment>::@setter::A
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @25
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      typeAliases
        augment A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          aliasedType: int
          augmentationTargetAny: <testLibraryFragment>::@setter::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic A (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::A
          element: <testLibrary>::@topLevelVariable::A
          setter2: <testLibraryFragment>::@setter::A
      setters
        set A @19
          reference: <testLibraryFragment>::@setter::A
          element: <testLibraryFragment>::@setter::A#element
          formalParameters
            _ @25
              element: <testLibraryFragment>::@setter::A::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <testLibrary>::@typeAlias::A
  typeAliases
    A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
      aliasedType: int
  topLevelVariables
    synthetic A
      reference: <testLibrary>::@topLevelVariable::A
      firstFragment: <testLibraryFragment>::@topLevelVariable::A
      type: int
      setter: <testLibraryFragment>::@setter::A#element
  setters
    static set A
      firstFragment: <testLibraryFragment>::@setter::A
      formalParameters
        requiredPositional _
          type: int
''');
  }

  test_typeAlias_augments_typeAlias() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment typedef A = int;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
typedef A = int;
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      typeAliases
        A @23
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      typeAliases
        augment notSimplyBounded A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          aliasedType: int
          augmentationTarget: <testLibraryFragment>::@typeAlias::A
  exportedReferences
    declared <testLibraryFragment>::@typeAlias::A
  exportNamespace
    A: <testLibraryFragment>::@typeAlias::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      typeAliases
        A @23
          reference: <testLibraryFragment>::@typeAlias::A
          element: <testLibrary>::@typeAlias::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <testLibrary>::@typeAlias::A
  typeAliases
    A
      firstFragment: <testLibraryFragment>::@typeAlias::A
      aliasedType: int
  exportedReferences
    declared <testLibraryFragment>::@typeAlias::A
  exportNamespace
    A: <testLibraryFragment>::@typeAlias::A
''');
  }
}

@reflectiveTest
class TypeAliasElementTest_augmentation_fromBytes
    extends TypeAliasElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class TypeAliasElementTest_augmentation_keepLinking
    extends TypeAliasElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class TypeAliasElementTest_fromBytes extends TypeAliasElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class TypeAliasElementTest_keepLinking extends TypeAliasElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
