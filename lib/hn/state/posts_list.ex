defmodule HN.State.PostsList do
  use GenServer
  alias HN.State.Post
  require Logger

  @me __MODULE__

  def start_link(params \\ []) do
    GenServer.start_link(@me, params, name: @me)
  end

  # Callbacks

  def init(posts) do
    state = %{posts: posts, new_posts: []}
    schedule_work()
    {:ok, state, {:continue, :load_posts}}
  end

  def get_posts() do
    GenServer.call(@me, :get_posts)
  end

  def get_latest_post() do
    get_posts() |> Enum.at(0)
  end

  def update() do
    GenServer.cast(@me, :update)
  end

  def handle_continue(:load_posts, state) do
    posts = load_posts()
    new_posts = get_diff(posts, state.posts)
    Logger.debug("Got #{length(posts)} Who is hiring posts")
    {:noreply, %{posts: posts, new_posts: new_posts}, {:continue, :expand_posts}}
  end

  def handle_continue(:expand_posts, state) do
    state.new_posts
    |> Enum.map(fn post -> %{id: post["id"], start: {Post, :start_link, [post]}} end)
    |> Supervisor.start_link(strategy: :one_for_one)

    {:noreply, state}
  end

  def handle_cast(:update, state) do
    {:noreply, state, {:continue, :load_posts}}
  end

  def handle_call(:get_posts, _from, state), do: {:reply, state.posts, state}

  def handle_info(:work, state) do
    Logger.debug("Scheduled posts check...")
    schedule_work()
    update()
    {:noreply, state}
  end

  # defaults to 1 hour
  defp schedule_work(time \\ 60 * 60 * 1000) do
    Process.send_after(self(), :work, time)
  end

  defp load_posts() do
    "whoishiring"
    |> HN.get_posts_by_user(0, 10)
    |> filter_hiring_posts()
    |> Enum.slice(0, 3)
  end

  defp filter_hiring_posts(posts) do
    posts
    |> Enum.filter(fn post ->
      String.contains?(post["title"], "Ask HN: Who is hiring")
    end)
  end

  def get_diff(current, old) do
    Enum.filter(current, fn item ->
      !Enum.any?(old, fn oldItem -> oldItem["id"] == item["id"] end)
    end)
  end
end
