// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OffsetsElementTest_keepLinking);
    defineReflectiveTests(OffsetsElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class OffsetsElementTest extends ElementsBaseTest {
  test_codeRange_class() async {
    var library = await buildLibrary('''
class Raw {}

/// Comment 1.
/// Comment 2.
class HasDocComment {}

@Object()
class HasAnnotation {}

@Object()
/// Comment 1.
/// Comment 2.
class AnnotationThenComment {}

/// Comment 1.
/// Comment 2.
@Object()
class CommentThenAnnotation {}

/// Comment 1.
@Object()
/// Comment 2.
class CommentAroundAnnotation {}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class Raw @6
          reference: <testLibraryFragment>::@class::Raw
          element: <testLibrary>::@class::Raw
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::Raw::@constructor::new
              element: <testLibraryFragment>::@class::Raw::@constructor::new#element
              typeName: Raw
        class HasDocComment @50
          reference: <testLibraryFragment>::@class::HasDocComment
          element: <testLibrary>::@class::HasDocComment
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::HasDocComment::@constructor::new
              element: <testLibraryFragment>::@class::HasDocComment::@constructor::new#element
              typeName: HasDocComment
        class HasAnnotation @84
          reference: <testLibraryFragment>::@class::HasAnnotation
          element: <testLibrary>::@class::HasAnnotation
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::HasAnnotation::@constructor::new#element
              typeName: HasAnnotation
        class AnnotationThenComment @148
          reference: <testLibraryFragment>::@class::AnnotationThenComment
          element: <testLibrary>::@class::AnnotationThenComment
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
              element: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new#element
              typeName: AnnotationThenComment
        class CommentThenAnnotation @220
          reference: <testLibraryFragment>::@class::CommentThenAnnotation
          element: <testLibrary>::@class::CommentThenAnnotation
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new#element
              typeName: CommentThenAnnotation
        class CommentAroundAnnotation @292
          reference: <testLibraryFragment>::@class::CommentAroundAnnotation
          element: <testLibrary>::@class::CommentAroundAnnotation
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new#element
              typeName: CommentAroundAnnotation
  classes
    class Raw
      reference: <testLibrary>::@class::Raw
      firstFragment: <testLibraryFragment>::@class::Raw
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::Raw::@constructor::new
    class HasDocComment
      reference: <testLibrary>::@class::HasDocComment
      firstFragment: <testLibraryFragment>::@class::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::HasDocComment::@constructor::new
    class HasAnnotation
      reference: <testLibrary>::@class::HasAnnotation
      firstFragment: <testLibraryFragment>::@class::HasAnnotation
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
    class AnnotationThenComment
      reference: <testLibrary>::@class::AnnotationThenComment
      firstFragment: <testLibraryFragment>::@class::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
    class CommentThenAnnotation
      reference: <testLibrary>::@class::CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
    class CommentAroundAnnotation
      reference: <testLibrary>::@class::CommentAroundAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentAroundAnnotation
      documentationComment: /// Comment 2.
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
''');
  }

  test_codeRange_class_namedMixin() async {
    var library = await buildLibrary('''
class A {}

class B {}

class Raw = Object with A, B;

/// Comment 1.
/// Comment 2.
class HasDocComment = Object with A, B;

@Object()
class HasAnnotation = Object with A, B;

@Object()
/// Comment 1.
/// Comment 2.
class AnnotationThenComment = Object with A, B;

/// Comment 1.
/// Comment 2.
@Object()
class CommentThenAnnotation = Object with A, B;

/// Comment 1.
@Object()
/// Comment 2.
class CommentAroundAnnotation = Object with A, B;
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
        class B @18
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
        class Raw @30
          reference: <testLibraryFragment>::@class::Raw
          element: <testLibrary>::@class::Raw
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@class::Raw::@constructor::new
              element: <testLibraryFragment>::@class::Raw::@constructor::new#element
              typeName: Raw
        class HasDocComment @91
          reference: <testLibraryFragment>::@class::HasDocComment
          element: <testLibrary>::@class::HasDocComment
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@class::HasDocComment::@constructor::new
              element: <testLibraryFragment>::@class::HasDocComment::@constructor::new#element
              typeName: HasDocComment
        class HasAnnotation @142
          reference: <testLibraryFragment>::@class::HasAnnotation
          element: <testLibrary>::@class::HasAnnotation
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::HasAnnotation::@constructor::new#element
              typeName: HasAnnotation
        class AnnotationThenComment @223
          reference: <testLibraryFragment>::@class::AnnotationThenComment
          element: <testLibrary>::@class::AnnotationThenComment
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
              element: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new#element
              typeName: AnnotationThenComment
        class CommentThenAnnotation @312
          reference: <testLibraryFragment>::@class::CommentThenAnnotation
          element: <testLibrary>::@class::CommentThenAnnotation
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new#element
              typeName: CommentThenAnnotation
        class CommentAroundAnnotation @401
          reference: <testLibraryFragment>::@class::CommentAroundAnnotation
          element: <testLibrary>::@class::CommentAroundAnnotation
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new#element
              typeName: CommentAroundAnnotation
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class alias Raw
      reference: <testLibrary>::@class::Raw
      firstFragment: <testLibraryFragment>::@class::Raw
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::Raw::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::<fragment>::@class::Object::@constructor::new#element
    class alias HasDocComment
      reference: <testLibrary>::@class::HasDocComment
      firstFragment: <testLibraryFragment>::@class::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::HasDocComment::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::<fragment>::@class::Object::@constructor::new#element
    class alias HasAnnotation
      reference: <testLibrary>::@class::HasAnnotation
      firstFragment: <testLibraryFragment>::@class::HasAnnotation
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::<fragment>::@class::Object::@constructor::new#element
    class alias AnnotationThenComment
      reference: <testLibrary>::@class::AnnotationThenComment
      firstFragment: <testLibraryFragment>::@class::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::<fragment>::@class::Object::@constructor::new#element
    class alias CommentThenAnnotation
      reference: <testLibrary>::@class::CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::<fragment>::@class::Object::@constructor::new#element
    class alias CommentAroundAnnotation
      reference: <testLibrary>::@class::CommentAroundAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentAroundAnnotation
      documentationComment: /// Comment 2.
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::<fragment>::@class::Object::@constructor::new#element
''');
  }

  test_codeRange_constructor() async {
    var library = await buildLibrary('''
class C {
  C();

  C.raw() {}

  /// Comment 1.
  /// Comment 2.
  C.hasDocComment() {}

  @Object()
  C.hasAnnotation() {}

  @Object()
  /// Comment 1.
  /// Comment 2.
  C.annotationThenComment() {}

  /// Comment 1.
  /// Comment 2.
  @Object()
  C.commentThenAnnotation() {}

  /// Comment 1.
  @Object()
  /// Comment 2.
  C.commentAroundAnnotation() {}
}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              codeOffset: 12
              codeLength: 4
              typeName: C
              typeNameOffset: 12
            raw @22
              reference: <testLibraryFragment>::@class::C::@constructor::raw
              element: <testLibraryFragment>::@class::C::@constructor::raw#element
              codeOffset: 20
              codeLength: 10
              typeName: C
              typeNameOffset: 20
              periodOffset: 21
            hasDocComment @70
              reference: <testLibraryFragment>::@class::C::@constructor::hasDocComment
              element: <testLibraryFragment>::@class::C::@constructor::hasDocComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 34
              codeLength: 54
              typeName: C
              typeNameOffset: 68
              periodOffset: 69
            hasAnnotation @106
              reference: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::hasAnnotation#element
              metadata
                Annotation
                  atSign: @ @92
                  name: SimpleIdentifier
                    token: Object @93
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @99
                    rightParenthesis: ) @100
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 92
              codeLength: 32
              typeName: C
              typeNameOffset: 104
              periodOffset: 105
            annotationThenComment @176
              reference: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
              element: <testLibraryFragment>::@class::C::@constructor::annotationThenComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @128
                  name: SimpleIdentifier
                    token: Object @129
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @135
                    rightParenthesis: ) @136
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 128
              codeLength: 74
              typeName: C
              typeNameOffset: 174
              periodOffset: 175
            commentThenAnnotation @254
              reference: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @240
                  name: SimpleIdentifier
                    token: Object @241
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @247
                    rightParenthesis: ) @248
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 206
              codeLength: 74
              typeName: C
              typeNameOffset: 252
              periodOffset: 253
            commentAroundAnnotation @332
              reference: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation#element
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @301
                  name: SimpleIdentifier
                    token: Object @302
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @308
                    rightParenthesis: ) @309
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 301
              codeLength: 59
              typeName: C
              typeNameOffset: 330
              periodOffset: 331
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
        raw
          firstFragment: <testLibraryFragment>::@class::C::@constructor::raw
        hasDocComment
          firstFragment: <testLibraryFragment>::@class::C::@constructor::hasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
        hasAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
          metadata
            Annotation
              atSign: @ @92
              name: SimpleIdentifier
                token: Object @93
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @99
                rightParenthesis: ) @100
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @128
              name: SimpleIdentifier
                token: Object @129
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @135
                rightParenthesis: ) @136
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @240
              name: SimpleIdentifier
                token: Object @241
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @247
                rightParenthesis: ) @248
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @301
              name: SimpleIdentifier
                token: Object @302
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @308
                rightParenthesis: ) @309
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
''');
  }

  test_codeRange_constructor_factory() async {
    var library = await buildLibrary('''
class C {
  factory C() => throw 0;

  factory C.raw() => throw 0;

  /// Comment 1.
  /// Comment 2.
  factory C.hasDocComment() => throw 0;

  @Object()
  factory C.hasAnnotation() => throw 0;

  @Object()
  /// Comment 1.
  /// Comment 2.
  factory C.annotationThenComment() => throw 0;

  /// Comment 1.
  /// Comment 2.
  @Object()
  factory C.commentThenAnnotation() => throw 0;

  /// Comment 1.
  @Object()
  /// Comment 2.
  factory C.commentAroundAnnotation() => throw 0;
}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            factory new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              codeOffset: 12
              codeLength: 23
              typeName: C
              typeNameOffset: 20
            factory raw @49
              reference: <testLibraryFragment>::@class::C::@constructor::raw
              element: <testLibraryFragment>::@class::C::@constructor::raw#element
              codeOffset: 39
              codeLength: 27
              typeName: C
              typeNameOffset: 47
              periodOffset: 48
            factory hasDocComment @114
              reference: <testLibraryFragment>::@class::C::@constructor::hasDocComment
              element: <testLibraryFragment>::@class::C::@constructor::hasDocComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 70
              codeLength: 71
              typeName: C
              typeNameOffset: 112
              periodOffset: 113
            factory hasAnnotation @167
              reference: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::hasAnnotation#element
              metadata
                Annotation
                  atSign: @ @145
                  name: SimpleIdentifier
                    token: Object @146
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @152
                    rightParenthesis: ) @153
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 145
              codeLength: 49
              typeName: C
              typeNameOffset: 165
              periodOffset: 166
            factory annotationThenComment @254
              reference: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
              element: <testLibraryFragment>::@class::C::@constructor::annotationThenComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @198
                  name: SimpleIdentifier
                    token: Object @199
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @205
                    rightParenthesis: ) @206
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 198
              codeLength: 91
              typeName: C
              typeNameOffset: 252
              periodOffset: 253
            factory commentThenAnnotation @349
              reference: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @327
                  name: SimpleIdentifier
                    token: Object @328
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @334
                    rightParenthesis: ) @335
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 293
              codeLength: 91
              typeName: C
              typeNameOffset: 347
              periodOffset: 348
            factory commentAroundAnnotation @444
              reference: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation#element
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @405
                  name: SimpleIdentifier
                    token: Object @406
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @412
                    rightParenthesis: ) @413
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 405
              codeLength: 76
              typeName: C
              typeNameOffset: 442
              periodOffset: 443
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        factory new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
        factory raw
          firstFragment: <testLibraryFragment>::@class::C::@constructor::raw
        factory hasDocComment
          firstFragment: <testLibraryFragment>::@class::C::@constructor::hasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
        factory hasAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
          metadata
            Annotation
              atSign: @ @145
              name: SimpleIdentifier
                token: Object @146
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @152
                rightParenthesis: ) @153
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        factory annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @198
              name: SimpleIdentifier
                token: Object @199
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @205
                rightParenthesis: ) @206
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        factory commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @327
              name: SimpleIdentifier
                token: Object @328
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @334
                rightParenthesis: ) @335
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        factory commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @405
              name: SimpleIdentifier
                token: Object @406
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @412
                rightParenthesis: ) @413
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
''');
  }

  test_codeRange_extensions() async {
    var library = await buildLibrary('''
class A {}

extension Raw on A {}

/// Comment 1.
/// Comment 2.
extension HasDocComment on A {}

@Object()
extension HasAnnotation on A {}

@Object()
/// Comment 1.
/// Comment 2.
extension AnnotationThenComment on A {}

/// Comment 1.
/// Comment 2.
@Object()
extension CommentThenAnnotation on A {}

/// Comment 1.
@Object()
/// Comment 2.
extension CommentAroundAnnotation on A {}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
      extensions
        extension Raw @22
          reference: <testLibraryFragment>::@extension::Raw
          element: <testLibrary>::@extension::Raw
        extension HasDocComment @75
          reference: <testLibraryFragment>::@extension::HasDocComment
          element: <testLibrary>::@extension::HasDocComment
        extension HasAnnotation @118
          reference: <testLibraryFragment>::@extension::HasAnnotation
          element: <testLibrary>::@extension::HasAnnotation
        extension AnnotationThenComment @191
          reference: <testLibraryFragment>::@extension::AnnotationThenComment
          element: <testLibrary>::@extension::AnnotationThenComment
        extension CommentThenAnnotation @272
          reference: <testLibraryFragment>::@extension::CommentThenAnnotation
          element: <testLibrary>::@extension::CommentThenAnnotation
        extension CommentAroundAnnotation @353
          reference: <testLibraryFragment>::@extension::CommentAroundAnnotation
          element: <testLibrary>::@extension::CommentAroundAnnotation
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  extensions
    extension Raw
      reference: <testLibrary>::@extension::Raw
      firstFragment: <testLibraryFragment>::@extension::Raw
    extension HasDocComment
      reference: <testLibrary>::@extension::HasDocComment
      firstFragment: <testLibraryFragment>::@extension::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
    extension HasAnnotation
      reference: <testLibrary>::@extension::HasAnnotation
      firstFragment: <testLibraryFragment>::@extension::HasAnnotation
    extension AnnotationThenComment
      reference: <testLibrary>::@extension::AnnotationThenComment
      firstFragment: <testLibraryFragment>::@extension::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
    extension CommentThenAnnotation
      reference: <testLibrary>::@extension::CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@extension::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
    extension CommentAroundAnnotation
      reference: <testLibrary>::@extension::CommentAroundAnnotation
      firstFragment: <testLibraryFragment>::@extension::CommentAroundAnnotation
      documentationComment: /// Comment 2.
''');
  }

  test_codeRange_field() async {
    var library = await buildLibrary('''
class C {
  int withInit = 1;

  int withoutInit;

  int multiWithInit = 2, multiWithoutInit, multiWithInit2 = 3;
}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasInitializer withInit @16
              reference: <testLibraryFragment>::@class::C::@field::withInit
              element: <testLibraryFragment>::@class::C::@field::withInit#element
              getter2: <testLibraryFragment>::@class::C::@getter::withInit
              setter2: <testLibraryFragment>::@class::C::@setter::withInit
            withoutInit @37
              reference: <testLibraryFragment>::@class::C::@field::withoutInit
              element: <testLibraryFragment>::@class::C::@field::withoutInit#element
              getter2: <testLibraryFragment>::@class::C::@getter::withoutInit
              setter2: <testLibraryFragment>::@class::C::@setter::withoutInit
            hasInitializer multiWithInit @57
              reference: <testLibraryFragment>::@class::C::@field::multiWithInit
              element: <testLibraryFragment>::@class::C::@field::multiWithInit#element
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithInit
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithInit
            multiWithoutInit @76
              reference: <testLibraryFragment>::@class::C::@field::multiWithoutInit
              element: <testLibraryFragment>::@class::C::@field::multiWithoutInit#element
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithoutInit
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
            hasInitializer multiWithInit2 @94
              reference: <testLibraryFragment>::@class::C::@field::multiWithInit2
              element: <testLibraryFragment>::@class::C::@field::multiWithInit2#element
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithInit2
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithInit2
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get withInit
              reference: <testLibraryFragment>::@class::C::@getter::withInit
              element: <testLibraryFragment>::@class::C::@getter::withInit#element
            synthetic get withoutInit
              reference: <testLibraryFragment>::@class::C::@getter::withoutInit
              element: <testLibraryFragment>::@class::C::@getter::withoutInit#element
            synthetic get multiWithInit
              reference: <testLibraryFragment>::@class::C::@getter::multiWithInit
              element: <testLibraryFragment>::@class::C::@getter::multiWithInit#element
            synthetic get multiWithoutInit
              reference: <testLibraryFragment>::@class::C::@getter::multiWithoutInit
              element: <testLibraryFragment>::@class::C::@getter::multiWithoutInit#element
            synthetic get multiWithInit2
              reference: <testLibraryFragment>::@class::C::@getter::multiWithInit2
              element: <testLibraryFragment>::@class::C::@getter::multiWithInit2#element
          setters
            synthetic set withInit
              reference: <testLibraryFragment>::@class::C::@setter::withInit
              element: <testLibraryFragment>::@class::C::@setter::withInit#element
              formalParameters
                _withInit
                  element: <testLibraryFragment>::@class::C::@setter::withInit::@parameter::_withInit#element
            synthetic set withoutInit
              reference: <testLibraryFragment>::@class::C::@setter::withoutInit
              element: <testLibraryFragment>::@class::C::@setter::withoutInit#element
              formalParameters
                _withoutInit
                  element: <testLibraryFragment>::@class::C::@setter::withoutInit::@parameter::_withoutInit#element
            synthetic set multiWithInit
              reference: <testLibraryFragment>::@class::C::@setter::multiWithInit
              element: <testLibraryFragment>::@class::C::@setter::multiWithInit#element
              formalParameters
                _multiWithInit
                  element: <testLibraryFragment>::@class::C::@setter::multiWithInit::@parameter::_multiWithInit#element
            synthetic set multiWithoutInit
              reference: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
              element: <testLibraryFragment>::@class::C::@setter::multiWithoutInit#element
              formalParameters
                _multiWithoutInit
                  element: <testLibraryFragment>::@class::C::@setter::multiWithoutInit::@parameter::_multiWithoutInit#element
            synthetic set multiWithInit2
              reference: <testLibraryFragment>::@class::C::@setter::multiWithInit2
              element: <testLibraryFragment>::@class::C::@setter::multiWithInit2#element
              formalParameters
                _multiWithInit2
                  element: <testLibraryFragment>::@class::C::@setter::multiWithInit2::@parameter::_multiWithInit2#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        hasInitializer withInit
          firstFragment: <testLibraryFragment>::@class::C::@field::withInit
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::withInit#element
          setter: <testLibraryFragment>::@class::C::@setter::withInit#element
        withoutInit
          firstFragment: <testLibraryFragment>::@class::C::@field::withoutInit
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::withoutInit#element
          setter: <testLibraryFragment>::@class::C::@setter::withoutInit#element
        hasInitializer multiWithInit
          firstFragment: <testLibraryFragment>::@class::C::@field::multiWithInit
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::multiWithInit#element
          setter: <testLibraryFragment>::@class::C::@setter::multiWithInit#element
        multiWithoutInit
          firstFragment: <testLibraryFragment>::@class::C::@field::multiWithoutInit
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::multiWithoutInit#element
          setter: <testLibraryFragment>::@class::C::@setter::multiWithoutInit#element
        hasInitializer multiWithInit2
          firstFragment: <testLibraryFragment>::@class::C::@field::multiWithInit2
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::multiWithInit2#element
          setter: <testLibraryFragment>::@class::C::@setter::multiWithInit2#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get withInit
          firstFragment: <testLibraryFragment>::@class::C::@getter::withInit
        synthetic get withoutInit
          firstFragment: <testLibraryFragment>::@class::C::@getter::withoutInit
        synthetic get multiWithInit
          firstFragment: <testLibraryFragment>::@class::C::@getter::multiWithInit
        synthetic get multiWithoutInit
          firstFragment: <testLibraryFragment>::@class::C::@getter::multiWithoutInit
        synthetic get multiWithInit2
          firstFragment: <testLibraryFragment>::@class::C::@getter::multiWithInit2
      setters
        synthetic set withInit
          firstFragment: <testLibraryFragment>::@class::C::@setter::withInit
          formalParameters
            requiredPositional _withInit
              type: int
        synthetic set withoutInit
          firstFragment: <testLibraryFragment>::@class::C::@setter::withoutInit
          formalParameters
            requiredPositional _withoutInit
              type: int
        synthetic set multiWithInit
          firstFragment: <testLibraryFragment>::@class::C::@setter::multiWithInit
          formalParameters
            requiredPositional _multiWithInit
              type: int
        synthetic set multiWithoutInit
          firstFragment: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
          formalParameters
            requiredPositional _multiWithoutInit
              type: int
        synthetic set multiWithInit2
          firstFragment: <testLibraryFragment>::@class::C::@setter::multiWithInit2
          formalParameters
            requiredPositional _multiWithInit2
              type: int
''');
  }

  test_codeRange_field_annotations() async {
    var library = await buildLibrary('''
class C {
  /// Comment 1.
  /// Comment 2.
  int hasDocComment, hasDocComment2;

  @Object()
  int hasAnnotation, hasAnnotation2;

  @Object()
  /// Comment 1.
  /// Comment 2.
  int annotationThenComment, annotationThenComment2;

  /// Comment 1.
  /// Comment 2.
  @Object()
  int commentThenAnnotation, commentThenAnnotation2;

  /// Comment 1.
  @Object()
  /// Comment 2.
  int commentAroundAnnotation, commentAroundAnnotation2;
}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          fields
            hasDocComment @50
              reference: <testLibraryFragment>::@class::C::@field::hasDocComment
              element: <testLibraryFragment>::@class::C::@field::hasDocComment#element
              getter2: <testLibraryFragment>::@class::C::@getter::hasDocComment
              setter2: <testLibraryFragment>::@class::C::@setter::hasDocComment
            hasDocComment2 @65
              reference: <testLibraryFragment>::@class::C::@field::hasDocComment2
              element: <testLibraryFragment>::@class::C::@field::hasDocComment2#element
              getter2: <testLibraryFragment>::@class::C::@getter::hasDocComment2
              setter2: <testLibraryFragment>::@class::C::@setter::hasDocComment2
            hasAnnotation @100
              reference: <testLibraryFragment>::@class::C::@field::hasAnnotation
              element: <testLibraryFragment>::@class::C::@field::hasAnnotation#element
              getter2: <testLibraryFragment>::@class::C::@getter::hasAnnotation
              setter2: <testLibraryFragment>::@class::C::@setter::hasAnnotation
            hasAnnotation2 @115
              reference: <testLibraryFragment>::@class::C::@field::hasAnnotation2
              element: <testLibraryFragment>::@class::C::@field::hasAnnotation2#element
              getter2: <testLibraryFragment>::@class::C::@getter::hasAnnotation2
              setter2: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
            annotationThenComment @184
              reference: <testLibraryFragment>::@class::C::@field::annotationThenComment
              element: <testLibraryFragment>::@class::C::@field::annotationThenComment#element
              getter2: <testLibraryFragment>::@class::C::@getter::annotationThenComment
              setter2: <testLibraryFragment>::@class::C::@setter::annotationThenComment
            annotationThenComment2 @207
              reference: <testLibraryFragment>::@class::C::@field::annotationThenComment2
              element: <testLibraryFragment>::@class::C::@field::annotationThenComment2#element
              getter2: <testLibraryFragment>::@class::C::@getter::annotationThenComment2
              setter2: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
            commentThenAnnotation @284
              reference: <testLibraryFragment>::@class::C::@field::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@field::commentThenAnnotation#element
              getter2: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation
              setter2: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
            commentThenAnnotation2 @307
              reference: <testLibraryFragment>::@class::C::@field::commentThenAnnotation2
              element: <testLibraryFragment>::@class::C::@field::commentThenAnnotation2#element
              getter2: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2
              setter2: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
            commentAroundAnnotation @384
              reference: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation#element
              getter2: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation
              setter2: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
            commentAroundAnnotation2 @409
              reference: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation2
              element: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation2#element
              getter2: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2
              setter2: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          getters
            synthetic get hasDocComment
              reference: <testLibraryFragment>::@class::C::@getter::hasDocComment
              element: <testLibraryFragment>::@class::C::@getter::hasDocComment#element
            synthetic get hasDocComment2
              reference: <testLibraryFragment>::@class::C::@getter::hasDocComment2
              element: <testLibraryFragment>::@class::C::@getter::hasDocComment2#element
            synthetic get hasAnnotation
              reference: <testLibraryFragment>::@class::C::@getter::hasAnnotation
              element: <testLibraryFragment>::@class::C::@getter::hasAnnotation#element
            synthetic get hasAnnotation2
              reference: <testLibraryFragment>::@class::C::@getter::hasAnnotation2
              element: <testLibraryFragment>::@class::C::@getter::hasAnnotation2#element
            synthetic get annotationThenComment
              reference: <testLibraryFragment>::@class::C::@getter::annotationThenComment
              element: <testLibraryFragment>::@class::C::@getter::annotationThenComment#element
            synthetic get annotationThenComment2
              reference: <testLibraryFragment>::@class::C::@getter::annotationThenComment2
              element: <testLibraryFragment>::@class::C::@getter::annotationThenComment2#element
            synthetic get commentThenAnnotation
              reference: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation#element
            synthetic get commentThenAnnotation2
              reference: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2
              element: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2#element
            synthetic get commentAroundAnnotation
              reference: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation#element
            synthetic get commentAroundAnnotation2
              reference: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2
              element: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2#element
          setters
            synthetic set hasDocComment
              reference: <testLibraryFragment>::@class::C::@setter::hasDocComment
              element: <testLibraryFragment>::@class::C::@setter::hasDocComment#element
              formalParameters
                _hasDocComment
                  element: <testLibraryFragment>::@class::C::@setter::hasDocComment::@parameter::_hasDocComment#element
            synthetic set hasDocComment2
              reference: <testLibraryFragment>::@class::C::@setter::hasDocComment2
              element: <testLibraryFragment>::@class::C::@setter::hasDocComment2#element
              formalParameters
                _hasDocComment2
                  element: <testLibraryFragment>::@class::C::@setter::hasDocComment2::@parameter::_hasDocComment2#element
            synthetic set hasAnnotation
              reference: <testLibraryFragment>::@class::C::@setter::hasAnnotation
              element: <testLibraryFragment>::@class::C::@setter::hasAnnotation#element
              formalParameters
                _hasAnnotation
                  element: <testLibraryFragment>::@class::C::@setter::hasAnnotation::@parameter::_hasAnnotation#element
            synthetic set hasAnnotation2
              reference: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
              element: <testLibraryFragment>::@class::C::@setter::hasAnnotation2#element
              formalParameters
                _hasAnnotation2
                  element: <testLibraryFragment>::@class::C::@setter::hasAnnotation2::@parameter::_hasAnnotation2#element
            synthetic set annotationThenComment
              reference: <testLibraryFragment>::@class::C::@setter::annotationThenComment
              element: <testLibraryFragment>::@class::C::@setter::annotationThenComment#element
              formalParameters
                _annotationThenComment
                  element: <testLibraryFragment>::@class::C::@setter::annotationThenComment::@parameter::_annotationThenComment#element
            synthetic set annotationThenComment2
              reference: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
              element: <testLibraryFragment>::@class::C::@setter::annotationThenComment2#element
              formalParameters
                _annotationThenComment2
                  element: <testLibraryFragment>::@class::C::@setter::annotationThenComment2::@parameter::_annotationThenComment2#element
            synthetic set commentThenAnnotation
              reference: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation#element
              formalParameters
                _commentThenAnnotation
                  element: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation::@parameter::_commentThenAnnotation#element
            synthetic set commentThenAnnotation2
              reference: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
              element: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2#element
              formalParameters
                _commentThenAnnotation2
                  element: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2::@parameter::_commentThenAnnotation2#element
            synthetic set commentAroundAnnotation
              reference: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation#element
              formalParameters
                _commentAroundAnnotation
                  element: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation::@parameter::_commentAroundAnnotation#element
            synthetic set commentAroundAnnotation2
              reference: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2
              element: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2#element
              formalParameters
                _commentAroundAnnotation2
                  element: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2::@parameter::_commentAroundAnnotation2#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        hasDocComment
          firstFragment: <testLibraryFragment>::@class::C::@field::hasDocComment
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::hasDocComment#element
          setter: <testLibraryFragment>::@class::C::@setter::hasDocComment#element
        hasDocComment2
          firstFragment: <testLibraryFragment>::@class::C::@field::hasDocComment2
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::hasDocComment2#element
          setter: <testLibraryFragment>::@class::C::@setter::hasDocComment2#element
        hasAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@field::hasAnnotation
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::hasAnnotation#element
          setter: <testLibraryFragment>::@class::C::@setter::hasAnnotation#element
        hasAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@field::hasAnnotation2
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::hasAnnotation2#element
          setter: <testLibraryFragment>::@class::C::@setter::hasAnnotation2#element
        annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@field::annotationThenComment
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::annotationThenComment#element
          setter: <testLibraryFragment>::@class::C::@setter::annotationThenComment#element
        annotationThenComment2
          firstFragment: <testLibraryFragment>::@class::C::@field::annotationThenComment2
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::annotationThenComment2#element
          setter: <testLibraryFragment>::@class::C::@setter::annotationThenComment2#element
        commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@field::commentThenAnnotation
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation#element
          setter: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation#element
        commentThenAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@field::commentThenAnnotation2
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2#element
          setter: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2#element
        commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation#element
          setter: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation#element
        commentAroundAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation2
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2#element
          setter: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      getters
        synthetic get hasDocComment
          firstFragment: <testLibraryFragment>::@class::C::@getter::hasDocComment
        synthetic get hasDocComment2
          firstFragment: <testLibraryFragment>::@class::C::@getter::hasDocComment2
        synthetic get hasAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@getter::hasAnnotation
        synthetic get hasAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@getter::hasAnnotation2
        synthetic get annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@getter::annotationThenComment
        synthetic get annotationThenComment2
          firstFragment: <testLibraryFragment>::@class::C::@getter::annotationThenComment2
        synthetic get commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation
        synthetic get commentThenAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2
        synthetic get commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation
        synthetic get commentAroundAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2
      setters
        synthetic set hasDocComment
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasDocComment
          formalParameters
            requiredPositional _hasDocComment
              type: int
        synthetic set hasDocComment2
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasDocComment2
          formalParameters
            requiredPositional _hasDocComment2
              type: int
        synthetic set hasAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasAnnotation
          formalParameters
            requiredPositional _hasAnnotation
              type: int
        synthetic set hasAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
          formalParameters
            requiredPositional _hasAnnotation2
              type: int
        synthetic set annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@setter::annotationThenComment
          formalParameters
            requiredPositional _annotationThenComment
              type: int
        synthetic set annotationThenComment2
          firstFragment: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
          formalParameters
            requiredPositional _annotationThenComment2
              type: int
        synthetic set commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
          formalParameters
            requiredPositional _commentThenAnnotation
              type: int
        synthetic set commentThenAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
          formalParameters
            requiredPositional _commentThenAnnotation2
              type: int
        synthetic set commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
          formalParameters
            requiredPositional _commentAroundAnnotation
              type: int
        synthetic set commentAroundAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2
          formalParameters
            requiredPositional _commentAroundAnnotation2
              type: int
''');
  }

  test_codeRange_function() async {
    var library = await buildLibrary('''
void raw() {}

/// Comment 1.
/// Comment 2.
void hasDocComment() {}

@Object()
void hasAnnotation() {}

@Object()
/// Comment 1.
/// Comment 2.
void annotationThenComment() {}

/// Comment 1.
/// Comment 2.
@Object()
void commentThenAnnotation() {}

/// Comment 1.
@Object()
/// Comment 2.
void commentAroundAnnotation() {}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        raw @5
          reference: <testLibraryFragment>::@function::raw
          element: <testLibrary>::@function::raw
        hasDocComment @50
          reference: <testLibraryFragment>::@function::hasDocComment
          element: <testLibrary>::@function::hasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
        hasAnnotation @85
          reference: <testLibraryFragment>::@function::hasAnnotation
          element: <testLibrary>::@function::hasAnnotation
          metadata
            Annotation
              atSign: @ @70
              name: SimpleIdentifier
                token: Object @71
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @77
                rightParenthesis: ) @78
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        annotationThenComment @150
          reference: <testLibraryFragment>::@function::annotationThenComment
          element: <testLibrary>::@function::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @105
              name: SimpleIdentifier
                token: Object @106
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @112
                rightParenthesis: ) @113
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentThenAnnotation @223
          reference: <testLibraryFragment>::@function::commentThenAnnotation
          element: <testLibrary>::@function::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @208
              name: SimpleIdentifier
                token: Object @209
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @215
                rightParenthesis: ) @216
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentAroundAnnotation @296
          reference: <testLibraryFragment>::@function::commentAroundAnnotation
          element: <testLibrary>::@function::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @266
              name: SimpleIdentifier
                token: Object @267
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @273
                rightParenthesis: ) @274
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
  functions
    raw
      reference: <testLibrary>::@function::raw
      firstFragment: <testLibraryFragment>::@function::raw
      returnType: void
    hasDocComment
      reference: <testLibrary>::@function::hasDocComment
      firstFragment: <testLibraryFragment>::@function::hasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      returnType: void
    hasAnnotation
      reference: <testLibrary>::@function::hasAnnotation
      firstFragment: <testLibraryFragment>::@function::hasAnnotation
      metadata
        Annotation
          atSign: @ @70
          name: SimpleIdentifier
            token: Object @71
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @77
            rightParenthesis: ) @78
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      returnType: void
    annotationThenComment
      reference: <testLibrary>::@function::annotationThenComment
      firstFragment: <testLibraryFragment>::@function::annotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @105
          name: SimpleIdentifier
            token: Object @106
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @112
            rightParenthesis: ) @113
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      returnType: void
    commentThenAnnotation
      reference: <testLibrary>::@function::commentThenAnnotation
      firstFragment: <testLibraryFragment>::@function::commentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @208
          name: SimpleIdentifier
            token: Object @209
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @215
            rightParenthesis: ) @216
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      returnType: void
    commentAroundAnnotation
      reference: <testLibrary>::@function::commentAroundAnnotation
      firstFragment: <testLibraryFragment>::@function::commentAroundAnnotation
      documentationComment: /// Comment 2.
      metadata
        Annotation
          atSign: @ @266
          name: SimpleIdentifier
            token: Object @267
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @273
            rightParenthesis: ) @274
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      returnType: void
''');
  }

  test_codeRange_method() async {
    var library = await buildLibrary('''
class C {
  void raw() {}

  /// Comment 1.
  /// Comment 2.
  void hasDocComment() {}

  @Object()
  void hasAnnotation() {}

  @Object()
  /// Comment 1.
  /// Comment 2.
  void annotationThenComment() {}

  /// Comment 1.
  /// Comment 2.
  @Object()
  void commentThenAnnotation() {}

  /// Comment 1.
  @Object()
  /// Comment 2.
  void commentAroundAnnotation() {}
}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            raw @17
              reference: <testLibraryFragment>::@class::C::@method::raw
              element: <testLibraryFragment>::@class::C::@method::raw#element
              codeOffset: 12
              codeLength: 13
            hasDocComment @68
              reference: <testLibraryFragment>::@class::C::@method::hasDocComment
              element: <testLibraryFragment>::@class::C::@method::hasDocComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 29
              codeLength: 57
            hasAnnotation @107
              reference: <testLibraryFragment>::@class::C::@method::hasAnnotation
              element: <testLibraryFragment>::@class::C::@method::hasAnnotation#element
              metadata
                Annotation
                  atSign: @ @90
                  name: SimpleIdentifier
                    token: Object @91
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @97
                    rightParenthesis: ) @98
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 90
              codeLength: 35
            annotationThenComment @180
              reference: <testLibraryFragment>::@class::C::@method::annotationThenComment
              element: <testLibraryFragment>::@class::C::@method::annotationThenComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @129
                  name: SimpleIdentifier
                    token: Object @130
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @136
                    rightParenthesis: ) @137
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 129
              codeLength: 77
            commentThenAnnotation @261
              reference: <testLibraryFragment>::@class::C::@method::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@method::commentThenAnnotation#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @244
                  name: SimpleIdentifier
                    token: Object @245
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @251
                    rightParenthesis: ) @252
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 210
              codeLength: 77
            commentAroundAnnotation @342
              reference: <testLibraryFragment>::@class::C::@method::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@method::commentAroundAnnotation#element
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @308
                  name: SimpleIdentifier
                    token: Object @309
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @315
                    rightParenthesis: ) @316
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 308
              codeLength: 62
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        raw
          firstFragment: <testLibraryFragment>::@class::C::@method::raw
        hasDocComment
          firstFragment: <testLibraryFragment>::@class::C::@method::hasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
        hasAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@method::hasAnnotation
          metadata
            Annotation
              atSign: @ @90
              name: SimpleIdentifier
                token: Object @91
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @97
                rightParenthesis: ) @98
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@method::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @129
              name: SimpleIdentifier
                token: Object @130
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @136
                rightParenthesis: ) @137
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@method::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @244
              name: SimpleIdentifier
                token: Object @245
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @251
                rightParenthesis: ) @252
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@method::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @308
              name: SimpleIdentifier
                token: Object @309
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @315
                rightParenthesis: ) @316
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
''');
  }

  test_codeRange_parameter() async {
    var library = await buildLibrary('''
main({int a = 1, int b, int c = 2}) {}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        main @0
          reference: <testLibraryFragment>::@function::main
          element: <testLibrary>::@function::main
          formalParameters
            default a @10
              reference: <testLibraryFragment>::@function::main::@parameter::a
              element: <testLibraryFragment>::@function::main::@parameter::a#element
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @14
                  staticType: int
            default b @21
              reference: <testLibraryFragment>::@function::main::@parameter::b
              element: <testLibraryFragment>::@function::main::@parameter::b#element
            default c @28
              reference: <testLibraryFragment>::@function::main::@parameter::c
              element: <testLibraryFragment>::@function::main::@parameter::c#element
              initializer: expression_1
                IntegerLiteral
                  literal: 2 @32
                  staticType: int
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: <testLibraryFragment>::@function::main
      formalParameters
        optionalNamed a
          firstFragment: <testLibraryFragment>::@function::main::@parameter::a
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@function::main::@parameter::a
            expression: expression_0
        optionalNamed b
          firstFragment: <testLibraryFragment>::@function::main::@parameter::b
          type: int
        optionalNamed c
          firstFragment: <testLibraryFragment>::@function::main::@parameter::c
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@function::main::@parameter::c
            expression: expression_1
      returnType: dynamic
''');
  }

  test_codeRange_parameter_annotations() async {
    var library = await buildLibrary('''
main(@Object() int a, int b, @Object() int c) {}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        main @0
          reference: <testLibraryFragment>::@function::main
          element: <testLibrary>::@function::main
          formalParameters
            a @19
              element: <testLibraryFragment>::@function::main::@parameter::a#element
              metadata
                Annotation
                  atSign: @ @5
                  name: SimpleIdentifier
                    token: Object @6
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @12
                    rightParenthesis: ) @13
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
            b @26
              element: <testLibraryFragment>::@function::main::@parameter::b#element
            c @43
              element: <testLibraryFragment>::@function::main::@parameter::c#element
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: Object @30
                    element: dart:core::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @36
                    rightParenthesis: ) @37
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: <testLibraryFragment>::@function::main
      formalParameters
        requiredPositional a
          type: int
          metadata
            Annotation
              atSign: @ @5
              name: SimpleIdentifier
                token: Object @6
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @12
                rightParenthesis: ) @13
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        requiredPositional b
          type: int
        requiredPositional c
          type: int
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: Object @30
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @36
                rightParenthesis: ) @37
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      returnType: dynamic
''');
  }

  test_codeRange_topLevelVariable() async {
    var library = await buildLibrary('''
int withInit = 1 + 2 * 3;

int withoutInit;

int multiWithInit = 2, multiWithoutInit, multiWithInit2 = 3;
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasInitializer withInit @4
          reference: <testLibraryFragment>::@topLevelVariable::withInit
          element: <testLibrary>::@topLevelVariable::withInit
          getter2: <testLibraryFragment>::@getter::withInit
          setter2: <testLibraryFragment>::@setter::withInit
        withoutInit @31
          reference: <testLibraryFragment>::@topLevelVariable::withoutInit
          element: <testLibrary>::@topLevelVariable::withoutInit
          getter2: <testLibraryFragment>::@getter::withoutInit
          setter2: <testLibraryFragment>::@setter::withoutInit
        hasInitializer multiWithInit @49
          reference: <testLibraryFragment>::@topLevelVariable::multiWithInit
          element: <testLibrary>::@topLevelVariable::multiWithInit
          getter2: <testLibraryFragment>::@getter::multiWithInit
          setter2: <testLibraryFragment>::@setter::multiWithInit
        multiWithoutInit @68
          reference: <testLibraryFragment>::@topLevelVariable::multiWithoutInit
          element: <testLibrary>::@topLevelVariable::multiWithoutInit
          getter2: <testLibraryFragment>::@getter::multiWithoutInit
          setter2: <testLibraryFragment>::@setter::multiWithoutInit
        hasInitializer multiWithInit2 @86
          reference: <testLibraryFragment>::@topLevelVariable::multiWithInit2
          element: <testLibrary>::@topLevelVariable::multiWithInit2
          getter2: <testLibraryFragment>::@getter::multiWithInit2
          setter2: <testLibraryFragment>::@setter::multiWithInit2
      getters
        synthetic get withInit
          reference: <testLibraryFragment>::@getter::withInit
          element: <testLibraryFragment>::@getter::withInit#element
        synthetic get withoutInit
          reference: <testLibraryFragment>::@getter::withoutInit
          element: <testLibraryFragment>::@getter::withoutInit#element
        synthetic get multiWithInit
          reference: <testLibraryFragment>::@getter::multiWithInit
          element: <testLibraryFragment>::@getter::multiWithInit#element
        synthetic get multiWithoutInit
          reference: <testLibraryFragment>::@getter::multiWithoutInit
          element: <testLibraryFragment>::@getter::multiWithoutInit#element
        synthetic get multiWithInit2
          reference: <testLibraryFragment>::@getter::multiWithInit2
          element: <testLibraryFragment>::@getter::multiWithInit2#element
      setters
        synthetic set withInit
          reference: <testLibraryFragment>::@setter::withInit
          element: <testLibraryFragment>::@setter::withInit#element
          formalParameters
            _withInit
              element: <testLibraryFragment>::@setter::withInit::@parameter::_withInit#element
        synthetic set withoutInit
          reference: <testLibraryFragment>::@setter::withoutInit
          element: <testLibraryFragment>::@setter::withoutInit#element
          formalParameters
            _withoutInit
              element: <testLibraryFragment>::@setter::withoutInit::@parameter::_withoutInit#element
        synthetic set multiWithInit
          reference: <testLibraryFragment>::@setter::multiWithInit
          element: <testLibraryFragment>::@setter::multiWithInit#element
          formalParameters
            _multiWithInit
              element: <testLibraryFragment>::@setter::multiWithInit::@parameter::_multiWithInit#element
        synthetic set multiWithoutInit
          reference: <testLibraryFragment>::@setter::multiWithoutInit
          element: <testLibraryFragment>::@setter::multiWithoutInit#element
          formalParameters
            _multiWithoutInit
              element: <testLibraryFragment>::@setter::multiWithoutInit::@parameter::_multiWithoutInit#element
        synthetic set multiWithInit2
          reference: <testLibraryFragment>::@setter::multiWithInit2
          element: <testLibraryFragment>::@setter::multiWithInit2#element
          formalParameters
            _multiWithInit2
              element: <testLibraryFragment>::@setter::multiWithInit2::@parameter::_multiWithInit2#element
  topLevelVariables
    hasInitializer withInit
      reference: <testLibrary>::@topLevelVariable::withInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::withInit
      type: int
      getter: <testLibraryFragment>::@getter::withInit#element
      setter: <testLibraryFragment>::@setter::withInit#element
    withoutInit
      reference: <testLibrary>::@topLevelVariable::withoutInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::withoutInit
      type: int
      getter: <testLibraryFragment>::@getter::withoutInit#element
      setter: <testLibraryFragment>::@setter::withoutInit#element
    hasInitializer multiWithInit
      reference: <testLibrary>::@topLevelVariable::multiWithInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::multiWithInit
      type: int
      getter: <testLibraryFragment>::@getter::multiWithInit#element
      setter: <testLibraryFragment>::@setter::multiWithInit#element
    multiWithoutInit
      reference: <testLibrary>::@topLevelVariable::multiWithoutInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::multiWithoutInit
      type: int
      getter: <testLibraryFragment>::@getter::multiWithoutInit#element
      setter: <testLibraryFragment>::@setter::multiWithoutInit#element
    hasInitializer multiWithInit2
      reference: <testLibrary>::@topLevelVariable::multiWithInit2
      firstFragment: <testLibraryFragment>::@topLevelVariable::multiWithInit2
      type: int
      getter: <testLibraryFragment>::@getter::multiWithInit2#element
      setter: <testLibraryFragment>::@setter::multiWithInit2#element
  getters
    synthetic static get withInit
      firstFragment: <testLibraryFragment>::@getter::withInit
    synthetic static get withoutInit
      firstFragment: <testLibraryFragment>::@getter::withoutInit
    synthetic static get multiWithInit
      firstFragment: <testLibraryFragment>::@getter::multiWithInit
    synthetic static get multiWithoutInit
      firstFragment: <testLibraryFragment>::@getter::multiWithoutInit
    synthetic static get multiWithInit2
      firstFragment: <testLibraryFragment>::@getter::multiWithInit2
  setters
    synthetic static set withInit
      firstFragment: <testLibraryFragment>::@setter::withInit
      formalParameters
        requiredPositional _withInit
          type: int
    synthetic static set withoutInit
      firstFragment: <testLibraryFragment>::@setter::withoutInit
      formalParameters
        requiredPositional _withoutInit
          type: int
    synthetic static set multiWithInit
      firstFragment: <testLibraryFragment>::@setter::multiWithInit
      formalParameters
        requiredPositional _multiWithInit
          type: int
    synthetic static set multiWithoutInit
      firstFragment: <testLibraryFragment>::@setter::multiWithoutInit
      formalParameters
        requiredPositional _multiWithoutInit
          type: int
    synthetic static set multiWithInit2
      firstFragment: <testLibraryFragment>::@setter::multiWithInit2
      formalParameters
        requiredPositional _multiWithInit2
          type: int
''');
  }

  test_codeRange_topLevelVariable_annotations() async {
    var library = await buildLibrary('''
/// Comment 1.
/// Comment 2.
int hasDocComment, hasDocComment2;

@Object()
int hasAnnotation, hasAnnotation2;

@Object()
/// Comment 1.
/// Comment 2.
int annotationThenComment, annotationThenComment2;

/// Comment 1.
/// Comment 2.
@Object()
int commentThenAnnotation, commentThenAnnotation2;

/// Comment 1.
@Object()
/// Comment 2.
int commentAroundAnnotation, commentAroundAnnotation2;
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasDocComment @34
          reference: <testLibraryFragment>::@topLevelVariable::hasDocComment
          element: <testLibrary>::@topLevelVariable::hasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          getter2: <testLibraryFragment>::@getter::hasDocComment
          setter2: <testLibraryFragment>::@setter::hasDocComment
        hasDocComment2 @49
          reference: <testLibraryFragment>::@topLevelVariable::hasDocComment2
          element: <testLibrary>::@topLevelVariable::hasDocComment2
          documentationComment: /// Comment 1.\n/// Comment 2.
          getter2: <testLibraryFragment>::@getter::hasDocComment2
          setter2: <testLibraryFragment>::@setter::hasDocComment2
        hasAnnotation @80
          reference: <testLibraryFragment>::@topLevelVariable::hasAnnotation
          element: <testLibrary>::@topLevelVariable::hasAnnotation
          metadata
            Annotation
              atSign: @ @66
              name: SimpleIdentifier
                token: Object @67
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::hasAnnotation
          setter2: <testLibraryFragment>::@setter::hasAnnotation
        hasAnnotation2 @95
          reference: <testLibraryFragment>::@topLevelVariable::hasAnnotation2
          element: <testLibrary>::@topLevelVariable::hasAnnotation2
          metadata
            Annotation
              atSign: @ @66
              name: SimpleIdentifier
                token: Object @67
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::hasAnnotation2
          setter2: <testLibraryFragment>::@setter::hasAnnotation2
        annotationThenComment @156
          reference: <testLibraryFragment>::@topLevelVariable::annotationThenComment
          element: <testLibrary>::@topLevelVariable::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @112
              name: SimpleIdentifier
                token: Object @113
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::annotationThenComment
          setter2: <testLibraryFragment>::@setter::annotationThenComment
        annotationThenComment2 @179
          reference: <testLibraryFragment>::@topLevelVariable::annotationThenComment2
          element: <testLibrary>::@topLevelVariable::annotationThenComment2
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @112
              name: SimpleIdentifier
                token: Object @113
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::annotationThenComment2
          setter2: <testLibraryFragment>::@setter::annotationThenComment2
        commentThenAnnotation @248
          reference: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation
          element: <testLibrary>::@topLevelVariable::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @234
              name: SimpleIdentifier
                token: Object @235
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::commentThenAnnotation
          setter2: <testLibraryFragment>::@setter::commentThenAnnotation
        commentThenAnnotation2 @271
          reference: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation2
          element: <testLibrary>::@topLevelVariable::commentThenAnnotation2
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @234
              name: SimpleIdentifier
                token: Object @235
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::commentThenAnnotation2
          setter2: <testLibraryFragment>::@setter::commentThenAnnotation2
        commentAroundAnnotation @340
          reference: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation
          element: <testLibrary>::@topLevelVariable::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @311
              name: SimpleIdentifier
                token: Object @312
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::commentAroundAnnotation
          setter2: <testLibraryFragment>::@setter::commentAroundAnnotation
        commentAroundAnnotation2 @365
          reference: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation2
          element: <testLibrary>::@topLevelVariable::commentAroundAnnotation2
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @311
              name: SimpleIdentifier
                token: Object @312
                element: dart:core::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::commentAroundAnnotation2
          setter2: <testLibraryFragment>::@setter::commentAroundAnnotation2
      getters
        synthetic get hasDocComment
          reference: <testLibraryFragment>::@getter::hasDocComment
          element: <testLibraryFragment>::@getter::hasDocComment#element
        synthetic get hasDocComment2
          reference: <testLibraryFragment>::@getter::hasDocComment2
          element: <testLibraryFragment>::@getter::hasDocComment2#element
        synthetic get hasAnnotation
          reference: <testLibraryFragment>::@getter::hasAnnotation
          element: <testLibraryFragment>::@getter::hasAnnotation#element
        synthetic get hasAnnotation2
          reference: <testLibraryFragment>::@getter::hasAnnotation2
          element: <testLibraryFragment>::@getter::hasAnnotation2#element
        synthetic get annotationThenComment
          reference: <testLibraryFragment>::@getter::annotationThenComment
          element: <testLibraryFragment>::@getter::annotationThenComment#element
        synthetic get annotationThenComment2
          reference: <testLibraryFragment>::@getter::annotationThenComment2
          element: <testLibraryFragment>::@getter::annotationThenComment2#element
        synthetic get commentThenAnnotation
          reference: <testLibraryFragment>::@getter::commentThenAnnotation
          element: <testLibraryFragment>::@getter::commentThenAnnotation#element
        synthetic get commentThenAnnotation2
          reference: <testLibraryFragment>::@getter::commentThenAnnotation2
          element: <testLibraryFragment>::@getter::commentThenAnnotation2#element
        synthetic get commentAroundAnnotation
          reference: <testLibraryFragment>::@getter::commentAroundAnnotation
          element: <testLibraryFragment>::@getter::commentAroundAnnotation#element
        synthetic get commentAroundAnnotation2
          reference: <testLibraryFragment>::@getter::commentAroundAnnotation2
          element: <testLibraryFragment>::@getter::commentAroundAnnotation2#element
      setters
        synthetic set hasDocComment
          reference: <testLibraryFragment>::@setter::hasDocComment
          element: <testLibraryFragment>::@setter::hasDocComment#element
          formalParameters
            _hasDocComment
              element: <testLibraryFragment>::@setter::hasDocComment::@parameter::_hasDocComment#element
        synthetic set hasDocComment2
          reference: <testLibraryFragment>::@setter::hasDocComment2
          element: <testLibraryFragment>::@setter::hasDocComment2#element
          formalParameters
            _hasDocComment2
              element: <testLibraryFragment>::@setter::hasDocComment2::@parameter::_hasDocComment2#element
        synthetic set hasAnnotation
          reference: <testLibraryFragment>::@setter::hasAnnotation
          element: <testLibraryFragment>::@setter::hasAnnotation#element
          formalParameters
            _hasAnnotation
              element: <testLibraryFragment>::@setter::hasAnnotation::@parameter::_hasAnnotation#element
        synthetic set hasAnnotation2
          reference: <testLibraryFragment>::@setter::hasAnnotation2
          element: <testLibraryFragment>::@setter::hasAnnotation2#element
          formalParameters
            _hasAnnotation2
              element: <testLibraryFragment>::@setter::hasAnnotation2::@parameter::_hasAnnotation2#element
        synthetic set annotationThenComment
          reference: <testLibraryFragment>::@setter::annotationThenComment
          element: <testLibraryFragment>::@setter::annotationThenComment#element
          formalParameters
            _annotationThenComment
              element: <testLibraryFragment>::@setter::annotationThenComment::@parameter::_annotationThenComment#element
        synthetic set annotationThenComment2
          reference: <testLibraryFragment>::@setter::annotationThenComment2
          element: <testLibraryFragment>::@setter::annotationThenComment2#element
          formalParameters
            _annotationThenComment2
              element: <testLibraryFragment>::@setter::annotationThenComment2::@parameter::_annotationThenComment2#element
        synthetic set commentThenAnnotation
          reference: <testLibraryFragment>::@setter::commentThenAnnotation
          element: <testLibraryFragment>::@setter::commentThenAnnotation#element
          formalParameters
            _commentThenAnnotation
              element: <testLibraryFragment>::@setter::commentThenAnnotation::@parameter::_commentThenAnnotation#element
        synthetic set commentThenAnnotation2
          reference: <testLibraryFragment>::@setter::commentThenAnnotation2
          element: <testLibraryFragment>::@setter::commentThenAnnotation2#element
          formalParameters
            _commentThenAnnotation2
              element: <testLibraryFragment>::@setter::commentThenAnnotation2::@parameter::_commentThenAnnotation2#element
        synthetic set commentAroundAnnotation
          reference: <testLibraryFragment>::@setter::commentAroundAnnotation
          element: <testLibraryFragment>::@setter::commentAroundAnnotation#element
          formalParameters
            _commentAroundAnnotation
              element: <testLibraryFragment>::@setter::commentAroundAnnotation::@parameter::_commentAroundAnnotation#element
        synthetic set commentAroundAnnotation2
          reference: <testLibraryFragment>::@setter::commentAroundAnnotation2
          element: <testLibraryFragment>::@setter::commentAroundAnnotation2#element
          formalParameters
            _commentAroundAnnotation2
              element: <testLibraryFragment>::@setter::commentAroundAnnotation2::@parameter::_commentAroundAnnotation2#element
  topLevelVariables
    hasDocComment
      reference: <testLibrary>::@topLevelVariable::hasDocComment
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      type: int
      getter: <testLibraryFragment>::@getter::hasDocComment#element
      setter: <testLibraryFragment>::@setter::hasDocComment#element
    hasDocComment2
      reference: <testLibrary>::@topLevelVariable::hasDocComment2
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasDocComment2
      documentationComment: /// Comment 1.\n/// Comment 2.
      type: int
      getter: <testLibraryFragment>::@getter::hasDocComment2#element
      setter: <testLibraryFragment>::@setter::hasDocComment2#element
    hasAnnotation
      reference: <testLibrary>::@topLevelVariable::hasAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasAnnotation
      metadata
        Annotation
          atSign: @ @66
          name: SimpleIdentifier
            token: Object @67
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @73
            rightParenthesis: ) @74
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::hasAnnotation#element
      setter: <testLibraryFragment>::@setter::hasAnnotation#element
    hasAnnotation2
      reference: <testLibrary>::@topLevelVariable::hasAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasAnnotation2
      metadata
        Annotation
          atSign: @ @66
          name: SimpleIdentifier
            token: Object @67
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @73
            rightParenthesis: ) @74
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::hasAnnotation2#element
      setter: <testLibraryFragment>::@setter::hasAnnotation2#element
    annotationThenComment
      reference: <testLibrary>::@topLevelVariable::annotationThenComment
      firstFragment: <testLibraryFragment>::@topLevelVariable::annotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @112
          name: SimpleIdentifier
            token: Object @113
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @119
            rightParenthesis: ) @120
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::annotationThenComment#element
      setter: <testLibraryFragment>::@setter::annotationThenComment#element
    annotationThenComment2
      reference: <testLibrary>::@topLevelVariable::annotationThenComment2
      firstFragment: <testLibraryFragment>::@topLevelVariable::annotationThenComment2
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @112
          name: SimpleIdentifier
            token: Object @113
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @119
            rightParenthesis: ) @120
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::annotationThenComment2#element
      setter: <testLibraryFragment>::@setter::annotationThenComment2#element
    commentThenAnnotation
      reference: <testLibrary>::@topLevelVariable::commentThenAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @234
          name: SimpleIdentifier
            token: Object @235
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @241
            rightParenthesis: ) @242
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::commentThenAnnotation#element
      setter: <testLibraryFragment>::@setter::commentThenAnnotation#element
    commentThenAnnotation2
      reference: <testLibrary>::@topLevelVariable::commentThenAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation2
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @234
          name: SimpleIdentifier
            token: Object @235
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @241
            rightParenthesis: ) @242
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::commentThenAnnotation2#element
      setter: <testLibraryFragment>::@setter::commentThenAnnotation2#element
    commentAroundAnnotation
      reference: <testLibrary>::@topLevelVariable::commentAroundAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation
      documentationComment: /// Comment 2.
      metadata
        Annotation
          atSign: @ @311
          name: SimpleIdentifier
            token: Object @312
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @318
            rightParenthesis: ) @319
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::commentAroundAnnotation#element
      setter: <testLibraryFragment>::@setter::commentAroundAnnotation#element
    commentAroundAnnotation2
      reference: <testLibrary>::@topLevelVariable::commentAroundAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation2
      documentationComment: /// Comment 2.
      metadata
        Annotation
          atSign: @ @311
          name: SimpleIdentifier
            token: Object @312
            element: dart:core::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @318
            rightParenthesis: ) @319
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::commentAroundAnnotation2#element
      setter: <testLibraryFragment>::@setter::commentAroundAnnotation2#element
  getters
    synthetic static get hasDocComment
      firstFragment: <testLibraryFragment>::@getter::hasDocComment
    synthetic static get hasDocComment2
      firstFragment: <testLibraryFragment>::@getter::hasDocComment2
    synthetic static get hasAnnotation
      firstFragment: <testLibraryFragment>::@getter::hasAnnotation
    synthetic static get hasAnnotation2
      firstFragment: <testLibraryFragment>::@getter::hasAnnotation2
    synthetic static get annotationThenComment
      firstFragment: <testLibraryFragment>::@getter::annotationThenComment
    synthetic static get annotationThenComment2
      firstFragment: <testLibraryFragment>::@getter::annotationThenComment2
    synthetic static get commentThenAnnotation
      firstFragment: <testLibraryFragment>::@getter::commentThenAnnotation
    synthetic static get commentThenAnnotation2
      firstFragment: <testLibraryFragment>::@getter::commentThenAnnotation2
    synthetic static get commentAroundAnnotation
      firstFragment: <testLibraryFragment>::@getter::commentAroundAnnotation
    synthetic static get commentAroundAnnotation2
      firstFragment: <testLibraryFragment>::@getter::commentAroundAnnotation2
  setters
    synthetic static set hasDocComment
      firstFragment: <testLibraryFragment>::@setter::hasDocComment
      formalParameters
        requiredPositional _hasDocComment
          type: int
    synthetic static set hasDocComment2
      firstFragment: <testLibraryFragment>::@setter::hasDocComment2
      formalParameters
        requiredPositional _hasDocComment2
          type: int
    synthetic static set hasAnnotation
      firstFragment: <testLibraryFragment>::@setter::hasAnnotation
      formalParameters
        requiredPositional _hasAnnotation
          type: int
    synthetic static set hasAnnotation2
      firstFragment: <testLibraryFragment>::@setter::hasAnnotation2
      formalParameters
        requiredPositional _hasAnnotation2
          type: int
    synthetic static set annotationThenComment
      firstFragment: <testLibraryFragment>::@setter::annotationThenComment
      formalParameters
        requiredPositional _annotationThenComment
          type: int
    synthetic static set annotationThenComment2
      firstFragment: <testLibraryFragment>::@setter::annotationThenComment2
      formalParameters
        requiredPositional _annotationThenComment2
          type: int
    synthetic static set commentThenAnnotation
      firstFragment: <testLibraryFragment>::@setter::commentThenAnnotation
      formalParameters
        requiredPositional _commentThenAnnotation
          type: int
    synthetic static set commentThenAnnotation2
      firstFragment: <testLibraryFragment>::@setter::commentThenAnnotation2
      formalParameters
        requiredPositional _commentThenAnnotation2
          type: int
    synthetic static set commentAroundAnnotation
      firstFragment: <testLibraryFragment>::@setter::commentAroundAnnotation
      formalParameters
        requiredPositional _commentAroundAnnotation
          type: int
    synthetic static set commentAroundAnnotation2
      firstFragment: <testLibraryFragment>::@setter::commentAroundAnnotation2
      formalParameters
        requiredPositional _commentAroundAnnotation2
          type: int
''');
  }

  test_codeRange_type_parameter() async {
    var library = await buildLibrary('''
class A<T> {}
void f<U extends num> {}
''');
    configuration.withCodeRanges = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: T@8
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            U @21
              element: U@21
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        U
          bound: num
      returnType: void
''');
  }

  test_nameOffset_class_constructor() async {
    var library = await buildLibrary(r'''
class A {
  A();
  A.named();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 12
            named @21
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
              typeName: A
              typeNameOffset: 19
              periodOffset: 20
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
        named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named
''');
  }

  test_nameOffset_class_constructor_parameter() async {
    var library = await buildLibrary(r'''
class A {
  A(int a);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 12
              formalParameters
                a @18
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional a
              type: int
''');
  }

  test_nameOffset_class_field() async {
    var library = await buildLibrary(r'''
class A {
  int foo = 0;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            hasInitializer foo @16
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
              setter2: <testLibraryFragment>::@class::A::@setter::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@class::A::@setter::foo
              element: <testLibraryFragment>::@class::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
          setter: <testLibraryFragment>::@class::A::@setter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
      setters
        synthetic set foo
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_nameOffset_class_getter() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            synthetic foo
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          getters
            get foo @20
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
''');
  }

  test_nameOffset_class_method() async {
    var library = await buildLibrary(r'''
class A {
  void foo<T>(int a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          methods
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
              typeParameters
                T @21
                  element: T@21
              formalParameters
                a @28
                  element: <testLibraryFragment>::@class::A::@method::foo::@parameter::a#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
          typeParameters
            T
          formalParameters
            requiredPositional a
              type: int
''');
  }

  test_nameOffset_class_setter() async {
    var library = await buildLibrary(r'''
class A {
  set foo(int x) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          fields
            synthetic foo
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              setter2: <testLibraryFragment>::@class::A::@setter::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          setters
            set foo @16
              reference: <testLibraryFragment>::@class::A::@setter::foo
              element: <testLibraryFragment>::@class::A::@setter::foo#element
              formalParameters
                x @24
                  element: <testLibraryFragment>::@class::A::@setter::foo::@parameter::x#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          setter: <testLibraryFragment>::@class::A::@setter::foo#element
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      setters
        set foo
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo
          formalParameters
            requiredPositional x
              type: int
''');
  }

  test_nameOffset_class_typeParameter() async {
    var library = await buildLibrary(r'''
class A<T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: T@8
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
''');
  }

  test_nameOffset_extension_typeParameter() async {
    var library = await buildLibrary(r'''
extension E<T> on int {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
          element: <testLibrary>::@extension::E
          typeParameters
            T @12
              element: T@12
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: <testLibraryFragment>::@extension::E
      typeParameters
        T
''');
  }

  test_nameOffset_function_functionTypedFormal_parameter() async {
    var library = await buildLibrary(r'''
void f(void f<U>(int a)) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            f @12
              element: <testLibraryFragment>::@function::f::@parameter::f#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional f
          type: void Function<U>(int)
          formalParameters
            requiredPositional a
              type: int
      returnType: void
''');
  }

  test_nameOffset_function_functionTypedFormal_parameter2() async {
    var library = await buildLibrary(r'''
void f({required void f<U>(int a)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default f @22
              reference: <testLibraryFragment>::@function::f::@parameter::f
              element: <testLibraryFragment>::@function::f::@parameter::f#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredNamed f
          firstFragment: <testLibraryFragment>::@function::f::@parameter::f
          type: void Function<U>(int)
          formalParameters
            requiredPositional a
              type: int
      returnType: void
''');
  }

  test_nameOffset_function_typeParameter() async {
    var library = await buildLibrary(r'''
void f<T>() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          typeParameters
            T @7
              element: T@7
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        T
      returnType: void
''');
  }

  test_nameOffset_functionTypeAlias_typeParameter() async {
    var library = await buildLibrary(r'''
typedef void F<T>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @15
              element: T@15
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
      aliasedType: void Function()
''');
  }

  test_nameOffset_genericTypeAlias_typeParameter() async {
    var library = await buildLibrary(r'''
typedef F<T> = void Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @10
              element: T@10
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
      aliasedType: void Function()
''');
  }

  test_nameOffset_mixin_typeParameter() async {
    var library = await buildLibrary(r'''
mixin M<T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
          typeParameters
            T @8
              element: T@8
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
      superclassConstraints
        Object
''');
  }

  test_nameOffset_unit_getter() async {
    var library = await buildLibrary(r'''
int get foo => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @8
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
''');
  }
}

@reflectiveTest
class OffsetsElementTest_fromBytes extends OffsetsElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class OffsetsElementTest_keepLinking extends OffsetsElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
