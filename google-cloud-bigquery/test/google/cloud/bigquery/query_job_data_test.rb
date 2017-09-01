# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a extract of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Google::Cloud::Bigquery::QueryJob, :data, :mock_bigquery do
  let(:query_request) {
    qrg = query_request_gapi
    qrg.default_dataset = nil
    qrg.query = "SELECT * FROM test-project:my_dataset.my_view"
    qrg
  }
  let(:dataset_id) { "target_dataset_id" }
  let(:table_id) { "target_table_id" }
  let(:job) { Google::Cloud::Bigquery::Job.from_gapi query_job_gapi,
                                              bigquery.service }
  let(:job_id) { job.job_id }

  it "can retrieve query results" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: nil }]

    job.must_be :done?
    data = job.data
    mock.verify

    data.class.must_equal Google::Cloud::Bigquery::Data
    data.count.must_equal 3
    data[0].must_be_kind_of Hash
    data[0][:name].must_equal "Heidi"
    data[0][:age].must_equal 36
    data[0][:score].must_equal 7.65
    data[0][:active].must_equal true
    data[0][:avatar].must_be_kind_of StringIO
    data[0][:avatar].read.must_equal "image data"
    data[0][:started_at].must_equal Time.parse("2016-12-25 13:00:00 UTC")
    data[0][:duration].must_equal Google::Cloud::Bigquery::Time.new("04:00:00")
    data[0][:target_end].must_equal Time.parse("2017-01-01 00:00:00 UTC").to_datetime
    data[0][:birthday].must_equal Date.parse("1968-10-20")

    data[1].must_be_kind_of Hash
    data[1][:name].must_equal "Aaron"
    data[1][:age].must_equal 42
    data[1][:score].must_equal 8.15
    data[1][:active].must_equal false
    data[1][:avatar].must_equal nil
    data[1][:started_at].must_equal nil
    data[1][:duration].must_equal Google::Cloud::Bigquery::Time.new("04:32:10.555555")
    data[1][:target_end].must_equal nil
    data[1][:birthday].must_equal nil

    data[2].must_be_kind_of Hash
    data[2][:name].must_equal "Sally"
    data[2][:age].must_equal nil
    data[2][:score].must_equal nil
    data[2][:active].must_equal nil
    data[2][:avatar].must_equal nil
    data[2][:started_at].must_equal nil
    data[2][:duration].must_equal nil
    data[2][:target_end].must_equal nil
    data[2][:birthday].must_equal nil
    end

  it "can retrieve query results when it already has destination_schema" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: nil }]

    job.instance_variable_set :@destination_schema_gapi, query_data_gapi.schema

    job.must_be :done?
    data = job.data
    mock.verify

    data.class.must_equal Google::Cloud::Bigquery::Data
    data.count.must_equal 3
    data[0].must_be_kind_of Hash
    data[0][:name].must_equal "Heidi"
    data[0][:age].must_equal 36
    data[0][:score].must_equal 7.65
    data[0][:active].must_equal true
    data[0][:avatar].must_be_kind_of StringIO
    data[0][:avatar].read.must_equal "image data"
    data[0][:started_at].must_equal Time.parse("2016-12-25 13:00:00 UTC")
    data[0][:duration].must_equal Google::Cloud::Bigquery::Time.new("04:00:00")
    data[0][:target_end].must_equal Time.parse("2017-01-01 00:00:00 UTC").to_datetime
    data[0][:birthday].must_equal Date.parse("1968-10-20")

    data[1].must_be_kind_of Hash
    data[1][:name].must_equal "Aaron"
    data[1][:age].must_equal 42
    data[1][:score].must_equal 8.15
    data[1][:active].must_equal false
    data[1][:avatar].must_equal nil
    data[1][:started_at].must_equal nil
    data[1][:duration].must_equal Google::Cloud::Bigquery::Time.new("04:32:10.555555")
    data[1][:target_end].must_equal nil
    data[1][:birthday].must_equal nil

    data[2].must_be_kind_of Hash
    data[2][:name].must_equal "Sally"
    data[2][:age].must_equal nil
    data[2][:score].must_equal nil
    data[2][:active].must_equal nil
    data[2][:avatar].must_equal nil
    data[2][:started_at].must_equal nil
    data[2][:duration].must_equal nil
    data[2][:target_end].must_equal nil
    data[2][:birthday].must_equal nil
  end

  it "paginates data" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: nil }]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: "token1234567890", start_index: nil }]

    data1 = job.data

    data1.class.must_equal Google::Cloud::Bigquery::Data
    data1.token.wont_be :nil?
    data1.token.must_equal "token1234567890"
    data2 = job.data token: data1.token
    data2.class.must_equal Google::Cloud::Bigquery::Data
    mock.verify
  end

  it "paginates data using next? and next" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: nil }]
    mock.expect :list_table_data,
                table_data_gapi(token: nil),
                [project, dataset_id, table_id, {  max_results: nil, page_token: "token1234567890", start_index: nil }]

    data1 = job.data

    data1.class.must_equal Google::Cloud::Bigquery::Data
    data1.token.wont_be :nil?
    data1.next?.must_equal true # can't use must_be :next?
    data2 = data1.next
    data2.token.must_be :nil?
    data2.next?.must_equal false
    data2.class.must_equal Google::Cloud::Bigquery::Data
    mock.verify
  end

  it "paginates data using all" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: nil }]
    mock.expect :list_table_data,
                table_data_gapi(token: nil),
                [project, dataset_id, table_id, {  max_results: nil, page_token: "token1234567890", start_index: nil }]

    data = job.data.all.to_a

    data.count.must_equal 6
    data.each { |d| d.class.must_equal Hash }
    mock.verify
  end

  it "iterates data using all" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: nil }]
    mock.expect :list_table_data,
                table_data_gapi(token: nil),
                [project, dataset_id, table_id, {  max_results: nil, page_token: "token1234567890", start_index: nil }]

    data = job.data

    data.all { |d| d.class.must_equal Hash }
    mock.verify
  end

  it "iterates data using all using Enumerator" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: nil }]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: "token1234567890", start_index: nil }]

    data = job.data.all.take(5)

    data.count.must_equal 5
    data.each { |d| d.class.must_equal Hash }
    mock.verify
  end

  it "iterates data using all with request_limit set" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: nil }]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: "token1234567890", start_index: nil }]

    data = job.data.all(request_limit: 1).to_a

    data.count.must_equal 6
    data.each { |d| d.class.must_equal Hash }
    mock.verify
  end

  it "paginates data with max set" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: 3, page_token: nil, start_index: nil }]

    data = job.data max: 3
    data.class.must_equal Google::Cloud::Bigquery::Data
  end

  it "paginates data with start set" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :get_job_query_results,
                query_data_gapi,
                [project, job.job_id, {max_results: 0, page_token: nil, start_index: nil, timeout_ms: nil}]
    mock.expect :list_table_data,
                table_data_gapi,
                [project, dataset_id, table_id, {  max_results: nil, page_token: nil, start_index: 25 }]

    data = job.data start: 25
    mock.verify

    data.class.must_equal Google::Cloud::Bigquery::Data
  end

  def query_job_gapi
    Google::Apis::BigqueryV2::Job.from_json query_job_hash.to_json
  end

  def query_job_hash
    hash = random_job_hash("job9876543210", "done")
    hash["configuration"]["query"] = {
      "query" => "SELECT name, age, score, active FROM `users`",
      "destinationTable" => {
        "projectId" => project,
        "datasetId" => "target_dataset_id",
        "tableId"   => "target_table_id"
      },
      "tableDefinitions" => {},
      "createDisposition" => "CREATE_IF_NEEDED",
      "writeDisposition" => "WRITE_EMPTY",
      "defaultDataset" => {
        "datasetId" => "my_dataset",
        "projectId" => project
      },
      "priority" => "BATCH",
      "allowLargeResults" => true,
      "useQueryCache" => true,
      "flattenResults" => true,
      "useLegacySql" => false,
      "maximumBillingTier" => nil,
      "maximumBytesBilled" => nil
    }
    hash
  end

  def table_data_gapi token: "token1234567890"
    Google::Apis::BigqueryV2::TableDataList.from_json table_data_hash(token: token).to_json
  end

  def table_data_hash token: "token1234567890"
    {
      "kind" => "bigquery#tableDataList",
      "etag" => "etag1234567890",
      "rows" => random_data_rows,
      "pageToken" => token,
      "totalRows" => "3" # String per google/google-api-ruby-client#439
    }
  end

  def nil_table_data_gapi
    Google::Apis::BigqueryV2::TableDataList.from_json nil_table_data_json
  end

  def nil_table_data_json
    h = table_data_hash
    h.delete "rows"
    h.to_json
  end
end
