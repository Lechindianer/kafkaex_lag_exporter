defmodule KafkaexLagExporter.KafkaUtils.Test do
  use ExUnit.Case
  use Patch

  alias KafkaexLagExporter.KafkaWrapper.Behaviour, as: KafkaWrapper
  alias KafkaexLagExporter.KafkaUtils

  @test_endpoint "test_host:1234"
  @test_consumer_group "test-consumer-group"
  @test_sock_opts [ssl: []]

  setup do
    patch(
      KafkaUtils,
      :connection,
      fn _ -> {@test_endpoint, @test_sock_opts} end
    )

    :ok
  end

  describe "resolve_offsets" do
    setup do
      client = :client2
      topic = "test-topic"

      patch(
        KafkaWrapper,
        :get_partitions_count,
        fn _, _ -> {:ok, 3} end
      )

      patch(
        KafkaWrapper,
        :resolve_offset,
        fn _, _, _, _, _ -> {:ok, 42} end
      )

      offsets = KafkaUtils.resolve_offsets(topic, :earliest, client)

      [client: client, offsets: offsets, topic: topic]
    end

    test "should get partition count", context do
      expected_topic = context[:topic]
      expected_client = context[:client]

      assert_called(KafkaWrapper.get_partitions_count(expected_client, expected_topic))
    end

    test "should resolve offset per partition", context do
      expected_topic = context[:topic]

      assert_called(
        KafkaWrapper.resolve_offset(@test_endpoint, expected_topic, 0, :earliest, @test_sock_opts)
      )

      assert_called(
        KafkaWrapper.resolve_offset(@test_endpoint, expected_topic, 1, :earliest, @test_sock_opts)
      )

      assert_called(
        KafkaWrapper.resolve_offset(@test_endpoint, expected_topic, 2, :earliest, @test_sock_opts)
      )
    end

    test "should return offsets", context do
      assert context[:offsets] == [{0, 42}, {1, 42}, {2, 42}]
    end
  end

  describe "fetch_committed_offsets" do
    setup do
      partition_info1 = %{partition_index: 0, committed_offset: 23}
      partition_info2 = %{partition_index: 1, committed_offset: 42}

      patch(
        KafkaWrapper,
        :fetch_committed_offsets,
        fn _, _, _ ->
          {:ok, [%{name: "test name", partitions: [partition_info1, partition_info2]}]}
        end
      )

      offsets = KafkaUtils.fetch_committed_offsets("test-topic", @test_consumer_group, :test_atom)

      [offsets: offsets]
    end

    test "should get the committed offsets from KafkaWrapper" do
      assert_called(
        KafkaWrapper.fetch_committed_offsets(
          @test_endpoint,
          @test_sock_opts,
          @test_consumer_group
        )
      )
    end

    test "should return offsets", context do
      assert context[:offsets] == [{0, 23}, {1, 42}]
    end
  end
end
