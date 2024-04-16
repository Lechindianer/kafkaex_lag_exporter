defmodule KafkaexLagExporter.ConsumerOffsetFetcher.Test do
  use ExUnit.Case
  use Patch

  alias KafkaexLagExporter.ConsumerOffset

  @test_consumer_group_name1 "test_consumer_1"
  @test_consumer_group_name2 "test_consumer_2"
  @test_lags1 [{0, 23}, {1, 42}, {2, 666}]
  @test_lags2 [{0, 1}, {1, 2}, {2, 3}]
  @test_topic1 "test_topic_1"
  @test_topic2 "test_topic_2"
  @test_topic3 "test_topic_3"
  @test_consumer_id1 "test_consumer_id1"
  @test_consumer_id2 "test_consumer_id2"
  @test_member_host "127.0.0.1"

  setup do
    patch(
      KafkaexLagExporter.KafkaUtils,
      :get_consumer_group_names,
      fn _ -> [@test_consumer_group_name1, @test_consumer_group_name2] end
    )

    patch(KafkaexLagExporter.KafkaUtils, :lag, &lag(&1, &2, &3))

    patch(
      KafkaexLagExporter.KafkaUtils,
      :get_consumer_group_info,
      fn _, _, _ ->
        [
          {@test_consumer_group_name1, [@test_topic1, @test_topic2], @test_consumer_id1,
           @test_member_host},
          {@test_consumer_group_name2, [@test_topic3], @test_consumer_id2, @test_member_host}
        ]
      end
    )

    :ok
  end

  test "should return the calculated lags" do
    %{sum: sum, lags: lags} = KafkaexLagExporter.ConsumerOffsetFetcher.get({"test endpoint", 666})

    assert sum == [
             %ConsumerOffset{
               consumer_group: @test_consumer_group_name1,
               topic: @test_topic1,
               lag: {0, 731},
               consumer_id: @test_consumer_id1,
               member_host: @test_member_host
             },
             %ConsumerOffset{
               consumer_group: @test_consumer_group_name1,
               topic: @test_topic2,
               lag: {0, 6},
               consumer_id: @test_consumer_id1,
               member_host: @test_member_host
             },
             %ConsumerOffset{
               consumer_group: @test_consumer_group_name2,
               topic: @test_topic3,
               lag: {0, 6},
               consumer_id: @test_consumer_id2,
               member_host: @test_member_host
             }
           ]

    assert lags == [
             %ConsumerOffset{
               consumer_group: @test_consumer_group_name1,
               topic: @test_topic1,
               lag: @test_lags1,
               consumer_id: @test_consumer_id1,
               member_host: @test_member_host
             },
             %ConsumerOffset{
               consumer_group: @test_consumer_group_name1,
               topic: @test_topic2,
               lag: @test_lags2,
               consumer_id: @test_consumer_id1,
               member_host: @test_member_host
             },
             %ConsumerOffset{
               consumer_group: @test_consumer_group_name2,
               topic: @test_topic3,
               lag: @test_lags2,
               consumer_id: @test_consumer_id2,
               member_host: @test_member_host
             }
           ]
  end

  defp lag(@test_topic1, _, _), do: @test_lags1
  defp lag(_, _, _), do: @test_lags2
end
