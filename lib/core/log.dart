import 'dart:developer' as dev;

/// 结构化日志，对应 Android XJetLog。
class XJetLog {
  XJetLog._();

  static bool debug = true;
  static String tag = 'DartJet';

  static void init({bool enabled = true, String logTag = 'DartJet'}) {
    debug = enabled;
    tag = logTag;
  }

  static void v(String msg, [List<Object?> args = const []]) =>
      _log(msg, args, level: 0);
  static void d(String msg, [List<Object?> args = const []]) =>
      _log(msg, args, level: 1);
  static void i(String msg, [List<Object?> args = const []]) =>
      _log(msg, args, level: 2);
  static void w(String msg, [List<Object?> args = const []]) =>
      _log(msg, args, level: 3);
  static void e(String msg, [List<Object?> args = const []]) =>
      _log(msg, args, level: 4);

  static void json(String? text) {
    if (!debug || text == null || text.isEmpty) return;
    dev.log(_indentJson(text), name: tag);
  }

  static void xml(String? text) {
    if (!debug || text == null || text.isEmpty) return;
    dev.log(_indentXml(text), name: tag);
  }

  static void _log(String msg, List<Object?> args, {required int level}) {
    if (!debug) return;
    final rendered = args.isEmpty ? msg : _format(msg, args);
    dev.log(rendered, name: tag, level: level);
  }

  static String _format(String msg, List<Object?> args) {
    var result = msg;
    for (var i = 0; i < args.length; i++) {
      result = result.replaceFirst('{$i}', '${args[i]}');
    }
    return result;
  }

  static String _indentJson(String json) {
    final sb = StringBuffer();
    var depth = 0;
    var inString = false;
    for (var i = 0; i < json.length; i++) {
      final ch = json[i];
      if (ch == '"') {
        inString = !inString;
        sb.write(ch);
      } else if (inString) {
        sb.write(ch);
      } else {
        switch (ch) {
          case '{' || '[':
            sb.write(ch);
            sb.write('\n');
            depth++;
            sb.write('  ' * depth);
          case '}' || ']':
            depth--;
            sb.write('\n');
            sb.write('  ' * depth);
            sb.write(ch);
          case ',':
            sb.write(',\n');
            sb.write('  ' * depth);
          case ':':
            sb.write(': ');
          default:
            sb.write(ch);
        }
      }
    }
    return sb.toString();
  }

  static String _indentXml(String xml) {
    final sb = StringBuffer();
    var depth = 0;
    for (var i = 0; i < xml.length; i++) {
      final ch = xml[i];
      sb.write(ch);
      if (ch == '<' && i + 1 < xml.length) {
        if (xml[i + 1] != '/') {
          depth++;
          sb.write('\n');
          sb.write('  ' * depth);
        } else {
          depth--;
          sb.write('\n');
          sb.write('  ' * depth);
        }
      } else if (ch == '>') {
        sb.write('\n');
        sb.write('  ' * depth);
      }
    }
    return sb.toString().trim();
  }
}
