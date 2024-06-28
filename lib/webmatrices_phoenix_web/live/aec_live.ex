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
        whois: nil,
        loading: %{
          whois: false
        }
      )

    {:ok, socket, layout: {WebmatricesPhoenixWeb.Layouts, :tool}}
  end

  def render(assigns) do
    ~H"""
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
          <.button phx-disable-with="Checking ..." class="w-min whitespace-nowrap">
            Check Eligibility
          </.button>
        </.form>
      </div>
    </div>

    <.icon :if={@loading.whois} name="hero-arrow-path" class="w-8 h-8 text-blue-500 animate-spin" />
    <div
      :if={!is_nil(@whois)}
      class="bg-neutral-50 p-4 w-full flex flex-col gap-2 justify-center items-center"
    >
      <div class="max-w-xl">
        <h1 class="font-mono text-2xl font-bold">Whois Lookup</h1>
        <div class="flex flex-col gap-2">
          <p class="font-mono text-lg font-bold">Domain: <%= @whois.domain %></p>
          <p class="font-mono text-lg font-bold">Registrar: <%= @whois.registrar %></p>
        </div>
      </div>
    </div>

    <pre class="bg-neutral-200 p-4 mb-2 mx-2 rounded-xl">
      <code class="font-extrabold text-2xl text-blue-500">@form:</code>
      <%= inspect(@form, pretty: true) %>
    </pre>
    <pre class="bg-neutral-200 p-4 mb-2 mx-2 rounded-xl">
      <code class="font-extrabold text-2xl text-blue-500">@whois:</code>
      <%= inspect(@whois, pretty: true) %>
    </pre>
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
            loading: %{whois: true}
          )
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "Changeset")

        {
          :noreply,
          assign(
            socket,
            form: action_form(changeset),
            loading: %{whois: false}
          )
        }
    end
  end

  def handle_info({:reset_form, changeset}, socket) do
    IO.puts("Reseting: #{inspect(changeset)}")

    {:noreply, assign(socket, form: action_form(changeset))}
  end

  def handle_info({:lookup, domain}, socket) do
    whois_info = AdsenseEligibilityCheck.get_lookup!(domain)

    case whois_info do
      %{error: reason} ->
        IO.puts("Lookup failed: #{reason}")

        {
          :noreply,
          socket
          |> put_flash(:error, "Lookup failed: #{reason}")
          |> update(:loading, fn loading -> Map.put(loading, :whois, false) end)
        }

      _ ->
        IO.puts("Lookup complete: #{inspect(whois_info)}")

        socket =
          assign(socket, whois: whois_info)
          |> update(:loading, fn loading -> Map.put(loading, :whois, false) end)

        {:noreply, socket}
    end
  end
end
