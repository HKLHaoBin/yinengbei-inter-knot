import 'package:inter_knot/helpers/normalize_markdown.dart';
import 'package:inter_knot/helpers/parse_html.dart';
import 'package:inter_knot/helpers/use.dart';
import 'package:inter_knot/models/author.dart';

class CommentModel {
  final AuthorModel author;
  final String bodyHTML;
  final DateTime createdAt;
  final DateTime? lastEditedAt;
  final replies = <CommentModel>{};
  final String id;
  final String url;

  CommentModel({
    required this.author,
    required this.bodyHTML,
    required this.createdAt,
    required this.lastEditedAt,
    required Iterable<CommentModel> replies,
    required this.id,
    required this.url,
  }) {
    this.replies.addAll(replies);
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // 处理 content 字段（可能是 Markdown 或 HTML）
    final content =
        json['content'] as String? ?? json['bodyHTML'] as String? ?? '';
    final normalized = normalizeMarkdown(content);
    final (:cover, :html) = parseHtml(normalized, true);

    final repliesData = json['replies'];
    final repliesList = <CommentModel>[];
    if (repliesData is List) {
      for (final r in repliesData) {
        if (r is Map<String, dynamic>) {
          repliesList.add(CommentModel.fromJson(r));
        }
      }
    } else if (repliesData is Map<String, dynamic>) {
      // Handle Strapi v5 relation response if it's not a list directly but wrapped
      // or if it's a single object (unlikely for oneToMany but possible)
      // Usually relations come as List in JSON if populated
    }

    return CommentModel(
      author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      bodyHTML: html,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastEditedAt:
          (json['updatedAt'] as String?).use((v) => DateTime.parse(v)),
      replies: repliesList,
      id: (json['documentId'] as String?) ?? json['id']?.toString() ?? '',
      url: '', // URL not supported yet
    );
  }

  @override
  bool operator ==(Object other) => other is CommentModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
