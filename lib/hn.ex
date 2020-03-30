defmodule HN do
  alias HN.Wrapper

  alias HN.State.PostsList
  alias HN.State.Post

  defdelegate get_item(id), to: Wrapper
  defdelegate get_items_async(id, batch \\ 0), to: Wrapper

  defdelegate get_posts_by_user(username, offset \\ 0, count \\ 0), to: Wrapper
  defdelegate get_posts_by_user(username, offset, count, batch), to: Wrapper
  defdelegate get_comments_for_post(post, offset \\ 0, count \\ 0), to: Wrapper
  defdelegate get_comments_for_post(post, offset, count, batch), to: Wrapper

  defdelegate get_posts(), to: PostsList
  defdelegate get_latest_post(), to: PostsList

  defdelegate get_comments(id), to: Post
  defdelegate get_comments(id, sort_by), to: Post
  defdelegate get_comments(id, offset, count), to: Post
  defdelegate get_comments(id, offset, count, sort_by), to: Post
end
