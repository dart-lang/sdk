// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A script for printing a JSON dump of HTML diff data. In particular, this
 * lists a map of `dart:dom` methods that have been renamed to `dart:html`
 * methods without changing their semantics, and `dart:dom` methods that have
 * been removed in `dart:html`. As a heuristic, a `dart:html` method doesn't
 * change the semantics of the corresponding `dart:dom` method if it's the only
 * corresponding HTML method and it has the corresponding return type.
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
#import('html_diff.dart');
#import('../../frog/lang.dart');

HtmlDiff diff;

/** Whether or not a domType represents the same type as an htmlType. */
bool sameType(Type domType, Type htmlType) {
  if (domType.isVoid || htmlType.isVoid) {
    return domType.isVoid && htmlType.isVoid;
  }

  final htmlTypes = diff.domTypesToHtml[domType];
  return htmlTypes != null && htmlTypes.some((t) => t == htmlType);
}

/** Returns the name of a member, including `get:` if it's a field. */
String memberName(Member m) => m is FieldMember ? 'get:${m.name}' : m.name;

/**
 * Returns a string describing the name of a member. If [type] is passed, it's
 * used in place of the member's real type name.
 */
String memberDesc(Member m, [Type type = null]) {
  if (type == null) type = m.declaringType;
  return '${type.name}.${memberName(m)}';
}

/**
 * Same as [memberDesc], but if [m] is a `dart:dom` type its `dart:html`
 * typename is used instead.
 */
String htmlishMemberDesc(Member m) {
  var type = m.declaringType;
  final htmlTypes = diff.domTypesToHtml[type];
  if (htmlTypes != null && htmlTypes.length == 1) {
    type = htmlTypes.iterator().next();
  }
  return memberDesc(m, type);
}

bool isGetter(Member member) => member.name.startsWith('get:');
bool isSetter(Member member) => member.name.startsWith('set:');

/**
 * Add an entry to the map of `dart:dom` names to `dart:html` names if
 * [domMember] was renamed to [htmlMembers] with the same semantics.
 */
void maybeAddRename(Map<String, String> renamed, Member domMember,
    Collection<Member> htmlMembers) {
  if (htmlMembers.length != 1) return;
  final htmlMember = htmlMembers.iterator().next();
  if (memberName(domMember) != memberName(htmlMember) &&
    sameType(domMember.returnType, htmlMember.returnType)) {
    renamed[memberDesc(domMember)] = memberDesc(htmlMember);
  }
}

void main() {
  var files = new NodeFileSystem();
  parseOptions('../../frog', [] /* args */, files);
  initializeWorld(files);

  HtmlDiff.initialize();
  diff = new HtmlDiff();
  diff.run();

  final renamed = <String>{};
  diff.domToHtml.forEach((domMember, htmlMembers) {
    if (domMember is PropertyMember) {
      if (domMember.canGet) {
        maybeAddRename(renamed, domMember.getter, htmlMembers.filter(isGetter));
      }
      if (domMember.canSet) {
        maybeAddRename(renamed, domMember.setter, htmlMembers.filter(isSetter));
      }
    } else {
      maybeAddRename(renamed, domMember, htmlMembers);
      return;
    }
  });

  final removed = <Set>[];
  for (final type in world.libraries['dart:dom'].types.getValues()) {
    if (type.members.getValues().every((m) =>
          !diff.domToHtml.containsKey(m))) {
      removed.add('${type.name}.*');
    } else {
      for (final member in type.members.getValues()) {
        if (!diff.domToHtml.containsKey(member)) {
          if (member is PropertyMember) {
            if (member.canGet) removed.add(htmlishMemberDesc(member.getter));
            if (member.canSet) removed.add(htmlishMemberDesc(member.setter));
          } else {
            removed.add(htmlishMemberDesc(member));
          }
        } else if (member is PropertyMember) {
          final htmlMembers = diff.domToHtml[member];
          if (member.canGet && !htmlMembers.some((m) => m.name.startsWith('get:'))) {
            removed.add(htmlishMemberDesc(member.getter));
          }
          if (member.canSet && !htmlMembers.some((m) => m.name.startsWith('set:'))) {
            removed.add(htmlishMemberDesc(member.setter));
          }
        }
      }
    }
  }

  print(JSON.stringify({'renamed': renamed, 'removed': removed}));
}
