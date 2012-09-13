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
// TODO(rnystrom): Use "package:" URL (#4968).
#import('../../pkg/dartdoc/lib/mirrors.dart');
#import('../../pkg/dartdoc/lib/mirrors_util.dart');
#import('../../pkg/dartdoc/lib/dartdoc.dart', prefix: 'doc');
#import('../../lib/_internal/libraries.dart');

HtmlDiff _diff;

void main() {
  final args = new Options().arguments;

  int mode = doc.MODE_STATIC;
  Path outputDir = const Path('docs');
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
          outputDir = new Path.fromNative(arg.substring('--out='.length));
        } else {
          print('Unknown option: $arg');
          return;
        }
        break;
    }
  }

  final libPath = doc.scriptDir.append('../../');

  doc.cleanOutputDirectory(outputDir);

  // The basic dartdoc-provided static content.
  final copiedStatic = doc.copyDirectory(
      doc.scriptDir.append('../../pkg/dartdoc/static'),
      outputDir);

  // The apidoc-specific static content.
  final copiedApiDocStatic = doc.copyDirectory(
      doc.scriptDir.append('static'),
      outputDir);

  print('Parsing MDN data...');
  final mdnFile = new File.fromPath(doc.scriptDir.append('mdn/database.json'));
  final mdn = JSON.parse(mdnFile.readAsTextSync());

  print('Cross-referencing dart:html...');
  HtmlDiff.initialize(libPath);
  _diff = new HtmlDiff(printWarnings:false);
  _diff.run();

  // Process handwritten HTML documentation.
  print('Processing handwritten HTML documentation...');
  final htmldoc = new Htmldoc();
  htmldoc.includeApi = true;
  htmldoc.documentLibraries(
    <Path>[doc.scriptDir.append('../../lib/html/doc/html.dartdoc')],
    libPath);

  // Process libraries.

  // TODO(johnniwinther): Libraries for the compilation seem to be more like
  // URIs. Perhaps Path should have a toURI() method.
  // Add all of the core libraries.
  final apidocLibraries = <Path>[];
  LIBRARIES.forEach((String name, LibraryInfo info) {
    if (info.documented) {
      apidocLibraries.add(new Path('dart:$name'));
    }
  });

  final includedLibraries = <String>[];

  var lister = new Directory.fromPath(doc.scriptDir.append('../../pkg')).list();
  lister.onDir = (dirPath) {
    var path = new Path.fromNative(dirPath);
    var libName = path.filename;

    // TODO(rnystrom): Get rid of oldStylePath support when all packages are
    // using new layout. See #5106.
    var oldStylePath = path.append('${libName}.dart');
    var newStylePath = path.append('lib/${libName}.dart');

    if (new File.fromPath(oldStylePath).existsSync()) {
      apidocLibraries.add(oldStylePath);
      includedLibraries.add(libName);
    } else if (new File.fromPath(newStylePath).existsSync()) {
      apidocLibraries.add(newStylePath);
      includedLibraries.add(libName);
    } else {
      print('Warning: could not find package at $path');
    }
  };

  lister.onDone = (success) {
    print('Generating docs...');
    final apidoc = new Apidoc(mdn, htmldoc, outputDir, mode, generateAppCache);
    apidoc.dartdocPath = doc.scriptDir.append('../../pkg/dartdoc/');
    // Select the libraries to include in the produced documentation:
    apidoc.includeApi = true;
    apidoc.includedLibraries = includedLibraries;

    Futures.wait([copiedStatic, copiedApiDocStatic]).then((_) {
      apidoc.documentLibraries(apidocLibraries, libPath);

      final compiled = doc.compileScript(mode, outputDir, libPath);

      Futures.wait([compiled, copiedStatic, copiedApiDocStatic]).then((_) {
        apidoc.cleanup();
      });
    });
  };
}

/**
 * This class is purely here to scrape handwritten HTML documentation.
 * This scraped documentation will later be merged with the generated
 * HTML library.
 */
class Htmldoc extends doc.Dartdoc {
  String libraryComment;

  /**
   * Map from qualified type names to comments.
   */
  Map<String, String> typeComments;

  /**
   * Map from qualified member names to comments.
   */
  Map<String, String> memberComments;

  Htmldoc() {
    typeComments = new Map<String, String>();
    memberComments = new Map<String, String>();
  }

  // Suppress any actual writing to file.  This is only for analysis.
  void endFile() {
  }

  void write(String s) {
  }

  String getRecordedLibraryComment(LibraryMirror library) {
    if (library.simpleName == HTML_LIBRARY_NAME) {
      return libraryComment;
    }
    return null;
  }

  String getRecordedTypeComment(TypeMirror type) {
    if (typeComments.containsKey(type.qualifiedName)) {
      return typeComments[type.qualifiedName];
    }
    return null;
  }

  String getRecordedMemberComment(MemberMirror member) {
    if (memberComments.containsKey(member.qualifiedName)) {
      return memberComments[member.qualifiedName];
    }
    return null;
  }

  // These methods are subclassed and used for internal processing.
  // Do not invoke outside of this class.
  String getLibraryComment(LibraryMirror library) {
    String comment = super.getLibraryComment(library);
    libraryComment = comment;
    return comment;
  }

  String getTypeComment(TypeMirror type) {
    String comment = super.getTypeComment(type);
    recordTypeComment(type, comment);
    return comment;
  }

  String getMethodComment(MethodMirror method) {
    String comment = super.getMethodComment(method);
    recordMemberComment(method, comment);
    return comment;
  }

  String getFieldComment(FieldMirror field) {
    String comment = super.getFieldComment(field);
    recordMemberComment(field, comment);
    return comment;
  }

  void recordTypeComment(TypeMirror type, String comment) {
    if (comment != null && comment.contains('@domName')) {
      // This is not a handwritten comment.
      return;
    }
    typeComments[type.qualifiedName] = comment;
  }

  void recordMemberComment(MemberMirror member, String comment) {
    if (comment != null && comment.contains('@domName')) {
      // This is not a handwritten comment.
      return;
    }
    memberComments[member.qualifiedName] = comment;
  }
}

class Apidoc extends doc.Dartdoc {
  /** Big ball of JSON containing the scraped MDN documentation. */
  final Map mdn;

  final Htmldoc htmldoc;

  static const disqusShortname = 'dartapidocs';

  // A set of type names (TypeMirror.simpleName values) to ignore while
  // looking up information from MDN data.  TODO(eub, jacobr): fix up the MDN
  // import scripts so they run correctly and generate data that doesn't have
  // any entries that need to be ignored.
  static Set<String> _mdnTypeNamesToSkip = null;

  /**
   * The URL to the page on MDN that content was pulled from for the current
   * type being documented. Will be `null` if the type doesn't use any MDN
   * content.
   */
  String mdnUrl;

  Apidoc(this.mdn, this.htmldoc, Path outputDir, int mode,
         bool generateAppCache) {
    this.outputDir = outputDir;
    this.mode = mode;
    this.generateAppCache = generateAppCache;

    // Skip bad entries in the checked-in mdn/database.json:
    //  * UnknownElement has a top-level Gecko DOM page in German.
    if (_mdnTypeNamesToSkip == null)
      _mdnTypeNamesToSkip = new Set.from(['UnknownElement']);

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

  void docIndexLibrary(LibraryMirror library) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (library.simpleName == 'dart:nativewrappers') return;
    super.docIndexLibrary(library);
  }

  void docLibraryNavigationJson(LibraryMirror library, List libraryList) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (library.simpleName == 'dart:nativewrappers') return;
    super.docLibraryNavigationJson(library, libraryList);
  }

  void docLibrary(LibraryMirror library) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (library.simpleName == 'dart:nativewrappers') return;
    super.docLibrary(library);
  }

  /** Override definition from parent class to strip out annotation tags. */
  String commentToHtml(String comment) {
    return super.commentToHtml(
        comment.replaceAll(const RegExp("@([a-zA-Z]+) ([^;]+)(?:;|\$)"), ''));
  }

  String getLibraryComment(LibraryMirror library) {
    if (library.simpleName == HTML_LIBRARY_NAME) {
      return htmldoc.libraryComment;
    }
    return super.getLibraryComment(library);
  }

  String getTypeComment(TypeMirror type) {
    return _mergeDocs(
        includeMdnTypeComment(type), super.getTypeComment(type),
        htmldoc.getRecordedTypeComment(type));
  }

  String getMethodComment(MethodMirror method) {
    return _mergeDocs(
        includeMdnMemberComment(method), super.getMethodComment(method),
        htmldoc.getRecordedMemberComment(method));
  }

  String getFieldComment(FieldMirror field) {
    return _mergeDocs(
        includeMdnMemberComment(field), super.getFieldComment(field),
        htmldoc.getRecordedMemberComment(field));
  }

  bool isNonEmpty(String string) => (string != null) && (string.trim() != '');

  String _mergeDocs(String mdnComment, String fileComment,
                    String handWrittenComment) {
    // Prefer the hand-written comment first.
    if (isNonEmpty(handWrittenComment)) return handWrittenComment;

    // Otherwise, prefer comment from the (possibly generated) Dart
    // file.
    if (isNonEmpty(fileComment)) return fileComment;

    // Finally, fallback on MDN if available.
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

  void docType(TypeMirror type) {
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
  includeMdnTypeComment(TypeMirror type) {
    if (_mdnTypeNamesToSkip.contains(type.simpleName)) {
      print('Skipping MDN type ${type.simpleName}');
      return null;
    }

    var typeString = '';
    if (type.library.simpleName == HTML_LIBRARY_NAME) {
      // If it's an HTML type, try to map it to a base DOM type so we can find
      // the MDN docs.
      final domTypes = _diff.htmlTypesToDom[type.qualifiedName];

      // Couldn't find a DOM type.
      if ((domTypes == null) || (domTypes.length != 1)) return null;

      // Use the corresponding DOM type when searching MDN.
      // TODO(rnystrom): Shame there isn't a simpler way to get the one item
      // out of a singleton Set.
      typeString = domTypes.iterator().next();
    } else {
      // Not a DOM type.
      return null;
    }

    final mdnType = mdn[typeString];
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
  includeMdnMemberComment(MemberMirror member) {
    var library = findLibrary(member);
    var memberString = '';
    if (library.simpleName == HTML_LIBRARY_NAME) {
      // If it's an HTML type, try to map it to a DOM type name so we can find
      // the MDN docs.
      final domMembers = _diff.htmlToDom[member.qualifiedName];

      // Couldn't find a DOM type.
      if ((domMembers == null) || (domMembers.length != 1)) return null;

      // Use the corresponding DOM member when searching MDN.
      // TODO(rnystrom): Shame there isn't a simpler way to get the one item
      // out of a singleton Set.
      memberString = domMembers.iterator().next();
    } else {
      // Not a DOM type.
      return null;
    }

    // Ignore top-level functions.
    if (member.isTopLevel) return null;

    var mdnMember = null;
    var mdnType =  null;
    var pieces = memberString.split('.');
    if (pieces.length == 2) {
      mdnType = mdn[pieces[0]];
      if (mdnType == null) return null;
      var nameToFind = pieces[1];
      for (final candidateMember in mdnType['members']) {
        if (candidateMember['name'] == nameToFind) {
          mdnMember = candidateMember;
          break;
        }
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
  String _linkMember(MemberMirror member) {
    final typeName = member.surroundingDeclaration.simpleName;
    var memberName = '$typeName.${member.simpleName}';
    if (member is MethodMirror && (member.isConstructor || member.isFactory)) {
      final separator = member.constructorName == '' ? '' : '.';
      memberName = 'new $typeName$separator${member.constructorName}';
    }

    return a(memberUrl(member), memberName);
  }
}
