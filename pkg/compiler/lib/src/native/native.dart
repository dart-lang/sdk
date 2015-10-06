// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library native;

import 'dart:collection' show Queue;

import '../common/backend_api.dart' show
    ForeignResolver;
import '../common/registry.dart' show
    Registry;
import '../common/resolution.dart' show
    Parsing,
    Resolution;
import '../compiler.dart' show
    Compiler;
import '../constants/values.dart';
import '../core_types.dart' show
    CoreTypes;
import '../dart_types.dart';
import '../diagnostics/diagnostic_listener.dart' show
    DiagnosticReporter;
import '../diagnostics/messages.dart' show
    MessageKind;
import '../diagnostics/spannable.dart' show
    NO_LOCATION_SPANNABLE,
    Spannable;
import '../enqueue.dart' show
    Enqueuer,
    ResolutionEnqueuer;
import '../elements/elements.dart';
import '../elements/modelx.dart' show
    BaseClassElementX,
    ElementX,
    FunctionElementX,
    LibraryElementX;
import '../js/js.dart' as js;
import '../js_backend/js_backend.dart';
import '../js_emitter/js_emitter.dart' show
    CodeEmitterTask,
    NativeEmitter;
import '../parser/listener.dart' show
    Listener;
import '../parser/element_listener.dart' show
    ElementListener;
import '../parser/partial_elements.dart' show
    PartialMetadataAnnotation;
import '../ssa/ssa.dart';
import '../tokens/token.dart' show
    BeginGroupToken,
    Token;
import '../tokens/token_constants.dart' as Tokens show
    EOF_TOKEN,
    STRING_TOKEN;
import '../tree/tree.dart';
import '../universe/side_effects.dart' show
    SideEffects;
import '../util/util.dart';

part 'behavior.dart';
part 'enqueue.dart';
part 'js.dart';
part 'scanner.dart';
part 'ssa.dart';

void maybeEnableNative(Compiler compiler,
                       LibraryElementX library) {
  String libraryName = library.canonicalUri.toString();
  if (library.entryCompilationUnit.script.name.contains(
          'sdk/tests/compiler/dart2js_native')
      || libraryName == 'dart:async'
      || libraryName == 'dart:html'
      || libraryName == 'dart:html_common'
      || libraryName == 'dart:indexed_db'
      || libraryName == 'dart:js'
      || libraryName == 'dart:svg'
      || libraryName == 'dart:_native_typed_data'
      || libraryName == 'dart:web_audio'
      || libraryName == 'dart:web_gl'
      || libraryName == 'dart:web_sql'
      || compiler.allowNativeExtensions) {
    library.canUseNative = true;
  }
}

// The tags string contains comma-separated 'words' which are either dispatch
// tags (having JavaScript identifier syntax) and directives that begin with
// `!`.
List<String> nativeTagsOfClassRaw(ClassElement cls) {
  String quotedName = cls.nativeTagInfo;
  return quotedName.substring(1, quotedName.length - 1).split(',');
}

List<String> nativeTagsOfClass(ClassElement cls) {
  return nativeTagsOfClassRaw(cls).where((s) => !s.startsWith('!')).toList();
}

bool nativeTagsForcedNonLeaf(ClassElement cls) =>
    nativeTagsOfClassRaw(cls).contains('!nonleaf');
