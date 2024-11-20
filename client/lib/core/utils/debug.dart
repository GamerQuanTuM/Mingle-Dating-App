// ignore_for_file: depend_on_referenced_packages

import 'dart:developer' as developer;
import 'package:ansi_styles/ansi_styles.dart';

abstract class Debug {
  // Primitive data types
  static void printString(String fileName, String value) {
    _log(fileName, 'String', AnsiStyles.green.call, value);
  }

  static void printInt(String fileName, int value) {
    _log(fileName, 'Int', AnsiStyles.blue.call, value.toString());
  }

  static void printDouble(String fileName, double value) {
    _log(fileName, 'Double', AnsiStyles.cyan.call, value.toString());
  }

  static void printBool(String fileName, bool value) {
    _log(fileName, 'Bool', AnsiStyles.magenta.call, value.toString());
  }

  // Non-primitive data types
  static void printList(String fileName, List value) {
    _log(fileName, 'List', AnsiStyles.yellow.call, value.toString());
  }

  static void printMap(String fileName, Map value) {
    _log(fileName, 'Map', AnsiStyles.red.call, value.toString());
  }

  static void printSet(String fileName, Set value) {
    _log(fileName, 'Set', AnsiStyles.gray.call, value.toString());
  }

  static void printClass(String fileName, Object instance) {
    _log(fileName, 'Class', AnsiStyles.bgBlue.call,
        '${instance.runtimeType}: ${instance.toString()}');
  }

  static void printFunction(String fileName, Function function) {
    _log(fileName, 'Function', AnsiStyles.bgGreen.call, function.toString());
  }

  static void printEnum(String fileName, Object enumValue) {
    _log(fileName, 'Enum', AnsiStyles.bgMagenta.call,
        '${enumValue.runtimeType}.${enumValue.toString().split('.').last}');
  }

  // Additional data types
  static void printSymbol(String fileName, Symbol value) {
    _log(fileName, 'Symbol', AnsiStyles.bgYellow.call, value.toString());
  }

  static void printIterable(String fileName, Iterable value) {
    _log(fileName, 'Iterable', AnsiStyles.bgCyan.call, value.toString());
  }

  static void printFuture(String fileName, Future value) {
    _log(fileName, 'Future', AnsiStyles.bgRed.call,
        'Future<${value.runtimeType}>');
    value
        .then((result) => print(fileName, result))
        .catchError((error) => print(fileName, error));
  }

  static void printStream(String fileName, Stream value) {
    _log(fileName, 'Stream', AnsiStyles.bgGreen.call,
        'Stream<${value.runtimeType}>');
  }

  static void printDuration(String fileName, Duration value) {
    _log(fileName, 'Duration', AnsiStyles.bgMagenta.call, value.toString());
  }

  static void printDateTime(String fileName, DateTime value) {
    _log(fileName, 'DateTime', AnsiStyles.bgBlue.call, value.toIso8601String());
  }

  static void printUri(String fileName, Uri value) {
    _log(fileName, 'Uri', AnsiStyles.bgCyan.call, value.toString());
  }

  static void printRegExp(String fileName, RegExp value) {
    _log(fileName, 'RegExp', AnsiStyles.bgYellow.call, value.pattern);
  }

  static void printNull(String fileName, value) {
    _log(fileName, 'Null', AnsiStyles.bgRed.call, 'null');
  }

  // Generic print method
  static void print(String fileName, dynamic value) {
    if (value == null) {
      printNull(fileName, value);
    } else if (value is String) {
      printString(fileName, value);
    } else if (value is int) {
      printInt(fileName, value);
    } else if (value is double) {
      printDouble(fileName, value);
    } else if (value is bool) {
      printBool(fileName, value);
    } else if (value is List) {
      printList(fileName, value);
    } else if (value is Map) {
      printMap(fileName, value);
    } else if (value is Set) {
      printSet(fileName, value);
    } else if (value is Symbol) {
      printSymbol(fileName, value);
    } else if (value is Iterable) {
      printIterable(fileName, value);
    } else if (value is Future) {
      printFuture(fileName, value);
    } else if (value is Stream) {
      printStream(fileName, value);
    } else if (value is Duration) {
      printDuration(fileName, value);
    } else if (value is DateTime) {
      printDateTime(fileName, value);
    } else if (value is Uri) {
      printUri(fileName, value);
    } else if (value is RegExp) {
      printRegExp(fileName, value);
    } else if (value is Function) {
      printFunction(fileName, value);
    } else if (value.runtimeType.toString().startsWith('_Enum')) {
      printEnum(fileName, value);
    } else {
      printClass(fileName, value);
    }
  }

  // Helper method for logging
  static void _log(String fileName, String type, String Function(String) style,
      String value) {
    developer.log(
        '[Filename = "$fileName"] ---> [datatype = ${AnsiStyles.bold.white(type)}]: [PRINT_LOG - ${style(value)}]');
  }
}
