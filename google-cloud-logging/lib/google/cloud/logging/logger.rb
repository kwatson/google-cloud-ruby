# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require "orderedhash"

module Google
  module Cloud
    module Logging
      ##
      # # Logger
      #
      # A (mostly) API-compatible logger for ruby's Logger.
      #
      # @example
      #   require "google/cloud/logging"
      #
      #   logging = Google::Cloud::Logging.new
      #
      #   resource = logging.resource "gae_app",
      #                               module_id: "1",
      #                               version_id: "20150925t173233"
      #
      #   logger = logging.logger "my_app_log", resource, env: :production
      #   logger.info "Job started."
      #
      class Logger
        ##
        # The Google Cloud writer object that calls to {#write_entries} are made
        # on. Either an AsyncWriter or Project object.
        attr_reader :writer

        ##
        # The Google Cloud log_name to write the log entry with.
        attr_reader :log_name

        ##
        # The Google Cloud resource to write the log entry with.
        attr_reader :resource

        ##
        # The Google Cloud labels to write the log entry with.
        attr_reader :labels

        ##
        # A OrderedHash of Thread IDs to Stackdriver request trace ID. The
        # Stackdriver trace ID is a shared request identifier across all
        # Stackdriver services.
        attr_reader :trace_ids

        attr_reader :level

        ##
        # Create a new Logger instance.
        #
        # @param [#write_entries] writer The object that will transmit log
        #   entries. Generally, to create a logger that blocks on transmitting
        #   log entries, pass the Project; otherwise, to create a logger that
        #   transmits log entries in the background, pass an AsyncWriter. You
        #   may also pass any other object that responds to #write_entries.
        # @param [String] log_name A log resource name to be associated with the
        #   written log entries.
        # @param [Google::Cloud::Logging::Resource] resource The monitored
        #   resource to be associated with written log entries.
        # @param [Hash] labels A set of user-defined data to be associated with
        #   written log entries.
        #
        # @return [Google::Cloud::Logging::Logger] a Logger object that can be
        #   used in place of a ruby standard library logger object.
        #
        # @example
        #   require "google/cloud/logging"
        #
        #   logging = Google::Cloud::Logging.new
        #
        #   writer = logging.async_writer max_queue_size: 1000
        #
        #   resource = logging.resource "gae_app", labels: {
        #                                 "module_id" => "1",
        #                                 "version_id" => "20150925t173233" }
        #                               }
        #
        #   logger = Google::Cloud::Logging::Logger.new writer,
        #                                               "my_app_log",
        #                                               resource,
        #                                               env: :production
        #   logger.info "Job started."
        #
        def initialize writer, log_name, resource, labels = nil
          @writer = writer
          @log_name = log_name
          @resource = resource
          @labels = labels
          @level = 0 # DEBUG is the default behavior
          @trace_ids = OrderedHash.new
        end

        def formatter
          ActiveSupport::Logger::Formatter.new
        end

        # def silence_logger
        #   ActiveRecord::SessionStore::Extension::LoggerSilencer
        # end
        def silence_logger
          if self.respond_to?(:silence) && self.method(:silence).arity == 0
             self.silence { yield }
          else
            yield
          end
        end

        ##
        # Log a `DEBUG` entry.
        #
        # @param [String, Hash] message The log entry payload, represented as
        #   either a string, a hash (JSON), or a hash (protocol buffer).
        # @yield Evaluates to the message to log. This is not evaluated unless
        #   the logger's level is sufficient to log the message. This allows you
        #   to create potentially expensive logging messages that are only
        #   called when the logger is configured to show them.
        #
        def debug message = nil, &block
          if block_given?
            add 0, nil, message, &block
          else
            add 0, message, nil, &block
          end
        end

        ##
        # Log an `INFO` entry.
        #
        # @param [String, Hash] message The log entry payload, represented as
        #   either a string, a hash (JSON), or a hash (protocol buffer).
        # @yield Evaluates to the message to log. This is not evaluated unless
        #   the logger's level is sufficient to log the message. This allows you
        #   to create potentially expensive logging messages that are only
        #   called when the logger is configured to show them.
        #
        def info message = nil, &block
          if block_given?
            add 1, nil, message, &block
          else
            add 1, message, nil, &block
          end
        end

        ##
        # Log a `WARN` entry.
        #
        # @param [String, Hash] message The log entry payload, represented as
        #   either a string, a hash (JSON), or a hash (protocol buffer).
        # @yield Evaluates to the message to log. This is not evaluated unless
        #   the logger's level is sufficient to log the message. This allows you
        #   to create potentially expensive logging messages that are only
        #   called when the logger is configured to show them.
        #
        def warn message = nil, &block
          if block_given?
            add 2, nil, message, &block
          else
            add 2, message, nil, &block
          end
        end

        ##
        # Log an `ERROR` entry.
        #
        # @param [String, Hash] message The log entry payload, represented as
        #   either a string, a hash (JSON), or a hash (protocol buffer).
        # @yield Evaluates to the message to log. This is not evaluated unless
        #   the logger's level is sufficient to log the message. This allows you
        #   to create potentially expensive logging messages that are only
        #   called when the logger is configured to show them.
        #
        def error message = nil, &block
          if block_given?
            add 3, nil, message, &block
          else
            add 3, message, nil, &block
          end
        end

        ##
        # Log a `FATAL` entry.
        #
        # @param [String, Hash] message The log entry payload, represented as
        #   either a string, a hash (JSON), or a hash (protocol buffer).
        # @yield Evaluates to the message to log. This is not evaluated unless
        #   the logger's level is sufficient to log the message. This allows you
        #   to create potentially expensive logging messages that are only
        #   called when the logger is configured to show them.
        #
        def fatal message = nil, &block
          if block_given?
            add 4, nil, message, &block
          else
            add 4, message, nil, &block
          end
        end

        ##
        # Log an `UNKNOWN` entry. This will be printed no matter what the
        # logger's current severity level is.
        #
        # @param [String, Hash] message The log entry payload, represented as
        #   either a string, a hash (JSON), or a hash (protocol buffer).
        # @yield Evaluates to the message to log. This is not evaluated unless
        #   the logger's level is sufficient to log the message. This allows you
        #   to create potentially expensive logging messages that are only
        #   called when the logger is configured to show them.
        #
        def unknown message = nil, &block
          if block_given?
            add 5, nil, message, &block
          else
            add 5, message, nil, &block
          end
        end

        ##
        # Log a message if the given severity is high enough. This is the
        # generic logging method. Users will be more inclined to use {#debug},
        # {#info}, {#warn}, {#error}, and {#fatal}.
        #
        # @param [Integer, String, Symbol] severity the integer code for or the
        #   name of the severity level
        # @param [String, Hash] message The log entry payload, represented as
        #   either a string, a hash (JSON), or a hash (protocol buffer).
        # @yield Evaluates to the message to log. This is not evaluated unless
        #   the logger's level is sufficient to log the message. This allows you
        #   to create potentially expensive logging messages that are only
        #   called when the logger is configured to show them.
        #
        def add severity, message = nil, progname = nil
          severity = derive_severity(severity) || 5 # 5 is UNKNOWN/DEFAULT
          return true if severity < @level

          if message.nil?
            if block_given?
              message = yield
            else
              message = progname
              # progname = nil # TODO: Figure out what to do with the progname
            end
          end

          write_entry severity, message
        end
        alias_method :log, :add

        ##
        # Returns `true` if the current severity level allows for sending
        # `DEBUG` messages.
        def debug?
          @level <= 0
        end

        ##
        # Returns `true` if the current severity level allows for sending `INFO`
        # messages.
        def info?
          @level <= 1
        end

        ##
        # Returns `true` if the current severity level allows for sending `WARN`
        # messages.
        def warn?
          @level <= 2
        end

        ##
        # Returns `true` if the current severity level allows for sending
        # `ERROR` messages.
        def error?
          @level <= 3
        end

        ##
        # Returns `true` if the current severity level allows for sending
        # `FATAL` messages.
        def fatal?
          @level <= 4
        end

        ##
        # Sets the logging severity level.
        #
        # @param [Integer, String, Symbol] severity the integer code for or the
        #   name of the severity level
        #
        # @example
        #   require "google/cloud/logging"
        #
        #   logging = Google::Cloud::Logging.new
        #
        #   resource = logging.resource "gae_app",
        #                               module_id: "1",
        #                               version_id: "20150925t173233"
        #
        #   logger = logging.logger "my_app_log", resource, env: :production
        #
        #   logger.level = "INFO"
        #   logger.debug "Job started." # No log entry written
        #
        def level= severity
          new_level = derive_severity severity
          fail ArgumentError, "invalid log level: #{severity}" if new_level.nil?
          @level = new_level
        end
        alias_method :sev_threshold=, :level=

        ##
        # Track a given trace_id by associating it with the current
        # Thread
        #
        # @param [String] trace_id The HTTP_X_CLOUD_TRACE_CONTEXT HTTP request
        #   header that's shared and tracked by all Stackdriver services
        def add_trace_id trace_id
          trace_ids[current_thread_id] = trace_id

          # Start removing old entries if hash gets too large.
          # This should never happen, because middleware should automatically
          # remove entries when a request is finished
          trace_ids.shift if trace_ids.size > 10_000
        end

        ##
        # Untrack the trace_id that's associated with current Thread
        #
        # @return [String] The trace_id that's being deleted
        def delete_trace_id
          trace_ids.delete current_thread_id
        end

        protected

        ##
        # @private Write a log entry to the Stackdriver Logging service.
        def write_entry severity, message
          entry = Entry.new.tap do |e|
            e.timestamp = Time.now
            e.severity = gcloud_severity(severity)
            e.payload = message
          end

          # merge input labels and trace_id
          trace_id = trace_ids[current_thread_id]
          merged_labels = trace_id.nil? ? {} : { traceId: trace_id }
          merged_labels = labels.merge(merged_labels) unless labels.nil?

          writer.write_entries entry, log_name: log_name, resource: resource,
                                      labels: merged_labels
        end

        ##
        # @private Get the logger level number from severity value object.
        def derive_severity severity
          return severity if severity.is_a? Integer

          downcase_severity = severity.to_s.downcase
          case downcase_severity
          when "debug".freeze then 0
          when "info".freeze then 1
          when "warn".freeze then 2
          when "error".freeze then 3
          when "fatal".freeze then 4
          when "unknown".freeze then 5
          else nil
          end
        end

        ##
        # @private Get Google Cloud deverity from logger level number.
        def gcloud_severity severity_int
          %i(DEBUG INFO WARNING ERROR CRITICAL DEFAULT)[severity_int]
        rescue
          :DEFAULT
        end

        ##
        # @private Get current thread id
        def current_thread_id
          Thread.current.object_id
        end
      end
    end
  end
end
