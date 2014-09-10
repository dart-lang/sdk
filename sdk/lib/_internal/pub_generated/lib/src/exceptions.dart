library pub.exceptions;
import 'dart:io';
import 'dart:isolate';
import "package:analyzer/analyzer.dart";
import "package:http/http.dart" as http;
import "package:stack_trace/stack_trace.dart";
import "package:yaml/yaml.dart";
import '../../asset/dart/serialize.dart';
class ApplicationException implements Exception {
  final String message;
  ApplicationException(this.message);
  String toString() => message;
}
class FileException implements ApplicationException {
  final String message;
  final String path;
  FileException(this.message, this.path);
  String toString() => message;
}
class WrappedException extends ApplicationException {
  final innerError;
  final Chain innerChain;
  WrappedException(String message, this.innerError, [StackTrace innerTrace])
      : innerChain = innerTrace == null ? null : new Chain.forTrace(innerTrace),
        super(message);
}
class SilentException extends WrappedException {
  SilentException(innerError, [StackTrace innerTrace])
      : super(innerError.toString(), innerError, innerTrace);
}
class UsageException extends ApplicationException {
  String _usage;
  UsageException(String message, this._usage) : super(message);
  String toString() => "$message\n\n$_usage";
}
class DataException extends ApplicationException {
  DataException(String message) : super(message);
}
class PackageNotFoundException extends WrappedException {
  PackageNotFoundException(String message, [innerError, StackTrace innerTrace])
      : super(message, innerError, innerTrace);
}
final _userFacingExceptions = new Set<String>.from(
    [
        'ApplicationException',
        'GitException',
        'ClientException',
        'AnalyzerError',
        'AnalyzerErrorGroup',
        'IsolateSpawnException',
        'CertificateException',
        'FileSystemException',
        'HandshakeException',
        'HttpException',
        'IOException',
        'ProcessException',
        'RedirectException',
        'SignalException',
        'SocketException',
        'StdoutException',
        'TlsException',
        'WebSocketException']);
bool isUserFacingException(error) {
  if (error is CrossIsolateException) {
    return _userFacingExceptions.contains(error.type);
  }
  return error is ApplicationException ||
      error is AnalyzerError ||
      error is AnalyzerErrorGroup ||
      error is IsolateSpawnException ||
      error is IOException ||
      error is http.ClientException ||
      error is YamlException;
}
