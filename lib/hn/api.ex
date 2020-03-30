defmodule HN.Api do
  @baseUrl "https://hacker-news.firebaseio.com/v0"

  def get_item(id), do: make_request(build_url("item", id))

  def get_user(username), do: make_request(build_url("user", username))

  def get_top(), do: make_request(build_url("topstories"))
  def get_new(), do: make_request(build_url("newstories"))
  def get_best(), do: make_request(build_url("beststories"))
  def get_asks(), do: make_request(build_url("askstories"))
  def get_shows(), do: make_request(build_url("showstories"))
  def get_jobs(), do: make_request(build_url("jobstories"))
  def get_maxitem(), do: make_request(build_url("maxitem"))

  defp make_request(url) do
    case Mojito.request(:get, url) do
      {:ok, response} ->
        {:ok, data} = Jason.decode(response.body)
        data

      {:error, data} ->
        IO.inspect(url)
        {:error, data}
    end
  end

  defp build_url(type), do: "#{@baseUrl}/#{type}.json"
  defp build_url(type, id), do: "#{@baseUrl}/#{type}/#{id}.json"
end
