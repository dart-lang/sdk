// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAliasElementTest_keepLinking);
    defineReflectiveTests(TypeAliasElementTest_fromBytes);
    defineReflectiveTests(TypeAliasElementTest_augmentation_keepLinking);
    defineReflectiveTests(TypeAliasElementTest_augmentation_fromBytes);
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased Raw @8
          reference: <testLibraryFragment>::@typeAlias::Raw
          codeOffset: 0
          codeLength: 14
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        functionTypeAliasBased HasDocComment @54
          reference: <testLibraryFragment>::@typeAlias::HasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          codeOffset: 16
          codeLength: 54
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        functionTypeAliasBased HasAnnotation @90
          reference: <testLibraryFragment>::@typeAlias::HasAnnotation
          metadata
            Annotation
              atSign: @ @72
              name: SimpleIdentifier
                token: Object @73
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @79
                rightParenthesis: ) @80
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 72
          codeLength: 34
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        functionTypeAliasBased AnnotationThenComment @156
          reference: <testLibraryFragment>::@typeAlias::AnnotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @108
              name: SimpleIdentifier
                token: Object @109
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @115
                rightParenthesis: ) @116
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 108
          codeLength: 72
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        functionTypeAliasBased CommentThenAnnotation @230
          reference: <testLibraryFragment>::@typeAlias::CommentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @212
              name: SimpleIdentifier
                token: Object @213
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @219
                rightParenthesis: ) @220
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 182
          codeLength: 72
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        functionTypeAliasBased CommentAroundAnnotation @304
          reference: <testLibraryFragment>::@typeAlias::CommentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @271
              name: SimpleIdentifier
                token: Object @272
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @278
                rightParenthesis: ) @279
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 271
          codeLength: 59
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        Raw @8
          reference: <testLibraryFragment>::@typeAlias::Raw
          element: <none>
        HasDocComment @54
          reference: <testLibraryFragment>::@typeAlias::HasDocComment
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
        HasAnnotation @90
          reference: <testLibraryFragment>::@typeAlias::HasAnnotation
          element: <none>
          metadata
            Annotation
              atSign: @ @72
              name: SimpleIdentifier
                token: Object @73
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @79
                rightParenthesis: ) @80
              element: dart:core::<fragment>::@class::Object::@constructor::new
        AnnotationThenComment @156
          reference: <testLibraryFragment>::@typeAlias::AnnotationThenComment
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @108
              name: SimpleIdentifier
                token: Object @109
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @115
                rightParenthesis: ) @116
              element: dart:core::<fragment>::@class::Object::@constructor::new
        CommentThenAnnotation @230
          reference: <testLibraryFragment>::@typeAlias::CommentThenAnnotation
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @212
              name: SimpleIdentifier
                token: Object @213
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @219
                rightParenthesis: ) @220
              element: dart:core::<fragment>::@class::Object::@constructor::new
        CommentAroundAnnotation @304
          reference: <testLibraryFragment>::@typeAlias::CommentAroundAnnotation
          element: <none>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @271
              name: SimpleIdentifier
                token: Object @272
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @278
                rightParenthesis: ) @279
              element: dart:core::<fragment>::@class::Object::@constructor::new
  typeAliases
    Raw
      reference: <none>
      aliasedType: dynamic Function()
    HasDocComment
      reference: <none>
      documentationComment: /// Comment 1.\n/// Comment 2.
      aliasedType: dynamic Function()
    HasAnnotation
      reference: <none>
      metadata
        Annotation
          atSign: @ @72
          name: SimpleIdentifier
            token: Object @73
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @79
            rightParenthesis: ) @80
          element: dart:core::<fragment>::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    AnnotationThenComment
      reference: <none>
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @108
          name: SimpleIdentifier
            token: Object @109
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @115
            rightParenthesis: ) @116
          element: dart:core::<fragment>::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    CommentThenAnnotation
      reference: <none>
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @212
          name: SimpleIdentifier
            token: Object @213
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @219
            rightParenthesis: ) @220
          element: dart:core::<fragment>::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    CommentAroundAnnotation
      reference: <none>
      documentationComment: /// Comment 2.
      metadata
        Annotation
          atSign: @ @271
          name: SimpleIdentifier
            token: Object @272
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @278
            rightParenthesis: ) @279
          element: dart:core::<fragment>::@class::Object::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        Raw @8
          reference: <testLibraryFragment>::@typeAlias::Raw
          codeOffset: 0
          codeLength: 25
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        HasDocComment @65
          reference: <testLibraryFragment>::@typeAlias::HasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          codeOffset: 27
          codeLength: 65
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        HasAnnotation @112
          reference: <testLibraryFragment>::@typeAlias::HasAnnotation
          metadata
            Annotation
              atSign: @ @94
              name: SimpleIdentifier
                token: Object @95
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @101
                rightParenthesis: ) @102
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 94
          codeLength: 45
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        AnnotationThenComment @189
          reference: <testLibraryFragment>::@typeAlias::AnnotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @141
              name: SimpleIdentifier
                token: Object @142
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @148
                rightParenthesis: ) @149
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 141
          codeLength: 83
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        CommentThenAnnotation @274
          reference: <testLibraryFragment>::@typeAlias::CommentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @256
              name: SimpleIdentifier
                token: Object @257
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @263
                rightParenthesis: ) @264
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 226
          codeLength: 83
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        CommentAroundAnnotation @359
          reference: <testLibraryFragment>::@typeAlias::CommentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @326
              name: SimpleIdentifier
                token: Object @327
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @333
                rightParenthesis: ) @334
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 326
          codeLength: 70
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        Raw @8
          reference: <testLibraryFragment>::@typeAlias::Raw
          element: <none>
        HasDocComment @65
          reference: <testLibraryFragment>::@typeAlias::HasDocComment
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
        HasAnnotation @112
          reference: <testLibraryFragment>::@typeAlias::HasAnnotation
          element: <none>
          metadata
            Annotation
              atSign: @ @94
              name: SimpleIdentifier
                token: Object @95
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @101
                rightParenthesis: ) @102
              element: dart:core::<fragment>::@class::Object::@constructor::new
        AnnotationThenComment @189
          reference: <testLibraryFragment>::@typeAlias::AnnotationThenComment
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @141
              name: SimpleIdentifier
                token: Object @142
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @148
                rightParenthesis: ) @149
              element: dart:core::<fragment>::@class::Object::@constructor::new
        CommentThenAnnotation @274
          reference: <testLibraryFragment>::@typeAlias::CommentThenAnnotation
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @256
              name: SimpleIdentifier
                token: Object @257
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @263
                rightParenthesis: ) @264
              element: dart:core::<fragment>::@class::Object::@constructor::new
        CommentAroundAnnotation @359
          reference: <testLibraryFragment>::@typeAlias::CommentAroundAnnotation
          element: <none>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @326
              name: SimpleIdentifier
                token: Object @327
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @333
                rightParenthesis: ) @334
              element: dart:core::<fragment>::@class::Object::@constructor::new
  typeAliases
    Raw
      reference: <none>
      aliasedType: dynamic Function()
    HasDocComment
      reference: <none>
      documentationComment: /// Comment 1.\n/// Comment 2.
      aliasedType: dynamic Function()
    HasAnnotation
      reference: <none>
      metadata
        Annotation
          atSign: @ @94
          name: SimpleIdentifier
            token: Object @95
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @101
            rightParenthesis: ) @102
          element: dart:core::<fragment>::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    AnnotationThenComment
      reference: <none>
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @141
          name: SimpleIdentifier
            token: Object @142
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @148
            rightParenthesis: ) @149
          element: dart:core::<fragment>::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    CommentThenAnnotation
      reference: <none>
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @256
          name: SimpleIdentifier
            token: Object @257
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @263
            rightParenthesis: ) @264
          element: dart:core::<fragment>::@class::Object::@constructor::new
      aliasedType: dynamic Function()
    CommentAroundAnnotation
      reference: <none>
      documentationComment: /// Comment 2.
      metadata
        Annotation
          atSign: @ @326
          name: SimpleIdentifier
            token: Object @327
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @333
            rightParenthesis: ) @334
          element: dart:core::<fragment>::@class::Object::@constructor::new
      aliasedType: dynamic Function()
''');
  }

  test_functionTypeAlias_enclosingElements() async {
    var library = await buildLibrary(r'''
typedef void F<T>(int a);
''');
    var unit = library.definingCompilationUnit;

    var F = unit.typeAliases[0];
    expect(F.name, 'F');

    var T = F.typeParameters[0];
    expect(T.name, 'T');
    expect(T.enclosingElement3, same(F));

    var function = F.aliasedElement as GenericFunctionTypeElement;
    expect(function.enclosingElement3, same(F));

    var a = function.parameters[0];
    expect(a.name, 'a');
    expect(a.enclosingElement3, same(function));
  }

  test_functionTypeAlias_type_element() async {
    var library = await buildLibrary(r'''
typedef T F<T>();
F<int> a;
''');
    var unit = library.definingCompilationUnit;
    var type = unit.topLevelVariables[0].type as FunctionType;

    expect(type.alias!.element, same(unit.typeAliases[0]));
    _assertTypeStrings(type.alias!.typeArguments, ['int']);
  }

  test_functionTypeAlias_typeParameters_variance_contravariant() async {
    var library = await buildLibrary(r'''
typedef void F<T>(T a);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @15
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @20
                type: T
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @15
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F1 @13
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            contravariant T @16
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @21
                type: T
            returnType: void
        functionTypeAliasBased F2 @39
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            contravariant T @42
              defaultType: dynamic
          aliasedType: void Function(T) Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void Function(T)
              alias: <testLibraryFragment>::@typeAlias::F1
                typeArguments
                  T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @13
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @16
              element: <none>
        F2 @39
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @42
              element: <none>
  typeAliases
    F1
      reference: <none>
      typeParameters
        T
      aliasedType: void Function(T)
    F2
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F2 @14
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            contravariant T @17
              defaultType: dynamic
          aliasedType: void Function(T) Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void Function(T)
              alias: <testLibraryFragment>::@typeAlias::F1
                typeArguments
                  T
        functionTypeAliasBased F1 @36
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            contravariant T @39
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @44
                type: T
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F2 @14
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @17
              element: <none>
        F1 @36
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @39
              element: <none>
  typeAliases
    F2
      reference: <none>
      typeParameters
        T
      aliasedType: void Function(T) Function()
    F1
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            covariant T @12
              defaultType: dynamic
          aliasedType: T Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @12
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @16
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            covariant T @18
              defaultType: dynamic
          aliasedType: List<T> Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: List<T>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @16
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @18
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F1 @10
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            covariant T @13
              defaultType: dynamic
          aliasedType: T Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T
        functionTypeAliasBased F2 @33
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            covariant T @36
              defaultType: dynamic
          aliasedType: T Function() Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T Function()
              alias: <testLibraryFragment>::@typeAlias::F1
                typeArguments
                  T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @10
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @13
              element: <none>
        F2 @33
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @36
              element: <none>
  typeAliases
    F1
      reference: <none>
      typeParameters
        T
      aliasedType: T Function()
    F2
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F1 @13
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            contravariant T @16
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @21
                type: T
            returnType: void
        functionTypeAliasBased F2 @38
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            covariant T @41
              defaultType: dynamic
          aliasedType: void Function(void Function(T))
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @50
                type: void Function(T)
                  alias: <testLibraryFragment>::@typeAlias::F1
                    typeArguments
                      T
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @13
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @16
              element: <none>
        F2 @38
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @41
              element: <none>
  typeAliases
    F1
      reference: <none>
      typeParameters
        T
      aliasedType: void Function(T)
    F2
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            invariant T @12
              defaultType: dynamic
          aliasedType: T Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @17
                type: T
            returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @12
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F1 @10
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            covariant T @13
              defaultType: dynamic
          aliasedType: T Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T
        functionTypeAliasBased F2 @33
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            invariant T @36
              defaultType: dynamic
          aliasedType: T Function() Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @41
                type: T
            returnType: T Function()
              alias: <testLibraryFragment>::@typeAlias::F1
                typeArguments
                  T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @10
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @13
              element: <none>
        F2 @33
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @36
              element: <none>
  typeAliases
    F1
      reference: <none>
      typeParameters
        T
      aliasedType: T Function()
    F2
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @15
              defaultType: dynamic
          aliasedType: void Function(int)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @22
                type: int
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @15
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
      aliasedType: void Function(int)
''');
  }

  test_genericTypeAlias_enclosingElements() async {
    var library = await buildLibrary(r'''
typedef F<T> = void Function<U>(int a);
''');
    var unit = library.definingCompilationUnit;

    var F = unit.typeAliases[0];
    expect(F.name, 'F');

    var T = F.typeParameters[0];
    expect(T.name, 'T');
    expect(T.enclosingElement3, same(F));

    var function = F.aliasedElement as GenericFunctionTypeElement;
    expect(function.enclosingElement3, same(F));

    var U = function.typeParameters[0];
    expect(U.name, 'U');
    expect(U.enclosingElement3, same(function));

    var a = function.parameters[0];
    expect(a.name, 'a');
    expect(a.enclosingElement3, same(function));
  }

  test_genericTypeAlias_recursive() async {
    var library = await buildLibrary('''
typedef F<X extends F> = Function(F);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated X @10
              bound: dynamic
              defaultType: dynamic
          aliasedType: dynamic Function(dynamic)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: dynamic
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            X @10
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        X
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
        notSimplyBounded G @34
          reference: <testLibraryFragment>::@typeAlias::G
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
        G @34
          reference: <testLibraryFragment>::@typeAlias::G
          element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      aliasedType: dynamic Function()
    notSimplyBounded G
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: List<dynamic> Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: List<dynamic>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @10
              bound: dynamic
              defaultType: dynamic
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @10
              defaultType: dynamic
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @10
              bound: dynamic
              defaultType: dynamic
          aliasedType: List<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: List<dynamic>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: void Function({int p})
            parameters
              optionalNamed p @-1
                type: int
          aliasedElement: GenericFunctionTypeElement
            parameters
              optionalNamed p @31
                type: int
            returnType: void
      functions
        f @42
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @46
              type: void Function({int p})
                alias: <testLibraryFragment>::@typeAlias::A
                parameters
                  optionalNamed p @-1
                    type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
      functions
        f @42
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @46
              element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: void Function({int p})
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: void Function({int p})
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function(T Function<T, U>(U))
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @17
                type: T Function<T, U>(U)
                typeParameters
                  covariant T @19
                  covariant U @22
                parameters
                  requiredPositional u @27
                    type: U
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @10
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: T
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            contravariant T @11
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: T
            returnType: void
        F2 @42
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            contravariant T @45
              defaultType: dynamic
          aliasedType: void Function(T) Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void Function(T)
              alias: <testLibraryFragment>::@typeAlias::F1
                typeArguments
                  T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @11
              element: <none>
        F2 @42
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @45
              element: <none>
  typeAliases
    F1
      reference: <none>
      typeParameters
        T
      aliasedType: void Function(T)
    F2
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: T Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: List<T> Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: List<T>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            covariant T @11
              defaultType: dynamic
          aliasedType: T Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T
        F2 @38
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            covariant T @41
              defaultType: dynamic
          aliasedType: T Function() Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T Function()
              alias: <testLibraryFragment>::@typeAlias::F1
                typeArguments
                  T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @11
              element: <none>
        F2 @38
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @41
              element: <none>
  typeAliases
    F1
      reference: <none>
      typeParameters
        T
      aliasedType: T Function()
    F2
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            contravariant T @11
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: T
            returnType: void
        F2 @42
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            covariant T @45
              defaultType: dynamic
          aliasedType: void Function(void Function(T))
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: void Function(T)
                  alias: <testLibraryFragment>::@typeAlias::F1
                    typeArguments
                      T
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @11
              element: <none>
        F2 @42
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @45
              element: <none>
  typeAliases
    F1
      reference: <none>
      typeParameters
        T
      aliasedType: void Function(T)
    F2
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      typeAliases
        F @19
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @21
              defaultType: dynamic
          aliasedType: void Function(A)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: A
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      typeAliases
        F @19
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @21
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
        G @37
          reference: <testLibraryFragment>::@typeAlias::G
          typeParameters
            unrelated T @39
              defaultType: dynamic
          aliasedType: void Function(void Function())
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: void Function()
                  alias: <testLibraryFragment>::@typeAlias::F
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
        G @37
          reference: <testLibraryFragment>::@typeAlias::G
          element: <none>
          typeParameters
            T @39
              element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: void Function()
    G
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            invariant T @10
              defaultType: dynamic
          aliasedType: T Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: T
            returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          typeParameters
            covariant T @11
              defaultType: dynamic
          aliasedType: T Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T
        F2 @38
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            invariant T @41
              defaultType: dynamic
          aliasedType: T Function() Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: T
            returnType: T Function()
              alias: <testLibraryFragment>::@typeAlias::F1
                typeArguments
                  T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
          typeParameters
            T @11
              element: <none>
        F2 @38
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            T @41
              element: <none>
  typeAliases
    F1
      reference: <none>
      typeParameters
        T
      aliasedType: T Function()
    F2
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @10
              defaultType: dynamic
          aliasedType: void Function(int)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: int
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            contravariant T @10
              defaultType: dynamic
          aliasedType: List<void Function(T)>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            contravariant T @10
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: T
            returnType: void
        B @41
          reference: <testLibraryFragment>::@typeAlias::B
          typeParameters
            contravariant T @43
              defaultType: dynamic
          aliasedType: List<void Function(T)>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
        B @41
          reference: <testLibraryFragment>::@typeAlias::B
          element: <none>
          typeParameters
            T @43
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
      aliasedType: void Function(T)
    B
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: List<T>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: Map<int, T>
        B @36
          reference: <testLibraryFragment>::@typeAlias::B
          typeParameters
            covariant T @38
              defaultType: dynamic
          aliasedType: List<Map<int, T>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
        B @36
          reference: <testLibraryFragment>::@typeAlias::B
          element: <none>
          typeParameters
            T @38
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
      aliasedType: Map<int, T>
    B
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            contravariant T @10
              defaultType: dynamic
          aliasedType: (void Function(T), int)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            contravariant T @10
              defaultType: dynamic
          aliasedType: (void Function(T), int)
        B @48
          reference: <testLibraryFragment>::@typeAlias::B
          typeParameters
            contravariant T @50
              defaultType: dynamic
          aliasedType: List<(void Function(T), int)>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
        B @48
          reference: <testLibraryFragment>::@typeAlias::B
          element: <none>
          typeParameters
            T @50
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
      aliasedType: (void Function(T), int)
    B
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: (T, int)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            invariant T @10
              defaultType: dynamic
          aliasedType: (T Function(T), int)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            unrelated T @10
              defaultType: dynamic
          aliasedType: (int, String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
      aliasedType: (int, String)
''');
  }

  test_typedef_function_generic() async {
    var library = await buildLibrary(
        'typedef F<T> = int Function<S>(List<S> list, num Function<A>(A), T);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @10
              defaultType: dynamic
          aliasedType: int Function<S>(List<S>, num Function<A>(A), T)
          aliasedElement: GenericFunctionTypeElement
            typeParameters
              covariant S @28
            parameters
              requiredPositional list @39
                type: List<S>
              requiredPositional @-1
                type: num Function<A>(A)
              requiredPositional @-1
                type: T
            returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @43
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            f @58
              reference: <testLibraryFragment>::@class::A::@field::f
              enclosingElement: <testLibraryFragment>::@class::A
              type: int Function<T>(T)
                alias: <testLibraryFragment>::@typeAlias::Foo
                  typeArguments
                    int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::A::@getter::f
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int Function<T>(T)
                alias: <testLibraryFragment>::@typeAlias::Foo
                  typeArguments
                    int
            synthetic set f= @-1
              reference: <testLibraryFragment>::@class::A::@setter::f
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _f @-1
                  type: int Function<T>(T)
                    alias: <testLibraryFragment>::@typeAlias::Foo
                      typeArguments
                        int
              returnType: void
      typeAliases
        Foo @8
          reference: <testLibraryFragment>::@typeAlias::Foo
          typeParameters
            covariant S @12
              defaultType: dynamic
          aliasedType: S Function<T>(T)
          aliasedElement: GenericFunctionTypeElement
            typeParameters
              covariant T @28
            parameters
              requiredPositional x @33
                type: T
            returnType: S
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @43
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          fields
            f @58
              reference: <testLibraryFragment>::@class::A::@field::f
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::f
              setter2: <testLibraryFragment>::@class::A::@setter::f
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::A::@getter::f
              element: <none>
          setters
            set f= @-1
              reference: <testLibraryFragment>::@class::A::@setter::f
              element: <none>
              parameters
                _f @-1
                  element: <none>
      typeAliases
        Foo @8
          reference: <testLibraryFragment>::@typeAlias::Foo
          element: <none>
          typeParameters
            S @12
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        f
          reference: <none>
          type: int Function<T>(T)
            alias: <testLibraryFragment>::@typeAlias::Foo
              typeArguments
                int
          firstFragment: <testLibraryFragment>::@class::A::@field::f
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::f
      setters
        synthetic set f=
          reference: <none>
          parameters
            requiredPositional _f
              reference: <none>
              type: int Function<T>(T)
                alias: <testLibraryFragment>::@typeAlias::Foo
                  typeArguments
                    int
          firstFragment: <testLibraryFragment>::@class::A::@setter::f
  typeAliases
    Foo
      reference: <none>
      typeParameters
        S
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        notSimplyBounded class C @38
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @40
              bound: C<T>
              defaultType: C<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function(C<C<dynamic>>)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional c @28
                type: C<C<dynamic>>
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @38
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @40
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: C<T>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    notSimplyBounded F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        notSimplyBounded class C @36
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @38
              bound: C<T>
              defaultType: C<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function(C<C<dynamic>>)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional @-1
                type: C<C<dynamic>>
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @36
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @38
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: C<T>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    notSimplyBounded F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        notSimplyBounded class C @32
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @34
              bound: C<T>
              defaultType: C<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: C<C<dynamic>> Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: C<C<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @32
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @34
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: C<T>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    notSimplyBounded F
      reference: <none>
      aliasedType: C<C<dynamic>> Function()
''');
  }

  test_typedef_function_typeParameters_f_bound_simple() async {
    var library =
        await buildLibrary('typedef F<T extends U, U> = U Function(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @10
              bound: U
              defaultType: Never
            covariant U @23
              defaultType: dynamic
          aliasedType: U Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional t @41
                type: T
            returnType: U
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
            U @23
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        T
          bound: U
        U
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @68
          reference: <testLibraryFragment>::@typeAlias::F
          documentationComment: /**\n * Docs\n */
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @68
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          documentationComment: /**\n * Docs\n */
  typeAliases
    F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        notSimplyBounded class C @27
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @29
              bound: C<T>
              defaultType: C<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      typeAliases
        functionTypeAliasBased notSimplyBounded F @13
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function(C<C<dynamic>>)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional c @17
                type: C<C<dynamic>>
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @27
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @29
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: C<T>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    notSimplyBounded F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        notSimplyBounded class C @21
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @23
              bound: C<T>
              defaultType: C<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      typeAliases
        functionTypeAliasBased notSimplyBounded F @10
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: C<C<dynamic>> Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: C<C<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @21
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            T @23
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        T
          bound: C<T>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    notSimplyBounded F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased notSimplyBounded F @13
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @15
              bound: dynamic
              defaultType: dynamic
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @15
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_notSimplyBounded_simple_no_bounds() async {
    var library = await buildLibrary('typedef void F<T>();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @15
              defaultType: dynamic
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @15
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_parameter_hasImplicitType() async {
    var library = await buildLibrary(r'''
typedef void F(int a, b, [int c, d]);
''');
    var F = library.definingCompilationUnit.typeAliases.single;
    var function = F.aliasedElement as GenericFunctionTypeElement;
    // TODO(scheglov): Use better textual presentation with all information.
    expect(function.parameters[0].hasImplicitType, false);
    expect(function.parameters[1].hasImplicitType, true);
    expect(function.parameters[2].hasImplicitType, false);
    expect(function.parameters[3].hasImplicitType, true);
  }

  test_typedef_legacy_parameter_parameters() async {
    var library = await buildLibrary('typedef F(g(x, y));');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function(dynamic Function(dynamic, dynamic))
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional g @10
                type: dynamic Function(dynamic, dynamic)
                parameters
                  requiredPositional x @12
                    type: dynamic
                  requiredPositional y @15
                    type: dynamic
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function(dynamic Function(dynamic, dynamic))
''');
  }

  test_typedef_legacy_parameter_parameters_in_generic_class() async {
    var library = await buildLibrary('typedef F<A, B>(A g(B x));');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant A @10
              defaultType: dynamic
            covariant B @13
              defaultType: dynamic
          aliasedType: dynamic Function(A Function(B))
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional g @18
                type: A Function(B)
                parameters
                  requiredPositional x @22
                    type: B
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            A @10
              element: <none>
            B @13
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        A
        B
      aliasedType: dynamic Function(A Function(B))
''');
  }

  test_typedef_legacy_parameter_return_type() async {
    var library = await buildLibrary('typedef F(int g());');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function(int Function())
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional g @14
                type: int Function()
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function(int Function())
''');
  }

  test_typedef_legacy_parameter_type() async {
    var library = await buildLibrary('typedef F(int i);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function(int)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional i @14
                type: int
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function(int)
''');
  }

  test_typedef_legacy_parameter_type_generic() async {
    var library = await buildLibrary('typedef F<T>(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @10
              defaultType: dynamic
          aliasedType: dynamic Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional t @15
                type: T
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @10
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
      aliasedType: dynamic Function(T)
''');
  }

  test_typedef_legacy_parameters() async {
    var library = await buildLibrary('typedef F(x, y);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function(dynamic, dynamic)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional x @10
                type: dynamic
              requiredPositional y @13
                type: dynamic
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function(dynamic, dynamic)
''');
  }

  test_typedef_legacy_parameters_named() async {
    var library = await buildLibrary('typedef F({y, z, x});');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function({dynamic x, dynamic y, dynamic z})
          aliasedElement: GenericFunctionTypeElement
            parameters
              optionalNamed y @11
                type: dynamic
              optionalNamed z @14
                type: dynamic
              optionalNamed x @17
                type: dynamic
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function({dynamic x, dynamic y, dynamic z})
''');
  }

  test_typedef_legacy_return_type() async {
    var library = await buildLibrary('typedef int F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @12
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: int Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @12
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: int Function()
''');
  }

  test_typedef_legacy_return_type_generic() async {
    var library = await buildLibrary('typedef T F<T>();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            covariant T @12
              defaultType: dynamic
          aliasedType: T Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @12
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
      aliasedType: T Function()
''');
  }

  test_typedef_legacy_return_type_implicit() async {
    var library = await buildLibrary('typedef F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: dynamic Function()
''');
  }

  test_typedef_legacy_return_type_void() async {
    var library = await buildLibrary('typedef void F();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_typeParameters() async {
    var library = await buildLibrary('typedef U F<T, U>(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @12
              defaultType: dynamic
            covariant U @15
              defaultType: dynamic
          aliasedType: U Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional t @20
                type: T
            returnType: U
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @12
              element: <none>
            U @15
              element: <none>
  typeAliases
    F
      reference: <none>
      typeParameters
        T
        U
      aliasedType: U Function(T)
''');
  }

  test_typedef_legacy_typeParameters_bound() async {
    var library = await buildLibrary(
        'typedef U F<T extends Object, U extends D>(T t); class D {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class D @55
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
      typeAliases
        functionTypeAliasBased F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @12
              bound: Object
              defaultType: Object
            covariant U @30
              bound: D
              defaultType: D
          aliasedType: U Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional t @45
                type: T
            returnType: U
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class D @55
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @12
              element: <none>
            U @30
              element: <none>
  classes
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    F
      reference: <none>
      typeParameters
        T
          bound: Object
        U
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased notSimplyBounded F @13
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @15
              bound: dynamic
              defaultType: dynamic
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @15
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased notSimplyBounded F @13
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            unrelated T @15
              bound: List<dynamic>
              defaultType: dynamic
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @15
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        T
          bound: List<dynamic>
      aliasedType: void Function()
''');
  }

  test_typedef_legacy_typeParameters_f_bound_complex() async {
    var library = await buildLibrary('typedef U F<T extends List<U>, U>(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased notSimplyBounded F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @12
              bound: List<U>
              defaultType: List<Never>
            covariant U @31
              defaultType: dynamic
          aliasedType: U Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional t @36
                type: T
            returnType: U
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @12
              element: <none>
            U @31
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        T
          bound: List<U>
        U
      aliasedType: U Function(T)
''');
  }

  test_typedef_legacy_typeParameters_f_bound_simple() async {
    var library = await buildLibrary('typedef U F<T extends U, U>(T t);');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased notSimplyBounded F @10
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @12
              bound: U
              defaultType: Never
            covariant U @25
              defaultType: dynamic
          aliasedType: U Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional t @30
                type: T
            returnType: U
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @10
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
          typeParameters
            T @12
              element: <none>
            U @25
              element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      typeParameters
        T
          bound: U
        U
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A1 @8
          reference: <testLibraryFragment>::@typeAlias::A1
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
        A2 @38
          reference: <testLibraryFragment>::@typeAlias::A2
          typeParameters
            covariant R @41
              defaultType: dynamic
          aliasedType: R Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: R
      functions
        f1 @65
          reference: <testLibraryFragment>::@function::f1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @71
              type: void Function()
                alias: <testLibraryFragment>::@typeAlias::A1
          returnType: void
        f2 @82
          reference: <testLibraryFragment>::@function::f2
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @93
              type: int Function()
                alias: <testLibraryFragment>::@typeAlias::A2
                  typeArguments
                    int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A1 @8
          reference: <testLibraryFragment>::@typeAlias::A1
          element: <none>
        A2 @38
          reference: <testLibraryFragment>::@typeAlias::A2
          element: <none>
          typeParameters
            R @41
              element: <none>
      functions
        f1 @65
          reference: <testLibraryFragment>::@function::f1
          element: <none>
          parameters
            a @71
              element: <none>
        f2 @82
          reference: <testLibraryFragment>::@function::f2
          element: <none>
          parameters
            a @93
              element: <none>
  typeAliases
    A1
      reference: <none>
      aliasedType: void Function()
    A2
      reference: <none>
      typeParameters
        R
      aliasedType: R Function()
  functions
    f1
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: void Function()
            alias: <testLibraryFragment>::@typeAlias::A1
      returnType: void
    f2
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: int Function()
            alias: <testLibraryFragment>::@typeAlias::A2
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A1 @8
          reference: <testLibraryFragment>::@typeAlias::A1
          aliasedType: List<int>
        A2 @32
          reference: <testLibraryFragment>::@typeAlias::A2
          typeParameters
            covariant T @35
              defaultType: dynamic
            covariant U @38
              defaultType: dynamic
          aliasedType: Map<T, U>
      functions
        f1 @59
          reference: <testLibraryFragment>::@function::f1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @65
              type: List<int>
                alias: <testLibraryFragment>::@typeAlias::A1
          returnType: void
        f2 @76
          reference: <testLibraryFragment>::@function::f2
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @95
              type: Map<int, String>
                alias: <testLibraryFragment>::@typeAlias::A2
                  typeArguments
                    int
                    String
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A1 @8
          reference: <testLibraryFragment>::@typeAlias::A1
          element: <none>
        A2 @32
          reference: <testLibraryFragment>::@typeAlias::A2
          element: <none>
          typeParameters
            T @35
              element: <none>
            U @38
              element: <none>
      functions
        f1 @59
          reference: <testLibraryFragment>::@function::f1
          element: <none>
          parameters
            a @65
              element: <none>
        f2 @76
          reference: <testLibraryFragment>::@function::f2
          element: <none>
          parameters
            a @95
              element: <none>
  typeAliases
    A1
      reference: <none>
      aliasedType: List<int>
    A2
      reference: <none>
      typeParameters
        T
        U
      aliasedType: Map<T, U>
  functions
    f1
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: List<int>
            alias: <testLibraryFragment>::@typeAlias::A1
      returnType: void
    f2
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: Map<int, String>
            alias: <testLibraryFragment>::@typeAlias::A2
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @10
              defaultType: dynamic
            covariant U @13
              defaultType: dynamic
          aliasedType: (T, U)
      functions
        f @31
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @48
              type: (int, String)
                alias: <testLibraryFragment>::@typeAlias::A
                  typeArguments
                    int
                    String
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
            U @13
              element: <none>
      functions
        f @31
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @48
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
        U
      aliasedType: (T, U)
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: (int, String)
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: T
      functions
        f @23
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U @25
              defaultType: dynamic
          parameters
            requiredPositional a @33
              type: U
                alias: <testLibraryFragment>::@typeAlias::A
                  typeArguments
                    U
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
      functions
        f @23
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            U @25
              element: <none>
          parameters
            a @33
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
      aliasedType: T
  functions
    f
      reference: <none>
      typeParameters
        U
      parameters
        requiredPositional a
          reference: <none>
          type: U
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @32
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @34
              defaultType: dynamic
            covariant U @37
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @49
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          interfaces
            A<int, String>
              alias: <testLibraryFragment>::@typeAlias::X
                typeArguments
                  String
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: A<int, T>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @32
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @34
              element: <none>
            U @37
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @49
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
          typeParameters
            T @10
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
        U
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  typeAliases
    X
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @28
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @30
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @42
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
        class C @53
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class D @64
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          interfaces
            B
            C
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: A<T>?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @28
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @30
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @42
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
        class C @53
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
        class D @64
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
          typeParameters
            T @10
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    X
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @28
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @30
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @42
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
        class C @53
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class D @64
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          interfaces
            B
            A<int?>
              alias: <testLibraryFragment>::@typeAlias::X
                typeArguments
                  int
            C
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: A<T?>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @28
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @30
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @42
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
        class C @53
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
        class D @64
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
          typeParameters
            T @10
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    X
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @25
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: Never
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @25
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: Null
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @35
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
        class C @46
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U @48
              defaultType: dynamic
          interfaces
            A
            B
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @35
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
        class C @46
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          typeParameters
            U @48
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
          typeParameters
            T @10
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      typeParameters
        U
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    X
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @35
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
        class C @46
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          interfaces
            A
            B
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @35
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
        class C @46
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @26
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @28
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @40
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: Object
          mixins
            A<int>
              alias: <testLibraryFragment>::@typeAlias::X
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: A<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @26
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @28
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @40
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: Object
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @29
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @65
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: Object
          mixins
            M1
            M2
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
      mixins
        mixin M1 @41
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
        mixin M2 @53
          reference: <testLibraryFragment>::@mixin::M2
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: A<int>?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @29
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @65
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
      mixins
        mixin M1 @41
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1
        mixin M2 @53
          reference: <testLibraryFragment>::@mixin::M2
          element: <testLibraryFragment>::@mixin::M2
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: Object
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  mixins
    mixin M1
      reference: <testLibraryFragment>::@mixin::M1
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        Object
    mixin M2
      reference: <testLibraryFragment>::@mixin::M2
      firstFragment: <testLibraryFragment>::@mixin::M2
      superclassConstraints
        Object
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @29
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @65
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: Object
          mixins
            M1
            A<int?>
              alias: <testLibraryFragment>::@typeAlias::X
            M2
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
      mixins
        mixin M1 @41
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
        mixin M2 @53
          reference: <testLibraryFragment>::@mixin::M2
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: A<int?>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @29
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @65
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
      mixins
        mixin M1 @41
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1
        mixin M2 @53
          reference: <testLibraryFragment>::@mixin::M2
          element: <testLibraryFragment>::@mixin::M2
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: Object
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  mixins
    mixin M1
      reference: <testLibraryFragment>::@mixin::M1
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        Object
    mixin M2
      reference: <testLibraryFragment>::@mixin::M2
      firstFragment: <testLibraryFragment>::@mixin::M2
      superclassConstraints
        Object
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @25
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: Never
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @25
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @26
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @28
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @40
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A<int>
            alias: <testLibraryFragment>::@typeAlias::X
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: A<int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @26
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @28
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @40
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<int>
        alias: <testLibraryFragment>::@typeAlias::X
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @26
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @38
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A<int>
            alias: <testLibraryFragment>::@typeAlias::X
              typeArguments
                A<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @26
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @38
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
          typeParameters
            T @10
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<int>
        alias: <testLibraryFragment>::@typeAlias::X
          typeArguments
            A<int>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  typeAliases
    X
      reference: <none>
      typeParameters
        T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: Null
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @29
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class D @41
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: A<int>?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @29
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class D @41
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @29
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class D @41
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          supertype: A<int?>
            alias: <testLibraryFragment>::@typeAlias::X
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int?}
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: A<int?>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @27
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @29
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class D @41
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int?}
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      supertype: A<int?>
        alias: <testLibraryFragment>::@typeAlias::X
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @25
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: Never
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @25
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  typeAliases
    X
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          aliasedType: Null
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @24
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      typeAliases
        X @8
          reference: <testLibraryFragment>::@typeAlias::X
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  typeAliases
    X
      reference: <none>
      aliasedType: Null
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: dynamic
      functions
        f @26
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @30
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
      functions
        f @26
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @30
              element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: dynamic
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
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

    var alias = library.definingCompilationUnit.typeAliases[0];
    _assertTypeStr(alias.aliasedType, 'dynamic Function()');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @24
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: dynamic Function()
      functions
        f @38
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @42
              type: dynamic Function()
                alias: <testLibraryFragment>::@typeAlias::A
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @24
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
      functions
        f @38
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @42
              element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: dynamic Function()
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: dynamic Function()
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: int
      functions
        f @22
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @26
              type: int
                alias: <testLibraryFragment>::@typeAlias::A
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
      functions
        f @22
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @26
              element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: int
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: int
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: int?
      functions
        f @23
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @27
              type: int?
                alias: <testLibraryFragment>::@typeAlias::A
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
      functions
        f @23
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @27
              element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: int?
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: int?
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: Map<int, T>
      functions
        f @33
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @45
              type: Map<int, String>
                alias: <testLibraryFragment>::@typeAlias::A
                  typeArguments
                    String
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
      functions
        f @33
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @45
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
      aliasedType: Map<int, T>
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: Map<int, String>
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: Never
      functions
        f @24
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @28
              type: Never
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
      functions
        f @24
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @28
              element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: Never
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: Never?
      functions
        f @25
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @29
              type: Never?
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
      functions
        f @25
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @29
              element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: Never?
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: T
      functions
        f1 @23
          reference: <testLibraryFragment>::@function::f1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @28
              type: dynamic
          returnType: void
        f2 @39
          reference: <testLibraryFragment>::@function::f2
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @49
              type: int
                alias: <testLibraryFragment>::@typeAlias::A
                  typeArguments
                    int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
      functions
        f1 @23
          reference: <testLibraryFragment>::@function::f1
          element: <none>
          parameters
            a @28
              element: <none>
        f2 @39
          reference: <testLibraryFragment>::@function::f2
          element: <none>
          parameters
            a @49
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
      aliasedType: T
  functions
    f1
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: dynamic
      returnType: void
    f2
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: int
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @10
              defaultType: dynamic
          aliasedType: T?
      functions
        f1 @24
          reference: <testLibraryFragment>::@function::f1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @29
              type: dynamic
          returnType: void
        f2 @40
          reference: <testLibraryFragment>::@function::f2
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @50
              type: int?
                alias: <testLibraryFragment>::@typeAlias::A
                  typeArguments
                    int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
          typeParameters
            T @10
              element: <none>
      functions
        f1 @24
          reference: <testLibraryFragment>::@function::f1
          element: <none>
          parameters
            a @29
              element: <none>
        f2 @40
          reference: <testLibraryFragment>::@function::f2
          element: <none>
          parameters
            a @50
              element: <none>
  typeAliases
    A
      reference: <none>
      typeParameters
        T
      aliasedType: T?
  functions
    f1
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: dynamic
      returnType: void
    f2
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: int?
            alias: <testLibraryFragment>::@typeAlias::A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: void
      functions
        f @23
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @27
              type: void
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        A @8
          reference: <testLibraryFragment>::@typeAlias::A
          element: <none>
      functions
        f @23
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @27
              element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: void
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        notSimplyBounded F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: (dynamic, int) Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: (dynamic, int)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    notSimplyBounded F
      reference: <none>
      aliasedType: (dynamic, int) Function()
''');
  }

  test_typedefs() async {
    var library = await buildLibrary('f() {} g() {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        g @7
          reference: <testLibraryFragment>::@function::g
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
        g @7
          reference: <testLibraryFragment>::@function::g
          element: <none>
  functions
    f
      reference: <none>
      returnType: dynamic
    g
      reference: <none>
      returnType: dynamic
''');
  }

  // TODO(scheglov): This is duplicate.
  void _assertTypeStr(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }

  void _assertTypeStrings(List<DartType> types, List<String> expected) {
    var typeStringList = types.map((e) {
      return e.getDisplayString();
    }).toList();
    expect(typeStringList, expected);
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
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
          element: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
  typeAliases
    A
      reference: <none>
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      functions
        A @20
          reference: <testLibraryFragment>::@function::A
          enclosingElement: <testLibraryFragment>
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
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
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: int
  functions
    A
      reference: <none>
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static A @-1
          reference: <testLibraryFragment>::@topLevelVariable::A
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static get A @23
          reference: <testLibraryFragment>::@getter::A
          enclosingElement: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
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
        synthetic A @-1
          reference: <testLibraryFragment>::@topLevelVariable::A
          element: <none>
          getter2: <testLibraryFragment>::@getter::A
      getters
        get A @23
          reference: <testLibraryFragment>::@getter::A
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: int
  topLevelVariables
    synthetic A
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::A
      getter: <none>
  getters
    static get A
      reference: <none>
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
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
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <none>
  typeAliases
    A
      reference: <none>
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static A @-1
          reference: <testLibraryFragment>::@topLevelVariable::A
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static set A= @19
          reference: <testLibraryFragment>::@setter::A
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _ @25
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
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
        synthetic A @-1
          reference: <testLibraryFragment>::@topLevelVariable::A
          element: <none>
          setter2: <testLibraryFragment>::@setter::A
      setters
        set A= @19
          reference: <testLibraryFragment>::@setter::A
          element: <none>
          parameters
            _ @25
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: int
  topLevelVariables
    synthetic A
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::A
      setter: <none>
  setters
    static set A=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::A
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
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      typeAliases
        A @23
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: int
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      typeAliases
        augment A @37
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
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      typeAliases
        A @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@typeAliasAugmentation::A
          element: <none>
  typeAliases
    A
      reference: <none>
      aliasedType: int
    A
      reference: <none>
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
