// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_signature.dart';
import 'package:analysis_server/src/computer/computer_type_arguments_signature.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

class CiderSignatureHelpComputer {
  final FileResolver _fileResolver;

  CiderSignatureHelpComputer(this._fileResolver);

  SignatureHelpResponse? compute(String filePath, int line, int column) {
    var resolvedUnit = _fileResolver.resolve(path: filePath);
    var lineInfo = resolvedUnit.lineInfo;
    var offset = lineInfo.getOffsetOfLine(line) + column;
    final formats = <MarkupKind>{MarkupKind.Markdown};

    var dartDocInfo = DartdocDirectiveInfo();
    final typeArgsComputer = DartTypeArgumentsSignatureComputer(
        dartDocInfo, resolvedUnit.unit, offset, formats);
    if (typeArgsComputer.offsetIsValid) {
      final typeSignature = typeArgsComputer.compute();

      if (typeSignature != null) {
        return SignatureHelpResponse(typeSignature,
            lineInfo.getLocation(typeArgsComputer.argumentList.offset + 1));
      }
    }

    final computer =
        DartUnitSignatureComputer(dartDocInfo, resolvedUnit.unit, offset);
    if (computer.offsetIsValid) {
      final signature = computer.compute();
      if (signature != null) {
        return SignatureHelpResponse(toSignatureHelp(formats, signature),
            lineInfo.getLocation(computer.argumentList.offset + 1));
      }
    }
    return null;
  }
}

class SignatureHelpResponse {
  final SignatureHelp signatureHelp;

  /// The location of the left parenthesis.
  final CharacterLocation callStart;

  SignatureHelpResponse(this.signatureHelp, this.callStart);
}
