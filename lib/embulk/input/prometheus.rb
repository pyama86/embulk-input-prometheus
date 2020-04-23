require 'prometheus/api_client'
require 'openssl'
require 'json'
require 'pp'

module Embulk
  module Input

    class Prometheus < InputPlugin
      Plugin.register_input("prometheus", self)
      def self.transaction(config, &control)
        task = {
          "url" => config.param("url", :string, default: 'http://localhost:9090/api/v1/'),
          "query" => config.param("query", :string),
          "since" => config.param("since", :integer),
          "step" => config.param("step", :integer),
          "element_key" => config.param("element_key", :string, default: 'instance'),
          "tls" => config.param("tls", :hash, default: nil),
          "token" => config.param("token", :string,  default: nil),
          "timeout" => config.param("timeout", :interger, default: 60),
          "open_timeout" => config.param("open_timeout", :interger, default: 10),
        }

        columns = [
          Column.new(0, "name", :string),
          Column.new(1, "time", :double),
          Column.new(2, "value", :double),
        ]

        resume(task, columns, 1, &control)
      end

      def self.resume(task, columns, count, &control)
        task_reports = yield(task, columns, count)

        next_config_diff = {}
        return next_config_diff
      end

      def run
        params = {
          url: task['url'],
          options: {},
          ssl: {},
          credentials: {},
        }

        params[:ssl][:client_cert] = OpenSSL::X509::Certificate.new(File.read(task["tls"]["cert_path"])) if task["tls"]["cert_path"]
        params[:ssl][:client_key] = OpenSSL::PKey::RSA.new(File.read(task["tls"]["key_path"])) if task["tls"]["key_path"]
        params[:ssl][:ca_file] = task["tls"]["ca_path"] if task["tls"]["ca_path"]

        params[:credentials][:token] = task["token"] if task["token"]

        %w(
          open_timeout
          timeout
        ).each do |n|
          params[:options][n.to_sym] =  task[n] if task[n]
        end

        prometheus = ::Prometheus::ApiClient.client(params)
        result = JSON.parse(prometheus.get(
          'query_range',
          query: task['query'],
          start: (Time.now - task['since']).strftime("%Y-%m-%dT%H:%M:%S.%LZ"),
          end:   Time.now.strftime("%Y-%m-%dT%H:%M:%S.%LZ"),
          step:  "#{task['step']}s",
        ).body)

        if result['status'] == 'success'
          result['data']['result'].each do |r|
            r["values"].each do |v|
              page_builder.add([r["metric"][task["element_key"]], v[0], v[1]])
            end
          end
        end
        page_builder.finish
        task_report = {}
        return task_report
      end
    end
  end
end
