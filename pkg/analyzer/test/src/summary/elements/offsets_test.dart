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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class Raw @6
          reference: <testLibraryFragment>::@class::Raw
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 12
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::Raw::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::Raw
        class HasDocComment @50
          reference: <testLibraryFragment>::@class::HasDocComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          codeOffset: 14
          codeLength: 52
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::HasDocComment::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::HasDocComment
        class HasAnnotation @84
          reference: <testLibraryFragment>::@class::HasAnnotation
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @68
              name: SimpleIdentifier
                token: Object @69
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @75
                rightParenthesis: ) @76
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 68
          codeLength: 32
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::HasAnnotation
        class AnnotationThenComment @148
          reference: <testLibraryFragment>::@class::AnnotationThenComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @102
              name: SimpleIdentifier
                token: Object @103
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @109
                rightParenthesis: ) @110
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 102
          codeLength: 70
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::AnnotationThenComment
        class CommentThenAnnotation @220
          reference: <testLibraryFragment>::@class::CommentThenAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @204
              name: SimpleIdentifier
                token: Object @205
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @211
                rightParenthesis: ) @212
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 174
          codeLength: 70
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::CommentThenAnnotation
        class CommentAroundAnnotation @292
          reference: <testLibraryFragment>::@class::CommentAroundAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @261
              name: SimpleIdentifier
                token: Object @262
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @268
                rightParenthesis: ) @269
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 261
          codeLength: 57
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::CommentAroundAnnotation
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class Raw @6
          reference: <testLibraryFragment>::@class::Raw
          element: <testLibraryFragment>::@class::Raw
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::Raw::@constructor::new
              element: <none>
        class HasDocComment @50
          reference: <testLibraryFragment>::@class::HasDocComment
          element: <testLibraryFragment>::@class::HasDocComment
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::HasDocComment::@constructor::new
              element: <none>
        class HasAnnotation @84
          reference: <testLibraryFragment>::@class::HasAnnotation
          element: <testLibraryFragment>::@class::HasAnnotation
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
              element: <none>
        class AnnotationThenComment @148
          reference: <testLibraryFragment>::@class::AnnotationThenComment
          element: <testLibraryFragment>::@class::AnnotationThenComment
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
              element: <none>
        class CommentThenAnnotation @220
          reference: <testLibraryFragment>::@class::CommentThenAnnotation
          element: <testLibraryFragment>::@class::CommentThenAnnotation
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
              element: <none>
        class CommentAroundAnnotation @292
          reference: <testLibraryFragment>::@class::CommentAroundAnnotation
          element: <testLibraryFragment>::@class::CommentAroundAnnotation
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
              element: <none>
  classes
    class Raw
      firstFragment: <testLibraryFragment>::@class::Raw
      codeOffset: 0
      codeLength: 12
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::Raw::@constructor::new
    class HasDocComment
      firstFragment: <testLibraryFragment>::@class::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 14
      codeLength: 52
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::HasDocComment::@constructor::new
    class HasAnnotation
      firstFragment: <testLibraryFragment>::@class::HasAnnotation
      codeOffset: 68
      codeLength: 32
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
    class AnnotationThenComment
      firstFragment: <testLibraryFragment>::@class::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 102
      codeLength: 70
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
    class CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 174
      codeLength: 70
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
    class CommentAroundAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentAroundAnnotation
      documentationComment: /// Comment 2.
      codeOffset: 261
      codeLength: 57
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 10
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
        class B @18
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          codeOffset: 12
          codeLength: 10
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
        class alias Raw @30
          reference: <testLibraryFragment>::@class::Raw
          enclosingElement3: <testLibraryFragment>
          codeOffset: 24
          codeLength: 29
          supertype: Object
          mixins
            A
            B
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::Raw::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::Raw
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class alias HasDocComment @91
          reference: <testLibraryFragment>::@class::HasDocComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          codeOffset: 55
          codeLength: 69
          supertype: Object
          mixins
            A
            B
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::HasDocComment::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::HasDocComment
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class alias HasAnnotation @142
          reference: <testLibraryFragment>::@class::HasAnnotation
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @126
              name: SimpleIdentifier
                token: Object @127
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @133
                rightParenthesis: ) @134
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 126
          codeLength: 49
          supertype: Object
          mixins
            A
            B
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::HasAnnotation
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class alias AnnotationThenComment @223
          reference: <testLibraryFragment>::@class::AnnotationThenComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @177
              name: SimpleIdentifier
                token: Object @178
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @184
                rightParenthesis: ) @185
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 177
          codeLength: 87
          supertype: Object
          mixins
            A
            B
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::AnnotationThenComment
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class alias CommentThenAnnotation @312
          reference: <testLibraryFragment>::@class::CommentThenAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @296
              name: SimpleIdentifier
                token: Object @297
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @303
                rightParenthesis: ) @304
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 266
          codeLength: 87
          supertype: Object
          mixins
            A
            B
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::CommentThenAnnotation
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class alias CommentAroundAnnotation @401
          reference: <testLibraryFragment>::@class::CommentAroundAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @370
              name: SimpleIdentifier
                token: Object @371
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @377
                rightParenthesis: ) @378
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 370
          codeLength: 74
          supertype: Object
          mixins
            A
            B
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::CommentAroundAnnotation
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
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
        class B @18
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
        class Raw @30
          reference: <testLibraryFragment>::@class::Raw
          element: <testLibraryFragment>::@class::Raw
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::Raw::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class HasDocComment @91
          reference: <testLibraryFragment>::@class::HasDocComment
          element: <testLibraryFragment>::@class::HasDocComment
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::HasDocComment::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class HasAnnotation @142
          reference: <testLibraryFragment>::@class::HasAnnotation
          element: <testLibraryFragment>::@class::HasAnnotation
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class AnnotationThenComment @223
          reference: <testLibraryFragment>::@class::AnnotationThenComment
          element: <testLibraryFragment>::@class::AnnotationThenComment
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class CommentThenAnnotation @312
          reference: <testLibraryFragment>::@class::CommentThenAnnotation
          element: <testLibraryFragment>::@class::CommentThenAnnotation
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class CommentAroundAnnotation @401
          reference: <testLibraryFragment>::@class::CommentAroundAnnotation
          element: <testLibraryFragment>::@class::CommentAroundAnnotation
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      codeOffset: 0
      codeLength: 10
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      firstFragment: <testLibraryFragment>::@class::B
      codeOffset: 12
      codeLength: 10
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class alias Raw
      firstFragment: <testLibraryFragment>::@class::Raw
      codeOffset: 24
      codeLength: 29
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::Raw::@constructor::new
    class alias HasDocComment
      firstFragment: <testLibraryFragment>::@class::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 55
      codeLength: 69
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::HasDocComment::@constructor::new
    class alias HasAnnotation
      firstFragment: <testLibraryFragment>::@class::HasAnnotation
      codeOffset: 126
      codeLength: 49
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
    class alias AnnotationThenComment
      firstFragment: <testLibraryFragment>::@class::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 177
      codeLength: 87
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
    class alias CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 266
      codeLength: 87
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
    class alias CommentAroundAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentAroundAnnotation
      documentationComment: /// Comment 2.
      codeOffset: 370
      codeLength: 74
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 362
          constructors
            @12
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 12
              codeLength: 4
            raw @22
              reference: <testLibraryFragment>::@class::C::@constructor::raw
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 20
              codeLength: 10
              periodOffset: 21
              nameEnd: 25
            hasDocComment @70
              reference: <testLibraryFragment>::@class::C::@constructor::hasDocComment
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 34
              codeLength: 54
              periodOffset: 69
              nameEnd: 83
            hasAnnotation @106
              reference: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @92
                  name: SimpleIdentifier
                    token: Object @93
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @99
                    rightParenthesis: ) @100
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 92
              codeLength: 32
              periodOffset: 105
              nameEnd: 119
            annotationThenComment @176
              reference: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @128
                  name: SimpleIdentifier
                    token: Object @129
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @135
                    rightParenthesis: ) @136
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 128
              codeLength: 74
              periodOffset: 175
              nameEnd: 197
            commentThenAnnotation @254
              reference: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @240
                  name: SimpleIdentifier
                    token: Object @241
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @247
                    rightParenthesis: ) @248
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 206
              codeLength: 74
              periodOffset: 253
              nameEnd: 275
            commentAroundAnnotation @332
              reference: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @301
                  name: SimpleIdentifier
                    token: Object @302
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @308
                    rightParenthesis: ) @309
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 301
              codeLength: 59
              periodOffset: 331
              nameEnd: 355
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            new @12
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              codeOffset: 12
              codeLength: 4
            raw @22
              reference: <testLibraryFragment>::@class::C::@constructor::raw
              element: <none>
              codeOffset: 20
              codeLength: 10
              periodOffset: 21
              nameEnd: 25
            hasDocComment @70
              reference: <testLibraryFragment>::@class::C::@constructor::hasDocComment
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 34
              codeLength: 54
              periodOffset: 69
              nameEnd: 83
            hasAnnotation @106
              reference: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
              element: <none>
              metadata
                Annotation
                  atSign: @ @92
                  name: SimpleIdentifier
                    token: Object @93
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @99
                    rightParenthesis: ) @100
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 92
              codeLength: 32
              periodOffset: 105
              nameEnd: 119
            annotationThenComment @176
              reference: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @128
                  name: SimpleIdentifier
                    token: Object @129
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @135
                    rightParenthesis: ) @136
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 128
              codeLength: 74
              periodOffset: 175
              nameEnd: 197
            commentThenAnnotation @254
              reference: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @240
                  name: SimpleIdentifier
                    token: Object @241
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @247
                    rightParenthesis: ) @248
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 206
              codeLength: 74
              periodOffset: 253
              nameEnd: 275
            commentAroundAnnotation @332
              reference: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
              element: <none>
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @301
                  name: SimpleIdentifier
                    token: Object @302
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @308
                    rightParenthesis: ) @309
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 301
              codeLength: 59
              periodOffset: 331
              nameEnd: 355
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      codeOffset: 0
      codeLength: 362
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
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @99
                rightParenthesis: ) @100
              element: dart:core::<fragment>::@class::Object::@constructor::new
        annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @128
              name: SimpleIdentifier
                token: Object @129
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @135
                rightParenthesis: ) @136
              element: dart:core::<fragment>::@class::Object::@constructor::new
        commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @240
              name: SimpleIdentifier
                token: Object @241
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @247
                rightParenthesis: ) @248
              element: dart:core::<fragment>::@class::Object::@constructor::new
        commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @301
              name: SimpleIdentifier
                token: Object @302
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @308
                rightParenthesis: ) @309
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 483
          constructors
            factory @20
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 12
              codeLength: 23
            factory raw @49
              reference: <testLibraryFragment>::@class::C::@constructor::raw
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 39
              codeLength: 27
              periodOffset: 48
              nameEnd: 52
            factory hasDocComment @114
              reference: <testLibraryFragment>::@class::C::@constructor::hasDocComment
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 70
              codeLength: 71
              periodOffset: 113
              nameEnd: 127
            factory hasAnnotation @167
              reference: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @145
                  name: SimpleIdentifier
                    token: Object @146
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @152
                    rightParenthesis: ) @153
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 145
              codeLength: 49
              periodOffset: 166
              nameEnd: 180
            factory annotationThenComment @254
              reference: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @198
                  name: SimpleIdentifier
                    token: Object @199
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @205
                    rightParenthesis: ) @206
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 198
              codeLength: 91
              periodOffset: 253
              nameEnd: 275
            factory commentThenAnnotation @349
              reference: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @327
                  name: SimpleIdentifier
                    token: Object @328
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @334
                    rightParenthesis: ) @335
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 293
              codeLength: 91
              periodOffset: 348
              nameEnd: 370
            factory commentAroundAnnotation @444
              reference: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @405
                  name: SimpleIdentifier
                    token: Object @406
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @412
                    rightParenthesis: ) @413
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 405
              codeLength: 76
              periodOffset: 443
              nameEnd: 467
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            factory new @20
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
              codeOffset: 12
              codeLength: 23
            factory raw @49
              reference: <testLibraryFragment>::@class::C::@constructor::raw
              element: <none>
              codeOffset: 39
              codeLength: 27
              periodOffset: 48
              nameEnd: 52
            factory hasDocComment @114
              reference: <testLibraryFragment>::@class::C::@constructor::hasDocComment
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 70
              codeLength: 71
              periodOffset: 113
              nameEnd: 127
            factory hasAnnotation @167
              reference: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
              element: <none>
              metadata
                Annotation
                  atSign: @ @145
                  name: SimpleIdentifier
                    token: Object @146
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @152
                    rightParenthesis: ) @153
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 145
              codeLength: 49
              periodOffset: 166
              nameEnd: 180
            factory annotationThenComment @254
              reference: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @198
                  name: SimpleIdentifier
                    token: Object @199
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @205
                    rightParenthesis: ) @206
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 198
              codeLength: 91
              periodOffset: 253
              nameEnd: 275
            factory commentThenAnnotation @349
              reference: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @327
                  name: SimpleIdentifier
                    token: Object @328
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @334
                    rightParenthesis: ) @335
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 293
              codeLength: 91
              periodOffset: 348
              nameEnd: 370
            factory commentAroundAnnotation @444
              reference: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
              element: <none>
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @405
                  name: SimpleIdentifier
                    token: Object @406
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @412
                    rightParenthesis: ) @413
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 405
              codeLength: 76
              periodOffset: 443
              nameEnd: 467
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      codeOffset: 0
      codeLength: 483
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
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @152
                rightParenthesis: ) @153
              element: dart:core::<fragment>::@class::Object::@constructor::new
        factory annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @198
              name: SimpleIdentifier
                token: Object @199
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @205
                rightParenthesis: ) @206
              element: dart:core::<fragment>::@class::Object::@constructor::new
        factory commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @327
              name: SimpleIdentifier
                token: Object @328
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @334
                rightParenthesis: ) @335
              element: dart:core::<fragment>::@class::Object::@constructor::new
        factory commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @405
              name: SimpleIdentifier
                token: Object @406
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @412
                rightParenthesis: ) @413
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 10
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      extensions
        Raw @22
          reference: <testLibraryFragment>::@extension::Raw
          enclosingElement3: <testLibraryFragment>
          codeOffset: 12
          codeLength: 21
          extendedType: A
        HasDocComment @75
          reference: <testLibraryFragment>::@extension::HasDocComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          codeOffset: 35
          codeLength: 61
          extendedType: A
        HasAnnotation @118
          reference: <testLibraryFragment>::@extension::HasAnnotation
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @98
              name: SimpleIdentifier
                token: Object @99
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @105
                rightParenthesis: ) @106
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 98
          codeLength: 41
          extendedType: A
        AnnotationThenComment @191
          reference: <testLibraryFragment>::@extension::AnnotationThenComment
          enclosingElement3: <testLibraryFragment>
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
          codeLength: 79
          extendedType: A
        CommentThenAnnotation @272
          reference: <testLibraryFragment>::@extension::CommentThenAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @252
              name: SimpleIdentifier
                token: Object @253
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @259
                rightParenthesis: ) @260
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 222
          codeLength: 79
          extendedType: A
        CommentAroundAnnotation @353
          reference: <testLibraryFragment>::@extension::CommentAroundAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @318
              name: SimpleIdentifier
                token: Object @319
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @325
                rightParenthesis: ) @326
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 318
          codeLength: 66
          extendedType: A
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
      extensions
        extension Raw @22
          reference: <testLibraryFragment>::@extension::Raw
          element: <testLibraryFragment>::@extension::Raw
        extension HasDocComment @75
          reference: <testLibraryFragment>::@extension::HasDocComment
          element: <testLibraryFragment>::@extension::HasDocComment
        extension HasAnnotation @118
          reference: <testLibraryFragment>::@extension::HasAnnotation
          element: <testLibraryFragment>::@extension::HasAnnotation
        extension AnnotationThenComment @191
          reference: <testLibraryFragment>::@extension::AnnotationThenComment
          element: <testLibraryFragment>::@extension::AnnotationThenComment
        extension CommentThenAnnotation @272
          reference: <testLibraryFragment>::@extension::CommentThenAnnotation
          element: <testLibraryFragment>::@extension::CommentThenAnnotation
        extension CommentAroundAnnotation @353
          reference: <testLibraryFragment>::@extension::CommentAroundAnnotation
          element: <testLibraryFragment>::@extension::CommentAroundAnnotation
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      codeOffset: 0
      codeLength: 10
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  extensions
    extension Raw
      firstFragment: <testLibraryFragment>::@extension::Raw
      codeOffset: 12
      codeLength: 21
    extension HasDocComment
      firstFragment: <testLibraryFragment>::@extension::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 35
      codeLength: 61
    extension HasAnnotation
      firstFragment: <testLibraryFragment>::@extension::HasAnnotation
      codeOffset: 98
      codeLength: 41
    extension AnnotationThenComment
      firstFragment: <testLibraryFragment>::@extension::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 141
      codeLength: 79
    extension CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@extension::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      codeOffset: 222
      codeLength: 79
    extension CommentAroundAnnotation
      firstFragment: <testLibraryFragment>::@extension::CommentAroundAnnotation
      documentationComment: /// Comment 2.
      codeOffset: 318
      codeLength: 66
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 115
          fields
            withInit @16
              reference: <testLibraryFragment>::@class::C::@field::withInit
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 12
              codeLength: 16
              type: int
              shouldUseTypeForInitializerInference: true
            withoutInit @37
              reference: <testLibraryFragment>::@class::C::@field::withoutInit
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 33
              codeLength: 15
              type: int
            multiWithInit @57
              reference: <testLibraryFragment>::@class::C::@field::multiWithInit
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 53
              codeLength: 21
              type: int
              shouldUseTypeForInitializerInference: true
            multiWithoutInit @76
              reference: <testLibraryFragment>::@class::C::@field::multiWithoutInit
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 76
              codeLength: 16
              type: int
            multiWithInit2 @94
              reference: <testLibraryFragment>::@class::C::@field::multiWithInit2
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 94
              codeLength: 18
              type: int
              shouldUseTypeForInitializerInference: true
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get withInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::withInit
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set withInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::withInit
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _withInit @-1
                  type: int
              returnType: void
            synthetic get withoutInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::withoutInit
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set withoutInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::withoutInit
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _withoutInit @-1
                  type: int
              returnType: void
            synthetic get multiWithInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithInit
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set multiWithInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithInit
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _multiWithInit @-1
                  type: int
              returnType: void
            synthetic get multiWithoutInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithoutInit
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set multiWithoutInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _multiWithoutInit @-1
                  type: int
              returnType: void
            synthetic get multiWithInit2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithInit2
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set multiWithInit2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithInit2
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _multiWithInit2 @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            withInit @16
              reference: <testLibraryFragment>::@class::C::@field::withInit
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::withInit
              setter2: <testLibraryFragment>::@class::C::@setter::withInit
            withoutInit @37
              reference: <testLibraryFragment>::@class::C::@field::withoutInit
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::withoutInit
              setter2: <testLibraryFragment>::@class::C::@setter::withoutInit
            multiWithInit @57
              reference: <testLibraryFragment>::@class::C::@field::multiWithInit
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithInit
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithInit
            multiWithoutInit @76
              reference: <testLibraryFragment>::@class::C::@field::multiWithoutInit
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithoutInit
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
            multiWithInit2 @94
              reference: <testLibraryFragment>::@class::C::@field::multiWithInit2
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithInit2
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithInit2
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get withInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::withInit
              element: <none>
            get withoutInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::withoutInit
              element: <none>
            get multiWithInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithInit
              element: <none>
            get multiWithoutInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithoutInit
              element: <none>
            get multiWithInit2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithInit2
              element: <none>
          setters
            set withInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::withInit
              element: <none>
              parameters
                _withInit @-1
                  element: <none>
            set withoutInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::withoutInit
              element: <none>
              parameters
                _withoutInit @-1
                  element: <none>
            set multiWithInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithInit
              element: <none>
              parameters
                _multiWithInit @-1
                  element: <none>
            set multiWithoutInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
              element: <none>
              parameters
                _multiWithoutInit @-1
                  element: <none>
            set multiWithInit2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithInit2
              element: <none>
              parameters
                _multiWithInit2 @-1
                  element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      codeOffset: 0
      codeLength: 115
      fields
        withInit
          firstFragment: <testLibraryFragment>::@class::C::@field::withInit
          type: int
          getter: <none>
          setter: <none>
        withoutInit
          firstFragment: <testLibraryFragment>::@class::C::@field::withoutInit
          type: int
          getter: <none>
          setter: <none>
        multiWithInit
          firstFragment: <testLibraryFragment>::@class::C::@field::multiWithInit
          type: int
          getter: <none>
          setter: <none>
        multiWithoutInit
          firstFragment: <testLibraryFragment>::@class::C::@field::multiWithoutInit
          type: int
          getter: <none>
          setter: <none>
        multiWithInit2
          firstFragment: <testLibraryFragment>::@class::C::@field::multiWithInit2
          type: int
          getter: <none>
          setter: <none>
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
        synthetic set withInit=
          firstFragment: <testLibraryFragment>::@class::C::@setter::withInit
          parameters
            requiredPositional _withInit
              type: int
        synthetic set withoutInit=
          firstFragment: <testLibraryFragment>::@class::C::@setter::withoutInit
          parameters
            requiredPositional _withoutInit
              type: int
        synthetic set multiWithInit=
          firstFragment: <testLibraryFragment>::@class::C::@setter::multiWithInit
          parameters
            requiredPositional _multiWithInit
              type: int
        synthetic set multiWithoutInit=
          firstFragment: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
          parameters
            requiredPositional _multiWithoutInit
              type: int
        synthetic set multiWithInit2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::multiWithInit2
          parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 436
          fields
            hasDocComment @50
              reference: <testLibraryFragment>::@class::C::@field::hasDocComment
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 12
              codeLength: 51
              type: int
            hasDocComment2 @65
              reference: <testLibraryFragment>::@class::C::@field::hasDocComment2
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 65
              codeLength: 14
              type: int
            hasAnnotation @100
              reference: <testLibraryFragment>::@class::C::@field::hasAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @84
                  name: SimpleIdentifier
                    token: Object @85
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @91
                    rightParenthesis: ) @92
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 84
              codeLength: 29
              type: int
            hasAnnotation2 @115
              reference: <testLibraryFragment>::@class::C::@field::hasAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @84
                  name: SimpleIdentifier
                    token: Object @85
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @91
                    rightParenthesis: ) @92
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 115
              codeLength: 14
              type: int
            annotationThenComment @184
              reference: <testLibraryFragment>::@class::C::@field::annotationThenComment
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @134
                  name: SimpleIdentifier
                    token: Object @135
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @141
                    rightParenthesis: ) @142
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 134
              codeLength: 71
              type: int
            annotationThenComment2 @207
              reference: <testLibraryFragment>::@class::C::@field::annotationThenComment2
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @134
                  name: SimpleIdentifier
                    token: Object @135
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @141
                    rightParenthesis: ) @142
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 207
              codeLength: 22
              type: int
            commentThenAnnotation @284
              reference: <testLibraryFragment>::@class::C::@field::commentThenAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @268
                  name: SimpleIdentifier
                    token: Object @269
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @275
                    rightParenthesis: ) @276
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 234
              codeLength: 71
              type: int
            commentThenAnnotation2 @307
              reference: <testLibraryFragment>::@class::C::@field::commentThenAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @268
                  name: SimpleIdentifier
                    token: Object @269
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @275
                    rightParenthesis: ) @276
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 307
              codeLength: 22
              type: int
            commentAroundAnnotation @384
              reference: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @351
                  name: SimpleIdentifier
                    token: Object @352
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @358
                    rightParenthesis: ) @359
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 351
              codeLength: 56
              type: int
            commentAroundAnnotation2 @409
              reference: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @351
                  name: SimpleIdentifier
                    token: Object @352
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @358
                    rightParenthesis: ) @359
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 409
              codeLength: 24
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          accessors
            synthetic get hasDocComment @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasDocComment
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set hasDocComment= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasDocComment
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _hasDocComment @-1
                  type: int
              returnType: void
            synthetic get hasDocComment2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasDocComment2
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set hasDocComment2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasDocComment2
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _hasDocComment2 @-1
                  type: int
              returnType: void
            synthetic get hasAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set hasAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _hasAnnotation @-1
                  type: int
              returnType: void
            synthetic get hasAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set hasAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _hasAnnotation2 @-1
                  type: int
              returnType: void
            synthetic get annotationThenComment @-1
              reference: <testLibraryFragment>::@class::C::@getter::annotationThenComment
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set annotationThenComment= @-1
              reference: <testLibraryFragment>::@class::C::@setter::annotationThenComment
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _annotationThenComment @-1
                  type: int
              returnType: void
            synthetic get annotationThenComment2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::annotationThenComment2
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set annotationThenComment2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _annotationThenComment2 @-1
                  type: int
              returnType: void
            synthetic get commentThenAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set commentThenAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _commentThenAnnotation @-1
                  type: int
              returnType: void
            synthetic get commentThenAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set commentThenAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _commentThenAnnotation2 @-1
                  type: int
              returnType: void
            synthetic get commentAroundAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set commentAroundAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _commentAroundAnnotation @-1
                  type: int
              returnType: void
            synthetic get commentAroundAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: int
            synthetic set commentAroundAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _commentAroundAnnotation2 @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          fields
            hasDocComment @50
              reference: <testLibraryFragment>::@class::C::@field::hasDocComment
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::hasDocComment
              setter2: <testLibraryFragment>::@class::C::@setter::hasDocComment
            hasDocComment2 @65
              reference: <testLibraryFragment>::@class::C::@field::hasDocComment2
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::hasDocComment2
              setter2: <testLibraryFragment>::@class::C::@setter::hasDocComment2
            hasAnnotation @100
              reference: <testLibraryFragment>::@class::C::@field::hasAnnotation
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::hasAnnotation
              setter2: <testLibraryFragment>::@class::C::@setter::hasAnnotation
            hasAnnotation2 @115
              reference: <testLibraryFragment>::@class::C::@field::hasAnnotation2
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::hasAnnotation2
              setter2: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
            annotationThenComment @184
              reference: <testLibraryFragment>::@class::C::@field::annotationThenComment
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::annotationThenComment
              setter2: <testLibraryFragment>::@class::C::@setter::annotationThenComment
            annotationThenComment2 @207
              reference: <testLibraryFragment>::@class::C::@field::annotationThenComment2
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::annotationThenComment2
              setter2: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
            commentThenAnnotation @284
              reference: <testLibraryFragment>::@class::C::@field::commentThenAnnotation
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation
              setter2: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
            commentThenAnnotation2 @307
              reference: <testLibraryFragment>::@class::C::@field::commentThenAnnotation2
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2
              setter2: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
            commentAroundAnnotation @384
              reference: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation
              setter2: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
            commentAroundAnnotation2 @409
              reference: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation2
              element: <none>
              getter2: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2
              setter2: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          getters
            get hasDocComment @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasDocComment
              element: <none>
            get hasDocComment2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasDocComment2
              element: <none>
            get hasAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasAnnotation
              element: <none>
            get hasAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasAnnotation2
              element: <none>
            get annotationThenComment @-1
              reference: <testLibraryFragment>::@class::C::@getter::annotationThenComment
              element: <none>
            get annotationThenComment2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::annotationThenComment2
              element: <none>
            get commentThenAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation
              element: <none>
            get commentThenAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2
              element: <none>
            get commentAroundAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation
              element: <none>
            get commentAroundAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2
              element: <none>
          setters
            set hasDocComment= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasDocComment
              element: <none>
              parameters
                _hasDocComment @-1
                  element: <none>
            set hasDocComment2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasDocComment2
              element: <none>
              parameters
                _hasDocComment2 @-1
                  element: <none>
            set hasAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasAnnotation
              element: <none>
              parameters
                _hasAnnotation @-1
                  element: <none>
            set hasAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
              element: <none>
              parameters
                _hasAnnotation2 @-1
                  element: <none>
            set annotationThenComment= @-1
              reference: <testLibraryFragment>::@class::C::@setter::annotationThenComment
              element: <none>
              parameters
                _annotationThenComment @-1
                  element: <none>
            set annotationThenComment2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
              element: <none>
              parameters
                _annotationThenComment2 @-1
                  element: <none>
            set commentThenAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
              element: <none>
              parameters
                _commentThenAnnotation @-1
                  element: <none>
            set commentThenAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
              element: <none>
              parameters
                _commentThenAnnotation2 @-1
                  element: <none>
            set commentAroundAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
              element: <none>
              parameters
                _commentAroundAnnotation @-1
                  element: <none>
            set commentAroundAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2
              element: <none>
              parameters
                _commentAroundAnnotation2 @-1
                  element: <none>
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      codeOffset: 0
      codeLength: 436
      fields
        hasDocComment
          firstFragment: <testLibraryFragment>::@class::C::@field::hasDocComment
          type: int
          getter: <none>
          setter: <none>
        hasDocComment2
          firstFragment: <testLibraryFragment>::@class::C::@field::hasDocComment2
          type: int
          getter: <none>
          setter: <none>
        hasAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@field::hasAnnotation
          type: int
          getter: <none>
          setter: <none>
        hasAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@field::hasAnnotation2
          type: int
          getter: <none>
          setter: <none>
        annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@field::annotationThenComment
          type: int
          getter: <none>
          setter: <none>
        annotationThenComment2
          firstFragment: <testLibraryFragment>::@class::C::@field::annotationThenComment2
          type: int
          getter: <none>
          setter: <none>
        commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@field::commentThenAnnotation
          type: int
          getter: <none>
          setter: <none>
        commentThenAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@field::commentThenAnnotation2
          type: int
          getter: <none>
          setter: <none>
        commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation
          type: int
          getter: <none>
          setter: <none>
        commentAroundAnnotation2
          firstFragment: <testLibraryFragment>::@class::C::@field::commentAroundAnnotation2
          type: int
          getter: <none>
          setter: <none>
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
        synthetic set hasDocComment=
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasDocComment
          parameters
            requiredPositional _hasDocComment
              type: int
        synthetic set hasDocComment2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasDocComment2
          parameters
            requiredPositional _hasDocComment2
              type: int
        synthetic set hasAnnotation=
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasAnnotation
          parameters
            requiredPositional _hasAnnotation
              type: int
        synthetic set hasAnnotation2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
          parameters
            requiredPositional _hasAnnotation2
              type: int
        synthetic set annotationThenComment=
          firstFragment: <testLibraryFragment>::@class::C::@setter::annotationThenComment
          parameters
            requiredPositional _annotationThenComment
              type: int
        synthetic set annotationThenComment2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
          parameters
            requiredPositional _annotationThenComment2
              type: int
        synthetic set commentThenAnnotation=
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
          parameters
            requiredPositional _commentThenAnnotation
              type: int
        synthetic set commentThenAnnotation2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
          parameters
            requiredPositional _commentThenAnnotation2
              type: int
        synthetic set commentAroundAnnotation=
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
          parameters
            requiredPositional _commentAroundAnnotation
              type: int
        synthetic set commentAroundAnnotation2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2
          parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        raw @5
          reference: <testLibraryFragment>::@function::raw
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 13
          returnType: void
        hasDocComment @50
          reference: <testLibraryFragment>::@function::hasDocComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          codeOffset: 15
          codeLength: 53
          returnType: void
        hasAnnotation @85
          reference: <testLibraryFragment>::@function::hasAnnotation
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @70
              name: SimpleIdentifier
                token: Object @71
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @77
                rightParenthesis: ) @78
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 70
          codeLength: 33
          returnType: void
        annotationThenComment @150
          reference: <testLibraryFragment>::@function::annotationThenComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @105
              name: SimpleIdentifier
                token: Object @106
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @112
                rightParenthesis: ) @113
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 105
          codeLength: 71
          returnType: void
        commentThenAnnotation @223
          reference: <testLibraryFragment>::@function::commentThenAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @208
              name: SimpleIdentifier
                token: Object @209
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @215
                rightParenthesis: ) @216
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 178
          codeLength: 71
          returnType: void
        commentAroundAnnotation @296
          reference: <testLibraryFragment>::@function::commentAroundAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @266
              name: SimpleIdentifier
                token: Object @267
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @273
                rightParenthesis: ) @274
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 266
          codeLength: 58
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        raw @5
          reference: <testLibraryFragment>::@function::raw
          element: <none>
        hasDocComment @50
          reference: <testLibraryFragment>::@function::hasDocComment
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
        hasAnnotation @85
          reference: <testLibraryFragment>::@function::hasAnnotation
          element: <none>
          metadata
            Annotation
              atSign: @ @70
              name: SimpleIdentifier
                token: Object @71
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @77
                rightParenthesis: ) @78
              element: dart:core::<fragment>::@class::Object::@constructor::new
        annotationThenComment @150
          reference: <testLibraryFragment>::@function::annotationThenComment
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @105
              name: SimpleIdentifier
                token: Object @106
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @112
                rightParenthesis: ) @113
              element: dart:core::<fragment>::@class::Object::@constructor::new
        commentThenAnnotation @223
          reference: <testLibraryFragment>::@function::commentThenAnnotation
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @208
              name: SimpleIdentifier
                token: Object @209
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @215
                rightParenthesis: ) @216
              element: dart:core::<fragment>::@class::Object::@constructor::new
        commentAroundAnnotation @296
          reference: <testLibraryFragment>::@function::commentAroundAnnotation
          element: <none>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @266
              name: SimpleIdentifier
                token: Object @267
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @273
                rightParenthesis: ) @274
              element: dart:core::<fragment>::@class::Object::@constructor::new
  functions
    raw
      firstFragment: <testLibraryFragment>::@function::raw
      returnType: void
    hasDocComment
      firstFragment: <testLibraryFragment>::@function::hasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      returnType: void
    hasAnnotation
      firstFragment: <testLibraryFragment>::@function::hasAnnotation
      metadata
        Annotation
          atSign: @ @70
          name: SimpleIdentifier
            token: Object @71
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @77
            rightParenthesis: ) @78
          element: dart:core::<fragment>::@class::Object::@constructor::new
      returnType: void
    annotationThenComment
      firstFragment: <testLibraryFragment>::@function::annotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @105
          name: SimpleIdentifier
            token: Object @106
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @112
            rightParenthesis: ) @113
          element: dart:core::<fragment>::@class::Object::@constructor::new
      returnType: void
    commentThenAnnotation
      firstFragment: <testLibraryFragment>::@function::commentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      metadata
        Annotation
          atSign: @ @208
          name: SimpleIdentifier
            token: Object @209
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @215
            rightParenthesis: ) @216
          element: dart:core::<fragment>::@class::Object::@constructor::new
      returnType: void
    commentAroundAnnotation
      firstFragment: <testLibraryFragment>::@function::commentAroundAnnotation
      documentationComment: /// Comment 2.
      metadata
        Annotation
          atSign: @ @266
          name: SimpleIdentifier
            token: Object @267
            staticElement: dart:core::<fragment>::@class::Object
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @273
            rightParenthesis: ) @274
          element: dart:core::<fragment>::@class::Object::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 372
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            raw @17
              reference: <testLibraryFragment>::@class::C::@method::raw
              enclosingElement3: <testLibraryFragment>::@class::C
              codeOffset: 12
              codeLength: 13
              returnType: void
            hasDocComment @68
              reference: <testLibraryFragment>::@class::C::@method::hasDocComment
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 29
              codeLength: 57
              returnType: void
            hasAnnotation @107
              reference: <testLibraryFragment>::@class::C::@method::hasAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              metadata
                Annotation
                  atSign: @ @90
                  name: SimpleIdentifier
                    token: Object @91
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @97
                    rightParenthesis: ) @98
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 90
              codeLength: 35
              returnType: void
            annotationThenComment @180
              reference: <testLibraryFragment>::@class::C::@method::annotationThenComment
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @129
                  name: SimpleIdentifier
                    token: Object @130
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @136
                    rightParenthesis: ) @137
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 129
              codeLength: 77
              returnType: void
            commentThenAnnotation @261
              reference: <testLibraryFragment>::@class::C::@method::commentThenAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @244
                  name: SimpleIdentifier
                    token: Object @245
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @251
                    rightParenthesis: ) @252
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 210
              codeLength: 77
              returnType: void
            commentAroundAnnotation @342
              reference: <testLibraryFragment>::@class::C::@method::commentAroundAnnotation
              enclosingElement3: <testLibraryFragment>::@class::C
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @308
                  name: SimpleIdentifier
                    token: Object @309
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @315
                    rightParenthesis: ) @316
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 308
              codeLength: 62
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          methods
            raw @17
              reference: <testLibraryFragment>::@class::C::@method::raw
              element: <none>
              codeOffset: 12
              codeLength: 13
            hasDocComment @68
              reference: <testLibraryFragment>::@class::C::@method::hasDocComment
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 29
              codeLength: 57
            hasAnnotation @107
              reference: <testLibraryFragment>::@class::C::@method::hasAnnotation
              element: <none>
              metadata
                Annotation
                  atSign: @ @90
                  name: SimpleIdentifier
                    token: Object @91
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @97
                    rightParenthesis: ) @98
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 90
              codeLength: 35
            annotationThenComment @180
              reference: <testLibraryFragment>::@class::C::@method::annotationThenComment
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @129
                  name: SimpleIdentifier
                    token: Object @130
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @136
                    rightParenthesis: ) @137
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 129
              codeLength: 77
            commentThenAnnotation @261
              reference: <testLibraryFragment>::@class::C::@method::commentThenAnnotation
              element: <none>
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @244
                  name: SimpleIdentifier
                    token: Object @245
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @251
                    rightParenthesis: ) @252
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 210
              codeLength: 77
            commentAroundAnnotation @342
              reference: <testLibraryFragment>::@class::C::@method::commentAroundAnnotation
              element: <none>
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @308
                  name: SimpleIdentifier
                    token: Object @309
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @315
                    rightParenthesis: ) @316
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 308
              codeLength: 62
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      codeOffset: 0
      codeLength: 372
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
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @97
                rightParenthesis: ) @98
              element: dart:core::<fragment>::@class::Object::@constructor::new
        annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@method::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @129
              name: SimpleIdentifier
                token: Object @130
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @136
                rightParenthesis: ) @137
              element: dart:core::<fragment>::@class::Object::@constructor::new
        commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@method::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @244
              name: SimpleIdentifier
                token: Object @245
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @251
                rightParenthesis: ) @252
              element: dart:core::<fragment>::@class::Object::@constructor::new
        commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@method::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @308
              name: SimpleIdentifier
                token: Object @309
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @315
                rightParenthesis: ) @316
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        main @0
          reference: <testLibraryFragment>::@function::main
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 38
          parameters
            optionalNamed default a @10
              reference: <testLibraryFragment>::@function::main::@parameter::a
              type: int
              codeOffset: 6
              codeLength: 9
              constantInitializer
                IntegerLiteral
                  literal: 1 @14
                  staticType: int
            optionalNamed default b @21
              reference: <testLibraryFragment>::@function::main::@parameter::b
              type: int
              codeOffset: 17
              codeLength: 5
            optionalNamed default c @28
              reference: <testLibraryFragment>::@function::main::@parameter::c
              type: int
              codeOffset: 24
              codeLength: 9
              constantInitializer
                IntegerLiteral
                  literal: 2 @32
                  staticType: int
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        main @0
          reference: <testLibraryFragment>::@function::main
          element: <none>
          parameters
            default a @10
              reference: <testLibraryFragment>::@function::main::@parameter::a
              element: <none>
            default b @21
              reference: <testLibraryFragment>::@function::main::@parameter::b
              element: <none>
            default c @28
              reference: <testLibraryFragment>::@function::main::@parameter::c
              element: <none>
  functions
    main
      firstFragment: <testLibraryFragment>::@function::main
      parameters
        optionalNamed a
          firstFragment: <testLibraryFragment>::@function::main::@parameter::a
          type: int
        optionalNamed b
          firstFragment: <testLibraryFragment>::@function::main::@parameter::b
          type: int
        optionalNamed c
          firstFragment: <testLibraryFragment>::@function::main::@parameter::c
          type: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        main @0
          reference: <testLibraryFragment>::@function::main
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 48
          parameters
            requiredPositional a @19
              type: int
              metadata
                Annotation
                  atSign: @ @5
                  name: SimpleIdentifier
                    token: Object @6
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @12
                    rightParenthesis: ) @13
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 5
              codeLength: 15
            requiredPositional b @26
              type: int
              codeOffset: 22
              codeLength: 5
            requiredPositional c @43
              type: int
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: Object @30
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @36
                    rightParenthesis: ) @37
                  element: dart:core::<fragment>::@class::Object::@constructor::new
              codeOffset: 29
              codeLength: 15
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        main @0
          reference: <testLibraryFragment>::@function::main
          element: <none>
          parameters
            a @19
              element: <none>
              metadata
                Annotation
                  atSign: @ @5
                  name: SimpleIdentifier
                    token: Object @6
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @12
                    rightParenthesis: ) @13
                  element: dart:core::<fragment>::@class::Object::@constructor::new
            b @26
              element: <none>
            c @43
              element: <none>
              metadata
                Annotation
                  atSign: @ @29
                  name: SimpleIdentifier
                    token: Object @30
                    staticElement: dart:core::<fragment>::@class::Object
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @36
                    rightParenthesis: ) @37
                  element: dart:core::<fragment>::@class::Object::@constructor::new
  functions
    main
      firstFragment: <testLibraryFragment>::@function::main
      parameters
        requiredPositional a
          type: int
          metadata
            Annotation
              atSign: @ @5
              name: SimpleIdentifier
                token: Object @6
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @12
                rightParenthesis: ) @13
              element: dart:core::<fragment>::@class::Object::@constructor::new
        requiredPositional b
          type: int
        requiredPositional c
          type: int
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: Object @30
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @36
                rightParenthesis: ) @37
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static withInit @4
          reference: <testLibraryFragment>::@topLevelVariable::withInit
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 24
          type: int
          shouldUseTypeForInitializerInference: true
        static withoutInit @31
          reference: <testLibraryFragment>::@topLevelVariable::withoutInit
          enclosingElement3: <testLibraryFragment>
          codeOffset: 27
          codeLength: 15
          type: int
        static multiWithInit @49
          reference: <testLibraryFragment>::@topLevelVariable::multiWithInit
          enclosingElement3: <testLibraryFragment>
          codeOffset: 45
          codeLength: 21
          type: int
          shouldUseTypeForInitializerInference: true
        static multiWithoutInit @68
          reference: <testLibraryFragment>::@topLevelVariable::multiWithoutInit
          enclosingElement3: <testLibraryFragment>
          codeOffset: 68
          codeLength: 16
          type: int
        static multiWithInit2 @86
          reference: <testLibraryFragment>::@topLevelVariable::multiWithInit2
          enclosingElement3: <testLibraryFragment>
          codeOffset: 86
          codeLength: 18
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get withInit @-1
          reference: <testLibraryFragment>::@getter::withInit
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set withInit= @-1
          reference: <testLibraryFragment>::@setter::withInit
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _withInit @-1
              type: int
          returnType: void
        synthetic static get withoutInit @-1
          reference: <testLibraryFragment>::@getter::withoutInit
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set withoutInit= @-1
          reference: <testLibraryFragment>::@setter::withoutInit
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _withoutInit @-1
              type: int
          returnType: void
        synthetic static get multiWithInit @-1
          reference: <testLibraryFragment>::@getter::multiWithInit
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set multiWithInit= @-1
          reference: <testLibraryFragment>::@setter::multiWithInit
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _multiWithInit @-1
              type: int
          returnType: void
        synthetic static get multiWithoutInit @-1
          reference: <testLibraryFragment>::@getter::multiWithoutInit
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set multiWithoutInit= @-1
          reference: <testLibraryFragment>::@setter::multiWithoutInit
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _multiWithoutInit @-1
              type: int
          returnType: void
        synthetic static get multiWithInit2 @-1
          reference: <testLibraryFragment>::@getter::multiWithInit2
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set multiWithInit2= @-1
          reference: <testLibraryFragment>::@setter::multiWithInit2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _multiWithInit2 @-1
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        withInit @4
          reference: <testLibraryFragment>::@topLevelVariable::withInit
          element: <none>
          getter2: <testLibraryFragment>::@getter::withInit
          setter2: <testLibraryFragment>::@setter::withInit
        withoutInit @31
          reference: <testLibraryFragment>::@topLevelVariable::withoutInit
          element: <none>
          getter2: <testLibraryFragment>::@getter::withoutInit
          setter2: <testLibraryFragment>::@setter::withoutInit
        multiWithInit @49
          reference: <testLibraryFragment>::@topLevelVariable::multiWithInit
          element: <none>
          getter2: <testLibraryFragment>::@getter::multiWithInit
          setter2: <testLibraryFragment>::@setter::multiWithInit
        multiWithoutInit @68
          reference: <testLibraryFragment>::@topLevelVariable::multiWithoutInit
          element: <none>
          getter2: <testLibraryFragment>::@getter::multiWithoutInit
          setter2: <testLibraryFragment>::@setter::multiWithoutInit
        multiWithInit2 @86
          reference: <testLibraryFragment>::@topLevelVariable::multiWithInit2
          element: <none>
          getter2: <testLibraryFragment>::@getter::multiWithInit2
          setter2: <testLibraryFragment>::@setter::multiWithInit2
      getters
        get withInit @-1
          reference: <testLibraryFragment>::@getter::withInit
          element: <none>
        get withoutInit @-1
          reference: <testLibraryFragment>::@getter::withoutInit
          element: <none>
        get multiWithInit @-1
          reference: <testLibraryFragment>::@getter::multiWithInit
          element: <none>
        get multiWithoutInit @-1
          reference: <testLibraryFragment>::@getter::multiWithoutInit
          element: <none>
        get multiWithInit2 @-1
          reference: <testLibraryFragment>::@getter::multiWithInit2
          element: <none>
      setters
        set withInit= @-1
          reference: <testLibraryFragment>::@setter::withInit
          element: <none>
          parameters
            _withInit @-1
              element: <none>
        set withoutInit= @-1
          reference: <testLibraryFragment>::@setter::withoutInit
          element: <none>
          parameters
            _withoutInit @-1
              element: <none>
        set multiWithInit= @-1
          reference: <testLibraryFragment>::@setter::multiWithInit
          element: <none>
          parameters
            _multiWithInit @-1
              element: <none>
        set multiWithoutInit= @-1
          reference: <testLibraryFragment>::@setter::multiWithoutInit
          element: <none>
          parameters
            _multiWithoutInit @-1
              element: <none>
        set multiWithInit2= @-1
          reference: <testLibraryFragment>::@setter::multiWithInit2
          element: <none>
          parameters
            _multiWithInit2 @-1
              element: <none>
  topLevelVariables
    withInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::withInit
      type: int
      getter: <none>
      setter: <none>
    withoutInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::withoutInit
      type: int
      getter: <none>
      setter: <none>
    multiWithInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::multiWithInit
      type: int
      getter: <none>
      setter: <none>
    multiWithoutInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::multiWithoutInit
      type: int
      getter: <none>
      setter: <none>
    multiWithInit2
      firstFragment: <testLibraryFragment>::@topLevelVariable::multiWithInit2
      type: int
      getter: <none>
      setter: <none>
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
    synthetic static set withInit=
      firstFragment: <testLibraryFragment>::@setter::withInit
      parameters
        requiredPositional _withInit
          type: int
    synthetic static set withoutInit=
      firstFragment: <testLibraryFragment>::@setter::withoutInit
      parameters
        requiredPositional _withoutInit
          type: int
    synthetic static set multiWithInit=
      firstFragment: <testLibraryFragment>::@setter::multiWithInit
      parameters
        requiredPositional _multiWithInit
          type: int
    synthetic static set multiWithoutInit=
      firstFragment: <testLibraryFragment>::@setter::multiWithoutInit
      parameters
        requiredPositional _multiWithoutInit
          type: int
    synthetic static set multiWithInit2=
      firstFragment: <testLibraryFragment>::@setter::multiWithInit2
      parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static hasDocComment @34
          reference: <testLibraryFragment>::@topLevelVariable::hasDocComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          codeOffset: 0
          codeLength: 47
          type: int
        static hasDocComment2 @49
          reference: <testLibraryFragment>::@topLevelVariable::hasDocComment2
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          codeOffset: 49
          codeLength: 14
          type: int
        static hasAnnotation @80
          reference: <testLibraryFragment>::@topLevelVariable::hasAnnotation
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @66
              name: SimpleIdentifier
                token: Object @67
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 66
          codeLength: 27
          type: int
        static hasAnnotation2 @95
          reference: <testLibraryFragment>::@topLevelVariable::hasAnnotation2
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @66
              name: SimpleIdentifier
                token: Object @67
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 95
          codeLength: 14
          type: int
        static annotationThenComment @156
          reference: <testLibraryFragment>::@topLevelVariable::annotationThenComment
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @112
              name: SimpleIdentifier
                token: Object @113
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 112
          codeLength: 65
          type: int
        static annotationThenComment2 @179
          reference: <testLibraryFragment>::@topLevelVariable::annotationThenComment2
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @112
              name: SimpleIdentifier
                token: Object @113
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 179
          codeLength: 22
          type: int
        static commentThenAnnotation @248
          reference: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @234
              name: SimpleIdentifier
                token: Object @235
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 204
          codeLength: 65
          type: int
        static commentThenAnnotation2 @271
          reference: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation2
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @234
              name: SimpleIdentifier
                token: Object @235
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 271
          codeLength: 22
          type: int
        static commentAroundAnnotation @340
          reference: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @311
              name: SimpleIdentifier
                token: Object @312
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 311
          codeLength: 52
          type: int
        static commentAroundAnnotation2 @365
          reference: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation2
          enclosingElement3: <testLibraryFragment>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @311
              name: SimpleIdentifier
                token: Object @312
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element: dart:core::<fragment>::@class::Object::@constructor::new
          codeOffset: 365
          codeLength: 24
          type: int
      accessors
        synthetic static get hasDocComment @-1
          reference: <testLibraryFragment>::@getter::hasDocComment
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set hasDocComment= @-1
          reference: <testLibraryFragment>::@setter::hasDocComment
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _hasDocComment @-1
              type: int
          returnType: void
        synthetic static get hasDocComment2 @-1
          reference: <testLibraryFragment>::@getter::hasDocComment2
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set hasDocComment2= @-1
          reference: <testLibraryFragment>::@setter::hasDocComment2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _hasDocComment2 @-1
              type: int
          returnType: void
        synthetic static get hasAnnotation @-1
          reference: <testLibraryFragment>::@getter::hasAnnotation
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set hasAnnotation= @-1
          reference: <testLibraryFragment>::@setter::hasAnnotation
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _hasAnnotation @-1
              type: int
          returnType: void
        synthetic static get hasAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::hasAnnotation2
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set hasAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::hasAnnotation2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _hasAnnotation2 @-1
              type: int
          returnType: void
        synthetic static get annotationThenComment @-1
          reference: <testLibraryFragment>::@getter::annotationThenComment
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set annotationThenComment= @-1
          reference: <testLibraryFragment>::@setter::annotationThenComment
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _annotationThenComment @-1
              type: int
          returnType: void
        synthetic static get annotationThenComment2 @-1
          reference: <testLibraryFragment>::@getter::annotationThenComment2
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set annotationThenComment2= @-1
          reference: <testLibraryFragment>::@setter::annotationThenComment2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _annotationThenComment2 @-1
              type: int
          returnType: void
        synthetic static get commentThenAnnotation @-1
          reference: <testLibraryFragment>::@getter::commentThenAnnotation
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set commentThenAnnotation= @-1
          reference: <testLibraryFragment>::@setter::commentThenAnnotation
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _commentThenAnnotation @-1
              type: int
          returnType: void
        synthetic static get commentThenAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::commentThenAnnotation2
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set commentThenAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::commentThenAnnotation2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _commentThenAnnotation2 @-1
              type: int
          returnType: void
        synthetic static get commentAroundAnnotation @-1
          reference: <testLibraryFragment>::@getter::commentAroundAnnotation
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set commentAroundAnnotation= @-1
          reference: <testLibraryFragment>::@setter::commentAroundAnnotation
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _commentAroundAnnotation @-1
              type: int
          returnType: void
        synthetic static get commentAroundAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::commentAroundAnnotation2
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set commentAroundAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::commentAroundAnnotation2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _commentAroundAnnotation2 @-1
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        hasDocComment @34
          reference: <testLibraryFragment>::@topLevelVariable::hasDocComment
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          getter2: <testLibraryFragment>::@getter::hasDocComment
          setter2: <testLibraryFragment>::@setter::hasDocComment
        hasDocComment2 @49
          reference: <testLibraryFragment>::@topLevelVariable::hasDocComment2
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          getter2: <testLibraryFragment>::@getter::hasDocComment2
          setter2: <testLibraryFragment>::@setter::hasDocComment2
        hasAnnotation @80
          reference: <testLibraryFragment>::@topLevelVariable::hasAnnotation
          element: <none>
          metadata
            Annotation
              atSign: @ @66
              name: SimpleIdentifier
                token: Object @67
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element: dart:core::<fragment>::@class::Object::@constructor::new
          getter2: <testLibraryFragment>::@getter::hasAnnotation
          setter2: <testLibraryFragment>::@setter::hasAnnotation
        hasAnnotation2 @95
          reference: <testLibraryFragment>::@topLevelVariable::hasAnnotation2
          element: <none>
          metadata
            Annotation
              atSign: @ @66
              name: SimpleIdentifier
                token: Object @67
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element: dart:core::<fragment>::@class::Object::@constructor::new
          getter2: <testLibraryFragment>::@getter::hasAnnotation2
          setter2: <testLibraryFragment>::@setter::hasAnnotation2
        annotationThenComment @156
          reference: <testLibraryFragment>::@topLevelVariable::annotationThenComment
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @112
              name: SimpleIdentifier
                token: Object @113
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element: dart:core::<fragment>::@class::Object::@constructor::new
          getter2: <testLibraryFragment>::@getter::annotationThenComment
          setter2: <testLibraryFragment>::@setter::annotationThenComment
        annotationThenComment2 @179
          reference: <testLibraryFragment>::@topLevelVariable::annotationThenComment2
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @112
              name: SimpleIdentifier
                token: Object @113
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element: dart:core::<fragment>::@class::Object::@constructor::new
          getter2: <testLibraryFragment>::@getter::annotationThenComment2
          setter2: <testLibraryFragment>::@setter::annotationThenComment2
        commentThenAnnotation @248
          reference: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @234
              name: SimpleIdentifier
                token: Object @235
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element: dart:core::<fragment>::@class::Object::@constructor::new
          getter2: <testLibraryFragment>::@getter::commentThenAnnotation
          setter2: <testLibraryFragment>::@setter::commentThenAnnotation
        commentThenAnnotation2 @271
          reference: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation2
          element: <none>
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @234
              name: SimpleIdentifier
                token: Object @235
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element: dart:core::<fragment>::@class::Object::@constructor::new
          getter2: <testLibraryFragment>::@getter::commentThenAnnotation2
          setter2: <testLibraryFragment>::@setter::commentThenAnnotation2
        commentAroundAnnotation @340
          reference: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation
          element: <none>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @311
              name: SimpleIdentifier
                token: Object @312
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element: dart:core::<fragment>::@class::Object::@constructor::new
          getter2: <testLibraryFragment>::@getter::commentAroundAnnotation
          setter2: <testLibraryFragment>::@setter::commentAroundAnnotation
        commentAroundAnnotation2 @365
          reference: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation2
          element: <none>
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @311
              name: SimpleIdentifier
                token: Object @312
                staticElement: dart:core::<fragment>::@class::Object
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element: dart:core::<fragment>::@class::Object::@constructor::new
          getter2: <testLibraryFragment>::@getter::commentAroundAnnotation2
          setter2: <testLibraryFragment>::@setter::commentAroundAnnotation2
      getters
        get hasDocComment @-1
          reference: <testLibraryFragment>::@getter::hasDocComment
          element: <none>
        get hasDocComment2 @-1
          reference: <testLibraryFragment>::@getter::hasDocComment2
          element: <none>
        get hasAnnotation @-1
          reference: <testLibraryFragment>::@getter::hasAnnotation
          element: <none>
        get hasAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::hasAnnotation2
          element: <none>
        get annotationThenComment @-1
          reference: <testLibraryFragment>::@getter::annotationThenComment
          element: <none>
        get annotationThenComment2 @-1
          reference: <testLibraryFragment>::@getter::annotationThenComment2
          element: <none>
        get commentThenAnnotation @-1
          reference: <testLibraryFragment>::@getter::commentThenAnnotation
          element: <none>
        get commentThenAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::commentThenAnnotation2
          element: <none>
        get commentAroundAnnotation @-1
          reference: <testLibraryFragment>::@getter::commentAroundAnnotation
          element: <none>
        get commentAroundAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::commentAroundAnnotation2
          element: <none>
      setters
        set hasDocComment= @-1
          reference: <testLibraryFragment>::@setter::hasDocComment
          element: <none>
          parameters
            _hasDocComment @-1
              element: <none>
        set hasDocComment2= @-1
          reference: <testLibraryFragment>::@setter::hasDocComment2
          element: <none>
          parameters
            _hasDocComment2 @-1
              element: <none>
        set hasAnnotation= @-1
          reference: <testLibraryFragment>::@setter::hasAnnotation
          element: <none>
          parameters
            _hasAnnotation @-1
              element: <none>
        set hasAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::hasAnnotation2
          element: <none>
          parameters
            _hasAnnotation2 @-1
              element: <none>
        set annotationThenComment= @-1
          reference: <testLibraryFragment>::@setter::annotationThenComment
          element: <none>
          parameters
            _annotationThenComment @-1
              element: <none>
        set annotationThenComment2= @-1
          reference: <testLibraryFragment>::@setter::annotationThenComment2
          element: <none>
          parameters
            _annotationThenComment2 @-1
              element: <none>
        set commentThenAnnotation= @-1
          reference: <testLibraryFragment>::@setter::commentThenAnnotation
          element: <none>
          parameters
            _commentThenAnnotation @-1
              element: <none>
        set commentThenAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::commentThenAnnotation2
          element: <none>
          parameters
            _commentThenAnnotation2 @-1
              element: <none>
        set commentAroundAnnotation= @-1
          reference: <testLibraryFragment>::@setter::commentAroundAnnotation
          element: <none>
          parameters
            _commentAroundAnnotation @-1
              element: <none>
        set commentAroundAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::commentAroundAnnotation2
          element: <none>
          parameters
            _commentAroundAnnotation2 @-1
              element: <none>
  topLevelVariables
    hasDocComment
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasDocComment
      type: int
      getter: <none>
      setter: <none>
    hasDocComment2
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasDocComment2
      type: int
      getter: <none>
      setter: <none>
    hasAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasAnnotation
      type: int
      getter: <none>
      setter: <none>
    hasAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasAnnotation2
      type: int
      getter: <none>
      setter: <none>
    annotationThenComment
      firstFragment: <testLibraryFragment>::@topLevelVariable::annotationThenComment
      type: int
      getter: <none>
      setter: <none>
    annotationThenComment2
      firstFragment: <testLibraryFragment>::@topLevelVariable::annotationThenComment2
      type: int
      getter: <none>
      setter: <none>
    commentThenAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation
      type: int
      getter: <none>
      setter: <none>
    commentThenAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation2
      type: int
      getter: <none>
      setter: <none>
    commentAroundAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation
      type: int
      getter: <none>
      setter: <none>
    commentAroundAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation2
      type: int
      getter: <none>
      setter: <none>
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
    synthetic static set hasDocComment=
      firstFragment: <testLibraryFragment>::@setter::hasDocComment
      parameters
        requiredPositional _hasDocComment
          type: int
    synthetic static set hasDocComment2=
      firstFragment: <testLibraryFragment>::@setter::hasDocComment2
      parameters
        requiredPositional _hasDocComment2
          type: int
    synthetic static set hasAnnotation=
      firstFragment: <testLibraryFragment>::@setter::hasAnnotation
      parameters
        requiredPositional _hasAnnotation
          type: int
    synthetic static set hasAnnotation2=
      firstFragment: <testLibraryFragment>::@setter::hasAnnotation2
      parameters
        requiredPositional _hasAnnotation2
          type: int
    synthetic static set annotationThenComment=
      firstFragment: <testLibraryFragment>::@setter::annotationThenComment
      parameters
        requiredPositional _annotationThenComment
          type: int
    synthetic static set annotationThenComment2=
      firstFragment: <testLibraryFragment>::@setter::annotationThenComment2
      parameters
        requiredPositional _annotationThenComment2
          type: int
    synthetic static set commentThenAnnotation=
      firstFragment: <testLibraryFragment>::@setter::commentThenAnnotation
      parameters
        requiredPositional _commentThenAnnotation
          type: int
    synthetic static set commentThenAnnotation2=
      firstFragment: <testLibraryFragment>::@setter::commentThenAnnotation2
      parameters
        requiredPositional _commentThenAnnotation2
          type: int
    synthetic static set commentAroundAnnotation=
      firstFragment: <testLibraryFragment>::@setter::commentAroundAnnotation
      parameters
        requiredPositional _commentAroundAnnotation
          type: int
    synthetic static set commentAroundAnnotation2=
      firstFragment: <testLibraryFragment>::@setter::commentAroundAnnotation2
      parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 13
          typeParameters
            covariant T @8
              codeOffset: 8
              codeLength: 1
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          codeOffset: 14
          codeLength: 24
          typeParameters
            covariant U @21
              codeOffset: 21
              codeLength: 13
              bound: num
              defaultType: num
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
          typeParameters
            T @8
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            U @21
              element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      codeOffset: 0
      codeLength: 13
      typeParameters
        T
          codeOffset: 8
          codeLength: 1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      typeParameters
        U
          codeOffset: 21
          codeLength: 13
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
            named @21
              reference: <testLibraryFragment>::@class::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 20
              nameEnd: 26
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
            new @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
            named @21
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <none>
              periodOffset: 20
              nameEnd: 26
  classes
    class A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional a @18
                  type: int
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
            new @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                a @18
                  element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            foo @16
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: true
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _foo @-1
                  type: int
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
          fields
            foo @16
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::foo
              setter2: <testLibraryFragment>::@class::A::@setter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo
              element: <none>
              parameters
                _foo @-1
                  element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo
          parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            get foo @20
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
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
          fields
            foo @-1
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get foo @20
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              typeParameters
                covariant T @21
                  defaultType: dynamic
              parameters
                requiredPositional a @28
                  type: int
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
          methods
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <none>
              typeParameters
                T @21
                  element: <none>
              parameters
                a @28
                  element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
          typeParameters
            T
          parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            set foo= @16
              reference: <testLibraryFragment>::@class::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional x @24
                  type: int
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
          fields
            foo @-1
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <none>
              setter2: <testLibraryFragment>::@class::A::@setter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          setters
            set foo= @16
              reference: <testLibraryFragment>::@class::A::@setter::foo
              element: <none>
              parameters
                x @24
                  element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          setter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      setters
        set foo=
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo
          parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
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
          typeParameters
            T @8
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
  classes
    class A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @12
              defaultType: dynamic
          extendedType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E
          element: <testLibraryFragment>::@extension::E
          typeParameters
            T @12
              element: <none>
  extensions
    extension E
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional f @12
              type: void Function<U>(int)
              typeParameters
                covariant U @14
              parameters
                requiredPositional a @21
                  type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            f @12
              element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      parameters
        requiredPositional f
          type: void Function<U>(int)
          parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredNamed default f @22
              reference: <testLibraryFragment>::@function::f::@parameter::f
              type: void Function<U>(int)
              typeParameters
                covariant U @24
              parameters
                requiredPositional a @31
                  type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            default f @22
              reference: <testLibraryFragment>::@function::f::@parameter::f
              element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      parameters
        requiredNamed f
          firstFragment: <testLibraryFragment>::@function::f::@parameter::f
          type: void Function<U>(int)
          parameters
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            T @7
              element: <none>
  functions
    f
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
          typeParameters
            T @8
              element: <none>
  mixins
    mixin M
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static get foo @8
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @8
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  topLevelVariables
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <none>
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
