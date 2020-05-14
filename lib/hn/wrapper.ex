defmodule HN.Wrapper do
  alias HN.Api
  require Logger

  def get_item(id) do
    Api.get_item(id)
  end

  def get_user(id) do
    Api.get_user(id)
  end

  def get_items(ids) do
    Enum.map(ids, &get_item/1)
  end

  def get_items_async(ids) do
    ids
    |> Enum.map(fn id -> Task.async(fn -> get_item(id) end) end)
    |> Enum.map(fn x -> Task.await(x, 10000) end)
  end

  def get_items_async(ids, 0), do: get_items_async(ids)

  def get_items_async(ids, batch) do
    ids
    |> Enum.chunk_every(batch)
    |> Enum.map(fn l ->
      get_items_async(l)
    end)
    |> List.flatten()
  end

  def get_items_by_user(username, offset \\ 0, count \\ 0, batch \\ 0) do
    username
    |> get_user()
    |> extract_submitted_ids()
    |> get_items_sliced(offset, count, batch)
  end

  def get_comments_for_post(post, offset \\ 0, count \\ 0, batch \\ 100) do
    (post["kids"] || [])
    |> get_items_sliced(offset, count, batch)
    |> Enum.filter(&remove_unusuable/1)
  end

  @spec get_items_sliced(any, integer, non_neg_integer, non_neg_integer) :: [any]
  def get_items_sliced(ids, offset \\ 0, count \\ 0, batch \\ 0) do
    ids
    |> slice_offset(offset, count)
    |> get_items_async(batch)
    |> Enum.filter(&remove_deleted/1)
  end

  def get_posts_by_user(username, offset \\ 0, count \\ 0, batch \\ 100) do
    username
    |> get_items_by_user(offset, count, batch)
    |> Enum.filter(&filter_post/1)
  end

  defp extract_submitted_ids(%{"submitted" => submitted}), do: submitted
  defp extract_submitted_ids(_), do: []

  defp filter_post(%{"type" => type}), do: type != "comment"
  defp filter_post(_), do: false

  defp remove_deleted(%{"dead" => dead}), do: !dead
  defp remove_deleted(%{"deleted" => deleted}), do: !deleted
  defp remove_deleted(_), do: true

  defp remove_unusuable(%{"id" => id, "type" => type, "by" => by, "time" => time, "text" => text}) do
    !(is_nil(id) || is_nil(by) || is_nil(time) || is_nil(text)) && type == "comment"
  end

  defp remove_unusuable(_), do: false

  defp slice_offset(items, 0, 0), do: items
  defp slice_offset(items, offset, length), do: Enum.slice(items, offset, length)
end
