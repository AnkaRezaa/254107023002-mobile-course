import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'providers.dart';

final postDetailProvider =
    AsyncNotifierProvider.family<PostDetailNotifier, Post, int>(
  PostDetailNotifier.new,
);

class PostDetailNotifier extends AsyncNotifier<Post> {
  PostDetailNotifier(this.postId);

  final int postId;

  @override
  Future<Post> build() async {
    final loadedPosts = ref.read(postListProvider).maybeWhen(
          data: (posts) => posts,
          orElse: () => null,
        );

    if (loadedPosts != null) {
      for (final post in loadedPosts) {
        if (post.id == postId) {
          return post;
        }
      }
    }

    return ref.read(postRepositoryProvider).fetchPost(postId);
  }
}