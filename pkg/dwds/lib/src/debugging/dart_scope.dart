// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/debugging/chrome_inspector.dart';
import 'package:dwds/src/utilities/objects.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// The regular expressions used to filter out temp variables.
/// Needs to be kept in sync with SDK repo.
///
/// TODO(annagrin) - use an alternative way to identify
/// synthetic variables.
/// Issue: https://github.com/dart-lang/sdk/issues/44262
final ddcTemporaryVariableRegExp = RegExp(
  // Starts with t$
  r'^t\$'
  // followed by anything
  r'.*'
  // or,
  r'|'
  // anything that contains the sequence '$35'.
  r'.*\$35.*',
);
final ddcTemporaryTypeVariableRegExp = RegExp(r'^__t[\$\w*]+$');

/// Temporary variable regex before SDK changes for patterns.
/// TODO(annagrin): remove after dart 3.0 is stable.
final previousDdcTemporaryVariableRegExp = RegExp(
  r'^(t[0-9]+\$?[0-9]*|__t[\$\w*]+)$',
);

const ddcAsyncScope = 'asyncScope';
const ddcCapturedAsyncScope = 'capturedAsyncScope';

/// Find the visible Dart variables from a JS Scope Chain, coming from the
/// scopeChain attribute of a Chrome CallFrame corresponding to [frame].
///
/// See chromedevtools.github.io/devtools-protocol/tot/Debugger#type-CallFrame.
Future<List<Property>> visibleVariables({
  required ChromeAppInspector inspector,
  required WipCallFrame frame,
}) async {
  final allProperties = <Property>[];

  if (frame.thisObject.type != 'undefined') {
    allProperties.add(Property({'name': 'this', 'value': frame.thisObject}));
  }

  // TODO: Try and populate all the property info for the scopes in one backend
  // call. Along with some other optimizations (caching classRef lookups), we'd
  // end up averaging one backend call per frame.

  // Iterate to least specific scope last to help preserve order in the local
  // variables view when stepping.
  for (final scope in filterScopes(frame).reversed) {
    final objectId = scope.object.objectId;
    if (objectId != null) {
      final properties = await inspector.getProperties(objectId);
      allProperties.addAll(properties);
    }
  }

  if (frame.returnValue != null && frame.returnValue!.type != 'undefined') {
    allProperties.add(Property({'name': 'return', 'value': frame.returnValue}));
  }

  // DDC's async lowering hoists variable declarations into scope objects. We
  // create one scope object per Dart scope (skipping scopes containing no
  // declarations). If a Dart scope is captured by a Dart closure the
  // JS scope object will also be captured by the compiled JS closure.
  //
  // For debugging purposes we unpack these scope objects into the set of
  // available properties to recreate the Dart context at any given point.

  final capturedAsyncScopes = [
    ...allProperties.where(
      (p) => p.name?.startsWith(ddcCapturedAsyncScope) ?? false,
    ),
  ];

  if (capturedAsyncScopes.isNotEmpty) {
    // If we are in a local function within an async function, we should use the
    // available captured scopes. These will contain all the variables captured
    // by the closure. We only close over variables used within the closure.
    for (final scopeObject in capturedAsyncScopes) {
      final scopeObjectId = scopeObject.value?.objectId;
      if (scopeObjectId == null) continue;
      final scopeProperties = await inspector.getProperties(scopeObjectId);
      allProperties.addAll(scopeProperties);
      allProperties.remove(scopeObject);
    }
  } else {
    // Otherwise we are in the async function body itself. Unpack the available
    // async scopes. Scopes we have not entered may already have a scope object
    // declared but the object will not have any values in it yet.
    final asyncScopes = [
      ...allProperties.where((p) => p.name?.startsWith(ddcAsyncScope) ?? false),
    ];
    for (final scopeObject in asyncScopes) {
      final scopeObjectId = scopeObject.value?.objectId;
      if (scopeObjectId == null) continue;
      final scopeProperties = await inspector.getProperties(scopeObjectId);
      allProperties.addAll(scopeProperties);
      allProperties.remove(scopeObject);
    }
  }

  allProperties.removeWhere((property) {
    final value = property.value;
    if (value == null) return true;

    final type = value.type;
    if (type == 'undefined') return true;

    final description = value.description ?? '';
    final name = property.name ?? '';

    // TODO(#786) Handle these correctly rather than just suppressing them.
    // We should never see a raw JS class. The only case where this happens is a
    // Dart generic function, where the type arguments get passed in as
    // parameters. Hide those.
    return (type == 'function' && description.startsWith('class ')) ||
        previousDdcTemporaryVariableRegExp.hasMatch(name) ||
        ddcTemporaryVariableRegExp.hasMatch(name) ||
        ddcTemporaryTypeVariableRegExp.hasMatch(name) ||
        (type == 'object' && description == 'dart.LegacyType.new');
  });

  return allProperties;
}

/// Filters the provided frame scopes to those that are pertinent for Dart
/// debugging.
List<WipScope> filterScopes(WipCallFrame frame) {
  final scopes = frame.getScopeChain().toList();
  // Remove outer scopes up to and including the Dart SDK.
  while (scopes.isNotEmpty &&
      !(scopes.last.name?.startsWith('load__') ?? false)) {
    scopes.removeLast();
  }
  if (scopes.isNotEmpty) scopes.removeLast();
  return scopes;
}
