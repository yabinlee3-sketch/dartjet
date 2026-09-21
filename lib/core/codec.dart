import 'dart:convert' as conv;
import 'package:crypto/crypto.dart' as crypto;

/// 摘要与编码工具，对应 Android Codec。
class Codec {
  Codec._();

  static String md5(String data) =>
      crypto.md5.convert(conv.utf8.encode(data)).toString();

  static String sha1(String data) =>
      crypto.sha1.convert(conv.utf8.encode(data)).toString();

  static String sha256(String data) =>
      crypto.sha256.convert(conv.utf8.encode(data)).toString();

  static String base64Encode(List<int> bytes) => conv.base64Encode(bytes);

  static List<int> base64Decode(String code) => conv.base64Decode(code);
}
