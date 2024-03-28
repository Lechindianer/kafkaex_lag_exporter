defmodule KafkaexLagExporter.ConsumerOffsetFetcher.Test do
  use ExUnit.Case
  use Patch

  @test_consumer_group_name1 "test_consumer_1"
  @test_consumer_group_name2 "test_consumer_2"
  @test_lags [{0, 23}, {1, 42}, {2, 666}]

  setup do
    patch(
      KafkaexLagExporter.KafkaUtils,
      :get_consumer_group_names,
      fn _ -> [@test_consumer_group_name1, @test_consumer_group_name2] end
    )

    patch(KafkaexLagExporter.KafkaUtils, :lag, fn _, _, _ -> @test_lags end)

    patch(
      KafkaexLagExporter.KafkaUtils,
      :topic_names_for_consumer_groups,
      fn _, _, _ ->
        [
          {@test_consumer_group_name1, ["test_topic_1", "test_topic_2"]},
          {@test_consumer_group_name2, ["test_topic_3"]}
        ]
      end
    )

    :ok
  end

  test "should return the calculated lags" do
    test_endpoint = {"test endpoint", 666}

    %{sum: sum, lags: lags} = KafkaexLagExporter.ConsumerOffsetFetcher.get(test_endpoint)

    assert sum == [
             {@test_consumer_group_name1, 1462},
             {@test_consumer_group_name2, 731}
           ]

    assert lags == [
             {@test_consumer_group_name1, @test_lags ++ @test_lags},
             {@test_consumer_group_name2, @test_lags}
           ]
  end
end
