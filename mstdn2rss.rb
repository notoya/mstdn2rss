#!/usr/bin/env ruby
# coding: utf-8

require 'rss'
require 'mastodon'
require 'dotenv'


# 絵文字をHTML数値文字参照に変換 (TinyTinyRSS対策)
def emoji2html(str)
  str.gsub(/[^\u{0}-\u{FFFF}]/){'&#x%X;' % $&.ord}
end

def tohtml(st)
  created_at = Time.parse(st.created_at).localtime.strftime('%Y/%m/%d %H:%M')
  direct = ''
  media = ''
  content = ''

  if st.attributes['visibility'] == 'direct' then
    direct = '<p class="mastoson_dm">Direct Message:</p>'
  end

  st.media_attachments.each{ |m|
    if m.type == 'image' then
      media << %Q!<img src="#{m.url}"><br>!
    else
      media << %Q!<video src="#{m.url}" autoplay loop></video><br>!
    end
  }

  if st.attributes['spoiler_text'].empty? then
    content = st.content
  else
    content = %Q!<p>#{st.attributes['spoiler_text']}</p><p class="mastodon_readmore">---- read more ----</p>#{st.content}!
  end

  emoji2html(%Q!<p><a href="#{st.account.url}"><img width="60" height="60" src="#{st.account.avatar}"></a> #{st.account.attributes['display_name']} @#{st.account.acct}<br>#{created_at}</p>#{direct}#{content}#{media}!)

end

def rss_new_item(maker, st, client)
  return if ENV['MASTODON_PUBLIC_ONLY'] == 'true' and st.attributes['visibility'] != 'public'

  created_at = st.created_at
  boost = ''
  boost_str = emoji2html(%Q!<p class="mastodon_boost">( Boosted by #{st.account.attributes['display_name']} <a href="#{st.account.url}">@#{st.account.acct}</a> )</p>!)
  begin
    st = st.reblog
    boost = boost_str
  rescue
  end

  reply = ''
  if st.in_reply_to_id then
    begin # リプライ先の id が存在しない時スルー
      reply = %Q!<p>reply to:</p><blockquote>#{tohtml(client.status(st.in_reply_to_id))}</blockquote>!
    rescue
    end
  end

  item = maker.items.new_item
  item.link = "#{ENV['MASTODON_URL']}/web/statuses/#{st.id}"
  item.title = emoji2html("#{st.account.attributes['display_name']} @#{st.account.acct}")
  item.date = created_at
  item.dc_subject = "Mastodon, #{st.attributes['visibility']}, #{Time.parse(st.created_at).localtime.strftime('%a')}"
  item.content_encoded  = tohtml(st) + reply + boost
end

if ARGV[0] then
  Dotenv.load(ARGV[0])
else
  Dotenv.load
end

now = Time.now

client = Mastodon::REST::Client.new(base_url: ENV['MASTODON_URL'], bearer_token: ENV['MASTODON_ACCESS_TOKEN'])

rss = RSS::Maker.make("1.0") do |maker|
  maker.channel.about = ENV['MASTODON_URL']
  maker.channel.title = ENV['MASTODON_URL'] + " Home timeline"
  maker.channel.description = ENV['MASTODON_URL'] + " Home timeline"
  maker.channel.link = ENV['MASTODON_URL']
  maker.items.do_sort = true

  home = client.home_timeline(limit: 40)
  home.each{ |st|
    rss_new_item(maker, st, client)
  }
  oldest_st = home.last
  while Time.parse(oldest_st.created_at) > now - ENV['MASTODON_CHECK_MIN'].to_i * 60
    tl = client.home_timeline(limit: 40, max_id: oldest_st.id)
    tl.each{ |st|
      rss_new_item(maker, st, client)
    }
    oldest_st = tl.last
  end
end

puts rss.to_s

