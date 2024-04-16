defmodule KafkaexLagExporter.KafkaUtils.Test do
  use ExUnit.Case
  use Patch

  alias KafkaexLagExporter.KafkaWrapper.Behaviour, as: KafkaWrapper
  alias KafkaexLagExporter.KafkaUtils

  @test_endpoint {"test_host", "1234"}
  @test_sock_opts [ssl: []]
  @test_group_name1 "test-consumer_group1"
  @test_group_name2 "test-consumer_group"
  @test_topic_name "test-topic_name"

  setup do
    patch(
      KafkaUtils,
      :connection,
      fn _ -> {@test_endpoint, @test_sock_opts} end
    )

    :ok
  end

  describe "get_consumer_group_names" do
    setup do
      consumer_info1 = {:a, @test_group_name1, "consumer"}
      consumer_info2 = {:b, @test_group_name2, "something-other"}

      patch(KafkaWrapper, :list_all_groups, fn _, _ ->
        [{@test_endpoint, [consumer_info1, consumer_info2]}]
      end)

      group_names = KafkaUtils.get_consumer_group_names(@test_endpoint)

      [group_names: group_names]
    end

    test "should list all groups" do
      assert_called(KafkaWrapper.list_all_groups([@test_endpoint], []))
    end

    test "should filter for consumer groups and return names", context do
      assert context[:group_names] === [@test_group_name1]
    end
  end

  describe "get_consumer_group_info" do
    setup do
      consumer_group_name = "test-group-id1"
      member_assignment = "test_member_assignment"
      member_assignment = "test_member_assignment"
      consumer_id = "test_consumer_id"
      member_host = "test_member_host"

      patch(KafkaWrapper, :describe_groups, fn _, _, _ ->
        {
          :ok,
          [
            %{
              group_id: consumer_group_name,
              members: [
                %{
                  client_host: member_host,
                  member_assignment: member_assignment,
                  member_id: consumer_id
                }
              ]
            }
          ]
        }
      end)

      patch(KafkaexLagExporter.TopicNameParser, :parse_topic_names, fn _ -> [@test_topic_name] end)

      group_info =
        KafkaUtils.get_consumer_group_info(@test_endpoint, [], [
          @test_group_name1,
          @test_group_name2
        ])

      [
        member_host: member_host,
        group_info: group_info,
        consumer_group_name: consumer_group_name,
        member_assignment: member_assignment,
        consumer_id: consumer_id
      ]
    end

    test "should describe groups" do
      assert_called(
        KafkaWrapper.describe_groups(@test_endpoint, [], [@test_group_name1, @test_group_name2])
      )
    end

    test "should parse topic names", context do
      expected_member_assignment = context[:expected_member_assignment]

      assert_called(
        KafkaexLagExporter.TopicNameParser.parse_topic_names(expected_member_assignment)
      )
    end

    test "should filter for consumer groups and return names", context do
      expected_consumer_group_name = context[:consumer_group_name]
      expected_consumer_id = context[:consumer_id]
      expected_member_host = context[:member_host]

      assert context[:group_info] === [
               {
                 expected_consumer_group_name,
                 [@test_topic_name],
                 expected_consumer_id,
                 expected_member_host
               }
             ]
    end
  end

  describe "lag" do
    setup do
      consumer_group = "test-consumer-group"
      client = :client1
      committed_offset1 = 23
      committed_offset2 = 42
      resolved_offset = 50

      partition_info1 = %{partition_index: 0, committed_offset: committed_offset1}
      partition_info2 = %{partition_index: 1, committed_offset: committed_offset2}

      patch(KafkaWrapper, :get_partitions_count, fn _, _ -> {:ok, 2} end)

      patch(KafkaWrapper, :resolve_offset, fn _, _, _, _, _ -> {:ok, resolved_offset} end)

      patch(KafkaWrapper, :fetch_committed_offsets, fn _, _, _ ->
        {:ok, [%{name: "test name", partitions: [partition_info1, partition_info2]}]}
      end)

      lag = KafkaUtils.lag(@test_topic_name, consumer_group, client)

      [
        lag: lag,
        consumer_group: consumer_group,
        client: client,
        committed_offset1: committed_offset1,
        committed_offset2: committed_offset2,
        resolved_offset: resolved_offset
      ]
    end

    test "should start connection", context do
      expected_client = context[:client]

      assert_called(KafkaUtils.connection(expected_client))
    end

    test "should get partition count", context do
      expected_client = context[:client]

      assert_called(KafkaWrapper.get_partitions_count(expected_client, @test_topic_name))
    end

    test "should resolve offsets for each partition" do
      assert_called(
        KafkaWrapper.resolve_offset(@test_endpoint, @test_topic_name, 0, :latest, @test_sock_opts)
      )

      assert_called(
        KafkaWrapper.resolve_offset(@test_endpoint, @test_topic_name, 1, :latest, @test_sock_opts)
      )
    end

    test "should fetch committed offsets", context do
      expected_consumer_group = context[:consumer_group]

      assert_called(
        KafkaWrapper.fetch_committed_offsets(
          @test_endpoint,
          @test_sock_opts,
          expected_consumer_group
        )
      )
    end

    test "should return calculated lag per partition", context do
      expected_lag_partition_1 = context[:resolved_offset] - context[:committed_offset1]
      expected_lag_partition_2 = context[:resolved_offset] - context[:committed_offset2]

      assert context[:lag] === [
               {0, expected_lag_partition_1},
               {1, expected_lag_partition_2}
             ]
    end
  end
end
