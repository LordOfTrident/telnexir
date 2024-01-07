defmodule Telnexir.Server do
	use GenServer
	require Logger

	@cmd_prefix "@"
	@help       "\n-- COMMANDS --\n@help, @time\n\n"
	@welcome    "Hello, client!\n" <> @help

	def start_link(port) do
		GenServer.start_link(__MODULE__, port, name: __MODULE__)
	end

	def init(port) do
		{:ok, socket} = :gen_tcp.listen(port, [
			:binary,
			packet:    :line,
			active:    false,
			reuseaddr: true,
		])

		Logger.info("Accepting connections on port #{port}")
		loop_acceptor(socket)
	end

	defp loop_acceptor(socket) do
		{:ok, client} = :gen_tcp.accept(socket)

		Logger.info("Connection from #{client |> socket_ip}")
		:gen_tcp.send(client, @welcome)
		Task.start_link(fn -> client |> serve end)

		loop_acceptor(socket)
	end

	defp serve(client) do
		ip = client |> socket_ip

		case client |> read_line do
			:closed -> Logger.info("Connection from #{ip} closed")
			input   ->
				response = input
					|> String.trim
					|> process(client)

				:gen_tcp.send(client, response)
				serve(client)
		end
	end

	defp read_line(socket) do
		case :gen_tcp.recv(socket, 0) do
			{:ok, data} -> data
			{:error, :closed} -> :closed
		end
	end

	defp process(@cmd_prefix <> cmd, _client) do
		case cmd do
			"help"  -> @help
			"time"  -> "#{System.os_time}\n"
			unknown -> "Error: Unknown command \"#{@cmd_prefix <> unknown}\""
		end
	end

	defp process(msg, client) do
		Logger.info("Echoing message from #{client |> socket_ip}: #{msg}")
		"Echoing: #{msg}\n"
	end

	defp socket_ip(socket) do
		{:ok, {ip, _}} = :inet.peername(socket)
		ip |> Tuple.to_list |> Enum.join(".")
	end
end
