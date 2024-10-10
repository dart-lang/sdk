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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @75
                rightParenthesis: ) @76
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @109
                rightParenthesis: ) @110
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @211
                rightParenthesis: ) @212
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @268
                rightParenthesis: ) @269
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@class::Raw#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::Raw::@constructor::new
              element: <testLibraryFragment>::@class::Raw::@constructor::new#element
        class HasDocComment @50
          reference: <testLibraryFragment>::@class::HasDocComment
          element: <testLibraryFragment>::@class::HasDocComment#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::HasDocComment::@constructor::new
              element: <testLibraryFragment>::@class::HasDocComment::@constructor::new#element
        class HasAnnotation @84
          reference: <testLibraryFragment>::@class::HasAnnotation
          element: <testLibraryFragment>::@class::HasAnnotation#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::HasAnnotation::@constructor::new#element
        class AnnotationThenComment @148
          reference: <testLibraryFragment>::@class::AnnotationThenComment
          element: <testLibraryFragment>::@class::AnnotationThenComment#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
              element: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new#element
        class CommentThenAnnotation @220
          reference: <testLibraryFragment>::@class::CommentThenAnnotation
          element: <testLibraryFragment>::@class::CommentThenAnnotation#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new#element
        class CommentAroundAnnotation @292
          reference: <testLibraryFragment>::@class::CommentAroundAnnotation
          element: <testLibraryFragment>::@class::CommentAroundAnnotation#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new#element
  classes
    class Raw
      firstFragment: <testLibraryFragment>::@class::Raw
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::Raw::@constructor::new
    class HasDocComment
      firstFragment: <testLibraryFragment>::@class::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::HasDocComment::@constructor::new
    class HasAnnotation
      firstFragment: <testLibraryFragment>::@class::HasAnnotation
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
    class AnnotationThenComment
      firstFragment: <testLibraryFragment>::@class::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
    class CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
    class CommentAroundAnnotation
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
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class alias HasAnnotation @142
          reference: <testLibraryFragment>::@class::HasAnnotation
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @126
              name: SimpleIdentifier
                token: Object @127
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @133
                rightParenthesis: ) @134
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @184
                rightParenthesis: ) @185
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @303
                rightParenthesis: ) @304
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @377
                rightParenthesis: ) @378
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
        class B @18
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
        class Raw @30
          reference: <testLibraryFragment>::@class::Raw
          element: <testLibraryFragment>::@class::Raw#element
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::Raw::@constructor::new
              element: <testLibraryFragment>::@class::Raw::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class HasDocComment @91
          reference: <testLibraryFragment>::@class::HasDocComment
          element: <testLibraryFragment>::@class::HasDocComment#element
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::HasDocComment::@constructor::new
              element: <testLibraryFragment>::@class::HasDocComment::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class HasAnnotation @142
          reference: <testLibraryFragment>::@class::HasAnnotation
          element: <testLibraryFragment>::@class::HasAnnotation#element
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::HasAnnotation::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class AnnotationThenComment @223
          reference: <testLibraryFragment>::@class::AnnotationThenComment
          element: <testLibraryFragment>::@class::AnnotationThenComment#element
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
              element: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class CommentThenAnnotation @312
          reference: <testLibraryFragment>::@class::CommentThenAnnotation
          element: <testLibraryFragment>::@class::CommentThenAnnotation#element
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class CommentAroundAnnotation @401
          reference: <testLibraryFragment>::@class::CommentAroundAnnotation
          element: <testLibraryFragment>::@class::CommentAroundAnnotation#element
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new
              element: <testLibraryFragment>::@class::CommentAroundAnnotation::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class alias Raw
      firstFragment: <testLibraryFragment>::@class::Raw
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::Raw::@constructor::new
    class alias HasDocComment
      firstFragment: <testLibraryFragment>::@class::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::HasDocComment::@constructor::new
    class alias HasAnnotation
      firstFragment: <testLibraryFragment>::@class::HasAnnotation
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::HasAnnotation::@constructor::new
    class alias AnnotationThenComment
      firstFragment: <testLibraryFragment>::@class::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::AnnotationThenComment::@constructor::new
    class alias CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::CommentThenAnnotation::@constructor::new
    class alias CommentAroundAnnotation
      firstFragment: <testLibraryFragment>::@class::CommentAroundAnnotation
      documentationComment: /// Comment 2.
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @99
                    rightParenthesis: ) @100
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @135
                    rightParenthesis: ) @136
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @247
                    rightParenthesis: ) @248
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @308
                    rightParenthesis: ) @309
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            new @12
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              codeOffset: 12
              codeLength: 4
            raw @22
              reference: <testLibraryFragment>::@class::C::@constructor::raw
              element: <testLibraryFragment>::@class::C::@constructor::raw#element
              codeOffset: 20
              codeLength: 10
              periodOffset: 21
              nameEnd: 25
            hasDocComment @70
              reference: <testLibraryFragment>::@class::C::@constructor::hasDocComment
              element: <testLibraryFragment>::@class::C::@constructor::hasDocComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 34
              codeLength: 54
              periodOffset: 69
              nameEnd: 83
            hasAnnotation @106
              reference: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::hasAnnotation#element
              metadata
                Annotation
                  atSign: @ @92
                  name: SimpleIdentifier
                    token: Object @93
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @99
                    rightParenthesis: ) @100
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 92
              codeLength: 32
              periodOffset: 105
              nameEnd: 119
            annotationThenComment @176
              reference: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
              element: <testLibraryFragment>::@class::C::@constructor::annotationThenComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @128
                  name: SimpleIdentifier
                    token: Object @129
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @135
                    rightParenthesis: ) @136
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 128
              codeLength: 74
              periodOffset: 175
              nameEnd: 197
            commentThenAnnotation @254
              reference: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @240
                  name: SimpleIdentifier
                    token: Object @241
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @247
                    rightParenthesis: ) @248
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 206
              codeLength: 74
              periodOffset: 253
              nameEnd: 275
            commentAroundAnnotation @332
              reference: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation#element
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @301
                  name: SimpleIdentifier
                    token: Object @302
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @308
                    rightParenthesis: ) @309
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 301
              codeLength: 59
              periodOffset: 331
              nameEnd: 355
  classes
    class C
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
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @99
                rightParenthesis: ) @100
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @128
              name: SimpleIdentifier
                token: Object @129
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @135
                rightParenthesis: ) @136
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @240
              name: SimpleIdentifier
                token: Object @241
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @247
                rightParenthesis: ) @248
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @301
              name: SimpleIdentifier
                token: Object @302
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @308
                rightParenthesis: ) @309
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @152
                    rightParenthesis: ) @153
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @205
                    rightParenthesis: ) @206
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @334
                    rightParenthesis: ) @335
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @412
                    rightParenthesis: ) @413
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            factory new @20
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              codeOffset: 12
              codeLength: 23
            factory raw @49
              reference: <testLibraryFragment>::@class::C::@constructor::raw
              element: <testLibraryFragment>::@class::C::@constructor::raw#element
              codeOffset: 39
              codeLength: 27
              periodOffset: 48
              nameEnd: 52
            factory hasDocComment @114
              reference: <testLibraryFragment>::@class::C::@constructor::hasDocComment
              element: <testLibraryFragment>::@class::C::@constructor::hasDocComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 70
              codeLength: 71
              periodOffset: 113
              nameEnd: 127
            factory hasAnnotation @167
              reference: <testLibraryFragment>::@class::C::@constructor::hasAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::hasAnnotation#element
              metadata
                Annotation
                  atSign: @ @145
                  name: SimpleIdentifier
                    token: Object @146
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @152
                    rightParenthesis: ) @153
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 145
              codeLength: 49
              periodOffset: 166
              nameEnd: 180
            factory annotationThenComment @254
              reference: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
              element: <testLibraryFragment>::@class::C::@constructor::annotationThenComment#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @198
                  name: SimpleIdentifier
                    token: Object @199
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @205
                    rightParenthesis: ) @206
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 198
              codeLength: 91
              periodOffset: 253
              nameEnd: 275
            factory commentThenAnnotation @349
              reference: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation#element
              documentationComment: /// Comment 1.\n/// Comment 2.
              metadata
                Annotation
                  atSign: @ @327
                  name: SimpleIdentifier
                    token: Object @328
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @334
                    rightParenthesis: ) @335
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 293
              codeLength: 91
              periodOffset: 348
              nameEnd: 370
            factory commentAroundAnnotation @444
              reference: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation#element
              documentationComment: /// Comment 2.
              metadata
                Annotation
                  atSign: @ @405
                  name: SimpleIdentifier
                    token: Object @406
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @412
                    rightParenthesis: ) @413
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 405
              codeLength: 76
              periodOffset: 443
              nameEnd: 467
  classes
    class C
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
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @152
                rightParenthesis: ) @153
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        factory annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@constructor::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @198
              name: SimpleIdentifier
                token: Object @199
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @205
                rightParenthesis: ) @206
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        factory commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @327
              name: SimpleIdentifier
                token: Object @328
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @334
                rightParenthesis: ) @335
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        factory commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@constructor::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @405
              name: SimpleIdentifier
                token: Object @406
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @412
                rightParenthesis: ) @413
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @105
                rightParenthesis: ) @106
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @148
                rightParenthesis: ) @149
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @259
                rightParenthesis: ) @260
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @325
                rightParenthesis: ) @326
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      extensions
        extension Raw @22
          reference: <testLibraryFragment>::@extension::Raw
          element: <testLibraryFragment>::@extension::Raw#element
        extension HasDocComment @75
          reference: <testLibraryFragment>::@extension::HasDocComment
          element: <testLibraryFragment>::@extension::HasDocComment#element
        extension HasAnnotation @118
          reference: <testLibraryFragment>::@extension::HasAnnotation
          element: <testLibraryFragment>::@extension::HasAnnotation#element
        extension AnnotationThenComment @191
          reference: <testLibraryFragment>::@extension::AnnotationThenComment
          element: <testLibraryFragment>::@extension::AnnotationThenComment#element
        extension CommentThenAnnotation @272
          reference: <testLibraryFragment>::@extension::CommentThenAnnotation
          element: <testLibraryFragment>::@extension::CommentThenAnnotation#element
        extension CommentAroundAnnotation @353
          reference: <testLibraryFragment>::@extension::CommentAroundAnnotation
          element: <testLibraryFragment>::@extension::CommentAroundAnnotation#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  extensions
    extension Raw
      firstFragment: <testLibraryFragment>::@extension::Raw
    extension HasDocComment
      firstFragment: <testLibraryFragment>::@extension::HasDocComment
      documentationComment: /// Comment 1.\n/// Comment 2.
    extension HasAnnotation
      firstFragment: <testLibraryFragment>::@extension::HasAnnotation
    extension AnnotationThenComment
      firstFragment: <testLibraryFragment>::@extension::AnnotationThenComment
      documentationComment: /// Comment 1.\n/// Comment 2.
    extension CommentThenAnnotation
      firstFragment: <testLibraryFragment>::@extension::CommentThenAnnotation
      documentationComment: /// Comment 1.\n/// Comment 2.
    extension CommentAroundAnnotation
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
          element: <testLibraryFragment>::@class::C#element
          fields
            withInit @16
              reference: <testLibraryFragment>::@class::C::@field::withInit
              element: <testLibraryFragment>::@class::C::@field::withInit#element
              getter2: <testLibraryFragment>::@class::C::@getter::withInit
              setter2: <testLibraryFragment>::@class::C::@setter::withInit
            withoutInit @37
              reference: <testLibraryFragment>::@class::C::@field::withoutInit
              element: <testLibraryFragment>::@class::C::@field::withoutInit#element
              getter2: <testLibraryFragment>::@class::C::@getter::withoutInit
              setter2: <testLibraryFragment>::@class::C::@setter::withoutInit
            multiWithInit @57
              reference: <testLibraryFragment>::@class::C::@field::multiWithInit
              element: <testLibraryFragment>::@class::C::@field::multiWithInit#element
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithInit
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithInit
            multiWithoutInit @76
              reference: <testLibraryFragment>::@class::C::@field::multiWithoutInit
              element: <testLibraryFragment>::@class::C::@field::multiWithoutInit#element
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithoutInit
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
            multiWithInit2 @94
              reference: <testLibraryFragment>::@class::C::@field::multiWithInit2
              element: <testLibraryFragment>::@class::C::@field::multiWithInit2#element
              getter2: <testLibraryFragment>::@class::C::@getter::multiWithInit2
              setter2: <testLibraryFragment>::@class::C::@setter::multiWithInit2
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get withInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::withInit
              element: <testLibraryFragment>::@class::C::@getter::withInit#element
            get withoutInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::withoutInit
              element: <testLibraryFragment>::@class::C::@getter::withoutInit#element
            get multiWithInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithInit
              element: <testLibraryFragment>::@class::C::@getter::multiWithInit#element
            get multiWithoutInit @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithoutInit
              element: <testLibraryFragment>::@class::C::@getter::multiWithoutInit#element
            get multiWithInit2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::multiWithInit2
              element: <testLibraryFragment>::@class::C::@getter::multiWithInit2#element
          setters
            set withInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::withInit
              element: <testLibraryFragment>::@class::C::@setter::withInit#element
              formalParameters
                _withInit @-1
                  element: <testLibraryFragment>::@class::C::@setter::withInit::@parameter::_withInit#element
            set withoutInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::withoutInit
              element: <testLibraryFragment>::@class::C::@setter::withoutInit#element
              formalParameters
                _withoutInit @-1
                  element: <testLibraryFragment>::@class::C::@setter::withoutInit::@parameter::_withoutInit#element
            set multiWithInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithInit
              element: <testLibraryFragment>::@class::C::@setter::multiWithInit#element
              formalParameters
                _multiWithInit @-1
                  element: <testLibraryFragment>::@class::C::@setter::multiWithInit::@parameter::_multiWithInit#element
            set multiWithoutInit= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
              element: <testLibraryFragment>::@class::C::@setter::multiWithoutInit#element
              formalParameters
                _multiWithoutInit @-1
                  element: <testLibraryFragment>::@class::C::@setter::multiWithoutInit::@parameter::_multiWithoutInit#element
            set multiWithInit2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::multiWithInit2
              element: <testLibraryFragment>::@class::C::@setter::multiWithInit2#element
              formalParameters
                _multiWithInit2 @-1
                  element: <testLibraryFragment>::@class::C::@setter::multiWithInit2::@parameter::_multiWithInit2#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        withInit
          firstFragment: <testLibraryFragment>::@class::C::@field::withInit
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::withInit#element
          setter: <testLibraryFragment>::@class::C::@setter::withInit#element
        withoutInit
          firstFragment: <testLibraryFragment>::@class::C::@field::withoutInit
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::withoutInit#element
          setter: <testLibraryFragment>::@class::C::@setter::withoutInit#element
        multiWithInit
          firstFragment: <testLibraryFragment>::@class::C::@field::multiWithInit
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::multiWithInit#element
          setter: <testLibraryFragment>::@class::C::@setter::multiWithInit#element
        multiWithoutInit
          firstFragment: <testLibraryFragment>::@class::C::@field::multiWithoutInit
          type: int
          getter: <testLibraryFragment>::@class::C::@getter::multiWithoutInit#element
          setter: <testLibraryFragment>::@class::C::@setter::multiWithoutInit#element
        multiWithInit2
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
        synthetic set withInit=
          firstFragment: <testLibraryFragment>::@class::C::@setter::withInit
          formalParameters
            requiredPositional _withInit
              type: int
        synthetic set withoutInit=
          firstFragment: <testLibraryFragment>::@class::C::@setter::withoutInit
          formalParameters
            requiredPositional _withoutInit
              type: int
        synthetic set multiWithInit=
          firstFragment: <testLibraryFragment>::@class::C::@setter::multiWithInit
          formalParameters
            requiredPositional _multiWithInit
              type: int
        synthetic set multiWithoutInit=
          firstFragment: <testLibraryFragment>::@class::C::@setter::multiWithoutInit
          formalParameters
            requiredPositional _multiWithoutInit
              type: int
        synthetic set multiWithInit2=
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @91
                    rightParenthesis: ) @92
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @91
                    rightParenthesis: ) @92
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @141
                    rightParenthesis: ) @142
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @141
                    rightParenthesis: ) @142
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @275
                    rightParenthesis: ) @276
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @275
                    rightParenthesis: ) @276
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @358
                    rightParenthesis: ) @359
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @358
                    rightParenthesis: ) @359
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@class::C#element
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
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          getters
            get hasDocComment @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasDocComment
              element: <testLibraryFragment>::@class::C::@getter::hasDocComment#element
            get hasDocComment2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasDocComment2
              element: <testLibraryFragment>::@class::C::@getter::hasDocComment2#element
            get hasAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasAnnotation
              element: <testLibraryFragment>::@class::C::@getter::hasAnnotation#element
            get hasAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::hasAnnotation2
              element: <testLibraryFragment>::@class::C::@getter::hasAnnotation2#element
            get annotationThenComment @-1
              reference: <testLibraryFragment>::@class::C::@getter::annotationThenComment
              element: <testLibraryFragment>::@class::C::@getter::annotationThenComment#element
            get annotationThenComment2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::annotationThenComment2
              element: <testLibraryFragment>::@class::C::@getter::annotationThenComment2#element
            get commentThenAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation#element
            get commentThenAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2
              element: <testLibraryFragment>::@class::C::@getter::commentThenAnnotation2#element
            get commentAroundAnnotation @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation#element
            get commentAroundAnnotation2 @-1
              reference: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2
              element: <testLibraryFragment>::@class::C::@getter::commentAroundAnnotation2#element
          setters
            set hasDocComment= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasDocComment
              element: <testLibraryFragment>::@class::C::@setter::hasDocComment#element
              formalParameters
                _hasDocComment @-1
                  element: <testLibraryFragment>::@class::C::@setter::hasDocComment::@parameter::_hasDocComment#element
            set hasDocComment2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasDocComment2
              element: <testLibraryFragment>::@class::C::@setter::hasDocComment2#element
              formalParameters
                _hasDocComment2 @-1
                  element: <testLibraryFragment>::@class::C::@setter::hasDocComment2::@parameter::_hasDocComment2#element
            set hasAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasAnnotation
              element: <testLibraryFragment>::@class::C::@setter::hasAnnotation#element
              formalParameters
                _hasAnnotation @-1
                  element: <testLibraryFragment>::@class::C::@setter::hasAnnotation::@parameter::_hasAnnotation#element
            set hasAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
              element: <testLibraryFragment>::@class::C::@setter::hasAnnotation2#element
              formalParameters
                _hasAnnotation2 @-1
                  element: <testLibraryFragment>::@class::C::@setter::hasAnnotation2::@parameter::_hasAnnotation2#element
            set annotationThenComment= @-1
              reference: <testLibraryFragment>::@class::C::@setter::annotationThenComment
              element: <testLibraryFragment>::@class::C::@setter::annotationThenComment#element
              formalParameters
                _annotationThenComment @-1
                  element: <testLibraryFragment>::@class::C::@setter::annotationThenComment::@parameter::_annotationThenComment#element
            set annotationThenComment2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
              element: <testLibraryFragment>::@class::C::@setter::annotationThenComment2#element
              formalParameters
                _annotationThenComment2 @-1
                  element: <testLibraryFragment>::@class::C::@setter::annotationThenComment2::@parameter::_annotationThenComment2#element
            set commentThenAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
              element: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation#element
              formalParameters
                _commentThenAnnotation @-1
                  element: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation::@parameter::_commentThenAnnotation#element
            set commentThenAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
              element: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2#element
              formalParameters
                _commentThenAnnotation2 @-1
                  element: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2::@parameter::_commentThenAnnotation2#element
            set commentAroundAnnotation= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
              element: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation#element
              formalParameters
                _commentAroundAnnotation @-1
                  element: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation::@parameter::_commentAroundAnnotation#element
            set commentAroundAnnotation2= @-1
              reference: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2
              element: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2#element
              formalParameters
                _commentAroundAnnotation2 @-1
                  element: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation2::@parameter::_commentAroundAnnotation2#element
  classes
    class C
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
        synthetic set hasDocComment=
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasDocComment
          formalParameters
            requiredPositional _hasDocComment
              type: int
        synthetic set hasDocComment2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasDocComment2
          formalParameters
            requiredPositional _hasDocComment2
              type: int
        synthetic set hasAnnotation=
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasAnnotation
          formalParameters
            requiredPositional _hasAnnotation
              type: int
        synthetic set hasAnnotation2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::hasAnnotation2
          formalParameters
            requiredPositional _hasAnnotation2
              type: int
        synthetic set annotationThenComment=
          firstFragment: <testLibraryFragment>::@class::C::@setter::annotationThenComment
          formalParameters
            requiredPositional _annotationThenComment
              type: int
        synthetic set annotationThenComment2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::annotationThenComment2
          formalParameters
            requiredPositional _annotationThenComment2
              type: int
        synthetic set commentThenAnnotation=
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation
          formalParameters
            requiredPositional _commentThenAnnotation
              type: int
        synthetic set commentThenAnnotation2=
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentThenAnnotation2
          formalParameters
            requiredPositional _commentThenAnnotation2
              type: int
        synthetic set commentAroundAnnotation=
          firstFragment: <testLibraryFragment>::@class::C::@setter::commentAroundAnnotation
          formalParameters
            requiredPositional _commentAroundAnnotation
              type: int
        synthetic set commentAroundAnnotation2=
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @77
                rightParenthesis: ) @78
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @112
                rightParenthesis: ) @113
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @215
                rightParenthesis: ) @216
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @273
                rightParenthesis: ) @274
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@function::raw#element
        hasDocComment @50
          reference: <testLibraryFragment>::@function::hasDocComment
          element: <testLibraryFragment>::@function::hasDocComment#element
          documentationComment: /// Comment 1.\n/// Comment 2.
        hasAnnotation @85
          reference: <testLibraryFragment>::@function::hasAnnotation
          element: <testLibraryFragment>::@function::hasAnnotation#element
          metadata
            Annotation
              atSign: @ @70
              name: SimpleIdentifier
                token: Object @71
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @77
                rightParenthesis: ) @78
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        annotationThenComment @150
          reference: <testLibraryFragment>::@function::annotationThenComment
          element: <testLibraryFragment>::@function::annotationThenComment#element
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @105
              name: SimpleIdentifier
                token: Object @106
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @112
                rightParenthesis: ) @113
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentThenAnnotation @223
          reference: <testLibraryFragment>::@function::commentThenAnnotation
          element: <testLibraryFragment>::@function::commentThenAnnotation#element
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @208
              name: SimpleIdentifier
                token: Object @209
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @215
                rightParenthesis: ) @216
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentAroundAnnotation @296
          reference: <testLibraryFragment>::@function::commentAroundAnnotation
          element: <testLibraryFragment>::@function::commentAroundAnnotation#element
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @266
              name: SimpleIdentifier
                token: Object @267
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @273
                rightParenthesis: ) @274
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @77
            rightParenthesis: ) @78
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @112
            rightParenthesis: ) @113
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @215
            rightParenthesis: ) @216
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @273
            rightParenthesis: ) @274
          element: dart:core::<fragment>::@class::Object::@constructor::new
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @97
                    rightParenthesis: ) @98
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @136
                    rightParenthesis: ) @137
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @251
                    rightParenthesis: ) @252
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @315
                    rightParenthesis: ) @316
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
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
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @97
                    rightParenthesis: ) @98
                  element: dart:core::<fragment>::@class::Object::@constructor::new
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
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @136
                    rightParenthesis: ) @137
                  element: dart:core::<fragment>::@class::Object::@constructor::new
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
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @251
                    rightParenthesis: ) @252
                  element: dart:core::<fragment>::@class::Object::@constructor::new
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
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @315
                    rightParenthesis: ) @316
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
              codeOffset: 308
              codeLength: 62
  classes
    class C
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
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @97
                rightParenthesis: ) @98
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        annotationThenComment
          firstFragment: <testLibraryFragment>::@class::C::@method::annotationThenComment
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @129
              name: SimpleIdentifier
                token: Object @130
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @136
                rightParenthesis: ) @137
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentThenAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@method::commentThenAnnotation
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @244
              name: SimpleIdentifier
                token: Object @245
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @251
                rightParenthesis: ) @252
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
        commentAroundAnnotation
          firstFragment: <testLibraryFragment>::@class::C::@method::commentAroundAnnotation
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @308
              name: SimpleIdentifier
                token: Object @309
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @315
                rightParenthesis: ) @316
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
          element: <testLibraryFragment>::@function::main#element
          formalParameters
            default a @10
              reference: <testLibraryFragment>::@function::main::@parameter::a
              element: <testLibraryFragment>::@function::main::@parameter::a#element
            default b @21
              reference: <testLibraryFragment>::@function::main::@parameter::b
              element: <testLibraryFragment>::@function::main::@parameter::b#element
            default c @28
              reference: <testLibraryFragment>::@function::main::@parameter::c
              element: <testLibraryFragment>::@function::main::@parameter::c#element
  functions
    main
      firstFragment: <testLibraryFragment>::@function::main
      formalParameters
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @12
                    rightParenthesis: ) @13
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @36
                    rightParenthesis: ) @37
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@function::main#element
          formalParameters
            a @19
              element: <testLibraryFragment>::@function::main::@parameter::a#element
              metadata
                Annotation
                  atSign: @ @5
                  name: SimpleIdentifier
                    token: Object @6
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @12
                    rightParenthesis: ) @13
                  element: dart:core::<fragment>::@class::Object::@constructor::new
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
                    staticElement: dart:core::<fragment>::@class::Object
                    element: dart:core::<fragment>::@class::Object#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @36
                    rightParenthesis: ) @37
                  element: dart:core::<fragment>::@class::Object::@constructor::new
                  element2: dart:core::<fragment>::@class::Object::@constructor::new#element
  functions
    main
      firstFragment: <testLibraryFragment>::@function::main
      formalParameters
        requiredPositional a
          type: int
          metadata
            Annotation
              atSign: @ @5
              name: SimpleIdentifier
                token: Object @6
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @12
                rightParenthesis: ) @13
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @36
                rightParenthesis: ) @37
              element: dart:core::<fragment>::@class::Object::@constructor::new
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
          element: <testLibraryFragment>::@topLevelVariable::withInit#element
          getter2: <testLibraryFragment>::@getter::withInit
          setter2: <testLibraryFragment>::@setter::withInit
        withoutInit @31
          reference: <testLibraryFragment>::@topLevelVariable::withoutInit
          element: <testLibraryFragment>::@topLevelVariable::withoutInit#element
          getter2: <testLibraryFragment>::@getter::withoutInit
          setter2: <testLibraryFragment>::@setter::withoutInit
        multiWithInit @49
          reference: <testLibraryFragment>::@topLevelVariable::multiWithInit
          element: <testLibraryFragment>::@topLevelVariable::multiWithInit#element
          getter2: <testLibraryFragment>::@getter::multiWithInit
          setter2: <testLibraryFragment>::@setter::multiWithInit
        multiWithoutInit @68
          reference: <testLibraryFragment>::@topLevelVariable::multiWithoutInit
          element: <testLibraryFragment>::@topLevelVariable::multiWithoutInit#element
          getter2: <testLibraryFragment>::@getter::multiWithoutInit
          setter2: <testLibraryFragment>::@setter::multiWithoutInit
        multiWithInit2 @86
          reference: <testLibraryFragment>::@topLevelVariable::multiWithInit2
          element: <testLibraryFragment>::@topLevelVariable::multiWithInit2#element
          getter2: <testLibraryFragment>::@getter::multiWithInit2
          setter2: <testLibraryFragment>::@setter::multiWithInit2
      getters
        get withInit @-1
          reference: <testLibraryFragment>::@getter::withInit
          element: <testLibraryFragment>::@getter::withInit#element
        get withoutInit @-1
          reference: <testLibraryFragment>::@getter::withoutInit
          element: <testLibraryFragment>::@getter::withoutInit#element
        get multiWithInit @-1
          reference: <testLibraryFragment>::@getter::multiWithInit
          element: <testLibraryFragment>::@getter::multiWithInit#element
        get multiWithoutInit @-1
          reference: <testLibraryFragment>::@getter::multiWithoutInit
          element: <testLibraryFragment>::@getter::multiWithoutInit#element
        get multiWithInit2 @-1
          reference: <testLibraryFragment>::@getter::multiWithInit2
          element: <testLibraryFragment>::@getter::multiWithInit2#element
      setters
        set withInit= @-1
          reference: <testLibraryFragment>::@setter::withInit
          element: <testLibraryFragment>::@setter::withInit#element
          formalParameters
            _withInit @-1
              element: <testLibraryFragment>::@setter::withInit::@parameter::_withInit#element
        set withoutInit= @-1
          reference: <testLibraryFragment>::@setter::withoutInit
          element: <testLibraryFragment>::@setter::withoutInit#element
          formalParameters
            _withoutInit @-1
              element: <testLibraryFragment>::@setter::withoutInit::@parameter::_withoutInit#element
        set multiWithInit= @-1
          reference: <testLibraryFragment>::@setter::multiWithInit
          element: <testLibraryFragment>::@setter::multiWithInit#element
          formalParameters
            _multiWithInit @-1
              element: <testLibraryFragment>::@setter::multiWithInit::@parameter::_multiWithInit#element
        set multiWithoutInit= @-1
          reference: <testLibraryFragment>::@setter::multiWithoutInit
          element: <testLibraryFragment>::@setter::multiWithoutInit#element
          formalParameters
            _multiWithoutInit @-1
              element: <testLibraryFragment>::@setter::multiWithoutInit::@parameter::_multiWithoutInit#element
        set multiWithInit2= @-1
          reference: <testLibraryFragment>::@setter::multiWithInit2
          element: <testLibraryFragment>::@setter::multiWithInit2#element
          formalParameters
            _multiWithInit2 @-1
              element: <testLibraryFragment>::@setter::multiWithInit2::@parameter::_multiWithInit2#element
  topLevelVariables
    withInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::withInit
      type: int
      getter: <testLibraryFragment>::@getter::withInit#element
      setter: <testLibraryFragment>::@setter::withInit#element
    withoutInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::withoutInit
      type: int
      getter: <testLibraryFragment>::@getter::withoutInit#element
      setter: <testLibraryFragment>::@setter::withoutInit#element
    multiWithInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::multiWithInit
      type: int
      getter: <testLibraryFragment>::@getter::multiWithInit#element
      setter: <testLibraryFragment>::@setter::multiWithInit#element
    multiWithoutInit
      firstFragment: <testLibraryFragment>::@topLevelVariable::multiWithoutInit
      type: int
      getter: <testLibraryFragment>::@getter::multiWithoutInit#element
      setter: <testLibraryFragment>::@setter::multiWithoutInit#element
    multiWithInit2
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
    synthetic static set withInit=
      firstFragment: <testLibraryFragment>::@setter::withInit
      formalParameters
        requiredPositional _withInit
          type: int
    synthetic static set withoutInit=
      firstFragment: <testLibraryFragment>::@setter::withoutInit
      formalParameters
        requiredPositional _withoutInit
          type: int
    synthetic static set multiWithInit=
      firstFragment: <testLibraryFragment>::@setter::multiWithInit
      formalParameters
        requiredPositional _multiWithInit
          type: int
    synthetic static set multiWithoutInit=
      firstFragment: <testLibraryFragment>::@setter::multiWithoutInit
      formalParameters
        requiredPositional _multiWithoutInit
          type: int
    synthetic static set multiWithInit2=
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
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
          element: <testLibraryFragment>::@topLevelVariable::hasDocComment#element
          documentationComment: /// Comment 1.\n/// Comment 2.
          getter2: <testLibraryFragment>::@getter::hasDocComment
          setter2: <testLibraryFragment>::@setter::hasDocComment
        hasDocComment2 @49
          reference: <testLibraryFragment>::@topLevelVariable::hasDocComment2
          element: <testLibraryFragment>::@topLevelVariable::hasDocComment2#element
          documentationComment: /// Comment 1.\n/// Comment 2.
          getter2: <testLibraryFragment>::@getter::hasDocComment2
          setter2: <testLibraryFragment>::@setter::hasDocComment2
        hasAnnotation @80
          reference: <testLibraryFragment>::@topLevelVariable::hasAnnotation
          element: <testLibraryFragment>::@topLevelVariable::hasAnnotation#element
          metadata
            Annotation
              atSign: @ @66
              name: SimpleIdentifier
                token: Object @67
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::hasAnnotation
          setter2: <testLibraryFragment>::@setter::hasAnnotation
        hasAnnotation2 @95
          reference: <testLibraryFragment>::@topLevelVariable::hasAnnotation2
          element: <testLibraryFragment>::@topLevelVariable::hasAnnotation2#element
          metadata
            Annotation
              atSign: @ @66
              name: SimpleIdentifier
                token: Object @67
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @73
                rightParenthesis: ) @74
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::hasAnnotation2
          setter2: <testLibraryFragment>::@setter::hasAnnotation2
        annotationThenComment @156
          reference: <testLibraryFragment>::@topLevelVariable::annotationThenComment
          element: <testLibraryFragment>::@topLevelVariable::annotationThenComment#element
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @112
              name: SimpleIdentifier
                token: Object @113
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::annotationThenComment
          setter2: <testLibraryFragment>::@setter::annotationThenComment
        annotationThenComment2 @179
          reference: <testLibraryFragment>::@topLevelVariable::annotationThenComment2
          element: <testLibraryFragment>::@topLevelVariable::annotationThenComment2#element
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @112
              name: SimpleIdentifier
                token: Object @113
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @119
                rightParenthesis: ) @120
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::annotationThenComment2
          setter2: <testLibraryFragment>::@setter::annotationThenComment2
        commentThenAnnotation @248
          reference: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation
          element: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation#element
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @234
              name: SimpleIdentifier
                token: Object @235
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::commentThenAnnotation
          setter2: <testLibraryFragment>::@setter::commentThenAnnotation
        commentThenAnnotation2 @271
          reference: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation2
          element: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation2#element
          documentationComment: /// Comment 1.\n/// Comment 2.
          metadata
            Annotation
              atSign: @ @234
              name: SimpleIdentifier
                token: Object @235
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @241
                rightParenthesis: ) @242
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::commentThenAnnotation2
          setter2: <testLibraryFragment>::@setter::commentThenAnnotation2
        commentAroundAnnotation @340
          reference: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation
          element: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation#element
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @311
              name: SimpleIdentifier
                token: Object @312
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::commentAroundAnnotation
          setter2: <testLibraryFragment>::@setter::commentAroundAnnotation
        commentAroundAnnotation2 @365
          reference: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation2
          element: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation2#element
          documentationComment: /// Comment 2.
          metadata
            Annotation
              atSign: @ @311
              name: SimpleIdentifier
                token: Object @312
                staticElement: dart:core::<fragment>::@class::Object
                element: dart:core::<fragment>::@class::Object#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @318
                rightParenthesis: ) @319
              element: dart:core::<fragment>::@class::Object::@constructor::new
              element2: dart:core::<fragment>::@class::Object::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::commentAroundAnnotation2
          setter2: <testLibraryFragment>::@setter::commentAroundAnnotation2
      getters
        get hasDocComment @-1
          reference: <testLibraryFragment>::@getter::hasDocComment
          element: <testLibraryFragment>::@getter::hasDocComment#element
        get hasDocComment2 @-1
          reference: <testLibraryFragment>::@getter::hasDocComment2
          element: <testLibraryFragment>::@getter::hasDocComment2#element
        get hasAnnotation @-1
          reference: <testLibraryFragment>::@getter::hasAnnotation
          element: <testLibraryFragment>::@getter::hasAnnotation#element
        get hasAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::hasAnnotation2
          element: <testLibraryFragment>::@getter::hasAnnotation2#element
        get annotationThenComment @-1
          reference: <testLibraryFragment>::@getter::annotationThenComment
          element: <testLibraryFragment>::@getter::annotationThenComment#element
        get annotationThenComment2 @-1
          reference: <testLibraryFragment>::@getter::annotationThenComment2
          element: <testLibraryFragment>::@getter::annotationThenComment2#element
        get commentThenAnnotation @-1
          reference: <testLibraryFragment>::@getter::commentThenAnnotation
          element: <testLibraryFragment>::@getter::commentThenAnnotation#element
        get commentThenAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::commentThenAnnotation2
          element: <testLibraryFragment>::@getter::commentThenAnnotation2#element
        get commentAroundAnnotation @-1
          reference: <testLibraryFragment>::@getter::commentAroundAnnotation
          element: <testLibraryFragment>::@getter::commentAroundAnnotation#element
        get commentAroundAnnotation2 @-1
          reference: <testLibraryFragment>::@getter::commentAroundAnnotation2
          element: <testLibraryFragment>::@getter::commentAroundAnnotation2#element
      setters
        set hasDocComment= @-1
          reference: <testLibraryFragment>::@setter::hasDocComment
          element: <testLibraryFragment>::@setter::hasDocComment#element
          formalParameters
            _hasDocComment @-1
              element: <testLibraryFragment>::@setter::hasDocComment::@parameter::_hasDocComment#element
        set hasDocComment2= @-1
          reference: <testLibraryFragment>::@setter::hasDocComment2
          element: <testLibraryFragment>::@setter::hasDocComment2#element
          formalParameters
            _hasDocComment2 @-1
              element: <testLibraryFragment>::@setter::hasDocComment2::@parameter::_hasDocComment2#element
        set hasAnnotation= @-1
          reference: <testLibraryFragment>::@setter::hasAnnotation
          element: <testLibraryFragment>::@setter::hasAnnotation#element
          formalParameters
            _hasAnnotation @-1
              element: <testLibraryFragment>::@setter::hasAnnotation::@parameter::_hasAnnotation#element
        set hasAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::hasAnnotation2
          element: <testLibraryFragment>::@setter::hasAnnotation2#element
          formalParameters
            _hasAnnotation2 @-1
              element: <testLibraryFragment>::@setter::hasAnnotation2::@parameter::_hasAnnotation2#element
        set annotationThenComment= @-1
          reference: <testLibraryFragment>::@setter::annotationThenComment
          element: <testLibraryFragment>::@setter::annotationThenComment#element
          formalParameters
            _annotationThenComment @-1
              element: <testLibraryFragment>::@setter::annotationThenComment::@parameter::_annotationThenComment#element
        set annotationThenComment2= @-1
          reference: <testLibraryFragment>::@setter::annotationThenComment2
          element: <testLibraryFragment>::@setter::annotationThenComment2#element
          formalParameters
            _annotationThenComment2 @-1
              element: <testLibraryFragment>::@setter::annotationThenComment2::@parameter::_annotationThenComment2#element
        set commentThenAnnotation= @-1
          reference: <testLibraryFragment>::@setter::commentThenAnnotation
          element: <testLibraryFragment>::@setter::commentThenAnnotation#element
          formalParameters
            _commentThenAnnotation @-1
              element: <testLibraryFragment>::@setter::commentThenAnnotation::@parameter::_commentThenAnnotation#element
        set commentThenAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::commentThenAnnotation2
          element: <testLibraryFragment>::@setter::commentThenAnnotation2#element
          formalParameters
            _commentThenAnnotation2 @-1
              element: <testLibraryFragment>::@setter::commentThenAnnotation2::@parameter::_commentThenAnnotation2#element
        set commentAroundAnnotation= @-1
          reference: <testLibraryFragment>::@setter::commentAroundAnnotation
          element: <testLibraryFragment>::@setter::commentAroundAnnotation#element
          formalParameters
            _commentAroundAnnotation @-1
              element: <testLibraryFragment>::@setter::commentAroundAnnotation::@parameter::_commentAroundAnnotation#element
        set commentAroundAnnotation2= @-1
          reference: <testLibraryFragment>::@setter::commentAroundAnnotation2
          element: <testLibraryFragment>::@setter::commentAroundAnnotation2#element
          formalParameters
            _commentAroundAnnotation2 @-1
              element: <testLibraryFragment>::@setter::commentAroundAnnotation2::@parameter::_commentAroundAnnotation2#element
  topLevelVariables
    hasDocComment
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasDocComment
      type: int
      getter: <testLibraryFragment>::@getter::hasDocComment#element
      setter: <testLibraryFragment>::@setter::hasDocComment#element
    hasDocComment2
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasDocComment2
      type: int
      getter: <testLibraryFragment>::@getter::hasDocComment2#element
      setter: <testLibraryFragment>::@setter::hasDocComment2#element
    hasAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasAnnotation
      metadata
        Annotation
          atSign: @ @66
          name: SimpleIdentifier
            token: Object @67
            staticElement: dart:core::<fragment>::@class::Object
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @73
            rightParenthesis: ) @74
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::hasAnnotation#element
      setter: <testLibraryFragment>::@setter::hasAnnotation#element
    hasAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::hasAnnotation2
      metadata
        Annotation
          atSign: @ @66
          name: SimpleIdentifier
            token: Object @67
            staticElement: dart:core::<fragment>::@class::Object
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @73
            rightParenthesis: ) @74
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::hasAnnotation2#element
      setter: <testLibraryFragment>::@setter::hasAnnotation2#element
    annotationThenComment
      firstFragment: <testLibraryFragment>::@topLevelVariable::annotationThenComment
      metadata
        Annotation
          atSign: @ @112
          name: SimpleIdentifier
            token: Object @113
            staticElement: dart:core::<fragment>::@class::Object
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @119
            rightParenthesis: ) @120
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::annotationThenComment#element
      setter: <testLibraryFragment>::@setter::annotationThenComment#element
    annotationThenComment2
      firstFragment: <testLibraryFragment>::@topLevelVariable::annotationThenComment2
      metadata
        Annotation
          atSign: @ @112
          name: SimpleIdentifier
            token: Object @113
            staticElement: dart:core::<fragment>::@class::Object
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @119
            rightParenthesis: ) @120
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::annotationThenComment2#element
      setter: <testLibraryFragment>::@setter::annotationThenComment2#element
    commentThenAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation
      metadata
        Annotation
          atSign: @ @234
          name: SimpleIdentifier
            token: Object @235
            staticElement: dart:core::<fragment>::@class::Object
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @241
            rightParenthesis: ) @242
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::commentThenAnnotation#element
      setter: <testLibraryFragment>::@setter::commentThenAnnotation#element
    commentThenAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentThenAnnotation2
      metadata
        Annotation
          atSign: @ @234
          name: SimpleIdentifier
            token: Object @235
            staticElement: dart:core::<fragment>::@class::Object
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @241
            rightParenthesis: ) @242
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::commentThenAnnotation2#element
      setter: <testLibraryFragment>::@setter::commentThenAnnotation2#element
    commentAroundAnnotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation
      metadata
        Annotation
          atSign: @ @311
          name: SimpleIdentifier
            token: Object @312
            staticElement: dart:core::<fragment>::@class::Object
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @318
            rightParenthesis: ) @319
          element: dart:core::<fragment>::@class::Object::@constructor::new
          element2: dart:core::<fragment>::@class::Object::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::commentAroundAnnotation#element
      setter: <testLibraryFragment>::@setter::commentAroundAnnotation#element
    commentAroundAnnotation2
      firstFragment: <testLibraryFragment>::@topLevelVariable::commentAroundAnnotation2
      metadata
        Annotation
          atSign: @ @311
          name: SimpleIdentifier
            token: Object @312
            staticElement: dart:core::<fragment>::@class::Object
            element: dart:core::<fragment>::@class::Object#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @318
            rightParenthesis: ) @319
          element: dart:core::<fragment>::@class::Object::@constructor::new
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
    synthetic static set hasDocComment=
      firstFragment: <testLibraryFragment>::@setter::hasDocComment
      formalParameters
        requiredPositional _hasDocComment
          type: int
    synthetic static set hasDocComment2=
      firstFragment: <testLibraryFragment>::@setter::hasDocComment2
      formalParameters
        requiredPositional _hasDocComment2
          type: int
    synthetic static set hasAnnotation=
      firstFragment: <testLibraryFragment>::@setter::hasAnnotation
      formalParameters
        requiredPositional _hasAnnotation
          type: int
    synthetic static set hasAnnotation2=
      firstFragment: <testLibraryFragment>::@setter::hasAnnotation2
      formalParameters
        requiredPositional _hasAnnotation2
          type: int
    synthetic static set annotationThenComment=
      firstFragment: <testLibraryFragment>::@setter::annotationThenComment
      formalParameters
        requiredPositional _annotationThenComment
          type: int
    synthetic static set annotationThenComment2=
      firstFragment: <testLibraryFragment>::@setter::annotationThenComment2
      formalParameters
        requiredPositional _annotationThenComment2
          type: int
    synthetic static set commentThenAnnotation=
      firstFragment: <testLibraryFragment>::@setter::commentThenAnnotation
      formalParameters
        requiredPositional _commentThenAnnotation
          type: int
    synthetic static set commentThenAnnotation2=
      firstFragment: <testLibraryFragment>::@setter::commentThenAnnotation2
      formalParameters
        requiredPositional _commentThenAnnotation2
          type: int
    synthetic static set commentAroundAnnotation=
      firstFragment: <testLibraryFragment>::@setter::commentAroundAnnotation
      formalParameters
        requiredPositional _commentAroundAnnotation
          type: int
    synthetic static set commentAroundAnnotation2=
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
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      functions
        f @19
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          typeParameters
            U @21
              element: <not-implemented>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  functions
    f
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            new @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
            named @21
              reference: <testLibraryFragment>::@class::A::@constructor::named
              element: <testLibraryFragment>::@class::A::@constructor::named#element
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            new @12
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                a @18
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
  classes
    class A
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
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @16
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
              setter2: <testLibraryFragment>::@class::A::@setter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo
              element: <testLibraryFragment>::@class::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        foo
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
        synthetic set foo=
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
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @-1
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          getters
            get foo @20
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
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
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          methods
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
              typeParameters
                T @21
                  element: <not-implemented>
              formalParameters
                a @28
                  element: <testLibraryFragment>::@class::A::@method::foo::@parameter::a#element
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
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @-1
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              setter2: <testLibraryFragment>::@class::A::@setter::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          setters
            set foo= @16
              reference: <testLibraryFragment>::@class::A::@setter::foo
              element: <testLibraryFragment>::@class::A::@setter::foo#element
              formalParameters
                x @24
                  element: <testLibraryFragment>::@class::A::@setter::foo::@parameter::x#element
  classes
    class A
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
        set foo=
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
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
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
          element: <testLibraryFragment>::@extension::E#element
          typeParameters
            T @12
              element: <not-implemented>
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
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            f @12
              element: <testLibraryFragment>::@function::f::@parameter::f#element
  functions
    f
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
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            default f @22
              reference: <testLibraryFragment>::@function::f::@parameter::f
              element: <testLibraryFragment>::@function::f::@parameter::f#element
  functions
    f
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
          element: <testLibraryFragment>::@function::f#element
          typeParameters
            T @7
              element: <not-implemented>
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
          element: <testLibraryFragment>::@typeAlias::F#element
          typeParameters
            T @15
              element: <not-implemented>
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
          element: <testLibraryFragment>::@typeAlias::F#element
          typeParameters
            T @10
              element: <not-implemented>
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
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @8
              element: <not-implemented>
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
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @8
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    synthetic foo
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
