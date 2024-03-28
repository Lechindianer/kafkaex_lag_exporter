defmodule KafkaexLagExporter.ConsumerOffsetFetcher.Test do
  use ExUnit.Case
  use Patch

  @test_consumer_group_name1 "test_consumer_1"
  @test_consumer_group_name2 "test_consumer_2"
  @test_lags1 [{0, 23}, {1, 42}, {2, 666}]
  @test_lags2 [{0, 1}, {1, 2}, {2, 3}]
  @test_topic1 "test_topic_1"
  @test_topic2 "test_topic_2"
  @test_topic3 "test_topic_3"

  setup do
    patch(
      KafkaexLagExporter.KafkaUtils,
      :get_consumer_group_names,
      fn _ -> [@test_consumer_group_name1, @test_consumer_group_name2] end
    )

    patch(KafkaexLagExporter.KafkaUtils, :lag, &lag(&1, &2, &3))

    patch(
      KafkaexLagExporter.KafkaUtils,
      :topic_names_for_consumer_groups,
      fn _, _, _ ->
        [
          {@test_consumer_group_name1, [@test_topic1, @test_topic2]},
          {@test_consumer_group_name2, [@test_topic3]}
        ]
      end
    )

    :ok
  end

  test "should return the calculated lags" do
    test_endpoint = {"test endpoint", 666}

    %{sum: sum, lags: lags} = KafkaexLagExporter.ConsumerOffsetFetcher.get(test_endpoint)

    assert sum == [
             {@test_consumer_group_name1, @test_topic1, 731},
             {@test_consumer_group_name1, @test_topic2, 6},
             {@test_consumer_group_name2, @test_topic3, 6}
           ]

    assert lags == [
             {@test_consumer_group_name1, @test_topic1, @test_lags1},
             {@test_consumer_group_name1, @test_topic2, @test_lags2},
             {@test_consumer_group_name2, @test_topic3, @test_lags2}
           ]
  end

  defp lag(@test_topic1, _, _), do: @test_lags1
  defp lag(_, _, _), do: @test_lags2
end
