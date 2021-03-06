#
# Copyright 2015, SUSE Linux GmbH
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
#

module Crowbar
  module Client
    module Command
      module Upgrade
        #
        # Implementation for the upgrade status command
        #
        class Prechecks < Base
          include Mixin::Format
          include Mixin::Filter

          def request
            @request ||= Request::Upgrade::Prechecks.new(
              args
            )
          end

          def execute
            request.process do |request|
              case request.code
              when 200
                formatter = Formatter::Hash.new(
                  format: provide_format,
                  headings: ["Check ID", "Passed", "Required", "Errors", "Help"],
                  values: Filter::Hash.new(
                    filter: provide_filter,
                    values: content_from(request)
                  ).result
                )

                if formatter.empty?
                  err "No checks"
                else
                  say formatter.result
                  next unless provide_format == :table
                  say "Make sure that there are no errors for the required checks" \
                    " before executing the next step."
                  say "Next step: 'crowbarctl upgrade prepare'"
                end
              else
                err request.parsed_response["error"]
              end
            end
          end

          protected

          def content_from(request)
            [].tap do |row|
              request.parsed_response["checks"].each do |check_id, values|
                # make the check_id server agnostic
                # the check_id could be named differently in the server response
                check_ids = values["errors"].keys if values["errors"].any?

                if check_ids
                  check_ids.each do |id|
                    row.push(parsed_checks(id, values))
                  end
                else
                  row.push(parsed_checks(check_id, values))
                end
              end
            end
          end

          def parsed_checks(check_id, values)
            {
              check_id: check_id,
              passed: values["passed"],
              required: values["required"],
              errors: if values["errors"].key?(check_id)
                        values["errors"][check_id]["data"].inspect
                      end,
              help: if values["errors"].key?(check_id)
                      values["errors"][check_id]["help"].inspect
                    end
            }
          end
        end
      end
    end
  end
end
