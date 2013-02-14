library java.engine;

import "dart:io";
import "java_core.dart";
import "source.dart";
import "error.dart";
import "ast.dart";
import "element.dart";

//class AnalysisException implements Exception {
//  String toString() => "AnalysisException";
//}

//class AnalysisEngine {
//  static getInstance() {
//    throw new UnsupportedOperationException();
//  }
//}

//class AnalysisContext {
//  Element getElement(ElementLocation location) {
//    throw new UnsupportedOperationException();
//  }
//}

//class AnalysisContextImpl extends AnalysisContext {
//  getSourceFactory() {
//    throw new UnsupportedOperationException();
//  }
//  LibraryElement getLibraryElementOrNull(Source source) {
//    return null;
//  }
//  LibraryElement getLibraryElement(Source source) {
//    throw new UnsupportedOperationException();
//  }
//  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
//    throw new UnsupportedOperationException();
//  }
//  getPublicNamespace(LibraryElement library) {
//    throw new UnsupportedOperationException();
//  }
//  CompilationUnit parse(Source source, AnalysisErrorListener errorListener) {
//    throw new UnsupportedOperationException();
//  }
//}

class StringUtilities {
  static List<String> EMPTY_ARRAY = new List.fixedLength(0);
}

File createFile(String path) => new File(path);

class OSUtilities {
  static bool isWindows() => Platform.operatingSystem == 'windows';
  static bool isMac() => Platform.operatingSystem == 'macos';
}