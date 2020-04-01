defmodule HN.State.Post do
  use GenServer
  require Logger

  @me __MODULE__
  def start_link(%{"id" => id} = post) do
    Logger.debug("Starting process for #{post["id"]}")
    GenServer.start_link(@me, post, name: get_pid_from_id(id))
  end

  def init(post) do
    state = %{
      post: post,
      comments: []
    }

    schedule_work(calculate_scheduler_time(post["time"]), post["id"])

    {:ok, state, {:continue, :load_comments}}
  end

  def get_comments(id, sort_by \\ {"id", :asc}) do
    id
    |> get_pid_from_id()
    |> GenServer.call(:get_comments, 10000)
    |> sort_items(sort_by)
  end

  def get_comments(id, offset, count, sort_by \\ {"id", :asc}) do
    pid = get_pid_from_id(id)

    get_comments(pid, sort_by)
    |> Enum.slice(offset, count)
  end

  def get_post(id) do
    pid = get_pid_from_id(id)
    GenServer.call(pid, :get_post)
  end

  def update(id) do
    pid = get_pid_from_id(id)
    GenServer.cast(pid, :update)
  end

  def handle_continue(:load_comments, %{post: post}) do
    new_post = HN.get_item(post["id"])
    comments = load_comments(new_post)
    new_state = %{post: new_post, comments: comments}
    Logger.debug("Got #{length(comments)} comments for #{post["id"]}")
    {:noreply, new_state}
  end

  def handle_continue(:update_comments, %{post: post, comments: comments}) do
    Logger.debug("Updating comments...")
    new_post = HN.get_item(post["id"])
    comment_diff = get_diff(new_post["kids"], post["kids"])
    Logger.debug("Got #{length(comment_diff)} new comments...")
    IO.inspect(comment_diff)
    new_comments = HN.get_items_async(comment_diff, 100)
    new_state = %{post: new_post, comments: new_comments ++ comments}
    {:noreply, new_state}
  end

  def handle_call(:get_comments, _from, state) do
    {:reply, state.comments, state}
  end

  def handle_call(:get_post, _from, state) do
    {:reply, state.post, state}
  end

  def handle_cast(:update, state) do
    {:noreply, state, {:continue, :update_comments}}
  end

  def handle_info(:work, %{post: post} = state) do
    %{"time" => time, "id" => id} = post
    Logger.debug("Executing scheduled work for #{id}...")
    schedule_work(calculate_scheduler_time(time), id)
    update(id)
    {:noreply, state}
  end

  def sort_items(comments, {:score, _}), do: comments

  def sort_items(comments, {type, :asc}) do
    Enum.sort(comments, &(&1[type] < &2[type]))
  end

  def sort_items(comments, {type, :desc}) do
    Enum.sort(comments, &(&1[type] >= &2[type]))
  end

  defp schedule_work(delay, id) do
    if delay > 0 do
      Logger.debug("#{id}: Scheduling work for #{delay} seconds")
      Process.send_after(self(), :work, delay)
    else
      Logger.debug("#{id}: no need to schedule")
    end
  end

  defp load_comments(post) do
    HN.get_comments_for_post(post)
  end

  defp get_pid_from_id(id), do: String.to_atom("#{id}")

  defp get_diff(current, old) do
    Enum.filter(current, fn item ->
      !Enum.any?(old, fn oldItem -> oldItem == item end)
    end)
  end

  defp calculate_scheduler_time(post_time) do
    # miliseconds
    second = 1000
    minute = 60 * second
    hour = 60 * minute
    day = 24 * hour
    week = 7 * day

    diff = (System.system_time(:second) - post_time) * second

    cond do
      diff < 3 * hour ->
        30 * second

      diff < 6 * hour ->
        minute

      diff < 3 * day ->
        10 * minute

      diff < 10 * day ->
        30 * minute

      diff < 4 * week ->
        hour

      diff > 4 * week ->
        0
    end
  end
end
