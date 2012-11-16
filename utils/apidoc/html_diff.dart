// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A script to assist in documenting the difference between the dart:html API
 * and the old DOM API.
 */
library html_diff;

import 'dart:io';

// TODO(rnystrom): Use "package:" URL (#4968).
import '../../sdk/lib/_internal/dartdoc/lib/dartdoc.dart';
import '../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart';

// TODO(amouravski): There is currently magic that looks at dart:* libraries
// rather than the declared library names. This changed due to recent syntax
// changes. We should only need to look at the library 'html'.
const List<String> HTML_LIBRARY_NAMES = const ['dart:html', 'dart:svg'];
const List<String> HTML_DECLARED_NAMES = const ['html', 'svg'];

/**
 * A class for computing a many-to-many mapping between the types and
 * members in `dart:html` and the MDN DOM types. This mapping is
 * based on two indicators:
 *
 *   1. Auto-detected wrappers. Most `dart:html` types correspond
 *      straightforwardly to a single `@domName` type, and
 *      have the same name.  In addition, most `dart:html` methods
 *      just call a single `@domName` method. This class
 *      detects these simple correspondences automatically.
 *
 *   2. Manual annotations. When it's not clear which
 *      `@domName` items a given `dart:html` item
 *      corresponds to, the `dart:html` item can be annotated in the
 *      documentation comments using the `@domName` annotation.
 *
 * The `@domName` annotations for types and members are of the form
 * `@domName NAME(, NAME)*`, where the `NAME`s refer to the
 * `@domName` types/members that correspond to the
 * annotated `dart:html` type/member. `NAME`s on member annotations
 * can refer to either fully-qualified member names (e.g.
 * `Document.createElement`) or unqualified member names
 * (e.g. `createElement`).  Unqualified member names are assumed to
 * refer to members of one of the corresponding `@domName`
 * types.
 */
class HtmlDiff {
  /**
   * A map from `dart:html` members to the corresponding fully qualified
   * `@domName` member(s).
   */
  final Map<String, Set<String>> htmlToDom;

  /** A map from `dart:html` types to corresponding `@domName` types. */
  final Map<String, Set<String>> htmlTypesToDom;

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
    var paths = <Path>[];
    for (var libraryName in HTML_LIBRARY_NAMES) {
      paths.add(new Path(libraryName));
    }
    _compilation = new Compilation.library(paths, libDir);
    _mirrors = _compilation.mirrors;
  }

  HtmlDiff({bool printWarnings: false}) :
    _printWarnings = printWarnings,
    htmlToDom = new Map<String, Set<String>>(),
    htmlTypesToDom = new Map<String, Set<String>>(),
    comments = new CommentMap();

  void warn(String s) {
    if (_printWarnings) {
      print('Warning: $s');
    }
  }

  /**
   * Computes the `@domName` to `dart:html` mapping, and
   * places it in [htmlToDom] and [htmlTypesToDom]. Before this is run, dart2js
   * should be initialized (via [parseOptions] and [initializeWorld]) and
   * [HtmlDiff.initialize] should be called.
   */
  void run() {
    for (var libraryName in HTML_DECLARED_NAMES) {
      var library = _mirrors.libraries[libraryName];
      if (library == null) {
        warn('Could not find $libraryName');
        return;
      }
      for (ClassMirror type in library.classes.values) {
        final domTypes = htmlToDomTypes(type);
        if (domTypes.isEmpty) continue;

        htmlTypesToDom.putIfAbsent(type.qualifiedName,
            () => new Set()).addAll(domTypes);

        type.members.forEach(
            (_, m) => _addMemberDiff(m, domTypes, library.simpleName));
      }
    }
  }

  /**
   * Records the `@domName` to `dart:html` mapping for
   * [htmlMember] (from `dart:html`). [domTypes] are the
   * `@domName` type values that correspond to [htmlMember]'s
   * defining type.
   */
  void _addMemberDiff(MemberMirror htmlMember, List<String> domTypes,
      String libraryName) {
    var domMembers = htmlToDomMembers(htmlMember, domTypes);
    if (htmlMember == null && !domMembers.isEmpty) {
      warn('$libraryName member '
           '${htmlMember.owner.simpleName}.'
           '${htmlMember.simpleName} has no corresponding '
           '$libraryName member.');
    }

    if (htmlMember == null) return;
    if (!domMembers.isEmpty) {
      htmlToDom[htmlMember.qualifiedName] = domMembers;
    }
  }

  /**
   * Returns the `@domName` type values that correspond to
   * [htmlType] from `dart:html`. This can be the empty list if no
   * correspondence is found.
   */
  List<String> htmlToDomTypes(ClassMirror htmlType) {
    if (htmlType.simpleName == null) return [];
    final tags = _getTags(comments.find(htmlType.location));
    if (tags.containsKey('domName')) {
      var domNames = <String>[];
      for (var s in tags['domName'].split(',')) {
        domNames.add(s.trim());
      }
      if (domNames.length == 1 && domNames[0] == 'none') return <String>[];
      return domNames;
    }
    return <String>[];
  }

  /**
   * Returns the `@domName` member values that correspond to
   * [htmlMember] from `dart:html`. This can be the empty set if no
   * correspondence is found.  [domTypes] are the
   * `@domName` type values that correspond to [htmlMember]'s
   * defining type.
   */
  Set<String> htmlToDomMembers(MemberMirror htmlMember, List<String> domTypes) {
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
        if (nameMembers.isEmpty) {
          if (name.contains('.')) {
            warn('no member $name');
          } else {
            final options = <String>[];
            for (var t in domTypes) {
              options.add('$t.$name');
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
   * Returns the `@domName` strings that are indicated by
   * [name]. [name] can be either an unqualified member name
   * (e.g. `createElement`), in which case it's treated as the name of
   * a member of one of [defaultTypes], or a fully-qualified member
   * name (e.g. `Document.createElement`), in which case it's treated as a
   * member of the @domName element (`Document` in this case).
   */
  Set<String> _membersFromName(String name, List<String> defaultTypes) {
    if (!name.contains('.', 0)) {
      if (defaultTypes.isEmpty) {
        warn('no default type for $name');
        return new Set();
      }
      final members = new Set<String>();
      defaultTypes.forEach((t) { members.add('$t.$name'); });
      return members;
    }

    if (name.split('.').length != 2) {
      warn('invalid member name ${name}');
      return new Set();
    }
    return new Set.from([name]);
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
    final re = new RegExp("@([a-zA-Z]+) ([^;]+)(?:;|\$)");
    final tags = <String, String>{};
    for (var m in re.allMatches(comment.trim())) {
      tags[m[1]] = m[2];
    }
    return tags;
  }
}
