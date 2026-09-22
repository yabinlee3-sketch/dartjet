/// 新闻模型，对应 Android xjet-news-demo 的 NewsItem。
class NewsItem {
  final int id;
  final String title;
  final String by;
  final int score;
  final int comments;
  final String url;

  const NewsItem({
    required this.id,
    required this.title,
    this.by = '',
    this.score = 0,
    this.comments = 0,
    this.url = '',
  });

  factory NewsItem.fromJson(Map<String, dynamic> json, int id) {
    return NewsItem(
      id: id,
      title: json['title'] as String? ?? '',
      by: json['by'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      comments: json['descendants'] as int? ?? 0,
      url: (json['url'] as String? ?? '').isEmpty
          ? 'https://news.ycombinator.com/item?id=$id'
          : json['url'] as String,
    );
  }
}
