defmodule HelloTest do
  use MyTestCase, async: true

  import Foo, only: [foo: 1]

  alias MyApp.Event
  alias MyApp.Baz

  @tag database: true, superadministrator: true
  test "creates a baz", %{superadministrator: %{access_token: access_token, session: session}} do
    bar = MyApp.Factory.bar(access_token)

    wadus1 = MyApp.Factory.wadus(access_token, bar_id: bar.id)
    wadus2 = MyApp.Factory.wadus(access_token, bar_id: bar.id)
    wadus3 = MyApp.Factory.wadus(access_token, bar_id: bar.id)

    assert {:ok, bar} = MyApp.get_bar(access_token, id: bar.id)

    subbaz_content = "wadus #{wadus1.womo}"

    subbaz_womo = foo(subbaz_content)

    baz_content = """
    bar #{subbaz_womo}
    wadus #{wadus2.womo}
    wadus #{wadus3.womo}\
    """

    baz_womo = foo(baz_content)

    assert {{:ok, subbaz}, [event1]} =
             a(fn ->
               MyApp.put_baz(
                 access_token,
                 bar_id: bar.id,
                 womo: foo(subbaz_content),
                 baz: subbaz_content
               )
             end)

    assert {{:ok, baz}, [event2]} =
             a(fn ->
               MyApp.put_baz(
                 access_token,
                 bar_id: bar.id,
                 womo: baz_womo,
                 baz: baz_content
               )
             end)

    assert subbaz.__struct__ == Baz
    assert subbaz.bar_id == bar.id
    assert subbaz.womo == subbaz_womo
    assert subbaz.uri == "#{bar.uri}:baz:#{subbaz.womo}"
    assert subbaz.hululu == wadus1.hululu
    assert is_nil(subbaz.__baz__)

    assert baz.__struct__ == Baz
    assert baz.bar_id == bar.id
    assert baz.womo == baz_womo
    assert baz.uri == "#{bar.uri}:baz:#{baz.womo}"
    assert baz.hululu == wadus1.hululu + wadus2.hululu + wadus3.hululu
    assert is_nil(baz.__baz__)

    assert {:ok, ^bar} = MyApp.get_bar(access_token, id: bar.id)

    assert {:ok, ^subbaz_content} =
             MyApp.read_baz(
               access_token,
               bar_id: subbaz.bar_id,
               womo: subbaz.womo
             )

    assert {:ok, ^baz_content} =
             MyApp.read_baz(
               access_token,
               bar_id: baz.bar_id,
               womo: baz.womo
             )

    assert event1.__struct__ == Event
    assert event1.session_id == session.id
    assert event1.actor_id == session.user.id
    assert event1.requester_id == session.user.id
    assert event1.type == "baz:created"
    assert event1.streams == [subbaz.uri]

    assert event1.data == %{
             "bar_id" => subbaz.bar_id,
             "womo" => subbaz.womo,
             "uri" => subbaz.uri,
             "hululu" => subbaz.hululu,
             "created_at" => DateTime.to_iso8601(subbaz.created_at)
           }

    assert event1.metadata == %{}
    assert event1.timestamp == subbaz.created_at
    assert is_integer(event1.logical_timestamp)

    assert event2.__struct__ == Event
    assert event2.session_id == session.id
    assert event2.actor_id == session.user.id
    assert event2.requester_id == session.user.id
    assert event2.type == "baz:created"
    assert event2.streams == [baz.uri]

    assert event2.data == %{
             "bar_id" => baz.bar_id,
             "womo" => baz.womo,
             "uri" => baz.uri,
             "hululu" => baz.hululu,
             "created_at" => DateTime.to_iso8601(baz.created_at)
           }

    assert event2.metadata == %{}
    assert event2.timestamp == baz.created_at
    assert is_integer(event2.logical_timestamp)

    assert event1.logical_timestamp < event2.logical_timestamp
  end

  # defp a(_), do: :noop
end
