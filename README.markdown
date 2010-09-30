# Weechat Notifo highlight notifications

## Instructions

Place notifo.rb in ~/.weechat/ruby/, symbolic link in ~/.weechat/ruby/autoload/

Set user name and API key (`plugins.var.ruby.notifo.api_key` and `plugins.var.ruby.notifo.user`).

Install [HTTParty](http://rubygems.org/gems/httparty "httparty on rubygems")

    gem install httparty

## Silence mode

`plugins.var.ruby.notifo.silence` can be set to "on" to not send notifications.
