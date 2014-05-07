// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.method;

import 'package:markdown/markdown.dart' as markdown;

import '../exports/mirrors_util.dart' as dart2js_util;
import '../exports/source_mirrors.dart';

import '../library_helpers.dart';

import 'class.dart';
import 'doc_gen_type.dart';
import 'dummy_mirror.dart';
import 'indexable.dart';
import 'model_helpers.dart';
import 'owned_indexable.dart';
import 'parameter.dart';


/// A class containing properties of a Dart method.
class Method extends OwnedIndexable<MethodMirror> {

  /// Parameters for this method.
  final Map<String, Parameter> parameters;

  final bool isStatic;
  final bool isAbstract;
  final bool isConst;
  final DocGenType returnType;
  Method methodInheritedFrom;

  /// Qualified name to state where the comment is inherited from.
  String commentInheritedFrom = "";

  factory Method(MethodMirror mirror, Indexable owner,
      [Method methodInheritedFrom]) {
    var method = getDocgenObject(mirror, owner);
    if (method is DummyMirror) {
      method = new Method._(mirror, owner, methodInheritedFrom);
    }
    return method;
  }

  Method._(MethodMirror mirror, Indexable owner, this.methodInheritedFrom)
      : returnType = new DocGenType(mirror.returnType, owner.owningLibrary),
        isStatic = mirror.isStatic,
        isAbstract = mirror.isAbstract,
        isConst = mirror.isConstConstructor,
        parameters = createParameters(mirror.parameters, owner),
        super(mirror, owner);

  Method get originallyInheritedFrom => methodInheritedFrom == null ?
      this : methodInheritedFrom.originallyInheritedFrom;

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = determineLookupFunc(name);

    var memberScope = lookupFunc(this.mirror, name);
    if (memberScope != null) {
      // do we check for a dummy mirror returned here and look up with an owner
      // higher ooooor in getDocgenObject do we include more things in our
      // lookup
      var result = getDocgenObject(memberScope, owner);
      if (result is DummyMirror && owner.owner != null
          && owner.owner is! DummyMirror) {
        var aresult = getDocgenObject(memberScope, owner.owner);
        if (aresult is! DummyMirror) result = aresult;
      }
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }

    if (owner != null) {
      var result = owner.findElementInScope(name);
      if (result != null) return result;
    }
    return super.findElementInScope(name);
  }

  String get docName {
    if (mirror.isConstructor) {
      // We name constructors specially -- including the class name again and a
      // "-" to separate the constructor from its name (if any).
      return '${owner.docName}.${dart2js_util.nameOf(mirror.owner)}-'
          '${dart2js_util.nameOf(mirror)}';
    }
    return super.docName;
  }

  String get qualifiedName => packagePrefix + docName;

  /// Makes sure that the method with an inherited equivalent have comments.
  void ensureCommentFor(Method inheritedMethod) {
    if (comment.isNotEmpty) return;

    comment = inheritedMethod.commentToHtml(this);
    unresolvedComment = inheritedMethod.unresolvedComment;
    commentInheritedFrom = inheritedMethod.commentInheritedFrom == '' ?
        new DummyMirror(inheritedMethod.mirror).docName :
        inheritedMethod.commentInheritedFrom;
  }

  /// Generates a map describing the [Method] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'commentFrom': (methodInheritedFrom != null &&
        commentInheritedFrom == methodInheritedFrom.docName ? ''
        : commentInheritedFrom),
    'inheritedFrom': (methodInheritedFrom == null? '' :
        originallyInheritedFrom.docName),
    'static': isStatic,
    'abstract': isAbstract,
    'constant': isConst,
    'return': [returnType.toMap()],
    'parameters': recurseMap(parameters),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };

  String get typeName {
    if (mirror.isConstructor) return 'constructor';
    if (mirror.isGetter) return 'getter';
    if (mirror.isSetter) return 'setter';
    if (mirror.isOperator) return 'operator';
    return 'method';
  }

  String get comment {
    if (commentField != null) return commentField;
    if (owner is Class) {
      (owner as Class).ensureComments();
    }
    var result = super.comment;
    if (result == '' && methodInheritedFrom != null) {
      // This should be NOT from the MIRROR, but from the COMMENT.
      methodInheritedFrom.comment; // Ensure comment field has been populated.
      unresolvedComment = methodInheritedFrom.unresolvedComment;

      comment = unresolvedComment == null ? '' :
        markdown.markdownToHtml(unresolvedComment.trim(),
            linkResolver: fixReference, inlineSyntaxes: MARKDOWN_SYNTAXES);
      commentInheritedFrom = comment != '' ?
          methodInheritedFrom.commentInheritedFrom : '';
      result = comment;
    }
    return result;
  }

  bool isValidMirror(DeclarationMirror mirror) => mirror is MethodMirror;
}