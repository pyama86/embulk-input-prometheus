require 'prometheus/api_client'
require 'openssl'
require 'json'
require 'pp'
require 'time'

module Embulk
  module Input

    class Prometheus < InputPlugin
      Plugin.register_input("prometheus", self)
      def self.transaction(config, &control)
        task = {
          "url" => config.param("url", :string, default: 'http://localhost:9090/api/v1/'),
          "query" => config.param("query", :string),
          "since" => config.param("since", :integer, default: 0),
          "start_at" => config.param("start_at", :string, default: nil),
          "end_at" => config.param("end_at", :string, default: nil),
          "step" => config.param("step", :integer),
          "element_key" => config.param("element_key", :string, default: 'instance'),
          "tls" => config.param("tls", :hash, default: nil),
          "token" => config.param("token", :string,  default: nil),
          "timeout" => config.param("timeout", :interger, default: 60),
          "open_timeout" => config.param("open_timeout", :interger, default: 10),
        }

        columns = [
          Column.new(0, "name", :string),
          Column.new(1, "time", :long),
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

        if task["tls"]
          params[:ssl][:client_cert] = OpenSSL::X509::Certificate.new(File.read(task["tls"]["cert_path"])) if task["tls"]["cert_path"]
          params[:ssl][:client_key] = OpenSSL::PKey::RSA.new(File.read(task["tls"]["key_path"])) if task["tls"]["key_path"]
          params[:ssl][:ca_file] = task["tls"]["ca_path"] if task["tls"]["ca_path"]
        end
        params[:credentials][:token] = task["token"] if task["token"]

        %w(
          open_timeout
          timeout
        ).each do |n|
          params[:options][n.to_sym] =  task[n] if task[n]
        end

        start_at = if task['start_at'] && !task['start_at'].empty?
                     Time.parse(task['start_at'])
                   else
                     Time.now - task['since']
                   end
        end_at   = if task['end_at'] && !task['end_at'].empty?
                     Time.parse(task['end_at'])
                   else
                     Time.now
                   end

        result = JSON.parse(::Prometheus::ApiClient.client(params).get(
          'query_range',
          query: task['query'],
          start: start_at.strftime("%Y-%m-%dT%H:%M:%S.%LZ"),
          end:   end_at.strftime("%Y-%m-%dT%H:%M:%S.%LZ"),
          step:  "#{task['step']}s",
        ).body)

        result['data']['result'].each do |r|
          r["values"].each do |v|
            page_builder.add([r["metric"][task["element_key"]], v[0], v[1]])
          end
        end if result['status'] == 'success'

        page_builder.finish
        task_report = {}
        return task_report
      end
    end
  end
end
