import 'dart:math';

/// 日常工具，对应 Android Kits（去掉了 Android 专属的 packageManager 能力）。
class Kits {
  Kits._();

  static final Random _random = Random();

  static String randomString(int length, {String alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'}) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  static int randomInt(int min, int max) {
    if (max <= min) return min;
    return min + _random.nextInt(max - min + 1);
  }

  static bool isToday(DateTime time, {DateTime? now}) {
    final date = now ?? DateTime.now();
    return time.year == date.year &&
        time.month == date.month &&
        time.day == date.day;
  }

  static String formatDate(DateTime time, {String pattern = 'yyyy-MM-dd HH:mm:ss'}) {
    String two(int v) => v.toString().padLeft(2, '0');
    return pattern
        .replaceAll('yyyy', time.year.toString())
        .replaceAll('MM', two(time.month))
        .replaceAll('dd', two(time.day))
        .replaceAll('HH', two(time.hour))
        .replaceAll('mm', two(time.minute))
        .replaceAll('ss', two(time.second));
  }
}
