# Copyright 2016 Google Inc. All rights reserved.
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

describe Google::Cloud::Bigquery::Dataset, :query_job, :named_params, :mock_bigquery do
  let(:query) { "SELECT name, age, score, active, create_date, update_timestamp FROM [some_project:some_dataset.users]" }

  let(:dataset_id) { "my_dataset" }
  let(:dataset) { Google::Cloud::Bigquery::Dataset.from_gapi dataset_gapi, bigquery.service }

  let(:query_job_gapi) do
    Google::Apis::BigqueryV2::Job.from_json(query_job_json("SELECT * FROM tbl")).tap do |r|
      r.configuration.query.default_dataset = Google::Apis::BigqueryV2::DatasetReference.new(dataset_id: dataset_id, project_id: project)
      r.configuration.query.use_legacy_sql = false
      r.configuration.query.parameter_mode = "NAMED"
    end
  end
  let(:dataset_gapi) { random_dataset_gapi dataset_id }

  it "queries the data with a string parameter" do
    query_job_gapi.configuration.query.query = "#{query} WHERE name = @name"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "name",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "STRING"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: "Testy McTesterson"
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE name = @name", params: { name: "Testy McTesterson" }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with an integer parameter" do
    query_job_gapi.configuration.query.query = "#{query} WHERE age > @age"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "age",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "INT64"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: 35
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE age > @age", params: { age: 35 }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with a float parameter" do
    query_job_gapi.configuration.query.query = "#{query} WHERE score > @score"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "score",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "FLOAT64"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: 90.0
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE score > @score", params: { score: 90.0 }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with a true parameter" do
    query_job_gapi.configuration.query.query = "#{query} WHERE active = @active"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "active",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "BOOL"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: true
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE active = @active", params: { active: true }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with a false parameter" do
    query_job_gapi.configuration.query.query = "#{query} WHERE active = @active"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "active",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "BOOL"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: false
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE active = @active", params: { active: false }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with a date parameter" do
    today = Date.today

    query_job_gapi.configuration.query.query = "#{query} WHERE create_date = @date"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "date",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "DATE"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: today.to_s
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE create_date = @date", params: { date: today }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with a time parameter" do
    now = Time.now

    query_job_gapi.configuration.query.query = "#{query} WHERE update_timestamp < @time"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "time",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "TIMESTAMP"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: now.strftime("%Y-%m-%d %H:%M:%S.%3N%:z")
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE update_timestamp < @time", params: { time: now }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with many parameters" do
    today = Date.today
    now = Time.now

    query_job_gapi.configuration.query.query = "#{query} WHERE name = @name" +
                                                       " AND age > @age" +
                                                       " AND score > @score" +
                                                       " AND active = @active" +
                                                       " AND create_date = @date" +
                                                       " AND update_timestamp < @time"

    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "name",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "STRING"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: "Testy McTesterson"
        )
      ),
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "age",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "INT64"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: 35
        )
      ),
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "score",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "FLOAT64"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: 90.0
        )
      ),
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "active",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "BOOL"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: true
        )
      ),
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "date",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "DATE"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: today.to_s
        )
      ),
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "time",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "TIMESTAMP"
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          value: now.strftime("%Y-%m-%d %H:%M:%S.%3N%:z")
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE name = @name" +
                                     " AND age > @age" +
                                     " AND score > @score" +
                                     " AND active = @active" +
                                     " AND create_date = @date" +
                                     " AND update_timestamp < @time",
                          params: { name: "Testy McTesterson",
                                    age: 35,
                                    score: 90.0,
                                    active: true,
                                    date: today,
                                    time: now }


    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with an array parameter" do
    query_job_gapi.configuration.query.query = "#{query} WHERE name IN @names"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "names",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "ARRAY",
          array_type: Google::Apis::BigqueryV2::QueryParameterType.new(
            type: "STRING"
          )
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          array_values: [
            Google::Apis::BigqueryV2::QueryParameterValue.new(value: "name1"),
            Google::Apis::BigqueryV2::QueryParameterValue.new(value: "name2"),
            Google::Apis::BigqueryV2::QueryParameterValue.new(value: "name3")
          ]
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE name IN @names", params: { names: %w{name1 name2 name3} }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end

  it "queries the data with a struct parameter" do
    query_job_gapi.configuration.query.query = "#{query} WHERE meta = @meta"
    query_job_gapi.configuration.query.query_parameters = [
      Google::Apis::BigqueryV2::QueryParameter.new(
        name: "meta",
        parameter_type: Google::Apis::BigqueryV2::QueryParameterType.new(
          type: "STRUCT",
          struct_types: [
            Google::Apis::BigqueryV2::QueryParameterType::StructType.new(
              name: "name",
              type: Google::Apis::BigqueryV2::QueryParameterType.new(type: "STRING")),
            Google::Apis::BigqueryV2::QueryParameterType::StructType.new(
              name: "age",
              type: Google::Apis::BigqueryV2::QueryParameterType.new(type: "INT64")),
            Google::Apis::BigqueryV2::QueryParameterType::StructType.new(
              name: "active",
              type: Google::Apis::BigqueryV2::QueryParameterType.new(type: "BOOL")),
            Google::Apis::BigqueryV2::QueryParameterType::StructType.new(
              name: "score",
              type: Google::Apis::BigqueryV2::QueryParameterType.new(type: "FLOAT64"))
          ]
        ),
        parameter_value: Google::Apis::BigqueryV2::QueryParameterValue.new(
          struct_values: [
            Google::Apis::BigqueryV2::QueryParameterValue.new(value: "Testy McTesterson"),
            Google::Apis::BigqueryV2::QueryParameterValue.new(value: 42),
            Google::Apis::BigqueryV2::QueryParameterValue.new(value: false),
            Google::Apis::BigqueryV2::QueryParameterValue.new(value: 98.7)
          ]
        )
      )
    ]

    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :insert_job, query_job_gapi, [project, query_job_gapi]

    job = dataset.query_job "#{query} WHERE meta = @meta", params: { meta: { name: "Testy McTesterson", age: 42, active: false, score: 98.7 } }
    mock.verify

    job.must_be_kind_of Google::Cloud::Bigquery::QueryJob
  end
end
