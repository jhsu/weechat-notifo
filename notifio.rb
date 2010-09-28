#!/usr/bin/env ruby

begin
require 'httparty'
rescue
  Weechat.print Weechat.current_buffer, "weechat-notifio requires 'gem install httparty'"
end
require 'uri'

SCRIPT_NAME = 'notifio'
SCRIPT_AUTHOR = 'Joseph Hsu <jhsu@josephhsu.com>'
SCRIPT_DESC = 'Create a query buffer next to current buffer'
SCRIPT_VERSION = '0.1'
SCRIPT_LICENSE = 'GPL3'

class Notifio
  include HTTParty
  base_uri "https://api.notifo.com/v1"

  attr_accessor :api_key, :label, :msg, :title, :to, :uri, :user

  def initialize
    recheck_user
    recheck_api_key
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
        "<i> need to set 'plugins.var.ruby.notifio.api_key' and 'plugins.var.ruby.notifio.user'"
    end
  end
end

def weechat_init
  Weechat.register(SCRIPT_NAME, SCRIPT_AUTHOR, SCRIPT_VERSION,
                   SCRIPT_LICENSE, SCRIPT_DESC, "", "")
  Weechat.hook_signal("weechat_highlight", "send_message", "")
  @notifio = Notifio.new

  return Weechat::WEECHAT_RC_OK
end

def send_message(data, signal, msg)

  msg = msg.split
  from = msg.shift
  msg = msg.join(' ')
  @notifio.send_notification(msg, "weechat", from)
  return Weechat::WEECHAT_RC_OK
end
