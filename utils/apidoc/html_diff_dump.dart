// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A script for printing a JSON dump of HTML diff data. In particular,
 * this lists a map of `dart:dom_deprecated` methods that have been
 * renamed to `dart:html` methods without changing their semantics,
 * and `dart:dom_deprecated` methods that have been removed in
 * `dart:html`. As a heuristic, a `dart:html` method doesn't change
 * the semantics of the corresponding `dart:dom_deprecated` method if
 * it's the only corresponding HTML method and it has the
 * corresponding return type.
 *
 * The format of the output is as follows:
 *
 *   {
 *     "renamed": { domName: htmlName, ... },
 *     "removed": [name, ...]
 *   }
 *
 * Note that the removed members are listed with the names they would have in
 * HTML where possible; e.g. `HTMLMediaElement.get:textTracks` is listed as
 * `MediaElement.get:textTracks`.
 */
#library('html_diff_dump');

#import('dart:json');
#import('dart:io');
#import('html_diff.dart');
#import('../../pkg/dartdoc/mirrors/mirrors.dart');
#import('../../pkg/dartdoc/mirrors/mirrors_util.dart');

HtmlDiff diff;

/** Whether or not a domType represents the same type as an htmlType. */
bool sameType(MemberMirror domMember, MemberMirror htmlMember) {
  TypeMirror domType = domMember is FieldMirror
      ? domMember.type
      : domMember.returnType;
  TypeMirror htmlType = htmlMember is FieldMirror
      ? htmlMember.type
      : htmlMember.returnType;
  if (domType.isVoid || htmlType.isVoid) {
    return domType.isVoid && htmlType.isVoid;
  }

  final htmlTypes = diff.domTypesToHtml[domType.qualifiedName];
  return htmlTypes != null && htmlTypes.some((t) => t == htmlType);
}

/** Returns the name of a member, including `get:` if it's a field. */
String memberName(MemberMirror m) => m.simpleName;

/**
 * Returns a string describing the name of a member. If [type] is passed, it's
 * used in place of the member's real type name.
 */
String memberDesc(MemberMirror m, [ObjectMirror type = null]) {
  if (type == null) type = m.surroundingDeclaration;
  return '${type.simpleName}.${memberName(m)}';
}

/**
 * Same as [memberDesc], but if [m] is a `dart:dom_deprecated` type
 * its `dart:html` typename is used instead.
 */
String htmlishMemberDesc(MemberMirror m) {
  var type = m.surroundingDeclaration;
  final htmlTypes = diff.domTypesToHtml[type.qualifiedName];
  if (htmlTypes != null && htmlTypes.length == 1) {
    type = htmlTypes.iterator().next();
  }
  return memberDesc(m, type);
}

/**
 * Add an entry to the map of `dart:dom_deprecated` names to
 * `dart:html` names if [domMember] was renamed to [htmlMembers] with
 * the same semantics.
 */
void maybeAddRename(Map<String, String> renamed,
                    MemberMirror domMember,
                    Collection<MemberMirror> htmlMembers) {
  if (htmlMembers.length != 1) return;
  final htmlMember = htmlMembers.iterator().next();
  if (memberName(domMember) != memberName(htmlMember) &&
    sameType(domMember, htmlMember)) {
    renamed[memberDesc(domMember)] = memberDesc(htmlMember);
  }
}

void main() {
  var libPath = const Path('../../');
  HtmlDiff.initialize(libPath);
  diff = new HtmlDiff();
  diff.run();

  final renamed = <String, String>{};
  diff.domToHtml.forEach((MemberMirror domMember,
                          Set<MemberMirror> htmlMembers) {
    maybeAddRename(renamed, domMember, htmlMembers);
  });

  final removed = <String>[];

  for (InterfaceMirror type in HtmlDiff.dom.types.getValues()) {
    if (type.declaredMembers.getValues().every((m) =>
          !diff.domToHtml.containsKey(m))) {
      removed.add('${type.simpleName}.*');
    } else {
      for (MemberMirror member in type.declaredMembers.getValues()) {
        if (!diff.domToHtml.containsKey(member)) {
            removed.add(htmlishMemberDesc(member));
        }
      }
    }
  }

  print(JSON.stringify({'renamed': renamed, 'removed': removed}));
}
