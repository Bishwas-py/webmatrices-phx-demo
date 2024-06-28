defmodule WebmatricesPhoenixWeb.AecLive do
  use WebmatricesPhoenixWeb, :live_view

  alias WebmatricesPhoenix.AdsenseEligibilityCheck
  alias WebmatricesPhoenix.Sites.Site

  def mount(_params, _session, socket) do
    changeset = AdsenseEligibilityCheck.change_aec(%Site{})

    socket =
      assign(
        socket,
        form: to_form(changeset),
        whois: %{
          loading: false
        },
        loading: false
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <%= inspect(@form, pretty: true) %>
    <%= inspect(@whois, pretty: true) %>
    <div class="bg-neutral-50 p-4 w-full flex flex-col gap-2 justify-center items-center">
      <div class="max-w-xl">
        <h1 class="font-mono text-2xl font-bold">Adsense Eligibility Checker</h1>
        <.form phx-change="validate" for={@form} phx-submit="submit" class="flex flex-col gap-2">
          <.input
            field={@form[:url]}
            phx-debounce="500"
            phx-keydown="validate"
            phx-key="ctrl-v"
            class="w-full"
            placeholder="Enter your website URL"
          />
          <.button phx-disable-with="Saving..." class="w-min">Save</.button>
        </.form>
      </div>
    </div>
    """
  end

  def action_form(%Ecto.Changeset{} = changeset) do
    to_form(%{changeset | action: :insert})
  end

  def handle_event("validate", %{"site" => site_params}, socket) do
    changeset = AdsenseEligibilityCheck.change_aec(%Site{}, site_params)
    socket = assign(socket, form: action_form(changeset))
    {:noreply, socket}
  end

  def handle_event("submit", %{"site" => site_params}, socket) do
    case AdsenseEligibilityCheck.get_adsense_eligibility_check!(site_params) do
      {:ok, result} ->
        send(self(), {:reset_form, result.changeset})
        send(self(), {:lookup, result.domain})

        {
          :noreply,
          assign(
            socket,
            loading: true,
            whois: %{loading: true}
          )
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "Changeset")

        {
          :noreply,
          assign(
            socket,
            whois: %{loading: false},
            form: action_form(changeset),
            loading: false
          )
        }
    end
  end

  def handle_info({:reset_form, changeset}, socket) do
    IO.puts("Reseting: #{inspect(changeset)}")

    {:noreply, assign(socket, form: action_form(changeset))}
  end

  def handle_info({:lookup, domain}, socket) do
    whois_info =
      AdsenseEligibilityCheck.get_lookup!(domain)
      |> Map.put(:loading, false)

    case whois_info do
      %{error: reason} ->
        IO.puts("Lookup failed: #{reason}")

        {
          :noreply,
          socket
          |> put_flash(:error, "Lookup failed: #{reason}")
        }

      _ ->
        IO.puts("Lookup complete: #{inspect(whois_info)}")
        {:noreply, assign(socket, whois: whois_info, loading: false)}
    end
  end
end
