defmodule Hades.Cerberus.Soul do
  defstruct name: nil, description: nil, start: nil, stop: nil, restart: nil,
    stop_timeout: nil, os_pid: nil, pid: nil, state: nil, timer: :infinity, pid_file: nil,
    metrics: nil
end
