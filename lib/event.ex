defmodule MyApp.Event do
  defstruct [
    :id,
    :session_id,
    :actor_id,
    :requester_id,
    :streams,
    :type,
    :data,
    :metadata,
    :timestamp,
    :logical_timestamp,
    :created_at
  ]
end
