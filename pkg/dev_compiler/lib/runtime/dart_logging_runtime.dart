library ddc.runtime.dart_logging_runtime;

import 'dart:mirrors' as mirrors;

import 'dart_runtime.dart' as rt;
export 'dart_runtime.dart' show Arity, getArity, type;

import 'package:stack_trace/stack_trace.dart';

class CastRecord {
  final Type runtimeType;
  final Type staticType;
  final bool ddcSuccess;
  final bool dartSuccess;

  CastRecord(
      this.runtimeType, this.staticType, this.ddcSuccess, this.dartSuccess);
}

// Register a handler to process CastRecords.  The default (see below) just
// prints a summary at the end.
typedef void CastRecordHandler(String key, CastRecord record);
CastRecordHandler castRecordHandler = _record;

dynamic cast(dynamic obj, Type staticType, {String key}) {
  if (key == null) {
    // If no key is past in, use the caller's frame as a key.
    final trace = new Trace.current(1);
    final frame = trace.frames.first;
    key = frame.toString();
  }
  bool ddcSuccess = true;
  bool dartSuccess = true;
  // TODO(vsm): Use instanceOf once we settle on nullability.
  try {
    rt.cast(obj, staticType);
  } catch (e) {
    ddcSuccess = false;
  }
  if (obj == null) {
    dartSuccess =
        staticType == Object || staticType == dynamic || staticType == Null;
  } else {
    // TODO(vsm): We could avoid mirror code by requiring the caller to pass
    // in obj is TypeLiteral as a parameter.  We can't do that once we have a
    // Type object instead.
    final staticMirror = mirrors.reflectType(staticType);
    final instanceMirror = mirrors.reflect(obj);
    final classMirror = instanceMirror.type;
    dartSuccess = classMirror.isSubtypeOf(staticMirror);
  }
  var record =
      new CastRecord(obj.runtimeType, staticType, ddcSuccess, dartSuccess);
  castRecordHandler(key, record);
  if (dartSuccess) {
    return obj;
  } else {
    // The public API doesn't let us set a message or configure.
    throw new CastError();
  }
}

// The default handler simply records all CastRecords and prints a summary
// at the end.
final _recordMap = new Map<String, List<CastRecord>>();
void _record(String key, CastRecord record) {
  _recordMap.putIfAbsent(key, () => <CastRecord>[]).add(record);
}

String summary({bool clear: true}) {
  final buffer = new StringBuffer();
  _recordMap.forEach((String key, List<CastRecord> records) {
    buffer.writeln('Key $key:');
    int success = 0;
    int mismatch = 0;
    int error = 0;
    int failure = 0;
    for (var record in records) {
      if (record.ddcSuccess) {
        if (record.dartSuccess) {
          success++;
        } else {
          error++;
        }
      } else {
        if (record.dartSuccess) {
          mismatch++;
        } else {
          failure++;
        }
      }
    }
    final total = success + mismatch + error + failure;
    assert(total != 0);
    final category = (String cat, int val) =>
        buffer.writeln(' - $cat: $val (${val / total})');
    category('success', success);
    category('failure', failure);
    category('mismatch', mismatch);
    category('error', error);
  });
  if (clear) {
    _recordMap.clear();
  }
  return buffer.toString();
}
