// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A script to assist in documenting the difference between the dart:html API
 * and the old DOM API.
 */
#library('html_diff');

#import('dart:coreimpl');

#import('../../lib/dartdoc/frog/lang.dart');
#import('../../lib/dartdoc/frog/file_system_vm.dart');
#import('../../lib/dartdoc/frog/file_system.dart');
#import('../../lib/dartdoc/dartdoc.dart');

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
  final Map<Member, Set<Member>> domToHtml;

  /** A map from `dart:html` members to corresponding
   * `dart:dom_deprecated` members. */
  final Map<Member, Set<Member>> htmlToDom;

  /** A map from `dart:dom_deprecated` types to corresponding
   * `dart:html` types. */
  final Map<Type, Set<Type>> domTypesToHtml;

  /** A map from `dart:html` types to corresponding
   * `dart:dom_deprecated` types. */
  final Map<Type, Set<Type>> htmlTypesToDom;

  final CommentMap comments;

  /** If true, then print warning messages. */
  final bool _printWarnings;

  static Library dom;

  /**
   * Perform static initialization of [world]. This should be run before
   * calling [HtmlDiff.run].
   */
  static void initialize() {
    world.getOrAddLibrary('dart:dom_deprecated');
    world.getOrAddLibrary('dart:html');
    world.process();

    dom = world.libraries['dart:dom_deprecated'];
  }

  HtmlDiff([bool printWarnings = false]) : 
    _printWarnings = printWarnings, 
    domToHtml = new Map<Member, Set<Member>>(),
    htmlToDom = new Map<Member, Set<Member>>(),
    domTypesToHtml = new Map<Type, Set<Type>>(),
    htmlTypesToDom = new Map<Type, Set<Type>>(),
    comments = new CommentMap();

  void warn(String s) {
    if (_printWarnings) {
      print('Warning: ' + s);
    }
  }

  /**
   * Computes the `dart:dom_deprecated` to `dart:html` mapping, and
   * places it in [domToHtml], [htmlToDom], [domTypesToHtml], and
   * [htmlTypesToDom]. Before this is run, Frog should be initialized
   * (via [parseOptions] and [initializeWorld]) and
   * [HtmlDiff.initialize] should be called.
   */
  void run() {
    final htmlLib = world.libraries['dart:html'];
    for (Type htmlType in htmlLib.types.getValues()) {
      final domTypes = htmlToDomTypes(htmlType);
      if (domTypes.isEmpty()) continue;

      htmlTypesToDom.putIfAbsent(htmlType,
          () => new Set()).addAll(domTypes);
      domTypes.forEach((t) =>
          domTypesToHtml.putIfAbsent(t, () => new Set()).add(htmlType));

      final members = new List.from(htmlType.members.getValues());
      members.addAll(htmlType.constructors.getValues());
      htmlType.factories.forEach((f) => members.add(f));
      members.forEach((m) => _addMemberDiff(m, domTypes));
    }
  }

  /**
   * Records the `dart:dom_deprecated` to `dart:html` mapping for
   * [implMember] (from `dart:html`). [domTypes] are the
   * `dart:dom_deprecated` [Type]s that correspond to [implMember]'s
   * defining [Type].
   */
  void _addMemberDiff(Member htmlMember, List<Type> domTypes) {
    if (htmlMember.isProperty) {
      if (htmlMember.canGet) _addMemberDiff(htmlMember.getter, domTypes);
      if (htmlMember.canSet) _addMemberDiff(htmlMember.setter, domTypes);
    }

    var domMembers = htmlToDomMembers(htmlMember, domTypes);
    if (htmlMember == null && !domMembers.isEmpty()) {
      warn('dart:html member ${htmlMember.declaringType.name}.' +
          '${htmlMember.name} has no corresponding dart:html member.');
    }

    if (htmlMember == null) return;
    if (!domMembers.isEmpty()) htmlToDom[htmlMember] = domMembers;
    domMembers.forEach((m) =>
        domToHtml.putIfAbsent(m, () => new Set()).add(htmlMember));
  }

  /**
   * Returns the `dart:dom_deprecated` [Type]s that correspond to
   * [htmlType] from `dart:html`. This can be the empty list if no
   * correspondence is found.
   */
  List<Type> htmlToDomTypes(Type htmlType) {
    if (htmlType.name == null) return [];
    final tags = _getTags(comments.find(htmlType.span));

    if (tags.containsKey('domName')) {
      var domNames = map(tags['domName'].split(','), (s) => s.trim());
      if (domNames.length == 1 && domNames[0] == 'none') return [];
      return map(domNames, (domName) {
        final domType = dom.types[domName];
        if (domType == null) warn('no dart:dom_deprecated type named $domName');
        return domType;
      });
    }
    return <Type>[];
  }

  /**
   * Returns the `dart:dom_deprecated` [Member]s that correspond to
   * [htmlMember] from `dart:html`. This can be the empty set if no
   * correspondence is found.  [domTypes] are the
   * `dart:dom_deprecated` [Type]s that correspond to [implMember]'s
   * defining [Type].
   */
  Set<Member> htmlToDomMembers(Member htmlMember, List<Type> domTypes) {
    if (htmlMember.isPrivate) return new Set();
    final tags = _getTags(comments.find(htmlMember.span));
    if (tags.containsKey('domName')) {
      final domNames = map(tags['domName'].split(','), (s) => s.trim());
      if (domNames.length == 1 && domNames[0] == 'none') return new Set();
      final members = new Set();
      domNames.forEach((name) {
        var nameMembers = _membersFromName(name, domTypes);
        if (nameMembers.isEmpty()) {
          if (name.contains('.')) {
            warn('no member $name');
          } else {
            final options = Strings.join(
                map(domTypes, (t) => "${t.name}.$name"), ' or ');
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
  Set<Member> _membersFromName(String name, List<Type> defaultTypes) {
    if (!name.contains('.', 0)) {
      if (defaultTypes.isEmpty()) {
        warn('no default type for ${name}');
        return new Set();
      }
      final members = new Set<Member>();
      defaultTypes.forEach((t) {
        if (t.members.containsKey(name)) members.add(t.members[name]);
      });
      return members;
    }

    final splitName = name.split('.');
    if (splitName.length != 2) {
      warn('invalid member name ${name}');
      return new Set();
    }

    var typeName = splitName[0];

    final type = dom.types[typeName];
    if (type == null) return new Set();

    final member = type.members[splitName[1]];
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
    if (comment == null) return const <String>{};
    final re = const RegExp("@([a-zA-Z]+) ([^;]+)(?:;|\$)");
    final tags = <String>{};
    for (var m in re.allMatches(comment.trim())) {
      tags[m[1]] = m[2];
    }
    return tags;
  }
}
