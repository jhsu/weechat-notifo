# Author: Joseph "jshsu" Hsu <jhsu@josephhsu.com>
# File: notifo.rb
#
# Send highlighted messages to Notifo
#
#   Copyright (C) 2010 Joseph Hsu
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
begin
require 'httparty'
rescue
  Weechat.print Weechat.current_buffer, "weechat-notifo requires 'gem install httparty'"
end
require 'uri'

SCRIPT_NAME = 'notifo'
SCRIPT_AUTHOR = 'Joseph Hsu <jhsu@josephhsu.com>'
SCRIPT_DESC = 'Send highlighted messages to Notifo'
SCRIPT_VERSION = '0.1'
SCRIPT_LICENSE = 'GPL3'

class Notifo
  include HTTParty
  base_uri "https://api.notifo.com/v1"

  attr_accessor :api_key, :label, :msg, :title, :to, :uri, :user

  def initialize
    recheck_user
    recheck_api_key
  end

  def silence?
    set_value = Weechat.config_get_plugin("silence")
    if set_value && !set_value.empty?
      set_value == "on" ? true : false
    else
      Weechat.config_set_plugin("silence", "off")
      false
    end
  end

  def recheck_user
    set_value = Weechat.config_get_plugin("user")
    @user = if set_value && !set_value.empty?
        set_value
      else
        Weechat.config_set_plugin("user", "")
        nil
      end
  end

  def recheck_api_key
    set_value = Weechat.config_get_plugin("api_key")
    @api_key = if set_value && !set_value.empty?
        set_value
      else
        Weechat.config_set_plugin("api_key", "")
        nil
      end
  end

  def send_notification(msg, label=nil, title=nil, uri=nil)
    recheck_user
    recheck_api_key
    unless silence?
      params = { :to => @user, :msg => msg,
        :label => label, :title => title, :uri => uri}
      params.each do |param, value|
        params[param] = URI.escape(value, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) if value
      end

      if @user && @api_key
        self.class.basic_auth @user, @api_key
        response = self.class.post("/send_notification", {:body => params})
      else
        Weechat.print Weechat.current_buffer,
          "<i> need to set 'plugins.var.ruby.notifo.api_key' and 'plugins.var.ruby.notifo.user'"
      end
    end
  end
end

def weechat_init
  Weechat.register(SCRIPT_NAME, SCRIPT_AUTHOR, SCRIPT_VERSION,
                   SCRIPT_LICENSE, SCRIPT_DESC, "", "")
  Weechat.hook_signal("weechat_highlight", "send_message", "")
  @notifo = Notifo.new

  return Weechat::WEECHAT_RC_OK
end

def send_message(data, signal, msg)
  msg = msg.split
  from = msg.shift
  msg = msg.join(' ')
  @notifo.send_notification(msg, "weechat", from)
  return Weechat::WEECHAT_RC_OK
end
