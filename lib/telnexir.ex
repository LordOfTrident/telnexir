defmodule Telnexir do
	@moduledoc false

	use Application

	@impl true
	def start(_type, port: port) do
		children = [
			{Telnexir.Server, port}
		]

		opts = [strategy: :one_for_one, name: Telnexir.Supervisor]
		Supervisor.start_link(children, opts)
	end
end
