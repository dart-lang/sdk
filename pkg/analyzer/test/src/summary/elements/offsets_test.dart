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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class Raw (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::Raw
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::Raw::@constructor::new
              typeName: Raw
        #F3 class HasDocComment (nameOffset:50) (firstTokenOffset:14) (offset:50)
          element: <testLibrary>::@class::HasDocComment
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::HasDocComment::@constructor::new
              typeName: HasDocComment
        #F5 class HasAnnotation (nameOffset:84) (firstTokenOffset:68) (offset:84)
          element: <testLibrary>::@class::HasAnnotation
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:84)
              element: <testLibrary>::@class::HasAnnotation::@constructor::new
              typeName: HasAnnotation
        #F7 class AnnotationThenComment (nameOffset:148) (firstTokenOffset:102) (offset:148)
          element: <testLibrary>::@class::AnnotationThenComment
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:148)
              element: <testLibrary>::@class::AnnotationThenComment::@constructor::new
              typeName: AnnotationThenComment
        #F9 class CommentThenAnnotation (nameOffset:220) (firstTokenOffset:174) (offset:220)
          element: <testLibrary>::@class::CommentThenAnnotation
          constructors
            #F10 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:220)
              element: <testLibrary>::@class::CommentThenAnnotation::@constructor::new
              typeName: CommentThenAnnotation
        #F11 class CommentAroundAnnotation (nameOffset:292) (firstTokenOffset:261) (offset:292)
          element: <testLibrary>::@class::CommentAroundAnnotation
          constructors
            #F12 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:292)
              element: <testLibrary>::@class::CommentAroundAnnotation::@constructor::new
              typeName: CommentAroundAnnotation
  classes
    class Raw
      reference: <testLibrary>::@class::Raw
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::Raw::@constructor::new
          firstFragment: #F2
    class HasDocComment
      reference: <testLibrary>::@class::HasDocComment
      firstFragment: #F3
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          reference: <testLibrary>::@class::HasDocComment::@constructor::new
          firstFragment: #F4
    class HasAnnotation
      reference: <testLibrary>::@class::HasAnnotation
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::HasAnnotation::@constructor::new
          firstFragment: #F6
    class AnnotationThenComment
      reference: <testLibrary>::@class::AnnotationThenComment
      firstFragment: #F7
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          reference: <testLibrary>::@class::AnnotationThenComment::@constructor::new
          firstFragment: #F8
    class CommentThenAnnotation
      reference: <testLibrary>::@class::CommentThenAnnotation
      firstFragment: #F9
      documentationComment: /// Comment 1.\n/// Comment 2.
      constructors
        synthetic new
          reference: <testLibrary>::@class::CommentThenAnnotation::@constructor::new
          firstFragment: #F10
    class CommentAroundAnnotation
      reference: <testLibrary>::@class::CommentAroundAnnotation
      firstFragment: #F11
      documentationComment: /// Comment 2.
      constructors
        synthetic new
          reference: <testLibrary>::@class::CommentAroundAnnotation::@constructor::new
          firstFragment: #F12
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class Raw (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::Raw
          constructors
            #F6 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::Raw::@constructor::new
              typeName: Raw
        #F7 class HasDocComment (nameOffset:91) (firstTokenOffset:55) (offset:91)
          element: <testLibrary>::@class::HasDocComment
          constructors
            #F8 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
              element: <testLibrary>::@class::HasDocComment::@constructor::new
              typeName: HasDocComment
        #F9 class HasAnnotation (nameOffset:142) (firstTokenOffset:126) (offset:142)
          element: <testLibrary>::@class::HasAnnotation
          constructors
            #F10 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:142)
              element: <testLibrary>::@class::HasAnnotation::@constructor::new
              typeName: HasAnnotation
        #F11 class AnnotationThenComment (nameOffset:223) (firstTokenOffset:177) (offset:223)
          element: <testLibrary>::@class::AnnotationThenComment
          constructors
            #F12 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:223)
              element: <testLibrary>::@class::AnnotationThenComment::@constructor::new
              typeName: AnnotationThenComment
        #F13 class CommentThenAnnotation (nameOffset:312) (firstTokenOffset:266) (offset:312)
          element: <testLibrary>::@class::CommentThenAnnotation
          constructors
            #F14 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:312)
              element: <testLibrary>::@class::CommentThenAnnotation::@constructor::new
              typeName: CommentThenAnnotation
        #F15 class CommentAroundAnnotation (nameOffset:401) (firstTokenOffset:370) (offset:401)
          element: <testLibrary>::@class::CommentAroundAnnotation
          constructors
            #F16 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:401)
              element: <testLibrary>::@class::CommentAroundAnnotation::@constructor::new
              typeName: CommentAroundAnnotation
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
    class alias Raw
      reference: <testLibrary>::@class::Raw
      firstFragment: #F5
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          reference: <testLibrary>::@class::Raw::@constructor::new
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
    class alias HasDocComment
      reference: <testLibrary>::@class::HasDocComment
      firstFragment: #F7
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          reference: <testLibrary>::@class::HasDocComment::@constructor::new
          firstFragment: #F8
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
    class alias HasAnnotation
      reference: <testLibrary>::@class::HasAnnotation
      firstFragment: #F9
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          reference: <testLibrary>::@class::HasAnnotation::@constructor::new
          firstFragment: #F10
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
    class alias AnnotationThenComment
      reference: <testLibrary>::@class::AnnotationThenComment
      firstFragment: #F11
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          reference: <testLibrary>::@class::AnnotationThenComment::@constructor::new
          firstFragment: #F12
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
    class alias CommentThenAnnotation
      reference: <testLibrary>::@class::CommentThenAnnotation
      firstFragment: #F13
      documentationComment: /// Comment 1.\n/// Comment 2.
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          reference: <testLibrary>::@class::CommentThenAnnotation::@constructor::new
          firstFragment: #F14
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
    class alias CommentAroundAnnotation
      reference: <testLibrary>::@class::CommentAroundAnnotation
      firstFragment: #F15
      documentationComment: /// Comment 2.
      supertype: Object
      mixins
        A
        B
      constructors
        synthetic const new
          reference: <testLibrary>::@class::CommentAroundAnnotation::@constructor::new
          firstFragment: #F16
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              codeOffset: 12
              codeLength: 4
              typeName: C
              typeNameOffset: 12
            #F3 raw (nameOffset:22) (firstTokenOffset:20) (offset:22)
              element: <testLibrary>::@class::C::@constructor::raw
              codeOffset: 20
              codeLength: 10
              typeName: C
              typeNameOffset: 20
              periodOffset: 21
            #F4 hasDocComment (nameOffset:70) (firstTokenOffset:34) (offset:70)
              element: <testLibrary>::@class::C::@constructor::hasDocComment
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 34
              codeLength: 54
              typeName: C
              typeNameOffset: 68
              periodOffset: 69
            #F5 hasAnnotation (nameOffset:106) (firstTokenOffset:92) (offset:106)
              element: <testLibrary>::@class::C::@constructor::hasAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 92
              codeLength: 32
              typeName: C
              typeNameOffset: 104
              periodOffset: 105
            #F6 annotationThenComment (nameOffset:176) (firstTokenOffset:128) (offset:176)
              element: <testLibrary>::@class::C::@constructor::annotationThenComment
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 128
              codeLength: 74
              typeName: C
              typeNameOffset: 174
              periodOffset: 175
            #F7 commentThenAnnotation (nameOffset:254) (firstTokenOffset:206) (offset:254)
              element: <testLibrary>::@class::C::@constructor::commentThenAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 206
              codeLength: 74
              typeName: C
              typeNameOffset: 252
              periodOffset: 253
            #F8 commentAroundAnnotation (nameOffset:332) (firstTokenOffset:301) (offset:332)
              element: <testLibrary>::@class::C::@constructor::commentAroundAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 301
              codeLength: 59
              typeName: C
              typeNameOffset: 330
              periodOffset: 331
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
        raw
          reference: <testLibrary>::@class::C::@constructor::raw
          firstFragment: #F3
        hasDocComment
          reference: <testLibrary>::@class::C::@constructor::hasDocComment
          firstFragment: #F4
          documentationComment: /// Comment 1.\n/// Comment 2.
        hasAnnotation
          reference: <testLibrary>::@class::C::@constructor::hasAnnotation
          firstFragment: #F5
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
              element2: dart:core::@class::Object::@constructor::new
        annotationThenComment
          reference: <testLibrary>::@class::C::@constructor::annotationThenComment
          firstFragment: #F6
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
              element2: dart:core::@class::Object::@constructor::new
        commentThenAnnotation
          reference: <testLibrary>::@class::C::@constructor::commentThenAnnotation
          firstFragment: #F7
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
              element2: dart:core::@class::Object::@constructor::new
        commentAroundAnnotation
          reference: <testLibrary>::@class::C::@constructor::commentAroundAnnotation
          firstFragment: #F8
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
              element2: dart:core::@class::Object::@constructor::new
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 factory new (nameOffset:<null>) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::C::@constructor::new
              codeOffset: 12
              codeLength: 23
              typeName: C
              typeNameOffset: 20
            #F3 factory raw (nameOffset:49) (firstTokenOffset:39) (offset:49)
              element: <testLibrary>::@class::C::@constructor::raw
              codeOffset: 39
              codeLength: 27
              typeName: C
              typeNameOffset: 47
              periodOffset: 48
            #F4 factory hasDocComment (nameOffset:114) (firstTokenOffset:70) (offset:114)
              element: <testLibrary>::@class::C::@constructor::hasDocComment
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 70
              codeLength: 71
              typeName: C
              typeNameOffset: 112
              periodOffset: 113
            #F5 factory hasAnnotation (nameOffset:167) (firstTokenOffset:145) (offset:167)
              element: <testLibrary>::@class::C::@constructor::hasAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 145
              codeLength: 49
              typeName: C
              typeNameOffset: 165
              periodOffset: 166
            #F6 factory annotationThenComment (nameOffset:254) (firstTokenOffset:198) (offset:254)
              element: <testLibrary>::@class::C::@constructor::annotationThenComment
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 198
              codeLength: 91
              typeName: C
              typeNameOffset: 252
              periodOffset: 253
            #F7 factory commentThenAnnotation (nameOffset:349) (firstTokenOffset:293) (offset:349)
              element: <testLibrary>::@class::C::@constructor::commentThenAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 293
              codeLength: 91
              typeName: C
              typeNameOffset: 347
              periodOffset: 348
            #F8 factory commentAroundAnnotation (nameOffset:444) (firstTokenOffset:405) (offset:444)
              element: <testLibrary>::@class::C::@constructor::commentAroundAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 405
              codeLength: 76
              typeName: C
              typeNameOffset: 442
              periodOffset: 443
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
        factory raw
          reference: <testLibrary>::@class::C::@constructor::raw
          firstFragment: #F3
        factory hasDocComment
          reference: <testLibrary>::@class::C::@constructor::hasDocComment
          firstFragment: #F4
          documentationComment: /// Comment 1.\n/// Comment 2.
        factory hasAnnotation
          reference: <testLibrary>::@class::C::@constructor::hasAnnotation
          firstFragment: #F5
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
              element2: dart:core::@class::Object::@constructor::new
        factory annotationThenComment
          reference: <testLibrary>::@class::C::@constructor::annotationThenComment
          firstFragment: #F6
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
              element2: dart:core::@class::Object::@constructor::new
        factory commentThenAnnotation
          reference: <testLibrary>::@class::C::@constructor::commentThenAnnotation
          firstFragment: #F7
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
              element2: dart:core::@class::Object::@constructor::new
        factory commentAroundAnnotation
          reference: <testLibrary>::@class::C::@constructor::commentAroundAnnotation
          firstFragment: #F8
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
              element2: dart:core::@class::Object::@constructor::new
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        #F3 extension Raw (nameOffset:22) (firstTokenOffset:12) (offset:22)
          element: <testLibrary>::@extension::Raw
        #F4 extension HasDocComment (nameOffset:75) (firstTokenOffset:35) (offset:75)
          element: <testLibrary>::@extension::HasDocComment
        #F5 extension HasAnnotation (nameOffset:118) (firstTokenOffset:98) (offset:118)
          element: <testLibrary>::@extension::HasAnnotation
        #F6 extension AnnotationThenComment (nameOffset:191) (firstTokenOffset:141) (offset:191)
          element: <testLibrary>::@extension::AnnotationThenComment
        #F7 extension CommentThenAnnotation (nameOffset:272) (firstTokenOffset:222) (offset:272)
          element: <testLibrary>::@extension::CommentThenAnnotation
        #F8 extension CommentAroundAnnotation (nameOffset:353) (firstTokenOffset:318) (offset:353)
          element: <testLibrary>::@extension::CommentAroundAnnotation
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  extensions
    extension Raw
      reference: <testLibrary>::@extension::Raw
      firstFragment: #F3
      extendedType: A
    extension HasDocComment
      reference: <testLibrary>::@extension::HasDocComment
      firstFragment: #F4
      documentationComment: /// Comment 1.\n/// Comment 2.
      extendedType: A
    extension HasAnnotation
      reference: <testLibrary>::@extension::HasAnnotation
      firstFragment: #F5
      extendedType: A
    extension AnnotationThenComment
      reference: <testLibrary>::@extension::AnnotationThenComment
      firstFragment: #F6
      documentationComment: /// Comment 1.\n/// Comment 2.
      extendedType: A
    extension CommentThenAnnotation
      reference: <testLibrary>::@extension::CommentThenAnnotation
      firstFragment: #F7
      documentationComment: /// Comment 1.\n/// Comment 2.
      extendedType: A
    extension CommentAroundAnnotation
      reference: <testLibrary>::@extension::CommentAroundAnnotation
      firstFragment: #F8
      documentationComment: /// Comment 2.
      extendedType: A
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 hasInitializer withInit (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::withInit
            #F3 withoutInit (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@class::C::@field::withoutInit
            #F4 hasInitializer multiWithInit (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: <testLibrary>::@class::C::@field::multiWithInit
            #F5 multiWithoutInit (nameOffset:76) (firstTokenOffset:76) (offset:76)
              element: <testLibrary>::@class::C::@field::multiWithoutInit
            #F6 hasInitializer multiWithInit2 (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::C::@field::multiWithInit2
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F8 synthetic withInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::withInit
            #F9 synthetic withoutInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@getter::withoutInit
            #F10 synthetic multiWithInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@getter::multiWithInit
            #F11 synthetic multiWithoutInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@class::C::@getter::multiWithoutInit
            #F12 synthetic multiWithInit2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::C::@getter::multiWithInit2
          setters
            #F13 synthetic withInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::withInit
              formalParameters
                #F14 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::withInit::@formalParameter::value
            #F15 synthetic withoutInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@setter::withoutInit
              formalParameters
                #F16 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
                  element: <testLibrary>::@class::C::@setter::withoutInit::@formalParameter::value
            #F17 synthetic multiWithInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@setter::multiWithInit
              formalParameters
                #F18 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
                  element: <testLibrary>::@class::C::@setter::multiWithInit::@formalParameter::value
            #F19 synthetic multiWithoutInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@class::C::@setter::multiWithoutInit
              formalParameters
                #F20 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
                  element: <testLibrary>::@class::C::@setter::multiWithoutInit::@formalParameter::value
            #F21 synthetic multiWithInit2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
              element: <testLibrary>::@class::C::@setter::multiWithInit2
              formalParameters
                #F22 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:94)
                  element: <testLibrary>::@class::C::@setter::multiWithInit2::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasInitializer withInit
          reference: <testLibrary>::@class::C::@field::withInit
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::withInit
          setter: <testLibrary>::@class::C::@setter::withInit
        withoutInit
          reference: <testLibrary>::@class::C::@field::withoutInit
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::C::@getter::withoutInit
          setter: <testLibrary>::@class::C::@setter::withoutInit
        hasInitializer multiWithInit
          reference: <testLibrary>::@class::C::@field::multiWithInit
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::C::@getter::multiWithInit
          setter: <testLibrary>::@class::C::@setter::multiWithInit
        multiWithoutInit
          reference: <testLibrary>::@class::C::@field::multiWithoutInit
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::C::@getter::multiWithoutInit
          setter: <testLibrary>::@class::C::@setter::multiWithoutInit
        hasInitializer multiWithInit2
          reference: <testLibrary>::@class::C::@field::multiWithInit2
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::C::@getter::multiWithInit2
          setter: <testLibrary>::@class::C::@setter::multiWithInit2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F7
      getters
        synthetic withInit
          reference: <testLibrary>::@class::C::@getter::withInit
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@class::C::@field::withInit
        synthetic withoutInit
          reference: <testLibrary>::@class::C::@getter::withoutInit
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@class::C::@field::withoutInit
        synthetic multiWithInit
          reference: <testLibrary>::@class::C::@getter::multiWithInit
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@class::C::@field::multiWithInit
        synthetic multiWithoutInit
          reference: <testLibrary>::@class::C::@getter::multiWithoutInit
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::C::@field::multiWithoutInit
        synthetic multiWithInit2
          reference: <testLibrary>::@class::C::@getter::multiWithInit2
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@class::C::@field::multiWithInit2
      setters
        synthetic withInit
          reference: <testLibrary>::@class::C::@setter::withInit
          firstFragment: #F13
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::withInit
        synthetic withoutInit
          reference: <testLibrary>::@class::C::@setter::withoutInit
          firstFragment: #F15
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F16
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::withoutInit
        synthetic multiWithInit
          reference: <testLibrary>::@class::C::@setter::multiWithInit
          firstFragment: #F17
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F18
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::multiWithInit
        synthetic multiWithoutInit
          reference: <testLibrary>::@class::C::@setter::multiWithoutInit
          firstFragment: #F19
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F20
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::multiWithoutInit
        synthetic multiWithInit2
          reference: <testLibrary>::@class::C::@setter::multiWithInit2
          firstFragment: #F21
          formalParameters
            #E4 requiredPositional value
              firstFragment: #F22
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::multiWithInit2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 hasDocComment (nameOffset:50) (firstTokenOffset:50) (offset:50)
              element: <testLibrary>::@class::C::@field::hasDocComment
            #F3 hasDocComment2 (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: <testLibrary>::@class::C::@field::hasDocComment2
            #F4 hasAnnotation (nameOffset:100) (firstTokenOffset:100) (offset:100)
              element: <testLibrary>::@class::C::@field::hasAnnotation
            #F5 hasAnnotation2 (nameOffset:115) (firstTokenOffset:115) (offset:115)
              element: <testLibrary>::@class::C::@field::hasAnnotation2
            #F6 annotationThenComment (nameOffset:184) (firstTokenOffset:184) (offset:184)
              element: <testLibrary>::@class::C::@field::annotationThenComment
            #F7 annotationThenComment2 (nameOffset:207) (firstTokenOffset:207) (offset:207)
              element: <testLibrary>::@class::C::@field::annotationThenComment2
            #F8 commentThenAnnotation (nameOffset:284) (firstTokenOffset:284) (offset:284)
              element: <testLibrary>::@class::C::@field::commentThenAnnotation
            #F9 commentThenAnnotation2 (nameOffset:307) (firstTokenOffset:307) (offset:307)
              element: <testLibrary>::@class::C::@field::commentThenAnnotation2
            #F10 commentAroundAnnotation (nameOffset:384) (firstTokenOffset:384) (offset:384)
              element: <testLibrary>::@class::C::@field::commentAroundAnnotation
            #F11 commentAroundAnnotation2 (nameOffset:409) (firstTokenOffset:409) (offset:409)
              element: <testLibrary>::@class::C::@field::commentAroundAnnotation2
          constructors
            #F12 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F13 synthetic hasDocComment (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@getter::hasDocComment
            #F14 synthetic hasDocComment2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@class::C::@getter::hasDocComment2
            #F15 synthetic hasAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:100)
              element: <testLibrary>::@class::C::@getter::hasAnnotation
            #F16 synthetic hasAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:115)
              element: <testLibrary>::@class::C::@getter::hasAnnotation2
            #F17 synthetic annotationThenComment (nameOffset:<null>) (firstTokenOffset:<null>) (offset:184)
              element: <testLibrary>::@class::C::@getter::annotationThenComment
            #F18 synthetic annotationThenComment2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:207)
              element: <testLibrary>::@class::C::@getter::annotationThenComment2
            #F19 synthetic commentThenAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
              element: <testLibrary>::@class::C::@getter::commentThenAnnotation
            #F20 synthetic commentThenAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:307)
              element: <testLibrary>::@class::C::@getter::commentThenAnnotation2
            #F21 synthetic commentAroundAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:384)
              element: <testLibrary>::@class::C::@getter::commentAroundAnnotation
            #F22 synthetic commentAroundAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:409)
              element: <testLibrary>::@class::C::@getter::commentAroundAnnotation2
          setters
            #F23 synthetic hasDocComment (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::C::@setter::hasDocComment
              formalParameters
                #F24 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
                  element: <testLibrary>::@class::C::@setter::hasDocComment::@formalParameter::value
            #F25 synthetic hasDocComment2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@class::C::@setter::hasDocComment2
              formalParameters
                #F26 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
                  element: <testLibrary>::@class::C::@setter::hasDocComment2::@formalParameter::value
            #F27 synthetic hasAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:100)
              element: <testLibrary>::@class::C::@setter::hasAnnotation
              formalParameters
                #F28 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:100)
                  element: <testLibrary>::@class::C::@setter::hasAnnotation::@formalParameter::value
            #F29 synthetic hasAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:115)
              element: <testLibrary>::@class::C::@setter::hasAnnotation2
              formalParameters
                #F30 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:115)
                  element: <testLibrary>::@class::C::@setter::hasAnnotation2::@formalParameter::value
            #F31 synthetic annotationThenComment (nameOffset:<null>) (firstTokenOffset:<null>) (offset:184)
              element: <testLibrary>::@class::C::@setter::annotationThenComment
              formalParameters
                #F32 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:184)
                  element: <testLibrary>::@class::C::@setter::annotationThenComment::@formalParameter::value
            #F33 synthetic annotationThenComment2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:207)
              element: <testLibrary>::@class::C::@setter::annotationThenComment2
              formalParameters
                #F34 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:207)
                  element: <testLibrary>::@class::C::@setter::annotationThenComment2::@formalParameter::value
            #F35 synthetic commentThenAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
              element: <testLibrary>::@class::C::@setter::commentThenAnnotation
              formalParameters
                #F36 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:284)
                  element: <testLibrary>::@class::C::@setter::commentThenAnnotation::@formalParameter::value
            #F37 synthetic commentThenAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:307)
              element: <testLibrary>::@class::C::@setter::commentThenAnnotation2
              formalParameters
                #F38 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:307)
                  element: <testLibrary>::@class::C::@setter::commentThenAnnotation2::@formalParameter::value
            #F39 synthetic commentAroundAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:384)
              element: <testLibrary>::@class::C::@setter::commentAroundAnnotation
              formalParameters
                #F40 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:384)
                  element: <testLibrary>::@class::C::@setter::commentAroundAnnotation::@formalParameter::value
            #F41 synthetic commentAroundAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:409)
              element: <testLibrary>::@class::C::@setter::commentAroundAnnotation2
              formalParameters
                #F42 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:409)
                  element: <testLibrary>::@class::C::@setter::commentAroundAnnotation2::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        hasDocComment
          reference: <testLibrary>::@class::C::@field::hasDocComment
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::hasDocComment
          setter: <testLibrary>::@class::C::@setter::hasDocComment
        hasDocComment2
          reference: <testLibrary>::@class::C::@field::hasDocComment2
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::C::@getter::hasDocComment2
          setter: <testLibrary>::@class::C::@setter::hasDocComment2
        hasAnnotation
          reference: <testLibrary>::@class::C::@field::hasAnnotation
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@class::C::@getter::hasAnnotation
          setter: <testLibrary>::@class::C::@setter::hasAnnotation
        hasAnnotation2
          reference: <testLibrary>::@class::C::@field::hasAnnotation2
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@class::C::@getter::hasAnnotation2
          setter: <testLibrary>::@class::C::@setter::hasAnnotation2
        annotationThenComment
          reference: <testLibrary>::@class::C::@field::annotationThenComment
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@class::C::@getter::annotationThenComment
          setter: <testLibrary>::@class::C::@setter::annotationThenComment
        annotationThenComment2
          reference: <testLibrary>::@class::C::@field::annotationThenComment2
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@class::C::@getter::annotationThenComment2
          setter: <testLibrary>::@class::C::@setter::annotationThenComment2
        commentThenAnnotation
          reference: <testLibrary>::@class::C::@field::commentThenAnnotation
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@class::C::@getter::commentThenAnnotation
          setter: <testLibrary>::@class::C::@setter::commentThenAnnotation
        commentThenAnnotation2
          reference: <testLibrary>::@class::C::@field::commentThenAnnotation2
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@class::C::@getter::commentThenAnnotation2
          setter: <testLibrary>::@class::C::@setter::commentThenAnnotation2
        commentAroundAnnotation
          reference: <testLibrary>::@class::C::@field::commentAroundAnnotation
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@class::C::@getter::commentAroundAnnotation
          setter: <testLibrary>::@class::C::@setter::commentAroundAnnotation
        commentAroundAnnotation2
          reference: <testLibrary>::@class::C::@field::commentAroundAnnotation2
          firstFragment: #F11
          type: int
          getter: <testLibrary>::@class::C::@getter::commentAroundAnnotation2
          setter: <testLibrary>::@class::C::@setter::commentAroundAnnotation2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F12
      getters
        synthetic hasDocComment
          reference: <testLibrary>::@class::C::@getter::hasDocComment
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@class::C::@field::hasDocComment
        synthetic hasDocComment2
          reference: <testLibrary>::@class::C::@getter::hasDocComment2
          firstFragment: #F14
          returnType: int
          variable: <testLibrary>::@class::C::@field::hasDocComment2
        synthetic hasAnnotation
          reference: <testLibrary>::@class::C::@getter::hasAnnotation
          firstFragment: #F15
          returnType: int
          variable: <testLibrary>::@class::C::@field::hasAnnotation
        synthetic hasAnnotation2
          reference: <testLibrary>::@class::C::@getter::hasAnnotation2
          firstFragment: #F16
          returnType: int
          variable: <testLibrary>::@class::C::@field::hasAnnotation2
        synthetic annotationThenComment
          reference: <testLibrary>::@class::C::@getter::annotationThenComment
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@class::C::@field::annotationThenComment
        synthetic annotationThenComment2
          reference: <testLibrary>::@class::C::@getter::annotationThenComment2
          firstFragment: #F18
          returnType: int
          variable: <testLibrary>::@class::C::@field::annotationThenComment2
        synthetic commentThenAnnotation
          reference: <testLibrary>::@class::C::@getter::commentThenAnnotation
          firstFragment: #F19
          returnType: int
          variable: <testLibrary>::@class::C::@field::commentThenAnnotation
        synthetic commentThenAnnotation2
          reference: <testLibrary>::@class::C::@getter::commentThenAnnotation2
          firstFragment: #F20
          returnType: int
          variable: <testLibrary>::@class::C::@field::commentThenAnnotation2
        synthetic commentAroundAnnotation
          reference: <testLibrary>::@class::C::@getter::commentAroundAnnotation
          firstFragment: #F21
          returnType: int
          variable: <testLibrary>::@class::C::@field::commentAroundAnnotation
        synthetic commentAroundAnnotation2
          reference: <testLibrary>::@class::C::@getter::commentAroundAnnotation2
          firstFragment: #F22
          returnType: int
          variable: <testLibrary>::@class::C::@field::commentAroundAnnotation2
      setters
        synthetic hasDocComment
          reference: <testLibrary>::@class::C::@setter::hasDocComment
          firstFragment: #F23
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F24
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::hasDocComment
        synthetic hasDocComment2
          reference: <testLibrary>::@class::C::@setter::hasDocComment2
          firstFragment: #F25
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F26
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::hasDocComment2
        synthetic hasAnnotation
          reference: <testLibrary>::@class::C::@setter::hasAnnotation
          firstFragment: #F27
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F28
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::hasAnnotation
        synthetic hasAnnotation2
          reference: <testLibrary>::@class::C::@setter::hasAnnotation2
          firstFragment: #F29
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F30
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::hasAnnotation2
        synthetic annotationThenComment
          reference: <testLibrary>::@class::C::@setter::annotationThenComment
          firstFragment: #F31
          formalParameters
            #E4 requiredPositional value
              firstFragment: #F32
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::annotationThenComment
        synthetic annotationThenComment2
          reference: <testLibrary>::@class::C::@setter::annotationThenComment2
          firstFragment: #F33
          formalParameters
            #E5 requiredPositional value
              firstFragment: #F34
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::annotationThenComment2
        synthetic commentThenAnnotation
          reference: <testLibrary>::@class::C::@setter::commentThenAnnotation
          firstFragment: #F35
          formalParameters
            #E6 requiredPositional value
              firstFragment: #F36
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::commentThenAnnotation
        synthetic commentThenAnnotation2
          reference: <testLibrary>::@class::C::@setter::commentThenAnnotation2
          firstFragment: #F37
          formalParameters
            #E7 requiredPositional value
              firstFragment: #F38
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::commentThenAnnotation2
        synthetic commentAroundAnnotation
          reference: <testLibrary>::@class::C::@setter::commentAroundAnnotation
          firstFragment: #F39
          formalParameters
            #E8 requiredPositional value
              firstFragment: #F40
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::commentAroundAnnotation
        synthetic commentAroundAnnotation2
          reference: <testLibrary>::@class::C::@setter::commentAroundAnnotation2
          firstFragment: #F41
          formalParameters
            #E9 requiredPositional value
              firstFragment: #F42
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::commentAroundAnnotation2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 raw (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::raw
        #F2 hasDocComment (nameOffset:50) (firstTokenOffset:15) (offset:50)
          element: <testLibrary>::@function::hasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
        #F3 hasAnnotation (nameOffset:85) (firstTokenOffset:70) (offset:85)
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
              element2: dart:core::@class::Object::@constructor::new
        #F4 annotationThenComment (nameOffset:150) (firstTokenOffset:105) (offset:150)
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
              element2: dart:core::@class::Object::@constructor::new
        #F5 commentThenAnnotation (nameOffset:223) (firstTokenOffset:178) (offset:223)
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
              element2: dart:core::@class::Object::@constructor::new
        #F6 commentAroundAnnotation (nameOffset:296) (firstTokenOffset:266) (offset:296)
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
              element2: dart:core::@class::Object::@constructor::new
  functions
    raw
      reference: <testLibrary>::@function::raw
      firstFragment: #F1
      returnType: void
    hasDocComment
      reference: <testLibrary>::@function::hasDocComment
      firstFragment: #F2
      documentationComment: /// Comment 1.\n/// Comment 2.
      returnType: void
    hasAnnotation
      reference: <testLibrary>::@function::hasAnnotation
      firstFragment: #F3
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
          element2: dart:core::@class::Object::@constructor::new
      returnType: void
    annotationThenComment
      reference: <testLibrary>::@function::annotationThenComment
      firstFragment: #F4
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
          element2: dart:core::@class::Object::@constructor::new
      returnType: void
    commentThenAnnotation
      reference: <testLibrary>::@function::commentThenAnnotation
      firstFragment: #F5
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
          element2: dart:core::@class::Object::@constructor::new
      returnType: void
    commentAroundAnnotation
      reference: <testLibrary>::@function::commentAroundAnnotation
      firstFragment: #F6
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
          element2: dart:core::@class::Object::@constructor::new
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 raw (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::C::@method::raw
              codeOffset: 12
              codeLength: 13
            #F4 hasDocComment (nameOffset:68) (firstTokenOffset:29) (offset:68)
              element: <testLibrary>::@class::C::@method::hasDocComment
              documentationComment: /// Comment 1.\n/// Comment 2.
              codeOffset: 29
              codeLength: 57
            #F5 hasAnnotation (nameOffset:107) (firstTokenOffset:90) (offset:107)
              element: <testLibrary>::@class::C::@method::hasAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 90
              codeLength: 35
            #F6 annotationThenComment (nameOffset:180) (firstTokenOffset:129) (offset:180)
              element: <testLibrary>::@class::C::@method::annotationThenComment
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 129
              codeLength: 77
            #F7 commentThenAnnotation (nameOffset:261) (firstTokenOffset:210) (offset:261)
              element: <testLibrary>::@class::C::@method::commentThenAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 210
              codeLength: 77
            #F8 commentAroundAnnotation (nameOffset:342) (firstTokenOffset:308) (offset:342)
              element: <testLibrary>::@class::C::@method::commentAroundAnnotation
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
                  element2: dart:core::@class::Object::@constructor::new
              codeOffset: 308
              codeLength: 62
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        raw
          reference: <testLibrary>::@class::C::@method::raw
          firstFragment: #F3
          returnType: void
        hasDocComment
          reference: <testLibrary>::@class::C::@method::hasDocComment
          firstFragment: #F4
          documentationComment: /// Comment 1.\n/// Comment 2.
          returnType: void
        hasAnnotation
          reference: <testLibrary>::@class::C::@method::hasAnnotation
          firstFragment: #F5
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
              element2: dart:core::@class::Object::@constructor::new
          returnType: void
        annotationThenComment
          reference: <testLibrary>::@class::C::@method::annotationThenComment
          firstFragment: #F6
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
              element2: dart:core::@class::Object::@constructor::new
          returnType: void
        commentThenAnnotation
          reference: <testLibrary>::@class::C::@method::commentThenAnnotation
          firstFragment: #F7
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
              element2: dart:core::@class::Object::@constructor::new
          returnType: void
        commentAroundAnnotation
          reference: <testLibrary>::@class::C::@method::commentAroundAnnotation
          firstFragment: #F8
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
              element2: dart:core::@class::Object::@constructor::new
          returnType: void
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 main (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::main
          formalParameters
            #F2 a (nameOffset:10) (firstTokenOffset:6) (offset:10)
              element: <testLibrary>::@function::main::@formalParameter::a
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @14
                  staticType: int
            #F3 b (nameOffset:21) (firstTokenOffset:17) (offset:21)
              element: <testLibrary>::@function::main::@formalParameter::b
            #F4 c (nameOffset:28) (firstTokenOffset:24) (offset:28)
              element: <testLibrary>::@function::main::@formalParameter::c
              initializer: expression_1
                IntegerLiteral
                  literal: 2 @32
                  staticType: int
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed a
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
        #E1 optionalNamed b
          firstFragment: #F3
          type: int
        #E2 optionalNamed c
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 main (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::main
          formalParameters
            #F2 a (nameOffset:19) (firstTokenOffset:5) (offset:19)
              element: <testLibrary>::@function::main::@formalParameter::a
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
                  element2: dart:core::@class::Object::@constructor::new
            #F3 b (nameOffset:26) (firstTokenOffset:22) (offset:26)
              element: <testLibrary>::@function::main::@formalParameter::b
            #F4 c (nameOffset:43) (firstTokenOffset:29) (offset:43)
              element: <testLibrary>::@function::main::@formalParameter::c
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
                  element2: dart:core::@class::Object::@constructor::new
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F2
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
              element2: dart:core::@class::Object::@constructor::new
        #E1 requiredPositional b
          firstFragment: #F3
          type: int
        #E2 requiredPositional c
          firstFragment: #F4
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
              element2: dart:core::@class::Object::@constructor::new
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer withInit (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::withInit
        #F2 withoutInit (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::withoutInit
        #F3 hasInitializer multiWithInit (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::multiWithInit
        #F4 multiWithoutInit (nameOffset:68) (firstTokenOffset:68) (offset:68)
          element: <testLibrary>::@topLevelVariable::multiWithoutInit
        #F5 hasInitializer multiWithInit2 (nameOffset:86) (firstTokenOffset:86) (offset:86)
          element: <testLibrary>::@topLevelVariable::multiWithInit2
      getters
        #F6 synthetic withInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::withInit
        #F7 synthetic withoutInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::withoutInit
        #F8 synthetic multiWithInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::multiWithInit
        #F9 synthetic multiWithoutInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
          element: <testLibrary>::@getter::multiWithoutInit
        #F10 synthetic multiWithInit2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:86)
          element: <testLibrary>::@getter::multiWithInit2
      setters
        #F11 synthetic withInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::withInit
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::withInit::@formalParameter::value
        #F13 synthetic withoutInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::withoutInit
          formalParameters
            #F14 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::withoutInit::@formalParameter::value
        #F15 synthetic multiWithInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::multiWithInit
          formalParameters
            #F16 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::multiWithInit::@formalParameter::value
        #F17 synthetic multiWithoutInit (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
          element: <testLibrary>::@setter::multiWithoutInit
          formalParameters
            #F18 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
              element: <testLibrary>::@setter::multiWithoutInit::@formalParameter::value
        #F19 synthetic multiWithInit2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:86)
          element: <testLibrary>::@setter::multiWithInit2
          formalParameters
            #F20 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:86)
              element: <testLibrary>::@setter::multiWithInit2::@formalParameter::value
  topLevelVariables
    hasInitializer withInit
      reference: <testLibrary>::@topLevelVariable::withInit
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::withInit
      setter: <testLibrary>::@setter::withInit
    withoutInit
      reference: <testLibrary>::@topLevelVariable::withoutInit
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::withoutInit
      setter: <testLibrary>::@setter::withoutInit
    hasInitializer multiWithInit
      reference: <testLibrary>::@topLevelVariable::multiWithInit
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::multiWithInit
      setter: <testLibrary>::@setter::multiWithInit
    multiWithoutInit
      reference: <testLibrary>::@topLevelVariable::multiWithoutInit
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::multiWithoutInit
      setter: <testLibrary>::@setter::multiWithoutInit
    hasInitializer multiWithInit2
      reference: <testLibrary>::@topLevelVariable::multiWithInit2
      firstFragment: #F5
      type: int
      getter: <testLibrary>::@getter::multiWithInit2
      setter: <testLibrary>::@setter::multiWithInit2
  getters
    synthetic static withInit
      reference: <testLibrary>::@getter::withInit
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::withInit
    synthetic static withoutInit
      reference: <testLibrary>::@getter::withoutInit
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::withoutInit
    synthetic static multiWithInit
      reference: <testLibrary>::@getter::multiWithInit
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::multiWithInit
    synthetic static multiWithoutInit
      reference: <testLibrary>::@getter::multiWithoutInit
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::multiWithoutInit
    synthetic static multiWithInit2
      reference: <testLibrary>::@getter::multiWithInit2
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::multiWithInit2
  setters
    synthetic static withInit
      reference: <testLibrary>::@setter::withInit
      firstFragment: #F11
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::withInit
    synthetic static withoutInit
      reference: <testLibrary>::@setter::withoutInit
      firstFragment: #F13
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::withoutInit
    synthetic static multiWithInit
      reference: <testLibrary>::@setter::multiWithInit
      firstFragment: #F15
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F16
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::multiWithInit
    synthetic static multiWithoutInit
      reference: <testLibrary>::@setter::multiWithoutInit
      firstFragment: #F17
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F18
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::multiWithoutInit
    synthetic static multiWithInit2
      reference: <testLibrary>::@setter::multiWithInit2
      firstFragment: #F19
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F20
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::multiWithInit2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasDocComment (nameOffset:34) (firstTokenOffset:34) (offset:34)
          element: <testLibrary>::@topLevelVariable::hasDocComment
          documentationComment: /// Comment 1.\n/// Comment 2.
        #F2 hasDocComment2 (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::hasDocComment2
          documentationComment: /// Comment 1.\n/// Comment 2.
        #F3 hasAnnotation (nameOffset:80) (firstTokenOffset:80) (offset:80)
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
              element2: dart:core::@class::Object::@constructor::new
        #F4 hasAnnotation2 (nameOffset:95) (firstTokenOffset:95) (offset:95)
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
              element2: dart:core::@class::Object::@constructor::new
        #F5 annotationThenComment (nameOffset:156) (firstTokenOffset:156) (offset:156)
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
              element2: dart:core::@class::Object::@constructor::new
        #F6 annotationThenComment2 (nameOffset:179) (firstTokenOffset:179) (offset:179)
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
              element2: dart:core::@class::Object::@constructor::new
        #F7 commentThenAnnotation (nameOffset:248) (firstTokenOffset:248) (offset:248)
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
              element2: dart:core::@class::Object::@constructor::new
        #F8 commentThenAnnotation2 (nameOffset:271) (firstTokenOffset:271) (offset:271)
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
              element2: dart:core::@class::Object::@constructor::new
        #F9 commentAroundAnnotation (nameOffset:340) (firstTokenOffset:340) (offset:340)
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
              element2: dart:core::@class::Object::@constructor::new
        #F10 commentAroundAnnotation2 (nameOffset:365) (firstTokenOffset:365) (offset:365)
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
              element2: dart:core::@class::Object::@constructor::new
      getters
        #F11 synthetic hasDocComment (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@getter::hasDocComment
        #F12 synthetic hasDocComment2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::hasDocComment2
        #F13 synthetic hasAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
          element: <testLibrary>::@getter::hasAnnotation
        #F14 synthetic hasAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
          element: <testLibrary>::@getter::hasAnnotation2
        #F15 synthetic annotationThenComment (nameOffset:<null>) (firstTokenOffset:<null>) (offset:156)
          element: <testLibrary>::@getter::annotationThenComment
        #F16 synthetic annotationThenComment2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:179)
          element: <testLibrary>::@getter::annotationThenComment2
        #F17 synthetic commentThenAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:248)
          element: <testLibrary>::@getter::commentThenAnnotation
        #F18 synthetic commentThenAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:271)
          element: <testLibrary>::@getter::commentThenAnnotation2
        #F19 synthetic commentAroundAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:340)
          element: <testLibrary>::@getter::commentAroundAnnotation
        #F20 synthetic commentAroundAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:365)
          element: <testLibrary>::@getter::commentAroundAnnotation2
      setters
        #F21 synthetic hasDocComment (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@setter::hasDocComment
          formalParameters
            #F22 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@setter::hasDocComment::@formalParameter::value
        #F23 synthetic hasDocComment2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::hasDocComment2
          formalParameters
            #F24 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::hasDocComment2::@formalParameter::value
        #F25 synthetic hasAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
          element: <testLibrary>::@setter::hasAnnotation
          formalParameters
            #F26 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@setter::hasAnnotation::@formalParameter::value
        #F27 synthetic hasAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
          element: <testLibrary>::@setter::hasAnnotation2
          formalParameters
            #F28 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@setter::hasAnnotation2::@formalParameter::value
        #F29 synthetic annotationThenComment (nameOffset:<null>) (firstTokenOffset:<null>) (offset:156)
          element: <testLibrary>::@setter::annotationThenComment
          formalParameters
            #F30 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:156)
              element: <testLibrary>::@setter::annotationThenComment::@formalParameter::value
        #F31 synthetic annotationThenComment2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:179)
          element: <testLibrary>::@setter::annotationThenComment2
          formalParameters
            #F32 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:179)
              element: <testLibrary>::@setter::annotationThenComment2::@formalParameter::value
        #F33 synthetic commentThenAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:248)
          element: <testLibrary>::@setter::commentThenAnnotation
          formalParameters
            #F34 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:248)
              element: <testLibrary>::@setter::commentThenAnnotation::@formalParameter::value
        #F35 synthetic commentThenAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:271)
          element: <testLibrary>::@setter::commentThenAnnotation2
          formalParameters
            #F36 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:271)
              element: <testLibrary>::@setter::commentThenAnnotation2::@formalParameter::value
        #F37 synthetic commentAroundAnnotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:340)
          element: <testLibrary>::@setter::commentAroundAnnotation
          formalParameters
            #F38 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:340)
              element: <testLibrary>::@setter::commentAroundAnnotation::@formalParameter::value
        #F39 synthetic commentAroundAnnotation2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:365)
          element: <testLibrary>::@setter::commentAroundAnnotation2
          formalParameters
            #F40 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:365)
              element: <testLibrary>::@setter::commentAroundAnnotation2::@formalParameter::value
  topLevelVariables
    hasDocComment
      reference: <testLibrary>::@topLevelVariable::hasDocComment
      firstFragment: #F1
      documentationComment: /// Comment 1.\n/// Comment 2.
      type: int
      getter: <testLibrary>::@getter::hasDocComment
      setter: <testLibrary>::@setter::hasDocComment
    hasDocComment2
      reference: <testLibrary>::@topLevelVariable::hasDocComment2
      firstFragment: #F2
      documentationComment: /// Comment 1.\n/// Comment 2.
      type: int
      getter: <testLibrary>::@getter::hasDocComment2
      setter: <testLibrary>::@setter::hasDocComment2
    hasAnnotation
      reference: <testLibrary>::@topLevelVariable::hasAnnotation
      firstFragment: #F3
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
          element2: dart:core::@class::Object::@constructor::new
      type: int
      getter: <testLibrary>::@getter::hasAnnotation
      setter: <testLibrary>::@setter::hasAnnotation
    hasAnnotation2
      reference: <testLibrary>::@topLevelVariable::hasAnnotation2
      firstFragment: #F4
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
          element2: dart:core::@class::Object::@constructor::new
      type: int
      getter: <testLibrary>::@getter::hasAnnotation2
      setter: <testLibrary>::@setter::hasAnnotation2
    annotationThenComment
      reference: <testLibrary>::@topLevelVariable::annotationThenComment
      firstFragment: #F5
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
          element2: dart:core::@class::Object::@constructor::new
      type: int
      getter: <testLibrary>::@getter::annotationThenComment
      setter: <testLibrary>::@setter::annotationThenComment
    annotationThenComment2
      reference: <testLibrary>::@topLevelVariable::annotationThenComment2
      firstFragment: #F6
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
          element2: dart:core::@class::Object::@constructor::new
      type: int
      getter: <testLibrary>::@getter::annotationThenComment2
      setter: <testLibrary>::@setter::annotationThenComment2
    commentThenAnnotation
      reference: <testLibrary>::@topLevelVariable::commentThenAnnotation
      firstFragment: #F7
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
          element2: dart:core::@class::Object::@constructor::new
      type: int
      getter: <testLibrary>::@getter::commentThenAnnotation
      setter: <testLibrary>::@setter::commentThenAnnotation
    commentThenAnnotation2
      reference: <testLibrary>::@topLevelVariable::commentThenAnnotation2
      firstFragment: #F8
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
          element2: dart:core::@class::Object::@constructor::new
      type: int
      getter: <testLibrary>::@getter::commentThenAnnotation2
      setter: <testLibrary>::@setter::commentThenAnnotation2
    commentAroundAnnotation
      reference: <testLibrary>::@topLevelVariable::commentAroundAnnotation
      firstFragment: #F9
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
          element2: dart:core::@class::Object::@constructor::new
      type: int
      getter: <testLibrary>::@getter::commentAroundAnnotation
      setter: <testLibrary>::@setter::commentAroundAnnotation
    commentAroundAnnotation2
      reference: <testLibrary>::@topLevelVariable::commentAroundAnnotation2
      firstFragment: #F10
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
          element2: dart:core::@class::Object::@constructor::new
      type: int
      getter: <testLibrary>::@getter::commentAroundAnnotation2
      setter: <testLibrary>::@setter::commentAroundAnnotation2
  getters
    synthetic static hasDocComment
      reference: <testLibrary>::@getter::hasDocComment
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::hasDocComment
    synthetic static hasDocComment2
      reference: <testLibrary>::@getter::hasDocComment2
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::hasDocComment2
    synthetic static hasAnnotation
      reference: <testLibrary>::@getter::hasAnnotation
      firstFragment: #F13
      returnType: int
      variable: <testLibrary>::@topLevelVariable::hasAnnotation
    synthetic static hasAnnotation2
      reference: <testLibrary>::@getter::hasAnnotation2
      firstFragment: #F14
      returnType: int
      variable: <testLibrary>::@topLevelVariable::hasAnnotation2
    synthetic static annotationThenComment
      reference: <testLibrary>::@getter::annotationThenComment
      firstFragment: #F15
      returnType: int
      variable: <testLibrary>::@topLevelVariable::annotationThenComment
    synthetic static annotationThenComment2
      reference: <testLibrary>::@getter::annotationThenComment2
      firstFragment: #F16
      returnType: int
      variable: <testLibrary>::@topLevelVariable::annotationThenComment2
    synthetic static commentThenAnnotation
      reference: <testLibrary>::@getter::commentThenAnnotation
      firstFragment: #F17
      returnType: int
      variable: <testLibrary>::@topLevelVariable::commentThenAnnotation
    synthetic static commentThenAnnotation2
      reference: <testLibrary>::@getter::commentThenAnnotation2
      firstFragment: #F18
      returnType: int
      variable: <testLibrary>::@topLevelVariable::commentThenAnnotation2
    synthetic static commentAroundAnnotation
      reference: <testLibrary>::@getter::commentAroundAnnotation
      firstFragment: #F19
      returnType: int
      variable: <testLibrary>::@topLevelVariable::commentAroundAnnotation
    synthetic static commentAroundAnnotation2
      reference: <testLibrary>::@getter::commentAroundAnnotation2
      firstFragment: #F20
      returnType: int
      variable: <testLibrary>::@topLevelVariable::commentAroundAnnotation2
  setters
    synthetic static hasDocComment
      reference: <testLibrary>::@setter::hasDocComment
      firstFragment: #F21
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F22
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::hasDocComment
    synthetic static hasDocComment2
      reference: <testLibrary>::@setter::hasDocComment2
      firstFragment: #F23
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F24
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::hasDocComment2
    synthetic static hasAnnotation
      reference: <testLibrary>::@setter::hasAnnotation
      firstFragment: #F25
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F26
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::hasAnnotation
    synthetic static hasAnnotation2
      reference: <testLibrary>::@setter::hasAnnotation2
      firstFragment: #F27
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F28
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::hasAnnotation2
    synthetic static annotationThenComment
      reference: <testLibrary>::@setter::annotationThenComment
      firstFragment: #F29
      formalParameters
        #E4 requiredPositional value
          firstFragment: #F30
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::annotationThenComment
    synthetic static annotationThenComment2
      reference: <testLibrary>::@setter::annotationThenComment2
      firstFragment: #F31
      formalParameters
        #E5 requiredPositional value
          firstFragment: #F32
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::annotationThenComment2
    synthetic static commentThenAnnotation
      reference: <testLibrary>::@setter::commentThenAnnotation
      firstFragment: #F33
      formalParameters
        #E6 requiredPositional value
          firstFragment: #F34
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::commentThenAnnotation
    synthetic static commentThenAnnotation2
      reference: <testLibrary>::@setter::commentThenAnnotation2
      firstFragment: #F35
      formalParameters
        #E7 requiredPositional value
          firstFragment: #F36
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::commentThenAnnotation2
    synthetic static commentAroundAnnotation
      reference: <testLibrary>::@setter::commentAroundAnnotation
      firstFragment: #F37
      formalParameters
        #E8 requiredPositional value
          firstFragment: #F38
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::commentAroundAnnotation
    synthetic static commentAroundAnnotation2
      reference: <testLibrary>::@setter::commentAroundAnnotation2
      firstFragment: #F39
      formalParameters
        #E9 requiredPositional value
          firstFragment: #F40
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::commentAroundAnnotation2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      functions
        #F4 f (nameOffset:19) (firstTokenOffset:14) (offset:19)
          element: <testLibrary>::@function::f
          typeParameters
            #F5 U (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: #E1 U
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
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F4
      typeParameters
        #E1 U
          firstFragment: #F5
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
            #F3 named (nameOffset:21) (firstTokenOffset:19) (offset:21)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 19
              periodOffset: 20
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 a (nameOffset:18) (firstTokenOffset:14) (offset:18)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
          setters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
              typeParameters
                #F4 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
              formalParameters
                #F5 a (nameOffset:28) (firstTokenOffset:24) (offset:28)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F4
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F5
              type: int
          returnType: void
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          setters
            #F4 foo (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F5 x (nameOffset:24) (firstTokenOffset:20) (offset:24)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::x
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        synthetic foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@class::A::@setter::foo
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      setters
        foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      extendedType: int
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 f (nameOffset:12) (firstTokenOffset:7) (offset:12)
              element: <testLibrary>::@function::f::@formalParameter::f
              typeParameters
                #F3 U (nameOffset:14) (firstTokenOffset:14) (offset:14)
                  element: #E0 U
              parameters
                #F4 a (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: a@21
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E1 requiredPositional f
          firstFragment: #F2
          type: void Function<U>(int)
          typeParameters
            #E0 U
              firstFragment: #F3
          formalParameters
            #E2 requiredPositional a
              firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 f (nameOffset:22) (firstTokenOffset:8) (offset:22)
              element: <testLibrary>::@function::f::@formalParameter::f
              typeParameters
                #F3 U (nameOffset:24) (firstTokenOffset:24) (offset:24)
                  element: #E0 U
              parameters
                #F4 a (nameOffset:31) (firstTokenOffset:27) (offset:31)
                  element: a@31
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E1 requiredNamed f
          firstFragment: #F2
          type: void Function<U>(int)
          typeParameters
            #E0 U
              firstFragment: #F3
          formalParameters
            #E2 requiredPositional a
              firstFragment: #F4
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T (nameOffset:15) (firstTokenOffset:15) (offset:15)
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

  test_nameOffset_genericTypeAlias_typeParameter() async {
    var library = await buildLibrary(r'''
typedef F<T> = void Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
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

  test_nameOffset_mixin_typeParameter() async {
    var library = await buildLibrary(r'''
mixin M<T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
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
