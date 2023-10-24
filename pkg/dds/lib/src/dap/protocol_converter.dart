// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dap/dap.dart' as dap;
import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart' as vm;

import '../../dap.dart';
import 'isolate_manager.dart';
import 'variables.dart';

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
    bool allowTruncatedValue = true,
    VariableFormat? format,
  }) async {
    final isTruncated = ref.valueAsStringIsTruncated ?? false;
    final valueAsString = ref.valueAsString;
    final formatter = format ?? const VariableFormat();
    if (ref.kind == vm.InstanceKind.kString && isTruncated) {
      // Call toString() if allowed (and we don't already have a value),
      // otherwise (or if it returns null) fall back to the truncated value
      // with "…" suffix.
      var stringValue = allowCallingToString &&
              (valueAsString == null || !allowTruncatedValue)
          ? await _callToString(thread, ref,
              // Quotes are handled below, so they can be wrapped around the
              // ellipsis.
              format: VariableFormat.noQuotes())
          : null;
      stringValue ??= '$valueAsString…';

      return formatter.formatString(stringValue);
    } else if (ref.kind == vm.InstanceKind.kString) {
      // Untruncated strings.
      return formatter.formatString(valueAsString ?? "");
    } else if (valueAsString != null) {
      if (isTruncated) {
        return '$valueAsString…';
      } else if (ref.kind == vm.InstanceKind.kInt) {
        return formatter.formatInt(int.tryParse(valueAsString));
      } else {
        return valueAsString.toString();
      }
    } else if (ref.kind == 'PlainInstance') {
      var stringValue = ref.classRef?.name ?? '<unknown instance>';
      if (allowCallingToString) {
        final toStringValue = await _callToString(thread, ref,
            // Suppress quotes because this is going inside a longer string.
            format: VariableFormat.noQuotes());
        // Include the toString() result only if it's not the default (which
        // duplicates the type name we're already showing).
        if (toStringValue != "Instance of '${ref.classRef?.name}'") {
          stringValue += ' ($toStringValue)';
        }
      }
      return stringValue;
    } else if (_isList(ref)) {
      return '${ref.kind} (${ref.length} ${ref.length == 1 ? "item" : "items"})';
    } else if (_isMap(ref)) {
      return 'Map (${ref.length} ${ref.length == 1 ? "item" : "items"})';
    } else if (ref.kind == 'Type') {
      return 'Type (${ref.name})';
    } else {
      return ref.kind ?? '<unknown result>';
    }
  }

  /// Converts a [vm.Instance] to a list of [dap.Variable]s, one for each
  /// field/member/element/association.
  ///
  /// If [startItem] and/or [numItems] are supplied, it is assumed that the
  /// elements/associations/bytes in [instance] have been restricted to that set
  /// when fetched from the VM.
  Future<List<dap.Variable>> convertVmInstanceToVariablesList(
    ThreadInfo thread,
    vm.Instance instance, {
    required String? evaluateName,
    required bool allowCallingToString,
    int? startItem = 0,
    int? numItems,
    VariableFormat? format,
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
          name: null,
          evaluateName: evaluateName,
          allowCallingToString: allowCallingToString,
          format: format,
        )
      ];
    } else if (elements != null) {
      // For lists, map each item (in the requested subset) to a variable.
      // Elements can contain nulls!
      final start = startItem ?? 0;
      return Future.wait(elements.cast<vm.Response?>().mapIndexed(
        (index, response) {
          final name = '[${start + index}]';
          final itemEvaluateName =
              _adapter.combineEvaluateName(evaluateName, name);
          if (response is vm.InstanceRef) {
            _adapter.storeEvaluateName(response, itemEvaluateName);
          }

          return convertVmResponseToVariable(
            thread,
            response,
            name: name,
            evaluateName: itemEvaluateName,
            allowCallingToString:
                allowCallingToString && index <= maxToStringsPerEvaluation,
            format: format,
          );
        },
      ));
    } else if (associations != null) {
      // For maps, create a variable for each entry (in the requested subset).
      // Use the keys and values to create a display string in the form
      // "Key -> Value".
      // Both the key and value will be expandable (handled by variablesRequest
      // detecting the MapAssociation type).
      final start = startItem ?? 0;
      return Future.wait(associations.mapIndexed((index, mapEntry) async {
        final key = mapEntry.key;
        final value = mapEntry.value;
        final callToString =
            allowCallingToString && index <= maxToStringsPerEvaluation;

        final keyDisplay = await convertVmResponseToDisplayString(
          thread,
          key,
          allowCallingToString: callToString,
          format: format,
        );
        final valueDisplay = await convertVmResponseToDisplayString(
          thread,
          value,
          allowCallingToString: callToString,
          format: format,
        );

        // We only provide an evaluateName for the value, and only if the
        // key is a simple value.
        if (key is vm.InstanceRef &&
            value is vm.InstanceRef &&
            evaluateName != null &&
            isSimpleKind(key.kind)) {
          _adapter.storeEvaluateName(value, '$evaluateName[$keyDisplay]');
        }

        return dap.Variable(
          name: '${start + index}',
          value: '$keyDisplay -> $valueDisplay',
          variablesReference: thread.storeData(VariableData(mapEntry, format)),
        );
      }));
    } else if (_isList(instance) &&
        instance.length != null &&
        instance.bytes != null) {
      final elements = _decodeList(instance);

      final start = startItem ?? 0;
      return elements.mapIndexed(
        (index, element) {
          final name = '[${start + index}]';
          return dap.Variable(
            name: name,
            evaluateName: _adapter.combineEvaluateName(evaluateName, name),
            value: element.toString(),
            variablesReference: 0,
          );
        },
      ).toList();
    } else if (fields != null) {
      // Otherwise, show the fields from the instance.
      final variables = await Future.wait(fields.mapIndexed(
        (index, field) async {
          var name = field.decl?.name;
          if (name == null && field.name is int) {
            // Indexed record fields are given only their index as the name, but
            // users will expect to see them as they are accessed like `$1`.
            name = '\$${field.name}';
          } else {
            name ??= field.name;
          }
          final fieldEvaluateName = name != null
              ? _adapter.combineEvaluateName(evaluateName, '.$name')
              : null;
          final value = field.value;
          if (fieldEvaluateName != null && value is vm.InstanceRef) {
            _adapter.storeEvaluateName(value, fieldEvaluateName);
          }
          return convertVmResponseToVariable(
            thread,
            field.value,
            name: name ?? '<unnamed field>',
            evaluateName: fieldEvaluateName,
            allowCallingToString:
                allowCallingToString && index <= maxToStringsPerEvaluation,
            format: format,
          );
        },
      ));

      // 'evaluateGettersInDebugViews' implies 'showGettersInDebugViews' so
      // either being `true` will cause getters to be included.
      final includeGetters = (_adapter.args.showGettersInDebugViews ?? false) ||
          (_adapter.args.evaluateGettersInDebugViews ?? false);
      final lazyGetters = !(_adapter.args.evaluateGettersInDebugViews ?? false);
      final service = _adapter.vmService;
      if (service != null && includeGetters) {
        /// Helper to create a Variable for a getter.
        Future<dap.Variable> createVariable(
            int index, String getterName) async {
          try {
            return lazyGetters
                ? createVariableForLazyGetter(
                    thread,
                    instance,
                    getterName,
                    evaluateName,
                    allowCallingToString,
                    format,
                  )
                : await createVariableForGetter(
                    service,
                    thread,
                    instance,
                    getterName: getterName,
                    evaluateName: evaluateName,
                    allowCallingToString: allowCallingToString &&
                        index <= maxToStringsPerEvaluation,
                    format: format,
                  );
          } catch (e) {
            return dap.Variable(
              name: getterName,
              value: _adapter.extractEvaluationErrorMessage('$e'),
              variablesReference: 0,
            );
          }
        }

        // Collect getter names for this instances class and its supers.
        final getterNames =
            await _getterNamesForClassHierarchy(thread, instance.classRef);

        final getterVariables = getterNames.mapIndexed(createVariable);
        variables.addAll(await Future.wait(getterVariables));
      }

      // Sort the fields/getters by name.
      variables.sortBy((v) => v.name);

      return variables;
    } else {
      // For any other type that we don't produce variables for, return an empty
      // list.
      return [];
    }
  }

  /// Creates a Variable for a getter after eagerly fetching its value.
  Future<Variable> createVariableForGetter(
    vm.VmService service,
    ThreadInfo thread,
    vm.Instance instance, {
    String? variableName,
    required String getterName,
    required String? evaluateName,
    required bool allowCallingToString,
    required VariableFormat? format,
  }) async {
    final response = await service.evaluate(
      thread.isolate.id!,
      instance.id!,
      getterName,
    );
    final fieldEvaluateName =
        _adapter.combineEvaluateName(evaluateName, '.$getterName');
    if (response is vm.InstanceRef) {
      _adapter.storeEvaluateName(response, fieldEvaluateName);
    }
    // Convert results to variables.
    return convertVmResponseToVariable(
      thread,
      response,
      name: variableName ?? getterName,
      evaluateName: _adapter.combineEvaluateName(evaluateName, '.$getterName'),
      allowCallingToString: allowCallingToString,
      format: format,
    );
  }

  /// Creates a Variable for a getter that will be lazily evaluated.
  ///
  /// This stores any data required to call [createVariableForGetter] later.
  ///
  /// Lazy getters are implemented by inserting wrapper values and setting
  /// their presentation hint to "lazy". This will instruct clients like VS Code
  /// that they can show the value as "..." and fetch the child value into the
  /// placeholder when clicked.
  Variable createVariableForLazyGetter(
    ThreadInfo thread,
    vm.Instance instance,
    String getterName,
    String? evaluateName,
    bool allowCallingToString,
    VariableFormat? format,
  ) {
    final variablesReference = thread.storeData(
      VariableData(
        VariableGetter(
          instance: instance,
          getterName: getterName,
          parentEvaluateName: evaluateName,
          allowCallingToString: allowCallingToString,
        ),
        format,
      ),
    );

    return dap.Variable(
      name: getterName,
      value: '',
      variablesReference: variablesReference,
      presentationHint: dap.VariablePresentationHint(lazy: true),
    );
  }

  /// Decodes the bytes of a list from the base64 encoded string
  /// [instance.bytes].
  List<Object?> _decodeList(vm.Instance instance) {
    final bytes = base64Decode(instance.bytes!);
    switch (instance.kind) {
      case 'Uint8ClampedList':
        return bytes.buffer.asUint8ClampedList();
      case 'Uint8List':
        return bytes.buffer.asUint8List();
      case 'Uint16List':
        return bytes.buffer.asUint16List();
      case 'Uint32List':
        return bytes.buffer.asUint32List();
      case 'Uint64List':
        return bytes.buffer.asUint64List();
      case 'Int8List':
        return bytes.buffer.asInt8List();
      case 'Int16List':
        return bytes.buffer.asInt16List();
      case 'Int32List':
        return bytes.buffer.asInt32List();
      case 'Int64List':
        return bytes.buffer.asInt64List();
      case 'Float32List':
        return bytes.buffer.asFloat32List();
      case 'Float64List':
        return bytes.buffer.asFloat64List();
      case 'Int32x4List':
        return bytes.buffer.asInt32x4List();
      case 'Float32x4List':
        return bytes.buffer.asFloat32x4List();
      case 'Float64x2List':
        return bytes.buffer.asFloat64x2List();
      default:
        // A list type we don't know how to decode.
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
    VariableFormat? format,
  }) async {
    if (response is vm.InstanceRef) {
      return convertVmInstanceRefToDisplayString(
        thread,
        response,
        allowCallingToString: allowCallingToString,
        format: format,
      );
    } else if (response is vm.ErrorRef) {
      final errorMessage = response.message;
      return errorMessage != null
          ? _adapter.extractUnhandledExceptionMessage(errorMessage)
          : response.kind ?? '<unknown error>';
    } else if (response is vm.Sentinel) {
      return '<sentinel>';
    } else {
      return '<unknown: ${response.type}>';
    }
  }

  Future<dap.Variable> convertFieldRefToVariable(
    ThreadInfo thread,
    vm.FieldRef fieldRef, {
    required bool allowCallingToString,
    required VariableFormat? format,
  }) async {
    final field = await thread.getObject(fieldRef);
    if (field is vm.Field) {
      return convertVmResponseToVariable(
        thread,
        field.staticValue,
        name: fieldRef.name,
        allowCallingToString: allowCallingToString,
        evaluateName: fieldRef.name,
        format: format,
      );
    } else {
      return dap.Variable(
        name: fieldRef.name ?? '<unnamed field>',
        value: '<unavailable>',
        variablesReference: 0,
      );
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
    vm.Response? response, {
    required String? name,
    required String? evaluateName,
    required bool allowCallingToString,
    VariableFormat? format,
  }) async {
    if (response is vm.InstanceRef) {
      // For non-simple variables, store them and produce a new reference that
      // can be used to access their fields/items/associations.
      final variablesReference = isSimpleKind(response.kind)
          ? 0
          : thread.storeData(VariableData(response, format));

      return dap.Variable(
        name: name ?? response.kind.toString(),
        evaluateName: evaluateName,
        value: await convertVmResponseToDisplayString(
          thread,
          response,
          allowCallingToString: allowCallingToString,
          format: format,
        ),
        indexedVariables: _isList(response) ? response.length : null,
        variablesReference: variablesReference,
      );
    } else if (response is vm.Sentinel) {
      return dap.Variable(
        name: name ?? '<sentinel>',
        value: response.valueAsString.toString(),
        variablesReference: 0,
      );
    } else if (response is vm.ErrorRef) {
      final errorMessage = _adapter
          .extractUnhandledExceptionMessage(response.message ?? '<error>');
      return dap.Variable(
        name: name ?? '<error>',
        value: '<$errorMessage>',
        variablesReference: 0,
      );
    } else if (response == null) {
      return dap.Variable(
        name: name ?? '<null>',
        value: 'null',
        variablesReference: 0,
      );
    } else {
      return dap.Variable(
        name: name ?? '<error>',
        value: response.runtimeType.toString(),
        variablesReference: 0,
      );
    }
  }

  /// Returns whether [ref] is a List kind.
  ///
  /// This includes standard Dart [List], as well as lists from
  /// `dart:typed_data` such as `Uint8List`.
  bool _isList(vm.InstanceRef ref) => ref.kind?.endsWith('List') ?? false;

  /// Returns whether [ref] is a Map kind.
  bool _isMap(vm.InstanceRef ref) => ref.kind == 'Map';

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
    final scriptRefUri = scriptRef?.uri;
    final uri = scriptRefUri != null ? Uri.parse(scriptRefUri) : null;
    final uriIsDart = uri?.isScheme('dart') ?? false;
    final uriIsPackage = uri?.isScheme('package') ?? false;
    final sourcePath = uri != null ? await thread.resolveUriToPath(uri) : null;
    var canShowSource = sourcePath != null && File(sourcePath).existsSync();

    // If we don't have a local source file but the source is a "dart:" uri we
    // might still be able to download the source from the VM.
    int? sourceReference;
    if (!canShowSource &&
        uri != null &&
        (uri.isScheme('dart') || uri.isScheme('org-dartlang-app')) &&
        scriptRef != null) {
      // Try to download it (to avoid showing "source not available" errors if
      // navigated to) because a sourceRef here does not guarantee we can get
      // the source. The result will be cached (by `thread.getScript()`) and
      // reused in the resulting `sourceRequest`.
      final source = await thread.getScript(scriptRef);
      if (source.source != null) {
        sourceReference = thread.storeData(scriptRef);
        canShowSource = true;
      }
    }

    // First try to use line/col from location to avoid fetching scripts.
    // LSP doesn't support nullable lines so we use 0 as where we can't map.
    var lineCol = await _getLineCol(thread, location);

    // If the location has tokenPos -1, try reading it from the function.
    // TODO(dantup): Remove this if/when this SDK issue is fixed:
    //  https://github.com/dart-lang/sdk/issues/53559
    if (lineCol == null && location.tokenPos == -1) {
      lineCol = await _getLineCol(thread, frame.function?.location);
    }

    // LSP uses 0 for unknown lines.
    var (line, col) = lineCol ?? (0, 0);

    // If a source would be considered not-debuggable (for example it's in the
    // SDK and debugSdkLibraries=false) then we should also mark it as
    // deemphasized so that the editor can jump up the stack to the first frame
    // of debuggable code.
    final isDebuggable =
        uri != null && await _adapter.libraryIsDebuggable(thread, uri);
    final presentationHint = isDebuggable ? null : 'deemphasize';
    final origin = uri != null && _adapter.isSdkLibrary(uri)
        ? 'from the SDK'
        : uri != null && await _adapter.isExternalPackageLibrary(thread, uri)
            ? 'from external packages'
            : null;

    final source = canShowSource
        ? dap.Source(
            name: uriIsPackage || uriIsDart
                ? uri!.toString()
                : sourcePath != null
                    ? convertToRelativePath(sourcePath)
                    : uri?.toString() ?? '<unknown source>',
            path: sourcePath,
            sourceReference: sourceReference,
            origin: origin,
            adapterData: location.script,
            presentationHint: presentationHint,
          )
        : null;

    // The VM only allows us to restart from frames that are not the top frame.
    // Since we're showing `asyncCausalFrames`, frame indices past the first
    // async boundary are not real so we can't support those.
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
    VariableFormat? format,
  }) async {
    final service = _adapter.vmService;
    if (service == null) {
      return null;
    }
    var result = await service.invoke(
      thread.isolate.id!,
      ref.id!,
      'toString',
      [],
      disableBreakpoints: true,
    );

    // If the response is a string and is truncated, use getObject() to get the
    // full value.
    if (result is vm.InstanceRef &&
        result.kind == 'String' &&
        (result.valueAsStringIsTruncated ?? false)) {
      result = await service.getObject(thread.isolate.id!, result.id!);
    }

    return convertVmResponseToDisplayString(
      thread,
      result,
      allowCallingToString: false, // Don't allow recursing.
      format: format,
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
            (f.isGetter ?? false) &&
            !(f.isStatic ?? false) &&
            !(f.isConst ?? false));
        getterNames.addAll(instanceFields
            .map((f) => f.name!)
            .where((name) => !name.startsWith('_')));
      }

      classRef = classResponse.superClass;
    }

    return getterNames;
  }

  /// Gets the line/column for [location] in [thread].
  Future<(int line, int col)?> _getLineCol(
    ThreadInfo thread,
    vm.SourceLocation? location,
  ) async {
    if (location == null) {
      return null;
    }

    var line = location.line;
    var col = location.column;

    if (line != null && col != null) {
      return (line, col);
    }

    final scriptRef = location.script;
    final tokenPos = location.tokenPos;
    if (scriptRef != null && tokenPos != null && tokenPos != -1) {
      try {
        final script = await thread.getScript(scriptRef);
        line = script.getLineNumberFromTokenPos(tokenPos);
        col = script.getColumnNumberFromTokenPos(tokenPos);

        if (line != null && col != null) {
          return (line, col);
        }
      } catch (e) {
        _adapter.logger?.call('Failed to map frame location to line/col: $e');
      }
    }

    return null;
  }
}
