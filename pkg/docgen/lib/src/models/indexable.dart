// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.indexable;

import 'dart:collection';

import 'package:markdown/markdown.dart' as markdown;

import '../exports/mirrors_util.dart' as dart2js_util;
import '../exports/source_mirrors.dart';

import '../library_helpers.dart';
import 'library.dart';
import 'mirror_based.dart';
import 'model_helpers.dart';

/// An item that is categorized in our mirrorToDocgen map, as a distinct,
/// searchable element.
///
/// These are items that refer to concrete entities (a Class, for example,
/// but not a Type, which is a "pointer" to a class) that we wish to be
/// globally resolvable. This includes things such as class methods and
/// variables, but parameters for methods are not "Indexable" as we do not want
/// the user to be able to search for a method based on its parameter names!
/// The set of indexable items also includes Typedefs, since the user can refer
/// to them as concrete entities in a particular scope.
abstract class Indexable<TMirror extends DeclarationMirror>
    extends MirrorBased<TMirror> {

  Library get owningLibrary => owner.owningLibrary;

  /// The reference to this element based on where it is printed as a
  /// documentation file and also the unique URL to refer to this item.
  ///
  /// The qualified name (for URL purposes) and the file name are the same,
  /// of the form packageName/ClassName or packageName/ClassName.methodName.
  /// This defines both the URL and the directory structure.
  String get qualifiedName => packagePrefix + ownerPrefix + name;

  /// The name of the file we write this object's data into. The same as the
  /// qualified name but with leading colons (i.e. dart:)
  /// replaced by hyphens because of Windows.
  String get fileName => qualifiedName.replaceFirst(":", "-");

  final TMirror mirror;
  final bool isPrivate;
  /// The comment text pre-resolution. We keep this around because inherited
  /// methods need to resolve links differently from the superclass.
  String unresolvedComment = '';

  Indexable(TMirror mirror)
      : this.mirror = mirror,
        this.isPrivate = isHidden(mirror as DeclarationSourceMirror) {

    var mirrorQualifiedName = dart2js_util.qualifiedNameOf(this.mirror);

    var map = _mirrorToDocgen.putIfAbsent(mirrorQualifiedName,
        () => new HashMap<String, Indexable>());

    var added = false;
    map.putIfAbsent(owner.docName, () {
      added = true;
      return this;
    });

    if (!added) {
      throw new StateError('An indexable has already been stored for '
          '${owner.docName}');
    }
  }

  /// Returns this object's qualified name, but following the conventions
  /// we're using in Dartdoc, which is that library names with dots in them
  /// have them replaced with hyphens.
  String get docName;

  /// Converts all [foo] references in comments to <a>libraryName.foo</a>.
  markdown.Node fixReference(String name) {
    // Attempt the look up the whole name up in the scope.
    String elementName = findElementInScope(name);
    if (elementName != null) {
      return new markdown.Element.text('a', elementName);
    }
    return fixComplexReference(name);
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) =>
      findElementInScopeWithPrefix(name, packagePrefix);

  /// The full docName of the owner element, appended with a '.' for this
  /// object's name to be appended.
  String get ownerPrefix => owner.docName != '' ? owner.docName + '.' : '';

  /// The prefix String to refer to the package that this item is in, for URLs
  /// and comment resolution.
  ///
  /// The prefix can be prepended to a qualified name to get a fully unique
  /// name among all packages.
  String get packagePrefix;

  /// Documentation comment with converted markdown and all links resolved.
  String commentField;

  /// Accessor to documentation comment with markdown converted to html and all
  /// links resolved.
  String get comment {
    if (commentField != null) return commentField;

    commentField = commentToHtml();
    if (commentField.isEmpty) {
      commentField = getMdnComment();
    }
    return commentField;
  }

  void set comment(x) {
    commentField = x;
  }

  /// The simple name to refer to this item.
  String get name => dart2js_util.nameOf(mirror);

  /// Accessor to the parent item that owns this item.
  ///
  /// "Owning" is defined as the object one scope-level above which this item
  /// is defined. Ex: The owner for a top level class, would be its enclosing
  /// library. The owner of a local variable in a method would be the enclosing
  /// method.
  Indexable get owner;

  /// Generates MDN comments from database.json.
  String getMdnComment();

  /// The type of this member to be used in index.txt.
  String get typeName;

  /// Creates a [Map] with this [Indexable]'s name and a preview comment.
  Map get previewMap {
    var finalMap = { 'name' : name, 'qualifiedName' : qualifiedName };
    var pre = preview;
    if (pre != null) finalMap['preview'] = pre;
    return finalMap;
  }

  String get preview {
    if (comment != '') {
      var index = comment.indexOf('</p>');
      return index > 0 ?
          '${comment.substring(0, index)}</p>' :
          '<p><i>Comment preview not available</i></p>';
    }
    return null;
  }

  /// Accessor to obtain the raw comment text for a given item, _without_ any
  /// of the links resolved.
  String get _commentText {
    String commentText;
    mirror.metadata.forEach((metadata) {
      if (metadata is CommentInstanceMirror) {
        CommentInstanceMirror comment = metadata;
        if (comment.isDocComment) {
          if (commentText == null) {
            commentText = comment.trimmedText;
          } else {
            commentText = '$commentText\n${comment.trimmedText}';
          }
        }
      }
    });
    return commentText;
  }

  /// Returns any documentation comments associated with a mirror with
  /// simple markdown converted to html.
  ///
  /// By default we resolve any comment references within our own scope.
  /// However, if a method is inherited, we want the inherited comments, but
  /// links to the subclasses's version of the methods.
  String commentToHtml([Indexable resolvingScope]) {
    if (resolvingScope == null) resolvingScope = this;
    var commentText = _commentText;
    unresolvedComment = commentText;

    commentText = commentText == null ? '' :
        markdown.markdownToHtml(commentText.trim(),
            linkResolver: resolvingScope.fixReference,
            inlineSyntaxes: MARKDOWN_SYNTAXES);
    return commentText;
  }

  /// Return a map representation of this type.
  Map toMap();

  /// Accessor to determine if this item and all of its owners are visible.
  bool get isVisible => isFullChainVisible(this);

  /// Returns true if [mirror] is the correct type of mirror that this Docgen
  /// object wraps. (Workaround for the fact that Types are not first class.)
  bool isValidMirror(DeclarationMirror mirror);
}

/// Index of all the dart2js mirrors examined to corresponding MirrorBased
/// docgen objects.
///
/// Used for lookup because of the dart2js mirrors exports
/// issue. The second level map is indexed by owner docName for faster lookup.
/// Why two levels of lookup? Speed, man. Speed.
final Map<String, Map<String, Indexable>> _mirrorToDocgen =
    new HashMap<String, Map<String, Indexable>>();

Iterable<Indexable> get allIndexables =>
    _mirrorToDocgen.values.expand((map) => map.values);

Map<String, Indexable> lookupIndexableMap(DeclarationMirror mirror) {
  return _mirrorToDocgen[dart2js_util.qualifiedNameOf(mirror)];
}
