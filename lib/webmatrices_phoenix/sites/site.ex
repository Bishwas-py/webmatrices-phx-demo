defmodule WebmatricesPhoenix.Sites.Site do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :url, :string
  end

  @site ~r/^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/
  def changeset(site, attrs) do
    site
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> validate_format(:url, @site, message: "must be a valid site")
  end

  def domain(url) do
    url = URI.parse(url)

    url.authority
  end

  def validate_domain(%Ecto.Changeset{valid?: true, changes: %{url: url}} = changeset) do
    IO.inspect(url, label: "URL")
    domain = domain(url)
    {:ok, %{domain: domain, changeset: changeset}}
  end

  def validate_domain(%Ecto.Changeset{valid?: false} = changeset) do
    IO.inspect(changeset, label: "Errors")
    {:error, changeset}
  end
end
