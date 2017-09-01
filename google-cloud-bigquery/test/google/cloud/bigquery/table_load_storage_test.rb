# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a load of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Google::Cloud::Bigquery::Table, :load, :storage, :mock_bigquery do
  let(:credentials) { OpenStruct.new }
  let(:storage) { Google::Cloud::Storage::Project.new(Google::Cloud::Storage::Service.new(project, credentials)) }
  let(:load_bucket_gapi) { Google::Apis::StorageV1::Bucket.from_json random_bucket_hash.to_json }
  let(:load_bucket) { Google::Cloud::Storage::Bucket.from_gapi load_bucket_gapi, storage.service }
  let(:load_file) { storage_file }
  let(:load_url) { load_file.to_gs_url }

  let(:dataset) { "dataset" }
  let(:table_id) { "table_id" }
  let(:table_name) { "Target Table" }
  let(:description) { "This is the target table" }
  let(:table_hash) { random_table_hash dataset, table_id, table_name, description }
  let(:table_gapi) { Google::Apis::BigqueryV2::Table.from_json table_hash.to_json }
  let(:table) { Google::Cloud::Bigquery::Table.from_gapi table_gapi, bigquery.service }
  let(:labels) { { "foo" => "bar" } }

  def storage_file path = nil
    gapi = Google::Apis::StorageV1::Object.from_json random_file_hash(load_bucket.name, path).to_json
    Google::Cloud::Storage::File.from_gapi gapi, storage.service
  end

  it "can specify a storage file" do
    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, load_url
    mock.expect :insert_job, load_job_resp_gapi(table, load_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load load_file
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can specify a storage file with format" do
    special_file = storage_file "data.json"
    special_url = special_file.to_gs_url

    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, special_url
    job_gapi.configuration.load.source_format = "CSV"
    mock.expect :insert_job, load_job_resp_gapi(table, special_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load special_file, format: :csv
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can specify a storage file and derive CSV format" do
    special_file = storage_file "data.csv"
    special_url = special_file.to_gs_url

    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, special_url
    job_gapi.configuration.load.source_format = "CSV"
    mock.expect :insert_job, load_job_resp_gapi(table, special_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load special_file
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can specify a storage file and derive CSV format with CSV options" do
    special_file = storage_file "data.csv"
    special_url = special_file.to_gs_url

    mock = Minitest::Mock.new
    job_gapi = load_job_csv_options_gapi table_gapi.table_reference
    job_gapi.configuration.load.source_uris = [special_url]
    mock.expect :insert_job, load_job_resp_gapi(table, special_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load special_file, jagged_rows: true, quoted_newlines: true,
      encoding: "ISO-8859-1", delimiter: "\t", ignore_unknown: true, max_bad_records: 42,
      quote: "'", skip_leading: 1
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can specify a storage file and derive Avro format" do
    special_file = storage_file "data.avro"
    special_url = special_file.to_gs_url

    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, special_url
    job_gapi.configuration.load.source_format = "AVRO"
    mock.expect :insert_job, load_job_resp_gapi(table, special_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load special_file
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can specify a storage file and derive Datastore backup format" do
    special_file = storage_file "data.backup_info"
    special_url = special_file.to_gs_url

    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, special_url
    job_gapi.configuration.load.source_format = "DATASTORE_BACKUP"
    mock.expect :insert_job, load_job_resp_gapi(table, special_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load special_file
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can load a Datastore backup file and specify projection fields" do
    special_file = storage_file "data.backup_info"
    special_url = special_file.to_gs_url
    projection_fields = ["first_name"]

    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, special_url
    job_gapi.configuration.load.source_format = "DATASTORE_BACKUP"
    job_gapi.configuration.load.projection_fields = projection_fields
    mock.expect :insert_job, load_job_resp_gapi(table, special_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load special_file, projection_fields: projection_fields
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can specify a storage url" do
    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, load_url
    mock.expect :insert_job, load_job_resp_gapi(table, load_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load load_url
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can load itself as a dryrun" do
    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, load_url
    job_gapi.configuration.dry_run = true
    mock.expect :insert_job, load_job_resp_gapi(table, load_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load load_url, dryrun: true
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can load itself with create disposition" do
    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, load_url
    job_gapi.configuration.load.create_disposition = "CREATE_NEVER"
    mock.expect :insert_job, load_job_resp_gapi(table, load_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load load_url, create: "CREATE_NEVER"
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can load itself with create disposition symbol" do
    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, load_url
    job_gapi.configuration.load.create_disposition = "CREATE_NEVER"
    mock.expect :insert_job, load_job_resp_gapi(table, load_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load load_url, create: :never
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can load itself with write disposition" do
    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, load_url
    job_gapi.configuration.load.write_disposition = "WRITE_TRUNCATE"
    mock.expect :insert_job, load_job_resp_gapi(table, load_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load load_url, write: "WRITE_TRUNCATE"
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can load itself with write disposition symbol" do
    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, load_url
    job_gapi.configuration.load.write_disposition = "WRITE_TRUNCATE"
    mock.expect :insert_job, load_job_resp_gapi(table, load_url),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load load_url, write: :truncate
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob

    mock.verify
  end

  it "can load a storage file with the job labels option" do
    mock = Minitest::Mock.new
    job_gapi = load_job_url_gapi table_gapi.table_reference, load_url
    job_gapi.configuration.labels = labels
    mock.expect :insert_job, load_job_resp_gapi(table, load_url, labels: labels),
      [project, job_gapi]
    table.service.mocked_service = mock

    job = table.load load_file, labels: labels
    job.must_be_kind_of Google::Cloud::Bigquery::LoadJob
    job.labels.must_equal labels

    mock.verify
  end

  def load_job_resp_gapi table, load_url, job_id: "job_9876543210", labels: nil
    hash = random_job_hash job_id
    hash["configuration"]["load"] = {
      "sourceUris" => [load_url],
      "destinationTable" => {
        "projectId" => table.project_id,
        "datasetId" => table.dataset_id,
        "tableId" => table.table_id
      },
    }
    resp = Google::Apis::BigqueryV2::Job.from_json hash.to_json
    resp.configuration.labels = labels if labels
    resp
  end

  # Borrowed from MockStorage, load to a common module?

  def random_bucket_hash name=random_bucket_name
    {"kind"=>"storage#bucket",
     "id"=>name,
     "selfLink"=>"https://www.googleapis.com/storage/v1/b/#{name}",
     "projectNumber"=>"1234567890",
     "name"=>name,
     "timeCreated"=>::Time.now,
     "metageneration"=>"1",
     "owner"=>{"entity"=>"project-owners-1234567890"},
     "location"=>"US",
     "storageClass"=>"STANDARD",
     "etag"=>"CAE=" }
  end

  def random_file_hash bucket=random_bucket_name, name=random_file_path
    {"kind"=>"storage#object",
     "id"=>"#{bucket}/#{name}/1234567890",
     "selfLink"=>"https://www.googleapis.com/storage/v1/b/#{bucket}/o/#{name}",
     "name"=>"#{name}",
     "bucket"=>"#{bucket}",
     "generation"=>"1234567890",
     "metageneration"=>"1",
     "contentType"=>"text/plain",
     "updated"=>::Time.now,
     "storageClass"=>"STANDARD",
     "size"=>rand(10_000),
     "md5Hash"=>"HXB937GQDFxDFqUGi//weQ==",
     "mediaLink"=>"https://www.googleapis.com/download/storage/v1/b/#{bucket}/o/#{name}?generation=1234567890&alt=media",
     "owner"=>{"entity"=>"user-1234567890", "entityId"=>"abc123"},
     "crc32c"=>"Lm1F3g==",
     "etag"=>"CKih16GjycICEAE="}
  end

  def random_bucket_name
    (0...50).map { ("a".."z").to_a[rand(26)] }.join
  end

  def random_file_path
    [(0...10).map { ("a".."z").to_a[rand(26)] }.join,
     (0...10).map { ("a".."z").to_a[rand(26)] }.join,
     (0...10).map { ("a".."z").to_a[rand(26)] }.join + ".txt"].join "/"
  end
end
