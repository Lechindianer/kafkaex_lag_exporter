defmodule KafkaexLagExporterTopicNameParserTest do
  use ExUnit.Case
  doctest KafkaexLagExporter.TopicNameParser

  test "should parse single topic" do
    test_member_assignment =
      <<0, 0, 0, 0, 0, 1, 0, 17, 111, 119, 108, 115, 104, 111, 112, 45, 99, 117, 115, 116, 111,
        109, 101, 114, 115, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0,
        4, 0>>

    assert KafkaexLagExporter.TopicNameParser.parse_topic_names(test_member_assignment) == [
             "owlshop-customers"
           ]
  end

  test "should parse multiple topics" do
    test_member_assignment =
      <<0, 1, 0, 0, 0, 31, 0, 42, 102, 111, 111, 95, 54, 50, 100, 54, 97, 99, 99, 54, 48, 55, 57,
        56, 48, 101, 49, 50, 52, 54, 49, 54, 100, 98, 55, 99, 0, 0, 0, 1, 0, 0, 0, 1, 0, 42, 102,
        111, 111, 95, 54, 51, 54, 52, 102, 57, 51, 49, 101, 54, 100, 50, 97, 51, 102, 48, 56, 99,
        49, 97, 100, 54, 100, 52, 0, 0, 0, 1, 0, 0, 0, 1, 0, 42, 102, 111, 111, 95, 54, 51, 51,
        50, 101, 100, 56, 49, 48, 57, 100, 101, 48, 48, 98, 52, 51, 55, 49, 57, 49, 57, 48, 56>>

    assert KafkaexLagExporter.TopicNameParser.parse_topic_names(test_member_assignment) == [
             "foo_62d6acc607980e124616db7c",
             "foo_6364f931e6d2a3f08c1ad6d4",
             "foo_6332ed8109de00b437191908"
           ]
  end
end
