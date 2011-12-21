// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Generates the complete set of corelib reference documentation.
 */
#library('apidoc');

#import('html_diff.dart');
#import('../../frog/lang.dart');
#import('../../frog/file_system_node.dart');
#import('../../frog/file_system.dart');
#import('../dartdoc/dartdoc.dart', prefix: 'doc');

HtmlDiff _diff;

void main() {
  var files = new NodeFileSystem();
  parseOptions('../../frog', [] /* args */, files);
  initializeWorld(files);
  final apidoc = new Apidoc();

  HtmlDiff.initialize();

  _diff = new HtmlDiff();
  _diff.run();
  world.reset();

  apidoc.document('html');
}

class Apidoc extends doc.Dartdoc {
  Apidoc() {
    mainTitle = 'Dart API Reference';
    mainUrl = 'http://dartlang.org';

    final note    = 'http://code.google.com/policies.html#restrictions';
    final cca     = 'http://creativecommons.org/licenses/by/3.0/';
    final bsd     = 'http://code.google.com/google_bsd_license.html';
    final tos     = 'http://www.dartlang.org/tos.html';
    final privacy = 'http://www.google.com/intl/en/privacy/privacy-policy.html';

    footerText =
        '''
        <p>Except as otherwise <a href="$note">noted</a>, the content of this
        page is licensed under the <a href="$cca">Creative Commons Attribution
        3.0 License</a>, and code samples are licensed under the
        <a href="$bsd">BSD License</a>.</p>
        <p><a href="$tos">Terms of Service</a> |
        <a href="$privacy">Privacy Policy</a></p>
        ''';
  }

  void writeHeadContents(String title) {
    super.writeHeadContents(title);

    // Add the analytics code.
    doc.writeln(
        '''
        <script type="text/javascript">
          var _gaq = _gaq || [];
          _gaq.push(['_setAccount', 'UA-26406144-4']);
          _gaq.push(['_setDomainName', 'dartlang.org']);
          _gaq.push(['_trackPageview']);

          (function() {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
          })();
        </script>
        ''');
  }

  getTypeComment(Type type) {
    return _mergeComments(super.getTypeComment(type), getTypeDoc(type));
  }

  getMethodComment(MethodMember method) {
    return _mergeComments(super.getMethodComment(method), getMemberDoc(method));
  }

  getFieldComment(FieldMember field) {
    return _mergeComments(super.getFieldComment(field), getMemberDoc(field));
  }

  String _mergeComments(String comment, String extra) {
    if (comment == null) return extra;
    return '$comment\n\n$extra';
  }
}

/**
 * Returns a Markdown-formatted link to [member], relative to a type page that
 * may be in a different library than [member].
 */
String _linkMember(Member member) {
  final typeName = member.declaringType.name;
  var memberName = "$typeName.${member.name}";
  if (member.isConstructor || member.isFactory) {
    final separator = member.constructorName == '' ? '' : '.';
    memberName = 'new $typeName$separator${member.constructorName}';
  } else if (member.name.startsWith('get:')) {
    memberName = "$typeName.${member.name.substring(4)}";
  }

  return "[$memberName](../${doc.memberUrl(member)})";
}

/**
 * Returns a Markdown-formatted link to [type], relative to a type page that
 * may be in a different library than [type].
 */
String _linkType(Type type) => "[${type.name}](../${doc.typeUrl(type)})";

/**
 * Unify getters and setters of the same property. We only want to print
 * explicit setters if no getter exists.
 *
 * If [members] contains no setters, returns it unmodified.
 */
Set<Member> _unifyProperties(Set<Member> members) {
  // Only print setters if the getter doesn't exist.
  return members.filter((m) {
    if (!m.name.startsWith('set:')) return true;
    var getName = m.name.replaceFirst('set:', 'get:');
    return !members.some((maybeGet) => maybeGet.name == getName);
  });
}

/**
 * Returns additional Markdown-formatted documentation for [member], linking it
 * to the corresponding `dart:html` or `dart:dom` [Member](s). If [member] is
 * not in `dart:html` or `dart:dom`, returns no additional documentation.
 */
String getMemberDoc(Member member) {
  if (_diff.domToHtml.containsKey(member)) {
    final htmlMemberSet = _unifyProperties(_diff.domToHtml[member]);
    final allSameName = htmlMemberSet.every((m) => _diff.sameName(member, m));
    final phrase = allSameName ? "available as" : "renamed to";
    final htmlMembers = doc.joinWithCommas(map(htmlMemberSet, _linkMember));
    return "_This is $phrase $htmlMembers in the " +
      "[dart:html](../html.html) library._";
  } else if (_diff.htmlToDom.containsKey(member)) {
    final domMemberSet = _unifyProperties(_diff.htmlToDom[member]);
    final allSameName = domMemberSet.every((m) => _diff.sameName(m, member));
    final phrase = allSameName ? "is the same as" : "renames";
    final domMembers = doc.joinWithCommas(map(domMemberSet, _linkMember));
    return "_This $phrase $domMembers in the [dart:dom](../dom.html) " +
      "library._";
  } else {
    return "";
  }
}

/**
 * Returns additional Markdown-formatted documentation for [type], linking it to
 * the corresponding `dart:html` or `dart:dom` [Type](s). If [type] is not in
 * `dart:html` or `dart:dom`, returns no additional documentation.
 */
String getTypeDoc(Type type) {
  if (_diff.domTypesToHtml.containsKey(type)) {
    var htmlTypes = doc.joinWithCommas(
        map(_diff.domTypesToHtml[type], _linkType));
    return "_This corresponds to $htmlTypes in the [dart:html](../html.html) " +
      "library._";
  } else if (_diff.htmlTypesToDom.containsKey(type)) {
    var domTypes = doc.joinWithCommas(
        map(_diff.htmlTypesToDom[type], _linkType));
    return "_This corresponds to $domTypes in the [dart:dom](../dom.html) " +
      "library._";
  } else {
    return "";
  }
}
