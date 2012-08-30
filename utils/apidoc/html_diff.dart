// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A script to assist in documenting the difference between the dart:html API
 * and the old DOM API.
 */
#library('html_diff');

#import('dart:coreimpl');
#import('dart:io');

#import('../../pkg/dartdoc/dartdoc.dart');
#import('../../pkg/dartdoc/mirrors/mirrors.dart');
#import('../../pkg/dartdoc/mirrors/mirrors_util.dart');

final HTML_LIBRARY_NAME = 'dart:html';
final DOM_LIBRARY_NAME = 'dart:dom_deprecated';

/**
 * A class for computing a many-to-many mapping between the types and
 * members in `dart:dom_deprecated` and `dart:html`. This mapping is
 * based on two indicators:
 *
 *   1. Auto-detected wrappers. Most `dart:html` types correspond
 *      straightforwardly to a single `dart:dom_deprecated` type, and
 *      have the same name.  In addition, most `dart:html` methods
 *      just call a single `dart:dom_deprecated` method. This class
 *      detects these simple correspondences automatically.
 *
 *   2. Manual annotations. When it's not clear which
 *      `dart:dom_deprecated` items a given `dart:html` item
 *      corresponds to, the `dart:html` item can be annotated in the
 *      documentation comments using the `@domName` annotation.
 *
 * The `@domName` annotations for types and members are of the form
 * `@domName NAME(, NAME)*`, where the `NAME`s refer to the
 * `dart:dom_deprecated` types/members that correspond to the
 * annotated `dart:html` type/member. `NAME`s on member annotations
 * can refer to either fully-qualified member names (e.g.
 * `Document.createElement`) or unqualified member names
 * (e.g. `createElement`).  Unqualified member names are assumed to
 * refer to members of one of the corresponding `dart:dom_deprecated`
 * types.
 */
class HtmlDiff {
  /** A map from `dart:dom_deprecated` members to corresponding
   * `dart:html` members. */
  final Map<MemberMirror, Set<MemberMirror>> domToHtml;

  /** A map from `dart:html` members to corresponding
   * `dart:dom_deprecated` members.
   * TODO(johnniwinther): We use qualified names as keys, since mirrors
   * (currently) are not equal between different mirror systems.
   */
  final Map<String, Set<MemberMirror>> htmlToDom;

  /** A map from `dart:dom_deprecated` types to corresponding
   * `dart:html` types.
   * TODO(johnniwinther): We use qualified names as keys, since mirrors
   * (currently) are not equal between different mirror systems.
   */
  final Map<String, Set<InterfaceMirror>> domTypesToHtml;

  /** A map from `dart:html` types to corresponding
   * `dart:dom_deprecated` types.
   * TODO(johnniwinther): We use qualified names as keys, since mirrors
   * (currently) are not equal between different mirror systems.
   */
  final Map<String, Set<InterfaceMirror>> htmlTypesToDom;

  final CommentMap comments;

  /** If true, then print warning messages. */
  final bool _printWarnings;

  static Compilation _compilation;
  static MirrorSystem _mirrors;
  static LibraryMirror dom;

  /**
   * Perform static initialization of [world]. This should be run before
   * calling [HtmlDiff.run].
   */
  static void initialize(Path libDir) {
    _compilation = new Compilation.library(
        const <Path>[const Path(HTML_LIBRARY_NAME)], libDir);
    _mirrors = _compilation.mirrors;

    // Find 'dart:dom_deprecated' by its library tag 'dom'.
    dom = findMirror(_mirrors.libraries, DOM_LIBRARY_NAME);
  }

  HtmlDiff([bool printWarnings = false]) :
    _printWarnings = printWarnings,
    domToHtml = new Map<MemberMirror, Set<MemberMirror>>(),
    htmlToDom = new Map<String, Set<MemberMirror>>(),
    domTypesToHtml = new Map<String, Set<InterfaceMirror>>(),
    htmlTypesToDom = new Map<String, Set<InterfaceMirror>>(),
    comments = new CommentMap();

  void warn(String s) {
    if (_printWarnings) {
      print('Warning: $s');
    }
  }

  /**
   * Computes the `dart:dom_deprecated` to `dart:html` mapping, and
   * places it in [domToHtml], [htmlToDom], [domTypesToHtml], and
   * [htmlTypesToDom]. Before this is run, dart2js should be initialized
   * (via [parseOptions] and [initializeWorld]) and
   * [HtmlDiff.initialize] should be called.
   */
  void run() {
    LibraryMirror htmlLib = findMirror(_mirrors.libraries, HTML_LIBRARY_NAME);
    if (htmlLib === null) {
      warn('Could not find $HTML_LIBRARY_NAME');
      return;
    }
    for (InterfaceMirror htmlType in htmlLib.types.getValues()) {
      final domTypes = htmlToDomTypes(htmlType);
      if (domTypes.isEmpty()) continue;

      htmlTypesToDom.putIfAbsent(htmlType.qualifiedName,// map of html->[its dom types]
          () => new Set()).addAll(domTypes);
      domTypes.forEach((t) => // map of dom type -> [the html name].
          domTypesToHtml.putIfAbsent(t.qualifiedName,
            () => new Set()).add(htmlType));

      htmlType.declaredMembers.forEach(
          (_, m) => _addMemberDiff(m, domTypes)); // add those dom member types to each
          // of the html member (name/type) we're looking at
    }
  }

  /**
   * Records the `dart:dom_deprecated` to `dart:html` mapping for
   * [implMember] (from `dart:html`). [domTypes] are the
   * `dart:dom_deprecated` [Type]s that correspond to [implMember]'s
   * defining [Type].
   */
  void _addMemberDiff(MemberMirror htmlMember, List<TypeMirror> domTypes) {
    var domMembers = htmlToDomMembers(htmlMember, domTypes);
    if (htmlMember == null && !domMembers.isEmpty()) {
      warn('$HTML_LIBRARY_NAME member '
           '${htmlMember.surroundingDeclaration.simpleName}.'
           '${htmlMember.simpleName} has no corresponding '
           '$HTML_LIBRARY_NAME member.');
    }

    if (htmlMember == null) return;
    if (!domMembers.isEmpty()) {
      htmlToDom[htmlMember.qualifiedName] = domMembers;
      //htmlToDom[htmlmembername] -> list of corresponding dom members
    }
    domMembers.forEach((m) => // add the html member name to the domToHtml
        domToHtml.putIfAbsent(m, () => new Set()).add(htmlMember));
  }

  /**
   * Returns the `dart:dom_deprecated` [Type]s that correspond to
   * [htmlType] from `dart:html`. This can be the empty list if no
   * correspondence is found.
   */
  List<InterfaceMirror> htmlToDomTypes(InterfaceMirror htmlType) {
    if (htmlType.simpleName == null) return [];
    final tags = _getTags(comments.find(htmlType.location));
    if (tags.containsKey('domName')) { // TODO(efortuna): instead just tag with
      // domTypes and domMembers instead of domName
      var domNames = <String>[];
      for (var s in tags['domName'].split(',')) {
        domNames.add(s.trim());
      }
      if (domNames.length == 1 && domNames[0] == 'none') return [];
      var domTypes = <InterfaceMirror>[];
      for (var domName in domNames) {
        final domType = findMirror(dom.types, domName);
        if (domType == null) {
          warn('no $DOM_LIBRARY_NAME type named $domName');
        } else {
          domTypes.add(domType);
        }
      }
      return domTypes;
    }
    return <InterfaceMirror>[];
  }

  /**
   * Returns the `dart:dom_deprecated` [Member]s that correspond to
   * [htmlMember] from `dart:html`. This can be the empty set if no
   * correspondence is found.  [domTypes] are the
   * `dart:dom_deprecated` [Type]s that correspond to [implMember]'s
   * defining [Type].
   */
  Set<MemberMirror> htmlToDomMembers(MemberMirror htmlMember,
                                     List<InterfaceMirror> domTypes) {
    if (htmlMember.isPrivate) return new Set();
    final tags = _getTags(comments.find(htmlMember.location));
    if (tags.containsKey('domName')) {
      var domNames = <String>[];
      for (var s in tags['domName'].split(',')) {
        domNames.add(s.trim());
      }
      if (domNames.length == 1 && domNames[0] == 'none') return new Set();
      final members = new Set();
      domNames.forEach((name) {
        var nameMembers = _membersFromName(name, domTypes);
        if (nameMembers.isEmpty()) {
          if (name.contains('.')) {
            warn('no member $name');
          } else {
            final options = <String>[];
            for (var t in domTypes) {
              options.add('${t.simpleName}.${name}');
            }
            Strings.join(options, ' or ');
            warn('no member $options');
          }
        }
        members.addAll(nameMembers);
      });
      return members;
    }

    return new Set();
  }

  /**
   * Returns the `dart:dom_deprecated` [Member]s that are indicated by
   * [name]. [name] can be either an unqualified member name
   * (e.g. `createElement`), in which case it's treated as the name of
   * a member of one of [defaultTypes], or a fully-qualified member
   * name (e.g. `Document.createElement`), in which case it's looked
   * up in `dart:dom_deprecated` and [defaultTypes] is ignored.
   */
  Set<MemberMirror> _membersFromName(String name,
                                     List<InterfaceMirror> defaultTypes) {
    if (!name.contains('.', 0)) {
      if (defaultTypes.isEmpty()) {
        warn('no default type for ${name}');
        return new Set();
      }
      final members = new Set<MemberMirror>();
      defaultTypes.forEach((t) {
        MemberMirror member = findMirror(t.declaredMembers, name);
        if (member !== null) {
          members.add(member);
        }
      });
      return members;
    }

    final splitName = name.split('.');
    if (splitName.length != 2) {
      warn('invalid member name ${name}');
      return new Set();
    }

    var typeName = splitName[0];

    InterfaceMirror type = findMirror(dom.types, typeName);
    if (type == null) return new Set();

    MemberMirror member = findMirror(type.declaredMembers, splitName[1]);
    if (member == null) return new Set();

    return new Set.from([member]);
  }

  /**
   * Extracts a [Map] from tag names to values from [comment], which is parsed
   * from a Dart source file via dartdoc. Tags are of the form `@NAME VALUE`,
   * where `NAME` is alphabetic and `VALUE` can contain any character other than
   * `;`. Multiple tags can be separated by semicolons.
   *
   * At time of writing, the only tag that's used is `@domName`.
   */
  Map<String, String> _getTags(String comment) {
    if (comment == null) return const <String, String>{};
    final re = const RegExp("@([a-zA-Z]+) ([^;]+)(?:;|\$)");
    final tags = <String, String>{};
    for (var m in re.allMatches(comment.trim())) {
      tags[m[1]] = m[2];
    }
    return tags;
  }
}
