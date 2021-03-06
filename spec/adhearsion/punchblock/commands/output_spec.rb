require 'spec_helper'

module Adhearsion
  module Punchblock
    module Commands
      describe Output do
        include PunchblockCommandTestHelpers

        describe "#play_ssml" do
          let(:ssml) { RubySpeech::SSML.draw { string "BOO" } }

          it 'executes an Output with the correct ssml' do
            expect_component_execution Punchblock::Component::Output.new(:ssml => ssml.to_s)
            mock_execution_environment.play_ssml(ssml)
          end

          describe "if an error is returned" do
            before do
              mock_execution_environment.should_receive(:execute_component_and_await_completion).once.and_raise(StandardError)
            end

            it 'should return false' do
              mock_execution_environment.play_ssml(ssml).should be false
            end
          end
        end

        describe "#play_audio" do
          let(:audio_file) { "boo.wav" }
          let(:ssml) do
            file = audio_file
            RubySpeech::SSML.draw { audio :src => file }
          end

          it 'plays the correct ssml' do
            mock_execution_environment.should_receive(:play_ssml).once.with(ssml).and_return true
            mock_execution_environment.play_audio(audio_file).should be true
          end
        end

        describe "#play_numeric" do
          let :expected_doc do
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { "123" }
            end
          end

          describe "with a number" do
            let(:input) { 123 }

            it 'plays the correct ssml' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_numeric(input).should be true
            end
          end

          describe "with a string representation of a number" do
            let(:input) { "123" }

            it 'plays the correct ssml' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_numeric(input).should be true
            end
          end

          describe "with something that's not a number" do
            let(:input) { 'foo' }

            it 'returns nil' do
              mock_execution_environment.play_numeric(input).should be nil
            end
          end
        end

        describe "#play_time" do
          let :expected_doc do
            content = input.to_s
            opts = expected_say_as_options
            RubySpeech::SSML.draw do
              say_as(opts) { content }
            end
          end

          describe "with a time" do
            let(:input) { Time.parse("12/5/2000") }
            let(:expected_say_as_options) { {:interpret_as => 'time'} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(input).should be true
            end
          end

          describe "with a date" do
            let(:input) { Date.parse('2011-01-23') }
            let(:expected_say_as_options) { {:interpret_as => 'date'} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(input).should be true
            end
          end

          describe "with a date and a say_as format" do
            let(:input) { Date.parse('2011-01-23') }
            let(:format) { "d-m-y" }
            let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(input, :format => format).should be true
            end
          end

          describe "with a date and a strftime option" do
            let(:strftime) { "%d-%m-%Y" }
            let(:base_input) { Date.parse('2011-01-23') }
            let(:input) { base_input.strftime(strftime) }
            let(:expected_say_as_options) { {:interpret_as => 'date'} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(base_input, :strftime => strftime).should be true
            end
          end

          describe "with a date, a format option and a strftime option" do
            let(:strftime) { "%d-%m-%Y" }
            let(:format) { "d-m-y" }
            let(:base_input) { Date.parse('2011-01-23') }
            let(:input) { base_input.strftime(strftime) }
            let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

            it 'plays the correct SSML' do
              mock_execution_environment.should_receive(:play_ssml).once.with(expected_doc).and_return true
              mock_execution_environment.play_time(base_input, :format => format, :strftime => strftime).should be true
            end
          end

          describe "with an object other than Time, DateTime, or Date" do
            let(:input) { "foo" }

            it 'returns false' do
              mock_execution_environment.play_time(input).should be false
            end
          end

        end

        describe '#play' do
          describe "with a single string" do
            let(:file) { "cents-per-minute" }

            it 'plays the audio file' do
              mock_execution_environment.should_receive(:play_audio).once.with(file).and_return true
              mock_execution_environment.play(file).should be true
            end
          end

          describe "with multiple strings" do
            let(:args) { ['rock', 'paperz', 'scissors'] }

            it 'plays multiple files' do
              args.each do |file|
                mock_execution_environment.should_receive(:play_audio).once.with(file).and_return true
              end
              mock_execution_environment.play(*args).should be true
            end

            describe "if an audio file cannot be found" do
              before do
                mock_execution_environment.should_receive(:play_audio).with(args[0]).and_return(true).ordered
                mock_execution_environment.should_receive(:play_audio).with(args[1]).and_return(false).ordered
                mock_execution_environment.should_receive(:play_audio).with(args[2]).and_return(true).ordered
              end

              it 'should return false' do
                mock_execution_environment.play(*args).should be false
              end
            end
          end

          describe "with a number" do
            it 'plays the number' do
              mock_execution_environment.should_receive(:play_numeric).with(123).and_return(true)
              mock_execution_environment.play(123).should be true
            end
          end

          describe "with a string representation of a number" do
            it 'plays the number' do
              mock_execution_environment.should_receive(:play_numeric).with('123').and_return(true)
              mock_execution_environment.play('123').should be true
            end
          end

          describe "with a time" do
            let(:time) { Time.parse("12/5/2000") }

            it 'plays the time' do
              mock_execution_environment.should_receive(:play_time).with([time]).and_return(true)
              mock_execution_environment.play(time).should be true
            end
          end

          describe "with a date" do
            let(:date) { Date.parse('2011-01-23') }

            it 'plays the time' do
              mock_execution_environment.should_receive(:play_time).with([date]).and_return(true)
              mock_execution_environment.play(date).should be true
            end
          end

          describe "with an array containing a Date/DateTime/Time object and a hash" do
            let(:date) { Date.parse('2011-01-23') }
            let(:format) { "d-m-y" }
            let(:strftime) { "%d-%m%Y" }

            it 'plays the time with the specified format and strftime' do
              mock_execution_environment.should_receive(:play_time).with([date, {:format => format, :strftime => strftime}]).and_return(true)
              mock_execution_environment.play(date, :format => format, :strftime => strftime).should be true
            end
          end

          it 'If a string matching dollars and (optionally) cents is passed to play(), a series of command will be executed to read the dollar amount', :ignore => true do
            pending "I think we should not have this be part of #play. Too much functionality in one method. Too much overloading. When we want to support multiple currencies, it'll be completely unwieldy. I'd suggest play_currency as a separate method. - Chad"
          end
        end

        describe "#speak" do
          describe "with a RubySpeech document" do
            it 'plays the correct SSML' do
              doc = RubySpeech::SSML.draw { "Hello world" }
              mock_execution_environment.should_receive(:play_ssml).once.with(doc, {}).and_return true
              mock_execution_environment.should_receive(:output).never
              mock_execution_environment.speak(doc).should be true
            end
          end

          describe "with a string" do
            it 'outputs the correct text' do
              string = "Hello world"
              mock_execution_environment.should_receive(:play_ssml).once.with(string, {})
              mock_execution_environment.should_receive(:output).once.with(:text, string, {}).and_return true
              mock_execution_environment.speak(string).should be true
            end
          end
        end

        describe "#interruptible_play" do
          let(:ssml) { RubySpeech::SSML.draw {"press a button"} }
          let(:component) {
            Punchblock::Component::Input.new(
              {:mode => :dtmf,
               :grammar => {:value => '[1 DIGIT]', :content_type => 'application/grammar+voxeo'}
            })
          }
          it "accepts SSML to play as a prompt" do
            mock_execution_environment.should_receive(:interruptible_play).once.with(ssml)
            mock_execution_environment.interruptible_play(ssml).should be nil
          end

          it "sends the correct input command" do
            pending
            #expect_message_waiting_for_response component
            #mock_execution_environment.interruptible_play(ssml)
          end
        end#describe #interruptible_play

        describe "#raw_output" do
          pending
        end
      end
    end
  end
end
