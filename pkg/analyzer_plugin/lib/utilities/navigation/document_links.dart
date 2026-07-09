// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/src/utilities/navigation/document_links.dart'
    show DocumentLink;

// Re-export a class that was here before but moved to src.
export 'package:analyzer_plugin/src/utilities/navigation/document_links.dart'
    show DartDocumentLinkVisitor, DocumentLink;

// Export a typedef with the old name for this class.
typedef DartdocumentLink = DocumentLink;
