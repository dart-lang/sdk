// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart' as vm;

import 'adapters/dart.dart';
import 'isolate_manager.dart';
import 'protocol_generated.dart' as dap;

/// A helper that handlers converting to/from DAP and VM Service types and to
/// user-friendly display strings.
///
/// This class may call back to the VM Service to fetch additional information
/// when converting classes - for example when converting a stack frame it may
/// fetch scripts from the VM Service in order to map token positions back to
/// line/columns as required by DAP.
class ProtocolConverter {
  /// The parent debug adapter, used to access arguments and the VM Service for
  /// the debug session.
  final DartDebugAdapter _adapter;

  ProtocolConverter(this._adapter);

  /// Converts an absolute path to one relative to the cwd used to launch the
  /// application.
  ///
  /// If [sourcePath] is outside of the cwd used for launching the application
  /// then the full absolute path will be returned.
  String convertToRelativePath(String sourcePath) {
    final cwd = _adapter.args.cwd;
    if (cwd == null) {
      return sourcePath;
    }
    final rel = path.relative(sourcePath, from: cwd);
    return !rel.startsWith('..') ? rel : sourcePath;
  }

  /// Converts a [vm.InstanceRef] into a user-friendly display string.
  ///
  /// This may be shown in the collapsed view of a complex type.
  ///
  /// If [allowCallingToString] is true, the toString() method may be called on
  /// the object for a display string.
  ///
  /// Strings are usually wrapped in quotes to indicate their type. This can be
  /// controlled with [includeQuotesAroundString] (for example to suppress them
  /// if the context indicates the user is copying the value to the clipboard).
  Future<String> convertVmInstanceRefToDisplayString(
    ThreadInfo thread,
    vm.InstanceRef ref, {
    required bool allowCallingToString,
    bool includeQuotesAroundString = true,
  }) async {
    final canCallToString = allowCallingToString &&
        (_adapter.args.evaluateToStringInDebugViews ?? false);

    if (ref.kind == 'String' || ref.valueAsString != null) {
      var stringValue = ref.valueAsString.toString();
      if (ref.valueAsStringIsTruncated ?? false) {
        stringValue = '$stringValue…';
      }
      if (ref.kind == 'String' && includeQuotesAroundString) {
        stringValue = '"$stringValue"';
      }
      return stringValue;
    } else if (ref.kind == 'PlainInstance') {
      var stringValue = ref.classRef?.name ?? '<unknown instance>';
      if (canCallToString) {
        final toStringValue = await _callToString(
          thread,
          ref,
          includeQuotesAroundString: false,
        );
        stringValue += ' ($toStringValue)';
      }
      return stringValue;
    } else if (ref.kind == 'List') {
      return 'List (${ref.length} ${ref.length == 1 ? "item" : "items"})';
    } else if (ref.kind == 'Map') {
      return 'Map (${ref.length} ${ref.length == 1 ? "item" : "items"})';
    } else if (ref.kind == 'Type') {
      return 'Type (${ref.name})';
    } else {
      return ref.kind ?? '<unknown result>';
    }
  }

  /// Converts a [vm.Instace] to a list of [dap.Variable]s, one for each
  /// field/member/element/association.
  ///
  /// If [startItem] and/or [numItems] are supplied, only a slice of the
  /// items will be returned to allow the client to page.
  Future<List<dap.Variable>> convertVmInstanceToVariablesList(
    ThreadInfo thread,
    vm.Instance instance, {
    int? startItem = 0,
    int? numItems,
  }) async {
    final elements = instance.elements;
    final associations = instance.associations;
    final fields = instance.fields;

    if (isSimpleKind(instance.kind)) {
      // For simple kinds, just return a single variable with their value.
      return [
        await convertVmResponseToVariable(
          thread,
          instance,
          allowCallingToString: true,
        )
      ];
    } else if (elements != null) {
      // For lists, map each item (in the requested subset) to a variable.
      final start = startItem ?? 0;
      return Future.wait(elements
          .cast<vm.Response>()
          .sublist(start, numItems != null ? start + numItems : null)
          .mapIndexed((index, response) async => convertVmResponseToVariable(
              thread, response,
              name: '${start + index}',
              allowCallingToString: index <= maxToStringsPerEvaluation)));
    } else if (associations != null) {
      // For maps, create a variable for each entry (in the requested subset).
      // Use the keys and values to create a display string in the form
      // "Key -> Value".
      // Both the key and value will be expandable (handled by variablesRequest
      // detecting the MapAssociation type).
      final start = startItem ?? 0;
      return Future.wait(associations
          .sublist(start, numItems != null ? start + numItems : null)
          .mapIndexed((index, mapEntry) async {
        final allowCallingToString = index <= maxToStringsPerEvaluation;
        final keyDisplay = await convertVmResponseToDisplayString(
            thread, mapEntry.key,
            allowCallingToString: allowCallingToString);
        final valueDisplay = await convertVmResponseToDisplayString(
            thread, mapEntry.value,
            allowCallingToString: allowCallingToString);
        return dap.Variable(
          name: '${start + index}',
          value: '$keyDisplay -> $valueDisplay',
          variablesReference: thread.storeData(mapEntry),
        );
      }));
    } else if (fields != null) {
      // Otherwise, show the fields from the instance.
      final variables = await Future.wait(fields.mapIndexed(
          (index, field) async => convertVmResponseToVariable(
              thread, field.value,
              name: field.decl?.name ?? '<unnamed field>',
              allowCallingToString: index <= maxToStringsPerEvaluation)));

      // Also evaluate the getters if evaluateGettersInDebugViews=true enabled.
      final service = _adapter.vmService;
      if (service != null &&
          (_adapter.args.evaluateGettersInDebugViews ?? false)) {
        // Collect getter names for this instances class and its supers.
        final getterNames =
            await _getterNamesForClassHierarchy(thread, instance.classRef);

        /// Helper to evaluate each getter and convert the response to a
        /// variable.
        Future<dap.Variable> evaluate(int index, String getterName) async {
          final response = await service.evaluate(
            thread.isolate.id!,
            instance.id!,
            getterName,
          );
          // Convert results to variables.
          return convertVmResponseToVariable(
            thread,
            response,
            name: getterName,
            allowCallingToString: index <= maxToStringsPerEvaluation,
          );
        }

        variables.addAll(await Future.wait(getterNames.mapIndexed(evaluate)));
      }

      return variables;
    } else {
      // For any other type that we don't produce variables for, return an empty
      // list.
      return [];
    }
  }

  /// Converts a [vm.Response] into a user-friendly display string.
  ///
  /// This may be shown in the collapsed view of a complex type.
  ///
  /// If [allowCallingToString] is true, the toString() method may be called on
  /// the object for a display string.
  Future<String> convertVmResponseToDisplayString(
    ThreadInfo thread,
    vm.Response response, {
    required bool allowCallingToString,
    bool includeQuotesAroundString = true,
  }) async {
    if (response is vm.InstanceRef) {
      return convertVmInstanceRefToDisplayString(
        thread,
        response,
        allowCallingToString: allowCallingToString,
        includeQuotesAroundString: includeQuotesAroundString,
      );
    } else if (response is vm.Sentinel) {
      return '<sentinel>';
    } else {
      return '<unknown: ${response.type}>';
    }
  }

  /// Converts a [vm.Response] into to a [dap.Variable].
  ///
  /// If provided, [name] is used as the variables name (for example the field
  /// name holding this variable).
  ///
  /// If [allowCallingToString] is true, the toString() method may be called on
  /// the object for a display string.
  Future<dap.Variable> convertVmResponseToVariable(
    ThreadInfo thread,
    vm.Response response, {
    String? name,
    required bool allowCallingToString,
  }) async {
    if (response is vm.InstanceRef) {
      // For non-simple variables, store them and produce a new reference that
      // can be used to access their fields/items/associations.
      final variablesReference =
          isSimpleKind(response.kind) ? 0 : thread.storeData(response);

      return dap.Variable(
        name: name ?? response.kind.toString(),
        value: await convertVmResponseToDisplayString(
          thread,
          response,
          allowCallingToString: allowCallingToString,
        ),
        variablesReference: variablesReference,
      );
    } else if (response is vm.Sentinel) {
      return dap.Variable(
        name: '<sentinel>',
        value: response.valueAsString.toString(),
        variablesReference: 0,
      );
    } else {
      return dap.Variable(
        name: '<error>',
        value: response.runtimeType.toString(),
        variablesReference: 0,
      );
    }
  }

  /// Converts a VM Service stack frame to a DAP stack frame.
  Future<dap.StackFrame> convertVmToDapStackFrame(
    ThreadInfo thread,
    vm.Frame frame, {
    required bool isTopFrame,
    int? firstAsyncMarkerIndex,
  }) async {
    final frameId = thread.storeData(frame);

    if (frame.kind == vm.FrameKind.kAsyncSuspensionMarker) {
      return dap.StackFrame(
        id: frameId,
        name: '<asynchronous gap>',
        presentationHint: 'label',
        line: 0,
        column: 0,
      );
    }

    // The VM may supply frames with a prefix that we don't want to include in
    // the frame for the user.
    const unoptimizedPrefix = '[Unoptimized] ';
    final codeName = frame.code?.name;
    final frameName = codeName != null
        ? (codeName.startsWith(unoptimizedPrefix)
            ? codeName.substring(unoptimizedPrefix.length)
            : codeName)
        : '<unknown>';

    // If there's no location, this isn't source a user can debug so use a
    // subtle hint (which the editor may use to render the frame faded).
    final location = frame.location;
    if (location == null) {
      return dap.StackFrame(
        id: frameId,
        name: frameName,
        presentationHint: 'subtle',
        line: 0,
        column: 0,
      );
    }

    final scriptRef = location.script;
    final tokenPos = location.tokenPos;
    final uri = scriptRef?.uri;
    final sourcePath = uri != null ? await convertVmUriToSourcePath(uri) : null;
    var canShowSource = sourcePath != null && File(sourcePath).existsSync();

    // Download the source if from a "dart:" uri.
    int? sourceReference;
    if (uri != null &&
        (uri.startsWith('dart:') || uri.startsWith('org-dartlang-app:')) &&
        scriptRef != null) {
      sourceReference = thread.storeData(scriptRef);
      canShowSource = true;
    }

    var line = 0, col = 0;
    if (scriptRef != null && tokenPos != null) {
      try {
        final script = await thread.getScript(scriptRef);
        line = script.getLineNumberFromTokenPos(tokenPos) ?? 0;
        col = script.getColumnNumberFromTokenPos(tokenPos) ?? 0;
      } catch (e) {
        _adapter.logger?.call('Failed to map frame location to line/col: $e');
      }
    }

    final source = canShowSource
        ? dap.Source(
            name: sourcePath != null ? convertToRelativePath(sourcePath) : uri,
            path: sourcePath,
            sourceReference: sourceReference,
            origin: null,
            adapterData: location.script)
        : null;

    // The VM only allows us to restart from frames that are not the top frame,
    // but since we're also showing asyncCausalFrames any indexes past the first
    // async boundary will not line up so we cap it there.
    final canRestart = !isTopFrame &&
        (firstAsyncMarkerIndex == null || frame.index! < firstAsyncMarkerIndex);

    return dap.StackFrame(
      id: frameId,
      name: frameName,
      source: source,
      line: line,
      column: col,
      canRestart: canRestart,
    );
  }

  /// Converts the source path from the VM to a file path.
  ///
  /// This is required so that when the user stops (or navigates via a stack
  /// frame) we open the same file on their local disk. If we downloaded the
  /// source from the VM, they would end up seeing two copies of files (and they
  /// would each have their own breakpoints) which can be confusing.
  Future<String?> convertVmUriToSourcePath(String uri) async {
    if (uri.startsWith('file://')) {
      return Uri.parse(uri).toFilePath();
    } else if (uri.startsWith('package:')) {
      // TODO(dantup): Handle mapping package: uris ?
      return null;
    } else {
      return null;
    }
  }

  /// Whether [kind] is a simple kind, and does not need to be mapped to a variable.
  bool isSimpleKind(String? kind) {
    return kind == 'String' ||
        kind == 'Bool' ||
        kind == 'Int' ||
        kind == 'Num' ||
        kind == 'Double' ||
        kind == 'Null' ||
        kind == 'Closure';
  }

  /// Invokes the toString() method on a [vm.InstanceRef] and converts the
  /// response to a user-friendly display string.
  ///
  /// Strings are usually wrapped in quotes to indicate their type. This can be
  /// controlled with [includeQuotesAroundString] (for example to suppress them
  /// if the context indicates the user is copying the value to the clipboard).
  Future<String?> _callToString(
    ThreadInfo thread,
    vm.InstanceRef ref, {
    bool includeQuotesAroundString = true,
  }) async {
    final service = _adapter.vmService;
    if (service == null) {
      return null;
    }
    final result = await service.invoke(
      thread.isolate.id!,
      ref.id!,
      'toString',
      [],
      disableBreakpoints: true,
    );

    return convertVmResponseToDisplayString(
      thread,
      result,
      allowCallingToString: false,
      includeQuotesAroundString: includeQuotesAroundString,
    );
  }

  /// Collect a list of all getter names for [classRef] and its super classes.
  ///
  /// This is used to show/evaluate getters in debug views like hovers and
  /// variables/watch panes.
  Future<Set<String>> _getterNamesForClassHierarchy(
    ThreadInfo thread,
    vm.ClassRef? classRef,
  ) async {
    final getterNames = <String>{};
    final service = _adapter.vmService;
    while (service != null && classRef != null) {
      final classResponse =
          await service.getObject(thread.isolate.id!, classRef.id!);
      if (classResponse is! vm.Class) {
        break;
      }
      final functions = classResponse.functions;
      if (functions != null) {
        final instanceFields = functions.where((f) =>
            // TODO(dantup): Update this to use something better that bkonyi is
            // adding to the protocol.
            f.json?['_kind'] == 'GetterFunction' &&
            !(f.isStatic ?? false) &&
            !(f.isConst ?? false));
        getterNames.addAll(instanceFields.map((f) => f.name!));
      }

      classRef = classResponse.superClass;
    }

    return getterNames;
  }
}
