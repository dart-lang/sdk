// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This generates the reference documentation for the core libraries that come
 * with dart. It is built on top of dartdoc, which is a general-purpose library
 * for generating docs from any Dart code. This library extends that to include
 * additional information and styling specific to our standard library.
 *
 * Usage:
 *
 *     $ dart apidoc.dart [--out=<output directory>]
 */

#library('apidoc');

#import('dart:io');
#import('dart:json');
#import('html_diff.dart');

#import('../../frog/lang.dart');
#import('../../frog/file_system_vm.dart');
#import('../../frog/file_system.dart');
#import('../../lib/dartdoc/dartdoc.dart', prefix: 'doc');

HtmlDiff _diff;

final GET_PREFIX = 'get:';

void main() {
  final args = new Options().arguments;

  int mode = doc.MODE_STATIC;
  String outputDir = 'docs';
  String compilerPath;
  bool generateAppCache = false;

  // Parse the command-line arguments.
  for (int i = 0; i < args.length; i++) {
    final arg = args[i];

    switch (arg) {
      case '--mode=static':
        mode = doc.MODE_STATIC;
        break;

      case '--mode=live-nav':
        mode = doc.MODE_LIVE_NAV;
        break;

      case '--generate-app-cache=true':
        generateAppCache = true;
        break;

      default:
        if (arg.startsWith('--out=')) {
          outputDir = arg.substring('--out='.length);
        } else if (arg.startsWith('--compiler=')) {
          compilerPath = arg.substring('--compiler='.length);
        } else {
          print('Unknown option: $arg');
          return;
        }
        break;
    }
  }

  final frogPath = joinPaths(doc.scriptDir, '../../frog/');
  final libDir = joinPaths(frogPath, 'lib');

  if (compilerPath === null) {
    compilerPath = joinPaths(frogPath, 'frog.py');
  }

  doc.cleanOutputDirectory(outputDir);

  // Compile the client-side code to JS.
  // TODO(bob): Right path.

  final clientScript = (mode == doc.MODE_STATIC) ?
      'static' : 'live-nav';
  final Future scriptCompiled = doc.compileScript(compilerPath, libDir,
      '${doc.scriptDir}/../../lib/dartdoc/client-$clientScript.dart',
      '${outputDir}/client-$clientScript.js');

  // TODO(rnystrom): Use platform-specific path separator.
  // The basic dartdoc-provided static content.
  final Future copiedStatic = doc.copyFiles(
      '${doc.scriptDir}/../../lib/dartdoc/static', outputDir);

  // The apidoc-specific static content.
  final Future copiedApiDocStatic = doc.copyFiles('${doc.scriptDir}/static',
      outputDir);

  var files = new VMFileSystem();
  parseOptions(frogPath, ['', '', '--libdir=$frogPath/lib'], files);
  initializeWorld(files);

  print('Parsing MDN data...');
  final mdnFile = new File('${doc.scriptDir}/mdn/database.json');
  final mdn = JSON.parse(mdnFile.readAsTextSync());

  print('Cross-referencing dart:html...');
  HtmlDiff.initialize();
  _diff = new HtmlDiff(printWarnings:false);
  _diff.run();
  world.reset();

  // Add all of the core libraries.
  world.getOrAddLibrary('dart:core');
  world.getOrAddLibrary('dart:coreimpl');
  world.getOrAddLibrary('dart:crypto');
  world.getOrAddLibrary('dart:html');
  world.getOrAddLibrary('dart:io');
  world.getOrAddLibrary('dart:isolate');
  world.getOrAddLibrary('dart:json');
  world.getOrAddLibrary('${doc.scriptDir}/../../lib/math/math.dart');
  world.getOrAddLibrary('${doc.scriptDir}/../../lib/unittest/unittest.dart');
  world.getOrAddLibrary('dart:uri');
  world.getOrAddLibrary('dart:utf');
  world.process();

  print('Generating docs...');
  final apidoc = new Apidoc(mdn, outputDir, mode, generateAppCache);

  Futures.wait([scriptCompiled, copiedStatic, copiedApiDocStatic]).then((_) {
    apidoc.document();
  });
}

class Apidoc extends doc.Dartdoc {
  /** Big ball of JSON containing the scraped MDN documentation. */
  final Map mdn;

  static final disqusShortname = 'dartapidocs';

  /**
   * The URL to the page on MDN that content was pulled from for the current
   * type being documented. Will be `null` if the type doesn't use any MDN
   * content.
   */
  String mdnUrl;

  Apidoc(this.mdn, String outputDir, int mode, bool generateAppCache) {
    this.outputDir = outputDir;
    this.mode = mode;
    this.generateAppCache = generateAppCache;

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
        <p>
          Comments that are not specifically about the API libraries will
          be moderated and possibly deleted.
          Because we may incorporate information from comments into the
          documentation, any comment submitted here is under the same
          license as the documentation.
        </p>
        <p><a href="$tos">Terms of Service</a> |
        <a href="$privacy">Privacy Policy</a></p>
        ''';

    preFooterText =
        '''
        <div id="comments">
        <div id="disqus_thread"></div>
        <script type="text/javascript">
            /* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
            var disqus_shortname = "$disqusShortname"; // required: replace example with your forum shortname

            /* * * DON\'T EDIT BELOW THIS LINE * * */
            (function() {
                var dsq = document.createElement("script"); dsq.type = "text/javascript"; dsq.async = true;
                dsq.src = "http://" + disqus_shortname + ".disqus.com/embed.js";
                (document.getElementsByTagName("head")[0] || document.getElementsByTagName("body")[0]).appendChild(dsq);
            })();
        </script>
        <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
        </div> <!-- #comments -->
        ''';

    searchEngineId = '011220921317074318178:i4mscbaxtru';
    searchResultsUrl = 'http://www.dartlang.org/search.html';
  }

  void writeHeadContents(String title) {
    super.writeHeadContents(title);

    // Include the apidoc-specific CSS.
    // TODO(rnystrom): Use our CSS pre-processor to combine these.
    writeln(
        '''
        <link rel="stylesheet" type="text/css"
            href="${relativePath('apidoc-styles.css')}" />
        ''');

    // Add the analytics code.
    writeln(
        '''
        <script type="text/javascript">
          var _gaq = _gaq || [];
          _gaq.push(["_setAccount", "UA-26406144-9"]);
          _gaq.push(["_trackPageview"]);

          (function() {
            var ga = document.createElement("script");
            ga.type = "text/javascript"; ga.async = true;
            ga.src = ("https:" == document.location.protocol ?
              "https://ssl" : "http://www") + ".google-analytics.com/ga.js";
            var s = document.getElementsByTagName("script")[0];
            s.parentNode.insertBefore(ga, s);
          })();
        </script>
        ''');
  }

  void docIndexLibrary(Library library) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (library.name == 'dart:nativewrappers') return;
    super.docIndexLibrary(library);
  }

  void docLibraryNavigationJson(Library library, Map libraries) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (library.name == 'dart:nativewrappers') return;
    super.docLibraryNavigationJson(library, libraries);
  }

  void docLibrary(Library library) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (library.name == 'dart:nativewrappers') return;
    super.docLibrary(library);
  }

  /** Override definition from parent class to strip out annotation tags. */
  String commentToHtml(String comment) {
    return super.commentToHtml(
        comment.replaceAll(const RegExp("@([a-zA-Z]+) ([^;]+)(?:;|\$)"), ''));
  }

  String getTypeComment(Type type) {
    return _mergeDocs(
        includeMdnTypeComment(type), super.getTypeComment(type));
  }

  String getMethodComment(MethodMember method) {
    return _mergeDocs(
        includeMdnMemberComment(method), super.getMethodComment(method));
  }

  String getFieldComment(FieldMember field) {
    return _mergeDocs(
        includeMdnMemberComment(field), super.getFieldComment(field));
  }

  bool isNonEmpty(String string) => (string != null) && (string.trim() != '');

  String _mergeDocs(String mdnComment, String dartComment) {
    // Prefer hand-written Dart comments over stuff from MDN.
    if (isNonEmpty(dartComment)) return dartComment;

    if (isNonEmpty(mdnComment)) {
      // Wrap it so we can highlight it and so we handle MDN scraped content
      // that lacks a top-level block tag.
      return '''
          <div class="mdn">
          $mdnComment
          <div class="mdn-note"><a href="$mdnUrl">from MDN</a></div>
          </div>
          ''';
    }

    // We got nothing!
    return '';
  }

  void docType(Type type) {
    // Track whether we've inserted MDN content into this page.
    mdnUrl = null;

    super.docType(type);
  }

  void writeTypeFooter() {
    if (mdnUrl != null) {
      final MOZ = 'http://www.mozilla.org/';
      final MDN = 'https://developer.mozilla.org';
      final CCA = 'http://creativecommons.org/licenses/by-sa/2.5/';
      final CONTRIB = 'https://developer.mozilla.org/Project:en/How_to_Help';
      writeln(
          '''
          <p class="mdn-attribution">
          <a href="$MDN">
            <img src="${relativePath('mdn-logo-tiny.png')}" class="mdn-logo" />
          </a>
          This page includes <a href="$mdnUrl">content</a> from the
          <a href="$MOZ">Mozilla Foundation</a> that is graciously
          <a href="$MDN/Project:Copyrights">licensed</a> under a
          <a href="$CCA">Creative Commons: Attribution-Sharealike license</a>.
          Mozilla has no other association with Dart or dartlang.org. We
          encourage you to improve the web by
          <a href="$CONTRIB">contributing</a> to
          <a href="$MDN">The Mozilla Developer Network</a>.
          </p>
          ''');
    }
  }

  /**
   * Gets the MDN-scraped docs for [type], or `null` if this type isn't
   * scraped from MDN.
   */
  includeMdnTypeComment(Type type) {
    if (type.library.name == 'html') {
      // If it's an HTML type, try to map it to a base DOM type so we can find
      // the MDN docs.
      final domTypes = _diff.htmlTypesToDom[type];

      // Couldn't find a DOM type.
      if ((domTypes == null) || (domTypes.length != 1)) return null;

      // Use the corresponding DOM type when searching MDN.
      // TODO(rnystrom): Shame there isn't a simpler way to get the one item
      // out of a singleton Set.
      type = domTypes.iterator().next();
    } else if (type.library.name != 'dom') {
      // Not a DOM type.
      return null;
    }

    final mdnType = mdn[type.name];
    if (mdnType == null) return null;
    if (mdnType['skipped'] != null) return null;

    // Remember which MDN page we're using so we can attribute it.
    mdnUrl = mdnType['srcUrl'];
    return mdnType['summary'];
  }

  /**
   * Gets the MDN-scraped docs for [member], or `null` if this type isn't
   * scraped from MDN.
   */
  includeMdnMemberComment(Member member) {
    if (member.library.name == 'html') {
      // If it's an HTML type, try to map it to a base DOM type so we can find
      // the MDN docs.
      final domMembers = _diff.htmlToDom[member];

      // Couldn't find a DOM type.
      if ((domMembers == null) || (domMembers.length != 1)) return null;

      // Use the corresponding DOM member when searching MDN.
      // TODO(rnystrom): Shame there isn't a simpler way to get the one item
      // out of a singleton Set.
      member = domMembers.iterator().next();
    } else if (member.library.name != 'dom') {
      // Not a DOM type.
      return null;
    }

    // Ignore top-level functions.
    if (member.declaringType.isTop) return null;

    final mdnType = mdn[member.declaringType.name];
    if (mdnType == null) return null;
    var nameToFind = member.name;
    if (nameToFind.startsWith(GET_PREFIX)) {
      nameToFind = nameToFind.substring(GET_PREFIX.length);
    }
    var mdnMember = null;
    for (final candidateMember in mdnType['members']) {
      if (candidateMember['name'] == nameToFind) {
        mdnMember = candidateMember;
        break;
      }
    }

    if (mdnMember == null) return null;

    // Remember which MDN page we're using so we can attribute it.
    mdnUrl = mdnType['srcUrl'];
    return mdnMember['help'];
  }

  /**
   * Returns a link to [member], relative to a type page that may be in a
   * different library than [member].
   */
  String _linkMember(Member member) {
    final typeName = member.declaringType.name;
    var memberName = '$typeName.${member.name}';
    if (member.isConstructor || member.isFactory) {
      final separator = member.constructorName == '' ? '' : '.';
      memberName = 'new $typeName$separator${member.constructorName}';
    } else if (member.name.startsWith(GET_PREFIX)) {
      memberName = '$typeName.${member.name.substring(GET_PREFIX.length)}';
    }

    return a(memberUrl(member), memberName);
  }
}
