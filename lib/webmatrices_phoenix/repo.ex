defmodule WebmatricesPhoenix.Repo do
  use Ecto.Repo,
    otp_app: :webmatrices_phoenix,
    adapter: Ecto.Adapters.Postgres
end
