//
// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'dart pkg/analyzer/tool/messages/generate.dart' to update.

part of 'syntactic_errors.dart';

final fastaAnalyzerErrorCodes = <ErrorCode>[
  null,
  _EQUALITY_CANNOT_BE_EQUALITY_OPERAND,
  _CONTINUE_OUTSIDE_OF_LOOP,
  _EXTERNAL_CLASS,
  _STATIC_CONSTRUCTOR,
  _EXTERNAL_ENUM,
];

const ParserErrorCode _CONTINUE_OUTSIDE_OF_LOOP = const ParserErrorCode(
    'CONTINUE_OUTSIDE_OF_LOOP',
    "A continue statement can't be used outside of a loop or switch statement.",
    correction: "Try removing the continue statement.");

const ParserErrorCode _EQUALITY_CANNOT_BE_EQUALITY_OPERAND = const ParserErrorCode(
    'EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
    "An equality expression can't be an operand of another equality expression.",
    correction: "Try re-writing the expression.");

const ParserErrorCode _EXTERNAL_CLASS = const ParserErrorCode(
    'EXTERNAL_CLASS', "Classes can't be declared to be 'external'.",
    correction: "Try removing the keyword 'external'.");

const ParserErrorCode _EXTERNAL_ENUM = const ParserErrorCode(
    'EXTERNAL_ENUM', "Enums can't be declared to be 'external'.",
    correction: "Try removing the keyword 'external'.");

const ParserErrorCode _STATIC_CONSTRUCTOR = const ParserErrorCode(
    'STATIC_CONSTRUCTOR', "Constructors can't be static.",
    correction: "Try removing the keyword 'static'.");
