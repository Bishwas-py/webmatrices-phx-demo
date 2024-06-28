defmodule WebmatricesPhoenix.AdsenseEligibilityCheck do
  alias WebmatricesPhoenix.Sites.Site
  alias Whois

  def change_aec(%Site{} = site, attrs \\ %{}) do
    site
    |> Site.changeset(attrs)
  end

  def get_adsense_eligibility_check!(attr \\ %{}) do
    %Site{}
    |> Site.changeset(attr)
    |> IO.inspect(label: "Changeset")
    |> Site.validate_domain()
  end

  def get_lookup!(domain) do
    IO.puts("Looking up domain: #{domain}")

    case Whois.lookup(domain) do
      {:ok, result} ->
        IO.puts("Lookup complete: #{inspect(result)}")
        result

      {:error, reason} ->
        IO.puts("Lookup failed: #{reason}")
        %{error: reason}
    end
  end
end
