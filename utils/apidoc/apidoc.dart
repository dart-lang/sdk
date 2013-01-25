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
library apidoc;

import 'dart:async';
import 'dart:io';
import 'dart:json' as json;
import 'html_diff.dart';
// TODO(rnystrom): Use "package:" URL (#4968).
import '../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
import '../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart';
import '../../sdk/lib/_internal/dartdoc/lib/dartdoc.dart' as doc;
import '../../sdk/lib/_internal/libraries.dart';

HtmlDiff _diff;

void main() {
  final args = new Options().arguments;

  int mode = doc.MODE_STATIC;
  Path outputDir = new Path('docs');
  bool generateAppCache = false;

  List<String> excludedLibraries = <String>[];
  List<String> includedLibraries = <String>[];
  var pkgPath;


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
        if (arg.startsWith('--exclude-lib=')) {
          excludedLibraries.add(arg.substring('--exclude-lib='.length));
        } else if (arg.startsWith('--include-lib=')) {
          includedLibraries.add(arg.substring('--include-lib='.length));
        } else if (arg.startsWith('--out=')) {
          outputDir = new Path(arg.substring('--out='.length));
        } else if (arg.startsWith('--pkg=')) {
          pkgPath = arg.substring('--pkg='.length);
        } else {
          print('Unknown option: $arg');
          return;
        }
        break;
    }
  }

  final libPath = doc.scriptDir.append('../../sdk/');

  doc.cleanOutputDirectory(outputDir);

  // The basic dartdoc-provided static content.
  final copiedStatic = doc.copyDirectory(
      doc.scriptDir.append('../../sdk/lib/_internal/dartdoc/static'),
      outputDir);

  // The apidoc-specific static content.
  final copiedApiDocStatic = doc.copyDirectory(
      doc.scriptDir.append('static'),
      outputDir);

  print('Parsing MDN data...');
  final mdnFile = new File.fromPath(doc.scriptDir.append('mdn/database.json'));
  final mdn = json.parse(mdnFile.readAsStringSync());

  print('Cross-referencing dart:html...');
  HtmlDiff.initialize(libPath);
  _diff = new HtmlDiff(printWarnings:false);
  _diff.run();

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

  var lister = new Directory.fromPath(doc.scriptDir.append('../../pkg')).list();
  lister.onDir = (dirPath) {
    var path = new Path(dirPath);
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
    final apidoc = new Apidoc(mdn, outputDir, mode, generateAppCache,
        excludedLibraries);
    apidoc.dartdocPath =
        doc.scriptDir.append('../../sdk/lib/_internal/dartdoc/');
    // Select the libraries to include in the produced documentation:
    apidoc.includeApi = true;
    apidoc.includedLibraries = includedLibraries;

    Future.wait([copiedStatic, copiedApiDocStatic]).then((_) {
      apidoc.documentLibraries(apidocLibraries, libPath, pkgPath);

      final compiled = doc.compileScript(mode, outputDir, libPath);

      Future.wait([compiled, copiedStatic, copiedApiDocStatic]).then((_) {
        apidoc.cleanup();
      });
    });
  };
}

class Apidoc extends doc.Dartdoc {
  /** Big ball of JSON containing the scraped MDN documentation. */
  final Map mdn;


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
  String mdnUrl = null;

  Apidoc(this.mdn, Path outputDir, int mode,
         bool generateAppCache, [excludedLibraries]) {
    if (?excludedLibraries) {
      this.excludedLibraries = excludedLibraries;
    }

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
        <p><a href="$tos">Terms of Service</a> |
        <a href="$privacy">Privacy Policy</a></p>
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
    if (doc.displayName(library) == 'dart:nativewrappers') return;
    super.docIndexLibrary(library);
  }

  void docLibraryNavigationJson(LibraryMirror library, List libraryList) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (doc.displayName(library) == 'dart:nativewrappers') return;
    super.docLibraryNavigationJson(library, libraryList);
  }

  void docLibrary(LibraryMirror library) {
    // TODO(rnystrom): Hackish. The IO libraries reference this but we don't
    // want it in the docs.
    if (doc.displayName(library) == 'dart:nativewrappers') return;
    super.docLibrary(library);
  }

  /** Override definition from parent class to strip out annotation tags. */
  doc.DocComment createDocComment(String text,
                                  [ClassMirror inheritedFrom]) {
    String strippedText =
        text.replaceAll(new RegExp("@([a-zA-Z]+) ([^;]+)(?:;|\$)"),
                        '').trim();
    if (strippedText.isEmpty) return null;
    return super.createDocComment(strippedText, inheritedFrom);
  }

  doc.DocComment getLibraryComment(LibraryMirror library) {
    return super.getLibraryComment(library);
  }

  doc.DocComment getTypeComment(TypeMirror type) {
    return _mergeDocs(
        includeMdnTypeComment(type), super.getTypeComment(type));
  }

  doc.DocComment getMemberComment(MemberMirror member) {
    return _mergeDocs(
        includeMdnMemberComment(member), super.getMemberComment(member));
  }

  doc.DocComment _mergeDocs(MdnComment mdnComment,
                            doc.DocComment fileComment) {
    // Otherwise, prefer comment from the (possibly generated) Dart file.
    if (fileComment != null) return fileComment;

    // Finally, fallback on MDN if available.
    if (mdnComment != null) {
      mdnUrl = mdnComment.mdnUrl;
      return mdnComment;
    }

    // We got nothing!
    return null;
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
  MdnComment includeMdnTypeComment(TypeMirror type) {
    if (_mdnTypeNamesToSkip.contains(type.simpleName)) {
      print('Skipping MDN type ${type.simpleName}');
      return null;
    }

    var typeString = '';
    if (HTML_LIBRARY_NAMES.contains(doc.displayName(type.library))) {
      // If it's an HTML type, try to map it to a base DOM type so we can find
      // the MDN docs.
      final domTypes = _diff.htmlTypesToDom[type.qualifiedName];

      // Couldn't find a DOM type.
      if ((domTypes == null) || (domTypes.length != 1)) return null;

      // Use the corresponding DOM type when searching MDN.
      // TODO(rnystrom): Shame there isn't a simpler way to get the one item
      // out of a singleton Set.
      // TODO(floitsch): switch to domTypes.first, once that's implemented.
      var iter = domTypes.iterator;
      iter.moveNext();
      typeString = iter.current;
    } else {
      // Not a DOM type.
      return null;
    }

    final mdnType = mdn[typeString];
    if (mdnType == null) return null;
    if (mdnType['skipped'] != null) return null;
    if (mdnType['summary'] == null) return null;
    if (mdnType['summary'].trim().isEmpty) return null;

    // Remember which MDN page we're using so we can attribute it.
    return new MdnComment(mdnType['summary'], mdnType['srcUrl']);
  }

  /**
   * Gets the MDN-scraped docs for [member], or `null` if this type isn't
   * scraped from MDN.
   */
  MdnComment includeMdnMemberComment(MemberMirror member) {
    var library = findLibrary(member);
    var memberString = '';
    if (HTML_LIBRARY_NAMES.contains(doc.displayName(library))) {
      // If it's an HTML type, try to map it to a DOM type name so we can find
      // the MDN docs.
      final domMembers = _diff.htmlToDom[member.qualifiedName];

      // Couldn't find a DOM type.
      if ((domMembers == null) || (domMembers.length != 1)) return null;

      // Use the corresponding DOM member when searching MDN.
      // TODO(rnystrom): Shame there isn't a simpler way to get the one item
      // out of a singleton Set.
      // TODO(floitsch): switch to domTypes.first, once that's implemented.
      var iter = domMembers.iterator;
      iter.moveNext();
      memberString = iter.current;
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
    if (mdnMember['help'] == null) return null;
    if (mdnMember['help'].trim().isEmpty) return null;

    // Remember which MDN page we're using so we can attribute it.
    return new MdnComment(mdnMember['help'], mdnType['srcUrl']);
  }

  /**
   * Returns a link to [member], relative to a type page that may be in a
   * different library than [member].
   */
  String _linkMember(MemberMirror member) {
    final typeName = member.owner.simpleName;
    var memberName = '$typeName.${member.simpleName}';
    if (member is MethodMirror && (member.isConstructor || member.isFactory)) {
      final separator = member.constructorName == '' ? '' : '.';
      memberName = 'new $typeName$separator${member.constructorName}';
    }

    return a(memberUrl(member), memberName);
  }
}

class MdnComment implements doc.DocComment {
  final String mdnComment;
  final String mdnUrl;

  MdnComment(String this.mdnComment, String this.mdnUrl);

  String get text => mdnComment;

  ClassMirror get inheritedFrom => null;

  String get html {
    // Wrap the mdn comment so we can highlight it and so we handle MDN scraped
    // content that lacks a top-level block tag.
   return '''
        <div class="mdn">
        $mdnComment
        <div class="mdn-note"><a href="$mdnUrl">from MDN</a></div>
        </div>
        ''';
  }

  String toString() => mdnComment;
}
