import 'dart:math' show max;
import 'package:stack_trace/stack_trace.dart';
import 'package:dart2js_tools/src/trace.dart';
import 'package:dart2js_tools/src/name_decoder.dart';
import 'package:dart2js_tools/src/util.dart';
import 'package:dart2js_tools/src/trace_decoder.dart';

/// Deobuscates the given [obfuscatedTrace].
///
/// This method assumes a stack trace contains URIs normalized to be file URIs.
/// If for example you obtain a stack from a browser, you may need to preprocess
/// the stack to map the URI of the JavaScript files to URIs in the local file
/// system.
///
/// For example, a valid input to this method would be:
///
///   Error: no such method
///     at aB.a20 (/usr/local/foo/main.dart.js:71969:32)
///     at aNk.goV (/usr/local/foo/main.dart.js:72040:52)
///     at aNk.gfK (/usr/local/foo/main.dart.js:72038:27)
///     at FE.gtn (/usr/local/foo/main.dart.js:72640:24)
///     at aBZ.ghN (/usr/local/foo/main.dart.js:72642:24)
///     at inheritance (/usr/local/foo/main.dart.js:105334:0)
///     at FE (/usr/local/foo/main.dart.js:5037:18)
///
/// Internally this method will read those JavaScript files, search for the
///  `//# sourceMappingURL=` line at the end, and load the corresponding
/// source-map file.
String deobfuscateStackTrace(String obfuscatedTrace) {
  String error = extractErrorMessage(obfuscatedTrace);
  var provider = CachingFileProvider();
  StackDeobfuscationResult result = deobfuscateStack(obfuscatedTrace, provider);
  Frame firstFrame = result.original.frames.first;
  String translatedError = (firstFrame.uri.scheme == 'error'
          ? null
          : translate(error, provider.mappingFor(firstFrame.uri))) ??
      '<no error message found>';

  var sb = StringBuffer();
  sb.writeln(translatedError);
  maxMemberLengthHelper(int m, Frame f) => max(f.member.length, m);
  int longest = result.deobfuscated.frames.fold(0, maxMemberLengthHelper);
  longest = result.original.frames.fold(longest, maxMemberLengthHelper);
  for (var originalFrame in result.original.frames) {
    var deobfuscatedFrames = result.frameMap[originalFrame];
    if (deobfuscatedFrames == null) {
      var name = originalFrame.member;
      sb.writeln('    at ${name.padRight(longest)} ${originalFrame.location}');
    } else {
      for (var frame in deobfuscatedFrames) {
        var name = frame.member;
        // TODO(sigmund): eventually when ddc stops shipping source-maps to the
        // client, we can start encoding the function name and remove this
        // workaround.
        if (name == '<unknown>') name = originalFrame.member;
        sb.writeln('    at ${name.padRight(longest)} ${frame.location}');
      }
    }
  }
  return '$sb';
}
